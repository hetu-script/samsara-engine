import 'package:flame/effects.dart';

import 'border_component.dart';
import '../paint.dart';
import '../effect/fade_effect.dart';
import 'timer.dart';
import '../effect/advanced_move_effect.dart';

class FadingText extends BorderComponent {
  late final ScreenTextStyle style;

  final String text;

  final double fadeOutAfterDuration, movingUpOffset, duration;

  final Curve moveUpCurve;

  final void Function()? onComplete;

  FadingText(
    this.text, {
    this.movingUpOffset = 0,
    this.moveUpCurve = Curves.easeOut,
    this.fadeOutAfterDuration = 0,
    required this.duration,
    super.position,
    super.size,
    super.angle,
    super.priority,
    super.opacity,
    bool outlined = true,
    required TextPaint textPaint,
    this.onComplete,
  })  : style = ScreenTextStyle(textPaint: textPaint, outlined: outlined),
        super(anchor: Anchor.center) {
    final metric = textPaint.getLineMetrics(text);
    width = metric.width;
    height = metric.height;

    assert(fadeOutAfterDuration < duration);
  }

  @override
  void onLoad() {
    void addEffect() {
      add(FadeEffect(
        controller: EffectController(duration: duration),
        onComplete: onComplete,
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
