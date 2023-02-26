import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import 'package:flame/components.dart';

import 'package:samsara/components.dart';
import '../paint/paint.dart';

class Avatar extends GameComponent {
  final String imagePath;

  late final Sprite avatar;

  Avatar(
    this.imagePath, {
    double x = 0.0,
    double y = 0.0,
    double width = 120.0,
    double height = 120.0,
    double radius = 5.0,
  }) : super(position: Vector2(x, y), size: Vector2(width, height));

  @override
  Future<void> onLoad() async {
    super.onLoad();

    avatar = Sprite(await Flame.images.load(imagePath));
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(rborder, borderPaint);
    avatar.renderRect(canvas, border);
  }
}
