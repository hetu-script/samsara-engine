import 'package:flutter/material.dart';

import 'outlined_text.dart';
import '../extensions.dart';
import '../utils/color.dart';

class DynamicColorProgressBar extends StatelessWidget {
  DynamicColorProgressBar({
    Key? key,
    this.title,
    required this.width,
    this.height = 18.0,
    required this.value,
    required this.max,
    this.showNumber = true,
    this.showNumberAsPercentage = true,
    required this.colors,
    List<double>? stops,
    this.borderRadius = 2.5,
  })  : assert(colors.length > 1),
        super(key: key) {
    if (stops == null || stops.isEmpty) {
      this.stops = [];
      final d = 1.0 / (colors.length - 1);
      for (var i = 0; i < colors.length; ++i) {
        this.stops.add(i * d);
      }
      this.stops.last = 1.0;
    } else {
      assert(stops.length == colors.length);
      this.stops = stops;
    }
  }

  final String? title;

  final double width;

  final double height;

  final num value, max;

  final bool showNumber, showNumberAsPercentage;

  final List<Color> colors;

  late final List<double> stops;

  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final valueString = '${value.truncate()}/${max.truncate()}';
    return Tooltip(
      message: valueString,
      child: Row(
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(right: 5.0),
              child: Text(title!),
            ),
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(borderRadius),
              border:
                  Border.all(color: Theme.of(context).colorScheme.onBackground),
            ),
            child: Stack(
              alignment: AlignmentDirectional.centerStart,
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  width: value / max * width,
                  height: height,
                  decoration: BoxDecoration(
                    color: lerpGradient(
                      percentage: value / max,
                      colors: colors,
                      stops: stops,
                    ),
                  ),
                ),
                if (showNumber)
                  Align(
                    alignment: Alignment.center,
                    child: OutlinedText(
                      showNumberAsPercentage
                          ? (value / max).toPercentageString()
                          : valueString,
                      textColor: Theme.of(context).colorScheme.onBackground,
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
