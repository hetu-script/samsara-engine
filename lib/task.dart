import 'dart:async';

/// Runs a function asynchronously.
///
/// Callbacks registered through this function are always executed in order and
/// are guaranteed to run after the previous registered function is completed.

abstract class Task {
  static final List<Completer> _scheduleTasks = [];

  static void clearAll() {
    _scheduleTasks.clear();
  }

  /// add a task to be executed after all previous task is completed.
  static Future<T?> schedule<T>(FutureOr<T?> Function() task) {
    final previousTask = _scheduleTasks.isNotEmpty ? _scheduleTasks.last : null;

    final completer = Completer<T?>();
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
