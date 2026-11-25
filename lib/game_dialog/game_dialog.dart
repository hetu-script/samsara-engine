import 'dart:collection';
import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hetu_script/values.dart';
import 'package:samsara/task.dart';
import 'package:hetu_script/utils/uid.dart';

enum DialogRunResult { completed, cancelled }

class ScreenHintInfo {
  final double left, top, width, height;
  final String? text;
  final String? taskId;
  final void Function()? onTap;
  final MouseCursor? cursor;

  ScreenHintInfo({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.text,
    this.taskId,
    this.onTap,
    this.cursor,
  });
}

class IllustrationInfo {
  final String path;
  final double offsetX, offsetY;
  final bool isFadeIn;
  Duration fadeDuration;
  bool isFadeOut;
  String? taskId;

  IllustrationInfo(
    this.path, {
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.isFadeIn = false,
    this.isFadeOut = false,
    this.fadeDuration = const Duration(milliseconds: 800),
    this.taskId,
  });
}

class SceneMotion {
  final Duration duration;
  final Curve curve;
  final double beginScale, endScale;
  final Offset beginOffset, endOffset;
  final Duration? fadeDuration;

  const SceneMotion({
    required this.duration,
    this.curve = Curves.linear,
    this.beginScale = 1.0,
    this.endScale = 1.0,
    this.beginOffset = Offset.zero,
    this.endOffset = Offset.zero,
    this.fadeDuration,
  });
}

class SceneInfo {
  final String path;
  final bool isFadeIn;
  final SceneMotion? motion;
  Duration fadeDuration;
  bool isFadeOut;
  String? taskId;

  SceneInfo(
    this.path, {
    this.isFadeIn = false,
    this.isFadeOut = false,
    this.motion,
    this.fadeDuration = const Duration(milliseconds: 800),
    this.taskId,
  });
}

class SceneShadeInfo {
  final double fromOpacity, targetOpacity;
  final Duration duration;
  final String taskId;

  const SceneShadeInfo({
    required this.fromOpacity,
    required this.targetOpacity,
    required this.duration,
    required this.taskId,
  });
}

class GameDialog with ChangeNotifier, TaskController {
  bool isOpened = false;
  bool presentationPaused = false;
  double sceneShadeOpacity = 0;
  SceneShadeInfo? sceneShade;

  /// key是图片的asset路径
  final Set<SceneInfo> scenes = {};
  SceneInfo? get currentSceneInfo => scenes.lastOrNull;
  SceneInfo? prevScene;

  /// key是图片的asset路径，value是图片x坐标的偏移值
  final Set<IllustrationInfo> illustrations = {};
  IllustrationInfo? prevIllustration;
  final Map<String, dynamic> contents = {};
  dynamic get currentContent => contents.values.lastOrNull;

  dynamic selectionsData;

  ScreenHintInfo? screenHintInfo;

  final storedValues = <String, dynamic>{};

  void loadValues(Map<String, dynamic> values) {
    storedValues.clear();
    storedValues.addAll(values);
  }

  dynamic getValue(String key) {
    return storedValues[key];
  }

  Future<DialogRunResult>? execute() {
    if (!isCurrentTaskContext) {
      return Future.value(DialogRunResult.cancelled);
    }
    if (hasTask('execution_to_end')) return null;
    final completer = Completer<DialogRunResult>();
    _scheduleExecutionCleanup(completer, 'execution_to_end');
    return completer.future;
  }

  void _scheduleExecutionCleanup(
    Completer<DialogRunResult> completer,
    String taskId,
  ) {
    schedule(() {
      if (hasTaskAfter(taskId)) {
        _scheduleExecutionCleanup(
          completer,
          'execution_to_end_${randomUID(withTime: true)}',
        );
        return;
      }
      isOpened = false;
      presentationPaused = false;
      sceneShadeOpacity = 0;
      sceneShade = null;
      prevScene = null;
      prevIllustration = null;
      illustrations.clear();
      scenes.clear();
      contents.clear();
      selectionsData = null;
      screenHintInfo = null;
      notifyListeners();
      if (!completer.isCompleted) {
        completer.complete(DialogRunResult.completed);
      }
    }, id: taskId)
        ?.then(
      (_) {},
      onError: (Object error) {
        if (completer.isCompleted) return;
        if (error is TaskCancelledException) {
          completer.complete(DialogRunResult.cancelled);
        } else {
          completer.completeError(error);
        }
      },
    );
  }

  void reset({bool clearStoredValues = true}) {
    cancelAllTasks();
    isOpened = false;
    presentationPaused = false;
    sceneShadeOpacity = 0;
    sceneShade = null;
    prevScene = null;
    prevIllustration = null;
    illustrations.clear();
    scenes.clear();
    contents.clear();
    selectionsData = null;
    screenHintInfo = null;
    if (clearStoredValues) storedValues.clear();
    notifyListeners();
  }

  void setPresentationPaused(bool paused) {
    if (presentationPaused == paused) return;
    presentationPaused = paused;
    notifyListeners();
  }

  void setSceneShade(
    double opacity, {
    Duration duration = const Duration(milliseconds: 800),
    bool waitForTransition = true,
  }) {
    if (!isCurrentTaskContext) return;
    assert(opacity >= 0 && opacity <= 1);
    isOpened = true;
    final taskId = 'scene_shade_${randomUID(withTime: true)}';
    final animated = duration > Duration.zero;
    schedule(
      () {
        sceneShade = SceneShadeInfo(
          fromOpacity: sceneShadeOpacity,
          targetOpacity: opacity,
          duration: duration,
          taskId: taskId,
        );
        if (!animated) {
          sceneShadeOpacity = opacity;
          sceneShade = null;
        }
        notifyListeners();
      },
      id: taskId,
      isAuto: !(animated && waitForTransition),
    );
  }

  void completeSceneShade(SceneShadeInfo info) {
    if (sceneShade != info) return;
    sceneShadeOpacity = info.targetOpacity;
    sceneShade = null;
    finishTask(info.taskId);
    notifyListeners();
  }

  void completeSceneTransition(SceneInfo info) {
    if (prevScene == info && info.isFadeOut) {
      prevScene = null;
      notifyListeners();
    }
    final taskId = info.taskId;
    if (taskId != null) finishTask(taskId);
  }

  void completeIllustrationTransition(IllustrationInfo info) {
    if (prevIllustration == info && info.isFadeOut) {
      prevIllustration = null;
      notifyListeners();
    }
    final taskId = info.taskId;
    if (taskId != null) finishTask(taskId);
  }

  void pushBackground(
    String imageId, {
    bool isFadeIn = false,
    SceneMotion? motion,
    Duration fadeDuration = const Duration(milliseconds: 800),
    bool waitForTransition = true,
  }) {
    if (!isCurrentTaskContext) return;
    isOpened = true;
    final taskId = 'push_background_${randomUID(withTime: true)}';
    final animated = isFadeIn || motion != null;
    schedule(
      () {
        if (scenes.isNotEmpty) {
          prevScene = scenes.last;
        }
        scenes.add(SceneInfo(
          'assets/images/$imageId',
          isFadeIn: isFadeIn,
          motion: motion,
          fadeDuration: fadeDuration,
          taskId: taskId,
        ));
        notifyListeners();
      },
      id: taskId,
      isAuto: !(animated && waitForTransition),
    );
  }

  void popBackground({
    String? imageId,
    bool isFadeOut = false,
    Duration fadeDuration = const Duration(milliseconds: 800),
    bool waitForTransition = true,
  }) {
    if (!isCurrentTaskContext) return;
    // assert(isOpened == true);
    final taskId = 'pop_background_${randomUID(withTime: true)}';
    schedule(
      () {
        assert(scenes.isNotEmpty,
            'game dialog: pop background failed, no background to pop. imageId: $imageId');
        if (imageId != null) {
          prevScene = scenes.singleWhere(
            (scene) => scene.path == 'assets/images/$imageId',
            orElse: () => scenes.last,
          );
        } else {
          prevScene = scenes.last;
        }
        if (isFadeOut) {
          prevScene!
            ..isFadeOut = true
            ..fadeDuration = fadeDuration
            ..taskId = taskId;
        }
        scenes.remove(prevScene);
        notifyListeners();
      },
      id: taskId,
      isAuto: !(isFadeOut && waitForTransition),
    );
  }

  void popAllBackgrounds() {
    if (!isCurrentTaskContext) return;
    // assert(isOpened == true);
    final taskId = 'pop_all_backgrounds_${randomUID(withTime: true)}';
    schedule(
      () {
        assert(scenes.isNotEmpty,
            'game dialog: pop background failed, no background to pop.');
        if (scenes.isNotEmpty) {
          prevScene = scenes.last;
        }
        scenes.clear();
        notifyListeners();
      },
      id: taskId,
    );
  }

  void pushImage(
    String imageId, {
    double offsetX = 0.0,
    double offsetY = 0.0,
    bool isFadeIn = false,
    Duration fadeDuration = const Duration(milliseconds: 800),
    bool waitForTransition = true,
  }) {
    if (!isCurrentTaskContext) return;
    isOpened = true;
    final taskId = 'push_image_${randomUID(withTime: true)}';
    schedule(
      () {
        illustrations.add(IllustrationInfo(
          'assets/images/$imageId',
          offsetX: offsetX,
          offsetY: offsetY,
          isFadeIn: isFadeIn,
          fadeDuration: fadeDuration,
          taskId: taskId,
        ));
        notifyListeners();
      },
      id: taskId,
      isAuto: !(isFadeIn && waitForTransition),
    );
  }

  void popImage({
    String? imageId,
    bool isFadeOut = false,
    Duration fadeDuration = const Duration(milliseconds: 800),
    bool waitForTransition = true,
  }) {
    if (!isCurrentTaskContext) return;
    // assert(isOpened == true);
    final taskId = 'pop_image_${randomUID(withTime: true)}';
    schedule(
      () {
        assert(illustrations.isNotEmpty,
            'game dialog: pop image failed, no image to pop.');
        IllustrationInfo? target;
        if (imageId != null) {
          final path = 'assets/images/$imageId';
          for (final info in illustrations) {
            if (info.path == path) target = info;
          }
        } else if (illustrations.isNotEmpty) {
          target = illustrations.last;
        }
        if (target != null) {
          prevIllustration = target;
          if (isFadeOut) {
            target
              ..isFadeOut = true
              ..fadeDuration = fadeDuration
              ..taskId = taskId;
          }
          illustrations.remove(target);
        }
        notifyListeners();
      },
      id: taskId,
      isAuto: !(isFadeOut && waitForTransition),
    );
  }

  void popAllImages({
    bool isFadeOut = false,
    Duration fadeDuration = const Duration(milliseconds: 800),
    bool waitForTransition = true,
  }) {
    if (!isCurrentTaskContext) return;
    // assert(isOpened == true);
    final taskId = 'pop_all_images_${randomUID(withTime: true)}';
    schedule(
      () {
        assert(illustrations.isNotEmpty,
            'game dialog: pop image failed, no image to pop.');
        if (illustrations.isNotEmpty) {
          prevIllustration = illustrations.last;
          if (isFadeOut) {
            prevIllustration!
              ..isFadeOut = true
              ..fadeDuration = fadeDuration
              ..taskId = taskId;
          }
        }
        illustrations.clear();
        notifyListeners();
      },
      id: taskId,
      isAuto: !(isFadeOut && waitForTransition),
    );
  }

  void pushScreenHint({
    required Rect rect,
    String? text,
    void Function()? onTap,
    MouseCursor? cursor,
  }) {
    if (!isCurrentTaskContext) return;
    isOpened = true;
    final taskId = 'push_screen_hint_${randomUID(withTime: true)}';
    schedule(
      () {
        screenHintInfo = ScreenHintInfo(
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height,
          text: text,
          taskId: taskId,
          onTap: onTap,
          cursor: cursor,
        );
        notifyListeners();
      },
      id: taskId,
      isAuto: false,
    );
  }

  void finishScreenHint() {
    final tid = screenHintInfo?.taskId;
    screenHintInfo = null;
    if (tid != null && hasTask(tid)) {
      completeTask(tid);
    }
    notifyListeners();
  }

  /// 按原始数据推送游戏对话，格式如下
  /// ```javascript
  /// {
  ///   name: string,
  ///   icon: icon,
  ///   image: string,
  ///   lines: []string,
  /// }
  /// ```
  void pushDialogRaw(dynamic content, {String? imageId}) {
    if (!isCurrentTaskContext) return;
    isOpened = true;
    if (imageId != null) {
      pushImage(imageId);
    }
    assert(content != null);
    final resolved = <String, dynamic>{};

    if (content is String) {
      resolved['lines'] = [content];
    } else if (content is List) {
      resolved['lines'] = content;
    } else if (content is Map || content is HTStruct) {
      resolved.addAll(content);
    } else {
      throw 'Dialog.pushDialogRaw: content must be a String, List<String>, Map or HTStruct. $content';
    }
    final taskId = 'push_dialog_${randomUID(withTime: true)}';
    resolved['id'] = taskId;
    schedule(
      () {
        contents[taskId] = resolved;
        notifyListeners();
      },
      id: taskId,
      isAuto: false,
    );
    if (imageId != null) {
      popImage(imageId: imageId);
    }
  }

  void finishDialog(String id) {
    // assert(isOpened == true);
    // assert(contents.containsKey(id));
    contents.remove(id);
    finishTask(id);
    notifyListeners();
  }

  void finishTask(String id) {
    if (hasTask(id)) {
      completeTask(id);
    }
  }

  void pushTask(FutureOr<dynamic> Function() task, {String? flagId}) {
    if (!isCurrentTaskContext) return;
    isOpened = true;
    final taskId = 'push_task_${randomUID(withTime: true)}';
    schedule(task, id: taskId)?.then(
      (result) {
        if (flagId != null && isCurrentTaskContext) {
          storedValues[flagId] = result;
        }
      },
      onError: (Object error) {
        if (error is TaskCancelledException) return;
        throw error;
      },
    );
  }

  /// 按原始数据推送选择对话框，格式如下：
  /// ```
  /// {
  ///   // 用于稍后取出玩家选择的 key
  ///   id: 'selection_id',
  ///   selections: {
  ///     // 可以只有一个单独的文本
  ///     selectKey1: 'localedText1',
  ///     // 也可以是文本加一个描述文本
  ///     selectKey2: { text: 'localedText3', description: 'localedText4' },
  ///   }
  /// }
  void pushSelectionRaw(dynamic selectionsData) {
    assert(selectionsData is HTStruct || selectionsData is Map,
        'invalid selection data. $selectionsData');
    final taskId = 'push_selection_${randomUID(withTime: true)}';
    if (!isCurrentTaskContext) return;
    isOpened = true;
    schedule(
      () {
        selectionsData['taskId'] = taskId;
        this.selectionsData = selectionsData;
        notifyListeners();
      },
      id: taskId,
      isAuto: false,
    );
  }

  void finishSelection(String taskId, String dataId, {dynamic value}) {
    if (!hasTask(taskId)) return;
    storedValues[dataId] = value;
    selectionsData = null;
    completeTask(taskId);
    notifyListeners();
  }

  /// 根据当前选择分支执行任务
  dynamic checkSelected(dynamic data) {
    bool satisfied = true;
    if (data is List) {
      for (final key in data) {
        if (storedValues[key.toString()] != true) {
          satisfied = false;
          break;
        }
      }
      return satisfied;
    } else if (data is HTStruct || data is Map) {
      for (final key in data.keys) {
        final value = data[key];
        if (storedValues[key.toString()] != value) {
          satisfied = false;
          break;
        }
      }
      return satisfied;
    } else if (data is String) {
      return storedValues[data];
    } else {
      if (kDebugMode) {
        print('game dialog: invalid selected value data: $data');
      }
      return null;
    }
  }
}
