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

List<PointOnCircle> getDividingPointsFromCircle(
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
