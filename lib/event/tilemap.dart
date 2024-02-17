import 'dart:ui';

import 'event.dart';
import '../tilemap/tile.dart';

abstract class MapEvents {
  static const loadedMap = 'loaded_map';
  static const loadedMaze = 'loaded_maze';
  static const mapTapped = 'map_tapped';
  static const mapDoubleTapped = 'map_double_tapped';
  static const mapLongPressed = 'map_long_pressed';
  static const heroMoved = 'hero_moved_on_worldmap';
}

class MapLoadedEvent extends GameEvent {
  final bool isFirstLoad;

  const MapLoadedEvent({this.isFirstLoad = false})
      : super(name: MapEvents.loadedMap);
}

class MapInteractionEvent extends GameEvent {
  final Offset globalPosition;

  final int buttons;

  final TilePosition tilePosition;

  const MapInteractionEvent.mapTapped({
    required this.globalPosition,
    required this.buttons,
    required this.tilePosition,
  }) : super(name: MapEvents.mapTapped);

  const MapInteractionEvent.mapDoubleTapped({
    required this.globalPosition,
    required this.buttons,
    required this.tilePosition,
  }) : super(name: MapEvents.mapDoubleTapped);

  const MapInteractionEvent.mapLongPressed({
    required this.globalPosition,
    required this.buttons,
    required this.tilePosition,
  }) : super(name: MapEvents.mapLongPressed);
}

class HeroEvent extends GameEvent {
  final TilePosition tilePosition;

  const HeroEvent.heroMoved({
    required String sceneId,
    required this.tilePosition,
  }) : super(name: MapEvents.heroMoved, scene: sceneId);
}

class MazeLoadedEvent extends GameEvent {
  const MazeLoadedEvent() : super(name: MapEvents.loadedMaze);
}
