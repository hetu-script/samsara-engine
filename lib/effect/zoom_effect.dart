import 'package:flame/effects.dart';
import 'package:flame/game.dart';

class ZoomEffect extends Effect with EffectTarget<FlameGame> {
  final double zoom;

  late final double _start;
  late final double _diff;

  ZoomEffect(
    FlameGame game,
    EffectController controller, {
    required this.zoom,
    super.onComplete,
  }) : super(controller) {
    target = game;
    _start = game.camera.viewfinder.zoom;
    _diff = zoom - _start;
    assert(_diff != 0);
  }

  @override
  void apply(double progress) {
    target.camera.viewfinder.zoom = _start + (progress * _diff);
  }

  @override
  void onFinish() {
    super.onFinish();
    target.camera.viewfinder.zoom = zoom;
  }
}
