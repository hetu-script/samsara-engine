import 'dart:async';

import 'package:flame/effects.dart';

import '../../component/game_component.dart';
import '../paint/paint.dart';
import '../effect/fade_effect.dart';
import 'timer.dart';
import '../effect/advanced_move_effect.dart';

class FadingText extends GameComponent {
  late final ScreenTextStyle style;

  final String text;

  final double fadeOutAfterDuration, movingUpOffset, duration;

  final Curve moveUpCurve;

  FadingText(
    this.text, {
    this.movingUpOffset = 0,
    this.moveUpCurve = Curves.easeOut,
    this.fadeOutAfterDuration = 0,
    required this.duration,
    super.position,
    super.size,
    super.angle,
    super.anchor,
    super.priority,
    super.opacity,
    bool outlined = true,
    required TextPaint textPaint,
  }) : style = ScreenTextStyle(textPaint: textPaint, outlined: outlined) {
    width = style.textPaint!.measureTextWidth(text);
    height = style.textPaint!.measureTextHeight(text);

    assert(fadeOutAfterDuration < duration);
  }

  @override
  FutureOr<void> onLoad() {
    void addEffect() {
      add(FadeEffect(
        controller: EffectController(duration: duration),
      ));
    }

    if (movingUpOffset > 0) {
      add(AdvancedMoveEffect(
        endPosition: Vector2(x, y - movingUpOffset),
        controller: EffectController(duration: duration, curve: moveUpCurve),
      ));
    }

    if (fadeOutAfterDuration > 0) {
      add(Timer(fadeOutAfterDuration, onComplete: addEffect));
    } else {
      addEffect();
    }
  }

  @override
  void render(Canvas canvas) {
    drawScreenText(canvas, text,
        style: style.copyWith(rect: border, opacity: opacity));
  }
}