import 'package:flutter/material.dart';

import 'outlined_text.dart';
import '../extensions.dart';
import 'mouse_region2.dart';

class DynamicColorProgressBar extends StatelessWidget {
  final double width;
  final double height;
  final num value, max;
  final bool showNumber, showNumberAsPercentage;
  final List<Color> colors;
  final List<double> stops = [];
  final double borderRadius;
  final Color? borderColor;
  final double? borderWidth;
  final bool useVerticalStyle;
  final void Function(Rect)? onMouseEnter;
  final void Function()? onMouseExit;
  final String? label;

  DynamicColorProgressBar({
    super.key,
    required this.width,
    required this.height,
    required this.value,
    required this.max,
    this.showNumber = true,
    this.showNumberAsPercentage = true,
    required this.colors,
    List<double>? stops,
    this.borderRadius = 0.0,
    this.borderColor,
    this.borderWidth,
    this.useVerticalStyle = false,
    this.onMouseEnter,
    this.onMouseExit,
    this.label,
  }) : assert(colors.length > 1) {
    if (stops == null || stops.isEmpty) {
      final d = 1.0 / (colors.length - 1);
      for (var i = 0; i < colors.length; ++i) {
        this.stops.add(i * d);
      }
      this.stops.last = 1.0;
    } else {
      assert(stops.length == colors.length);
      this.stops.addAll(stops);
    }
  }

  @override
  Widget build(BuildContext context) {
    final valueString = '$label: ${value.truncate()}/${max.truncate()}';
    return MouseRegion2(
      onEnter: onMouseEnter,
      onExit: onMouseExit,
      child: Row(
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(borderRadius),
              border: (borderWidth != null && borderWidth! > 0)
                  ? Border.all(
                      color: borderColor ??
                          Theme.of(context).colorScheme.onSurface,
                      width: borderWidth!,
                    )
                  : null,
            ),
            child: Stack(
              alignment: AlignmentDirectional.centerStart,
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  width: value / max * width,
                  height: height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors),
                    // color: lerpGradient(
                    //   percentage: value / max,
                    //   colors: colors,
                    //   stops: stops,
                    // ),
                  ),
                ),
                if (showNumber)
                  Align(
                    alignment: Alignment.center,
                    child: OutlinedText(
                      showNumberAsPercentage
                          ? (value / max).toPercentageString()
                          : valueString,
                      textColor: Theme.of(context).colorScheme.onSurface,
                      style: const TextStyle(fontSize: 12.0),
                    ),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
