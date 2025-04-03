import 'dart:ui' show PointMode;

import 'package:flutter/material.dart' hide LineMetrics;
import 'package:flame/components.dart';
import 'package:flame/text.dart';

import 'package:colorfilter_generator/colorfilter_generator.dart';
import 'package:colorfilter_generator/addons.dart';

// import 'package:colorfilter_generator/presets.dart';

import '../extensions.dart';
// import '../widgets/sprite_widget.dart';

export '../extensions.dart' show Vector2Ex;
export 'package:flame/extensions.dart' show Vector2Extension;
export '../types.dart';

// import 'text_paint2.dart';

// export 'text_paint2.dart';

RegExp newLineExp = RegExp(r'\n');
double kLineSpacing = 0.0;
double kDefaultRichTextFontSize = 16.0;

abstract class PresetFilters {
  static ColorFilter brightness(double value) {
    return ColorFilter.matrix(ColorFilterGenerator(
        name: 'brightnessTint',
        filters: [ColorFilterAddons.brightness(value)]).matrix);
  }
}

// a matrix definition of a greyscale filter
// see https://api.flutter.dev/flutter/dart-ui/ColorFilter/ColorFilter.matrix.html
// see https://www.w3.org/TR/filter-effects-1/#grayscaleEquivalent
const ColorFilter kColorFilterGreyscale = ColorFilter.matrix(<double>[
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
]);

// https://developer.squareup.com/blog/welcome-to-the-color-matrix/
ColorFilter getColorFilterTintMatrix({
  Color tintColor = Colors.grey,
  double scale = 1,
}) {
  final double r = tintColor.r;
  final double g = tintColor.g;
  final double b = tintColor.b;

  final double rTint = r / 255;
  final double gTint = g / 255;
  final double bTint = b / 255;

  final double rL = 0.2126;
  final double gL = 0.7152;
  final double bL = 0.0722;

  final double translate = 1 - scale * 0.5;

  return ColorFilter.matrix(<double>[
    (rL * rTint * scale),
    (gL * rTint * scale),
    (bL * rTint * scale),
    (0),
    (r * translate),
    (rL * gTint * scale),
    (gL * gTint * scale),
    (bL * gTint * scale),
    (0),
    (g * translate),
    (rL * bTint * scale),
    (gL * bTint * scale),
    (bL * bTint * scale),
    (0),
    (b * translate),
    (0),
    (0),
    (0),
    (1),
    (0),
  ]);
}

abstract class PresetColors {
  static const light = Colors.white70;
  static const dark = Colors.black87;
  static const primary = Colors.blue;
  static const secondary = Colors.grey;
  static const info = Colors.lightBlue;
  static const success = Colors.green;
  static const warning = Colors.yellow;
  static const danger = Colors.red;
  static final invalid = Colors.grey.shade300;
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

  static final debug = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke
    ..color = Colors.lightBlue;

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

final Map<TextPaint, TextPaint> _cachedOutline = {};

abstract class PresetTextPaints {
  static final TextPaint light = TextPaint(
    style: TextStyle(
      color: Colors.white70,
      fontSize: kDefaultRichTextFontSize,
    ),
  );
  static final TextPaint dark = TextPaint(
    style: TextStyle(
      color: Colors.black87,
      fontSize: kDefaultRichTextFontSize,
    ),
  );
  static final TextPaint primary = TextPaint(
    style: TextStyle(
      color: Colors.blue,
      fontSize: kDefaultRichTextFontSize,
    ),
  );
  static final TextPaint secondary = TextPaint(
    style: TextStyle(
      color: Colors.grey,
      fontSize: kDefaultRichTextFontSize,
    ),
  );
  static final TextPaint info = TextPaint(
    style: TextStyle(
      color: Colors.lightBlue,
      fontSize: kDefaultRichTextFontSize,
    ),
  );
  static final TextPaint success = TextPaint(
    style: TextStyle(
      color: Colors.green,
      fontSize: kDefaultRichTextFontSize,
    ),
  );
  static final TextPaint warning = TextPaint(
    style: TextStyle(
      color: Colors.yellow,
      fontSize: kDefaultRichTextFontSize,
    ),
  );
  static final TextPaint danger = TextPaint(
    style: TextStyle(
      color: Colors.red,
      fontSize: kDefaultRichTextFontSize,
    ),
  );
}

enum ScreenTextOverflow {
  visible,
  hidden,
  ellipsis,
  wordwrap,
}

class ScreenTextConfig {
  final Vector2? size;
  final Anchor? anchor;
  final EdgeInsets? padding;
  final bool? outlined;
  final double? scale;
  final ScreenTextOverflow? overflow;
  final TextStyle? textStyle;
  final TextAlign? textAlign;

  const ScreenTextConfig({
    this.size,
    this.anchor,
    this.padding,
    this.outlined,
    this.scale,
    this.overflow,
    this.textStyle,
    this.textAlign,
  });

  /// 优先使用参数的属性，如果参数为 null，使用自己的属性
  ScreenTextConfig copyWith({
    Vector2? size,
    Anchor? anchor,
    EdgeInsets? padding,
    double? opacity,
    bool? outlined,
    double? scale,
    ScreenTextOverflow? overflow,
    TextStyle? textStyle,
    TextAlign? textAlign,
  }) {
    return ScreenTextConfig(
      size: size ?? this.size,
      anchor: anchor ?? this.anchor,
      padding: padding ?? this.padding,
      outlined: outlined ?? this.outlined,
      scale: scale ?? this.scale,
      overflow: overflow ?? this.overflow,
      textStyle: (textStyle ?? TextStyle()).merge(this.textStyle),
      textAlign: textAlign ?? this.textAlign,
    );
  }

  /// 优先使用自己的属性，如果自己的属性为 null，使用参数的属性
  ScreenTextConfig fillWith({
    Vector2? size,
    Anchor? anchor,
    EdgeInsets? padding,
    double? opacity,
    bool? outlined,
    double? scale,
    ScreenTextOverflow? overflow,
    TextStyle? textStyle,
    TextAlign? textAlign,
  }) {
    return ScreenTextConfig(
      size: this.size ?? size,
      anchor: this.anchor ?? anchor,
      padding: this.padding ?? padding,
      outlined: this.outlined ?? outlined,
      scale: this.scale ?? scale,
      overflow: this.overflow ?? overflow,
      textStyle: (this.textStyle ?? TextStyle()).merge(textStyle),
      textAlign: this.textAlign ?? textAlign,
    );
  }

  /// 优先使用参数对象的属性，如果参数对象的属性为 null，使用自己的属性
  ScreenTextConfig copyFrom(ScreenTextConfig? other) {
    return ScreenTextConfig(
      size: other?.size ?? size,
      anchor: other?.anchor ?? anchor,
      padding: other?.padding ?? padding,
      outlined: other?.outlined ?? outlined,
      scale: other?.scale ?? scale,
      overflow: other?.overflow ?? overflow,
      textStyle: (other?.textStyle ?? TextStyle()).merge(textStyle),
      textAlign: other?.textAlign ?? textAlign,
    );
  }

  /// 优先使用自己的属性，如果自己的属性为 null，从参数对象的属性复制
  ScreenTextConfig fillFrom(ScreenTextConfig? other) {
    return ScreenTextConfig(
      size: size ?? other?.size,
      anchor: anchor ?? other?.anchor,
      padding: padding ?? other?.padding,
      outlined: outlined ?? other?.outlined,
      scale: scale ?? other?.scale,
      overflow: overflow ?? other?.overflow,
      textStyle: (textStyle ?? TextStyle()).merge(other?.textStyle),
      textAlign: textAlign ?? other?.textAlign,
    );
  }
}

TextPaint getTextPaint({
  TextStyle? style,
  ScreenTextConfig? config,
  int alpha = 255,
}) {
  if (config == null) {
    return PresetTextPaints.light;
  } else {
    TextStyle inputStyle = (style ?? config.textStyle ?? TextStyle());
    if (inputStyle.color != null) {
      inputStyle =
          inputStyle.copyWith(color: inputStyle.color!.withAlpha(alpha));
    } else {
      inputStyle =
          inputStyle.copyWith(color: PresetColors.light.withAlpha(alpha));
    }
    return TextPaint(
      style: inputStyle.merge(
        TextStyle(
          fontSize: (style?.fontSize ??
                  config.textStyle?.fontSize ??
                  kDefaultRichTextFontSize) *
              (config.scale ?? (1.0)),
          // shadows: config.outlined == true
          //     ? [
          //         Shadow(
          //             // bottomLeft
          //             offset: const Offset(-1, -1),
          //             color: Colors.black.withAlpha(128)),
          //         Shadow(
          //             // bottomRight
          //             offset: const Offset(1, -1),
          //             color: Colors.black.withAlpha(128)),
          //         Shadow(
          //             // topRight
          //             offset: const Offset(1, 1),
          //             color: Colors.black.withAlpha(128)),
          //         Shadow(
          //             // topLeft
          //             offset: const Offset(-1, 1),
          //             color: Colors.black.withAlpha(128)),
          //       ]
          //     : null,
        ),
      ),
    );
  }
}

double getLinesHeight(int length, TextPaint textPaint) {
  return textPaint.getLineMetrics(' ').height * length;
}

/// 接受一个文本，按照一个固定宽度计算出换行后的多行文本
/// 文本中可能存在的硬换行'\n'也会被考虑在内
/// 计算出多行文字的总体高度，用于垂直区域的对齐
List<String> getWrappedText(
  String text, {
  required double maxWidth,
  required TextPaint textPaint,
  ScreenTextConfig? config,
}) {
  final result = <String>[];
  final rawLines = text.split(newLineExp);
  for (final line in rawLines) {
    String textBefore, textAfter;
    String current = line;
    do {
      LineMetrics lm = textPaint.getLineMetrics(current);
      int currentLength = current.length;
      do {
        textBefore = current.substring(0, currentLength);
        textAfter = current.substring(currentLength);
        lm = textPaint.getLineMetrics(textBefore);
        --currentLength;
      } while (lm.width > maxWidth && currentLength > 1);
      result.add(textBefore);
      current = textAfter;
    } while (textAfter.isNotEmpty);
  }
  return result;
}

/// 绘制一行或多行文字，返回最后一个字的右上角的位置
/// 这里接受的参数是一个按照行保存的列表
/// 每一个行字符串中需要确保没有换行符。
/// 之所以一次绘制多行文本
/// 是因为需要根据他们的总体高度和宽度统一处理对齐
Offset drawMultilineText(
  Canvas canvas,
  List<String> lines,
  TextPaint textPaint, {
  Offset position = Offset.zero,
  ScreenTextConfig? config,
  double offsetX = 0.0,
  double offsetY = 0.0,
  double? previousAscent,
  bool debugMode = false,
}) {
  /// 计算出多行文字的总体高度，用于垂直方向的对齐
  /// 因为字体中不同字符可能高度有差异，这里只是使用了一个基准高度计算来保证结果一致
  final lineHeight = textPaint.getLineMetrics(' ').height;
  final paragraphHeight = lineHeight * lines.length;

  final anchor = config?.anchor ?? Anchor.topLeft;
  final padding = config?.padding ?? EdgeInsets.zero;
  // 文字区域
  Rect rect = Rect.fromLTWH(
    position.dx,
    position.dy,
    config?.size?.x ?? 0.0,
    config?.size?.y ?? 0.0,
  );
  // if (debugMode) {
  //   canvas.drawRect(rect, PresetPaints.debug);
  // }
  late Offset lastCharacterPosition;
  // 这里分别处理每一行的对齐
  double currentLineOffsetY = 0.0;
  for (var i = 0; i < lines.length; ++i) {
    final currentLine = lines[i];
    final lm = textPaint.getLineMetrics(currentLine);
    final lineWidth = lm.width;
    double baseLineFix = 0.0;
    // 因为不同的字的基准线可能有差异，导致不能简单地以顶部对齐
    // 而需要找到这个字本身的基线和上一个字的基线对齐
    if (previousAscent != null && lm.ascent != previousAscent) {
      baseLineFix = previousAscent - lm.ascent;
    }
    if (currentLine.isNotEmpty) {
      double lineLeft, lineTop;
      if (anchor == Anchor.topCenter) {
        lineLeft = rect.left + (rect.width - lineWidth) / 2;
        lineTop = rect.top + padding.top + currentLineOffsetY;
      } else if (anchor == Anchor.topRight) {
        lineLeft = rect.right - lineWidth - padding.right;
        lineTop = rect.top + padding.top + currentLineOffsetY;
      } else if (anchor == Anchor.centerLeft) {
        lineLeft = rect.left + padding.left;
        lineTop =
            rect.top + (rect.height - paragraphHeight) / 2 + currentLineOffsetY;
      } else if (anchor == Anchor.center) {
        lineLeft = rect.left + (rect.width - lineWidth) / 2;
        lineTop =
            rect.top + (rect.height - paragraphHeight) / 2 + currentLineOffsetY;
      } else if (anchor == Anchor.centerRight) {
        lineLeft = rect.right - lineWidth - padding.right;
        lineTop =
            rect.top + (rect.height - paragraphHeight) / 2 + currentLineOffsetY;
      } else if (anchor == Anchor.bottomLeft) {
        lineLeft = rect.left + padding.left;
        lineTop =
            rect.bottom - paragraphHeight - padding.bottom + currentLineOffsetY;
      } else if (anchor == Anchor.bottomCenter) {
        lineLeft = rect.left + (rect.width - lineWidth) / 2;
        lineTop =
            rect.bottom - paragraphHeight - padding.bottom + currentLineOffsetY;
      } else if (anchor == Anchor.bottomRight) {
        lineLeft = rect.right - lineWidth - padding.right;
        lineTop =
            rect.bottom - paragraphHeight - padding.bottom + currentLineOffsetY;
      }
      // anchor == Anchor.topLeft
      else {
        lineLeft = rect.left + padding.left;
        lineTop = rect.top + padding.top + currentLineOffsetY;
      }
      if (debugMode) {
        Rect textRect = Rect.fromLTWH(
          lineLeft + offsetX,
          lineTop + offsetY,
          lm.width,
          lm.height,
        );
        canvas.drawRect(textRect, PresetPaints.debug);
      }
      if (i == lines.length - 1) {
        lastCharacterPosition =
            Offset(lineWidth, currentLineOffsetY + baseLineFix);
      }

      // another way to draw text shadows, obseleted due to low efficiency
      TextPaint? outlinePaint = _cachedOutline[textPaint];
      if (outlinePaint == null) {
        outlinePaint = textPaint.copyWith(
          (textStyle) => textStyle.copyWith(
            foreground: Paint()
              ..strokeWidth = 3
              ..color = Colors.black
              ..style = PaintingStyle.stroke,
          ),
        );
        _cachedOutline[textPaint] = outlinePaint;
      }

      outlinePaint.render(canvas, currentLine,
          Vector2(lineLeft + offsetX, lineTop + offsetY + baseLineFix));

      textPaint.render(
        canvas,
        currentLine,
        Vector2(lineLeft + offsetX, lineTop + offsetY + baseLineFix),
      );
    }
    currentLineOffsetY += lineHeight + kLineSpacing;
  }

  return lastCharacterPosition;
}

/// 在指定位置绘制文字
/// 接受的源字符串中可能存在r'\n'形式的字面值转义换行符和真正的'\n'硬换行符
/// 其他形式的换行会忽略
/// 实际显示时，还可能会根据显示区域宽度添加一些软换行符
/// position代表文本区域的位置
/// 在config中配置size和anchor可以进行对齐和自动换行
void drawScreenText(
  Canvas canvas,
  String text, {
  int alpha = 255,
  Offset position = Offset.zero,
  TextPaint? textPaint,
  ScreenTextConfig? config,
  bool debugMode = false,
}) {
  text = text.replaceAllEscapedLineBreaks();

  textPaint ??= getTextPaint(config: config, alpha: alpha);

  double maxWidth = config?.size?.x ?? 0.0;
  final overflow = config?.overflow ?? ScreenTextOverflow.visible;
  if (overflow != ScreenTextOverflow.visible && maxWidth > 0.0) {
    // 根据文字区域宽度计算出软换行后的多行文本
    final lines = getWrappedText(
      text,
      maxWidth: maxWidth -
          (config?.padding?.left ?? 0.0) -
          (config?.padding?.right ?? 0.0),
      textPaint: textPaint,
      config: config,
    );
    drawMultilineText(
      canvas,
      lines,
      textPaint,
      position: position,
      config: config,
      debugMode: debugMode,
    );
  } else {
    drawMultilineText(
      canvas,
      [text],
      textPaint,
      position: position,
      config: config,
      debugMode: debugMode,
    );
  }

  // if (style.backgroundSprite != null) {
  //   final backgroundRect = Rect.fromLTWH(
  //     textPosition.left - 10 - (style.rect?.left ?? 0.0),
  //     textPosition.top - 5 - (style.rect?.top ?? 0.0),
  //     textPosition.width + 10,
  //     textPosition.height + 10,
  //   );
  //   style.backgroundSprite?.renderRect(canvas, backgroundRect);
  // }
}

/// position代表文本区域的位置
// void drawScreenRichText(
//   Canvas canvas,
//   String richText, {
//   Offset position = Offset.zero,
//   ScreenTextConfig? config,
//   bool debugMode = false,
// }) {
//   List<TextPaint> textPaints = [];
//   double currentOffsetX = 0.0, currentOffsetY = 0.0;
//   for (var i = 0; i < richTextParagraphs.length; ++i) {
//     final paragraph = richTextParagraphs[i];
//     // 遍历一遍每个段落，获得整个文本的高度
//     double paragraphHeight = 0.0;
//     double paragraphWidth = 0.0;
//     for (var j = 0; j < paragraph.children!.length; ++j) {
//       final span = paragraph.children![j];
//       final textPaint = getTextPaint(style: span.style, config: config);
//       textPaints.add(textPaint);
//       if (span is TextSpan && span.text?.isNotEmpty == true) {
//         final m = textPaint.getLineMetrics(span.text!);
//         paragraphWidth += m.width;
//         paragraphHeight += m.height;
//       }
//     }

//     Offset currentOffset = Offset.zero;
//     double? ascent;
//     for (var j = 0; j < paragraph.length; ++j) {
//       final span = paragraph[j];
//       if (span is TextSpan && span.text?.isNotEmpty == true) {
//         final text = span.text!;
//         final textPaint = textPaints[j];
//         final offset = drawMultilineText(
//           canvas,
//           [text],
//           textPaint,
//           position: position,
//           config: config,
//           offsetX: currentOffset.dx,
//           offsetY: currentOffset.dy,
//           previousAscent: ascent,
//           debugMode: debugMode,
//         );
//         ascent = textPaint.getLineMetrics(text).ascent;
//         currentOffset += offset;
//       } else if (span is WidgetSpan) {
//         // if (span.child is SpriteWidget) {
//         // final sprite = (span.child as SpriteWidget).sprite;
//         // sprite.renderRect(
//         //   canvas,
//         //   Rect.fromLTWH(config!.rect!.left, config.rect!.top),
//         // );
//         // }
//       }
//     }
//   }
// }

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
