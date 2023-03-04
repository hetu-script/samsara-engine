import 'package:flame/effects.dart';

import '../component/game_component.dart';

export 'package:flutter/animation.dart' show Curve, Curves;

class AdvancedMoveEffect extends Effect with EffectTarget<GameComponent> {
  final Vector2? endPosition, endSize;
  final double? endAngle;

  Vector2? _diffPosition, _diffSize;
  double? _diffAngle;

  Function? onChange;

  AdvancedMoveEffect({
    this.endPosition,
    this.endSize,
    this.endAngle,
    GameComponent? target,
    required EffectController controller,
    this.onChange,
    super.onComplete,
  }) : super(controller) {
    this.target = target;
  }

  @override
  void onStart() {
    if (endPosition != null) {
      final diffX = (target.x - endPosition!.x).abs() *
          (target.x > endPosition!.x ? -1 : 1);
      final diffY = (target.y - endPosition!.y).abs() *
          (target.y > endPosition!.y ? -1 : 1);
      _diffPosition = Vector2(diffX, diffY);
    }

    if (endSize != null) {
      final diffWidth = (target.width - endSize!.x).abs() *
          (target.width > endSize!.x ? -1 : 1);
      final diffHeight = (target.height - endSize!.y).abs() *
          (target.height > endSize!.y ? -1 : 1);
      _diffSize = Vector2(diffWidth, diffHeight);
    }

    if (endAngle != null) {
      _diffAngle = (target.angle - endAngle!).abs() *
          (target.angle > endAngle! ? -1 : 1);
    }

    assert(_diffPosition != null || _diffSize != null || _diffAngle != null);
  }

  @override
  void apply(double progress) {
    final dProgress = progress - previousProgress;
    if (_diffPosition != null) {
      target.position += _diffPosition! * dProgress;
    }

    if (_diffSize != null) {
      target.size += _diffSize! * dProgress;
    }

    if (_diffAngle != null) {
      target.angle += _diffAngle! * dProgress;
    }

    onChange?.call();
  }

  @override
  void onFinish() {
    if (endPosition != null) {
      target.position = endPosition!;
    }
    if (endSize != null) {
      target.size = endSize!;
    }
    if (endAngle != null) {
      target.angle = endAngle!;
    }

    super.onFinish();
  }
}
