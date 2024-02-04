import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import '../component/game_component.dart';
import 'tile.dart';
import '../utils/direction.dart';
import '../engine.dart';
import '../../event/events.dart';
import '../animation/sprite_animation.dart';

enum AnimationDirection {
  south,
  east,
  west,
  north,
}

class TileMapObject extends GameComponent with TileInfo {
  static const defaultAnimationStepTime = 0.2;

  final String sceneId;
  final bool isHero;
  final double velocityFactor;

  Sprite? sprite;
  SpriteAnimationWithTicker? animation;
  bool _isMovingObject = false;
  bool _hasMoveOnWaterAnimation = false;
  late final SpriteAnimationWithTicker? moveAnimationSouth,
      moveAnimationEast,
      moveAnimationNorth,
      moveAnimationWest,
      swimAnimationSouth,
      swimAnimationEast,
      swimAnimationNorth,
      swimAnimationWest;

  OrthogonalDirection direction = OrthogonalDirection.south;

  bool _isMoving = false;
  bool _isBackward = false;
  bool get isMoving => _isMoving;
  bool isMovingCanceled = false;

  bool isOnWater = false;
  Vector2 _movingOffset = Vector2.zero();
  Vector2 _movingTargetWorldPosition = Vector2.zero();
  TilePosition _movingTargetTilePosition = const TilePosition.leftTop();
  Vector2 _velocity = Vector2.zero();

  final SamsaraEngine engine;

  String? entityId;

  TileMapObject({
    required this.engine,
    required this.sceneId,
    this.isHero = false,
    int? left,
    int? top,
    this.velocityFactor = 0.8,
    Sprite? sprite,
    SpriteAnimation? animation,
    SpriteSheet? moveAnimationSpriteSheet,
    SpriteSheet? swimAnimationSpriteSheet,
    required TileShape tileShape,
    required int tileMapWidth,
    required double gridWidth,
    required double gridHeight,
    required double srcWidth,
    required double srcHeight,
    double srcOffsetY = 0.0,
    this.entityId,
  }) {
    if (moveAnimationSpriteSheet != null) {
      _isMovingObject = true;
      moveAnimationSouth = SpriteAnimationWithTicker(moveAnimationSpriteSheet
          .createAnimation(row: 0, stepTime: defaultAnimationStepTime));
      moveAnimationEast = SpriteAnimationWithTicker(moveAnimationSpriteSheet
          .createAnimation(row: 1, stepTime: defaultAnimationStepTime));
      moveAnimationNorth = SpriteAnimationWithTicker(moveAnimationSpriteSheet
          .createAnimation(row: 2, stepTime: defaultAnimationStepTime));
      moveAnimationWest = SpriteAnimationWithTicker(moveAnimationSpriteSheet
          .createAnimation(row: 3, stepTime: defaultAnimationStepTime));

      if (swimAnimationSpriteSheet != null) {
        _hasMoveOnWaterAnimation = true;

        swimAnimationSouth = SpriteAnimationWithTicker(swimAnimationSpriteSheet
            .createAnimation(row: 0, stepTime: defaultAnimationStepTime));
        swimAnimationEast = SpriteAnimationWithTicker(swimAnimationSpriteSheet
            .createAnimation(row: 1, stepTime: defaultAnimationStepTime));
        swimAnimationNorth = SpriteAnimationWithTicker(swimAnimationSpriteSheet
            .createAnimation(row: 2, stepTime: defaultAnimationStepTime));
        swimAnimationWest = SpriteAnimationWithTicker(swimAnimationSpriteSheet
            .createAnimation(row: 3, stepTime: defaultAnimationStepTime));
      }
    } else {
      _isMovingObject = false;
      if (sprite != null) {
        this.sprite = sprite;
      } else if (animation != null) {
        this.animation = SpriteAnimationWithTicker(animation);
      }
    }

    this.tileMapWidth = tileMapWidth;
    this.tileShape = tileShape;
    this.gridWidth = gridWidth;
    this.gridHeight = gridHeight;
    this.srcWidth = srcWidth;
    this.srcHeight = srcHeight;
    this.srcOffsetY = srcOffsetY;
    tilePosition = TilePosition(left ?? 1, top ?? 1);
  }

  void stopAnimation() {
    currentAnimation?.ticker.setToLast();
  }

  void stop() {
    tilePosition = _movingTargetTilePosition;
    _isMoving = false;
    // 广播事件中会检查英雄是否正在移动，因此这里要先取消移动，再广播
    // 检查isBackward的目的，是为了在英雄倒退到entity上时，不触发
    // 只有玩家自己主动经过某个entity，才触发事件
    if (isHero && !_isBackward) {
      engine.broadcast(HeroEvent.heroMoved(
        sceneId: sceneId,
        tilePosition: tilePosition,
      ));
    }
    _isBackward = false;
    _movingOffset = Vector2.zero();
    _movingTargetWorldPosition = Vector2.zero();
    _velocity = Vector2.zero();
    _movingTargetTilePosition = const TilePosition.leftTop();
  }

  void walkTo(TilePosition target, {bool backward = false}) {
    assert(tilePosition != target);
    _movingTargetTilePosition = target;
    _isMoving = true;
    _isBackward = backward;
    _movingOffset = Vector2.zero();
    _movingTargetWorldPosition =
        tilePosition2TileCenterInWorld(target.left, target.top);
    direction = direction2Orthogonal(directionTo(target, backward: backward));

    // 计算地图上的斜方向实际距离
    final sx = _movingTargetWorldPosition.x - worldPosition.x;
    final sy = _movingTargetWorldPosition.y - worldPosition.y;
    final dx = sx.abs();
    final dy = sy.abs();
    final d = math.sqrt(dx * dx + dy * dy);
    final t = d / velocityFactor;
    final tx = dx / t;
    final ty = dy / t;
    _velocity = Vector2(tx * sx.sign, ty * sy.sign);
  }

  SpriteAnimationWithTicker? get currentAnimation {
    if (_hasMoveOnWaterAnimation && isOnWater) {
      switch (direction) {
        case OrthogonalDirection.south:
          return swimAnimationSouth;
        case OrthogonalDirection.east:
          return swimAnimationEast;
        case OrthogonalDirection.west:
          return swimAnimationWest;
        case OrthogonalDirection.north:
          return swimAnimationNorth;
      }
    } else {
      switch (direction) {
        case OrthogonalDirection.south:
          return moveAnimationSouth;
        case OrthogonalDirection.east:
          return moveAnimationEast;
        case OrthogonalDirection.west:
          return moveAnimationWest;
        case OrthogonalDirection.north:
          return moveAnimationNorth;
      }
    }
  }

  Sprite getSprite() {
    if (_isMovingObject) {
      return currentAnimation!.ticker.currentFrame.sprite;
    } else {
      if (animation != null) {
        return animation!.ticker.currentFrame.sprite;
      } else {
        return sprite!;
      }
    }
  }

  @override
  void render(Canvas canvas, {TilePosition? tilePosition}) {
    if (!isVisible) return;

    if (tilePosition != null) {
      this.tilePosition = tilePosition;
    }

    var rpos = renderPosition;
    if (isMoving) {
      rpos += _movingOffset;
    }

    getSprite().render(canvas, position: rpos);
  }

  @override
  void update(double dt) {
    if (isMoving) {
      currentAnimation?.ticker.update(dt);
      _movingOffset.x += _velocity.x;
      _movingOffset.y += _velocity.y;

      final currentPosition = worldPosition + _movingOffset;
      if (_movingTargetWorldPosition.y < worldPosition.y &&
          currentPosition.y < _movingTargetWorldPosition.y) {
        stop();
      } else if (_movingTargetWorldPosition.y > worldPosition.y &&
          currentPosition.y > _movingTargetWorldPosition.y) {
        stop();
      } else if (_movingTargetWorldPosition.x < worldPosition.x &&
          currentPosition.x < _movingTargetWorldPosition.x) {
        stop();
      } else if (_movingTargetWorldPosition.x > worldPosition.x &&
          currentPosition.x > _movingTargetWorldPosition.x) {
        stop();
      }
    }
  }
}
