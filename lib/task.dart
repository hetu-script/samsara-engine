import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:hetu_script/utils/uid.dart';

/// Runs a function asynchronously.
///
/// Callbacks registered through this function are always executed in order and
/// are guaranteed to run after the previous registered function is completed.

mixin class TaskController {
  final LinkedHashMap<String, Completer> _scheduleTasks =
      LinkedHashMap<String, Completer>();

  /// check wether a task id exists.
  bool hasTask(String id) => _scheduleTasks.containsKey(id);

  void clearAllTasks() => _scheduleTasks.clear();

  /// manually complete a task.
  void completeTask(String taskId, [dynamic result]) {
    assert(_scheduleTasks.containsKey(taskId));
    final completer = _scheduleTasks[taskId]!;
    completer.complete(result);
    for (final key in _scheduleTasks.keys.toList()) {
      _scheduleTasks.remove(key);
      if (key == taskId) {
        break;
      }
    }
  }

  /// add a task to be executed after all previous task is completed.
  Future<T>? schedule<T>(FutureOr<T> Function() task,
      {bool isAuto = true, String? id}) {
    final previousTask = _scheduleTasks.values.lastOrNull;

    final taskId = id ?? randomUID(withTime: true);
    if (_scheduleTasks.containsKey(taskId)) {
      if (kDebugMode) {
        print('Task controller warning: Task $taskId already exists.');
      }
      return null;
    }

    final completer = Completer<T>();
    _scheduleTasks[taskId] = completer;

    Future<void> handleTask() async {
      final result = await task();
      if (isAuto) {
        completeTask(taskId, result);
      }
    }

    if (previousTask != null) {
      if (previousTask.isCompleted) {
        handleTask();
      } else {
        previousTask.future.then((value) {
          handleTask();
        });
      }
    } else {
      handleTask();
    }

    return completer.future;
  }
}
