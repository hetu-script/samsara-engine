import 'dart:math' as math;

import 'package:hetu_script/utils/math.dart' as math;

import '../types.dart' show Vector2;

class PointOnCircle {
  Vector2 position;
  double angle;

  PointOnCircle(
    this.position,
    this.angle,
  );
}

List<PointOnCircle> generateDividingPointsFromCircle(
    double x0, double y0, double radius, int number,
    {double angleOffset = 0.0}) {
  assert(number > 1);
  List<PointOnCircle> coordinates = [];

  double angle = 0;

  for (int i = 0; i < number; i++) {
    angle = i * (360 / number) - 90 + angleOffset;

    double x = x0 + radius * math.cos(math.radians(angle));
    double y = y0 + radius * math.sin(math.radians(angle));

    coordinates.add(PointOnCircle(Vector2(x, y), math.radians(angle + 90)));
  }

  return coordinates;
}

/// 使用极坐标生成随机点
/// 可以将 exponent 调整为更靠近小的值来增加靠近圆心的概率
Vector2 generateRandomPointInCircle(
  Vector2 center,
  double radius, {
  double exponent = 0.5,
}) {
  final random = math.Random();

  final r = radius * (1 - math.pow(random.nextDouble(), exponent));

  final theta = random.nextDouble() * 2 * math.pi;

  final x = center.x + r * math.cos(theta);
  final y = center.y + r * math.sin(theta);

  return Vector2(x, y);
}
