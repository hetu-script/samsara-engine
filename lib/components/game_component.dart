import 'dart:async';

import 'package:flutter/material.dart' hide Tooltip, Viewport;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
// import 'package:flame/experimental.dart';
import 'package:flame/camera.dart';

import '../effect/fade_effect.dart';
import '../effect/advanced_move_effect.dart';
import '../scene/scene.dart';
import '../gestures/gesture_mixin.dart';
import '../lighting/light_config.dart';

export '../types.dart';

abstract class GameComponent extends PositionComponent
    with HasGameRef<Scene>, HasPaint
    implements SizeProvider, OpacityProvider {
  bool _isHud = false;
  bool get isHud => _isHud;

  Vector2? _toPosition;
  Vector2? _toSize;
  double? _toAngle;

  bool _isVisible = true;
  bool _isMoving = false;
  bool get isMoving => _isMoving;

  @mustCallSuper
  set isVisible(bool value) => _isVisible = value;

  LightConfig? lightConfig;

  bool get isVisible {
    if (!_isVisible) return false;
    if (!isHud && !size.isZero()) {
      return gameRef.camera.canSee(this);
    }
    return true;
  }

  GameComponent({
    super.key,
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.priority,
    super.nativeAngle,
    double opacity = 1.0,
    super.children,
    this.lightConfig,
    Paint? paint,
    bool isVisible = true,
  }) : _isVisible = isVisible {
    this.opacity = opacity;
    this.paint = paint ?? Paint()
      ..filterQuality = FilterQuality.high;

    setPaint('default', this.paint);
  }

  @override
  void onMount() {
    var p = parent;
    while (p != null) {
      if (p is Viewport || p is Viewfinder) {
        _isHud = true;
        break;
      }
      p = p.parent;
    }
  }

  Iterable<HandlesGesture> get gestureComponents =>
      children.reversed().whereType<HandlesGesture>().cast<HandlesGesture>();

  Future<void> fadeIn({
    required double duration,
    void Function()? onComplete,
  }) async {
    final completer = Completer();
    add(FadeEffect(
      fadeIn: true,
      controller: EffectController(duration: duration),
      onComplete: () {
        onComplete?.call();
        completer.complete();
      },
    ));
    return completer.future;
  }

  Future<void> fadeOut({
    required double duration,
    void Function()? onComplete,
  }) async {
    final completer = Completer();
    add(FadeEffect(
      controller: EffectController(duration: duration),
      onComplete: () {
        onComplete?.call();
        completer.complete();
      },
    ));
    return completer.future;
  }

  void snapTo({
    Vector2? toPosition,
    Vector2? toSize,
    double? toDegree,
  }) {
    double? toAngle;
    if (toDegree != null) {
      toAngle = radians(toDegree);
    }

    if ((toPosition == null || position == toPosition) &&
        (toSize == null || size == toSize) &&
        (toDegree == null || angle == toAngle)) {
      return;
    }

    if (toPosition != null) {
      position = toPosition;
    }
    if (toSize != null) {
      size = toSize;
    }
    if (toAngle != null) {
      angle = toAngle;
    }
  }

  Future<void> moveTo({
    Vector2? toPosition,
    Vector2? toSize,
    double? toAngle,
    bool clockwise = true,
    required double duration,
    Curve curve = Curves.linear,
    void Function()? onChange,
    void Function()? onComplete,
  }) async {
    if (toPosition == null && toSize == null && toAngle == null) {
      return;
    }

    if (position == toPosition &&
        size == toSize &&
        (toAngle == null || (angle == toAngle))) {
      return;
    }

    if (_toPosition == toPosition && _toSize == toSize && _toAngle == toAngle) {
      return;
    }

    final completer = Completer();
    _isMoving = true;
    add(AdvancedMoveEffect(
      controller: EffectController(duration: duration, curve: curve),
      endPosition: toPosition,
      endSize: toSize,
      endAngle: toAngle,
      clockwise: clockwise,
      onChange: onChange,
      onComplete: () {
        _toPosition = null;
        _toSize = null;
        _toAngle = null;
        _isMoving = false;
        onComplete?.call();
        completer.complete();
      },
    ));
    _toPosition = toPosition;
    _toSize = toSize;
    _toAngle = toAngle;
    return completer.future;
  }
}
