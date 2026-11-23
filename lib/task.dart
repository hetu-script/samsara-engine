import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:hetu_script/utils/uid.dart';

class TaskCancelledException implements Exception {
  const TaskCancelledException();

  @override
  String toString() => 'Task cancelled.';
}

/// Runs a function asynchronously.
///
/// Callbacks registered through this function are always executed in order and
/// are guaranteed to run after the previous registered function is completed.

mixin class TaskController {
  static const _generationZoneKey = #samsaraTaskGeneration;

  final LinkedHashMap<String, Completer> _scheduleTasks =
      LinkedHashMap<String, Completer>();

  int _generation = 0;

  bool get isCurrentTaskContext {
    final generation = Zone.current[_generationZoneKey];
    return generation == null || generation == _generation;
  }

  /// check wether a task id exists.
  bool hasTask(String id) => _scheduleTasks.containsKey(id);

  bool hasTaskAfter(String id) {
    var found = false;
    for (final taskId in _scheduleTasks.keys) {
      if (found) return true;
      if (taskId == id) found = true;
    }
    return false;
  }

  void clearAllTasks() => _scheduleTasks.clear();

  void cancelAllTasks() {
    _generation++;
    final tasks = _scheduleTasks.values.toList();
    _scheduleTasks.clear();
    for (final completer in tasks) {
      if (completer.isCompleted) continue;
      completer.future.catchError((Object error) {
        if (error is TaskCancelledException) return null;
        throw error;
      });
      completer.completeError(const TaskCancelledException());
    }
  }

  /// manually complete a task.
  void completeTask(String taskId, [dynamic result]) {
    assert(_scheduleTasks.containsKey(taskId));
    final completer = _scheduleTasks[taskId]!;
    if (completer.isCompleted) return;
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
    if (!isCurrentTaskContext) return null;
    final previousTask = _scheduleTasks.values.lastOrNull;

    final taskId = id ?? randomUID(withTime: true);
    if (_scheduleTasks.containsKey(taskId)) {
      if (kDebugMode) {
        print('Task controller warning: Task $taskId already exists.');
      }
      return null;
    }

    final generation = _generation;
    final completer = Completer<T>();
    _scheduleTasks[taskId] = completer;

    Future<void> handleTask() async {
      if (generation != _generation) return;
      final result = await task();
      if (generation != _generation ||
          !_scheduleTasks.containsKey(taskId)) {
        return;
      }
      if (isAuto) {
        completeTask(taskId, result);
      }
    }

    void runTaskInGeneration() {
      runZoned(
        () {
          if (generation == _generation) handleTask();
        },
        zoneValues: {_generationZoneKey: generation},
      );
    }

    if (previousTask != null) {
      if (previousTask.isCompleted) {
        runTaskInGeneration();
      } else {
        previousTask.future.then(
          (value) => runTaskInGeneration(),
          onError: (Object error, StackTrace stackTrace) {
            if (error is TaskCancelledException) return;
            Error.throwWithStackTrace(error, stackTrace);
          },
        );
      }
    } else {
      runTaskInGeneration();
    }

    return completer.future;
  }
}
