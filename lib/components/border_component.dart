import 'package:flutter/foundation.dart';

import 'game_component.dart';

export '../types.dart';

class BorderComponent extends GameComponent {
  late Paint borderPaint;

  late Rect _border;
  Rect get border => _border;
  final double borderWidth;
  late RRect _rBorder;
  RRect get roundBorder => _rBorder;
  final double borderRadius;
  late RRect _clipRRect;
  RRect get clipRRect => _clipRRect;

  BorderComponent({
    super.key,
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.priority,
    super.opacity,
    super.children,
    super.lightConfig,
    super.paint,
    this.borderWidth = 1.0,
    this.borderRadius = 0.0,
    Paint? borderPaint,
    super.isVisible,
  }) {
    this.borderPaint = borderPaint ?? Paint()
      ..color = Colors.white.withOpacity(0.75)
      ..strokeWidth = 0.35
      ..style = PaintingStyle.stroke;
    setPaint('borderPaint', this.borderPaint);

    generateBorder();
    size.addListener(generateBorder);
  }

  @mustCallSuper
  void generateBorder() {
    _border = Rect.fromLTWH(0, 0, width, height);
    _rBorder =
        RRect.fromLTRBR(0, 0, width, height, Radius.circular(borderRadius));

    _clipRRect = RRect.fromLTRBR(
        0 - borderWidth,
        0 - borderWidth,
        width + borderWidth * 2,
        height + borderWidth * 2,
        Radius.circular(borderRadius));
  }
}
