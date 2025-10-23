import 'package:quiver/core.dart';

import '../samsara.dart';

class TilePosition {
  final int left, top;

  const TilePosition(this.left, this.top);
  const TilePosition.leftTop() : this(1, 1);

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

  // Vector2 _renderSize = Vector2.zero();
  // Vector2 get renderSize => _renderSize;
  // set renderSize(Vector2 value) {
  //   _renderSize = value;
  //   _renderBottomRight = Vector2(
  //     _renderPosition.x + _renderSize.x,
  //     _renderPosition.y + _renderSize.y,
  //   );
  // }

  // Vector2 _renderBottomRight = Vector2.zero();
  // Vector2 get renderBottomRight => _renderBottomRight;

  // Vector2 _renderPosition = Vector2.zero();
  // Vector2 get renderPosition => _renderPosition;
  // set renderPosition(Vector2 value) {
  //   _renderPosition = value;
  //   _renderBottomRight = Vector2(
  //     _renderPosition.x + _renderSize.x,
  //     _renderPosition.y + _renderSize.y,
  //   );
  // }

  // Vector2 _offset = Vector2.zero();
  // Vector2 get offset => _offset;

  Vector2 offset = Vector2.zero();

  // set offset(Vector2 value) {
  //   _offset = value;
  //   _renderPosition = Vector2(
  //     _renderPosition.x + _offset.x,
  //     _renderPosition.y + _offset.y,
  //   );
  // }

  /// 画布位置，不要和tilemap的tile坐标混淆
  // Vector2 centerPosition = Vector2.zero();

  // horizontal hexgonal tile map 的坐标系
  // 用于距离计算的函数
  // slashLeft: 以 (1, 1) 为原点，该格子相对向右下行的斜线的距离
  // slashTop: 以 (1, 1) 为原点，该格子相对向右上行的斜线的距离
  int slashLeft = 0, slashTop = 0;

  int _left = 0;
  int get left => _left;
  set left(int value) {
    _left = value;

    slashLeft = ((left.isOdd ? (left + 1) / 2 : left / 2) - top).truncate();
  }

  int _top = 0;
  int get top => _top;
  set top(int value) {
    _top = value;

    slashTop = left - slashLeft - 1;
  }

  TilePosition get tilePosition => TilePosition(_left, _top);
  set tilePosition(TilePosition value) {
    left = value.left;
    top = value.top;

    slashLeft = ((left.isOdd ? (left + 1) / 2 : left / 2) - top).truncate();
    slashTop = left - slashLeft - 1;
  }

  final borderPath = Path();
  Map<int, Path> innerBorderPaths = {};
  // final shadowPath = Path();
}
