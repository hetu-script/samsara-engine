import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:samsara/extensions.dart';
import 'package:hetu_script/utils/math.dart';

class CameraShakeEffect extends Effect {
  late final CameraComponent camera;
  final Random random = Random();
  // 震动造成的屏幕位移
  final int shift;
  final int intensity;
  final int frequency;
  late double _interval;
  int _shakedCount = 0;
  bool _isShaking = false;

  /// Creates a new CameraShakeEffect.
  /// [intensity] is the speed of the camera movement.
  /// [shift] is the amount of pixels the camera will move in each direction.
  /// [frequency] is the maximum number of times the camera will shake during the duration.
  CameraShakeEffect({
    this.intensity = 100,
    this.shift = 10,
    // 持续时间内触发震动的次数
    this.frequency = 1,
    required EffectController controller,
    super.onComplete,
  }) : super(controller);

  @override
  void onStart() {
    final game = findGame();
    assert(game != null);

    camera = game!.camera;

    _interval = (controller.duration ?? 1) / frequency;
  }

  @override
  void apply(double progress) {
    final currentTarget = _shakedCount * _interval;

    if (_shakedCount < frequency && !_isShaking) {
      final shouldShake = random.nextBoolBiased(progress, currentTarget);
      if (shouldShake) {
        _isShaking = true;
        _shakedCount++;
        final initialPosition = camera.position.clone();
        camera.position +=
            Vector2(random.nextDouble() * shift, random.nextDouble() * shift);
        camera.moveTo2(initialPosition, speed: 100, onComplete: () {
          _isShaking = false;
        });
      }
    }
  }
}
