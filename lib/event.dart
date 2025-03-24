import 'package:flutter/foundation.dart';

typedef EventCallback = void Function(dynamic args);

mixin EventAggregator {
  // 第一层 key 是 eventId, 第二层 key 是 listenerId, value 是 callback
  final Map<String, Map<String, EventCallback>> _eventHandlers = {};

  void addEventListener(
      String listenerId, String eventId, EventCallback callback) {
    if (_eventHandlers[eventId] == null) {
      _eventHandlers[eventId] = <String, EventCallback>{};
    }
    final listeners = _eventHandlers[eventId]!;
    listeners[listenerId] = callback;
  }

  void removeEventListener(String listenerId) {
    for (final handlers in _eventHandlers.values) {
      handlers
          .removeWhere((registeredId, callback) => registeredId == listenerId);
    }
  }

  void emit(String eventId, [dynamic args]) {
    if (kDebugMode) {
      print('samsara - event: [$eventId], args: [$args]');
    }

    final listeners = _eventHandlers[eventId];
    if (listeners != null) {
      for (final callback in listeners.values) {
        callback.call(args);
      }
    }
  }
}
