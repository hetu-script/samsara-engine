import 'package:flame/effects.dart';

import '../component/game_component.dart';

export 'package:flutter/animation.dart' show Curve, Curves;

class FadeEffect extends Effect with EffectTarget<GameComponent> {
  FadeEffect({
    GameComponent? target,
    required EffectController controller,
    super.onComplete,
  }) : super(controller) {
    this.target = target;
  }

  @override
  void apply(double progress) {
    final dProgress = progress - previousProgress;

    target.opacity -= dProgress;
  }

  @override
  void onFinish() {
    target.removeFromParent();

    super.onFinish();
  }
}
