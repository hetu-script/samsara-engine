import '../paint/paint.dart';
import 'border_component.dart';
import '../utils/color.dart';
import '../extensions.dart';
import '../gestures/gesture_mixin.dart';

class DynamicColorProgressIndicator extends BorderComponent
    with HandlesGesture {
  late final ScreenTextConfig textStyle;

  int _value, max;

  bool showNumber, showNumberAsPercentage;

  final List<Color> colors;

  late final List<double> stops;

  double _elasped = 0;
  bool _isAnimating = false;
  double animationDuration;
  double _currentValue = 0;

  bool animated;

  DynamicColorProgressIndicator({
    super.position,
    super.size,
    super.anchor,
    super.borderRadius = 3.5,
    required int value,
    required this.max,
    this.showNumber = false,
    this.showNumberAsPercentage = false,
    required this.colors,
    List<double>? stops,
    super.borderPaint,
    this.animated = true,
    this.animationDuration = 4,
  })  : _value = value,
        _currentValue = value.toDouble() {
    textStyle = ScreenTextConfig(
      size: border.size.toVector2(),
      anchor: Anchor.center,
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

  int get value => _value;

  void setValue(int newValue, {bool animated = true}) {
    _value = newValue;
    if (animated) {
      _elasped = 0;
      _isAnimating = true;
    } else {
      _currentValue = newValue.toDouble();
    }
  }

  @override
  void update(double dt) {
    if (animated && _isAnimating && (_currentValue != _value.toDouble())) {
      _elasped += dt;
      if (_elasped >= animationDuration) {
        _elasped = 0;
        _isAnimating = false;
        _currentValue = _value.toDouble();
      } else {
        final diff = _elasped / animationDuration * (_value - _currentValue);
        _currentValue += diff;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!isVisible) return;

    final progressPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = lerpGradient(
        percentage: _currentValue / max,
        colors: colors,
        stops: stops,
      );

    double progress;

    if (max <= 0) {
      progress = 0;
    } else {
      if (_currentValue < max) {
        progress = roundBorder.left + _currentValue / max * roundBorder.width;
      } else {
        progress = roundBorder.width;
      }
    }

    final progressBorder = roundBorder.copyWith(right: progress);

    canvas.drawRRect(progressBorder, progressPaint);

    canvas.drawRRect(roundBorder, borderPaint);

    final text = '${_currentValue.toInt()}/$max';

    drawScreenText(canvas, text, config: textStyle);
  }
}
