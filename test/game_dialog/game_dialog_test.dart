import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:provider/provider.dart';
import 'package:samsara/game_dialog.dart';
import 'package:samsara/hover_info.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('execute completes after the last dialog', () async {
    final dialog = GameDialog();
    addTearDown(dialog.dispose);
    dialog.pushDialogRaw('hello');
    final execution = dialog.execute()!;

    dialog.finishDialog(dialog.currentContent['id'] as String);

    expect(await execution, DialogRunResult.completed);
    expect(dialog.currentContent, isNull);
    expect(dialog.isOpened, isFalse);
  });

  test('execute waits for dialogs appended by a running task', () async {
    final dialog = GameDialog();
    addTearDown(dialog.dispose);
    dialog.pushTask(() {
      dialog.pushDialogRaw('appended');
    });
    final execution = dialog.execute()!;
    await Future<void>.delayed(Duration.zero);

    expect(dialog.currentContent?['lines'], ['appended']);
    expect(dialog.isOpened, isTrue);
    dialog.finishDialog(dialog.currentContent['id'] as String);

    expect(await execution, DialogRunResult.completed);
    expect(dialog.currentContent, isNull);
    expect(dialog.isOpened, isFalse);
  });

  test('reset cancels execution and clears dialog state', () async {
    final dialog = GameDialog();
    addTearDown(dialog.dispose);
    dialog.storedValues['choice'] = 'old';
    dialog.pushDialogRaw('hello');
    final execution = dialog.execute()!;

    dialog.reset();

    expect(await execution, DialogRunResult.cancelled);
    expect(dialog.currentContent, isNull);
    expect(dialog.selectionsData, isNull);
    expect(dialog.screenHintInfo, isNull);
    expect(dialog.illustrations, isEmpty);
    expect(dialog.scenes, isEmpty);
    expect(dialog.storedValues, isEmpty);
    expect(dialog.isOpened, isFalse);
  });

  test('an asynchronous task from an old generation cannot reopen dialog',
      () async {
    final dialog = GameDialog();
    addTearDown(dialog.dispose);
    final gate = Completer<void>();
    dialog.pushTask(() async {
      await gate.future;
      dialog.pushDialogRaw('stale');
    });
    final execution = dialog.execute()!;

    dialog.reset();
    gate.complete();
    await Future<void>.delayed(Duration.zero);

    expect(await execution, DialogRunResult.cancelled);
    expect(dialog.currentContent, isNull);
    expect(dialog.isOpened, isFalse);
  });

  testWidgets('custom selection button preserves hover and selection', (
    tester,
  ) async {
    final dialog = GameDialog();
    final hover = HoverContentState();
    addTearDown(dialog.dispose);
    addTearDown(hover.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: dialog),
          ChangeNotifierProvider.value(value: hover),
        ],
        child: MaterialApp(
          home: GameDialogController(
            selectionButtonBuilder: (context, key, text, onPressed) {
              return TextButton(
                key: ValueKey('option-$key'),
                onPressed: onPressed,
                child: Text(text),
              );
            },
          ),
        ),
      ),
    );
    dialog.pushSelectionRaw({
      'id': 'choice',
      'selections': {
        'first': {'text': 'First', 'description': 'First description'},
      },
    });
    final execution = dialog.execute()!;
    await tester.pump();

    final option = find.byKey(const ValueKey('option-first'));
    expect(option, findsOneWidget);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(option));
    await tester.pump();
    expect(hover.content?.data, 'First description');

    await tester.tap(option);
    await tester.pump();
    expect(dialog.getValue('choice'), 'first');
    expect(hover.content, isNull);
    expect(await execution, DialogRunResult.completed);
  });

  testWidgets('controller offsets selection buttons from screen center', (
    tester,
  ) async {
    final dialog = GameDialog();
    final hover = HoverContentState();
    addTearDown(dialog.dispose);
    addTearDown(hover.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: dialog),
          ChangeNotifierProvider.value(value: hover),
        ],
        child: MaterialApp(
          home: GameDialogController(
            selectionOffset: const Offset(300, 0),
            selectionButtonBuilder: (context, key, text, onPressed) {
              return TextButton(
                key: ValueKey('option-$key'),
                onPressed: onPressed,
                child: Text(text),
              );
            },
          ),
        ),
      ),
    );
    dialog.pushSelectionRaw({
      'id': 'choice',
      'selections': {'first': 'First'},
    });
    final execution = dialog.execute()!;
    await tester.pump();

    final option = find.byKey(const ValueKey('option-first'));
    final screenSize = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(
      tester.getCenter(option),
      screenSize.center(Offset.zero) + const Offset(300, 0),
    );

    await tester.tap(option);
    await tester.pump();
    expect(await execution, DialogRunResult.completed);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('unrelated rebuild does not restart typewriter or custom frame', (
    tester,
  ) async {
    final dialog = GameDialog();
    addTearDown(dialog.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: dialog,
        child: MaterialApp(
          home: GameDialogController(
            dialogFrameBuilder: (context, child) {
              return SizedBox(
                key: const Key('custom-frame'),
                width: 500,
                height: 180,
                child: child,
              );
            },
          ),
        ),
      ),
    );
    dialog.pushDialogRaw({
      'name': 'Vera',
      'lines': ['ab', 'cd']
    });
    final execution = dialog.execute()!;
    await tester.pump();

    expect(find.byKey(const Key('custom-frame')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('a', findRichText: true), findsOneWidget);

    dialog.notifyListeners();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('ab', findRichText: true), findsOneWidget);

    await tester.tap(find.byType(GameDialogContent));
    await tester.pump();
    expect(find.text('cd', findRichText: true), findsNothing);
    await tester.tap(find.byType(GameDialogContent));
    await tester.pump();
    expect(find.text('cd', findRichText: true), findsOneWidget);

    await tester.tap(find.byType(GameDialogContent));
    await tester.pump();
    expect(await execution, DialogRunResult.completed);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('controller adds its offset to each illustration offset', (
    tester,
  ) async {
    final dialog = GameDialog();
    addTearDown(dialog.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: dialog,
        child: DefaultAssetBundle(
          bundle: _TestAssetBundle(),
          child: MaterialApp(
            home: GameDialogController(
              illustrationOffset: const Offset(12, -30),
              dialogFrameBuilder: (context, child) {
                return SizedBox(width: 500, height: 180, child: child);
              },
            ),
          ),
        ),
      ),
    );
    dialog.pushImage('portrait.png', offsetX: 8, offsetY: 5);
    dialog.pushDialogRaw('hello');
    final execution = dialog.execute()!;
    await tester.pump();

    final illustration = tester.widget<GameDialogIllustration>(
      find.byType(GameDialogIllustration),
    );
    expect(illustration.offsetX, 20);
    expect(illustration.offsetY, -25);

    dialog.finishDialog(dialog.currentContent['id'] as String);
    await tester.pump();
    expect(await execution, DialogRunResult.completed);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('illustrations preserve aspect ratio and align bottom center', (
    tester,
  ) async {
    Future<void> check(int width, int height, Size expected) async {
      final bytes = image.encodePng(image.Image(width: width, height: height));
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 400,
              height: 300,
              child: GameDialogIllustration(image: MemoryImage(bytes)),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await precacheImage(
          MemoryImage(bytes),
          tester.element(find.byType(GameDialogIllustration)),
        );
      });
      await tester.pump();
      final imageFinder = find.byType(Image);
      expect(tester.getSize(imageFinder), expected);
      expect(tester.getCenter(imageFinder).dx, 400.0);
      expect(tester.getRect(imageFinder).bottom, 300.0);
    }

    await check(100, 50, const Size(100, 50));
    await check(1024, 1024, const Size(300, 300));
    await check(1200, 300, const Size(400, 100));
  });

  testWidgets('motion runs beside dialog and pause restarts typewriter', (
    tester,
  ) async {
    final dialog = GameDialog();
    addTearDown(dialog.dispose);
    var skipCount = 0;
    await tester.pumpWidget(
      _dialogTestApp(
        dialog,
        onSkip: () => skipCount++,
      ),
    );
    dialog.pushBackground(
      'scene.png',
      motion: const SceneMotion(
        duration: Duration(seconds: 1),
        beginScale: 1,
        endScale: 1.04,
        fadeDuration: Duration(milliseconds: 200),
      ),
      waitForTransition: false,
    );
    dialog.pushDialogRaw({
      'lines': ['ab']
    });
    final execution = dialog.execute()!;
    await tester.pump();
    await tester.pump();

    expect(dialog.currentContent?['lines'], ['ab']);
    expect(find.byKey(const ValueKey('skip-button')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('a', findRichText: true), findsOneWidget);

    dialog.setPresentationPaused(true);
    await tester.pump();
    expect(find.byType(GameDialogContent), findsNothing);
    expect(find.byKey(const ValueKey('skip-button')), findsNothing);
    expect(dialog.currentContent, isNotNull);

    dialog.setPresentationPaused(false);
    await tester.pump();
    expect(find.byType(GameDialogContent), findsOneWidget);
    expect(find.text('ab', findRichText: true), findsNothing);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('ab', findRichText: true), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('skip-button')));
    expect(skipCount, 1);
    dialog.finishDialog(dialog.currentContent['id'] as String);
    expect(await execution, DialogRunResult.completed);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('selection hides skip button', (tester) async {
    final dialog = GameDialog();
    addTearDown(dialog.dispose);
    await tester.pumpWidget(_dialogTestApp(dialog, onSkip: () {}));
    dialog.pushSelectionRaw({
      'id': 'choice',
      'selections': {'first': 'First'},
    });
    final execution = dialog.execute()!;
    await tester.pump();

    expect(dialog.selectionsData, isNotNull);
    expect(find.byKey(const ValueKey('skip-button')), findsNothing);
    dialog.finishSelection(
      dialog.selectionsData['taskId'] as String,
      'choice',
      value: 'first',
    );
    expect(await execution, DialogRunResult.completed);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('shade pauses and reset clears pending animation',
      (tester) async {
    final dialog = GameDialog();
    addTearDown(dialog.dispose);
    await tester.pumpWidget(_dialogTestApp(dialog));
    dialog.setSceneShade(
      1,
      duration: const Duration(seconds: 1),
      waitForTransition: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(dialog.sceneShade, isNotNull);

    dialog.setPresentationPaused(true);
    await tester.pump(const Duration(milliseconds: 500));
    expect(dialog.sceneShade, isNotNull);
    dialog.setPresentationPaused(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    expect(dialog.sceneShade, isNull);
    expect(dialog.sceneShadeOpacity, 1);

    dialog.setSceneShade(0, duration: const Duration(seconds: 1));
    dialog.reset();
    await tester.pump();
    expect(dialog.sceneShade, isNull);
    expect(dialog.sceneShadeOpacity, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('illustration fade out clears previous illustration', (
    tester,
  ) async {
    final dialog = GameDialog();
    addTearDown(dialog.dispose);
    await tester.pumpWidget(_dialogTestApp(dialog));
    dialog.pushImage('vera.png');
    await tester.pump();
    expect(dialog.illustrations, hasLength(1));

    dialog.popAllImages(
      isFadeOut: true,
      fadeDuration: const Duration(milliseconds: 100),
    );
    final execution = dialog.execute()!;
    await tester.pump();
    expect(dialog.prevIllustration, isNotNull);
    await tester.pump(const Duration(milliseconds: 150));
    expect(dialog.prevIllustration, isNull);
    expect(await execution, DialogRunResult.completed);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Widget _dialogTestApp(GameDialog dialog, {VoidCallback? onSkip}) {
  return DefaultAssetBundle(
    bundle: _TestAssetBundle(),
    child: MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dialog),
        ChangeNotifierProvider(create: (_) => HoverContentState()),
      ],
      child: MaterialApp(
        home: GameDialogController(
          onSkip: onSkip,
          dialogFrameBuilder: (context, child) {
            return SizedBox(width: 500, height: 180, child: child);
          },
          selectionButtonBuilder: (context, key, text, onPressed) {
            return TextButton(onPressed: onPressed, child: Text(text));
          },
          skipButtonBuilder: (context, onPressed) {
            return TextButton(
              key: const ValueKey('skip-button'),
              onPressed: onPressed,
              child: const Text('Skip'),
            );
          },
        ),
      ),
    ),
  );
}

class _TestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = image.encodePng(image.Image(width: 1, height: 1));
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }

  @override
  Future<T> loadStructuredBinaryData<T>(
    String key,
    FutureOr<T> Function(ByteData data) parser,
  ) {
    return rootBundle.loadStructuredBinaryData(key, parser);
  }
}
