import '../types.dart';
import '../utils/color.dart';

enum LightShape {
  rect,
  circle,
}

class LightConfig {
  // late Paint huePaint;
  late Paint lightPaint;

  Color color;

  double radius;

  bool get hasHue => color != Colors.transparent;

  double lightUpDuration;

  LightShape shape;

  Vector2? lightCenter;
  Vector2? lightCenterOffset;

  late double _blurBorder;
  set blurBorder(double value) {
    _blurBorder = value;

    lightPaint = Paint()
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.clear
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        convertRadiusToSigma(_blurBorder),
      );
  }

  LightConfig({
    this.color = Colors.transparent,
    required this.radius,
    double blurBorder = 10.0,
    this.lightUpDuration = 0.0,
    this.shape = LightShape.circle,
    int flickerRate = 0,
    this.lightCenter,
    this.lightCenterOffset,
  }) {
    assert(radius > 0);

    this.blurBorder = blurBorder;

    // huePaint = Paint()
    //   ..color = color.withOpacity(0.5)
    //   ..maskFilter = MaskFilter.blur(
    //     BlurStyle.normal,
    //     convertRadiusToSigma(blurBorder ?? radius),
    //   );
  }
}
