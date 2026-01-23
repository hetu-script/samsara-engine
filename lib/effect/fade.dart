import 'package:flame/effects.dart';

import '../components/game_component.dart';

class FadeEffect extends Effect with EffectTarget<GameComponent> {
  final bool fadeIn;

  FadeEffect({
    GameComponent? target,
    required EffectController controller,
    this.fadeIn = false,
    super.onComplete,
  }) : super(controller) {
    this.target = target;
  }

  @override
  void apply(double progress) {
    final newOpacity = fadeIn ? (progress * 1.0) : ((1 - progress) * 1.0);
    target.opacity = newOpacity;
  }

  @override
  void onFinish() {
    super.onFinish();
    if (!fadeIn) {
      target.removeFromParent();
    }
  }
}
