import 'dart:ui';

import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flame/components.dart';

const kDefaultAnimationStepTime = 0.7;

extension AnimationWithTicker on SpriteSheet {
  List<Sprite> generateSpriteList({int? row}) {
    if (row != null) {
      return List<int>.generate(columns, (i) => i)
          .map((e) => getSprite(row, e))
          .toList();
    } else {
      final List<Sprite> spriteList = [];
      for (var i = 0; i < rows; ++i) {
        for (var j = 0; j < columns; ++j) {
          spriteList.add(getSprite(i, j));
        }
      }
      return spriteList;
    }
  }

  SpriteAnimationWithTicker createAnimationWithTicker({
    int? row,
    required double stepTime,
    bool loop = true,
    Rect? renderRect,
  }) {
    final spriteList = generateSpriteList(row: row);

    return SpriteAnimationWithTicker(
      animation: SpriteAnimation.spriteList(
        spriteList,
        stepTime: stepTime,
        loop: loop,
      ),
      renderRect: renderRect,
    );
  }
}

class SpriteAnimationWithTicker {
  late final SpriteAnimation animation;

  late final SpriteAnimationTicker ticker;

  bool _isLoaded = false;

  String? animationId;
  Vector2? srcSize;
  double stepTime;
  bool loop;

  Rect? renderRect;

  SpriteAnimationWithTicker({
    this.animationId,
    this.srcSize,
    this.stepTime = kDefaultAnimationStepTime,
    this.loop = true,
    SpriteAnimation? animation,
    this.renderRect,
  }) {
    if (animation != null) {
      this.animation = animation;
      ticker = this.animation.createTicker();
      _isLoaded = true;
    } else {
      assert(animationId != null);
      assert(srcSize != null);
    }
  }

  Future<void> load() async {
    if (animationId != null && srcSize != null) {
      final SpriteSheet spriteList = SpriteSheet(
        image: await Flame.images.load('animation/$animationId.png'),
        srcSize: srcSize!,
      );
      animation = SpriteAnimation.spriteList(
        spriteList.generateSpriteList(),
        stepTime: stepTime,
        loop: loop,
      );
      ticker = animation.createTicker();
      _isLoaded = true;
    }
  }

  Sprite get currentSprite => ticker.getSprite();

  SpriteAnimationWithTicker clone() =>
      SpriteAnimationWithTicker(animation: animation, renderRect: renderRect);

  void update(double dt) {
    if (_isLoaded) {
      ticker.update(dt);
    }
  }

  void render(Canvas canvas, {Vector2? position}) {
    if (!_isLoaded) return;

    if (renderRect != null) {
      currentSprite.renderRect(canvas, renderRect!);
    } else {
      currentSprite.render(canvas, position: position);
    }
  }
}
