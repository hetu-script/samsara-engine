import 'dart:async';
import 'dart:math' as math;

// import 'package:flutter/foundation.dart';

import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';
import '../tilemap/terrain.dart';
// import '../components/game_component.dart';
import 'tile_mixin.dart';
import 'direction.dart';
import '../animation/sprite_animation.dart';
import 'route.dart';
import '../animation/animation_state_controller.dart';
import '../extensions.dart';
import '../components/task_component.dart';

enum AnimationDirection {
  south,
  east,
  west,
  north,
}

const kObjectWalkStates = {
  'walk_north',
  'walk_south',
  'walk_east',
  'walk_west',
};

const kObjectWalkStatesWithSwim = {
  'walk_north',
  'walk_south',
  'walk_east',
  'walk_west',
  'swim_north',
  'swim_south',
  'swim_east',
  'swim_west',
};

class TileMapComponent extends TaskComponent
    with TileInfo, AnimationStateController {
  static const defaultAnimationStepTime = 0.2;

  Sprite? sprite;

  final String id;
  final dynamic data;

  final double velocityFactor;

  final bool isCharacter;
  final bool hasWalkAnimation;
  final bool hasSwimAnimation;

  late OrthogonalDirection _direction;

  OrthogonalDirection get direction => _direction;

  bool _isWalking = false;
  bool get isWalking => _isWalking;
  bool _isStoppingWalk = false;

  Vector2 _walkTargetRenderPosition = Vector2.zero();
  TilePosition _walkTargetTilePosition = TilePosition.leftTop();
  Vector2 _velocity = Vector2.zero();

  // void Function(int left, int top)? onMoved;

  // 下面这些是公开属性，由 tilemap 直接修改和管理
  bool isOnWater = false;
  bool isWalkCanceled = false;
  List<TileMapRouteNode>? currentRoute;
  TileMapRouteNode? prevRouteNode;
  bool isBackwardWalking = false;
  FutureOr<void> Function(TileMapTerrain terrain, TileMapTerrain? nextTerrain)?
      onStepCallback;
  FutureOr<void> Function(TileMapTerrain terrain,
      [TileMapTerrain? targetTerrain])? onFinishWalkCallback;
  OrthogonalDirection? finishWalkDirection;

  /// For moving object, states must contains all [kObjectWalkStates]
  TileMapComponent({
    required this.id,
    this.data,
    int? left,
    int? top,
    Vector2? offset,
    this.velocityFactor = 0.8,
    this.isCharacter = false,
    this.hasWalkAnimation = false,
    this.hasSwimAnimation = false,
    Map<String, SpriteAnimationWithTicker> animations = const {},
  }) {
    this.offset = offset ?? Vector2.zero();
    tilePosition = TilePosition(left ?? 1, top ?? 1);

    for (final key in animations.keys) {
      addState(key, animations[key]!);
    }

    if (hasWalkAnimation || hasSwimAnimation) {
      if (hasSwimAnimation) {
        for (final key in kObjectWalkStatesWithSwim) {
          assert(animations.containsKey(key));
        }
      } else if (hasWalkAnimation) {
        for (final key in kObjectWalkStates) {
          assert(animations.containsKey(key));
        }
      }

      direction = OrthogonalDirection.south;
      stopAnimation();
    }
  }

  void stopAnimation() {
    currentAnimation?.ticker.paused = true;
    currentAnimation?.ticker.setToLast();
  }

  set direction(OrthogonalDirection value) {
    _direction = value;
    if (hasSwimAnimation && isOnWater) {
      setState('swim_${_direction.name}');
    } else {
      setState('walk_${_direction.name}');
    }
  }

  @override
  FutureOr<void> onLoad() async {
    final String? spritePath = data?['sprite'];
    if (spritePath != null) {
      sprite = await Sprite.load(spritePath);
    }

    final animationData = data?['animation'];
    final assetPath = animationData?['path'];
    if (assetPath != null) {
      final double srcWidth = animationData['srcWidth'];
      final double srcHeight = animationData['srcHeight'];
      final Vector2 srcSize = Vector2(srcWidth, srcHeight);
      final double stepTime =
          animationData?['stepTime'] ?? defaultAnimationStepTime;
      final image = await Flame.images.load(assetPath);
      final sheet = SpriteSheet(image: image, srcSize: srcSize);
      final animation = SpriteAnimationWithTicker(
        animation: sheet.createAnimation(
          row: 0,
          stepTime: stepTime,
          loop: true,
        ),
      );
      addState('default', animation);
      setState('default');
    }
  }

  void loadFrameData() {
    final frameData = data['frameData'];
    if (frameData != null) {
      direction = OrthogonalDirection.values
          .singleWhere((element) => element.name == frameData['direction']);
      currentAnimation?.ticker.currentIndex = frameData['currentIndex'];
      currentAnimation?.ticker.clock = frameData['clock'];
      currentAnimation?.ticker.elapsed = frameData['elapsed'];
    }
  }

  void saveFrameData() {
    if (currentAnimationState == null || currentAnimation == null) return;
    data['frameData'] = {
      'state': currentAnimationState,
      'direction': _direction.name,
      'currentIndex': currentAnimation?.ticker.currentIndex,
      'clock': currentAnimation?.ticker.clock,
      'elapsed': currentAnimation?.ticker.elapsed,
    };
  }

  void stopWalk() {
    tilePosition = _walkTargetTilePosition;
    _isStoppingWalk = true;
    position = _walkTargetRenderPosition;
    // 这里要先取消移动，再调用事件
    // 检查isBackward的目的，是为了在英雄倒退到entity上时，不触发
    // 只有玩家自己主动经过某个entity，才触发事件
    // if (!_isBackward) {
    //   onMoved?.call(tilePosition.left, tilePosition.top);
    // }
    // _isBackward = false;
    _walkTargetRenderPosition = Vector2.zero();
    _velocity = Vector2.zero();
    _walkTargetTilePosition = TilePosition.leftTop();
  }

  void walkTo({
    required TilePosition target,
    required Vector2 targetRenderPosition,
    required OrthogonalDirection targetDirection,
    bool backward = false,
  }) {
    assert(tilePosition != target);
    _walkTargetTilePosition = target;
    _isWalking = true;
    // _isBackward = backward;
    _walkTargetRenderPosition = targetRenderPosition + offset;
    direction = targetDirection;

    // 计算地图上的斜方向实际距离
    final sx = _walkTargetRenderPosition.x - position.x;
    final sy = _walkTargetRenderPosition.y - position.y;
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
    if (_isStoppingWalk) {
      _isWalking = false;
      _isStoppingWalk = false;
    } else if (_isWalking) {
      currentAnimation?.ticker.update(dt);
      position += _velocity;
      if (_velocity.y < 0 && position.y < _walkTargetRenderPosition.y) {
        stopWalk();
      } else if (_velocity.y > 0 && position.y > _walkTargetRenderPosition.y) {
        stopWalk();
      } else if (_velocity.x < 0 && position.x < _walkTargetRenderPosition.x) {
        stopWalk();
      } else if (_velocity.x > 0 && position.x > _walkTargetRenderPosition.x) {
        stopWalk();
      }
    }
  }

  // TODO:计算是否在屏幕上可见
  @override
  bool get isVisible => true;

  @override
  void render(Canvas canvas) {
    sprite?.render(canvas);
    currentAnimation?.render(canvas);
  }
}
