import 'package:flame/components.dart';
import 'tile_mixin.dart';

class TileMapRouteNode {
  final int index;
  final TilePosition tilePosition;
  final Vector2 worldPosition;

  TileMapRouteNode({
    required this.index,
    required this.tilePosition,
    required this.worldPosition,
  });
}
