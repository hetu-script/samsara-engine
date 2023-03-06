import 'dart:ui';

import 'package:flame/components.dart';
import 'component/game_component.dart';

export 'utils/color.dart' show HexColor;

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

extension Offset2Vector2 on Offset {
  Vector2 toVector2() => Vector2(dx, dy);
}

extension Vector2Ex on Vector2 {
  bool contains(Vector2 position) {
    return position.x > 0 && position.y > 0 && position.x < x && position.y < y;
  }

  Vector2 operator *(Vector2 other) {
    return Vector2(x * other.x, y * other.y);
  }
}

extension CornerPosition on PositionComponent {
  Vector2 get topRightPosition => positionOfAnchor(Anchor.topRight);
  Vector2 get bottomLeftPosition => positionOfAnchor(Anchor.bottomLeft);
  Vector2 get bottomRightPosition => positionOfAnchor(Anchor.bottomRight);
}

extension CameraExtension on Camera {
  Rect toRect() {
    return Rect.fromLTWH(position.x, position.y, gameSize.x, gameSize.y);
  }

  bool isComponentOnCamera(GameComponent c) {
    if (!c.isVisible) {
      return false;
    }

    return gameSize.contains(c.topLeftPosition) ||
        gameSize.contains(c.topRightPosition) ||
        gameSize.contains(c.bottomLeftPosition) ||
        gameSize.contains(c.bottomRightPosition);
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
