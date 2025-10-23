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
    this.fadeOutAfterDuration = 0,
    required this.duration,
    super.position,
    super.size,
    super.angle,
    super.priority,
    super.opacity,
    TextStyle? textStyle,
    this.onComplete,
  }) : super(anchor: Anchor.center) {
    if (textStyle != null) {
      _textConfig =
          _textConfig.fillWith(textStyle: textStyle).copyWith(size: size);
    } else {
      _textConfig = _textConfig.copyWith(size: size);
    }

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
    drawScreenText(canvas, text, config: _textConfig);
  }
}
