enum TileMapDirection {
  north,
  northEast,
  east,
  southEast,
  south,
  southWest,
  west,
  northWest,
}

enum HexagonalVerticalDirection {
  north,
  northEast,
  southEast,
  south,
  southWest,
  northWest,
}

enum OrthogonalDirection {
  north,
  east,
  south,
  west,
}

HexagonalVerticalDirection direction2Hexagonal(TileMapDirection direction) {
  switch (direction) {
    case TileMapDirection.north:
      return HexagonalVerticalDirection.north;
    case TileMapDirection.south:
      return HexagonalVerticalDirection.south;
    case TileMapDirection.northEast:
      return HexagonalVerticalDirection.northEast;
    case TileMapDirection.southEast:
      return HexagonalVerticalDirection.southEast;
    case TileMapDirection.northWest:
      return HexagonalVerticalDirection.northWest;
    case TileMapDirection.southWest:
      return HexagonalVerticalDirection.southWest;
    default:
      throw 'Hexagonal map tile direction should never be $direction';
  }
}

OrthogonalDirection direction2Orthogonal(TileMapDirection direction) {
  switch (direction) {
    case TileMapDirection.north:
      return OrthogonalDirection.north;
    case TileMapDirection.south:
      return OrthogonalDirection.south;
    case TileMapDirection.east:
      return OrthogonalDirection.east;
    case TileMapDirection.west:
      return OrthogonalDirection.west;
    case TileMapDirection.northEast:
      return OrthogonalDirection.east;
    case TileMapDirection.southEast:
      return OrthogonalDirection.east;
    case TileMapDirection.northWest:
      return OrthogonalDirection.west;
    case TileMapDirection.southWest:
      return OrthogonalDirection.west;
  }
}
