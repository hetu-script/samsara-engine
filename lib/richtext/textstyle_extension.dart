import 'package:flame/text.dart';

extension FlameTextStyleConversion on TextStyle {
  InlineTextStyle toInlineTextStyle({
    double? fontScale,
  }) {
    return InlineTextStyle(
      color: color,
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontScale: fontScale,
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
