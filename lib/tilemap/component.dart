import 'dart:async';
import 'dart:math' as math;

// import 'package:flutter/foundation.dart';

import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';
import '../tilemap/terrain.dart';
// import '../components/game_component.dart';
import 'tile_info.dart';
import '../animation/sprite_animation.dart';
import 'route.dart';
import '../animation/animation_state_controller.dart';
import '../extensions.dart';
import '../components/task_component.dart';
import 'tilemap.dart';

enum AnimationDirection {
  south,
  east,
  west,
  north,
}

const kObjectWalkAnimations = {
  'walk_north',
  'walk_south',
  'walk_east',
  'walk_west',
};

const kObjectWalkAnimationsWithSwim = {
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
  final TileMap map;

  final double velocityFactor;

  final bool isCharacter;

  final Vector2? spriteSrcSize;

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
  FutureOr<void> Function(
          TileMapTerrain terrain, TileMapTerrain? nextTerrain, bool isFinished)?
      onStepCallback;
  OrthogonalDirection? finishWalkDirection;

  bool _isHidden;
  bool get isHidden => _isHidden;
  set isHidden(bool value) {
    _isHidden = value;
    data?['isHidden'] = value;
  }

  /// For moving object, animations must contains all [kObjectWalkAnimations]
  TileMapComponent({
    required this.map,
    required this.id,
    this.data,
    int? left,
    int? top,
    Vector2? offset,
    this.velocityFactor = 0.8,
    this.isCharacter = false,
    this.spriteSrcSize,
    bool isHidden = false,
  }) : _isHidden = isHidden {
    this.offset = offset ?? Vector2.zero();
    tilePosition = TilePosition(left ?? 1, top ?? 1);
  }

  void stopAnimation() {
    currentAnimation?.ticker.paused = true;
    currentAnimation?.ticker.setToLast();
  }

  void setDirection(OrthogonalDirection value, {bool jumpToEnd = false}) {
    _direction = value;
    if (isOnWater) {
      setState('swim_${_direction.name}', jumpToEnd: jumpToEnd);
    } else {
      setState('walk_${_direction.name}', jumpToEnd: jumpToEnd);
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

    if (isCharacter) {
      assert(spriteSrcSize != null);

      final Map<String, SpriteAnimationWithTicker> animations = {};

      SpriteSheet? walkAnimationSpriteSheet, swimAnimationSpriteSheet;
      final String? skinId = data['skin'];
      final String? shipModelId = data['shipModel'];

      if (skinId != null) {
        final image =
            await Flame.images.load('animation/character/tilemap_$skinId.png');
        walkAnimationSpriteSheet = SpriteSheet(
          image: image,
          srcSize: spriteSrcSize!,
        );

        animations['walk_south'] = SpriteAnimationWithTicker(
            animation: walkAnimationSpriteSheet.createAnimation(
                row: 0, stepTime: TileMapComponent.defaultAnimationStepTime));
        animations['walk_east'] = SpriteAnimationWithTicker(
            animation: walkAnimationSpriteSheet.createAnimation(
                row: 1, stepTime: TileMapComponent.defaultAnimationStepTime));
        animations['walk_north'] = SpriteAnimationWithTicker(
            animation: walkAnimationSpriteSheet.createAnimation(
                row: 2, stepTime: TileMapComponent.defaultAnimationStepTime));
        animations['walk_west'] = SpriteAnimationWithTicker(
            animation: walkAnimationSpriteSheet.createAnimation(
                row: 3, stepTime: TileMapComponent.defaultAnimationStepTime));
      }
      if (shipModelId != null) {
        final image = await Flame.images.load('animation/$shipModelId.png');
        swimAnimationSpriteSheet = SpriteSheet(
          image: image,
          srcSize: spriteSrcSize!,
        );

        animations['swim_south'] = SpriteAnimationWithTicker(
            animation: swimAnimationSpriteSheet.createAnimation(
                row: 0, stepTime: TileMapComponent.defaultAnimationStepTime));
        animations['swim_east'] = SpriteAnimationWithTicker(
            animation: swimAnimationSpriteSheet.createAnimation(
                row: 1, stepTime: TileMapComponent.defaultAnimationStepTime));
        animations['swim_north'] = SpriteAnimationWithTicker(
            animation: swimAnimationSpriteSheet.createAnimation(
                row: 2, stepTime: TileMapComponent.defaultAnimationStepTime));
        animations['swim_west'] = SpriteAnimationWithTicker(
            animation: swimAnimationSpriteSheet.createAnimation(
                row: 3, stepTime: TileMapComponent.defaultAnimationStepTime));
      }

      for (final key in animations.keys) {
        addState(key, animations[key]!);
      }

      if (shipModelId != null) {
        for (final key in kObjectWalkAnimationsWithSwim) {
          assert(animations.containsKey(key), 'animation not found! id: $key');
        }
      } else {
        for (final key in kObjectWalkAnimations) {
          assert(animations.containsKey(key), 'animation not found! id: $key');
        }
      }

      setDirection(OrthogonalDirection.south);
      stopAnimation();
    }
  }

  void loadFrameData() {
    final frameData = data['frameData'];
    if (frameData != null) {
      final direction = OrthogonalDirection.values
          .singleWhere((element) => element.name == frameData['direction']);
      setDirection(direction);
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
    setDirection(targetDirection);

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

  @override
  bool get isVisible => map.isTileOnScreen(this);

  @override
  void render(Canvas canvas) {
    if (!map.isEditorMode && isHidden) return;

    sprite?.render(canvas);
    currentAnimation?.render(canvas);
  }
}
