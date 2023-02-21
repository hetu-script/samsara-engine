import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';

/// Component used to generate numbers using the gameLoop.
class ValueGenerator extends Component {
  bool _isFinishing = false;
  bool _isFinished = false;

  final _maxInMilliSeconds = 1000;
  final Duration duration;
  final double begin;
  final double end;
  final Curve curve;
  final void Function()? onStart;
  final void Function()? onFinish;
  final void Function(double)? onChange;
  final bool autoStart;

  double _currentValue = 0;
  double _displacement = 0;
  bool _isRunning = false;

  ValueGenerator(
    this.duration, {
    this.begin = 0,
    this.end = 1,
    this.curve = Curves.decelerate,
    this.onStart,
    this.onFinish,
    this.onChange,
    this.autoStart = false,
  }) {
    _displacement = end - begin;

    if (autoStart) {
      start();
    }
  }

  @override
  void update(double dt) {
    if (!_isRunning) return;

    _currentValue += dt * _maxInMilliSeconds;
    if (_currentValue >= duration.inMilliseconds) {
      finish();
    } else {
      double value = curve.transform(_currentValue / duration.inMilliseconds);
      double realValue = begin + (_displacement * value);
      onChange?.call(realValue);
    }
  }

  void finish() {
    if (_isFinished || _isFinishing) return;

    _isFinishing = true;
    _isFinished = true;
    onChange?.call(end);
    onFinish?.call();
    removeFromParent();
  }

  void start() {
    if (_isRunning) return;

    onStart?.call();
    _isRunning = true;
  }

  void pause() {
    _isRunning = false;
  }

  void reset() {
    _isRunning = false;
    _currentValue = 0;
  }

  bool get isFinished => _isFinished;
}
