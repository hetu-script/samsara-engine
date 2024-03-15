import '../paint.dart';
import 'game_component.dart';
import '../utils/color.dart';
import '../extensions.dart';

class DynamicColorProgressIndicator extends GameComponent {
  late final ScreenTextStyle textStyle;

  double value, max;

  bool showNumber, showNumberAsPercentage;

  final List<Color> colors;

  late final List<double> stops;

  DynamicColorProgressIndicator({
    super.position,
    super.size,
    super.anchor,
    super.borderRadius = 3.5,
    required this.value,
    required this.max,
    this.showNumber = false,
    this.showNumberAsPercentage = false,
    required this.colors,
    List<double>? stops,
    super.borderPaint,
    super.flipH,
  }) {
    textStyle = ScreenTextStyle(
      rect: border,
      anchor: Anchor.center,
      colorTheme: ScreenTextColorTheme.light,
      outlined: true,
    );

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

  @override
  void render(Canvas canvas) {
    final progressPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = lerpGradient(
        percentage: value / max,
        colors: colors,
        stops: stops,
      );

    final double progress =
        max > 0 ? rrect.left + value / max * rrect.width : 0.0;

    final progressBorder = rrect.copyWith(right: progress);

    canvas.drawRRect(progressBorder, progressPaint);

    canvas.drawRRect(rrect, borderPaint);

    final text = '${value.truncate()}/${max.truncate()}';

    drawScreenText(canvas, text, style: textStyle);
  }
}
