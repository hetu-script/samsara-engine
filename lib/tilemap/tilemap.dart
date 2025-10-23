import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flame/flame.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/utils/uid.dart';

import '../gestures/gesture_mixin.dart';
import 'tile_info.dart';
import 'component.dart';
import 'terrain.dart';
import 'direction.dart';
import 'route.dart';
import '../utils/color.dart';

import '../samsara.dart';

export 'direction.dart';

const kTileMapTerrainPriority = 1;
const kTileMapComponentPriority = 10000;

const kColorModeNone = -1;
const kColorModeZone = 0;
const kColorModeCity = 1;
const kColorModeNation = 2;

const kScreenEdgeSize = 48;

class TileMap extends GameComponent with HandlesGesture {
  static final Map<Color, Paint> cachedColorPaints = {};

  static final halfShadowPaint = Paint()..color = Colors.white.withAlpha(128);

  static final gridPaint = Paint()
    ..color = Colors.blue.withAlpha(128)
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke;

  static final selectedPaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke
    ..color = Colors.yellow;

  static final hoverPaint = Paint()
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke
    ..color = Colors.yellow.withAlpha(180);

  static final visiblePerimeterPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.black.withAlpha(128)
    ..maskFilter = MaskFilter.blur(BlurStyle.solid, convertRadiusToSigma(2));

  static final uninteractablePaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.red.withAlpha(180);

  static final borderShadowPaint = Paint()
    ..strokeWidth = 3
    ..style = PaintingStyle.stroke
    ..color = Colors.black.withAlpha(90);

  /// 列表的index代表colorMode，列表的值是一个包含全部地图节点颜色数据的JSON
  /// 节点颜色数据的Key是一个int，代表terrain的index
  /// 值是一个Record值对，分别是颜色和对应的Paint
  final List<Map<int, Color>> zoneColors = [];

  /// 缓存的国家颜色 Paint
  final Map<Color, Paint> cachedPaints = {};

  /// 缓存的国家边界 Paint
  final Map<int, Paint> cachedBorderPaints = {};

  int colorMode = kColorModeNone;

  final SpriteSheet terrainSpriteSheet;

  String id;
  dynamic data;

  String? fogSpriteId;
  Sprite? fogSprite;

  bool showFogOfWar;
  bool showSelected;
  bool showHover;

  math.Random random;
  // double _cameraMoveDt = 0;

  final TextStyle captionStyle;

  TileShape tileShape;
  Vector2 gridSize, tileSpriteSrcSize, tileOffset;

  int tileMapWidth, tileMapHeight;

  Vector2 mapScreenSize = Vector2.zero();

  TileMapTerrain? selectedTerrain;
  List<TileMapComponent>? selectedActors;

  TilePosition? hoveringTilePosition;
  TileMapTerrain? hoveringTerrain;
  List<TileMapComponent>? hoveringActors;

  List<TileMapTerrain> terrains = [];

  /// 按id保存的components，这些component不以地块形式显示
  /// 这些可能是跨越多个地块的贴图或是动画
  /// 有些component可以互动，有些是NPC，并且可自行移动
  Map<String, TileMapComponent> components = {};

  void setMapComponentVisible(String id, bool visible) {
    assert(components.containsKey(id));
    final component = components[id]!;
    component.isHidden = !visible;
  }

  TileMapComponent? hero;

  bool autoUpdateComponent;

  bool isCameraFollowHero;

  final Vector2 tileFogOffset;

  bool isEditorMode;

  void Function(TileMapTerrain? tile)? onMouseEnterTile;
  void Function(OrthogonalDirection direction)? onMouseEnterScreenEdge;

  final HTLogger logger;

  TileMap({
    required this.logger,
    required this.id,
    required this.tileShape,
    required this.tileMapWidth,
    required this.tileMapHeight,
    required this.terrainSpriteSheet,
    this.data,
    required this.gridSize,
    required this.tileSpriteSrcSize,
    required this.tileOffset,
    required this.tileFogOffset,
    this.showFogOfWar = false,
    this.showSelected = false,
    this.showHover = false,
    this.isCameraFollowHero = false,
    this.autoUpdateComponent = false,
    required this.captionStyle,
    this.fogSpriteId,
    this.fogSprite,
    this.isEditorMode = false,
  })  : assert(!gridSize.isZero()),
        assert(!tileSpriteSrcSize.isZero()),
        random = math.Random() {
    onMouseHover = (Vector2 position) {
      final screenPosition = game.worldPosition2Screen(position);

      if (screenPosition.x < kScreenEdgeSize) {
        onMouseEnterScreenEdge?.call(OrthogonalDirection.west);
      } else if (screenPosition.x > game.size.x - kScreenEdgeSize) {
        onMouseEnterScreenEdge?.call(OrthogonalDirection.east);
      } else if (screenPosition.y < kScreenEdgeSize) {
        onMouseEnterScreenEdge?.call(OrthogonalDirection.north);
      } else if (screenPosition.y > game.size.y - kScreenEdgeSize) {
        onMouseEnterScreenEdge?.call(OrthogonalDirection.south);
      } else {
        final tilePosition = worldPosition2Tile(position);
        if (tilePosition != hoveringTilePosition) {
          hoveringTilePosition = tilePosition;
          hoveringTerrain = getTerrain(tilePosition.left, tilePosition.top);
          onMouseEnterTile?.call(hoveringTerrain);
        }
      }
    };
  }

  (double, double) getBleedingEdge(Vector2 srcSize) {
    double bleedingPixelHorizontal = srcSize.x * 0.04;
    double bleedingPixelVertical = srcSize.y * 0.04;
    if (bleedingPixelHorizontal > 2) {
      bleedingPixelHorizontal = 2;
    }
    if (bleedingPixelVertical > 2) {
      bleedingPixelVertical = 2;
    }
    return (bleedingPixelHorizontal, bleedingPixelVertical);
  }

  /// 修改 tile 的位置会连带影响很多其他属性，这里一并刷新
  void updateTileInfo(TileInfo tile) {
    tile.index = tilePosition2Index(tile.left, tile.top);
    // tile.renderPosition = tilePosition2RenderPosition(tile.left, tile.top);
    // tile.centerPosition = tilePosition2TileCenter(tile.left, tile.top);

    int basePriority = tile is TileMapComponent
        ? kTileMapComponentPriority
        : kTileMapTerrainPriority;

    late final double l, t;

    final (bleedingPixelHorizontal, bleedingPixelVertical) =
        getBleedingEdge(tile.srcSize);

    switch (tileShape) {
      case TileShape.orthogonal:
        // to avoid overlapping, render the tiles in a specific order:
        tile.priority =
            (basePriority + (tile.left - 1 + (tile.top - 1) * tileMapWidth));

        l = (tile.left - 1) * gridSize.x;
        t = (tile.top - 1) * gridSize.y;

        if (tile is! TileMapComponent) {
          final border = Rect.fromLTWH(l, t, gridSize.x, gridSize.y);
          tile.borderPath.addRect(border);
        }
      case TileShape.hexagonalVertical:
        // to avoid overlapping, render the tiles in a specific order:
        tile.priority = (basePriority +
            tileMapWidth * (tile.top - 1) +
            (tile.left.isOdd
                ? tile.left ~/ 2
                : ((tileMapWidth / 2).ceil() + tile.left ~/ 2)));

        l = (tile.left - 1) * gridSize.x * (3 / 4);
        t = tile.left.isOdd
            ? (tile.top - 1) * gridSize.y
            : (tile.top - 1) * gridSize.y + gridSize.y / 2;

        if (tile is! TileMapComponent) {
          tile.borderPath.moveTo(l, t + gridSize.y / 2);
          tile.borderPath.relativeLineTo(gridSize.x / 4, -gridSize.y / 2);
          tile.borderPath.relativeLineTo(gridSize.x / 2, 0);
          tile.borderPath.relativeLineTo(gridSize.x / 4, gridSize.y / 2);
          tile.borderPath.relativeLineTo(-gridSize.x / 4, gridSize.y / 2);
          tile.borderPath.relativeLineTo(-gridSize.x / 2, 0);
          tile.borderPath.relativeLineTo(-gridSize.x / 4, -gridSize.y / 2);
          tile.borderPath.close();

          final double innerMargin = gridSize.x / 10;
          final Vector2 innerSize = gridSize - Vector2.all(innerMargin * 2);

          Vector2 start = Vector2(l + innerMargin, t + gridSize.y / 2);

          final innerBorderPath1 = Path();
          innerBorderPath1.moveTo(start.x, start.y);
          start += Vector2(innerSize.x / 4, -innerSize.y / 2);
          innerBorderPath1.lineTo(start.x, start.y);
          innerBorderPath1.close();
          tile.innerBorderPaths[1] = innerBorderPath1;

          final innerBorderPath2 = Path();
          innerBorderPath2.moveTo(start.x, start.y);
          start += Vector2(innerSize.x / 2, 0);
          innerBorderPath2.lineTo(start.x, start.y);
          innerBorderPath2.close();
          tile.innerBorderPaths[2] = innerBorderPath2;

          final innerBorderPath3 = Path();
          innerBorderPath3.moveTo(start.x, start.y);
          start += Vector2(innerSize.x / 4, innerSize.y / 2);
          innerBorderPath3.lineTo(start.x, start.y);
          innerBorderPath3.close();
          tile.innerBorderPaths[3] = innerBorderPath3;

          final innerBorderPath4 = Path();
          innerBorderPath4.moveTo(start.x, start.y);
          start += Vector2(-innerSize.x / 4, innerSize.y / 2);
          innerBorderPath4.lineTo(start.x, start.y);
          innerBorderPath4.close();
          tile.innerBorderPaths[4] = innerBorderPath4;

          final innerBorderPath5 = Path();
          innerBorderPath5.moveTo(start.x, start.y);
          start += Vector2(-innerSize.x / 2, 0);
          innerBorderPath5.lineTo(start.x, start.y);
          innerBorderPath5.close();
          tile.innerBorderPaths[5] = innerBorderPath5;

          final innerBorderPath6 = Path();
          innerBorderPath6.moveTo(start.x, start.y);
          start += Vector2(-innerSize.x / 4, -innerSize.y / 2);
          innerBorderPath6.lineTo(start.x, start.y);
          innerBorderPath6.close();
          tile.innerBorderPaths[6] = innerBorderPath6;
        }
      case TileShape.hexagonalHorizontal:
        throw 'Horizontal hexagonal map tile is not supported yet!';
      case TileShape.isometric:
        throw 'Isometric map tile is not supported yet!';
    }

    tile.position =
        Vector2(l - bleedingPixelHorizontal / 2, t - bleedingPixelVertical / 2);

    // tile.position = Vector2(
    //   l -
    //       (tile.srcSize.x - gridSize.x) / 2
    //       //
    //       +
    //       tile.offset.x,
    //   t -
    //       (tile.srcSize.y - gridSize.y)
    //       //
    //       +
    //       tile.offset.y,
    // );
    // tile.size = Vector2(
    //   tile.srcSize.x
    //   //  + bleedingPixelHorizontal
    //   ,
    //   tile.srcSize.y
    //   //  + bleedingPixelVertical
    //   ,
    // );
  }

  @override
  Future<void> onLoad() async {
    if (fogSpriteId != null && fogSprite == null) {
      fogSprite = Sprite(await Flame.images.load(fogSpriteId!));
    }

    double mapScreenSizeX = (gridSize.x * 3 / 4) * tileMapWidth;
    double mapScreenSizeY = (gridSize.y * tileMapHeight + gridSize.y / 2);
    mapScreenSize = Vector2(mapScreenSizeX, mapScreenSizeY);

    await loadTerrainData();
  }

  @override
  Future<void> onMount() async {
    super.onMount();
  }

  Future<void> loadTerrainData([dynamic mapData]) async {
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
    assert(tileFogOffset.x == data['tileFogOffsetX']);
    assert(tileFogOffset.y == data['tileFogOffsetY']);

    tileMapWidth = data['width'];
    tileMapHeight = data['height'];

    // 处理地块数据
    terrains.clear();
    for (var j = 0; j < tileMapHeight; ++j) {
      for (var i = 0; i < tileMapWidth; ++i) {
        final index = tilePosition2Index(i + 1, j + 1);
        final terrainData = data['terrains'][index];
        // final bool isLighted = terrainData['isLighted'] ?? false;
        // final bool isOnLightPerimeter =
        //     terrainData['isOnLightPerimeter'] ?? false;
        final bool isNonEnterable = terrainData['isNonEnterable'] ?? false;
        final bool isWater = terrainData['isWater'] ?? false;
        final String? kindString = terrainData['kind'];
        final String? objectId = terrainData['objectId'];
        final String? zoneId = terrainData['zoneId'];
        final String? nationId = terrainData['nationId'];
        final String? cityId = terrainData['cityId'];
        final String? locationId = terrainData['locationId'];
        // 这里不载入图片和动画，而是交给terrain自己从data中读取
        final tile = TileMapTerrain(
          map: this,
          mapId: id,
          terrainSpriteSheet: terrainSpriteSheet,
          tileShape: tileShape,
          data: terrainData,
          left: i + 1,
          top: j + 1,
          // isLighted: isLighted,
          // isOnLightPerimeter: isOnLightPerimeter,
          isNonEnterable: isNonEnterable,
          isWater: isWater,
          srcSize: tileSpriteSrcSize,
          gridSize: gridSize,
          kind: kindString,
          objectId: objectId,
          zoneId: zoneId,
          nationId: nationId,
          cityId: cityId,
          locationId: locationId,
          offset: tileOffset,
        );
        updateTileInfo(tile);
        terrains.add(tile);
        add(tile);
      }
    }

    // 处理非地块显示组件
    components.clear();
    for (final componentData in data['components']) {
      await loadTileMapComponentFromData(componentData);
    }
  }

  void setTerrainCaption(int left, int top, String? caption, TextStyle? style) {
    final tile = getTerrain(left, top);
    assert(tile != null);
    tile!.caption = caption;
    tile.captionStyle = style;
  }

  /// 这里的id仅仅是id，可能对应于纯数据对象
  /// 而不一定对应于可能以dart对象存在的object，后者是另外的概念
  void setTerrainObjectId(int left, int top, String? objectId) {
    final tile = getTerrain(left, top);
    assert(tile != null);
    tile!.objectId = objectId;
  }

  Future<void> loadHeroFromData(
    dynamic data, {
    Vector2? srcSize,
    Vector2? srcOffset,
  }) async {
    hero = await loadTileMapComponentFromData(data,
        srcSize: srcSize, isCharacter: true, srcOffset: srcOffset);
  }

  Future<TileMapComponent> loadTileMapComponentFromData(
    dynamic data, {
    Vector2? srcSize,
    bool isCharacter = false,
    Vector2? srcOffset,
  }) async {
    // assert(data['worldPosition'] != null);

    String componentId;
    if (data['id'] != null) {
      componentId = data['id'];
    } else {
      componentId =
          data['id'] = (data['name'] ?? '') + randomUID(withTime: true);
    }

    if (components.containsKey(componentId)) {
      return components[componentId]!;
    } else if (hero?.id == componentId) {
      add(hero!);
      components[hero!.id] = hero!;
      return hero!;
    }

    final component = TileMapComponent(
      map: this,
      id: componentId,
      data: data,
      left: data['worldPosition']?['left'],
      top: data['worldPosition']?['top'],
      offset: srcOffset,
      isCharacter: isCharacter,
      spriteSrcSize: srcSize,
      isHidden: data!['isHidden'] ?? false,
    );
    component.loadFrameData();
    updateTileInfo(component);
    add(component);
    components[componentId] = component;
    return component;
  }

  void saveComponentsFrameData() {
    for (final component in components.values) {
      component.saveFrameData();
    }
  }

  void removeTileMapComponentById(String id) {
    final obj = components.remove(id);
    obj?.removeFromParent();
  }

  void removeTileMapComponentByPosition(TilePosition tilePosition) {
    components.removeWhere((k, c) {
      if (c.tilePosition == tilePosition) {
        c.removeFromParent();
        return true;
      }
      return false;
    });
  }

  Future<void> moveCameraToHero({bool animated = true}) async {
    if (hero != null) {
      await moveCameraToTilePosition(hero!.left, hero!.top, animated: animated);
    }
  }

  void setCameraFollowHero(bool value) {
    if (hero != null) {
      if (value) {
        game.camera.follow(hero!);
      } else {
        game.camera.stop();
      }
    }
  }

  bool isTileOnScreen(TileInfo tile) {
    final topLeft = tile.topLeft;
    final bottomRight = tile.bottomRight;
    final isOnScreen = topLeft.x + 5 > 0 &&
        topLeft.y + 5 > 0 &&
        bottomRight.x - 5 < game.size.x &&
        bottomRight.y - 5 < game.size.y;

    return isOnScreen;
  }

  bool isTileWithinSight(TileMapTerrain tile) {
    if (showFogOfWar == false) {
      return true;
    } else {
      // return (tile?.isLighted ?? false) || (tile?.isOnLightPerimeter ?? false);
      return _tilesWithinSight.contains(tile);
    }
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

  /// 返回一个Map，index是1-4(正方形地块)或者1-6(六边形地块)
  /// 每个编号对应一个固定位置的相邻地块，如果值为 null 表示这个位置没有符合要求的相邻地块
  Map<int, TileMapTerrain> getTileNeighbors(TileMapTerrain tile,
      {List terrainKinds = const []}) {
    final neighbors = <int, TileMapTerrain>{};
    switch (tileShape) {
      case TileShape.orthogonal:
        // 对于正方形tilemap，邻居顺序是左(1)上(2)右(3)下(4)
        final t1 = getTerrain(tile.left - 1, tile.top);
        if (t1 != null &&
            (terrainKinds.isEmpty || terrainKinds.contains(t1.kind))) {
          neighbors[1] = t1;
        }
        final t2 = getTerrain(tile.left, tile.top - 1);
        if (t2 != null &&
            (terrainKinds.isEmpty || terrainKinds.contains(t2.kind))) {
          neighbors[2] = t2;
        }
        final t3 = getTerrain(tile.left + 1, tile.top);
        if (t3 != null &&
            (terrainKinds.isEmpty || terrainKinds.contains(t3.kind))) {
          neighbors[3] = t3;
        }
        final t4 = getTerrain(tile.left, tile.top + 1);
        if (t4 != null &&
            (terrainKinds.isEmpty || terrainKinds.contains(t4.kind))) {
          neighbors[4] = t4;
        }

      case TileShape.hexagonalVertical:
        // 对于横向六边形tilemap，邻居顺序是左上(1)上(2)右上(3)右下(4)下(5)左下(6)

        if (tile.left.isOdd) {
          final t1 = getTerrain(tile.left - 1, tile.top - 1);
          if (t1 != null &&
              (terrainKinds.isEmpty || terrainKinds.contains(t1.kind))) {
            neighbors[1] = t1;
          }
          final t2 = getTerrain(tile.left, tile.top - 1);
          if (t2 != null &&
              (terrainKinds.isEmpty || terrainKinds.contains(t2.kind))) {
            neighbors[2] = t2;
          }
          final t3 = getTerrain(tile.left + 1, tile.top - 1);
          if (t3 != null &&
              (terrainKinds.isEmpty || terrainKinds.contains(t3.kind))) {
            neighbors[3] = t3;
          }
          final t4 = getTerrain(tile.left + 1, tile.top);
          if (t4 != null &&
              (terrainKinds.isEmpty || terrainKinds.contains(t4.kind))) {
            neighbors[4] = t4;
          }
          final t5 = getTerrain(tile.left, tile.top + 1);
          if (t5 != null &&
              (terrainKinds.isEmpty || terrainKinds.contains(t5.kind))) {
            neighbors[5] = t5;
          }
          final t6 = getTerrain(tile.left - 1, tile.top);
          if (t6 != null &&
              (terrainKinds.isEmpty || terrainKinds.contains(t6.kind))) {
            neighbors[6] = t6;
          }
        } else {
          final t1 = getTerrain(tile.left - 1, tile.top);
          if (t1 != null &&
              (terrainKinds.isEmpty || terrainKinds.contains(t1.kind))) {
            neighbors[1] = t1;
          }
          final t2 = getTerrain(tile.left, tile.top - 1);
          if (t2 != null &&
              (terrainKinds.isEmpty || terrainKinds.contains(t2.kind))) {
            neighbors[2] = t2;
          }
          final t3 = getTerrain(tile.left + 1, tile.top);
          if (t3 != null &&
              (terrainKinds.isEmpty || terrainKinds.contains(t3.kind))) {
            neighbors[3] = t3;
          }
          final t4 = getTerrain(tile.left + 1, tile.top + 1);
          if (t4 != null &&
              (terrainKinds.isEmpty || terrainKinds.contains(t4.kind))) {
            neighbors[4] = t4;
          }
          final t5 = getTerrain(tile.left, tile.top + 1);
          if (t5 != null &&
              (terrainKinds.isEmpty || terrainKinds.contains(t5.kind))) {
            neighbors[5] = t5;
          }
          final t6 = getTerrain(tile.left - 1, tile.top + 1);
          if (t6 != null &&
              (terrainKinds.isEmpty || terrainKinds.contains(t6.kind))) {
            neighbors[6] = t6;
          }
        }
      case TileShape.isometric:
        throw 'Get neighbors of Isometric map tile is not supported yet!';
      case TileShape.hexagonalHorizontal:
        throw 'Get neighbors of Horizontal hexagonal map tile is not supported yet!';
    }
    return neighbors;
  }

  // Vector2 getRandomTilePositionOnMap() {
  // final left = random.nextInt(tileMapWidth);
  // final top = random.nextInt(tileMapHeight);

  // final pos = tilePosition2RenderPosition(left, top);
  // pos.x = pos.x - gridSize.x / 2 + random.nextDouble() * gridSize.x;
  // pos.y = pos.y - gridSize.y / 2 + random.nextDouble() * gridSize.y;

  // return Vector2(pos.x, pos.y);
  // }

  TileMapTerrain? getTerrain(int left, int top) {
    if (isPositionWithinMap(left, top)) {
      if (terrains.isEmpty) return null;
      return terrains[tilePosition2Index(left, top)];
    } else {
      return null;
    }
  }

  TileMapTerrain? getHeroAtTerrain() {
    if (hero != null) {
      final terrainIndex = tilePosition2Index(hero!.left, hero!.top);
      if (terrainIndex >= 0 && terrainIndex < terrains.length) {
        return terrains[terrainIndex];
      } else {
        if (kDebugMode) {
          logger.warn(
              'Hero is out of map bounds! left: ${hero!.left}, top: ${hero!.top}');
        }
      }
    }
    return null;
  }

  /// manhattan 距离算法
  int getTileDistance(TileMapTerrain start, TileMapTerrain end) {
    int result;
    final dx = end.slashLeft - start.slashLeft;
    final dy = end.slashTop - start.slashTop;
    if ((dx >= 0 && dy >= 0) || (dx <= 0 && dy <= 0)) {
      result = (dx + dy).abs();
    } else {
      result = math.max(dx.abs(), dy.abs());
    }
    // print('getTileDistance: ${start}, ${end}, result: ${result}')
    return result;
  }

  /// hScore(n) 是曼哈顿距离时的 A* 算法
  List<int>? calculateRoute(TileMapTerrain start, TileMapTerrain end,
      {List terrainKinds = const []}) {
    // print('calculating route: ${start.left},${start.top} to ${end.left},${end.top}')

    if (start == end || start.index == end.index) {
      return null;
    }

    // g(n): 原点到该点的距离
    final gScore = <int, int>{};
    gScore[start.index] = 0;
    // h(n): 该点到终点的距离
    final hScore = <int, int>{};
    hScore[start.index] = getTileDistance(start, end);
    // f(n) = g(n) + h(n)
    final fScore = <int, int>{};
    fScore[start.index] = hScore[start.index]!;

    // 节点返回路径，每个 key 对应的 value 代表了 key 的坐标的上一步骤的坐标
    final cameFrom = <int, int>{};
    List<int> reconstructPath(Map<int, int> cameFrom, int current) {
      final from = cameFrom[current];
      if (from != null) {
        final path = reconstructPath(cameFrom, from);
        return [...path, current];
      } else {
        return [current];
      }
    }

    // 已被计算的坐标
    final closed = <int>{};
    // 将要计算的坐标, key 是 tile index，value 是 离起点的距离
    final open = <int>[];
    open.add(start.index);
    // final distance = getTileDistance(start, end);

    while (open.isNotEmpty) {
      // 找到 f(x) 最小的节点
      open.sort((t1, t2) {
        assert(fScore.containsKey(t1));
        assert(fScore.containsKey(t2));
        return fScore[t1]!.compareTo(fScore[t2]!);
      });
      final nextIndex = open.first;
      final nextTile = terrains[nextIndex];
      if (nextIndex == end.index) {
        // route.path = reconstructPath(cameFrom, end.index)
        final route = reconstructPath(cameFrom, end.index);
        return route;
      }
      open.remove(nextIndex);
      closed.add(nextIndex);
      final neighbors = getTileNeighbors(nextTile, terrainKinds: terrainKinds);
      for (final neighbor in neighbors.values) {
        if (neighbor.isNonEnterable && neighbor.index != end.index) continue;
        if (closed.contains(neighbor.index)) continue;
        assert(gScore.containsKey(nextIndex));
        final tentetiveGScore = gScore[nextIndex]! + 1;
        var tentativelyBetter = false;
        if (!open.contains(neighbor.index) ||
            (tentetiveGScore < gScore[neighbor.index]!)) {
          tentativelyBetter = true;
        }
        if (tentativelyBetter) {
          cameFrom[neighbor.index] = nextIndex;
          gScore[neighbor.index] = tentetiveGScore;
          hScore[neighbor.index] = getTileDistance(neighbor, end);
          assert(gScore.containsKey(neighbor.index));
          assert(hScore.containsKey(neighbor.index));
          fScore[neighbor.index] =
              gScore[neighbor.index]! + hScore[neighbor.index]!;
          if (!open.contains(neighbor.index)) {
            open.add(neighbor.index);
          }
        }
      }
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

  // void lightUpAroundTile(TilePosition tilePosition,
  //     {int size = 1, List<dynamic> excludeTerrainKinds = const []}) {
  //   final start = getTerrain(tilePosition.left, tilePosition.top);
  //   assert(start != null);
  //   List<TileMapTerrain> pendingTiles = [start!];
  //   List<TileMapTerrain> nextPendingTiles = [];

  //   int lightedLayers = 0;
  //   do {
  //     for (final tile in pendingTiles) {
  //       if (excludeTerrainKinds.isEmpty ||
  //           !excludeTerrainKinds.contains(tile.kind)) {
  //         tile.isLighted = true;
  //         tile.isOnVisiblePerimeter = false;
  //         final neighbors = getNeighborTilePositions(tile.left, tile.top);
  //         for (final neighbor in neighbors) {
  //           final neighborTile = getTerrain(neighbor.left, neighbor.top);
  //           if (neighborTile == null) continue;
  //           if (!neighborTile.isLighted) {
  //             nextPendingTiles.add(neighborTile);
  //           }
  //         }
  //       }
  //     }

  //     pendingTiles = nextPendingTiles;
  //     nextPendingTiles = [];

  //     ++lightedLayers;
  //   } while (lightedLayers < (size + 1));

  //   for (final tile in pendingTiles) {
  //     tile.isOnVisiblePerimeter = true;
  //   }
  // }

  final Set<TileMapTerrain> _tilesWithinSight = {};

  void lightUpAroundTile(TilePosition tilePosition,
      {int size = 1, List<dynamic> excludeTerrainKinds = const []}) {
    final center = getTerrain(tilePosition.left, tilePosition.top);
    if (center == null) {
      logger.warn(
          'lightUpAroundTile: tile at position (${tilePosition.left}, ${tilePosition.top}) does not exist!');
      return;
    }
    _tilesWithinSight.clear();
    Set<TileMapTerrain> peremeterTiles = {center};
    Set<TileMapTerrain> pendingTiles = {};
    int lightedLayers = 0;
    do {
      for (final tile in peremeterTiles) {
        if (!excludeTerrainKinds.contains(tile.kind)) {
          tile.isLighted = true;

          if (lightedLayers < size) {
            _tilesWithinSight.add(tile);
          }
        }
        final neighbors = getTileNeighbors(tile);
        for (final neighbor in neighbors.values) {
          if (_tilesWithinSight.contains(neighbor) ||
              peremeterTiles.contains(neighbor)) {
            continue;
          }
          pendingTiles.add(neighbor);
        }
      }
      peremeterTiles.clear();
      peremeterTiles.addAll(pendingTiles);
      pendingTiles.clear();
      ++lightedLayers;
      if (lightedLayers > size) {
        break;
      }
    } while (peremeterTiles.isNotEmpty);
  }

  int tilePosition2Index(int left, int top) {
    return (left - 1) + (top - 1) * tileMapWidth;
  }

  Vector2 tilePosition2TileCenter(int left, int top) {
    late final double l, t;
    final int bl = left - 1, bt = top - 1;
    switch (tileShape) {
      case TileShape.orthogonal:
        l = (bl * gridSize.x);
        t = (bt * gridSize.y);
      case TileShape.hexagonalVertical:
        l = (bl * gridSize.x * (3 / 4)) + gridSize.x / 2;
        t = left.isOdd
            ? (bt * gridSize.y) + gridSize.y / 2
            : (bt * gridSize.y) + gridSize.y;
      case TileShape.isometric:
        throw 'Isometric map tile is not supported yet!';
      case TileShape.hexagonalHorizontal:
        throw 'Horizontal hexagonal map tile is not supported yet!';
    }
    return Vector2(l, t);
  }

  Vector2 tilePosition2TileLeftTop(int left, int top) {
    return tilePosition2TileCenter(left, top) - gridSize / 2;
  }

  // Vector2 tilePosition2RenderPosition(int left, int top) {
  //   late final double l, t; //, l, t;
  //   switch (tileShape) {
  //     case TileShape.orthogonal:
  //       l = ((left - 1) * gridSize.x);
  //       t = ((top - 1) * gridSize.y);
  //     case TileShape.hexagonalVertical:
  //       l = (left - 1) * gridSize.x * (3 / 4);
  //       t = left.isOdd
  //           ? (top - 1) * gridSize.y
  //           : (top - 1) * gridSize.y + gridSize.y / 2;
  //     case TileShape.isometric:
  //       throw 'Isometric map tile is not supported yet!';
  //     case TileShape.hexagonalHorizontal:
  //       throw 'Horizontal hexagonal map tile is not supported yet!';
  //   }
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
  //   return Vector2(l - (tileSpriteSrcSize.x - gridSize.x) / 2 + tileOffset.x,
  //       t - (tileSpriteSrcSize.y - gridSize.y) + tileOffset.y);
  // }

  Vector2 tilePosition2TileCenterOnScreen(int left, int top) {
    final worldPos = tilePosition2TileCenter(left, top);
    final result = game.worldPosition2Screen(worldPos);
    return result;
  }

  TilePosition worldPosition2Tile(Vector2 worldPos) {
    late final int left, top;
    switch (tileShape) {
      case TileShape.orthogonal:
        left = (worldPos.x / gridSize.x).floor();
        top = (worldPos.y / gridSize.y).floor();
      case TileShape.hexagonalVertical:
        int l = (worldPos.x / (gridSize.x * 3 / 4)).floor() + 1;
        final inTilePosX = worldPos.x - (l - 1) * (gridSize.x * 3 / 4);
        late final double inTilePosY;
        int t;
        if (l.isOdd) {
          t = (worldPos.y / gridSize.y).floor() + 1;
          inTilePosY = gridSize.y / 2 - (worldPos.y) % gridSize.y;
        } else {
          t = ((worldPos.y - gridSize.y / 2) / gridSize.y).floor() + 1;
          inTilePosY =
              gridSize.y / 2 - (worldPos.y - gridSize.y / 2) % gridSize.y;
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

  Future<void> moveCameraToTileMapCenter() async {
    await moveCameraToTilePosition(tileMapWidth ~/ 2, tileMapHeight ~/ 2);
  }

  Future<void> moveCameraToTilePosition(
    int left,
    int top, {
    bool animated = true,
    double speed = 250.0,
    double? zoom,
  }) {
    final dest = tilePosition2TileCenter(left, top);

    final completer = Completer();

    if (animated) {
      game.camera.moveTo2(dest, speed: speed, zoom: zoom, onComplete: () {
        completer.complete();
      });
    } else {
      game.camera.snapTo(dest);
      completer.complete();
    }

    return completer.future;
  }

  // void unselectTile() {
  //   // selectedTerrain?.isSelected = false;
  //   selectedTerrain = null;
  // }

  TileMapTerrain? trySelectTile(int left, int top) {
    final terrain = getTerrain(left, top);
    if (terrain != null) {
      if (terrain != selectedTerrain) {
        // unselectTile();
        // &&  (!terrain.isNonEnterable || selectNonInteractable)) {
        // terrain.isSelected = true;
        selectedTerrain = terrain;
      }
    }
    return terrain;
  }

  void componentWalkToPreviousTile(TileMapComponent component) {
    if (component.prevRouteNode == null) return;

    assert(components.containsKey(component.id));

    component.currentRoute = null;
    componentWalkToTilePositionByRoute(
      component,
      [
        // 这里不能直接使用 component.index，因为 component 的 tileinfo 还没有被更新
        tilePosition2Index(component.left, component.top),
        component.prevRouteNode!.index
      ],
      backwardMoving: true,
    );

    component.prevRouteNode = null;
  }

  void componentWalkToTilePositionByRoute(
    TileMapComponent component,
    List<int> route, {
    OrthogonalDirection? finishMoveDirection,
    FutureOr<void> Function(TileMapTerrain terrain, TileMapTerrain? nextTerrain,
            bool isFinished)?
        onStepCallback,
    bool backwardMoving = false,
  }) {
    assert(components.containsKey(component.id));

    if (component.isWalking) {
      if (kDebugMode) {
        print('tilemap warning: try to move object while it is already moving');
      }
      return;
    }

    if (tilePosition2Index(component.left, component.top) != route.first) {
      if (kDebugMode) {
        print(
            'tilemap warning: the start position of the route does not match the current position of the component');
      }
      final tilePosition = index2TilePosition(route.first);
      component.tilePosition = tilePosition;
      updateTileInfo(component);
    }

    component.isBackwardWalking = backwardMoving;

    // component.onStepCallback = onStepCallback;
    // if (component == hero && isCameraFollowHero) {
    //   setCameraFollowHero(true);
    //   component.onStepCallback = (terrain, target, isFinished) async {
    //     setCameraFollowHero(false);
    //     onStepCallback?.call(terrain, target, isFinished);
    //   };
    // } else {
    // component.onStepCallback = onStepCallback;
    // }

    if (onStepCallback != null) {
      component.onStepCallback = onStepCallback;
    }

    // 默认移动结束后面朝主视角
    component.finishWalkDirection = finishMoveDirection;
    component.currentRoute = route
        .map((index) {
          final tilePos = index2TilePosition(index);
          final worldPos = tilePosition2TileCenter(tilePos.left, tilePos.top);
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

  void componentFinishWalk(
    TileMapComponent component, {
    bool stepCallback = false,
    TileMapTerrain? terrain,
    TileMapTerrain? target,
  }) async {
    if (stepCallback) {
      assert(terrain != null);
      await component.onStepCallback?.call(terrain!, target, true);
    }
    component.prevRouteNode = null;
    component.currentRoute = null;
    if (component.finishWalkDirection != null) {
      component.setDirection(component.finishWalkDirection!);
    }
    component.finishWalkDirection = null;
    component.isWalkCanceled = false;
    component.stopAnimation();
    if (component.changedRoute != null) {
      componentWalkToTilePositionByRoute(
        component,
        component.changedRoute!,
        onStepCallback: component.onStepCallback,
      );
      component.changedRoute = null;
    } else {
      component.onStepCallback = null;
    }
  }

  void componentUpdateWalkPosition(TileMapComponent component) {
    if (component.isWalking) return;
    if (component.currentRoute == null) return;

    if (component.currentRoute!.isEmpty) {
      componentFinishWalk(component);
      return;
    }

    final prevRouteNode = component.currentRoute!.last;
    component.currentRoute!.removeLast();

    // refreshTileInfo(object);
    final tile = prevRouteNode.tilePosition;
    final terrain = getTerrain(tile.left, tile.top);
    assert(terrain != null);

    if (component.currentRoute!.isEmpty) {
      componentFinishWalk(component, stepCallback: true, terrain: terrain!);
      return;
    }

    if (component.isWalkCanceled) {
      componentFinishWalk(component);
      return;
    }

    final nextTile = component.currentRoute!.last.tilePosition;
    final TileMapTerrain nextTerrain = getTerrain(nextTile.left, nextTile.top)!;
    if (nextTerrain.isWater) {
      component.isOnWater = true;
    } else {
      component.isOnWater = false;
    }
    // 如果路径上下一个目标是不可进入的，且该目标是路径上最后一个目标
    // 此种情况结束移动，但仍会触发对最终目标的交互
    if (component.currentRoute!.length == 1 && nextTerrain.isNonEnterable) {
      componentFinishWalk(component,
          stepCallback: true, terrain: terrain!, target: nextTerrain);
      return;
    }

    component.onStepCallback?.call(terrain!, nextTerrain, false);
    // prevRouteNode 记录了前一次移动时的位置，但第一次移动时，此值为Null
    component.prevRouteNode = prevRouteNode;

    // 这里要多检查一次，因为有可能在 onBeforeStepCallback 中被取消移动
    // 但这里的finishMove 不传递 terrain，这样不会再次触发 onAfterMoveCallback
    if (component.isWalkCanceled) {
      componentFinishWalk(component);
      return;
    }

    component.walkTo(
      target: nextTile,
      targetPosition: nextTerrain.position,
      targetDirection: direction2Orthogonal(directionTo(
          component.tilePosition, nextTile,
          backward: component.isBackwardWalking)),
      backward: component.isBackwardWalking,
    );
  }

  void darkenAllTiles() {
    for (final tile in terrains) {
      tile.isLighted = false;
    }
    _tilesWithinSight.clear();
  }

  void lightUpAllTiles() {
    for (final tile in terrains) {
      tile.isLighted = true;
    }
    // _tilesWithinSight.clear();
  }

  @override
  void updateTree(double dt) {
    super.updateTree(dt);

    if (hero != null) {
      componentUpdateWalkPosition(hero!);
    }

    if (autoUpdateComponent || (hero?.isWalking ?? false)) {
      for (final component in components.values) {
        if (component == hero) continue;
        componentUpdateWalkPosition(component);
      }
    }
  }

  @override
  bool get isVisible => true;

  // canvas.save();
  // canvas.transform(Float64List.fromList(transformMatrix.storage));
  // canvas.restore();
  @override
  void renderTree(Canvas canvas) {
    for (var c in children.whereType<TileMapTerrain>()) {
      if (!c.isVisible) continue;
      c.renderTree(canvas);
    }

    for (final tile in terrains) {
      if (!isTileOnScreen(tile)) continue;

      if (isEditorMode) {
        canvas.drawPath(tile.borderPath, gridPaint);
      }

      // 国界线
      if (tile.nationId != null) {
        // 取出门派模式下此地块所属门派的颜色
        final Color? color = zoneColors[kColorModeNation][tile.index];
        assert(
            color != null,
            'TileMapTerrain.render: tile (index: ${tile.index}, '
            'left: ${tile.left}, top: ${tile.top}, nationId: ${tile.nationId}) '
            'has no color defined in map.zoneColors');

        final bordersData = tile.data['borders'] ?? {};

        for (final neighborIndex in kNeighborIndexes) {
          if (bordersData[neighborIndex] == true) {
            assert(tile.innerBorderPaths[neighborIndex] != null);

            var borderPaint = cachedBorderPaints[tile.index];
            borderPaint ??= cachedBorderPaints[tile.index] = Paint()
              ..strokeWidth = 1.5
              ..style = PaintingStyle.stroke
              ..color = color!;

            // canvas.drawPath(
            //     innerBorderPaths[neighborIndex]!, TileMap.borderShadowPaint);
            // canvas.drawShadow(
            //     innerBorderPaths[neighborIndex]!, Colors.black, 5.0, false);
            canvas.drawPath(tile.innerBorderPaths[neighborIndex]!, borderPaint);
          }
        }
      }

      // 战争迷雾
      if (showFogOfWar && !isEditorMode) {
        if (tile.isLighted) {
          if (!isTileWithinSight(tile)) {
            canvas.drawPath(tile.borderPath, visiblePerimeterPaint);
          }
        } else {
          fogSprite?.render(canvas,
              position: tile.position + tileFogOffset,
              size: tile.size - tileFogOffset * 2);
        }
      }

      // 地块涂色模式
      if (colorMode != kColorModeNone) {
        final color = zoneColors[colorMode][tile.index];
        if (color != null) {
          var paint = cachedPaints[color];
          paint ??= cachedPaints[color] = Paint()
            ..style = PaintingStyle.fill
            ..color = color.withAlpha(120);
          canvas.drawPath(tile.borderPath, paint);
        }
      }

      // 编辑模式下的不可进入标记颜色
      if (isEditorMode && colorMode == kColorModeNone && tile.isNonEnterable) {
        canvas.drawPath(tile.borderPath, uninteractablePaint);
      }

      // 据点或地图对象名字
      if (tile.caption != null) {
        drawScreenText(
          canvas,
          tile.caption!,
          position: tile.position.toOffset(),
          config: ScreenTextConfig(
            size: tile.size,
            outlined: true,
            anchor: Anchor.topCenter,
            padding: EdgeInsets.only(top: gridSize.y / 4 * 3),
            textStyle: tile.captionStyle ?? captionStyle,
          ),
        );
      }
    }

    if (showSelected && selectedTerrain != null) {
      canvas.drawPath(selectedTerrain!.borderPath, selectedPaint);
    }

    if (showHover && hoveringTerrain != null) {
      if (isEditorMode || !showFogOfWar || hoveringTerrain!.isLighted) {
        canvas.drawPath(hoveringTerrain!.borderPath, hoverPaint);
      }
    }

    for (var c in children.whereType<TileMapComponent>()) {
      if (!c.isVisible) continue;
      c.renderTree(canvas);
    }
  }

  @override
  bool containsPoint(Vector2 point) {
    return true;
  }
}
