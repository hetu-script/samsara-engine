import 'dart:math' as math;
import 'dart:ui';

// import 'package:flutter/foundation.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import '../component/game_component.dart';
import 'tile_mixin.dart';
import 'direction.dart';
import '../animation/sprite_animation.dart';
import 'route.dart';

enum AnimationDirection {
  south,
  east,
  west,
  north,
}

class TileMapObject extends GameComponent with TileInfo {
  static const defaultAnimationStepTime = 0.2;

  final String id;
  final dynamic data;

  final double velocityFactor;

  Sprite? sprite;
  SpriteAnimationWithTicker? animation;
  bool _isMovingObject = false;
  bool _hasMoveOnWaterAnimation = false;
  late final SpriteAnimationWithTicker moveAnimationSouth,
      moveAnimationEast,
      moveAnimationNorth,
      moveAnimationWest,
      swimAnimationSouth,
      swimAnimationEast,
      swimAnimationNorth,
      swimAnimationWest;

  TileMapDirectionOrthogonal direction = TileMapDirectionOrthogonal.south;

  bool _isMoving = false;
  bool get isMoving => _isMoving;
  bool _isStopping = false;
  bool _isBackward = false;

  Vector2 _movingOffset = Vector2.zero();
  Offset get movingOffset => _movingOffset.toOffset();
  Vector2 _movingTargetWorldPosition = Vector2.zero();
  TilePosition _movingTargetTilePosition = TilePosition.leftTop();
  Vector2 _velocity = Vector2.zero();

  void Function(int left, int top)? onMoved;

  // 下面这些是公开属性，由 tilemap 直接修改和管理
  bool isOnWater = false;
  bool isMovingCanceled = false;
  List<TileMapRouteNode>? currentRoute;
  TileMapRouteNode? lastRouteNode;
  bool backwardMoving = false;
  void Function()? onDestinationCallback;
  TileMapDirectionOrthogonal? endDirection;

  TileMapObject({
    required this.id,
    this.data,
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
    this.onMoved,
  }) {
    if (moveAnimationSpriteSheet != null) {
      _isMovingObject = true;
      moveAnimationSouth = SpriteAnimationWithTicker(
          animation: moveAnimationSpriteSheet.createAnimation(
              row: 0, stepTime: defaultAnimationStepTime));
      moveAnimationEast = SpriteAnimationWithTicker(
          animation: moveAnimationSpriteSheet.createAnimation(
              row: 1, stepTime: defaultAnimationStepTime));
      moveAnimationNorth = SpriteAnimationWithTicker(
          animation: moveAnimationSpriteSheet.createAnimation(
              row: 2, stepTime: defaultAnimationStepTime));
      moveAnimationWest = SpriteAnimationWithTicker(
          animation: moveAnimationSpriteSheet.createAnimation(
              row: 3, stepTime: defaultAnimationStepTime));

      if (swimAnimationSpriteSheet != null) {
        _hasMoveOnWaterAnimation = true;

        swimAnimationSouth = SpriteAnimationWithTicker(
            animation: swimAnimationSpriteSheet.createAnimation(
                row: 0, stepTime: defaultAnimationStepTime));
        swimAnimationEast = SpriteAnimationWithTicker(
            animation: swimAnimationSpriteSheet.createAnimation(
                row: 1, stepTime: defaultAnimationStepTime));
        swimAnimationNorth = SpriteAnimationWithTicker(
            animation: swimAnimationSpriteSheet.createAnimation(
                row: 2, stepTime: defaultAnimationStepTime));
        swimAnimationWest = SpriteAnimationWithTicker(
            animation: swimAnimationSpriteSheet.createAnimation(
                row: 3, stepTime: defaultAnimationStepTime));
      }
    } else {
      _isMovingObject = false;
      if (sprite != null) {
        this.sprite = sprite;
      } else if (animation != null) {
        this.animation = SpriteAnimationWithTicker(animation: animation);
      }
    }

    this.tileShape = tileShape;
    this.gridWidth = gridWidth;
    this.gridHeight = gridHeight;
    this.srcWidth = srcWidth;
    this.srcHeight = srcHeight;
    this.srcOffsetY = srcOffsetY;
    tilePosition = TilePosition(left ?? 1, top ?? 1);
  }

  void stopAnimation() {
    currentAnimation.ticker.setToLast();
  }

  void loadFrameData() {
    final frameData = data?['worldLocation']?['animation'];
    if (frameData != null) {
      direction = TileMapDirectionOrthogonal.values
          .singleWhere((element) => element.name == frameData['direction']);
      currentAnimation.ticker.currentIndex = frameData['currentIndex'];
      currentAnimation.ticker.clock = frameData['clock'];
      currentAnimation.ticker.elapsed = frameData['elapsed'];
    }
  }

  void stop() {
    tilePosition = _movingTargetTilePosition;
    _isStopping = true;
    // 这里要先取消移动，再调用事件
    // 检查isBackward的目的，是为了在英雄倒退到entity上时，不触发
    // 只有玩家自己主动经过某个entity，才触发事件
    if (!_isBackward) {
      onMoved?.call(tilePosition.left, tilePosition.top);
    }
    _isBackward = false;
    _movingTargetWorldPosition = Vector2.zero();
    _velocity = Vector2.zero();
    _movingTargetTilePosition = TilePosition.leftTop();
  }

  void walkTo({
    required TilePosition target,
    required Vector2 targetWorldPosition,
    required TileMapDirectionOrthogonal targetDirection,
    bool backward = false,
  }) {
    assert(tilePosition != target);
    _movingTargetTilePosition = target;
    _isMoving = true;
    _isBackward = backward;
    _movingOffset = Vector2.zero();
    _movingTargetWorldPosition = targetWorldPosition;
    direction = targetDirection;

    // 计算地图上的斜方向实际距离
    final sx = _movingTargetWorldPosition.x - worldPosition.x;
    final sy = _movingTargetWorldPosition.y - worldPosition.y;
    final dx = sx.abs();
    final dy = sy.abs();
    final d = math.sqrt(dx * dx + dy * dy);
    final t = d / velocityFactor;
    final tx = dx / t;
    final ty = dy / t;
    final vx = tx * sx.sign;
    final vy = ty * sy.sign;
    _velocity = Vector2(vx, vy);
  }

  SpriteAnimationWithTicker get currentAnimation {
    if (_hasMoveOnWaterAnimation && isOnWater) {
      switch (direction) {
        case TileMapDirectionOrthogonal.south:
          return swimAnimationSouth;
        case TileMapDirectionOrthogonal.east:
          return swimAnimationEast;
        case TileMapDirectionOrthogonal.west:
          return swimAnimationWest;
        case TileMapDirectionOrthogonal.north:
          return swimAnimationNorth;
      }
    } else {
      switch (direction) {
        case TileMapDirectionOrthogonal.south:
          return moveAnimationSouth;
        case TileMapDirectionOrthogonal.east:
          return moveAnimationEast;
        case TileMapDirectionOrthogonal.west:
          return moveAnimationWest;
        case TileMapDirectionOrthogonal.north:
          return moveAnimationNorth;
      }
    }
  }

  Sprite get currentSprite {
    if (_isMovingObject) {
      return currentAnimation.ticker.currentFrame.sprite;
    } else {
      if (animation != null) {
        return animation!.ticker.currentFrame.sprite;
      } else {
        return sprite!;
      }
    }
  }

  @override
  void update(double dt) {
    if (_isStopping) {
      _isMoving = false;
      _movingOffset = Vector2.zero();
      _isStopping = false;
    } else if (_isMoving) {
      currentAnimation.ticker.update(dt);

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

  @override
  void render(Canvas canvas) {
    var rpos = renderPosition;
    if (isMoving) {
      rpos += _movingOffset;
    }

    currentSprite.render(canvas, position: rpos);
  }
}
