import 'dart:async';
import 'dart:collection';
import 'package:hetu_script/utils/uid.dart';

/// Runs a function asynchronously.
///
/// Callbacks registered through this function are always executed in order and
/// are guaranteed to run after the previous registered function is completed.

mixin TaskController {
  final LinkedHashMap<String, Completer> _scheduleTasks =
      LinkedHashMap<String, Completer>();

  void clearAllTask() {
    _scheduleTasks.clear();
  }

  void clearPreviousTask(String id) {
    for (final key in _scheduleTasks.keys) {
      _scheduleTasks.remove(key);
      if (key == id) {
        break;
      }
    }
  }

  Completer? get lastTask => _scheduleTasks.values.lastOrNull;

  /// add a task to be executed after all previous task is completed.
  Future<T> schedule<T>(FutureOr<T> Function() task, [String? id]) {
    final previousTask = lastTask;

    final taskId = '${id}_${randomUID(withTime: true)}';

    final completer = Completer<T>();
    _scheduleTasks[taskId] = completer;

    Future<void> handleTask() async {
      final r = await task();
      completer.complete(r);
      clearPreviousTask(taskId);
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
