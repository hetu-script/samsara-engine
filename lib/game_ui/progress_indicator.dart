import '../paint/paint.dart';
import '../component/game_component.dart';
import '../utils/color.dart';
import '../extensions.dart';

class DynamicColorProgressIndicator extends GameComponent {
  late final ScreenTextStyle textStyle;

  double value, max;

  bool showNumber, showNumberAsPercentage;

  final List<Color> colors;

  late final List<double> stops;

  final Paint borderPaint;

  DynamicColorProgressIndicator({
    required double x,
    required double y,
    required double width,
    required double height,
    super.borderRadius = 3.5,
    required this.value,
    required this.max,
    this.showNumber = false,
    this.showNumberAsPercentage = false,
    required this.colors,
    List<double>? stops,
    Paint? borderPaint,
  })  : borderPaint = borderPaint ?? Paint()
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..color = Colors.grey,
        super(
          position: Vector2(x, y),
          size: Vector2(width, height),
        ) {
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
        rborder.copyWith(right: rborder.left + value / max * rborder.width);

    canvas.drawRRect(progressBorder, progressPaint);

    canvas.drawRRect(rborder, borderPaint);

    final text = value.truncate().toString();

    drawScreenText(
      canvas,
      text,
      style: textStyle,
    );
  }
}
