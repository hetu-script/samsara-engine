import 'package:flutter/foundation.dart';
// import 'package:meta/meta.dart';

import 'scene.dart';

abstract class SceneController {
  // Scene? _scene;
  // Scene? get scene => _scene;

  final _cached = <String, Scene>{};

  final _sequence = <String>[];

  /// 取出当前场景序列的最后一个场景
  /// 如果没有使用 pushScene，则此值为 null
  Scene? get currentScene => _sequence.isEmpty ? null : _cached[_sequence.last];

  final _constructors = <String, Future<Scene> Function([dynamic arg])>{};

  /// 注册一个场景构造器
  /// 一个场景可能会存在多个实例，此时用 sceneId 区分它们
  void registerSceneConstructor(
      String constructorId, Future<Scene> Function([dynamic arg]) constructor) {
    _constructors[constructorId] = constructor;
  }

  bool hasScene(String id) => _cached.containsKey(id);

  /// 利用场景序列创造场景，可以实现场景的回退
  Future<Scene> pushScene(String sceneId,
      {String? constructorId, dynamic arguments}) async {
    if (_sequence.isNotEmpty) {
      final current = _cached[_sequence.last]!;
      current.onEnd();
    }
    _sequence.add(sceneId);
    final scene = await createScene(sceneId,
        constructorId: constructorId, arguments: arguments);
    scene.onStart(arguments);
    return scene;
  }

  /// 回退到当前场景序列的上一个场景
  Future<Scene?> popScene({bool clearCache = false}) async {
    assert(_sequence.length > 1, 'Cannot pop the last scene!');
    if (kDebugMode) {
      print('samsara - leaving scene: [${_sequence.last}]');
    }
    final current = _cached[_sequence.last]!;
    current.onEnd();
    if (clearCache) {
      _cached.remove(_sequence.last);
    }
    _sequence.removeLast();
    final scene = switchScene(_sequence.last);
    return scene;
  }

  /// 获取一个之前已经构建过的场景
  /// 使用此方法不会改变场景序列
  Scene switchScene(String sceneId, [dynamic arguments]) {
    assert(_cached.containsKey(sceneId), 'Scene [$sceneId] not found!');
    final scene = _cached[sceneId]!;
    scene.onStart(arguments);
    if (kDebugMode) {
      print('samsara - switched to scene: [$sceneId]');
    }
    return scene;
  }

  /// 构建一个场景，或者从缓存中取出之前已经构建过的场景。
  /// 如果不提供 构造ID ，则使用 sceneId 作为构造ID，这意味着这个场景的实例是唯一的。
  /// 使用此方法不会改变场景序列
  Future<Scene> createScene(String sceneId,
      {String? constructorId, dynamic arguments}) async {
    late Scene scene;
    if (_cached.containsKey(sceneId)) {
      scene = _cached[sceneId]!;
      if (kDebugMode) {
        print('samsara - resumed scene: [$sceneId]');
      }
    } else {
      final constructor = _constructors[constructorId ?? sceneId];
      assert(constructor != null, 'Constructor [$constructorId] not found!');
      final Scene created = (await constructor!(arguments));
      _cached[sceneId] = created;
      assert(created.id == sceneId,
          'Created scene ID [${created.id}] mismatch the function call [$sceneId]!');
      scene = created;
      if (kDebugMode) {
        print('samsara - created scene: [$sceneId]');
      }
    }
    return scene;
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
  void clearCachedScene(String sceneId) {
    assert(_cached.containsKey(sceneId), 'Scene [$sceneId] not found!');

    final scene = _cached[sceneId]!;
    scene.onEnd();
    scene.onDispose();
    _cached.remove(sceneId);
    if (kDebugMode) {
      print('samsara - cleared scene: [$sceneId]');
    }
  }

  void clearAllCachedScene({String? except}) {
    assert(_cached.isNotEmpty, 'No scene to clear!');
    assert(except == null || _cached.containsKey(except),
        'Scene [$except] not found!');

    for (final scene in _cached.values) {
      if (except != null && scene.id == except) {
        continue;
      }
      scene.onEnd();
      scene.onDispose();
    }
    if (except != null) {
      _cached.removeWhere((key, value) => key != except);
      _sequence.removeWhere((key) => key != except);
    } else {
      _cached.clear();
      _sequence.clear();
    }
    if (kDebugMode) {
      print('samsara - cleared all scenes.');
    }
  }
}
