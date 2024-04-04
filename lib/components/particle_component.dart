import 'package:flame/particles.dart';

import 'game_component.dart';

/// A modified version of Flame's [ParticleSystemComponent]
/// A [GameComponent] that renders a [Particle] at the designated
/// position, scaled to have the designated size and rotated to the specified
/// angle.
class ParticleComponent extends GameComponent {
  Particle particle;

  double? _originalLightingRadius;

  double elapsedTime = 0.0;

  /// {@macro particle_system_component}
  ParticleComponent(
    this.particle, {
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.priority,
    super.opacity,
    super.lightConfig,
  }) {
    _originalLightingRadius = lightConfig?.radius;
  }

  /// Passes rendering chain down to the inset
  /// [Particle] within this [Component].
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    particle.render(canvas);
  }

  /// Passes update chain to child [Particle].
  @override
  void update(double dt) {
    elapsedTime += dt;

    particle.update(dt);
    if (particle.shouldRemove) {
      removeFromParent();
    }

    if (_originalLightingRadius != null) {
      if (lightConfig!.lightUpDuration > 0) {
        if (elapsedTime < lightConfig!.lightUpDuration) {
          lightConfig!.radius = (elapsedTime / lightConfig!.lightUpDuration) *
              _originalLightingRadius!;
        } else if (lightConfig!.radius != _originalLightingRadius) {
          lightConfig!.radius = _originalLightingRadius!;
        }
      }
    }
  }
}
