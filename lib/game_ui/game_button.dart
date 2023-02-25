import 'dart:ui';

import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';

import '../paint/paint.dart';

class GameButton extends GameComponent with HandlesGesture {
  late Rect border;
  late RRect rborder;
  final double borderRadius;

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
    this.borderRadius = 5.0,
    this.onPressed,
  }) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    generateBorder();
  }

  void generateBorder() {
    border = Rect.fromLTWH(0, 0, width, height);
    rborder =
        RRect.fromLTRBR(0, 0, width, height, Radius.circular(borderRadius));
  }

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
