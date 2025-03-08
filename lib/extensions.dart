import 'dart:ui';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'effect/zoom.dart';

export 'package:flame/extensions.dart';

extension IterableEx<T> on Iterable<T> {
  T get random {
    return elementAt(math.Random().nextInt(length));
  }

  T? get randomOrNull {
    if (isNotEmpty) {
      return elementAt(math.Random().nextInt(length));
    } else {
      return null;
    }
  }
}

extension StringEx on String {
  String replaceAllEscapedLineBreaks() {
    return replaceAll(r'\n', '\n');
  }

  bool get isBlank => trim().isEmpty;

  bool get isNotBlank => !isBlank;

  String? get nonEmptyValueOrNull => isBlank ? null : this;

  String interpolate(List? interpolations) {
    if (interpolations == null) {
      return this;
    }
    String result = this;
    for (var i = 0; i < interpolations.length; ++i) {
      result = result.replaceAll('{$i}', interpolations[i].toString());
    }
    return result;
  }
}

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

extension HexColor on Color {
  /// String is in the format "rrggbb" or "aarrggbb" with an optional leading "#".
  static Color fromString(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${a.round().toRadixString(16).padLeft(2, '0')}'
      '${r.round().toRadixString(16).padLeft(2, '0')}'
      '${g.round().toRadixString(16).padLeft(2, '0')}'
      '${b.round().toRadixString(16).padLeft(2, '0')}';
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

  Vector2 get absoluteTopLeft => absolutePositionOfAnchor(Anchor.topLeft);
  Vector2 get absoluteTopCenter => absolutePositionOfAnchor(Anchor.topCenter);
  Vector2 get absoluteTopRight => absolutePositionOfAnchor(Anchor.topRight);
  Vector2 get absoluteCenterLeft => absolutePositionOfAnchor(Anchor.centerLeft);
  Vector2 get absoluteCenterRight =>
      absolutePositionOfAnchor(Anchor.centerRight);
  Vector2 get absoluteBottomLeft => absolutePositionOfAnchor(Anchor.bottomLeft);
  Vector2 get absoluteBottomCenter =>
      absolutePositionOfAnchor(Anchor.bottomCenter);
  Vector2 get absoluteBottomRight =>
      absolutePositionOfAnchor(Anchor.bottomRight);
}

extension CameraExtension on CameraComponent {
  void moveTo2(
    Vector2 point, {
    double speed = double.infinity,
    double? zoom,
    void Function()? onComplete,
  }) async {
    stop();
    viewfinder.add(
      MoveToEffect(
        point,
        EffectController(speed: speed),
        onComplete: onComplete,
      ),
    );
    if (zoom != null) {
      final game = findGame();
      assert(game != null);
      game!.add(
        ZoomEffect(
          game,
          EffectController(speed: speed),
          zoom: zoom,
        ),
      );
    }
  }

  void snapTo(Vector2 position) {
    viewfinder.position = position;
  }

  void snapBy(Vector2 offset) {
    viewfinder.position += offset;
  }

  Vector2 get position => viewfinder.position;
  set position(Vector2 newPos) => viewfinder.position = newPos;

  double get zoom => viewfinder.zoom;
  set zoom(double newZoom) => viewfinder.zoom = newZoom;

  // Rect toRect() {
  //   return Rect.fromLTWH(
  //       viewport.position.x, viewport.position.y, gameSize.x, gameSize.y);
  // }

  // bool isComponentOnCamera(GameComponent c) {
  //   if (!c.isVisible) {
  //     return false;
  //   }

  //   return gameSize.contains(c.topLeft) ||
  //       gameSize.contains(c.topRight) ||
  //       gameSize.contains(c.bottomLeft) ||
  //       gameSize.contains(c.bottomRight);
  // }
}

extension FormatHHMMSS on DateTime {
  String toYMDHHMMSS() {
    return '$year-$month-$day ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
  }

  String toYMDHHMMSS2() {
    return '$year${month.toString().padLeft(2, '0')}${day.toString().padLeft(2, '0')}${hour.toString().padLeft(2, '0')}${minute.toString().padLeft(2, '0')}${second.toString().padLeft(2, '0')}';
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

extension MeaningfulEx on DateTime {
  String toMeaningful() {
    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
  }
}
