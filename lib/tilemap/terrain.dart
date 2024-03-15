import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';

import '../component/game_component.dart';
import 'tile_mixin.dart';
import '../animation/sprite_animation.dart';
import 'tilemap.dart';
import '../utils/json.dart';
import '../paint.dart';

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

  final borderPath = Path();
  final shadowPath = Path();
  late Rect rect;

  final double offsetX, offsetY;

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
  final String? _nationId;
  String? get nationId => _nationId;
  final String? _locationId;
  String? get locationId => _locationId;

  // 显示标签
  String? caption;
  // set caption(String? value) {
  //   _caption = value;
  //   data?['caption'] = value;
  // }

  // String? get caption => _caption;

  bool _isNonInteractable, _isLighted;

  set isNonInteractable(value) {
    _isNonInteractable = value;
    data?['isNonInteractable'] = value;
  }

  bool get isNonInteractable => _isNonInteractable;

  set isLighted(value) {
    _isLighted = value;
    data?['isLighted'] = value;
  }

  bool get isLighted => _isLighted;

  final TextPaint _captionPaint;

  /// 此地块上的物体
  /// 此属性代表一些通常固定不移动的可互动对象，例如传送门、开关、地牢入口等等
  /// 对于可以在地图上移动的物体，地块本身并不保存，
  /// 由 tilemap 上的 movingObjects 维护
  String? objectId;

  /// 显示贴图
  Sprite? _sprite, _overlaySprite;
  SpriteAnimationWithTicker? _animation, _overlayAnimation;

  set spriteIndex(int? value) {
    data?['spriteIndex'] = value;
    if (value != null) {
      _sprite = TileMap.terrainSpriteSheet.getSpriteById(value);
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
    if (data == null) return;

    final d = overlay ? (data?['overlaySprite']) : data;
    assert(d != null);

    Sprite? sprite;
    final String? spritePath = d?['sprite'];
    final int? spriteIndex = d?['spriteIndex'];
    if (spritePath != null) {
      sprite = await Sprite.load(
        spritePath,
        srcSize: Vector2(srcWidth, srcHeight),
      );
    } else if (spriteIndex != null) {
      sprite = TileMap.terrainSpriteSheet.getSpriteById(spriteIndex);
    }
    if (sprite != null) {
      if (!overlay) {
        _sprite = sprite;
      } else {
        _overlaySprite = sprite;
      }
    }
  }

  Future<void> _tryLoadAnimationFromData({bool overlay = false}) async {
    final d =
        overlay ? data?['overlaySprite']?['animation'] : data?['animation'];
    if (d == null) return;

    SpriteAnimationWithTicker? animation;
    final String? animationPath = d?['path'];
    final int? animationFrameCount = d?['frameCount'];
    final int? animationRow = d?['row'];
    final int? animationStart = d?['start'];
    final int? animationEnd = d?['end'];
    final bool loop = d?['loop'] ?? (overlay ? false : true);
    if (animationPath != null) {
      final sheet = SpriteSheet(
          image: await Flame.images.load(animationPath),
          srcSize: Vector2(
            srcWidth,
            srcHeight,
          ));
      animation = SpriteAnimationWithTicker(
          animation: sheet.createAnimation(
              row: animationRow ?? 0,
              stepTime: defaultAnimationStepTime,
              loop: loop,
              from: 0,
              to: animationFrameCount ?? sheet.columns));
    } else if (animationRow != null) {
      animation = SpriteAnimationWithTicker(
          animation: TileMap.terrainSpriteSheet.createAnimation(
        row: animationRow,
        stepTime: defaultAnimationStepTime,
        loop: loop,
        from: animationStart ?? 0,
        to: animationEnd ?? TileMap.terrainSpriteSheet.columns,
      ));
    }
    if (animation != null) {
      if (!overlay) {
        _animation = animation;
      } else {
        _overlayAnimation = animation;
      }
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
    required TileShape tileShape,
    // this.renderDirection = TileRenderDirection.bottomRight,
    this.data,
    required int left,
    required int top,
    bool isNonInteractable = false,
    bool isLighted = true,
    required double srcWidth,
    required double srcHeight,
    required double gridWidth,
    required double gridHeight,
    String? kind,
    String? zoneId,
    String? nationId,
    String? locationId,
    String? caption,
    required TextStyle captionStyle,
    Sprite? sprite,
    SpriteAnimationWithTicker? animation,
    Sprite? overlaySprite,
    SpriteAnimationWithTicker? overlayAnimation,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.objectId,
  })  : _overlayAnimation = overlayAnimation,
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
        _isNonInteractable = isNonInteractable,
        _isLighted = isLighted,
        _zoneIndex = zoneId,
        _nationId = nationId,
        _locationId = locationId,
        // _caption = caption,
        _sprite = sprite,
        _overlaySprite = overlaySprite {
    this.tileShape = tileShape;
    this.gridWidth = gridWidth;
    this.gridHeight = gridHeight;
    this.srcWidth = width = srcWidth;
    this.srcHeight = height = srcHeight;
    srcOffsetY = 0;
    tilePosition = TilePosition(left, top);
    generateRect();

    _overlayAnimationOffset = math.Random().nextDouble() * 5;
  }

  void generateRect() {
    double bleendingPixelHorizontal = width * 0.04;
    double bleendingPixelVertical = height * 0.04;
    if (bleendingPixelHorizontal > 2) {
      bleendingPixelHorizontal = 2;
    }
    if (bleendingPixelVertical > 2) {
      bleendingPixelVertical = 2;
    }

    late final double l, t; // l, t,
    switch (tileShape) {
      case TileShape.orthogonal:
        l = ((left - 1) * gridWidth);
        t = ((top - 1) * gridHeight);
        final border = Rect.fromLTWH(l, t, gridWidth, gridHeight);
        borderPath.addRect(border);
        break;
      case TileShape.hexagonalVertical:
        l = (left - 1) * gridWidth * (3 / 4);
        t = left.isOdd
            ? (top - 1) * gridHeight
            : (top - 1) * gridHeight + gridHeight / 2;
        borderPath.moveTo(l, t + gridHeight / 2);
        borderPath.relativeLineTo(gridWidth / 4, -gridHeight / 2);
        borderPath.relativeLineTo(gridWidth / 2, 0);
        borderPath.relativeLineTo(gridWidth / 4, gridHeight / 2);
        borderPath.relativeLineTo(-gridWidth / 4, gridHeight / 2);
        borderPath.relativeLineTo(-gridWidth / 2, 0);
        borderPath.relativeLineTo(-gridWidth / 4, -gridHeight / 2);
        borderPath.close();
        shadowPath.moveTo(l - bleendingPixelHorizontal + offsetX,
            t + gridHeight / 2 + offsetX);
        shadowPath.relativeLineTo(gridWidth / 4 + bleendingPixelHorizontal,
            -gridHeight / 2 - bleendingPixelVertical);
        shadowPath.relativeLineTo(gridWidth / 2, 0);
        shadowPath.relativeLineTo(gridWidth / 4 + bleendingPixelHorizontal,
            gridHeight / 2 + bleendingPixelVertical);
        shadowPath.relativeLineTo(-gridWidth / 4 - bleendingPixelHorizontal,
            gridHeight / 2 + bleendingPixelVertical);
        shadowPath.relativeLineTo(-gridWidth / 2, 0);
        shadowPath.relativeLineTo(-gridWidth / 4 - bleendingPixelHorizontal,
            -gridHeight / 2 - bleendingPixelVertical);
        shadowPath.close();
        break;
      case TileShape.isometric:
        throw 'Isometric map tile is not supported yet!';
      case TileShape.hexagonalHorizontal:
        throw 'Vertical hexagonal map tile is not supported yet!';
    }
    // switch (renderDirection) {
    //   case TileRenderDirection.bottomRight:
    //     l = bl - (width - gridWidth);
    //     t = bt - (height - gridHeight);
    //     break;
    //   case TileRenderDirection.bottomLeft:
    //     l = bl;
    //     t = bt - (height - gridHeight);
    //     break;
    //   case TileRenderDirection.topRight:
    //     l = bl - (width - gridWidth);
    //     t = bt;
    //     break;
    //   case TileRenderDirection.topLeft:
    //     l = bl;
    //     t = bt;
    //     break;
    //   case TileRenderDirection.bottomCenter:
    //     break;
    // }
    rect = Rect.fromLTWH(
        l - (width - gridWidth) / 2 - bleendingPixelHorizontal / 2 + offsetX,
        t - (height - gridHeight) - bleendingPixelVertical / 2 + offsetY,
        width + bleendingPixelHorizontal,
        height + bleendingPixelVertical);
  }

  @override
  void render(Canvas canvas,
      {bool showGrids = false, bool showNonInteractableHintColor = false}) {
    _sprite?.renderRect(canvas, rect);
    _animation?.ticker.currentFrame.sprite.renderRect(canvas, rect);
    _overlaySprite?.renderRect(canvas, rect);
    _overlayAnimation?.ticker.currentFrame.sprite.renderRect(canvas, rect);
    if (showGrids) {
      canvas.drawPath(borderPath, borderPaint);
    }
    if (_isNonInteractable && showNonInteractableHintColor) {
      canvas.drawPath(borderPath, TileMap.uninteractablePaint);
    }
  }

  void renderCaption(Canvas canvas, {offset = 14.0}) {
    if (caption != null) {
      // Vector2 rPos = renderPosition.clone();
      // rPos.y += offset;
      drawScreenText(canvas, caption!,
          style: ScreenTextStyle(
            rect: rect,
            outlined: true,
            anchor: Anchor.center,
            padding: EdgeInsets.only(top: gridHeight / 2 - 5.0),
            textPaint: _captionPaint,
          ));
      // canvas.drawRect(rect, Paint()..style = PaintingStyle.stroke);
      // _captionPaint.render(
      //   canvas,
      //   caption!,
      //   rPos,
      //   anchor: Anchor.bottomCenter,
      // );
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
