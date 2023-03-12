import '../../component/game_component.dart';
import '../../gestures.dart';
import '../paint.dart';

class GameButton extends GameComponent with HandlesGesture {
  String text;
  late ScreenTextStyle textStyle;
  String? tooltip;
  ScreenTextStyle tooltipStyle;

  set isEnabled(bool value) => enableGesture = value;

  GameButton({
    required this.text,
    this.tooltip,
    ScreenTextStyle? tooltipStyle,
    required double x,
    required double y,
    double width = 160.0,
    double height = 80.0,
    void Function()? onPressed,
    super.borderRadius,
  })  : tooltipStyle = tooltipStyle ??
            ScreenTextStyle(
              rect: Rect.fromLTWH(0, -50, width, height),
              anchor: Anchor.bottomCenter,
              colorTheme: ScreenTextColorTheme.info,
            ),
        super(position: Vector2(x, y), size: Vector2(width, height)) {
    textStyle = ScreenTextStyle(
      rect: border,
      anchor: Anchor.center,
      colorTheme: ScreenTextColorTheme.info,
    );

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
