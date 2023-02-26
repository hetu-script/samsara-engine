import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';

import '../paint/paint.dart';

class GameButton extends GameComponent with HandlesGesture {
  String text;
  String? tooltip;

  Anchor tooltipAnchor;

  set isEnabled(bool value) => enableGesture = value;

  final void Function()? onPressed;

  GameButton({
    required this.text,
    this.tooltip,
    this.tooltipAnchor = Anchor.topLeft,
    required double x,
    required double y,
    double width = 160.0,
    double height = 80.0,
    this.onPressed,
    super.borderRadius,
  }) : super(position: Vector2(x, y), size: Vector2(width, height));

  @override
  void render(Canvas canvas) {
    if (isHovering) {
      canvas.drawRRect(rborder, borderPaintSelected);

      if (tooltip != null) {
        drawScreenText(
          canvas,
          tooltip!,
          rect: Rect.fromLTWH(0, -50, width, height),
          anchor: Anchor.bottomCenter,
          style: ScreenTextStyle.info,
        );
      }
    } else {
      canvas.drawRRect(rborder, borderPaint);
    }

    drawScreenText(canvas, text,
        rect: border, anchor: Anchor.center, style: ScreenTextStyle.info);
  }

  @override
  void onTap(int pointer, int buttons, TapUpDetails details) {
    onPressed?.call();
  }
}
