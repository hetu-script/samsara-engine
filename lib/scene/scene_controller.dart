import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:samsara/samsara.dart';

abstract class SceneController with ChangeNotifier implements HTLogger {
  // Scene? _scene;
  // Scene? get scene => _scene;

  final _cached = <String, Scene>{};

  final _sceneStack = <String>[];
  List<String> get sceneStack => List.unmodifiable(_sceneStack);

  final _cachedConstructorIds = <String, String>{};
  Map<String, String> get cachedConstructorIds =>
      Map.unmodifiable(_cachedConstructorIds);
  void loadSceneConstructorIds(Map<String, String> data) {
    _cachedConstructorIds.addAll(data);
  }

  final _cachedArguments = <String, dynamic>{};
  Map<String, dynamic> get cachedArguments =>
      Map.unmodifiable(_cachedArguments);
  void loadSceneArguments(Map<String, dynamic> data) {
    _cachedArguments.addAll(data);
  }

  void setSceneArguments(String sceneId, dynamic arguments) {
    _cachedArguments[sceneId] = arguments;
  }

  /// 当前场景
  Scene? scene;

  /// 取出当前场景序列的最后一个场景
  /// 如果没有使用场景序列，则此值为 null
  Scene? get lastScene =>
      _sceneStack.isEmpty ? null : _cached[_sceneStack.last];

  final _constructors = <String, Future<Scene> Function(dynamic arguments)>{};

  /// 注册一个场景构造器
  /// 一个场景可能会存在多个实例，此时用 sceneId 区分它们
  void registerSceneConstructor(String constructorId,
      Future<Scene> Function(dynamic arguments) constructor) {
    _constructors[constructorId] = constructor;
  }

  bool hasScene(String id) => _cached.containsKey(id);

  bool hasSceneInSequence(String id) => _sceneStack.contains(id);

  /// 构建一个场景，或者从缓存中取出之前已经构建过的场景。
  /// 如果不提供 构造ID ，则使用 sceneId 作为构造ID。
  Future<Scene> _createScene(
    String sceneId, {
    String? constructorId,
    dynamic arguments,
  }) async {
    if (scene?.id == sceneId) return scene!;

    Scene newScene;
    if (_cached.containsKey(sceneId)) {
      newScene = _cached[sceneId]!;
      if (kDebugMode) {
        info('resumed scene: [$sceneId]');
      }
    } else {
      if (constructorId != null) {
        _cachedConstructorIds[sceneId] = constructorId;
      }
      final ctorId = constructorId ?? sceneId;
      final constructor = _constructors[ctorId];
      assert(constructor != null, 'constructor [$ctorId] not found!');
      final tik = DateTime.now().millisecondsSinceEpoch;
      try {
        final Scene created = (await constructor!(arguments));
        _cached[sceneId] = created;
        if ((created.id != sceneId) && kDebugMode) {
          warn(
              'created scene id [${created.id}] mismatch the constructor argument scene id [$sceneId]!');
        }
        newScene = created;
        if (kDebugMode) {
          info(
              'created scene: [$sceneId] in ${DateTime.now().millisecondsSinceEpoch - tik}ms');
        }
      } catch (e) {
        rethrow;
      }
    }
    return newScene;
  }

  /// 利用场景序列创造场景
  Future<Scene> pushScene(
    String sceneId, {
    String? constructorId,
    dynamic arguments,
    bool triggerOnStart = true,
    void Function()? onAfterLoaded,
  }) async {
    if (scene?.id != sceneId) {
      if (_sceneStack.contains(sceneId)) {
        _sceneStack.remove(sceneId);
        _cachedArguments.remove(sceneId);
      }
      scene?.onEnd();
      _sceneStack.add(sceneId);
      if (constructorId != null) {
        _cachedConstructorIds[sceneId] = constructorId;
      } else {
        constructorId = _cachedConstructorIds[sceneId];
      }
      if (arguments != null) {
        _cachedArguments[sceneId] = arguments;
      } else {
        arguments = _cachedArguments[sceneId];
      }
      scene = await _createScene(sceneId,
          constructorId: constructorId, arguments: arguments);
      scene?.onAfterLoaded = onAfterLoaded;
      notifyListeners();
    }
    if (triggerOnStart) {
      scene?.onStart(arguments);
    }
    return scene!;
  }

  /// 获取一个之前已经构建过的场景
  /// 使用此方法不会改变场景序列
  /// 在明确已经创建该场景的资源，并且不需要使用场景序列时，使用此函数
  /// 因为此函数不会改变场景序列，因此在之后再次调用 pop 时
  /// 无论切换到了什么场景都会正确的回到场景序列上的前一个场景
  /// 使用这个方法可以强制再次触发进入当前场景
  Future<Scene> switchScene(
    String sceneId, {
    dynamic arguments,
    bool triggerOnStart = true,
  }) async {
    assert(_cached.containsKey(sceneId), 'scene [$sceneId] not found!');
    if (scene?.id != sceneId) {
      scene?.onEnd();
      scene = _cached[sceneId];
      scene?.onAfterLoaded = null;
      if (kDebugMode) {
        info('switched to scene: [$sceneId]');
      }
      notifyListeners();
    }
    if (arguments != null) {
      _cachedArguments[sceneId] = arguments;
    } else {
      arguments ??= _cachedArguments[sceneId];
    }
    if (triggerOnStart) {
      scene!.onStart(arguments);
    }
    return scene!;
  }

  /// 回退到当前场景序列的上一个场景
  Future<Scene?> popScene({bool clearCache = false}) async {
    assert(_sceneStack.isNotEmpty && _sceneStack.last == scene?.id);
    if (_sceneStack.length <= 1) {
      if (kDebugMode) {
        error('cannot pop the last scene!');
      }
      return null;
    }
    if (kDebugMode) {
      info('leaving scene: [${_sceneStack.last}]');
    }
    scene?.onEnd();
    if (_sceneStack.isNotEmpty) {
      _sceneStack.removeLast();
      _cachedArguments.remove(scene?.id);
    }
    if (clearCache) {
      _cached.remove(scene?.id);
    }
    scene = await switchScene(_sceneStack.last);
    scene?.onAfterLoaded = null;
    notifyListeners();
    return scene;
  }

  Future<Scene?> popSceneTill(String sceneId, {bool clearCache = false}) async {
    assert(_sceneStack.contains(sceneId),
        'could not find scene [$sceneId] to pop to!');

    while (_sceneStack.isNotEmpty && _sceneStack.last != sceneId) {
      await popScene(clearCache: clearCache);
    }
    return scene;
  }

  /// delete a previously cached scene
  void clearCachedScene(String sceneId) {
    assert(_cached.containsKey(sceneId), 'scene [$sceneId] not found!');

    _cached.remove(sceneId);
    if (_sceneStack.contains(sceneId)) {
      _sceneStack.remove(sceneId);
      _cachedArguments.remove(sceneId);
    }
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
    dynamic arguments,
    bool triggerOnStart = false,
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
    _sceneStack.removeWhere((key) => key != except);
    _cachedArguments.removeWhere((key, value) => key != except);
    scene = null;
    if (except != null) {
      assert(_cached.containsKey(except), 'scene [$except] not found!');

      if (arguments != null) {
        _cachedArguments[except] = arguments;
      } else {
        arguments ??= _cachedArguments[except];
      }

      scene = await switchScene(except,
          arguments: arguments, triggerOnStart: triggerOnStart);
    }

    if (kDebugMode) {
      info('cleared all scenes${except != null ? ', except [$except]' : ''}');
    }
    notifyListeners();
  }
}
