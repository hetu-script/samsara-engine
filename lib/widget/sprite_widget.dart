import 'package:flutter/material.dart';
import 'package:flame/components.dart';
// ignore: implementation_imports
import 'package:flame/src/widgets/sprite_painter.dart';

/// A [StatefulWidget] that renders a still [Sprite].
class SpriteWidget extends StatelessWidget {
  /// The [Sprite] to be rendered
  final Sprite sprite;

  /// The positioning [Anchor] for the [sprite]
  final Anchor anchor;

  /// The angle to rotate this [sprite], in rad. (default = 0)
  final double angle;

  final Size size;

  SpriteWidget({
    super.key,
    required this.sprite,
    this.anchor = Anchor.topLeft,
    this.angle = 0,
    Size? size,
  }) : size = size ?? sprite.srcSize.toSize();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SpritePainter(sprite, anchor, angle: angle),
      size: size,
    );
  }
}
