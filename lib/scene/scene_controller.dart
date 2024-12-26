import 'package:meta/meta.dart';
import 'package:hetu_script/hetu_script.dart';

import 'scene.dart';

abstract class SceneController implements HTLogger {
  Scene? _currentScene;
  Scene? get currentScene => _currentScene;

  final _cachedScenes = <String, Scene>{};

  final _sceneConstructors = <String, Future<Scene> Function([dynamic arg])>{};

  void registerSceneConstructor<T extends Scene>(
      String name, Future<T> Function([dynamic arg]) constructor) {
    _sceneConstructors[name] = constructor;
  }

  bool containsScene(String id) => _cachedScenes.containsKey(id);

  T? switchScene<T extends Scene>(String sceneId) {
    final cached = _cachedScenes[sceneId];
    if (cached != null) {
      _currentScene = cached;
      return cached as T;
    } else {
      return null;
    }
  }

  @mustCallSuper
  Future<T> createScene<T extends Scene>({
    required String contructorKey,
    required String sceneId,
    dynamic arg,
  }) async {
    final constructor = _sceneConstructors[contructorKey];
    assert(constructor != null);
    final T scene = (await constructor!(arg)) as T;
    _cachedScenes[sceneId] = scene;
    _currentScene = scene;
    return scene;
  }

  void leaveScene(String sceneId, {bool clearCache = false}) {
    if (_currentScene?.id == sceneId) {
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

  void clearAllCache() {
    _currentScene = null;
    _cachedScenes.clear();
  }
}
