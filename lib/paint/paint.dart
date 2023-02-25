import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flame/components.dart';

final borderPaint = Paint()
  ..strokeWidth = 1
  ..style = PaintingStyle.stroke
  ..color = Colors.white30;

final borderPaintFocused = Paint()
  ..strokeWidth = 1.5
  ..style = PaintingStyle.stroke
  ..color = Colors.yellow;

final borderPaintSelected = Paint()
  ..strokeWidth = 3
  ..style = PaintingStyle.stroke
  ..color = Colors.lightBlue;

final borderPaintPressed = Paint()
  ..strokeWidth = 2.5
  ..style = PaintingStyle.stroke
  ..color = Colors.red;

TextPaint screenTextPaintOutline = TextPaint(
  style: TextStyle(
    fontSize: 14.0,
    fontFamily: 'NotoSansMono',
    foreground: Paint()
      ..strokeWidth = 2
      ..color = Colors.black
      ..style = PaintingStyle.stroke,
  ),
);

TextPaint screenTextPaintLight = TextPaint(
  style: const TextStyle(
    color: Colors.white,
    fontSize: 14.0,
    fontFamily: 'NotoSansMono',
  ),
);

TextPaint screenTextPaintInfo = TextPaint(
  style: const TextStyle(
    color: Colors.lightBlue,
    fontSize: 14.0,
    fontFamily: 'NotoSansMono',
  ),
);

TextPaint screenTextPaintWarning = TextPaint(
  style: const TextStyle(
    color: Colors.yellow,
    fontSize: 14.0,
    fontFamily: 'NotoSansMono',
  ),
);

TextPaint screenTextPaintDanger = TextPaint(
  style: const TextStyle(
    color: Colors.red,
    fontSize: 14.0,
    fontFamily: 'NotoSansMono',
  ),
);

enum ScreenTextStyle {
  light,
  info,
  warning,
  danger,
}

void drawScreenText(
  Canvas canvas,
  String text, {
  Vector2? position,
  Rect? rect,
  Anchor anchor = Anchor.topLeft,
  double marginLeft = 0.0,
  double marginTop = 0.0,
  double marginRight = 0.0,
  double marginBottom = 0.0,
  ScreenTextStyle style = ScreenTextStyle.light,
}) {
  assert(position != null || rect != null);
  if (position != null) {
    screenTextPaintOutline.render(canvas, text, position);
    switch (style) {
      case ScreenTextStyle.light:
        screenTextPaintLight.render(canvas, text, position);
        break;
      case ScreenTextStyle.info:
        screenTextPaintInfo.render(canvas, text, position);
        break;
      case ScreenTextStyle.warning:
        screenTextPaintWarning.render(canvas, text, position);
        break;
      case ScreenTextStyle.danger:
        screenTextPaintDanger.render(canvas, text, position);
        break;
    }
  } else if (rect != null) {
    final textWidth = screenTextPaintOutline.measureTextWidth(text);
    final textHeight = screenTextPaintOutline.measureTextHeight(text);
    Vector2 textPosition;
    if (anchor == Anchor.topLeft) {
      textPosition = Vector2(rect.left + marginLeft, rect.top + marginTop);
    } else if (anchor == Anchor.topCenter) {
      textPosition = Vector2(
          rect.left + (rect.width - textWidth) / 2, rect.top + marginTop);
    } else if (anchor == Anchor.topRight) {
      textPosition = Vector2(rect.left + (rect.width - textWidth - marginRight),
          rect.top + marginTop);
    } else if (anchor == Anchor.centerLeft) {
      textPosition = Vector2(rect.left + marginLeft,
          rect.top + (rect.height - textHeight) / 2 + marginTop);
    } else if (anchor == Anchor.center) {
      textPosition = Vector2(rect.left + (rect.width - textWidth) / 2,
          rect.top + (rect.height - textHeight) / 2 + marginTop);
    } else if (anchor == Anchor.centerRight) {
      textPosition = Vector2(rect.left + (rect.width - textWidth - marginRight),
          rect.top + (rect.height - textHeight) / 2 + marginTop);
    } else if (anchor == Anchor.bottomLeft) {
      textPosition = Vector2(rect.left + marginLeft,
          rect.top + (rect.height - textHeight - marginBottom));
    } else if (anchor == Anchor.bottomCenter) {
      textPosition = Vector2(rect.left + (rect.width - textWidth) / 2,
          rect.top + (rect.height - textHeight - marginBottom));
    } else if (anchor == Anchor.bottomRight) {
      textPosition = Vector2(rect.left + (rect.width - textWidth - marginRight),
          rect.top + (rect.height - textHeight - marginBottom));
    } else {
      textPosition = Vector2(
          rect.left + marginLeft + anchor.x, rect.top + marginTop + anchor.y);
    }
    drawScreenText(canvas, text, position: textPosition, style: style);
  }
}

void drawDottedLine(
  Canvas canvas,
  Offset start,
  double width,
  Paint paint,
  double gap,
) {
  double pointSize = paint.strokeWidth;
  double strokeVerticalOverflow = pointSize / 2;
  double jointSize = pointSize + gap;
  double leapSize = (width + gap) % jointSize;

  double position = start.dx + strokeVerticalOverflow + leapSize / 2;
  List<Offset> points = [];

  // position + pointSize <= width + pointSize
  do {
    points.add(Offset(position, start.dy + strokeVerticalOverflow));
  } while ((position += jointSize) <= width);

  canvas.drawPoints(PointMode.points, points, paint);
}
