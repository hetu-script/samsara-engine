import 'package:flutter_test/flutter_test.dart';
import 'package:samsara/samsara.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loading listenable only notifies for actual loading changes', () {
    final engine = SamsaraEngine();
    addTearDown(engine.dispose);
    final loadingValues = <bool>[];
    var sceneNotifications = 0;
    var legacyNotifications = 0;
    engine.loadingState.addListener(() {
      loadingValues.add(engine.isLoading);
      expect(engine.loadingTip, 'loading scene');
      expect(engine.loadingMessage, 'please wait');
    });
    engine.sceneState.addListener(() => sceneNotifications++);
    engine.addListener(() => legacyNotifications++);

    engine.setLoading(
      true,
      tip: 'loading scene',
      message: 'please wait',
    );
    engine.setLoading(true);

    expect(loadingValues, [true]);
    expect(sceneNotifications, 0);
    expect(legacyNotifications, 1);
  });

  test('scene listenable follows navigation without loading notifications',
      () async {
    final engine = SamsaraEngine();
    addTearDown(engine.dispose);
    final scenes = <Scene?>[];
    var loadingNotifications = 0;
    var legacyNotifications = 0;
    engine.sceneState.addListener(() => scenes.add(engine.scene));
    engine.loadingState.addListener(() => loadingNotifications++);
    engine.addListener(() => legacyNotifications++);
    engine.registerSceneConstructor(
      'first',
      (_) async => _TestScene('first'),
    );
    engine.registerSceneConstructor(
      'second',
      (_) async => _TestScene('second'),
    );

    final first = await engine.pushScene('first', triggerOnStart: false);
    await engine.pushScene('first', triggerOnStart: false);
    final second = await engine.pushScene('second', triggerOnStart: false);
    await engine.popScene();
    engine.clearCachedScene('first');

    expect(scenes, [first, second, first, null]);
    expect(loadingNotifications, 0);
    expect(legacyNotifications, greaterThanOrEqualTo(4));
  });
  test('popScene ends the outgoing scene exactly once', () async {
    final engine = SamsaraEngine();
    addTearDown(engine.dispose);
    final first = _TestScene('first');
    final second = _TestScene('second');
    engine.registerSceneConstructor('first', (_) async => first);
    engine.registerSceneConstructor('second', (_) async => second);

    await engine.pushScene('first', triggerOnStart: false);
    await engine.pushScene('second', triggerOnStart: false);
    await engine.popScene(clearCache: true);

    expect(engine.scene, first);
    expect(first.endCount, 1);
    expect(second.endCount, 1);
  });
}

class _TestScene extends Scene {
  _TestScene(String id) : super(id: id);

  int endCount = 0;

  @override
  void onEnd() {
    endCount++;
    super.onEnd();
  }
}
