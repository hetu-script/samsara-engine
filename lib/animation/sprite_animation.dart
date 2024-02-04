import 'package:flame/sprite.dart';

class SpriteAnimationWithTicker {
  SpriteAnimation animation;

  SpriteAnimationTicker ticker;

  SpriteAnimationWithTicker(this.animation) : ticker = animation.createTicker();

  Sprite get currentSprite => ticker.getSprite();

  SpriteAnimationWithTicker clone() =>
      SpriteAnimationWithTicker(animation.clone());
}
