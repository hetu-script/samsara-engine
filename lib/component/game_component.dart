// ignore_for_file: implementation_imports

import 'dart:ui';

import 'package:meta/meta.dart';
import 'package:flame/components.dart';
import 'package:flame/src/effects/provider_interfaces.dart';
import 'package:flame/effects.dart';
import 'package:flame/palette.dart';

import '../effect/advanced_move_effect.dart';
import '../scene/scene.dart';
import '../extensions.dart';
import '../gestures/gesture_mixin.dart';

export 'package:flame/components.dart' show Anchor;
export 'package:flame/game.dart' show Camera;

abstract class GameComponent extends PositionComponent
    with HasGameRef<Scene>
    implements SizeProvider, OpacityProvider, PaintProvider {
  @override
  Paint paint = BasicPalette.white.paint();

  late Rect border;
  late RRect rborder;
  final double borderRadius;

  @override
  double opacity;

  GameComponent({
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.priority,
    this.borderRadius = 5.0,
    this.opacity = 1.0,
  }) {
    generateBorder();
  }

  @mustCallSuper
  void generateBorder() {
    border = Rect.fromLTWH(0, 0, width, height);
    rborder =
        RRect.fromLTRBR(0, 0, width, height, Radius.circular(borderRadius));
  }

  @override
  set x(double value) {
    super.x = value;
    generateBorder();
  }

  @override
  set y(double value) {
    super.y = value;
    generateBorder();
  }

  @override
  set position(Vector2 value) {
    super.position = value;
    generateBorder();
  }

  @override
  set width(double value) {
    super.width = value;
    generateBorder();
  }

  @override
  set height(double value) {
    super.height = value;
    generateBorder();
  }

  @override
  set size(Vector2 value) {
    super.size = value;
    generateBorder();
  }

  bool _isVisible = true;

  @mustCallSuper
  set isVisible(bool value) => _isVisible = value;

  bool get isVisible {
    if (isRemoving == true || _isVisible == false) {
      return false;
    }
    return true;
  }

  bool isVisibleInCamera() {
    return gameRef.camera.isComponentOnCamera(this);
  }

  Iterable<HandlesGesture> get gestureComponents =>
      children.whereType<HandlesGesture>().cast<HandlesGesture>();

  void snapTo({Vector2? position, Vector2? size}) {
    if ((position == null || this.position == position) &&
        (size == null || this.size == size)) {
      return;
    }

    if (position != null) {
      super.position = position;
    }
    if (size != null) {
      super.size = size;
    }

    if (position != null || size != null) {
      generateBorder();
    }
  }

  void moveTo({
    Vector2? position,
    Vector2? size,
    double? angle,
    required double duration,
    curve = Curves.linear,
    Function? onChange,
    void Function()? onComplete,
  }) {
    if ((position == null || this.position == position) &&
        (size == null || this.size == size)) {
      return;
    }

    final movingAnimation = AdvancedMoveEffect(
      target: this,
      controller: EffectController(duration: duration, curve: curve),
      endPosition: position,
      endSize: size,
      endAngle: angle,
      onChange: onChange,
      onComplete: onComplete,
    );
    add(movingAnimation);
  }
}
