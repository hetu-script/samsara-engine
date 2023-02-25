import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';
import 'package:flame/game.dart';

import '../../paint/paint.dart';

class HistoryZone extends GameComponent with HandlesGesture {
  @override
  Camera get camera => gameRef.camera;

  final String id;
  final String? title;

  final double borderRadius;
  late final Rect border;
  late final RRect rborder;

  final Anchor titleAnchor;

  HistoryZone({
    required this.id,
    this.title,
    required double x,
    required double y,
    required double width,
    required double height,
    this.borderRadius = 5.0,
    this.titleAnchor = Anchor.topLeft,
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
    if (title != null) {
      drawScreenText(
        canvas,
        title!,
        rect: border,
        anchor: titleAnchor,
        marginLeft: 10,
        marginTop: -10,
        marginRight: 10,
        marginBottom: -10,
      );
    }

    canvas.drawRRect(rborder, borderPaint);
  }
}
