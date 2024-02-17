import 'package:flame/sprite.dart';

extension AnimationWithTicker on SpriteSheet {
  List<Sprite> generateSpriteList({
    required int row,
    int from = 0,
    int? to,
  }) {
    to ??= columns;

    return List<int>.generate(to - from, (i) => from + i)
        .map((e) => getSprite(row, e))
        .toList();
  }

  SpriteAnimationWithTicker createAnimationWithTicker({
    required int row,
    required double stepTime,
    bool loop = true,
    int from = 0,
    int? to,
  }) {
    final spriteList = generateSpriteList(
      row: row,
      to: to,
      from: from,
    );

    return SpriteAnimationWithTicker(
      SpriteAnimation.spriteList(
        spriteList,
        stepTime: stepTime,
        loop: loop,
      ),
    );
  }
}

class SpriteAnimationWithTicker {
  SpriteAnimation animation;

  SpriteAnimationTicker ticker;

  SpriteAnimationWithTicker(this.animation) : ticker = animation.createTicker();

  Sprite get currentSprite => ticker.getSprite();

  SpriteAnimationWithTicker clone() =>
      SpriteAnimationWithTicker(animation.clone());
}
