import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:samsara/samsara.dart';

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

  final _constructors = <String, Future<Scene> Function(dynamic arguments)>{};

  /// 注册一个场景构造器
  /// 一个场景可能会存在多个实例，此时用 sceneId 区分它们
  void registerSceneConstructor(String constructorId,
      Future<Scene> Function(dynamic arguments) constructor) {
    _constructors[constructorId] = constructor;
  }

  bool hasScene(String id) => _cached.containsKey(id);

  /// 利用场景序列创造场景，可以实现场景的回退
  Future<Scene> pushScene(
    String sceneId, {
    String? constructorId,
    dynamic arguments = const {},
    bool clearCache = false,
  }) async {
    if (scene == null || scene?.id != sceneId) {
      if (_sequence.isNotEmpty) {
        if (_sequence.contains(sceneId)) {
          _sequence.remove(sceneId);
        }
      }
      await scene?.onEnd();
      _sequence.add(sceneId);
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
    assert(_sequence.isNotEmpty && _sequence.last == scene?.id);
    if (_sequence.length <= 1) {
      if (kDebugMode) {
        error('no scene to pop!');
      }
      return null;
    }
    if (kDebugMode) {
      info('leaving scene: [${_sequence.last}]');
    }
    await scene?.onEnd();
    if (_sequence.isNotEmpty) {
      _sequence.removeLast();
    }
    if (clearCache) {
      _cached.remove(scene?.id);
    }
    scene = await switchScene(_sequence.last);
    notifyListeners();
    return scene;
  }

  Future<Scene?> popSceneTill(String sceneId, {bool clearCache = false}) async {
    assert(_sequence.contains(sceneId),
        'could not find scene [$sceneId] to pop to!');

    String? before = scene?.id;
    while (_sequence.isNotEmpty && _sequence.last != sceneId) {
      await popScene(clearCache: clearCache);
    }
    if (scene?.id != before) {
      notifyListeners();
    }
    return scene;
  }

  /// 获取一个之前已经构建过的场景
  /// 使用此方法不会改变场景序列
  /// 在明确已经创建该场景的资源，并且不需要使用场景序列时，使用此函数
  /// 因为此函数不会改变场景序列，因此在之后再次调用 pop 时
  /// 无论切换到了什么场景都会正确的回到场景序列上的前一个场景
  /// 使用这个方法可以强制再次触发进入当前场景
  Future<Scene> switchScene(
    String sceneId, {
    dynamic arguments = const {},
    bool restart = false,
  }) async {
    assert(_cached.containsKey(sceneId), 'scene [$sceneId] not found!');
    bool switched = false;
    if (scene?.id != sceneId) {
      switched = true;
      await scene?.onEnd();
    }
    scene = _cached[sceneId];
    if (switched) {
      scene!.onStart(arguments);
      if (kDebugMode) {
        info('switched to scene: [$sceneId]');
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
    dynamic arguments = const {},
  }) async {
    if (scene?.id == sceneId) return scene!;

    if (_cached.containsKey(sceneId)) {
      scene = _cached[sceneId]!;
      if (kDebugMode) {
        info('resumed scene: [$sceneId]');
      }
    } else {
      final constructor = _constructors[constructorId ?? sceneId];
      assert(constructor != null, 'constructor [$constructorId] not found!');
      final tik = DateTime.now().millisecondsSinceEpoch;
      try {
        final Scene created = (await constructor!(arguments));
        _cached[sceneId] = created;
        if ((created.id != sceneId) && kDebugMode) {
          warn(
              'created scene id [${created.id}] mismatch the constructor argument scene id [$sceneId]!');
        }
        scene = created;
        if (kDebugMode) {
          info(
              'created scene: [$sceneId] in ${DateTime.now().millisecondsSinceEpoch - tik}ms');
        }
      } catch (e) {
        rethrow;
      }
    }
    scene!.onStart(arguments);
    notifyListeners();
    return scene!;
  }

  /// delete a previously cached scene
  void clearCachedScene(String sceneId) {
    assert(_cached.containsKey(sceneId), 'scene [$sceneId] not found!');

    _cached.remove(sceneId);
    if (kDebugMode) {
      info('cleared scene: [$sceneId]');
    }
    if (scene?.id == sceneId) {
      scene = null;
      notifyListeners();
    }
  }

  /// 清除所有缓存的 Scene 实例
  /// 如果提供了 except 参数，则保留该场景，并切换到该场景
  /// 不会触发 onEnd()
  Future<void> clearAllCachedScene({
    String? except,
    dynamic arguments = const {},
    bool restart = false,
  }) async {
    assert(_cached.isNotEmpty, 'No scene to clear!');
    assert(except == null || _cached.containsKey(except),
        'scene [$except] not found!');

    for (final cached in _cached.values.reversed) {
      if (except != null && cached.id == except) {
        continue;
      }
      if (scene == cached) {
        scene = null;
      }
    }
    _cached.removeWhere((key, value) => key != except);
    _sequence.removeWhere((key) => key != except);
    scene = null;
    if (except != null) {
      assert(_cached.containsKey(except), 'scene [$except] not found!');
      scene = await switchScene(except, arguments: arguments, restart: restart);
    }

    if (kDebugMode) {
      info('cleared all scenes${except != null ? ', except [$except]' : ''}');
    }
    notifyListeners();
  }
}
