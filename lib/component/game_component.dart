// ignore_for_file: implementation_imports

import 'dart:ui';

import 'package:meta/meta.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../effect/advanced_move_effect.dart';
import '../scene/scene.dart';
import '../extensions.dart';
import '../gestures/gesture_mixin.dart';

export 'package:flame/components.dart' show Anchor;
export 'package:flame/game.dart' show Camera;
export 'package:vector_math/vector_math_64.dart' show Vector2;
export 'dart:ui' show Canvas, Rect;
export 'package:flutter/widgets.dart' show EdgeInsets;

abstract class GameComponent extends PositionComponent
    with HasGameRef<Scene>, HasPaint
    implements SizeProvider, OpacityProvider {
  late Rect border;
  late RRect rborder;
  final double borderRadius;

  GameComponent({
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.priority,
    this.borderRadius = 5.0,
    double opacity = 1.0,
    super.children,
  }) {
    this.opacity = opacity;

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

  /// zoom the camera to make
  void fitScreen() {
    final gameViewPortSize = gameRef.size;
    // engine.info('游戏界面可视区域大小：${gameViewPortSize.x}x${gameViewPortSize.y}');
    final padRatio = width / height;
    final sizeRatio = gameViewPortSize.x / gameViewPortSize.y;
    if (sizeRatio > padRatio) {
      // 可视区域更宽
      final scaleFactor = gameViewPortSize.y / height;
      gameRef.camera.zoom = scaleFactor;
      final newWidth = width * scaleFactor;
      gameRef.camera.snapTo(Vector2(-(gameViewPortSize.x - newWidth) / 2, 0));
    } else {
      // 可视区域更窄
      final scaleFactor = gameViewPortSize.x / width;
      gameRef.camera.zoom = scaleFactor;
      final newHeight = height * scaleFactor;
      gameRef.camera
          .snapTo(Vector2(0, y = (gameViewPortSize.y - newHeight) / 2));
    }
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

    add(AdvancedMoveEffect(
      controller: EffectController(duration: duration, curve: curve),
      endPosition: position,
      endSize: size,
      endAngle: angle,
      onChange: onChange,
      onComplete: onComplete,
    ));
  }
}
