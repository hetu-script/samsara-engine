import 'package:flame/effects.dart';

import '../effect/fade.dart';
import 'timer.dart';
import '../samsara.dart';

class FadingText extends GameComponent {
  static TextStyle defaultTextStyle = TextStyle();

  // late TextPaint _textPaint;
  ScreenTextConfig _textConfig = ScreenTextConfig(
    textStyle: defaultTextStyle,
    anchor: Anchor.center,
  );

  final String text;

  final double fadeOutAfterDuration, movingUpOffset, duration;

  final Curve moveUpCurve;

  final void Function()? onComplete;

  FadingText(
    this.text, {
    this.movingUpOffset = 0,
    this.moveUpCurve = Curves.easeOut,
    double? fadeOutAfterDuration,
    required this.duration,
    super.position,
    super.size,
    super.angle,
    super.priority,
    super.opacity,
    TextStyle? textStyle,
    this.onComplete,
    Anchor? anchor,
  })  : fadeOutAfterDuration = fadeOutAfterDuration ?? duration / 2,
        super(anchor: Anchor.center) {
    _textConfig = _textConfig.copyWith(
        size: size, anchor: anchor, textStyle: textStyle ?? defaultTextStyle);

    assert(this.fadeOutAfterDuration < duration);
  }

  @override
  void onLoad() {
    void addFadeEffect() {
      add(FadeEffect(
        controller: EffectController(duration: duration - fadeOutAfterDuration),
        onComplete: onComplete,
        target: this,
      ));
    }

    if (movingUpOffset > 0) {
      add(AdvancedMoveEffect(
        endPosition: Vector2(x, y - movingUpOffset),
        controller: EffectController(duration: duration, curve: moveUpCurve),
      ));
    }

    if (fadeOutAfterDuration > 0) {
      add(Timer(fadeOutAfterDuration, onComplete: addFadeEffect));
    } else {
      addFadeEffect();
    }
  }

  @override
  void render(Canvas canvas) {
    drawScreenText(canvas, text,
        alpha: (opacity * 255).toInt(), config: _textConfig);
  }
}
