import 'dart:async';

import 'package:flutter/material.dart' hide Tooltip;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:samsara/effect/fade_effect.dart';
// import 'package:flame/experimental.dart';

import '../effect/advanced_move_effect.dart';
import '../scene/scene.dart';
import '../extensions.dart';
import '../gestures/gesture_mixin.dart';

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
  late Paint borderPaint;

  final bool isHud;

  late Rect _border;
  Rect get border => _border;
  final double borderWidth;
  late RRect _rBorder;
  RRect get rrect => _rBorder;
  final double borderRadius;
  late RRect _clipRRect;
  RRect get clipRRect => _clipRRect;

  Vector2? moving2Position;
  Vector2? moving2Size;
  double? moving2Angle;

  bool _isVisible = true;

  @mustCallSuper
  set isVisible(bool value) => _isVisible = value;

  bool get isVisible {
    if (isRemoving == true || _isVisible == false) {
      return false;
    }
    return true;
  }

  GameComponent({
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.priority,
    this.borderWidth = 1.0,
    this.borderRadius = 0.0,
    double opacity = 1.0,
    super.children,
    bool? isHud,
    bool flipH = false,
    bool flipV = false,
    Paint? paint,
    Paint? borderPaint,
  }) : isHud = isHud ?? false {
    this.opacity = opacity;
    this.paint = paint ?? Paint()
      ..filterQuality = FilterQuality.medium
      ..color = Colors.white.withOpacity(opacity);
    this.borderPaint = borderPaint ?? Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    generateBorder();
    size.addListener(generateBorder);

    if (flipH) flipHorizontally();
    if (flipV) flipVertically();
  }

  @mustCallSuper
  void generateBorder() {
    _border = Rect.fromLTWH(0, 0, width, height);
    _rBorder =
        RRect.fromLTRBR(0, 0, width, height, Radius.circular(borderRadius));

    _clipRRect = RRect.fromLTRBR(
        0 - borderWidth,
        0 - borderWidth,
        width + borderWidth * 2,
        height + borderWidth * 2,
        Radius.circular(borderRadius));
  }

  // bool isVisibleInCamera() {
  //   return gameRef.camera.isComponentOnCamera(this);
  // }

  @mustCallSuper
  @override
  void renderTree(Canvas canvas) {
    super.renderTree(canvas);
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
    double? toAngle,
  }) {
    if ((toPosition == null || position == toPosition) &&
        (toSize == null || size == toSize) &&
        (toAngle == null || angle == toAngle)) {
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
    required double duration,
    Curve curve = Curves.linear,
    void Function()? onChange,
    void Function()? onComplete,
  }) async {
    if (toPosition == null && toSize == null && toAngle == null) return;
    if (position == toPosition && size == toSize && angle == toAngle) return;
    if (moving2Position == toPosition &&
        moving2Size == toSize &&
        moving2Angle == toAngle) return;

    bool diffPos = toPosition != null && position != toPosition;
    bool diffSize = toSize != null && size != toPosition;
    bool diffAngle = toAngle != null && angle != toAngle;

    /// nothing need to be done withi this component.
    if (!(diffPos || diffSize || diffAngle)) return;

    final completer = Completer();
    add(AdvancedMoveEffect(
      controller: EffectController(duration: duration, curve: curve),
      endPosition: toPosition,
      endSize: toSize,
      endAngle: toAngle,
      onChange: onChange,
      onComplete: () {
        onComplete?.call();
        completer.complete();
        moving2Position = null;
        moving2Size = null;
        moving2Angle = null;
      },
    ));
    moving2Position = toPosition;
    moving2Size = toSize;
    moving2Angle = toAngle;
    return completer.future;
  }
}
