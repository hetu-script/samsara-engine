import 'package:flutter/foundation.dart';

export 'package:flutter/foundation.dart' show Key;

class EventHandler {
  final Key widgetKey;

  final void Function(String id, dynamic args, String? scene) callback;

  EventHandler({required this.widgetKey, required this.callback});
}

mixin EventAggregator {
  final _eventHandlers = <String, List<EventHandler>>{};

  void addEventListener(String eventId, EventHandler eventHandler) {
    if (_eventHandlers[eventId] == null) {
      _eventHandlers[eventId] = [];
    }
    _eventHandlers[eventId]!.add(eventHandler);
  }

  void removeEventListener(Key key) {
    for (final list in _eventHandlers.values) {
      list.removeWhere((handler) => handler.widgetKey == key);
    }
  }

  void emit(String id, {dynamic args, String? scene}) {
    final listeners = _eventHandlers[id];
    if (listeners != null) {
      for (final listener in listeners) {
        listener.callback(id, args, scene);
      }
    }
  }
}
