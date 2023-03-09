import 'package:meta/meta.dart';

import 'scene.dart';

class SceneController {
  Scene? _currentScene;
  Scene? get currentScene => _currentScene;

  final _cachedScenes = <String, Scene>{};

  final _sceneConstructors = <String, Future<Scene> Function([dynamic arg])>{};

  void registerSceneConstructor<T extends Scene>(
      String name, Future<T> Function([dynamic arg]) constructor) {
    _sceneConstructors[name] = constructor;
  }

  @mustCallSuper
  Future<Scene> createScene(
    String contructorKey,
    String sceneId, [
    dynamic arg,
  ]) async {
    final _cached = _cachedScenes[sceneId];
    if (_cached != null) {
      _currentScene = _cached;
      return _cached;
    } else {
      final constructor = _sceneConstructors[contructorKey];
      assert(constructor != null);
      final Scene scene = await constructor!(arg);
      _cachedScenes[sceneId] = scene;
      _currentScene = scene;
      return scene;
    }
  }

  void leaveScene(String sceneId, {bool clearCache = false}) {
    assert(_cachedScenes.containsKey(sceneId));
    if (_currentScene?.id == _cachedScenes[sceneId]!.id) {
      _currentScene = null;
    }
    if (clearCache) {
      _cachedScenes.remove(sceneId);
    }
  }

  /// 删除某个之前缓存的场景，这里允许接收一个不存在的id
  void clearCache(String sceneId) {
    if (_cachedScenes.containsKey(sceneId)) {
      if (_currentScene?.id == _cachedScenes[sceneId]!.id) {
        _currentScene = null;
      }
      _cachedScenes.remove(sceneId);
    }
  }
}
