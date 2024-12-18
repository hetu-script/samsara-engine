import 'dart:math' as math;
import 'dart:async';

// import 'package:flame/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:flame/flame.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import '../extensions.dart';
// import '../paint.dart';
import '../components/game_component.dart';
import '../gestures/gesture_mixin.dart';
import 'tile_mixin.dart';
import 'object.dart';
import 'terrain.dart';
import 'direction.dart';
import 'route.dart';
import '../utils/color.dart';
import '../animation/sprite_animation.dart';

export 'direction.dart';

const kTileBasePriority = 100;

const kObjectBasePriority = 1000;

const kColorModeNone = -1;

class TileMap extends GameComponent with HandlesGesture {
  static final Map<Color, Paint> cachedColorPaints = {};

  static final halfShadowPaint = Paint()..color = Colors.white.withAlpha(128);

  static final uninteractablePaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.red.withAlpha(180);

  static final visiblePerimeterPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.black.withAlpha(128)
    ..maskFilter = MaskFilter.blur(BlurStyle.solid, convertRadiusToSigma(2));

  static final selectedPaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke
    ..color = Colors.yellow;

  static final hoverPaint = Paint()
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke
    ..color = Colors.yellow.withAlpha(180);

  static final gridPaint = Paint()
    ..color = Colors.blue.withAlpha(128)
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke;

  static final Map<String, SpriteSheet> cachedMovingObjectSpriteSheet = {};

  /// key 是 mapId, value 是一个列表
  /// 列表的index代表colorMode，列表的值是一个包含全部地图节点颜色数据的JSON
  /// 节点颜色数据的Key是terrain的index，值是一个Record对，包含颜色和对应的Paint
  final Map<String, List<Map<int, (Color, Paint)>>> mapZoneColors = {};

  int colorMode = kColorModeNone;

  late SpriteSheet terrainSpriteSheet;

  String id;
  dynamic data;

  String? shadowSpriteId;
  Sprite? shadowSprite;

  bool showNonInteractableHintColor;
  bool showGrids;
  bool showFogOfWar;
  bool showSelected;
  bool showHover;

  math.Random random;

  double _scaleFactor = 1.0;

  double get scaleFactor => _scaleFactor;

  set scaleFactor(double value) {
    _scaleFactor = value;
    scale = Vector2(value, value);
  }

  // double _cameraMoveDt = 0;

  final TextStyle captionStyle;

  final TileShape tileShape;
  final Vector2 gridSize,
      tileSpriteSrcSize,
      tileOffset,
      tileObjectSpriteSrcSize;

  int tileMapWidth, tileMapHeight;

  Vector2 mapScreenSize = Vector2.zero();

  TileMapTerrain? selectedTerrain;
  List<TileMapMovingObject>? selectedActors;

  TileMapTerrain? hoveredTerrain;
  List<TileMapMovingObject>? hoverActors;

  List<TileMapTerrain> terrains = [];

  /// 按id保存的object
  /// 这些object不一定都可以互动
  /// 而且也不一定都会在一开始就显示出来
  Map<String, TileMapMovingObject> objects = {};

  /// 地图上的移动物体，通常代表一些从一个地方移动到另一个地方的NPC
  Map<String, TileMapMovingObject> movingObjects = {};

  TileMapMovingObject? hero;

  bool isTimeFlowing = false;

  bool autoUpdateMovingObject;

  bool isCameraFollowHero;

  void Function()? onLoadComplete;

  final Vector2 shadowOffset;

  TileMap({
    required this.id,
    required this.tileShape,
    required this.tileMapWidth,
    required this.tileMapHeight,
    this.data,
    required this.gridSize,
    required this.tileSpriteSrcSize,
    required this.tileObjectSpriteSrcSize,
    required this.tileOffset,
    double scaleFactor = 1.0,
    this.showNonInteractableHintColor = false,
    this.showGrids = false,
    this.showFogOfWar = false,
    this.showSelected = false,
    this.showHover = false,
    this.isCameraFollowHero = false,
    this.autoUpdateMovingObject = false,
    required this.captionStyle,
    this.shadowSpriteId,
    this.shadowSprite,
    Vector2? shadowOffset,
    this.onLoadComplete,
  })  : random = math.Random(),
        shadowOffset = shadowOffset ?? Vector2.zero(),
        assert(!gridSize.isZero()),
        assert(!tileSpriteSrcSize.isZero()),
        assert(!tileObjectSpriteSrcSize.isZero()) {
    this.scaleFactor = scaleFactor;

    onMouseHover = (Vector2 position) {
      final tilePosition = worldPosition2Tile(position);
      final terrain = getTerrainByPosition(tilePosition);
      if (terrain != null && terrain != hoveredTerrain) {
        terrain.isHovered = true;
        hoveredTerrain?.isHovered = false;
        hoveredTerrain = terrain;
      }
    };
  }

  /// 修改 tile 的位置会连带影响很多其他属性，这里一并将其纠正
  /// 一些信息涉及到地图本身，所以不能放在tile对象上进行
  void refreshTileInfo(TileInfo tile) {
    tile.index = tilePosition2Index(tile.left, tile.top, tileMapWidth);
    tile.renderPosition =
        tilePosition2RenderPosition(tile.left, tile.top) + tile.offset;
    tile.centerPosition = tilePosition2TileCenterInWorld(tile.left, tile.top);

    if (tile is TileMapMovingObject) {
      tile.position = tile.renderPosition;
    }

    int basePriority =
        tile is TileMapMovingObject ? kObjectBasePriority : kTileBasePriority;

    switch (tileShape) {
      case TileShape.orthogonal:
        tile.priority =
            basePriority + (tile.left - 1 + (tile.top - 1) * tileMapWidth);
      case TileShape.hexagonalVertical:
        // to avoid overlapping, render the tiles in a specific order:
        tile.priority = basePriority +
            tileMapWidth * (tile.top - 1) +
            (tile.left.isOdd
                ? tile.left ~/ 2
                : ((tileMapWidth / 2).ceil() + tile.left ~/ 2));
      case TileShape.isometric:
        throw 'Isometric map tile is not supported yet!';
      case TileShape.hexagonalHorizontal:
        throw 'Vertical hexagonal map tile is not supported yet!';
    }
  }

  @override
  Future<void> onLoad() async {
    if (shadowSpriteId != null && shadowSprite == null) {
      shadowSprite = Sprite(await Flame.images.load(shadowSpriteId!));
    }

    double mapScreenSizeX = (gridSize.x * 3 / 4) * tileMapWidth * scale.x;
    double mapScreenSizeY =
        (gridSize.y * tileMapHeight + gridSize.y / 2) * scale.y;
    mapScreenSize = Vector2(mapScreenSizeX, mapScreenSizeY);

    final terrainSpritePath = data['terrainSpriteSheet'];
    terrainSpriteSheet = SpriteSheet(
      image: await Flame.images.load(terrainSpritePath),
      srcSize: tileSpriteSrcSize,
    );

    await updateData();

    moveCameraToTilePosition(tileMapWidth ~/ 2, tileMapHeight ~/ 2,
        animated: false);

    onLoadComplete?.call();
  }

  Future<void> updateData([dynamic mapData]) async {
    if (mapData != null) {
      data = mapData;
    }

    assert(tileShape.name == data['tileShape']);
    assert(gridSize.x == data['gridWidth']);
    assert(gridSize.y == data['gridHeight']);
    assert(tileSpriteSrcSize.x == data['tileSpriteSrcWidth']);
    assert(tileSpriteSrcSize.y == data['tileSpriteSrcHeight']);
    assert(tileOffset.x == data['tileOffsetX']);
    assert(tileOffset.y == data['tileOffsetY']);

    terrains = <TileMapTerrain>[];
    for (var j = 0; j < tileMapHeight; ++j) {
      for (var i = 0; i < tileMapWidth; ++i) {
        final index = tilePosition2Index(i + 1, j + 1, tileMapWidth);
        final terrainData = data['terrains'][index];
        final bool isLighted = terrainData['isLighted'] ?? false;
        final bool isNonInteractable =
            terrainData['isNonInteractable'] ?? false;
        final String? kindString = terrainData['kind'];
        final String? zoneId = terrainData['zoneId'];
        final String? nationId = terrainData['nationId'];
        final String? locationId = terrainData['locationId'];
        final String? objectId = terrainData['objectId'];
        // 这里不载入图片和动画，而是交给terrain自己从data中读取
        final tile = TileMapTerrain(
          mapId: id,
          terrainSpriteSheet: terrainSpriteSheet,
          tileShape: tileShape,
          data: terrainData,
          left: i + 1,
          top: j + 1,
          isLighted: isLighted,
          isNonInteractable: isNonInteractable,
          srcSize: tileSpriteSrcSize,
          gridSize: gridSize,
          kind: kindString,
          zoneId: zoneId,
          nationId: nationId,
          locationId: locationId,
          objectId: objectId,
          captionStyle: captionStyle,
          offset: tileOffset,
        );
        refreshTileInfo(tile);
        tile.tryLoadSprite();

        final overlaySpriteData = terrainData['overlaySprite'];
        if (overlaySpriteData != null) {
          tile.tryLoadSprite(overlay: true);
        }

        terrains.add(tile);
        add(tile);
      }
    }
  }

  void setTerrainCaption(int left, int top, String? caption) {
    final tile = getTerrain(left, top);
    assert(tile != null);
    tile!.caption = caption;
  }

  void setTerrainObject(int left, int top, String? objectId) {
    if (objectId != null) assert(objects.containsKey(objectId));
    final tile = getTerrain(left, top);
    if (tile != null) {
      tile.objectId = objectId;
    }
  }

  void removeMovingObject(String id) {
    final obj = movingObjects.remove(id);
    obj?.removeFromParent();
  }

  Future<TileMapMovingObject> _loadMovingObjectFromData(dynamic data,
      [void Function(int left, int top)? onMoved]) async {
    final String skinId = data!['skin'];

    late SpriteSheet moveAnimationSpriteSheet, swimAnimationSpriteSheet;

    if (cachedMovingObjectSpriteSheet.containsKey(skinId)) {
      moveAnimationSpriteSheet = cachedMovingObjectSpriteSheet[skinId]!;
    } else {
      cachedMovingObjectSpriteSheet[skinId] =
          moveAnimationSpriteSheet = SpriteSheet(
        image: await Flame.images.load('animation/$skinId/tile_character.png'),
        srcSize: tileObjectSpriteSrcSize,
      );
    }
    if (cachedMovingObjectSpriteSheet.containsKey('_ship')) {
      swimAnimationSpriteSheet = cachedMovingObjectSpriteSheet['_ship']!;
    } else {
      cachedMovingObjectSpriteSheet['_ship'] =
          swimAnimationSpriteSheet = SpriteSheet(
        image: await Flame.images.load('animation/tile_ship.png'),
        srcSize: tileObjectSpriteSrcSize,
      );
    }

    final Map<String, SpriteAnimationWithTicker> states = {};

    states['move_south'] = SpriteAnimationWithTicker(
        animation: moveAnimationSpriteSheet.createAnimation(
            row: 0, stepTime: TileMapMovingObject.defaultAnimationStepTime));
    states['move_east'] = SpriteAnimationWithTicker(
        animation: moveAnimationSpriteSheet.createAnimation(
            row: 1, stepTime: TileMapMovingObject.defaultAnimationStepTime));
    states['move_north'] = SpriteAnimationWithTicker(
        animation: moveAnimationSpriteSheet.createAnimation(
            row: 2, stepTime: TileMapMovingObject.defaultAnimationStepTime));
    states['move_west'] = SpriteAnimationWithTicker(
        animation: moveAnimationSpriteSheet.createAnimation(
            row: 3, stepTime: TileMapMovingObject.defaultAnimationStepTime));

    states['swim_south'] = SpriteAnimationWithTicker(
        animation: swimAnimationSpriteSheet.createAnimation(
            row: 0, stepTime: TileMapMovingObject.defaultAnimationStepTime));
    states['swim_east'] = SpriteAnimationWithTicker(
        animation: swimAnimationSpriteSheet.createAnimation(
            row: 1, stepTime: TileMapMovingObject.defaultAnimationStepTime));
    states['swim_north'] = SpriteAnimationWithTicker(
        animation: swimAnimationSpriteSheet.createAnimation(
            row: 2, stepTime: TileMapMovingObject.defaultAnimationStepTime));
    states['swim_west'] = SpriteAnimationWithTicker(
        animation: swimAnimationSpriteSheet.createAnimation(
            row: 3, stepTime: TileMapMovingObject.defaultAnimationStepTime));

    final object = TileMapMovingObject(
      id: data!['id'],
      data: data,
      left: data!['worldPosition']['left'],
      top: data!['worldPosition']['top'],
      srcSize: tileObjectSpriteSrcSize,
      offset: tileOffset,
      onMoved: onMoved,
      states: states,
    );
    refreshTileInfo(object);
    add(object);
    return object;
  }

  Future<void> loadHeroFromData(dynamic data,
      [void Function(int left, int top)? onMoved]) async {
    hero = await _loadMovingObjectFromData(data, onMoved);
  }

  Future<void> loadMovingObjectFromData(dynamic data,
      [void Function(int, int)? onMoved]) async {
    if (movingObjects.containsKey(data['id'])) return;

    assert(data['worldPosition'] != null);
    final object = await _loadMovingObjectFromData(data, onMoved);
    movingObjects[object.id] = object;
    object.loadFrameData();
  }

  void saveMovingObjectsFrameData() {
    for (final object in movingObjects.values) {
      object.saveFrameData();
    }
  }

  void setCameraFollowHero(bool value) {
    if (hero != null) {
      if (value) {
        gameRef.camera.follow(hero!);
      } else {
        gameRef.camera.stop();
      }
    }
  }

  bool isTileVisible(int left, int top) {
    final tile = getTerrain(left, top);
    return (tile?.isLighted ?? false) || (tile?.isOnVisiblePerimeter ?? false);
  }

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
    // pos.x = pos.x - gridSize.x / 2 + random.nextDouble() * gridSize.x;
    // pos.y = pos.y - gridSize.y / 2 + random.nextDouble() * gridSize.y;

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
    if (hero != null) {
      return terrains[tilePosition2Index(hero!.left, hero!.top, tileMapWidth)];
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

  void lightUpAroundTile(TilePosition tilePosition,
      {int size = 1, List<dynamic> excludeTerrainKinds = const []}) {
    final start = getTerrain(tilePosition.left, tilePosition.top);
    assert(start != null);
    List<TileMapTerrain> pendingTiles = [start!];
    List<TileMapTerrain> nextPendingTiles = [];

    int lightedLayers = 0;
    do {
      for (final tile in pendingTiles) {
        if (excludeTerrainKinds.isEmpty ||
            !excludeTerrainKinds.contains(tile.kind)) {
          tile.isLighted = true;
          tile.isOnVisiblePerimeter = false;
          final neighbors = getNeighborTilePositions(tile.left, tile.top);
          for (final neighbor in neighbors) {
            final neighborTile = getTerrain(neighbor.left, neighbor.top);
            if (neighborTile == null) continue;
            if (!neighborTile.isLighted) {
              nextPendingTiles.add(neighborTile);
            }
          }
        }
      }

      pendingTiles = nextPendingTiles;
      nextPendingTiles = [];

      ++lightedLayers;
    } while (lightedLayers < (size + 1));

    for (final tile in pendingTiles) {
      tile.isOnVisiblePerimeter = true;
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
    late final double l, t;
    switch (tileShape) {
      case TileShape.orthogonal:
        l = ((left - 1) * gridSize.x);
        t = ((top - 1) * gridSize.y);
      case TileShape.hexagonalVertical:
        l = (left - 1) * gridSize.x * (3 / 4) + gridSize.x / 2;
        t = left.isOdd
            ? (top - 1) * gridSize.y + gridSize.y / 2
            : (top - 1) * gridSize.y + gridSize.y;
      case TileShape.isometric:
        throw 'Isometric map tile is not supported yet!';
      case TileShape.hexagonalHorizontal:
        throw 'Vertical hexagonal map tile is not supported yet!';
    }
    return Vector2(l, t);
  }

  Vector2 tilePosition2RenderPosition(int left, int top) {
    late final double l, t; //, l, t;
    switch (tileShape) {
      case TileShape.orthogonal:
        l = ((left - 1) * gridSize.x);
        t = ((top - 1) * gridSize.y);
      case TileShape.hexagonalVertical:
        l = (left - 1) * gridSize.x * (3 / 4);
        t = left.isOdd
            ? (top - 1) * gridSize.y
            : (top - 1) * gridSize.y + gridSize.y / 2;
      case TileShape.isometric:
        throw 'Isometric map tile is not supported yet!';
      case TileShape.hexagonalHorizontal:
        throw 'Vertical hexagonal map tile is not supported yet!';
    }
    // switch (renderDirection) {
    //   case TileRenderDirection.bottomRight:
    //     l = bl - (srcWidth - gridSize.x);
    //     t = bt - (srcHeight - gridSize.y);
    //     break;
    //   case TileRenderDirection.bottomLeft:
    //     l = bl;
    //     t = bt - (srcWidth - gridSize.y);
    //     break;
    //   case TileRenderDirection.topRight:
    //     l = bl - (srcHeight - gridSize.x);
    //     t = bt;
    //     break;
    //   case TileRenderDirection.topLeft:
    //     l = bl;
    //     t = bt;
    //     break;
    //   case TileRenderDirection.bottomCenter:
    //     break;
    // }
    return Vector2(l - (tileSpriteSrcSize.x - gridSize.x) / 2,
        t - (tileSpriteSrcSize.y - gridSize.y));
  }

  Vector2 tilePosition2TileCenterInScreen(int left, int top) {
    final worldPos = tilePosition2TileCenterInWorld(left, top);
    final result = worldPos * scaleFactor -
        (gameRef.camera.viewfinder.position - gameRef.size / 2);
    return result;
  }

  TilePosition worldPosition2Tile(Vector2 worldPos) {
    late final int left, top;
    switch (tileShape) {
      case TileShape.orthogonal:
        left = (worldPos.x / scale.x / gridSize.x).floor();
        top = (worldPos.y / scale.x / gridSize.y).floor();
      case TileShape.hexagonalVertical:
        int l = (worldPos.x / (gridSize.x * 3 / 4) / scale.x).floor() + 1;
        final inTilePosX =
            worldPos.x / scale.x - (l - 1) * (gridSize.x * 3 / 4);
        late final double inTilePosY;
        int t;
        if (l.isOdd) {
          t = (worldPos.y / scale.y / gridSize.y).floor() + 1;
          inTilePosY = gridSize.y / 2 - (worldPos.y / scale.y) % gridSize.y;
        } else {
          t = ((worldPos.y / scale.y - gridSize.y / 2) / gridSize.y).floor() +
              1;
          inTilePosY = gridSize.y / 2 -
              (worldPos.y / scale.y - gridSize.y / 2) % gridSize.y;
        }
        if (inTilePosX < gridSize.x / 4) {
          if (l.isOdd) {
            if (inTilePosY >= 0) {
              if (inTilePosY / inTilePosX > gridSize.y / gridSize.x * 2) {
                left = l - 1;
                top = t - 1;
              } else {
                left = l;
                top = t;
              }
            } else {
              if (-inTilePosY / inTilePosX > gridSize.y / gridSize.x * 2) {
                left = l - 1;
                top = t;
              } else {
                left = l;
                top = t;
              }
            }
          } else {
            if (inTilePosY >= 0) {
              if (inTilePosY / inTilePosX > gridSize.y / gridSize.x * 2) {
                left = l - 1;
                top = t;
              } else {
                left = l;
                top = t;
              }
            } else {
              if (-inTilePosY / inTilePosX > gridSize.y / gridSize.x * 2) {
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
      case TileShape.isometric:
        throw 'Get Isometric map tile position from screen position is not supported yet!';
      case TileShape.hexagonalHorizontal:
        throw 'Get Horizontal hexagonal map tile position from screen position is not supported yet!';
    }
    return TilePosition(left, top);
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

  Future<void> moveCameraToTilePosition(
    int left,
    int top, {
    bool animated = true,
    double speed = 250.0,
    double? zoom,
  }) {
    final worldPos = tilePosition2TileCenterInWorld(left, top);
    final dest = worldPos * scaleFactor;

    final completer = Completer();

    if (animated) {
      gameRef.camera.moveTo2(dest, speed: speed, zoom: zoom, onComplete: () {
        completer.complete();
      });
    } else {
      gameRef.camera.snapTo(dest);
      completer.complete();
    }

    return completer.future;
  }

  void unselectTile() {
    selectedTerrain?.isSelected = false;
    selectedTerrain = null;
  }

  bool trySelectTile(int left, int top) {
    final terrain = getTerrain(left, top);
    if (terrain != null) {
      if (terrain != selectedTerrain) {
        unselectTile();
        // &&  (!terrain.isNonInteractable || selectNonInteractable)) {
        terrain.isSelected = true;
        selectedTerrain = terrain;
      }
      return true;
    }
    return false;
  }

  void cancelObjectMoving(TileMapMovingObject object) {
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
    TileMapMovingObject object,
    List<int> route, {
    OrthogonalDirection? endDirection,
    void Function(TileMapTerrain tile)? onDestinationCallback,
    bool isMoveCanceling = false,
  }) {
    // assert(movingObjects.containsKey(id));
    // final object = movingObjects[id]!;

    if (object.isWalking) {
      if (kDebugMode) {
        print('tilemap warning: try to move object while it is already moving');
      }
      return;
    }

    assert(tilePosition2Index(object.left, object.top, tileMapWidth) ==
        route.first);

    object.backwardMoving = isMoveCanceling;

    if (object == hero && isCameraFollowHero) {
      setCameraFollowHero(true);
      object.onDestinationCallback = (TileMapTerrain tile) {
        setCameraFollowHero(false);
        onDestinationCallback?.call(tile);
      };
    } else {
      object.onDestinationCallback = onDestinationCallback;
    }
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

  void updateObjectMoving(TileMapMovingObject object) {
    if (object.currentRoute == null) return;

    assert(object.currentRoute!.isNotEmpty);

    if (object.isMovingCanceled) {
      object.currentRoute = null;
      object.isMovingCanceled = false;
    } else if (!object.isWalking) {
      object.lastRouteNode = object.currentRoute!.last;
      object.currentRoute!.removeLast();
      refreshTileInfo(object);
      final pos = object.lastRouteNode!.tilePosition;
      final terrain = getTerrain(pos.left, pos.top);
      if (terrain!.isWater) {
        object.isOnWater = true;
      } else {
        object.isOnWater = false;
      }
      if (object.currentRoute!.isNotEmpty) {
        final nextTile = object.currentRoute!.last.tilePosition;
        object.walkTo(
          target: nextTile,
          targetRenderPosition:
              tilePosition2RenderPosition(nextTile.left, nextTile.top),
          targetDirection: direction2Orthogonal(directionTo(
              hero!.tilePosition, nextTile,
              backward: object.backwardMoving)),
          backward: object.backwardMoving,
        );
      } else {
        if (object.onDestinationCallback != null) {
          object.onDestinationCallback!(terrain);
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
  void updateTree(double dt) {
    super.updateTree(dt);

    if (hero != null) {
      updateObjectMoving(hero!);
    }

    for (final object in movingObjects.values) {
      if (autoUpdateMovingObject || (hero?.isWalking ?? false)) {
        updateObjectMoving(object);
      }
    }
  }

  @override
  void renderTree(Canvas canvas) {
    super.renderTree(canvas);
    canvas.save();
    canvas.transform(transformMatrix.storage);

    for (final tile in terrains) {
      if (colorMode != kColorModeNone) {
        final colorData = mapZoneColors[id]?[colorMode][tile.index];
        if (colorData != null) {
          final (_, paint) = colorData;
          canvas.drawPath(tile.borderPath, paint);
        }
      }
      if (tile.isNonInteractable && showNonInteractableHintColor) {
        canvas.drawPath(tile.borderPath, uninteractablePaint);
      }
    }

    for (final tile in terrains) {
      if (showFogOfWar) {
        if (!tile.isLighted && tile.terrainKind != TileMapTerrainKind.empty) {
          if (tile.isOnVisiblePerimeter) {
            canvas.drawPath(tile.borderPath, visiblePerimeterPaint);
            // canvas.drawShadow(tile.shadowPath, Colors.black, 0, true);
            // shadowSprite?.render(canvas,
            //     position: tile.renderPosition, overridePaint: halfShadowPaint);
          } else {
            // canvas.drawPath(tile.shadowPath, fogPaint);
            shadowSprite?.render(canvas,
                position: tile.renderPosition + shadowOffset);
          }
        }
      }
    }

    for (final tile in terrains) {
      if (showGrids) {
        canvas.drawPath(tile.borderPath, gridPaint);
      }
    }

    if (showSelected && selectedTerrain != null) {
      canvas.drawPath(selectedTerrain!.borderPath, selectedPaint);
    }

    if (showHover && hoveredTerrain != null) {
      canvas.drawPath(hoveredTerrain!.borderPath, hoverPaint);
    }

    canvas.restore();
  }

  @override
  bool containsPoint(Vector2 point) {
    return true;
  }
}
