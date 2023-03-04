import 'package:flame/components.dart';

class Timer extends Component {
  final double duration;
  bool loop, autoDispose;
  bool _started = false;

  double _timer;
  double get timer => _timer;
  double get leftoverTime => _timer - duration;
  bool get completed => _timer == duration;

  void Function()? onStart, onComplete;
  void Function(double progress)? onChange;

  Timer(
    this.duration, {
    this.loop = false,
    bool autoStart = true,
    this.autoDispose = true,
    this.onStart,
    this.onChange,
    this.onComplete,
  })  : assert(duration >= 0, 'Duration cannot be negative: $duration'),
        _timer = 0 {
    if (autoStart) {
      start();
    }
  }

  @override
  void update(double dt) {
    if (!_started) return;

    _timer += dt;
    onChange?.call(_timer);
    if (_timer > duration) {
      if (loop) {
        _timer = 0;
      } else {
        end();
      }
    }
  }

  void start() {
    _timer = 0;
    _started = true;
    onStart?.call();
  }

  void end() {
    _timer = duration;
    _started = false;
    onComplete?.call();
    if (autoDispose) {
      removeFromParent();
    }
  }
}
