import 'dart:async';

/// A schedule task system.
///
/// In dart, if you call multiple async function within a sync function
/// without await keyword, they will be running parallelly.
///
/// The code in this file make sure a task is executed after the previous
/// tasks are fully resolved.

abstract class Task {
  static final List<Completer> _sheduleTasks = [];

  static void clearAll() {
    _sheduleTasks.clear();
  }

  /// add a task to be executed after all previous task is completed.
  static Future<T?> schedule<T>(FutureOr<T?> Function() task) async {
    final completer = Completer<T?>();
    final index = _sheduleTasks.length;
    _sheduleTasks.add(completer);

    Future<void> waitPreviousTasks() async {
      for (var i = 0; i < index; ++i) {
        final c = _sheduleTasks[i];
        if (!c.isCompleted) {
          await c.future;
        }
      }
      final r = await task();
      completer.complete(r);
    }

    waitPreviousTasks();

    return completer.future;
  }
}
