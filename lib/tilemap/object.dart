import 'dart:math' as math;

// import 'package:flutter/foundation.dart';

import '../tilemap/terrain.dart';
import '../components/game_component.dart';
import 'tile_mixin.dart';
import 'direction.dart';
import '../animation/sprite_animation.dart';
import 'route.dart';
import '../animation/animation_state_controller.dart';
import '../extensions.dart';

enum AnimationDirection {
  south,
  east,
  west,
  north,
}

const kObjectMovingStates = {
  'move_north',
  'move_south',
  'move_east',
  'move_west',
};

const kObjectMovingStatesWithSwim = {
  'move_north',
  'move_south',
  'move_east',
  'move_west',
  'swim_north',
  'swim_south',
  'swim_east',
  'swim_west',
};

class TileMapMovingObject extends GameComponent
    with TileInfo, AnimationStateController {
  static const defaultAnimationStepTime = 0.2;

  final String id;
  final dynamic data;

  final double velocityFactor;

  final bool hasSwimAnimation;

  late OrthogonalDirection _direction;

  OrthogonalDirection get direction => _direction;

  bool _isWalking = false;
  bool get isWalking => _isWalking;
  bool _isStopping = false;
  bool _isBackward = false;

  Vector2 _movingTargetRenderPosition = Vector2.zero();
  TilePosition _movingTargetTilePosition = TilePosition.leftTop();
  Vector2 _velocity = Vector2.zero();

  void Function(int left, int top)? onMoved;

  // 下面这些是公开属性，由 tilemap 直接修改和管理
  bool isOnWater = false;
  bool isMovingCanceled = false;
  List<TileMapRouteNode>? currentRoute;
  TileMapRouteNode? lastRouteNode;
  bool backwardMoving = false;
  void Function(TileMapTerrain tile)? onDestinationCallback;
  OrthogonalDirection? endDirection;

  /// states passed in there must contains all kObjectMovingStates
  TileMapMovingObject({
    required this.id,
    this.data,
    int? left,
    int? top,
    required Vector2 srcSize,
    Vector2? offset,
    this.velocityFactor = 0.8,
    this.onMoved,
    this.hasSwimAnimation = false,
    required Map<String, SpriteAnimationWithTicker> states,
  }) {
    this.srcSize = srcSize;
    assert(!srcSize.isZero());
    this.offset = offset ?? Vector2.zero();
    tilePosition = TilePosition(left ?? 1, top ?? 1);

    if (hasSwimAnimation) {
      for (final key in kObjectMovingStatesWithSwim) {
        assert(states.containsKey(key));
      }
    }

    for (final key in kObjectMovingStates) {
      assert(states.containsKey(key));
    }

    addStates(states);
    direction = OrthogonalDirection.south;

    stopAnimation();
  }

  set direction(OrthogonalDirection value) {
    _direction = value;
    if (hasSwimAnimation && isOnWater) {
      setState('swim_${_direction.name}');
    } else {
      setState('move_${_direction.name}');
    }
  }

  void loadFrameData() {
    final frameData = data?['worldLocation']?['animation'];
    if (frameData != null) {
      direction = OrthogonalDirection.values
          .singleWhere((element) => element.name == frameData['direction']);
      currentAnimation.ticker.currentIndex = frameData['currentIndex'];
      currentAnimation.ticker.clock = frameData['clock'];
      currentAnimation.ticker.elapsed = frameData['elapsed'];
    }
  }

  void saveFrameData() {
    assert(data['worldPosition'] != null);
    data['worldPosition'] = {
      'left': left,
      'top': top,
      'animation': {
        'direction': _direction.name,
        'currentIndex': currentAnimation.ticker.currentIndex,
        'clock': currentAnimation.ticker.clock,
        'elapsed': currentAnimation.ticker.elapsed,
      }
    };
  }

  void stopAnimation() {
    currentAnimation.ticker.paused = true;
    currentAnimation.ticker.setToLast();
  }

  void stop() {
    tilePosition = _movingTargetTilePosition;
    _isStopping = true;
    position = _movingTargetRenderPosition;
    // 这里要先取消移动，再调用事件
    // 检查isBackward的目的，是为了在英雄倒退到entity上时，不触发
    // 只有玩家自己主动经过某个entity，才触发事件
    if (!_isBackward) {
      onMoved?.call(tilePosition.left, tilePosition.top);
    }
    _isBackward = false;
    _movingTargetRenderPosition = Vector2.zero();
    _velocity = Vector2.zero();
    _movingTargetTilePosition = TilePosition.leftTop();
  }

  void walkTo({
    required TilePosition target,
    required Vector2 targetRenderPosition,
    required OrthogonalDirection targetDirection,
    bool backward = false,
  }) {
    assert(tilePosition != target);
    _movingTargetTilePosition = target;
    _isWalking = true;
    _isBackward = backward;
    _movingTargetRenderPosition = targetRenderPosition + offset;
    direction = targetDirection;

    // 计算地图上的斜方向实际距离
    final sx = _movingTargetRenderPosition.x - position.x;
    final sy = _movingTargetRenderPosition.y - position.y;
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

  @override
  void update(double dt) {
    if (_isStopping) {
      _isWalking = false;
      _isStopping = false;
    } else if (_isWalking) {
      currentAnimation.ticker.update(dt);

      position += _velocity;

      if (_velocity.y < 0 && position.y < _movingTargetRenderPosition.y) {
        stop();
      } else if (_velocity.y > 0 &&
          position.y > _movingTargetRenderPosition.y) {
        stop();
      } else if (_velocity.x < 0 &&
          position.x < _movingTargetRenderPosition.x) {
        stop();
      } else if (_velocity.x > 0 &&
          position.x > _movingTargetRenderPosition.x) {
        stop();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    currentAnimation.render(canvas);
  }
}
