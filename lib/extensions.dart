import 'dart:ui';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'component/game_component.dart';

export 'utils/color.dart' show HexColor;
export 'package:flame/extensions.dart';

extension PercentageString on num {
  String toPercentageString([int fractionDigits = 0]) {
    return '${(this * 100).toStringAsFixed(fractionDigits).toString()}%';
  }
}

extension DoubleFixed on double {
  double toDoubleAsFixed([int n = 2]) {
    return double.parse(toStringAsFixed(n));
  }
}

extension Vector2Ex on Vector2 {
  bool contains(Vector2 position) {
    return position.x > 0 && position.y > 0 && position.x < x && position.y < y;
  }

  Vector2 operator *(Vector2 other) {
    return Vector2(x * other.x, y * other.y);
  }

  Vector2 moveAlongAngle(double angle, double distance) {
    final x1 = x + math.cos(angle) * distance;
    final y1 = y + math.sin(angle) * distance;
    return Vector2(x1, y1);
  }
}

extension CornerPosition on PositionComponent {
  Vector2 get topLeft => positionOfAnchor(Anchor.topLeft);
  Vector2 get topCenter => positionOfAnchor(Anchor.topCenter);
  Vector2 get topRight => positionOfAnchor(Anchor.topRight);
  Vector2 get centerLeft => positionOfAnchor(Anchor.centerLeft);
  Vector2 get centerRight => positionOfAnchor(Anchor.centerRight);
  Vector2 get bottomLeft => positionOfAnchor(Anchor.bottomLeft);
  Vector2 get bottomCenter => positionOfAnchor(Anchor.bottomCenter);
  Vector2 get bottomRight => positionOfAnchor(Anchor.bottomRight);
}

extension CameraExtension on Camera {
  Rect toRect() {
    return Rect.fromLTWH(position.x, position.y, gameSize.x, gameSize.y);
  }

  bool isComponentOnCamera(GameComponent c) {
    if (!c.isVisible) {
      return false;
    }

    return gameSize.contains(c.topLeft) ||
        gameSize.contains(c.topRight) ||
        gameSize.contains(c.bottomLeft) ||
        gameSize.contains(c.bottomRight);
  }
}

extension FormatHHMMSS on DateTime {
  String toHHMMSS() {
    return '$year-$month-$day ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
  }
}

extension RectAddingon on Rect {
  Rect operator +(dynamic other) {
    if (other is Vector2) {
      return Rect.fromLTWH(left + other.x, top + other.y, width, height);
    } else if (other is Offset) {
      return Rect.fromLTWH(left + other.dx, top + other.dy, width, height);
    } else {
      throw 'Rect cannot adding with ${other.runtimeType}';
    }
  }
}

extension RectClone on Rect {
  /// 优先使用参数的属性，如果参数为 null，使用自己的属性
  Rect copyWith({
    double? left,
    double? top,
    double? width,
    double? height,
  }) {
    return Rect.fromLTWH(
      left ?? this.left,
      top ?? this.top,
      width ?? this.width,
      height ?? this.height,
    );
  }
}

extension RRectClone on RRect {
  /// 优先使用参数的属性，如果参数为 null，使用自己的属性
  RRect copyWith({
    double? left,
    double? top,
    double? right,
    double? bottom,
    Radius? topLeft,
    Radius? topRight,
    Radius? bottomRight,
    Radius? bottomLeft,
  }) {
    return RRect.fromLTRBAndCorners(
      left ?? this.left,
      top ?? this.top,
      right ?? this.right,
      bottom ?? this.bottom,
      topLeft: topLeft ?? tlRadius,
      topRight: topRight ?? trRadius,
      bottomRight: bottomRight ?? brRadius,
      bottomLeft: bottomLeft ?? blRadius,
    );
  }
}
