import 'package:flutter/foundation.dart';
import 'package:samsara/samsara.dart';

class SceneControllerState with ChangeNotifier {
  final SamsaraEngine _engine;

  SceneControllerState(SamsaraEngine engine) : _engine = engine;

  Scene? scene;

  Future<void> push(
    String sceneId, {
    String? constructorId,
    Map<String, dynamic> arguments = const {},
  }) async {
    if (scene?.id != sceneId) {
      scene = await _engine.pushScene(sceneId,
          constructorId: constructorId, arguments: arguments);
      notifyListeners();
    } else {
      scene!.onTrigger(arguments);
    }
  }

  Future<void> pop({bool clearCache = false}) async {
    scene = await _engine.popScene(clearCache: clearCache);

    notifyListeners();
  }

  /// 在明确已经创建该场景的资源，并且不需要使用场景序列时，使用此函数
  /// 因为此函数不会改变场景序列，因此在之后再次调用 pop 时
  /// 无论切换到了什么场景都会正确的回到之前的场景
  void switchTo(
    String sceneId, {
    Map<String, dynamic> arguments = const {},
  }) {
    scene = _engine.switchScene(sceneId, arguments: arguments);

    notifyListeners();
  }

  Future<void> create(
    String sceneId, {
    String? constructorId,
    Map<String, dynamic> arguments = const {},
  }) async {
    scene = await _engine.createScene(sceneId,
        constructorId: constructorId, arguments: arguments);

    notifyListeners();
  }

  void clearAll({
    String? except,
    Map<String, dynamic> arguments = const {},
  }) {
    _engine.clearAllCachedScene(except: except);
    if (except != null) {
      scene = _engine.switchScene(except, arguments: arguments);
    }

    notifyListeners();
  }
}
