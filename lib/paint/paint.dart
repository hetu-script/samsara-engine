import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flame/components.dart';

export 'package:flame/text.dart' show TextPaint;

final borderPaint = Paint()
  ..strokeWidth = 1
  ..style = PaintingStyle.stroke
  ..color = Colors.white30;

final borderPaintFocused = Paint()
  ..strokeWidth = 1.5
  ..style = PaintingStyle.stroke
  ..color = Colors.yellow;

final borderPaintSelected = Paint()
  ..strokeWidth = 3
  ..style = PaintingStyle.stroke
  ..color = Colors.lightBlue;

final borderPaintPressed = Paint()
  ..strokeWidth = 2.5
  ..style = PaintingStyle.stroke
  ..color = Colors.red;

final Map<TextPaint, TextPaint> _cachedOutline = {};

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

class ScreenTextStyle {
  Vector2? position;
  Rect? rect;
  Anchor? anchor;
  EdgeInsets? padding;
  TextPaint? textPaint;
  bool? outlined;
  ScreenTextColorTheme? colorTheme;
  Sprite? backgroundSprite;
  TextStyle? textStyle;

  ScreenTextStyle({
    this.position,
    this.rect,
    this.anchor,
    this.padding,
    this.textPaint,
    this.outlined,
    this.colorTheme,
    this.backgroundSprite,
    this.textStyle,
  });

  /// 优先使用参数的属性，如果参数为 null，使用自己的属性
  ScreenTextStyle copyWith({
    Vector2? position,
    Rect? rect,
    Anchor? anchor,
    EdgeInsets? padding,
    TextPaint? textPaint,
    bool? outlined,
    ScreenTextColorTheme? colorTheme,
    Sprite? backgroundSprite,
    TextStyle? textStyle,
  }) {
    return ScreenTextStyle(
      position: position ?? this.position,
      rect: rect ?? this.rect,
      anchor: anchor ?? this.anchor,
      padding: padding ?? this.padding,
      textPaint: textPaint ?? this.textPaint,
      outlined: outlined ?? this.outlined,
      colorTheme: colorTheme ?? this.colorTheme,
      backgroundSprite: backgroundSprite ?? this.backgroundSprite,
      textStyle: textStyle ?? this.textStyle,
    );
  }

  /// 优先使用自己的属性，如果自己的属性为 null，使用参数的属性
  ScreenTextStyle fillWith({
    Vector2? position,
    Rect? rect,
    Anchor? anchor,
    EdgeInsets? padding,
    TextPaint? textPaint,
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
      textPaint: this.textPaint ?? textPaint,
      outlined: this.outlined ?? outlined,
      colorTheme: this.colorTheme ?? colorTheme,
      backgroundSprite: this.backgroundSprite ?? backgroundSprite,
      textStyle: this.textStyle ?? textStyle,
    );
  }

  /// 优先使用参数对象的属性，如果参数对象的属性为 null，使用自己的属性
  ScreenTextStyle copyFrom(ScreenTextStyle other) {
    return ScreenTextStyle(
      position: other.position ?? position,
      rect: other.rect ?? rect,
      anchor: other.anchor ?? anchor,
      padding: other.padding ?? padding,
      textPaint: other.textPaint ?? textPaint,
      outlined: other.outlined ?? outlined,
      colorTheme: other.colorTheme ?? colorTheme,
      backgroundSprite: other.backgroundSprite ?? backgroundSprite,
      textStyle: other.textStyle ?? textStyle,
    );
  }

  /// 优先使用自己的属性，如果自己的属性为 null，从参数对象的属性复制
  ScreenTextStyle fillFrom(ScreenTextStyle other) {
    return ScreenTextStyle(
      position: position ?? other.position,
      rect: rect ?? other.rect,
      anchor: anchor ?? other.anchor,
      padding: padding ?? other.padding,
      textPaint: textPaint ?? other.textPaint,
      outlined: outlined ?? other.outlined,
      colorTheme: colorTheme ?? other.colorTheme,
      backgroundSprite: backgroundSprite ?? other.backgroundSprite,
      textStyle: textStyle ?? other.textStyle,
    );
  }
}

void drawScreenText(
  Canvas canvas,
  String text, {
  required ScreenTextStyle style,
}) {
  if (style.position == null && style.rect == null) {
    style.position = Vector2.zero();
  }

  TextPaint? textPaint = style.textPaint;

  if (textPaint == null) {
    final colorTheme = style.colorTheme ?? ScreenTextColorTheme.light;
    switch (colorTheme) {
      case ScreenTextColorTheme.light:
        textPaint = TextPaint(
          style: style.textStyle ??
              const TextStyle(
                color: Colors.white,
                fontSize: 12.0,
              ),
        );
        break;
      case ScreenTextColorTheme.dark:
        textPaint = TextPaint(
          style: style.textStyle ??
              const TextStyle(
                color: Colors.black,
                fontSize: 12.0,
              ),
        );
        break;
      case ScreenTextColorTheme.primary:
        textPaint = TextPaint(
          style: style.textStyle ??
              const TextStyle(
                color: Colors.blue,
                fontSize: 12.0,
              ),
        );
        break;
      case ScreenTextColorTheme.secondary:
        textPaint = TextPaint(
          style: style.textStyle ??
              const TextStyle(
                color: Colors.grey,
                fontSize: 12.0,
              ),
        );
        break;
      case ScreenTextColorTheme.success:
        textPaint = TextPaint(
          style: style.textStyle ??
              const TextStyle(
                color: Colors.green,
                fontSize: 12.0,
              ),
        );
        break;
      case ScreenTextColorTheme.info:
        textPaint = TextPaint(
          style: style.textStyle ??
              const TextStyle(
                color: Colors.lightBlue,
                fontSize: 12.0,
              ),
        );
        break;
      case ScreenTextColorTheme.warning:
        textPaint = TextPaint(
          style: style.textStyle ??
              const TextStyle(
                color: Colors.yellow,
                fontSize: 12.0,
              ),
        );
        break;
      case ScreenTextColorTheme.danger:
        textPaint = TextPaint(
          style: style.textStyle ??
              const TextStyle(
                color: Colors.red,
                fontSize: 12.0,
              ),
        );
        break;
    }
  }
  if (style.position != null) {
    TextPaint? outlinePaint = _cachedOutline[textPaint];
    if (outlinePaint == null) {
      outlinePaint = textPaint.copyWith(
        (textStyle) => textStyle.copyWith(
          foreground: Paint()
            ..strokeWidth = 2.5
            ..color = Colors.black
            ..style = PaintingStyle.stroke,
        ),
      );
      _cachedOutline[textPaint] = outlinePaint;
    }
    if ((style.outlined ?? false) &&
        style.colorTheme != ScreenTextColorTheme.dark) {
      outlinePaint.render(canvas, text, style.position!);
    }
    textPaint.render(canvas, text, style.position!);
  } else if (style.rect != null) {
    final rect = style.rect!;
    final anchor = style.anchor;
    final textWidth = textPaint.measureTextWidth(text);
    final textHeight = textPaint.measureTextHeight(text);
    Vector2 textPosition;
    final padding = style.padding ?? const EdgeInsets.all(0);
    final offsetX = padding.left - padding.right;
    final offsetY = padding.top - padding.bottom;
    if (anchor == Anchor.topLeft) {
      textPosition = Vector2(rect.left + offsetX, rect.top + offsetY);
    } else if (anchor == Anchor.topCenter) {
      textPosition = Vector2(rect.left + (rect.width - textWidth) / 2 + offsetX,
          rect.top + offsetY);
    } else if (anchor == Anchor.topRight) {
      textPosition =
          Vector2(rect.right - textWidth + offsetX, rect.top + offsetY);
    } else if (anchor == Anchor.centerLeft) {
      textPosition = Vector2(rect.left + offsetX,
          rect.top + (rect.height - textHeight) / 2 + offsetY);
    } else if (anchor == Anchor.center) {
      textPosition = Vector2(rect.left + (rect.width - textWidth) / 2 + offsetX,
          rect.top + (rect.height - textHeight) / 2 + offsetY);
    } else if (anchor == Anchor.centerRight) {
      textPosition = Vector2(rect.right - textWidth + offsetX,
          rect.top + (rect.height - textHeight) / 2 + offsetY);
    } else if (anchor == Anchor.bottomLeft) {
      textPosition =
          Vector2(rect.left + offsetX, rect.bottom - textHeight + offsetY);
    } else if (anchor == Anchor.bottomCenter) {
      textPosition = Vector2(rect.left + (rect.width - textWidth) / 2 + offsetX,
          rect.bottom - textHeight + offsetY);
    } else if (anchor == Anchor.bottomRight) {
      textPosition = Vector2(
          rect.right - textWidth + offsetX, rect.bottom - textHeight + offsetY);
    } else {
      textPosition = Vector2(rect.left + offsetX + (anchor?.x ?? 0),
          rect.top + offsetY + (anchor?.y ?? 0));
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

    drawScreenText(
      canvas,
      text,
      style: style.copyWith(position: textPosition),
    );
  }
}

void drawDottedLine(
  Canvas canvas,
  Offset start,
  double width,
  Paint paint,
  double gap,
) {
  double pointSize = paint.strokeWidth;
  double strokeVerticalOverflow = pointSize / 2;
  double jointSize = pointSize + gap;
  double leapSize = (width + gap) % jointSize;

  double position = start.dx + strokeVerticalOverflow + leapSize / 2;
  List<Offset> points = [];

  // position + pointSize <= width + pointSize
  do {
    points.add(Offset(position, start.dy + strokeVerticalOverflow));
  } while ((position += jointSize) <= width);

  canvas.drawPoints(PointMode.points, points, paint);
}
