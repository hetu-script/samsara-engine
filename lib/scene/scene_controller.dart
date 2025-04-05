import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hetu_script/hetu_script.dart';

import 'scene.dart';

abstract class SceneController with ChangeNotifier implements HTLogger {
  // Scene? _scene;
  // Scene? get scene => _scene;

  final _cached = <String, Scene>{};

  final _sequence = <String>[];

  /// 当前场景
  Scene? scene;

  /// 取出当前场景序列的最后一个场景
  /// 如果没有使用场景序列，则此值为 null
  Scene? get lastScene => _sequence.isEmpty ? null : _cached[_sequence.last];

  final _constructors =
      <String, Future<Scene> Function([Map<String, dynamic> arguments])>{};

  /// 注册一个场景构造器
  /// 一个场景可能会存在多个实例，此时用 sceneId 区分它们
  void registerSceneConstructor(String constructorId,
      Future<Scene> Function([Map<String, dynamic> arguments]) constructor) {
    _constructors[constructorId] = constructor;
  }

  bool hasScene(String id) => _cached.containsKey(id);

  /// 利用场景序列创造场景，可以实现场景的回退
  Future<Scene> pushScene(
    String sceneId, {
    String? constructorId,
    Map<String, dynamic> arguments = const {},
    // Completer? completer,
  }) async {
    if (scene == null || scene?.id != sceneId) {
      if (_sequence.isNotEmpty) {
        // assert(sceneId != _sequence.last, 'Cannot push the same scene again!');
        // final current = _cached[_sequence.last]!;
        // current.onEnd();

        if (_sequence.contains(sceneId)) {
          _sequence.remove(sceneId);
        }
      }
      _sequence.add(sceneId);
      scene?.onEnd();
      scene = await createScene(sceneId,
          constructorId: constructorId, arguments: arguments);
      // scene!.completer = completer;
      notifyListeners();
    } else {
      scene!.onTrigger(arguments);
    }

    return scene!;
  }

  /// 回退到当前场景序列的上一个场景
  Future<Scene?> popScene({bool clearCache = false}) async {
    assert(_sequence.length > 1, 'Cannot pop the last scene!');
    if (kDebugMode) {
      info('samsara - leaving scene: [${_sequence.last}]');
    }
    // scene?.onEnd();
    // final current = _cached[_sequence.last]!;
    // current.onEnd();
    if (clearCache) {
      _cached.remove(_sequence.last);
    }
    _sequence.removeLast();
    scene = switchScene(_sequence.last);
    notifyListeners();
    return scene;
  }

  /// 获取一个之前已经构建过的场景
  /// 使用此方法不会改变场景序列
  /// 在明确已经创建该场景的资源，并且不需要使用场景序列时，使用此函数
  /// 因为此函数不会改变场景序列，因此在之后再次调用 pop 时
  /// 无论切换到了什么场景都会正确的回到场景序列上的前一个场景
  /// 使用这个方法可以强制再次触发进入当前场景
  Scene switchScene(
    String sceneId, {
    Map<String, dynamic> arguments = const {},
    bool restart = false,
  }) {
    assert(_cached.containsKey(sceneId), 'Scene [$sceneId] not found!');
    bool switched = false;
    if (scene?.id != sceneId) {
      scene?.onEnd();
      switched = true;
    }
    scene = _cached[sceneId];
    if (switched) {
      scene!.onStart(arguments);
      if (kDebugMode) {
        info('samsara - switched to scene: [$sceneId]');
      }
    } else if (restart) {
      scene!.onStart(arguments);
    }
    notifyListeners();
    return scene!;
  }

  /// 构建一个场景，或者从缓存中取出之前已经构建过的场景。
  /// 如果不提供 构造ID ，则使用 sceneId 作为构造ID，这意味着这个场景的实例是唯一的。
  /// 使用此方法不会改变场景序列
  Future<Scene> createScene(
    String sceneId, {
    String? constructorId,
    Map<String, dynamic> arguments = const {},
  }) async {
    if (scene?.id == sceneId) return scene!;

    if (_cached.containsKey(sceneId)) {
      scene = _cached[sceneId]!;
      if (kDebugMode) {
        info('samsara - resumed scene: [$sceneId]');
      }
    } else {
      final constructor = _constructors[constructorId ?? sceneId];
      assert(constructor != null, 'Constructor [$constructorId] not found!');
      final tik = DateTime.now().millisecondsSinceEpoch;
      final Scene created = (await constructor!(arguments));
      _cached[sceneId] = created;
      assert(created.id == sceneId,
          'Created scene ID [${created.id}] mismatch the function call [$sceneId]!');
      scene = created;
      if (kDebugMode) {
        info(
            'samsara - created scene: [$sceneId] in ${DateTime.now().millisecondsSinceEpoch - tik}ms');
      }
    }
    scene!.onStart(arguments);
    notifyListeners();
    return scene!;
  }

  // void leaveScene(String sceneId, {bool clearCache = false}) {
  //   assert(_scene?.id == sceneId);

  //   _scene = null;
  //   if (clearCache) {
  //     _cachedScenes.remove(sceneId);
  //   }
  //   if (kDebugMode) {
  //     info('ended scene: $sceneId');
  //   }
  // }

  /// delete a previously cached scene
  void clearCachedScene(String sceneId) {
    assert(_cached.containsKey(sceneId), 'Scene [$sceneId] not found!');

    final cached = _cached[sceneId]!;
    cached.onEnd();
    // cached.onDispose();
    _cached.remove(sceneId);
    if (kDebugMode) {
      info('samsara - cleared scene: [$sceneId]');
    }
    if (scene?.id == sceneId) {
      scene = null;
      notifyListeners();
    }
  }

  void clearAllCachedScene({
    String? except,
    Map<String, dynamic> arguments = const {},
    bool restart = false,
  }) {
    assert(_cached.isNotEmpty, 'No scene to clear!');
    assert(except == null || _cached.containsKey(except),
        'Scene [$except] not found!');

    for (final cached in _cached.values) {
      if (except != null && cached.id == except) {
        continue;
      }
      cached.onEnd();
      if (scene == cached) {
        scene = null;
      }
      // scene.onDispose();
    }
    _cached.removeWhere((key, value) => key != except);
    _sequence.removeWhere((key) => key != except);
    if (except != null) {
      assert(_cached.containsKey(except), 'Scene [$except] not found!');
      scene = switchScene(except, arguments: arguments, restart: restart);
    } else {
      scene = null;
    }

    if (kDebugMode) {
      info(
          'samsara - cleared all scenes${except != null ? ', except [$except]' : ''}');
    }
    notifyListeners();
  }
}
