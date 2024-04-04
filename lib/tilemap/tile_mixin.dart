import 'package:quiver/core.dart';

import '../components/game_component.dart';

class TilePosition {
  int left, top;

  TilePosition(this.left, this.top);
  TilePosition.leftTop() : this(1, 1);

  @override
  String toString() => '[$left, $top]';

  @override
  int get hashCode {
    return hashObjects([left, top]);
  }

  @override
  bool operator ==(Object other) {
    if (other is TilePosition) {
      return other.left == left && other.top == top;
    }
    return false;
  }
}

enum TileShape {
  orthogonal,
  isometric,
  hexagonalVertical,
  hexagonalHorizontal,
}

enum TileRenderDirection {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  bottomCenter,
}

mixin TileInfo on GameComponent {
  TileShape tileShape = TileShape.hexagonalVertical;
  Vector2 gridSize = Vector2.zero();
  Vector2 srcSize = Vector2.zero();

  /// the tile index of the terrain array
  int index = 0;
  // int tileMapWidth = 0;
  Vector2 offset = Vector2.zero();
  TilePosition tilePosition = TilePosition.leftTop();
  Vector2 renderPosition = Vector2.zero();

  /// 画布位置，不要和tilemap的tile坐标混淆
  Vector2 centerPosition = Vector2.zero();

  int get left => tilePosition.left;
  int get top => tilePosition.top;
}
