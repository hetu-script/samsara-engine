import 'dart:async';

/// Runs a function asynchronously.
///
/// Callbacks registered through this function are always executed in order and
/// are guaranteed to run after the previous registered function is completed.

class TaskController {
  final List<Completer> _scheduleTasks = [];

  void clearAll() {
    _scheduleTasks.clear();
  }

  /// add a task to be executed after all previous task is completed.
  Future<T> schedule<T>(FutureOr<T> Function() task) {
    final previousTask = _scheduleTasks.isNotEmpty ? _scheduleTasks.last : null;

    final completer = Completer<T>();
    _scheduleTasks.add(completer);

    Future<void> handleTask() async {
      final r = await task();
      completer.complete(r);
    }

    if (previousTask != null && !previousTask.isCompleted) {
      previousTask.future.then((value) {
        handleTask();
      });
    } else {
      handleTask();
    }

    return completer.future;
  }
}

mixin HasTaskController {
  final TaskController _taskController = TaskController();

  Future<T> schedule<T>(FutureOr<T> Function() task) =>
      _taskController.schedule(task);
}
