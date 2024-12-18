import 'package:flame/text.dart';

extension FlameTextStyleConversion on TextStyle {
  InlineTextStyle toInlineTextStyle() {
    return InlineTextStyle(
      color: color,
      fontFamily: fontFamily,
      fontSize: fontSize,
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
