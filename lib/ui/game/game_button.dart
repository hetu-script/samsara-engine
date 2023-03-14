import '../../../component/game_component.dart';
import '../../../gestures.dart';
import '../../paint.dart';

class GameButton extends GameComponent with HandlesGesture {
  static const defaultTitleStyle = ScreenTextStyle(
    anchor: Anchor.center,
    colorTheme: ScreenTextColorTheme.info,
  );

  static const defaultTooltipStyle = ScreenTextStyle(
    anchor: Anchor.bottomCenter,
    colorTheme: ScreenTextColorTheme.info,
  );

  String text;
  late ScreenTextStyle textStyle;
  String? tooltip;
  late ScreenTextStyle tooltipStyle;

  set isEnabled(bool value) => enableGesture = value;

  GameButton({
    required this.text,
    ScreenTextStyle? textStyle,
    this.tooltip,
    ScreenTextStyle? tooltipStyle,
    super.position,
    super.size,
    void Function()? onPressed,
    super.borderRadius,
  }) {
    if (textStyle != null) {
      this.textStyle =
          textStyle.fillFrom(defaultTitleStyle).fillWith(rect: border);
    } else {
      this.textStyle = defaultTitleStyle.copyWith(rect: border);
    }
    if (tooltipStyle != null) {
      this.tooltipStyle = tooltipStyle.fillFrom(defaultTooltipStyle).fillWith(
            rect: Rect.fromLTWH(0, -50, width, height),
          );
    } else {
      this.tooltipStyle = defaultTooltipStyle.copyWith(
        rect: Rect.fromLTWH(0, -50, width, height),
      );
    }

    onTap = (buttons, position) {
      onPressed?.call();
    };
  }

  @override
  void render(Canvas canvas) {
    if (isHovering) {
      canvas.drawRRect(rborder, DefaultBorderPaint.primary);

      if (tooltip != null) {
        drawScreenText(
          canvas,
          tooltip!,
          style: tooltipStyle,
        );
      }
    } else {
      canvas.drawRRect(rborder, DefaultBorderPaint.light);
    }

    drawScreenText(
      canvas,
      text,
      style: textStyle,
    );
  }
}
