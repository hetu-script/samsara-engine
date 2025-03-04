import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';
import 'package:samsara/extensions.dart';

import '../components/game_component.dart';
import 'tile_mixin.dart';
import '../animation/sprite_animation.dart';
import '../utils/json.dart';
import '../paint/paint.dart';
import 'tilemap.dart';

enum TileMapTerrainKind {
  none,
  empty,
  plain,
  forest,
  mountain,
  shore,
  lake,
  sea,
  river,
  road,
}

TileMapTerrainKind getTerrainKind(String? kind) =>
    TileMapTerrainKind.values.firstWhere((element) => element.name == kind,
        orElse: () => TileMapTerrainKind.none);

class TileMapTerrain extends GameComponent with TileInfo {
  static const defaultAnimationStepTime = 0.2;

  final TileMap map;

  /// internal data of this tile, possible json or other user-defined data form.
  final dynamic data;

  final String mapId;

  final SpriteSheet terrainSpriteSheet;

  bool isSelected = false;
  bool isHovered = false;

  // final TileRenderDirection renderDirection;

  TileMapTerrainKind get terrainKind => getTerrainKind(_kind);
  String? _kind;
  String? get kind => _kind;
  set kind(String? value) {
    _kind = value;
    data?['kind'] = value;
  }

  bool get isWater =>
      terrainKind == TileMapTerrainKind.sea ||
      terrainKind == TileMapTerrainKind.lake;

  final String? _zoneIndex;
  String? get zoneId => _zoneIndex;

  String? _nationId;
  String? get nationId => _nationId;
  set nationId(value) {
    _nationId = value;
    if (data != null) {
      data?['nationId'] = value;
    }
  }

  String? _locationId;
  String? get locationId => _locationId;
  set locationId(value) {
    _locationId = value;
    if (data != null) {
      data?['locationId'] = value;
    }
  }

  bool _isNonEnterable, _isLighted; //, _isOnLightPerimeter;

  bool get isNonEnterable => _isNonEnterable;
  set isNonEnterable(bool value) {
    _isNonEnterable = value;
    if (data != null) {
      data?['isNonEnterable'] = value;
    }
  }

  bool get isLighted => _isLighted;
  set isLighted(value) {
    _isLighted = value;
    if (data != null) {
      data?['isLighted'] = value;
    }
  }

  // bool get isOnLightPerimeter => _isOnLightPerimeter;
  // set isOnLightPerimeter(value) {
  //   _isOnLightPerimeter = value;
  //   if (data != null) {
  //     data?['isOnLightPerimeter'] = value;
  //   }
  // }

  /// 此地块上的物体
  /// 通常用此属性代表一些固定不移动的可互动对象，例如传送门、开关、地牢入口等等
  /// 这些对象不一定是地图渲染时的component，可能纯是脚本数据
  String? _objectId;

  set objectId(value) {
    _objectId = value;
    if (data != null) {
      data?['objectId'] = value;
    }
  }

  String? get objectId => _objectId;

  // 显示标签
  String? caption;

  final TextPaint _captionPaint;

  /// 显示贴图
  Sprite? _sprite, _overlaySprite;
  SpriteAnimationWithTicker? _animation, _overlayAnimation;

  // set spriteIndex(int? value) {
  //   if (data != null) {
  //     data?['spriteIndex'] = value;
  //     if (value != null) {
  //       _sprite = terrainSpriteSheet.getSpriteById(value);
  //     } else {
  //       _sprite = null;
  //     }
  //   }
  // }

  // int? get spriteIndex {
  //   return data?['spriteIndex'];
  // }

  // set overlaySprite(dynamic overlayData) {
  //   // assert(spriteData != null);
  //   // jsonLikeDataAssign(data?['overlaySprite'], spriteData);
  //   if (data != null) {
  //     data['overlaySprite'] = overlayData;
  //     tryLoadSprite(overlay: true);
  //   }
  // }

  // dynamic get overlaySprite {
  //   return data?['overlaySprite'];
  // }

  // 随机数，用来让多个 tile 的贴图动画错开播放
  late final double _overlayAnimationOffset;
  double _overlayAnimationOffsetValue = 0;

  Future<void> _tryLoadSpriteFromData({bool isOverlay = false}) async {
    // if (data == null) return;

    final spriteData = isOverlay ? (data?['overlaySprite']) : data;
    // assert(d != null);

    Sprite? sprite;
    final String? spritePath = spriteData?['sprite'];
    final int? spriteIndex = spriteData?['spriteIndex'];
    if (spritePath != null) {
      sprite = await Sprite.load(spritePath, srcSize: srcSize);
    } else if (spriteIndex != null) {
      sprite = terrainSpriteSheet.getSpriteById(spriteIndex);
    } else {
      sprite = null;
    }
    if (!isOverlay) {
      _sprite = sprite;
    } else {
      _overlaySprite = sprite;
    }
  }

  Future<void> _tryLoadAnimationFromData({bool isOverlay = false}) async {
    final d =
        isOverlay ? data?['overlaySprite']?['animation'] : data?['animation'];
    // if (d == null) return;

    SpriteAnimationWithTicker? animation;
    final String? path = d?['path'];
    // final int? animationFrameCount = d?['frameCount'];
    final int? row = d?['row'];
    final int from = d?['from'] ?? 0;
    final int? to = d?['to'];
    final double stepTime = d?['stepTime'] ?? defaultAnimationStepTime;
    final bool loop = d?['loop'] ?? true;
    if (path != null) {
      final sheet =
          SpriteSheet(image: await Flame.images.load(path), srcSize: srcSize);
      animation = SpriteAnimationWithTicker(
        animation: sheet.createAnimation(
          row: row ?? 0,
          stepTime: stepTime,
          loop: loop,
          from: from,
          to: to ?? sheet.columns,
        ),
      );
    } else if (row != null) {
      animation = SpriteAnimationWithTicker(
        animation: terrainSpriteSheet.createAnimation(
          row: row,
          stepTime: stepTime,
          loop: loop,
          from: from,
          to: to,
        ),
      );
    } else {
      animation = null;
    }
    if (!isOverlay) {
      _animation = animation;
    } else {
      _overlayAnimation = animation;
    }
  }

  @override
  FutureOr<void> onLoad() {
    tryLoadSprite();
    if (data['overlaySprite'] != null) {
      tryLoadSprite(isOverlay: true);
    }
  }

  void tryLoadSprite({bool isOverlay = false}) async {
    await _tryLoadSpriteFromData(isOverlay: isOverlay);
    await _tryLoadAnimationFromData(isOverlay: isOverlay);
  }

  void overrideSpriteData(dynamic spriteData, {bool isOverlay = false}) {
    jsonLikeDataAssign(data, spriteData);
    tryLoadSprite(isOverlay: isOverlay);
  }

  void clearAllSprite() {
    data['sprite'] = null;
    data['spriteIndex'] = null;
    data['overlaySprite'] = null;
    _sprite = null;
    _animation = null;
    _overlaySprite = null;
    _overlayAnimation = null;
  }

  void clearSprite() {
    data['sprite'] = null;
    data['spriteIndex'] = null;
    _sprite = null;
  }

  void clearAnimation() {
    data['animation'] = null;
    _animation = null;
  }

  void clearOverlaySprite() {
    data?['overlaySprite']?['sprite'] = null;
    data?['overlaySprite']?['spriteIndex'] = null;
    _overlaySprite = null;
  }

  void clearOverlayAnimation() {
    data?['overlaySprite']?['animation'] = null;
    _overlayAnimation = null;
  }

  TileMapTerrain({
    required this.map,
    required this.mapId,
    required this.terrainSpriteSheet,
    required TileShape tileShape,
    // this.renderDirection = TileRenderDirection.bottomRight,
    this.data,
    required int left,
    required int top,
    bool isNonEnterable = false,
    bool isLighted = true,
    // bool isOnLightPerimeter = false,
    required Vector2 srcSize,
    required Vector2 gridSize,
    String? kind,
    String? zoneId,
    String? nationId,
    String? locationId,
    String? objectId,
    required TextStyle captionStyle,
    Sprite? sprite,
    SpriteAnimationWithTicker? animation,
    Sprite? overlaySprite,
    SpriteAnimationWithTicker? overlayAnimation,
    Vector2? offset,
  })  : assert(!gridSize.isZero()),
        assert(!srcSize.isZero()),
        _overlayAnimation = overlayAnimation,
        _animation = animation,
        _captionPaint = TextPaint(
          style: captionStyle.copyWith(
            color: Colors.white,
            fontSize: 7.0,
            shadows: const [
              Shadow(
                  // bottomLeft
                  offset: Offset(-0.01, -0.01),
                  color: Colors.black),
              Shadow(
                  // bottomRight
                  offset: Offset(0.01, -0.01),
                  color: Colors.black),
              Shadow(
                  // topRight
                  offset: Offset(0.01, 0.01),
                  color: Colors.black),
              Shadow(
                  // topLeft
                  offset: Offset(-0.01, 0.01),
                  color: Colors.black),
            ],
          ),
        ),
        _kind = kind,
        _isNonEnterable = isNonEnterable,
        _isLighted = isLighted,
        // _isOnLightPerimeter = isOnLightPerimeter,
        _zoneIndex = zoneId,
        _nationId = nationId,
        _locationId = locationId,
        _objectId = objectId,
        _sprite = sprite,
        _overlaySprite = overlaySprite {
    this.tileShape = tileShape;
    this.gridSize = gridSize;
    this.srcSize = srcSize;
    this.offset = offset ?? Vector2.zero();

    tilePosition = TilePosition(left, top);

    _overlayAnimationOffset = math.Random().nextDouble() * 5;
  }

  @override
  void render(Canvas canvas) {
    if (!map.isTileVisibleOnScreen(this)) return;

    _sprite?.renderRect(canvas, renderRect);
    _animation?.ticker.currentFrame.sprite.renderRect(canvas, renderRect);
    _overlaySprite?.renderRect(canvas, renderRect);

    if (map.isEditorMode || map.isTileWithinSight(this)) {
      _overlayAnimation?.ticker.currentFrame.sprite
          .renderRect(canvas, renderRect);
    }
  }

  void drawCaption(Canvas canvas) {
    if (caption == null) return;

    drawScreenText(
      canvas,
      caption!,
      position: renderRect.topLeft,
      textPaint: _captionPaint,
      config: ScreenTextConfig(
        size: renderRect.size.toVector2(),
        outlined: true,
        anchor: Anchor.center,
        padding: EdgeInsets.only(top: gridSize.y / 2 - 5.0),
      ),
    );
  }

  // TODO:计算是否在屏幕上可见
  @override
  bool get isVisible => true;

  @override
  void update(double dt) {
    super.update(dt);
    if (map.isTileVisibleOnScreen(this)) {
      _animation?.ticker.update(dt);
      if (_overlayAnimation != null) {
        _overlayAnimation?.ticker.update(dt);
        if (_overlayAnimation!.ticker.done()) {
          _overlayAnimationOffsetValue += dt;
          if (_overlayAnimationOffsetValue >= _overlayAnimationOffset) {
            _overlayAnimationOffsetValue = 0;
            _overlayAnimation!.ticker.reset();
          }
        }
      }
    }
  }
}
