import 'package:flame/text.dart';

extension FixedTextStyle on InlineTextStyle {
  TextPaint asTextRenderer2() {
    return TextPaint(
      style: asTextStyle2(),
    );
  }

  TextStyle asTextStyle2() {
    return TextStyle(
      color: foreground == null ? color : null,
      fontFamily: fontFamily,
      fontSize: fontSize! * (fontScale ?? 1.0),
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      height: height,
      leadingDistribution: leadingDistribution,
      shadows: shadows,
      fontFeatures: fontFeatures,
      fontVariations: fontVariations,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      background: background,
      foreground: foreground,
    );
  }
}
