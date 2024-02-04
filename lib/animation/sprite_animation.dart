import 'package:flame/sprite.dart';

class SpriteAnimationHandler {
  SpriteAnimation animation;

  SpriteAnimationTicker ticker;

  SpriteAnimationHandler(this.animation) : ticker = animation.createTicker();
}
