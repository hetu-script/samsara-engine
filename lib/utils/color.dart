import 'package:flutter/material.dart';

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}

/// Converts a blur radius in pixels to sigmas.
///
/// See the sigma argument to [MaskFilter.blur].
///
// See SkBlurMask::ConvertRadiusToSigma().
// <https://github.com/google/skia/blob/bb5b77db51d2e149ee66db284903572a5aac09be/src/effects/SkBlurMask.cpp#L23>
double convertRadiusToSigma(double radius) {
  return radius > 0 ? radius * 0.57735 + 0.5 : 0;
}

Color lerpGradient({
  required double percentage,
  required List<Color> colors,
  List<double>? stops,
}) {
  final List<double> s = stops ?? [];
  if (s.isEmpty) {
    final d = 1.0 / (colors.length - 1);
    for (var i = 0; i < colors.length; ++i) {
      s.add(i * d);
    }
    s.last = 1.0;
  }

  for (var i = 0; i < s.length - 1; i++) {
    final leftStop = s[i], rightStop = s[i + 1];
    final leftColor = colors[i], rightColor = colors[i + 1];
    if (percentage <= leftStop) {
      return leftColor;
    } else if (percentage < rightStop) {
      final sectionT = (percentage - leftStop) / (rightStop - leftStop);
      return Color.lerp(leftColor, rightColor, sectionT)!;
    }
  }
  return colors.last;
}
