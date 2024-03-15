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

enum TileMapDirectionHexagonal {
  north,
  northEast,
  southEast,
  south,
  southWest,
  northWest,
}

enum TileMapDirectionOrthogonal {
  north,
  east,
  south,
  west,
}

TileMapDirectionHexagonal direction2Hexagonal(TileMapDirection direction) {
  switch (direction) {
    case TileMapDirection.north:
      return TileMapDirectionHexagonal.north;
    case TileMapDirection.south:
      return TileMapDirectionHexagonal.south;
    case TileMapDirection.northEast:
      return TileMapDirectionHexagonal.northEast;
    case TileMapDirection.southEast:
      return TileMapDirectionHexagonal.southEast;
    case TileMapDirection.northWest:
      return TileMapDirectionHexagonal.northWest;
    case TileMapDirection.southWest:
      return TileMapDirectionHexagonal.southWest;
    default:
      throw 'Hexagonal map tile direction should never be $direction';
  }
}

TileMapDirectionOrthogonal direction2Orthogonal(TileMapDirection direction) {
  switch (direction) {
    case TileMapDirection.north:
      return TileMapDirectionOrthogonal.north;
    case TileMapDirection.south:
      return TileMapDirectionOrthogonal.south;
    case TileMapDirection.east:
      return TileMapDirectionOrthogonal.east;
    case TileMapDirection.west:
      return TileMapDirectionOrthogonal.west;
    case TileMapDirection.northEast:
      return TileMapDirectionOrthogonal.east;
    case TileMapDirection.southEast:
      return TileMapDirectionOrthogonal.east;
    case TileMapDirection.northWest:
      return TileMapDirectionOrthogonal.west;
    case TileMapDirection.southWest:
      return TileMapDirectionOrthogonal.west;
  }
}
