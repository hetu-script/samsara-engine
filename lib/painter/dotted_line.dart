import 'dart:ui';

import 'package:flutter/material.dart';

class LinePainter extends CustomPainter {
  final bool isDotted;
  final double? gapSize;
  final Paint style;

  const LinePainter({
    this.isDotted = false,
    this.gapSize,
    required this.style,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double width = size.width; // always axis is horizontal here

    if (isDotted) {
      if (style.strokeWidth <= 0.0) {
        style.strokeWidth = 1.0;
      }

      if (style.strokeWidth >= width) {
        _drawSolidLine(canvas, width, style);
        return;
      }

      double gap = gapSize ?? 5.0;
      if (gap >= width) return;

      _drawDottedLine(canvas, width, style, gap);
    } else {
      _drawSolidLine(canvas, width, style);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }

  void _drawSolidLine(Canvas canvas, double width, Paint paintDef) {
    double strokeVerticalOverflow = paintDef.strokeWidth / 2;
    double strokeHorizontalOverflow =
        paintDef.strokeCap == StrokeCap.butt ? 0.0 : strokeVerticalOverflow;

    canvas.drawLine(
      Offset(strokeHorizontalOverflow, strokeVerticalOverflow),
      Offset(width - strokeHorizontalOverflow, strokeVerticalOverflow),
      paintDef,
    );
  }

  void _drawDottedLine(
    Canvas canvas,
    double width,
    Paint paintDef,
    double gapSize,
  ) {
    double pointSize = paintDef.strokeWidth;
    double strokeVerticalOverflow = pointSize / 2;

    double jointSize = pointSize + gapSize;
    double leapSize = (width + gapSize) % jointSize;

    double position = strokeVerticalOverflow + leapSize / 2;
    List<Offset> points = [];

    // position + pointSize <= width + pointSize
    do {
      points.add(Offset(position, strokeVerticalOverflow));
    } while ((position += jointSize) <= width);

    canvas.drawPoints(PointMode.points, points, paintDef);
  }
}
