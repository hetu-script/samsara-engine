import 'dart:ui';

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

  TilePosition _tilePosition = TilePosition.leftTop();
  Vector2 _renderSize = Vector2.zero();
  Vector2 get renderSize => _renderSize;
  set renderSize(Vector2 value) {
    _renderSize = value;
    _bottomRightRenderRect = Vector2(
      _renderPosition.x + _renderSize.x,
      _renderPosition.y + _renderSize.y,
    );
  }

  Vector2 _bottomRightRenderRect = Vector2.zero();
  Vector2 get bottomRightRenderRect => _bottomRightRenderRect;

  Vector2 _renderPosition = Vector2.zero();
  Vector2 get renderPosition => _renderPosition;
  set renderPosition(Vector2 value) {
    _renderPosition = value;
    _renderPosition2 = Vector2(
      _renderPosition.x + _offset.x,
      _renderPosition.y + _offset.y,
    );
    _bottomRightRenderRect = Vector2(
      _renderPosition.x + _renderSize.x,
      _renderPosition.y + _renderSize.y,
    );
  }

  Vector2 _renderPosition2 = Vector2.zero();
  Vector2 get renderPosition2 => _renderPosition2;

  Vector2 _offset = Vector2.zero();
  Vector2 get offset => _offset;

  set offset(Vector2 value) {
    _offset = value;
    _renderPosition2 = Vector2(
      renderPosition.x + _offset.x,
      renderPosition.y + _offset.y,
    );
  }

  /// 画布位置，不要和tilemap的tile坐标混淆
  Vector2 centerPosition = Vector2.zero();

  int get left => _tilePosition.left;
  int get top => _tilePosition.top;
  TilePosition get tilePosition => _tilePosition;

  // 切换为 horizontal hexgonal tile map 的坐标系
  // 用于距离计算的函数
  // slashLeft: 以 (1, 1) 为原点，该格子相对向右下行的斜线的距离
  // slashTop: 以 (1, 1) 为原点，该格子相对向右上行的斜线的距离
  int slashLeft = 0, slashTop = 0;

  set left(int value) {
    _tilePosition.left = value;

    slashLeft = ((left.isOdd ? (left + 1) / 2 : left / 2) - top).truncate();
  }

  set top(int value) {
    _tilePosition.top = value;

    slashTop = left - slashLeft - 1;
  }

  set tilePosition(TilePosition value) {
    _tilePosition = value;

    slashLeft = ((left.isOdd ? (left + 1) / 2 : left / 2) - top).truncate();
    slashTop = left - slashLeft - 1;
  }

  final borderPath = Path();
  Map<int, Path> innerBorderPaths = {};
  // final shadowPath = Path();
}
