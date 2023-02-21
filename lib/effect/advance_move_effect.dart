import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:samsara/component/game_component.dart';

class AdvanceMoveEffect extends Effect {
  final Vector2? startPosition, endPosition, startSize, endSize;
  final double? startAngle, endAngle;
  final GameComponent target;

  Vector2? _diffPosition, _diffSize;
  double? _diffAngle;

  Function? onChange;

  AdvanceMoveEffect({
    this.startPosition,
    this.endPosition,
    this.startSize,
    this.endSize,
    this.startAngle,
    this.endAngle,
    required this.target,
    required EffectController controller,
    this.onChange,
    super.onComplete,
  }) : super(controller) {
    if (startPosition != null && endPosition != null) {
      final diffX = (startPosition!.x - endPosition!.x).abs() *
          (startPosition!.x > endPosition!.x ? -1 : 1);
      final diffY = (startPosition!.y - endPosition!.y).abs() *
          (startPosition!.y > endPosition!.y ? -1 : 1);
      _diffPosition = Vector2(diffX, diffY);
    }

    if (startSize != null && endSize != null) {
      final diffWidth = (startSize!.x - endSize!.x).abs() *
          (startSize!.x > endSize!.x ? -1 : 1);
      final diffHeight = (startSize!.y - endSize!.y).abs() *
          (startSize!.y > endSize!.y ? -1 : 1);
      _diffSize = Vector2(diffWidth, diffHeight);
    }

    if (startAngle != null && endAngle != null) {
      _diffAngle =
          (startAngle! - endAngle!).abs() * (startAngle! > endAngle! ? -1 : 1);
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
}
