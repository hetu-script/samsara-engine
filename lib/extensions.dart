import 'dart:ui';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'effect/zoom.dart';

export 'package:flame/extensions.dart' hide ListExtension;

extension IterableEx<T> on Iterable<T> {
  Iterable<T> get reversed => toList().reversed;

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

  String? get nonEmptyValue => isBlank ? null : this;

  String interpolate(List? interpolations) {
    if (interpolations == null || interpolations.isEmpty) {
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
  /// 将十六进制颜色字符串转换为 Flutter 的 Color 对象。
  ///
  /// 接受的格式:
  /// - 6位 RGB (例如, "FF0000")
  /// - 8位 RRGGBBAA (例如, "FF00007F")
  /// - 以上格式均可带 "#" 前缀 (例如, "#FF0000")
  ///
  /// [hexCode] 十六进制颜色字符串。
  /// 返回一个 [Color] 对象。
  /// 如果格式无效，则抛出 [ArgumentError]。
  static Color fromString(String hexCode) {
    // 移除 '#' 符号
    final String hex = hexCode.startsWith('#') ? hexCode.substring(1) : hexCode;
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    } else if (hex.length == 8) {
      // 如果是8位颜色码 (RRGGBBAA)，则需要将其转换为 AARRGGBB
      return Color(
        int.parse(
          '${hex.substring(6, 8)}${hex.substring(0, 6)}',
          radix: 16,
        ),
      );
    } else {
      // 如果长度不符合要求，则抛出异常
      throw ArgumentError('Invalid hex color code: $hexCode');
    }
  }

  /// HexColor String is in the format "rrggbb" or "rrggbbaa" with an optional leading "#".
  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${r.round().toRadixString(16).padLeft(2, '0')}'
      '${g.round().toRadixString(16).padLeft(2, '0')}'
      '${b.round().toRadixString(16).padLeft(2, '0')}'
      '${a.round().toRadixString(16).padLeft(2, '0')}';
}

extension Vector2Ex on Vector2 {
  bool contains(Vector2 position) {
    return position.x > 0 && position.y > 0 && position.x < x && position.y < y;
  }

  Vector2 operator *(double scale) {
    return Vector2(x * scale, y * scale);
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

extension CameraEx on CameraComponent {
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

extension RectEx on Rect {
  Rect stretchTo(Vector2 point) {
    return Rect.fromLTWH(
        left + point.x, top + point.y, width - point.x, height - point.y);
  }

  Rect operator +(dynamic other) {
    if (other is Vector2) {
      return Rect.fromLTWH(left + other.x, top + other.y, width, height);
    } else if (other is Offset) {
      return Rect.fromLTWH(left + other.dx, top + other.dy, width, height);
    } else if (other is Size) {
      return Rect.fromLTWH(
          left, top, width + other.width, height + other.height);
    } else {
      throw 'Rect cannot adding with ${other.runtimeType}';
    }
  }

  Rect operator *(num scale) {
    return Rect.fromLTWH(left, top, width * scale, height * scale);
  }

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
