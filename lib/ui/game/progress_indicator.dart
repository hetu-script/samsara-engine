import '../../paint.dart';
import '../../component/game_component.dart';
import '../../utils/color.dart';
import '../../extensions.dart';

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
    Paint? borderPaint,
  }) {
    borderPaint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..color = const Color.fromARGB(255, 156, 138, 138);

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

    final progressBorder =
        rBorder.copyWith(right: rBorder.left + value / max * rBorder.width);

    canvas.drawRRect(progressBorder, progressPaint);

    canvas.drawRRect(rBorder, borderPaint);

    final text = value.truncate().toString();

    drawScreenText(canvas, text, style: textStyle);
  }
}
