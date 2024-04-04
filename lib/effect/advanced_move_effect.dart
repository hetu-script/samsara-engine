import 'dart:math' as math;

import 'package:flame/effects.dart';

import '../components/game_component.dart';
import '../extensions.dart';

class AdvancedMoveEffect extends Effect with EffectTarget<GameComponent> {
  final Vector2? _endPosition, _endSize;
  final double? _endAngle;
  final bool _clockwise;

  Vector2? _diffPosition, _diffSize;
  double? _diffAngle;

  void Function()? onChange;

  AdvancedMoveEffect({
    Vector2? endPosition,
    Vector2? endSize,
    double? endAngle,
    bool clockwise = true,
    GameComponent? target,
    required EffectController controller,
    this.onChange,
    super.onComplete,
  })  : _endPosition = endPosition,
        _endSize = endSize,
        _endAngle = endAngle,
        _clockwise = clockwise,
        super(controller) {
    this.target = target;
  }

  @override
  void onStart() {
    if (_endPosition != null) {
      final diffX = (target.x - _endPosition!.x).abs() *
          (target.x > _endPosition!.x ? -1 : 1);
      final diffY = (target.y - _endPosition!.y).abs() *
          (target.y > _endPosition!.y ? -1 : 1);
      _diffPosition = Vector2(diffX, diffY);
    }

    if (_endSize != null) {
      final diffWidth = (target.width - _endSize!.x).abs() *
          (target.width > _endSize!.x ? -1 : 1);
      final diffHeight = (target.height - _endSize!.y).abs() *
          (target.height > _endSize!.y ? -1 : 1);
      _diffSize = Vector2(diffWidth, diffHeight);
    }

    if (_endAngle != null) {
      _diffAngle =
          (target.angle - (_endAngle != 0 ? _endAngle! : 2 * math.pi)).abs() *
              (_clockwise ? 1 : -1);
    }

    assert(_diffPosition != null || _diffSize != null || _endAngle != null);
  }

  @override
  void apply(double progress) {
    final dProgress = progress - previousProgress;
    if (_diffPosition != null) {
      target.position += _diffPosition! * dProgress;
    }

    if (_diffSize != null && !_diffSize!.isZero()) {
      target.size += _diffSize! * dProgress;
    }

    if (_diffAngle != null) {
      target.angle += _diffAngle! * dProgress;
    }

    onChange?.call();
  }

  @override
  void onFinish() {
    if (_endPosition != null) {
      target.position = _endPosition!;
    }
    if (_endSize != null) {
      target.size = _endSize!;
    }
    if (_endAngle != null) {
      target.angle = _endAngle!;
    }

    super.onFinish();
  }
}
