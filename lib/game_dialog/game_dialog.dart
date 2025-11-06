import 'dart:collection';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hetu_script/values.dart';
import 'package:samsara/task.dart';
import 'package:hetu_script/utils/uid.dart';

class IllustrationInfo {
  final String path;
  final double offsetX, offsetY;
  bool isFadeOut;

  IllustrationInfo(
    this.path, {
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.isFadeOut = false,
  });
}

class SceneInfo {
  final String path;
  final bool isFadeIn;
  bool isFadeOut;
  String? taskId;

  SceneInfo(
    this.path, {
    this.isFadeIn = false,
    this.isFadeOut = false,
    this.taskId,
  });
}

class GameDialog with ChangeNotifier, TaskController {
  bool isOpened = false;

  /// key是图片的asset路径
  final Set<SceneInfo> scenes = {};
  SceneInfo? get currentSceneInfo => scenes.lastOrNull;
  SceneInfo? prevScene;

  /// key是图片的asset路径，value是图片x坐标的偏移值
  final Set<IllustrationInfo> illustrations = {};
  final Map<String, dynamic> contents = {};
  dynamic get currentContent => contents.values.lastOrNull;

  dynamic selectionsData;

  final storedValues = <String, dynamic>{};

  void loadValues(Map<String, dynamic> values) {
    storedValues.clear();
    storedValues.addAll(values);
  }

  dynamic getValue(String key) {
    return storedValues[key];
  }

  Future<void>? execute() {
    return schedule(() {
      isOpened = false;
      prevScene = null;
      illustrations.clear();
      scenes.clear();
      contents.clear();
      selectionsData = null;
      notifyListeners();
    }, id: 'execution_to_end');
  }

  void pushBackground(String imageId, {bool isFadeIn = false}) {
    isOpened = true;
    final taskId = 'push_background_${randomUID(withTime: true)}';
    schedule(
      () {
        if (scenes.isNotEmpty) {
          prevScene = scenes.last;
        }
        scenes.add(SceneInfo(
          'assets/images/$imageId',
          isFadeIn: isFadeIn,
          taskId: taskId,
        ));
        notifyListeners();
      },
      id: taskId,
      isAuto: !isFadeIn,
    );
  }

  void popBackground({String? imageId, isFadeOut = false}) {
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
          prevScene!.isFadeOut = isFadeOut;
          prevScene!.taskId = taskId;
        }
        scenes.remove(prevScene);
        notifyListeners();
      },
      id: taskId,
      isAuto: !isFadeOut,
    );
  }

  void popAllBackgrounds() {
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
  }) {
    isOpened = true;
    final taskId = 'push_image_${randomUID(withTime: true)}';
    schedule(
      () {
        illustrations.add(IllustrationInfo(
          'assets/images/$imageId',
          offsetX: offsetX,
          offsetY: offsetY,
        ));
        notifyListeners();
      },
      id: taskId,
    );
  }

  void popImage({String? imageId}) {
    // assert(isOpened == true);
    final taskId = 'pop_image_${randomUID(withTime: true)}';
    schedule(
      () {
        assert(illustrations.isNotEmpty,
            'game dialog: pop image failed, no image to pop.');
        if (imageId != null) {
          illustrations
              .removeWhere((img) => img.path == 'assets/images/$imageId');
        } else if (illustrations.isNotEmpty) {
          illustrations.remove(illustrations.last);
        }
        notifyListeners();
      },
      id: taskId,
    );
  }

  void popAllImages() {
    // assert(isOpened == true);
    final taskId = 'pop_all_images_${randomUID(withTime: true)}';
    schedule(
      () {
        assert(illustrations.isNotEmpty,
            'game dialog: pop image failed, no image to pop.');
        illustrations.clear();
        notifyListeners();
      },
      id: taskId,
    );
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
    isOpened = true;
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
    isOpened = true;
    final taskId = 'push_task_${randomUID(withTime: true)}';
    schedule(task, id: taskId)?.then((result) {
      if (flagId != null) {
        storedValues[flagId] = result;
      }
    });
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
    // assert(isOpened == true);
    storedValues[dataId] = value;
    selectionsData = null;
    assert(hasTask(taskId));
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
