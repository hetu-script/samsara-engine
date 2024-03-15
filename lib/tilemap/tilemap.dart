import 'dart:math' as math;

// import 'package:flame/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:samsara/extensions.dart';
// import 'package:samsara/paint.dart';

import '../component/game_component.dart';
import '../gestures/gesture_mixin.dart';
import 'tile_mixin.dart';
import 'object.dart';
import '../utils/color.dart';
import 'terrain.dart';
import 'direction.dart';
import 'route.dart';

export 'direction.dart';

// enum DestinationAction {
//   none,
//   enter,
//   check,
// }

const kColorModeNone = -1;
const _kCaptionOffset = 14.0;

class TileMap extends GameComponent with HandlesGesture {
  static late SpriteSheet terrainSpriteSheet;

  static final List<Map<int, (Color, Paint)>> zoneColors = [];

  static final selectedPaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke
    ..color = Colors.yellow;

  static final hoverPaint = Paint()
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke
    ..color = Colors.yellow.withOpacity(0.5);

  static final fogPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.black
    ..maskFilter = MaskFilter.blur(BlurStyle.solid, convertRadiusToSigma(0.5));

  static final fogNeighborPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.black.withOpacity(0.5)
    ..maskFilter = MaskFilter.blur(BlurStyle.solid, convertRadiusToSigma(0.5));

  static final uninteractablePaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.red.withOpacity(0.5);

  static final Map<Color, Paint> cachedColorPaints = {};

  String id;
  dynamic data;

  String? shadowSpriteId;
  Sprite? shadowSprite;

  void Function(Canvas canvas)? customRender;

  math.Random random;

  double scaleFactor;

  TileMap({
    required this.id,
    this.data,
    this.tileShape = TileShape.hexagonalVertical,
    this.gridWidth = 32.0,
    this.gridHeight = 28.0,
    this.tileSpriteSrcWidth = 32.0,
    this.tileSpriteSrcHeight = 64.0,
    this.tileOffsetX = 0.0,
    this.tileOffsetY = 16.0,
    this.tileObjectSpriteSrcWidth = 32.0,
    this.tileObjectSpriteSrcHeight = 48.0,
    this.scaleFactor = 2.0,
    this.showGrids = false,
    this.showSelected = false,
    this.showNonInteractableHintColor = false,
    this.showHover = false,
    this.showFogOfWar = false,
    this.autoUpdateMovingObject = false,
    required this.captionStyle,
    this.shadowSpriteId,
    this.shadowSprite,
  }) : random = math.Random() {
    scale = Vector2(scaleFactor, scaleFactor);
  }

  /// 修改 tile 的位置会连带影响很多其他属性，这里一并将其纠正
  /// 一些信息涉及到地图本身，所以不能放在tile对象上进行
  TilePosition refreshTileInfo(TileInfo tile) {
    tile.index = tilePosition2Index(tile.left, tile.top, tileMapWidth);
    // tile.tileMapWidth = tileMapWidth;
    final p = tilePosition2RenderPosition(tile.left, tile.top);
    tile.renderPosition = Vector2(p.x, p.y + tile.srcOffsetY);
    tile.worldPosition = tilePosition2TileCenterInWorld(tile.left, tile.top);
    return tile.tilePosition;
  }

  Future<void> loadData([dynamic mapData]) async {
    if (mapData != null) {
      data = mapData;
    }
    TileShape dataTileShape = TileShape.orthogonal;
    final tileShapeData = data['tileShape'];
    if (tileShapeData == 'isometric') {
      dataTileShape = TileShape.isometric;
    } else if (tileShapeData == 'hexagonalHorizontal') {
      dataTileShape = TileShape.hexagonalHorizontal;
    } else if (tileShapeData == 'hexagonalVertical') {
      dataTileShape = TileShape.hexagonalVertical;
    }
    if (tileShape != dataTileShape) {
      throw 'tile shape in loaded map data [$dataTileShape] is not the same to the tile map component [$tileShape]';
    }
    // final tapSelect = data['tapSelect'] ?? false;

    final dataGridWidth = data['gridWidth'].toDouble();
    if (gridWidth != dataGridWidth) {
      throw 'gridWidth in loaded map data [$dataGridWidth] is not the same to the tile map component [$gridWidth]';
    }

    final dataGridHeight = data['gridHeight'].toDouble();
    if (gridHeight != dataGridHeight) {
      throw 'gridWidth in loaded map data [$dataGridHeight] is not the same to the tile map component [$gridHeight]';
    }

    final dataTileSpriteSrcWidth = data['tileSpriteSrcWidth'].toDouble();
    if (tileSpriteSrcWidth != dataTileSpriteSrcWidth) {
      throw 'gridWidth in loaded map data [$dataTileSpriteSrcWidth] is not the same to the tile map component [$tileSpriteSrcWidth]';
    }

    final dataTileSpriteSrcHeight = data['tileSpriteSrcHeight'].toDouble();
    if (tileSpriteSrcHeight != dataTileSpriteSrcHeight) {
      throw 'gridWidth in loaded map data [$dataTileSpriteSrcHeight] is not the same to the tile map component [$tileSpriteSrcHeight]';
    }

    final dataTileOffsetX = data['tileOffsetX'];
    if (tileOffsetX != dataTileOffsetX) {
      throw 'gridWidth in loaded map data [$dataTileOffsetX] is not the same to the tile map component [$tileOffsetX]';
    }

    final dataTileOffsetY = data['tileOffsetY'];
    if (tileOffsetY != dataTileOffsetY) {
      throw 'gridWidth in loaded map data [$dataTileOffsetY] is not the same to the tile map component [$tileOffsetY]';
    }

    final terrainSpritePath = data['terrainSpriteSheet'];
    TileMap.terrainSpriteSheet = SpriteSheet(
      image: await Flame.images.load(terrainSpritePath),
      srcSize: Vector2(tileSpriteSrcWidth, tileSpriteSrcHeight),
    );

    updateData();
  }

  Future<void> updateData([dynamic mapData]) async {
    if (mapData != null) {
      data = mapData;
    }

    id = data['id'];
    tileMapWidth = data['width'];
    tileMapHeight = data['height'];
    final terrainsData = data['terrains'];
    terrains = <TileMapTerrain>[];
    for (var j = 0; j < tileMapHeight; ++j) {
      for (var i = 0; i < tileMapWidth; ++i) {
        final index = tilePosition2Index(i + 1, j + 1, tileMapWidth);
        final terrainData = terrainsData[index];
        final bool isLighted = terrainData['isLighted'] ?? false;
        final bool isNonInteractable =
            terrainData['isNonInteractable'] ?? false;
        final String? kindString = terrainData['kind'];
        final String? zoneId = terrainData['zoneId'];
        final String? nationId = terrainData['nationId'];
        final String? locationId = terrainData['locationId'];
        final String? caption = terrainData['caption'];
        final String? objectId = terrainData['objectId'];
        // 这里不载入图片和动画，而是交给terrain自己从data中读取
        final tile = TileMapTerrain(
          tileShape: tileShape,
          data: terrainData,
          left: i + 1,
          top: j + 1,
          isLighted: isLighted,
          isNonInteractable: isNonInteractable,
          srcWidth: tileSpriteSrcWidth,
          srcHeight: tileSpriteSrcHeight,
          gridWidth: gridWidth,
          gridHeight: gridHeight,
          kind: kindString,
          zoneId: zoneId,
          nationId: nationId,
          locationId: locationId,
          caption: caption,
          captionStyle: captionStyle,
          offsetX: tileOffsetX,
          offsetY: tileOffsetY,
          objectId: objectId,
        );
        refreshTileInfo(tile);
        tile.tryLoadSprite();

        final overlaySpriteData = terrainData['overlaySprite'];
        if (overlaySpriteData != null) {
          tile.tryLoadSprite(overlay: true);
        }

        terrains.add(tile);
      }
    }

    final stillObjectData = data['stillObjects'];
    stillObjects = <String, TileMapObject>{};
    if (stillObjectData != null) {
      for (final data in stillObjectData) {
        loadStillObjectFromData(data);
      }
    }
  }

  final TextStyle captionStyle;

  final TileShape tileShape;
  final double gridWidth,
      gridHeight,
      tileSpriteSrcWidth,
      tileSpriteSrcHeight,
      tileOffsetX,
      tileOffsetY,
      tileObjectSpriteSrcWidth,
      tileObjectSpriteSrcHeight;

  late int tileMapWidth, tileMapHeight;

  // final bool tapSelect;

  Vector2 mapScreenSize = Vector2.zero();

  TileMapTerrain? selectedTerrain;
  List<TileMapObject>? selectedActors;

  TileMapTerrain? hoverTerrain;
  List<TileMapObject>? hoverActors;

  List<TileMapTerrain> terrains = [];
  // List<TileMapZone> zones = [];

  /// 按id保存的object
  /// 这些object不一定都可以互动
  /// 而且也不一定都会在一开始就显示出来
  Map<String, TileMapObject> stillObjects = {};

  /// 地图上的移动物体，通常代表一些从一个地方移动到另一个地方的NPC
  Map<String, TileMapObject> movingObjects = {};

  void setTerrainCaption(int left, int top, String? caption) {
    final tile = getTerrain(left, top);
    assert(tile != null);
    tile!.caption = caption;
  }

  void loadStillObjectFromData(dynamic data) async {
    final spritePath = data['sprite'];
    final int? left = data['left'];
    final int? top = data['top'];
    final Sprite sprite = Sprite(await Flame.images.load(spritePath));
    final objectId = data['id'];
    final object = TileMapObject(
      id: objectId,
      data: data,
      left: left,
      top: top,
      sprite: sprite,
      tileShape: tileShape,
      tileMapWidth: tileMapWidth,
      gridWidth: gridWidth,
      gridHeight: gridHeight,
      srcWidth: data['srcWidth'].toDouble(),
      srcHeight: data['srcHeight'].toDouble(),
      srcOffsetY: data['srcOffsetY'] ?? 0.0,
    );
    refreshTileInfo(object);

    if (left != null && top != null) {
      final tile = terrains[object.index];
      tile.objectId = objectId;
    }
    stillObjects[objectId] = object;
  }

  void setTerrainObject(int left, int top, String? objectId) {
    if (objectId != null) assert(stillObjects.containsKey(objectId));
    final tile = getTerrain(left, top);
    if (tile != null) {
      tile.objectId = objectId;
    }
  }

  void removeMovingObject(String id) {
    movingObjects.remove(id);
  }

  Future<TileMapObject> _loadMovingObjectFromData(dynamic data,
      [void Function(int left, int top)? onMoved]) async {
    final object = TileMapObject(
      id: data!['id'],
      data: data,
      moveAnimationSpriteSheet: SpriteSheet(
        image: await Flame.images
            .load('animation/tile_character_${data!['skin']}.png'),
        srcSize: Vector2(tileObjectSpriteSrcWidth, tileObjectSpriteSrcHeight),
      ),
      swimAnimationSpriteSheet: SpriteSheet(
        image: await Flame.images.load('animation/tile_ship.png'),
        srcSize: Vector2(tileObjectSpriteSrcWidth, tileObjectSpriteSrcHeight),
      ),
      left: data!['worldPosition']['left'],
      top: data!['worldPosition']['top'],
      tileShape: tileShape,
      tileMapWidth: tileMapWidth,
      gridWidth: gridWidth,
      gridHeight: gridHeight,
      srcOffsetY: 16.0,
      srcWidth: tileObjectSpriteSrcWidth,
      srcHeight: tileObjectSpriteSrcHeight,
      onMoved: onMoved,
    );
    return object;
  }

  Future<void> loadHero(dynamic data,
      [void Function(int left, int top)? onMoved]) async {
    hero = await _loadMovingObjectFromData(data, onMoved);
    refreshTileInfo(hero!);
  }

  Future<void> loadMovingObject(dynamic data,
      [void Function(int, int)? onMoved]) async {
    if (movingObjects.containsKey(data['id'])) {
      return;
    } else {
      assert(data['worldPosition'] != null);

      final object = await _loadMovingObjectFromData(data, onMoved);
      movingObjects[object.id] = object;
      object.loadFrameData();
      refreshTileInfo(object);
    }
  }

  void reloadObjectsSprite() {
    // TODO: 修改对象图片路径后，刷新显示
  }

  TileMapObject? _hero;
  TileMapObject? get hero => _hero;
  set hero(TileMapObject? entity) {
    _hero = entity;
    if (_hero != null) {
      lightUpAroundTile(_hero!.tilePosition, size: 1);
      moveCameraToTilePosition(_hero!.left, _hero!.top, animated: false);
    }
  }

  bool isTimeFlowing = false;

  int colorMode = kColorModeNone;

  bool showGrids;
  bool showSelected;
  bool showNonInteractableHintColor;
  bool showHover;
  bool showFogOfWar;
  bool autoUpdateMovingObject;

  final Set<TilePosition> _visiblePerimeter = {};

  // 从索引得到坐标
  TilePosition index2TilePosition(int index) {
    final left = index % tileMapWidth + 1;
    final top = index ~/ tileMapWidth + 1;
    return TilePosition(left, top);
  }

  bool isPositionWithinMap(int left, int top) {
    return (left > 0 &&
        top > 0 &&
        left <= tileMapWidth &&
        top <= tileMapHeight);
  }

  List<TilePosition> getNeighborTilePositions(int left, int top) {
    final positions = <TilePosition>[];
    switch (tileShape) {
      case TileShape.orthogonal:
        positions.add(TilePosition(left - 1, top));
        positions.add(TilePosition(left, top - 1));
        positions.add(TilePosition(left + 1, top));
        positions.add(TilePosition(left, top + 1));
        break;
      case TileShape.hexagonalVertical:
        positions.add(TilePosition(left - 1, top));
        positions.add(TilePosition(left, top - 1));
        positions.add(TilePosition(left + 1, top));
        positions.add(TilePosition(left, top + 1));
        if (left.isOdd) {
          positions.add(TilePosition(left - 1, top - 1));
          positions.add(TilePosition(left + 1, top - 1));
        } else {
          positions.add(TilePosition(left + 1, top + 1));
          positions.add(TilePosition(left - 1, top + 1));
        }
        break;
      case TileShape.isometric:
        throw 'Get neighbors of Isometric map tile is not supported yet!';
      case TileShape.hexagonalHorizontal:
        throw 'Get neighbors of Vertical hexagonal map tile is not supported yet!';
    }
    return positions;
  }

  TileMapTerrain? getTerrainByPosition(TilePosition position) {
    return getTerrain(position.left, position.top);
  }

  Vector2 getRandomTerrainPosition() {
    final left = random.nextInt(tileMapWidth);
    final top = random.nextInt(tileMapHeight);

    final pos = tilePosition2RenderPosition(left, top);
    // pos.x = pos.x - gridWidth / 2 + random.nextDouble() * gridWidth;
    // pos.y = pos.y - gridHeight / 2 + random.nextDouble() * gridHeight;

    return Vector2(pos.x, pos.y);
  }

  TileMapTerrain? getTerrain(int left, int top) {
    if (isPositionWithinMap(left, top)) {
      return terrains[tilePosition2Index(left, top, tileMapWidth)];
    } else {
      return null;
    }
  }

  TileMapTerrain? getTerrainAtHero() {
    if (_hero != null) {
      return terrains[
          tilePosition2Index(_hero!.left, _hero!.top, tileMapWidth)];
    }
    return null;
  }

  // TileMapRouteNode getRouteNodeFromTileIndex(int index) {
  //   final tilePos = index2TilePosition(index);
  //   final worldPos = tilePosition2TileCenterInWorld(tilePos.left, tilePos.top);
  //   return TileMapRouteNode(
  //     index: index,
  //     tilePosition: tilePos,
  //     worldPosition: worldPos,
  //   );
  // }

  void lightUpAroundTile(TilePosition tilePosition, {int size = 1}) {
    final start = getTerrain(tilePosition.left, tilePosition.top)!;
    start.isLighted = true;
    _visiblePerimeter.remove(tilePosition);
    final neighbors =
        getNeighborTilePositions(tilePosition.left, tilePosition.top);
    for (final pos in neighbors) {
      final tile = getTerrain(pos.left, pos.top);
      if (tile != null) {
        if (!tile.isLighted) {
          _visiblePerimeter.add(tile.tilePosition);
        }
        if (size > 0) {
          lightUpAroundTile(pos, size: size - 1);
        }
      }
    }
  }

  Vector2 worldPosition2Screen(Vector2 position, Vector2 gameSize) {
    return position + (gameSize / 2 - gameRef.camera.viewfinder.position);
  }

  Vector2 screenPosition2World(Vector2 position, Vector2 gameSize) {
    return position - (gameSize / 2 - gameRef.camera.viewfinder.position);
  }

  int tilePosition2Index(int left, int top, int tileMapWidth) {
    return (left - 1) + (top - 1) * tileMapWidth;
  }

  Vector2 tilePosition2TileCenterInWorld(int left, int top) {
    late final double rl, rt;
    switch (tileShape) {
      case TileShape.orthogonal:
        rl = ((left - 1) * gridWidth);
        rt = ((top - 1) * gridHeight);
        break;
      case TileShape.hexagonalVertical:
        rl = (left - 1) * gridWidth * (3 / 4) + gridWidth / 2;
        rt = left.isOdd
            ? (top - 1) * gridHeight + gridHeight / 2
            : (top - 1) * gridHeight + gridHeight;
        break;
      case TileShape.isometric:
        throw 'Isometric map tile is not supported yet!';
      case TileShape.hexagonalHorizontal:
        throw 'Vertical hexagonal map tile is not supported yet!';
    }
    return Vector2(rl, rt);
  }

  Vector2 tilePosition2TileCenterInScreen(int left, int top) {
    final worldPos = tilePosition2TileCenterInWorld(left, top);
    final scaled = Vector2(worldPos.x * scale.x, worldPos.y * scale.y);
    final result =
        scaled - (gameRef.camera.viewfinder.position - gameRef.size / 2);
    return result;
  }

  TilePosition worldPosition2Tile(Vector2 worldPos) {
    late final int left, top;
    switch (tileShape) {
      case TileShape.orthogonal:
        left = (worldPos.x / scale.x / gridWidth).floor();
        top = (worldPos.y / scale.x / gridHeight).floor();
        break;
      case TileShape.hexagonalVertical:
        int l = (worldPos.x / (gridWidth * 3 / 4) / scale.x).floor() + 1;
        final inTilePosX = worldPos.x / scale.x - (l - 1) * (gridWidth * 3 / 4);
        late final double inTilePosY;
        int t;
        if (l.isOdd) {
          t = (worldPos.y / scale.y / gridHeight).floor() + 1;
          inTilePosY = gridHeight / 2 - (worldPos.y / scale.y) % gridHeight;
        } else {
          t = ((worldPos.y / scale.y - gridHeight / 2) / gridHeight).floor() +
              1;
          inTilePosY = gridHeight / 2 -
              (worldPos.y / scale.y - gridHeight / 2) % gridHeight;
        }
        if (inTilePosX < gridWidth / 4) {
          if (l.isOdd) {
            if (inTilePosY >= 0) {
              if (inTilePosY / inTilePosX > gridHeight / gridWidth * 2) {
                left = l - 1;
                top = t - 1;
              } else {
                left = l;
                top = t;
              }
            } else {
              if (-inTilePosY / inTilePosX > gridHeight / gridWidth * 2) {
                left = l - 1;
                top = t;
              } else {
                left = l;
                top = t;
              }
            }
          } else {
            if (inTilePosY >= 0) {
              if (inTilePosY / inTilePosX > gridHeight / gridWidth * 2) {
                left = l - 1;
                top = t;
              } else {
                left = l;
                top = t;
              }
            } else {
              if (-inTilePosY / inTilePosX > gridHeight / gridWidth * 2) {
                left = l - 1;
                top = t + 1;
              } else {
                left = l;
                top = t;
              }
            }
          }
        } else {
          left = l;
          top = t;
        }
        break;
      case TileShape.isometric:
        throw 'Get Isometric map tile position from screen position is not supported yet!';
      case TileShape.hexagonalHorizontal:
        throw 'Get Horizontal hexagonal map tile position from screen position is not supported yet!';
    }
    return TilePosition(left, top);
  }

  Vector2 tilePosition2RenderPosition(int left, int top) {
    late final double l, t; //, l, t;
    switch (tileShape) {
      case TileShape.orthogonal:
        l = ((left - 1) * gridWidth);
        t = ((top - 1) * gridHeight);
        break;
      case TileShape.hexagonalVertical:
        l = (left - 1) * gridWidth * (3 / 4);
        t = left.isOdd
            ? (top - 1) * gridHeight
            : (top - 1) * gridHeight + gridHeight / 2;
        break;
      case TileShape.isometric:
        throw 'Isometric map tile is not supported yet!';
      case TileShape.hexagonalHorizontal:
        throw 'Vertical hexagonal map tile is not supported yet!';
    }
    // switch (renderDirection) {
    //   case TileRenderDirection.bottomRight:
    //     l = bl - (srcWidth - gridWidth);
    //     t = bt - (srcHeight - gridHeight);
    //     break;
    //   case TileRenderDirection.bottomLeft:
    //     l = bl;
    //     t = bt - (srcWidth - gridHeight);
    //     break;
    //   case TileRenderDirection.topRight:
    //     l = bl - (srcHeight - gridWidth);
    //     t = bt;
    //     break;
    //   case TileRenderDirection.topLeft:
    //     l = bl;
    //     t = bt;
    //     break;
    //   case TileRenderDirection.bottomCenter:
    //     break;
    // }
    return Vector2(l - (tileSpriteSrcWidth - gridWidth) / 2,
        t - (tileSpriteSrcHeight - gridHeight));
  }

  /// 计算 hexagonal tile 的方向，如果是 backward 则是反方向
  TileMapDirection directionTo(TilePosition from, TilePosition to,
      {bool backward = false}) {
    assert(from != to);
    if (from.left % 2 != 0) {
      if (to.left == from.left) {
        if (to.top < from.top) {
          return backward ? TileMapDirection.south : TileMapDirection.north;
        } else {
          return backward ? TileMapDirection.north : TileMapDirection.south;
        }
      } else if (to.left > from.left) {
        if (to.top == from.top) {
          if (to.left % 2 != 0) {
            return backward ? TileMapDirection.west : TileMapDirection.east;
          } else {
            return backward
                ? TileMapDirection.northWest
                : TileMapDirection.southEast;
          }
        } else if (to.top < from.top) {
          return backward
              ? TileMapDirection.southWest
              : TileMapDirection.northEast;
        } else {
          return backward
              ? TileMapDirection.northWest
              : TileMapDirection.southEast;
        }
      } else {
        if (to.top == from.top) {
          if (to.left % 2 != 0) {
            return backward ? TileMapDirection.east : TileMapDirection.west;
          } else {
            return backward
                ? TileMapDirection.northEast
                : TileMapDirection.southWest;
          }
        } else if (to.top < from.top) {
          return backward
              ? TileMapDirection.southEast
              : TileMapDirection.northWest;
        } else {
          return backward
              ? TileMapDirection.northEast
              : TileMapDirection.southWest;
        }
      }
    } else {
      if (to.left == from.left) {
        if (to.top < from.top) {
          return backward ? TileMapDirection.south : TileMapDirection.north;
        } else {
          return backward ? TileMapDirection.north : TileMapDirection.south;
        }
      } else if (to.left > from.left) {
        if (to.top == from.top) {
          if (to.left.isEven) {
            return backward ? TileMapDirection.west : TileMapDirection.east;
          } else {
            return backward
                ? TileMapDirection.southWest
                : TileMapDirection.northEast;
          }
        } else if (to.top < from.top) {
          return backward
              ? TileMapDirection.southWest
              : TileMapDirection.northEast;
        } else {
          return backward
              ? TileMapDirection.northWest
              : TileMapDirection.southEast;
        }
      } else {
        if (to.top == from.top) {
          if (to.left.isEven) {
            return backward ? TileMapDirection.east : TileMapDirection.west;
          } else {
            return backward
                ? TileMapDirection.southEast
                : TileMapDirection.northWest;
          }
        } else if (to.top < from.top) {
          return backward
              ? TileMapDirection.southEast
              : TileMapDirection.northWest;
        } else {
          return backward
              ? TileMapDirection.northEast
              : TileMapDirection.southWest;
        }
      }
    }
  }

  void moveCameraToTilePosition(int left, int top,
      {bool animated = true, double speed = 500.0}) {
    final worldPos = tilePosition2TileCenterInWorld(left, top);
    final dest = Vector2(worldPos.x * scale.x, worldPos.y * scale.y);

    if (animated) {
      gameRef.camera.moveTo(dest, speed: speed);
    } else {
      gameRef.camera.snapTo(dest);
    }
  }

  void unselectTile() {
    selectedTerrain = null;
  }

  bool trySelectTile(int left, int top) {
    final terrain = getTerrain(left, top);
    if (terrain != null) {
      // &&  (!terrain.isNonInteractable || selectNonInteractable)) {
      selectedTerrain = terrain;
      return true;
    }
    return false;
  }

  void cancelObjectMoving(TileMapObject object) {
    // assert(movingObjects.containsKey(id));
    // final object = movingObjects[id]!;

    if (object.lastRouteNode != null) {
      object.currentRoute = null;
      moveObjectToTilePositionByRoute(
        object,
        [
          // 这里不能直接使用 object.index，因为object的 tileinfo还没有被正确的通过setTileInfo来更新
          tilePosition2Index(object.left, object.top, tileMapWidth),
          object.lastRouteNode!.index
        ],
        isMoveCanceling: true,
      );
    }
    object.lastRouteNode = null;
  }

  void moveObjectToTilePositionByRoute(
    TileMapObject object,
    List<int> route, {
    TileMapDirectionOrthogonal? endDirection,
    void Function()? onDestinationCallback,
    bool isMoveCanceling = false,
  }) {
    // assert(movingObjects.containsKey(id));
    // final object = movingObjects[id]!;

    if (object.isMoving) {
      if (kDebugMode) {
        print('tilemap warning: try to move object while it is already moving');
      }
      return;
    }

    assert(tilePosition2Index(object.left, object.top, tileMapWidth) ==
        route.first);

    object.backwardMoving = isMoveCanceling;
    object.onDestinationCallback = onDestinationCallback;
    // 默认移动结束后面朝主视角
    object.endDirection = endDirection;
    object.currentRoute = route
        .map((index) {
          final tilePos = index2TilePosition(index);
          final worldPos =
              tilePosition2TileCenterInWorld(tilePos.left, tilePos.top);
          return TileMapRouteNode(
            index: index,
            tilePosition: tilePos,
            worldPosition: worldPos,
          );
        })
        .toList()
        .reversed
        .toList();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    if (shadowSpriteId != null && shadowSprite == null) {
      shadowSprite = Sprite(await Flame.images.load(shadowSpriteId!));
    }

    double mapScreenSizeX = (gridWidth * 3 / 4) * tileMapWidth * scale.x;
    double mapScreenSizeY =
        (gridHeight * tileMapHeight + gridHeight / 2) * scale.y;
    mapScreenSize = Vector2(mapScreenSizeX, mapScreenSizeY);
  }

  void updateObjectMoving(TileMapObject object) {
    if (object.currentRoute == null) return;

    assert(object.currentRoute!.isNotEmpty);

    if (object.isMovingCanceled) {
      object.currentRoute = null;
      object.isMovingCanceled = false;
    } else if (!object.isMoving) {
      object.lastRouteNode = object.currentRoute!.last;
      object.currentRoute!.removeLast();
      refreshTileInfo(object);
      if (object.currentRoute!.isNotEmpty) {
        final pos = object.lastRouteNode!.tilePosition;
        final terrain = getTerrain(pos.left, pos.top);
        if (terrain!.isWater) {
          object.isOnWater = true;
        } else {
          object.isOnWater = false;
        }
        final nextTile = object.currentRoute!.last.tilePosition;
        object.walkTo(
          target: nextTile,
          targetWorldPosition:
              tilePosition2TileCenterInWorld(nextTile.left, nextTile.top),
          targetDirection: direction2Orthogonal(directionTo(
              _hero!.tilePosition, nextTile,
              backward: object.backwardMoving)),
          backward: object.backwardMoving,
        );
      } else {
        if (object.onDestinationCallback != null) {
          object.onDestinationCallback!();
        }
        object.currentRoute = null;
        object.lastRouteNode = null;
        if (object.endDirection != null) {
          object.direction = object.endDirection!;
        }
        object.endDirection = null;
        object.stopAnimation();
      }
    }
  }

  @override
  void updateTree(double dt, {bool callOwnUpdate = true}) {
    super.updateTree(dt);

    for (final tile in terrains) {
      tile.update(dt);
    }

    for (final object in stillObjects.values) {
      object.update(dt);
    }

    if (_hero != null) {
      _hero!.update(dt);
      updateObjectMoving(_hero!);
    }

    for (final object in movingObjects.values) {
      if (autoUpdateMovingObject || (_hero?.isMoving ?? false)) {
        object.update(dt);
        updateObjectMoving(object);
      }
    }
  }

  void renderTileObject(Canvas canvas, TileMapTerrain tile) {
    if (tile.objectId != null) {
      final object = stillObjects[tile.objectId]!;
      object.render(canvas);
    }
    for (final object in movingObjects.values) {
      if (object.tilePosition == tile.tilePosition) {
        object.render(canvas);
      }
    }
    if (tile.tilePosition == hero?.tilePosition) {
      hero?.render(canvas);
    }
  }

  @override
  void renderTree(Canvas canvas) {
    // backgroundSprite?.render(canvas, size: gameRef.size);

    canvas.save();
    canvas.transform(transformMatrix.storage);

    // to avoid overlapping, render the tiles in a specific order:
    for (var j = 0; j < tileMapHeight; ++j) {
      if (tileShape == TileShape.hexagonalVertical) {
        for (var i = 0; i < tileMapWidth; i = i + 2) {
          final tile = terrains[i + j * tileMapWidth];
          tile.render(canvas,
              showGrids: showGrids,
              showNonInteractableHintColor: showNonInteractableHintColor);
        }
        for (var i = 1; i < tileMapWidth; i = i + 2) {
          final tile = terrains[i + j * tileMapWidth];
          tile.render(canvas,
              showGrids: showGrids,
              showNonInteractableHintColor: showNonInteractableHintColor);
        }
      } else if (tileShape == TileShape.orthogonal) {
        for (var i = 0; i < tileMapWidth; ++i) {
          final tile = terrains[i + j * tileMapWidth];
          tile.render(canvas,
              showGrids: showGrids,
              showNonInteractableHintColor: showNonInteractableHintColor);
        }
      } else {
        throw 'tile shape $tileShape is not supported!';
      }
    }

    // after all terrains, render the objects, in the same way:
    for (var j = 0; j < tileMapHeight; ++j) {
      if (tileShape == TileShape.hexagonalVertical) {
        for (var i = 0; i < tileMapWidth; i = i + 2) {
          final tile = terrains[i + j * tileMapWidth];
          renderTileObject(canvas, tile);
        }
        for (var i = 1; i < tileMapWidth; i = i + 2) {
          final tile = terrains[i + j * tileMapWidth];
          renderTileObject(canvas, tile);
        }
      } else if (tileShape == TileShape.orthogonal) {
        for (var i = 0; i < tileMapWidth; ++i) {
          final tile = terrains[i + j * tileMapWidth];
          renderTileObject(canvas, tile);
        }
      } else {
        throw 'tile shape $tileShape is not supported!';
      }
    }

    for (final tile in terrains) {
      tile.renderCaption(canvas, offset: _kCaptionOffset);
    }

    if (colorMode >= 0) {
      for (final tile in terrains) {
        final color = TileMap.zoneColors[colorMode][tile.index];
        if (color != null) {
          canvas.drawPath(tile.borderPath, paint);
        }
      }
    }

    customRender?.call(canvas);

    if (showFogOfWar) {
      for (final tile in terrains) {
        if (tile.isLighted || tile.terrainKind == TileMapTerrainKind.empty) {
          continue;
        } else if (_visiblePerimeter.contains(tile.tilePosition)) {
          canvas.drawPath(tile.borderPath, fogNeighborPaint);
          // canvas.drawShadow(tile.shadowPath, Colors.black, 0, true);

          // shadowSprite?.render(canvas, position: tile.worldPosition);
        } else {
          canvas.drawPath(tile.shadowPath, fogPaint);
        }
      }
    }

    if (showSelected && selectedTerrain != null) {
      canvas.drawPath(selectedTerrain!.borderPath, selectedPaint);
    }

    if (showHover && hoverTerrain != null) {
      canvas.drawPath(hoverTerrain!.borderPath, hoverPaint);
    }

    canvas.restore();

    super.renderTree(canvas);
  }

  @override
  bool containsPoint(Vector2 point) {
    return true;
  }
}
