import 'package:flutter/foundation.dart';

export 'package:flutter/foundation.dart' show Key;

class GameEvent {
  final String name;
  final String? scene;

  const GameEvent({required this.name, this.scene});
}

class EventHandler {
  final Key ownerKey;

  final void Function(GameEvent event) handle;

  EventHandler({required this.ownerKey, required this.handle});
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
      list.removeWhere((handler) => handler.ownerKey == key);
    }
  }

  void emit(GameEvent event) {
    final listeners = _eventHandlers[event.name];
    if (listeners != null) {
      for (final listener in listeners) {
        listener.handle(event);
      }
    }
  }
}
