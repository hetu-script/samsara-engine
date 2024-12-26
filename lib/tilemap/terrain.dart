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

  bool _isNonEnterable, _isLighted;

  set isNonEnterable(value) {
    _isNonEnterable = value;
    if (data != null) {
      data?['isNonEnterable'] = value;
    }
  }

  bool get isNonEnterable => _isNonEnterable;

  set isLighted(value) {
    _isLighted = value;
    if (data != null) {
      data?['isLighted'] = value;
    }
  }

  bool get isLighted => _isLighted;

  bool isOnVisiblePerimeter = false;

  /// 此地块上的物体
  /// 此属性代表一些通常固定不移动的可互动对象，例如传送门、开关、地牢入口等等
  /// 对于可以在地图上移动的物体，地块本身并不保存，
  /// 由 tilemap 上的 movingObjects 维护
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

  set spriteIndex(int? value) {
    if (data != null) {
      data?['spriteIndex'] = value;
      if (value != null) {
        _sprite = terrainSpriteSheet.getSpriteById(value);
      } else {
        _sprite = null;
      }
    }
  }

  int? get spriteIndex {
    return data?['spriteIndex'];
  }

  set overlaySprite(dynamic spriteData) {
    assert(spriteData != null);
    jsonLikeDataAssign(data?['overlaySprite'], spriteData);
    tryLoadSprite(overlay: true);
  }

  dynamic get overlaySprite {
    return data?['overlaySprite'];
  }

  // 随机数，用来让多个 tile 的贴图动画错开播放
  late final double _overlayAnimationOffset;
  double _overlayAnimationOffsetValue = 0;

  Future<void> _tryLoadSpriteFromData({bool overlay = false}) async {
    // if (data == null) return;

    final d = overlay ? (data?['overlaySprite']) : data;
    // assert(d != null);

    Sprite? sprite;
    final String? spritePath = d?['sprite'];
    final int? spriteIndex = d?['spriteIndex'];
    if (spritePath != null) {
      sprite = await Sprite.load(spritePath, srcSize: srcSize);
    } else if (spriteIndex != null) {
      sprite = terrainSpriteSheet.getSpriteById(spriteIndex);
    } else {
      sprite = null;
    }
    if (!overlay) {
      _sprite = sprite;
    } else {
      _overlaySprite = sprite;
    }
  }

  Future<void> _tryLoadAnimationFromData({bool overlay = false}) async {
    final d =
        overlay ? data?['overlaySprite']?['animation'] : data?['animation'];
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
    if (!overlay) {
      _animation = animation;
    } else {
      _overlayAnimation = animation;
    }
  }

  void tryLoadSprite({bool overlay = false}) async {
    await _tryLoadSpriteFromData(overlay: overlay);
    await _tryLoadAnimationFromData(overlay: overlay);
  }

  void clearAllSprite() {
    data.remove('spriteIndex');
    _sprite = null;
    _animation = null;
    data['overlaySprite'].clear();
    _overlaySprite = null;
    _overlayAnimation = null;
  }

  void clearSprite() {
    data.remove('sprite');
    data.remove('spriteIndex');
    _sprite = null;
  }

  void clearOverlaySprite() {
    data?['overlaySprite']?.remove('sprite');
    data?['overlaySprite']?.remove('spriteIndex');
    _overlaySprite = null;
  }

  void clearAnimation() {
    data.remove('animation');
    _animation = null;
  }

  void clearOverlayAnimation() {
    data?['overlaySprite']?.remove('animation');
    _overlayAnimation = null;
  }

  TileMapTerrain({
    required this.mapId,
    required this.terrainSpriteSheet,
    required TileShape tileShape,
    // this.renderDirection = TileRenderDirection.bottomRight,
    this.data,
    required int left,
    required int top,
    bool isNonEnterable = false,
    bool isLighted = true,
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
                  offset: Offset(-0.5, -0.5),
                  color: Colors.black),
              Shadow(
                  // bottomRight
                  offset: Offset(0.5, -0.5),
                  color: Colors.black),
              Shadow(
                  // topRight
                  offset: Offset(0.5, 0.5),
                  color: Colors.black),
              Shadow(
                  // topLeft
                  offset: Offset(-0.5, 0.5),
                  color: Colors.black),
            ],
          ),
        ),
        _kind = kind,
        _isNonEnterable = isNonEnterable,
        _isLighted = isLighted,
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
    _sprite?.renderRect(canvas, renderRect);
    _animation?.ticker.currentFrame.sprite.renderRect(canvas, renderRect);
    _overlaySprite?.renderRect(canvas, renderRect);
    _overlayAnimation?.ticker.currentFrame.sprite
        .renderRect(canvas, renderRect);

    if (caption != null) {
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
  }

  @override
  void update(double dt) {
    super.update(dt);
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
