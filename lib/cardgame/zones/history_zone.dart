import 'package:flutter/material.dart';

import '../../component/game_component.dart';
import '../../gestures.dart';
import '../../paint/paint.dart';

class HistoryZone extends GameComponent with HandlesGesture {
  final String? id;
  final String? title;

  late ScreenTextStyle titleStyle;

  final Anchor titleAnchor;

  HistoryZone({
    this.id,
    this.title,
    required double x,
    required double y,
    required double width,
    required double height,
    super.borderRadius = 5.0,
    this.titleAnchor = Anchor.topLeft,
  }) : super(
          position: Vector2(x, y),
          size: Vector2(width, height),
        ) {
    titleStyle = ScreenTextStyle(
      rect: border,
      anchor: titleAnchor,
      padding: const EdgeInsets.fromLTRB(10, -10, 10, -10),
    );
  }

  @override
  void render(Canvas canvas) {
    if (title != null) {
      drawScreenText(canvas, title!, style: titleStyle);
    }

    canvas.drawRRect(rborder, DefaultBorderPaint.light);
  }
}
