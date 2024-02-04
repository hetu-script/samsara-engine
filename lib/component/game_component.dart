import 'dart:async';

import 'dart:ui';

import 'package:meta/meta.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../effect/advanced_move_effect.dart';
import '../scene/scene.dart';
import '../extensions.dart';
import '../gestures/gesture_mixin.dart';
import 'package:flutter/animation.dart' show Curve, Curves;

export 'package:flame/components.dart' show Anchor, CameraComponent;
export 'package:vector_math/vector_math_64.dart' show Vector2;
export '../extensions.dart' show Vector2Ex;
export 'package:flame/extensions.dart' show Vector2Extension;
export 'dart:ui' show Canvas, Rect;
export 'package:flutter/widgets.dart' show EdgeInsets;
export 'package:flutter/material.dart' show Colors;
export 'package:flutter/animation.dart' show Curve, Curves;

abstract class GameComponent extends PositionComponent
    with HasGameRef<Scene>, HasPaint
    implements SizeProvider, OpacityProvider {
  final String? id;

  late Rect border;
  late RRect rborder;
  double _borderRadius;

  final bool isHud;

  double get borderRadius => _borderRadius;

  GameComponent({
    this.id,
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.priority,
    double borderRadius = 5.0,
    double opacity = 1.0,
    super.children,
    bool? isHud,
  })  : _borderRadius = borderRadius,
        isHud = isHud ?? false {
    this.opacity = opacity;

    generateBorder();
  }

  @mustCallSuper
  void generateBorder() {
    border = Rect.fromLTWH(0, 0, width, height);
    rborder =
        RRect.fromLTRBR(0, 0, width, height, Radius.circular(_borderRadius));
  }

  set borderRadius(double value) {
    _borderRadius = value;
    rborder =
        RRect.fromLTRBR(0, 0, width, height, Radius.circular(_borderRadius));
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

  // bool isVisibleInCamera() {
  //   return gameRef.camera.isComponentOnCamera(this);
  // }

  @mustCallSuper
  @override
  void renderTree(Canvas canvas) {
    if (!isVisible) return;
    super.renderTree(canvas);
  }

  Iterable<HandlesGesture> get gestureComponents =>
      children.reversed().whereType<HandlesGesture>().cast<HandlesGesture>();

  void snapTo({
    Vector2? position,
    Vector2? size,
    double? angle,
  }) {
    if ((position == null || this.position == position) &&
        (size == null || this.size == size) &&
        (angle == null || this.angle == angle)) {
      return;
    }

    if (position != null) {
      this.position = position;
    }
    if (size != null) {
      this.size = size;
    }
    if (angle != null) {
      this.angle = angle;
    }
  }

  Future<void> moveTo({
    Vector2? position,
    Vector2? size,
    double? angle,
    required double duration,
    Curve curve = Curves.linear,
    Function? onChange,
    void Function()? onComplete,
  }) async {
    if (position == null && size == null && angle == null) return;

    bool diffPos = position != null && this.position != position;
    bool diffSize = size != null && this.size != position;
    bool diffAngle = angle != null && this.angle != angle;

    /// nothing need to be done withi this component.
    if (!(diffPos || diffSize || diffAngle)) return;

    final completer = Completer();
    add(AdvancedMoveEffect(
      controller: EffectController(duration: duration, curve: curve),
      endPosition: position,
      endSize: size,
      endAngle: angle,
      onChange: onChange,
      onComplete: () {
        onComplete?.call();
        completer.complete();
      },
    ));
    return completer.future;
  }
}
