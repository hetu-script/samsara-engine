import 'package:flutter/foundation.dart';
// import 'package:meta/meta.dart';
import 'package:hetu_script/hetu_script.dart';

import 'scene.dart';

abstract class SceneController implements HTLogger {
  // Scene? _scene;
  // Scene? get scene => _scene;

  final _cachedScenes = <String, Scene>{};

  final _sceneConstructors = <String, Future<Scene> Function([dynamic arg])>{};

  void registerSceneConstructor<T extends Scene>(
      String name, Future<T> Function([dynamic arg]) constructor) {
    _sceneConstructors[name] = constructor;
  }

  bool containsScene(String id) => _cachedScenes.containsKey(id);

  T? switchScene<T extends Scene>(String sceneId) {
    final cached = _cachedScenes[sceneId];
    assert(cached != null);
    // _scene = cached;
    if (kDebugMode) {
      print('switched scene: $sceneId');
    }
    return cached as T;
  }

  @mustCallSuper
  Future<T> createScene<T extends Scene>({
    required String contructorKey,
    required String sceneId,
    dynamic arg,
  }) async {
    late Scene scene;
    if (_cachedScenes.containsKey(sceneId)) {
      scene = _cachedScenes[sceneId]!;
    } else {
      final constructor = _sceneConstructors[contructorKey];
      assert(constructor != null);
      final T created = (await constructor!(arg)) as T;
      _cachedScenes[sceneId] = created;
      scene = created;
    }
    if (kDebugMode) {
      print('started scene: $sceneId');
    }
    return scene as T;
  }

  // void leaveScene(String sceneId, {bool clearCache = false}) {
  //   assert(_scene?.id == sceneId);

  //   _scene = null;
  //   if (clearCache) {
  //     _cachedScenes.remove(sceneId);
  //   }
  //   if (kDebugMode) {
  //     print('ended scene: $sceneId');
  //   }
  // }

  /// delete a previously cached scene
  void clearCache(String sceneId) {
    assert(_cachedScenes.containsKey(sceneId));

    _cachedScenes.remove(sceneId);

    // if (_cachedScenes.containsKey(sceneId)) {
    // if (_scene?.id == _cachedScenes[sceneId]!.id) {
    //   _scene = null;
    // }
    //   _cachedScenes.remove(sceneId);
    // }
  }

  void clearAllCache() {
    // _scene = null;
    _cachedScenes.clear();
  }
}
