import 'dart:ui' show PointMode;

import 'package:flutter/material.dart' hide LineMetrics;
import 'package:flame/components.dart';
import 'package:flame/text.dart';

import 'package:colorfilter_generator/colorfilter_generator.dart';
import 'package:colorfilter_generator/addons.dart';
// import 'package:colorfilter_generator/presets.dart';

export 'package:flame/text.dart' show TextPaint, LineMetrics;
export 'dart:ui'
    show
        Offset,
        Canvas,
        Color,
        Paint,
        PaintingStyle,
        Image,
        BlendMode,
        ImageFilter;
export 'package:flutter/material.dart'
    show Colors, TextStyle, FontWeight, FilterQuality;

abstract class PredefinedFilters {
  static ColorFilter brightness(double value) {
    return ColorFilter.matrix(ColorFilterGenerator(
        name: 'brightnessTint',
        filters: [ColorFilterAddons.brightness(value)]).matrix);
  }
}

abstract class PresetPaints {
  static final light = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke
    ..color = Colors.white70;

  static final dark = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke
    ..color = Colors.black87;

  static final primary = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke
    ..color = Colors.blue;

  static final secondary = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke
    ..color = Colors.grey;

  static final info = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke
    ..color = Colors.lightBlue;

  static final success = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke
    ..color = Colors.green;

  static final warning = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke
    ..color = Colors.yellow;

  static final danger = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke
    ..color = Colors.red;

  static final invalid = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke
    ..color = Colors.grey.shade300;

  static final lightFill = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.white70;

  static final darkFill = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.black87;

  static final primaryFill = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.blue;

  static final secondaryFill = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.grey;

  static final infoFill = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.lightBlue;

  static final successFill = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.green;

  static final warningFill = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.yellow;

  static final dangerFill = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.red;

  static final lightGreenFill = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.lightGreen;

  static final invalidFill = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.grey.shade300;
}

// final Map<TextPaint, TextPaint> _cachedOutline = {};

enum ScreenTextColorTheme {
  light,
  dark,
  primary,
  secondary,
  info,
  success,
  warning,
  danger,
}

abstract class PresetTextPaints {
  static final TextPaint light = TextPaint(
    style: const TextStyle(
      color: Colors.white70,
      fontSize: 12.0,
    ),
  );
  static final TextPaint dark = TextPaint(
    style: const TextStyle(
      color: Colors.black87,
      fontSize: 12.0,
    ),
  );
  static final TextPaint primary = TextPaint(
    style: const TextStyle(
      color: Colors.blue,
      fontSize: 12.0,
    ),
  );
  static final TextPaint secondary = TextPaint(
    style: const TextStyle(
      color: Colors.grey,
      fontSize: 12.0,
    ),
  );
  static final TextPaint info = TextPaint(
    style: const TextStyle(
      color: Colors.lightBlue,
      fontSize: 12.0,
    ),
  );
  static final TextPaint success = TextPaint(
    style: const TextStyle(
      color: Colors.green,
      fontSize: 12.0,
    ),
  );
  static final TextPaint warning = TextPaint(
    style: const TextStyle(
      color: Colors.yellow,
      fontSize: 12.0,
    ),
  );
  static final TextPaint danger = TextPaint(
    style: const TextStyle(
      color: Colors.red,
      fontSize: 12.0,
    ),
  );
}

class ScreenTextStyle {
  final Vector2? position;
  final Rect? rect;
  final Anchor? anchor;
  final EdgeInsets? padding;
  final double? opacity;
  final bool? outlined;
  final ScreenTextColorTheme? colorTheme;
  final Sprite? backgroundSprite;
  final TextStyle? textStyle;

  late final TextPaint textPaint;

  ScreenTextStyle({
    this.position,
    this.rect,
    this.anchor,
    this.padding,
    this.opacity,
    this.outlined,
    this.colorTheme,
    this.backgroundSprite,
    this.textStyle,
    TextPaint? textPaint,
  }) {
    final ct = colorTheme ?? ScreenTextColorTheme.light;
    if (textPaint == null) {
      switch (ct) {
        case ScreenTextColorTheme.light:
          textPaint = TextPaint(
            style: TextStyle(
              color: Colors.white.withOpacity(opacity ?? 1.0),
              fontSize: 12.0,
            ).merge(textStyle),
          );
          break;
        case ScreenTextColorTheme.dark:
          textPaint = TextPaint(
            style: TextStyle(
              color: Colors.black87.withOpacity(opacity ?? 1.0),
              fontSize: 12.0,
            ).merge(textStyle),
          );
          break;
        case ScreenTextColorTheme.primary:
          textPaint = TextPaint(
            style: TextStyle(
              color: Colors.blue.withOpacity(opacity ?? 1.0),
              fontSize: 12.0,
            ).merge(textStyle),
          );
          break;
        case ScreenTextColorTheme.secondary:
          textPaint = TextPaint(
            style: TextStyle(
              color: Colors.grey.withOpacity(opacity ?? 1.0),
              fontSize: 12.0,
            ).merge(textStyle),
          );
          break;
        case ScreenTextColorTheme.success:
          textPaint = TextPaint(
            style: TextStyle(
              color: Colors.green.withOpacity(opacity ?? 1.0),
              fontSize: 12.0,
            ).merge(textStyle),
          );
          break;
        case ScreenTextColorTheme.info:
          textPaint = TextPaint(
            style: TextStyle(
              color: Colors.lightBlue.withOpacity(opacity ?? 1.0),
              fontSize: 12.0,
            ).merge(textStyle),
          );
          break;
        case ScreenTextColorTheme.warning:
          textPaint = TextPaint(
            style: TextStyle(
              color: Colors.yellow.withOpacity(opacity ?? 1.0),
              fontSize: 12.0,
            ).merge(textStyle),
          );
          break;
        case ScreenTextColorTheme.danger:
          textPaint = TextPaint(
            style: TextStyle(
              color: Colors.red.withOpacity(opacity ?? 1.0),
              fontSize: 12.0,
            ).merge(textStyle),
          );
          break;
      }
      this.textPaint = textPaint;
    } else {
      this.textPaint = textPaint.copyWith(
        (textStyle) => textStyle.copyWith(
          color: (textStyle.color ??
                  textStyle.foreground?.color ??
                  Colors.blueGrey)
              .withOpacity(opacity ?? 1.0),
        ),
      );
    }
  }

  /// 优先使用参数的属性，如果参数为 null，使用自己的属性
  ScreenTextStyle copyWith({
    Vector2? position,
    Rect? rect,
    Anchor? anchor,
    EdgeInsets? padding,
    double? opacity,
    bool? outlined,
    ScreenTextColorTheme? colorTheme,
    Sprite? backgroundSprite,
    TextStyle? textStyle,
    TextPaint? textPaint,
  }) {
    return ScreenTextStyle(
      position: position ?? this.position,
      rect: rect ?? this.rect,
      anchor: anchor ?? this.anchor,
      padding: padding ?? this.padding,
      opacity: opacity ?? this.opacity,
      outlined: outlined ?? this.outlined,
      colorTheme: colorTheme ?? this.colorTheme,
      backgroundSprite: backgroundSprite ?? this.backgroundSprite,
      textStyle: textStyle ?? this.textStyle,
      textPaint: textPaint ?? this.textPaint,
    );
  }

  /// 优先使用自己的属性，如果自己的属性为 null，使用参数的属性
  ScreenTextStyle fillWith({
    Vector2? position,
    Rect? rect,
    Anchor? anchor,
    EdgeInsets? padding,
    double? opacity,
    bool? outlined,
    ScreenTextColorTheme? colorTheme,
    Sprite? backgroundSprite,
    TextStyle? textStyle,
  }) {
    return ScreenTextStyle(
      position: this.position ?? position,
      rect: this.rect ?? rect,
      anchor: this.anchor ?? anchor,
      padding: this.padding ?? padding,
      opacity: this.opacity ?? opacity,
      outlined: this.outlined ?? outlined,
      colorTheme: this.colorTheme ?? colorTheme,
      backgroundSprite: this.backgroundSprite ?? backgroundSprite,
      textStyle: this.textStyle ?? textStyle,
      textPaint: textPaint,
    );
  }

  /// 优先使用参数对象的属性，如果参数对象的属性为 null，使用自己的属性
  ScreenTextStyle copyFrom(ScreenTextStyle other) {
    return ScreenTextStyle(
      position: other.position ?? position,
      rect: other.rect ?? rect,
      anchor: other.anchor ?? anchor,
      padding: other.padding ?? padding,
      opacity: other.opacity ?? opacity,
      outlined: other.outlined ?? outlined,
      colorTheme: other.colorTheme ?? colorTheme,
      backgroundSprite: other.backgroundSprite ?? backgroundSprite,
      textStyle: other.textStyle ?? textStyle,
      textPaint: other.textPaint,
    );
  }

  /// 优先使用自己的属性，如果自己的属性为 null，从参数对象的属性复制
  ScreenTextStyle fillFrom(ScreenTextStyle other) {
    return ScreenTextStyle(
      position: position ?? other.position,
      rect: rect ?? other.rect,
      anchor: anchor ?? other.anchor,
      padding: padding ?? other.padding,
      opacity: opacity ?? other.opacity,
      outlined: outlined ?? other.outlined,
      colorTheme: colorTheme ?? other.colorTheme,
      backgroundSprite: backgroundSprite ?? other.backgroundSprite,
      textStyle: textStyle ?? other.textStyle,
      textPaint: textPaint,
    );
  }
}

void drawScreenText(
  Canvas canvas,
  String text, {
  ScreenTextStyle? style,
}) {
  TextPaint textPaint = style?.textPaint ?? PresetTextPaints.light;

  // final opacity = style?.opacity ?? 1.0;

  if (style?.position != null) {
    if ((style?.outlined ?? false) &&
        style?.colorTheme != ScreenTextColorTheme.dark) {
      textPaint = TextPaint(
        style: textPaint.style.copyWith(
          shadows: const [
            Shadow(
                // bottomLeft
                offset: Offset(-0.5, -0.5),
                color: Colors.black),
            Shadow(
                // bottomRight
                offset: Offset(0.5, -0.5),
                color: Colors.black),
            Shadow(
                // topRight
                offset: Offset(0.5, 0.5),
                color: Colors.black),
            Shadow(
                // topLeft
                offset: Offset(-0.5, 0.5),
                color: Colors.black),
          ],
        ),
      );

      //   TextPaint? outlinePaint = _cachedOutline[textPaint];
      //   if (outlinePaint == null) {
      //     outlinePaint = textPaint.copyWith(
      //       (textStyle) => textStyle.copyWith(
      //         foreground: Paint()
      //           ..strokeWidth = 2
      //           ..color = Colors.black.withOpacity(opacity)
      //           ..style = PaintingStyle.stroke,
      //       ),
      //     );
      //     _cachedOutline[textPaint] = outlinePaint;
      //   }

      //   outlinePaint.render(canvas, text, style!.position!);
    }

    // 这里才是真正绘制文字的地方
    textPaint.render(canvas, text, style!.position!);
  } else {
    Vector2 textPosition = Vector2.zero();

    if (style?.rect != null) {
      final rect = style!.rect!;
      final anchor = style.anchor;
      final lineMetrics = textPaint.getLineMetrics(text);
      final textWidth = lineMetrics.width;
      final textHeight = lineMetrics.height;
      final padding = style.padding ?? const EdgeInsets.all(0);
      final offsetX = padding.left - padding.right;
      final offsetY = padding.top - padding.bottom;
      if (anchor == Anchor.topLeft) {
        textPosition = Vector2(rect.left + offsetX, rect.top + offsetY);
      } else if (anchor == Anchor.topCenter) {
        textPosition = Vector2(
            rect.left + (rect.width - textWidth) / 2 + offsetX,
            rect.top + offsetY);
      } else if (anchor == Anchor.topRight) {
        textPosition =
            Vector2(rect.right - textWidth + offsetX, rect.top + offsetY);
      } else if (anchor == Anchor.centerLeft) {
        textPosition = Vector2(rect.left + offsetX,
            rect.top + (rect.height - textHeight) / 2 + offsetY);
      } else if (anchor == Anchor.center) {
        textPosition = Vector2(
            rect.left + (rect.width - textWidth) / 2 + offsetX,
            rect.top + (rect.height - textHeight) / 2 + offsetY);
      } else if (anchor == Anchor.centerRight) {
        textPosition = Vector2(rect.right - textWidth + offsetX,
            rect.top + (rect.height - textHeight) / 2 + offsetY);
      } else if (anchor == Anchor.bottomLeft) {
        textPosition =
            Vector2(rect.left + offsetX, rect.bottom - textHeight + offsetY);
      } else if (anchor == Anchor.bottomCenter) {
        textPosition = Vector2(
            rect.left + (rect.width - textWidth) / 2 + offsetX,
            rect.bottom - textHeight + offsetY);
      } else if (anchor == Anchor.bottomRight) {
        textPosition = Vector2(rect.right - textWidth + offsetX,
            rect.bottom - textHeight + offsetY);
      } else {
        textPosition = Vector2(
            rect.left + offsetX + (anchor?.x ?? 0) * rect.width,
            rect.top + offsetY + (anchor?.y ?? 0) * rect.height);
      }
      if (style.backgroundSprite != null) {
        final backgroundRect = Rect.fromLTWH(
          textPosition.x - 10 - rect.left,
          textPosition.y - 5 - rect.top,
          textWidth + 20,
          textHeight + 10,
        );
        style.backgroundSprite?.renderRect(canvas, backgroundRect);
      }
    }

    drawScreenText(
      canvas,
      text,
      style: style?.copyWith(textPaint: textPaint, position: textPosition) ??
          ScreenTextStyle(textPaint: textPaint, position: textPosition),
    );
  }
}

void drawDottedLine(
  Canvas canvas,
  Vector2 start,
  double width,
  Paint paint,
  double gap,
) {
  double pointSize = paint.strokeWidth;
  double strokeVerticalOverflow = pointSize / 2;
  double jointSize = pointSize + gap;
  double leapSize = (width + gap) % jointSize;

  double position = start.x + strokeVerticalOverflow + leapSize / 2;
  List<Offset> points = [];

  // position + pointSize <= width + pointSize
  do {
    points.add(Offset(position, start.y + strokeVerticalOverflow));
  } while ((position += jointSize) <= width);

  canvas.drawPoints(PointMode.points, points, paint);
}
