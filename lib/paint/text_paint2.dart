import 'package:flame/cache.dart';
import 'package:flame/text.dart';
import 'package:flutter/rendering.dart';

import 'text_element2.dart';

/// [TextPaint2] applies a Flutter [TextStyle] to a string of
/// text, creating a [TextPainterTextElement].
class TextPaint2 extends TextRenderer {
  TextPaint2({
    TextStyle? style,
    this.textDirection = TextDirection.ltr,
  }) : style = style ?? defaultTextStyle;

  final TextStyle style;
  final TextDirection textDirection;

  @override
  TextPainterTextElement2 format(String text) {
    final tp = toTextPainter(text);
    return TextPainterTextElement2(tp);
  }

  final MemoryCache<String, TextPainter> _textPainterCache = MemoryCache();

  static const TextStyle defaultTextStyle = TextStyle(
    color: Color(0xFFFFFFFF),
    fontFamily: 'Arial',
    fontSize: 24,
  );

  /// Returns a [TextPainter] that allows for text rendering and size
  /// measuring.
  ///
  /// A [TextPainter] has three important properties: paint, width and
  /// height (or size).
  ///
  /// Example usage:
  ///
  ///   const config = TextPaint(fontSize: 48.0, fontFamily: 'Arial');
  ///   final tp = config.toTextPainter('Score: $score');
  ///   tp.paint(canvas, const Offset(10, 10));
  ///
  /// However, you probably want to use the [render] method which already
  /// takes the anchor into consideration.
  /// That way, you don't need to perform the math for that yourself.
  TextPainter toTextPainter(String text) {
    if (!_textPainterCache.containsKey(text)) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: textDirection,
      );
      tp.layout();
      _textPainterCache.setValue(text, tp);
    }
    return _textPainterCache.getValue(text)!;
  }

  TextPaint2 copyWith(
    TextStyle Function(TextStyle) transform, {
    TextDirection? textDirection,
  }) {
    return TextPaint2(
      style: transform(style),
      textDirection: textDirection ?? this.textDirection,
    );
  }
}
