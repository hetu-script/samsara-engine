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
import '../components/game_component.dart';
import 'tilemap.dart';
import '../task.dart';

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

typedef OnTileMapComponentStepCallback = FutureOr<bool> Function(
    TileMapTerrain terrain, TileMapTerrain? nextTerrain, bool isFinished);

class TileMapComponent extends GameComponent
    with TileInfo, AnimationStateController, TaskController {
  static const defaultAnimationStepTime = 0.2;

  Sprite? sprite;

  final String id;
  final dynamic data;
  final TileMap map;

  final double speed;
  double speedMultiplier = 1.0;

  final bool isCharacter;

  final Vector2? spriteSrcSize;

  late OrthogonalDirection _direction;

  OrthogonalDirection get direction => _direction;

  bool _isHidden;
  bool get isHidden => _isHidden;
  set isHidden(bool value) {
    _isHidden = value;
    data?['isHidden'] = value;
  }

  bool isWalking = false;

  Vector2 _walkTargetRenderPosition = Vector2.zero();
  TilePosition _walkTargetTilePosition = TilePosition.leftTop();
  Vector2 _velocity = Vector2.zero();

  // 下面这些是公开属性，由 tilemap 直接修改和管理
  bool isOnWater = false;
  bool isWalkCanceled = false;
  List<TileMapRouteNode>? currentRoute;
  TileMapRouteNode? prevRouteNode;
  bool isBackwardWalking = false;
  OnTileMapComponentStepCallback? onStepCallback;
  OrthogonalDirection? finishWalkDirection;

  List<int>? changedRoute;

  int tik = 0;

  @override
  bool get isVisible => map.isTileOnScreen(this) && !isHidden;

  bool animateOnlyWhenHeroWalking;

  /// For moving object, animations must contains all [kObjectWalkAnimations]
  TileMapComponent({
    required this.map,
    required this.id,
    this.data,
    int? left,
    int? top,
    Vector2? offset,
    this.speed = 1.0,
    this.isCharacter = false,
    required this.spriteSrcSize,
    bool isHidden = false,
    this.animateOnlyWhenHeroWalking = false,
  })  : _isHidden = isHidden,
        super(size: spriteSrcSize) {
    this.offset = offset ?? Vector2.zero();
    tilePosition = TilePosition(
      left ?? 1,
      top ?? 1,
    );
  }

  void stopAnimation() {
    currentAnimation?.ticker.paused = true;
    currentAnimation?.ticker.setToLast();
  }

  void setDirection(OrthogonalDirection value, {bool jumpToEnd = true}) {
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
              row: 0, stepTime: TileMapComponent.defaultAnimationStepTime),
        );
        animations['walk_east'] = SpriteAnimationWithTicker(
          animation: walkAnimationSpriteSheet.createAnimation(
              row: 1, stepTime: TileMapComponent.defaultAnimationStepTime),
        );
        animations['walk_north'] = SpriteAnimationWithTicker(
          animation: walkAnimationSpriteSheet.createAnimation(
              row: 2, stepTime: TileMapComponent.defaultAnimationStepTime),
        );
        animations['walk_west'] = SpriteAnimationWithTicker(
          animation: walkAnimationSpriteSheet.createAnimation(
              row: 3, stepTime: TileMapComponent.defaultAnimationStepTime),
        );
      }
      if (shipModelId != null) {
        final image = await Flame.images.load('animation/$shipModelId.png');
        swimAnimationSpriteSheet = SpriteSheet(
          image: image,
          srcSize: spriteSrcSize!,
        );

        animations['swim_south'] = SpriteAnimationWithTicker(
          animation: swimAnimationSpriteSheet.createAnimation(
              row: 0, stepTime: TileMapComponent.defaultAnimationStepTime),
        );
        animations['swim_east'] = SpriteAnimationWithTicker(
          animation: swimAnimationSpriteSheet.createAnimation(
              row: 1, stepTime: TileMapComponent.defaultAnimationStepTime),
        );
        animations['swim_north'] = SpriteAnimationWithTicker(
          animation: swimAnimationSpriteSheet.createAnimation(
              row: 2, stepTime: TileMapComponent.defaultAnimationStepTime),
        );
        animations['swim_west'] = SpriteAnimationWithTicker(
          animation: swimAnimationSpriteSheet.createAnimation(
              row: 3, stepTime: TileMapComponent.defaultAnimationStepTime),
        );
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
    isWalking = false;
    position = _walkTargetRenderPosition;
    // _isBackward = false;
    _walkTargetRenderPosition = Vector2.zero();
    _velocity = Vector2.zero();
    _walkTargetTilePosition = TilePosition.leftTop();
    // print('work time: ${DateTime.now().millisecondsSinceEpoch - tik} ms');
  }

  void walkTo({
    required TilePosition target,
    required Vector2 targetPosition,
    required OrthogonalDirection targetDirection,
    bool backward = false,
  }) {
    // tik = DateTime.now().millisecondsSinceEpoch;
    assert(tilePosition != target);
    isWalking = true;
    _walkTargetTilePosition = target;
    _walkTargetRenderPosition = targetPosition;
    setDirection(targetDirection);
    currentAnimation?.ticker.paused = false;

    // 计算地图上的斜方向实际距离
    final sx = _walkTargetRenderPosition.x - position.x;
    final sy = _walkTargetRenderPosition.y - position.y;
    final dx = sx.abs();
    final dy = sy.abs();
    final d = math.sqrt(dx * dx + dy * dy);
    final t = d / (speed * speedMultiplier);
    final tx = dx / t;
    final ty = dy / t;
    final vx = tx * sx.sign;
    final vy = ty * sy.sign;

    _velocity = Vector2(vx, vy);
  }

  void walkToTilePositionByRoute(
    List<int> route, {
    OrthogonalDirection? finishDirection,
    OnTileMapComponentStepCallback? onStepCallback,
    bool backwardMoving = false,
    double speedMultiplier = 1.0,
  }) {
    if (isWalking) {
      map.logger.error('try to move object while it is already moving');
      return;
    }

    if (map.tilePosition2Index(left, top) != route.first) {
      map.logger.warning(
          'the start position of the route does not match the current position of the component');
      final tilePosition = map.index2TilePosition(route.first);
      this.tilePosition = tilePosition;
      map.updateTileInfo(this);
    }

    isBackwardWalking = backwardMoving;
    this.speedMultiplier = speedMultiplier;

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
      this.onStepCallback = onStepCallback;
    }

    // 默认移动结束后面朝主视角
    finishWalkDirection = finishDirection;
    currentRoute = route
        .map((index) {
          final tilePos = map.index2TilePosition(index);
          final worldPos =
              map.tilePosition2TileCenter(tilePos.left, tilePos.top);
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

  void finishWalk({
    bool stepCallback = false,
    TileMapTerrain? terrain,
    TileMapTerrain? target,
  }) async {
    if (stepCallback) {
      assert(terrain != null);
      assert(onStepCallback != null);
      final continued = await onStepCallback!.call(terrain!, target, true);
      if (continued) return;
    }
    prevRouteNode = null;
    currentRoute = null;
    if (finishWalkDirection != null) {
      setDirection(finishWalkDirection!);
    }
    finishWalkDirection = null;
    isWalkCanceled = false;
    stopAnimation();
    if (changedRoute != null) {
      walkToTilePositionByRoute(
        changedRoute!,
        onStepCallback: onStepCallback,
      );
      changedRoute = null;
    } else {
      onStepCallback = null;
    }
  }

  @override
  void update(double dt) {
    if (map.hero != null &&
        this != map.hero &&
        !map.hero!.isWalking &&
        animateOnlyWhenHeroWalking &&
        map.isStandby != true) {
      return;
    }

    if (isWalking) {
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
    } else {
      if (currentRoute == null) return;

      if (currentRoute!.isEmpty) {
        finishWalk();
        return;
      }

      final prev = currentRoute!.last;
      currentRoute!.removeLast();

      // refreshTileInfo(object);
      final tile = prev.tilePosition;
      final terrain = map.getTerrain(tile.left, tile.top);
      assert(terrain != null);

      if (currentRoute!.isEmpty) {
        finishWalk(stepCallback: true, terrain: terrain!);
        return;
      }

      if (isWalkCanceled) {
        finishWalk();
        return;
      }

      final nextTile = currentRoute!.last.tilePosition;
      final TileMapTerrain nextTerrain =
          map.getTerrain(nextTile.left, nextTile.top)!;
      if (nextTerrain.isWater) {
        isOnWater = true;
      } else {
        isOnWater = false;
      }
      // 如果路径上下一个目标是不可进入的，且该目标是路径上最后一个目标
      // 此种情况结束移动，但仍会触发对最终目标的交互
      if (currentRoute!.length == 1 && nextTerrain.isNonEnterable) {
        finishWalk(stepCallback: true, terrain: terrain!, target: nextTerrain);
        return;
      }

      onStepCallback?.call(terrain!, nextTerrain, false);
      // prevRouteNode 记录了前一次移动时的位置，但第一次移动时，此值为Null
      prevRouteNode = prev;

      // 这里要多检查一次，因为有可能在 onBeforeStepCallback 中被取消移动
      // 但这里的finishMove 不传递 terrain，这样不会再次触发 onAfterMoveCallback
      if (isWalkCanceled) {
        finishWalk();
        return;
      }

      walkTo(
        target: nextTile,
        targetPosition: nextTerrain.position,
        targetDirection: direction2Orthogonal(map
            .directionTo(tilePosition, nextTile, backward: isBackwardWalking)),
        backward: isBackwardWalking,
      );
    }
  }

  void walkToPreviousTile() {
    if (prevRouteNode == null) return;

    currentRoute = null;
    walkToTilePositionByRoute(
      [
        // 这里不能直接使用 component.index，因为 component 的 tileinfo 还没有被更新
        map.tilePosition2Index(left, top),
        prevRouteNode!.index
      ],
      backwardMoving: true,
    );

    prevRouteNode = null;
  }

  @override
  void render(Canvas canvas) {
    if (!map.isEditorMode && isHidden) return;

    sprite?.render(canvas, position: offset);
    currentAnimation?.render(canvas, position: offset);
  }
}
