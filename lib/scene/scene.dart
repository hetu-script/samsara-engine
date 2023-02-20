import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:samsara/samsara.dart';

import '../ui/pointer_detector.dart';
import '../gestures/gesture_mixin.dart';

abstract class Scene extends FlameGame {
  static const overlayUIBuilderMapKey = 'overlayUI';

  final String id, key;
  final SceneController controller;

  Scene({
    required this.id,
    required this.key,
    required this.controller,
  });

  void end() {
    controller.leaveScene(id);
  }

  Vector2 get screenCenter => size / 2;

  Iterable<HandlesGesture> get gestureComponents =>
      children.whereType<HandlesGesture>().cast<HandlesGesture>();

  void onTapDown(int pointer, int buttons, TapDownDetails details) {
    for (final c in gestureComponents) {
      c.handleTapDown(pointer, buttons, details);
    }
  }

  void onTapUp(int pointer, int buttons, TapUpDetails details) {
    for (final c in gestureComponents) {
      c.handleTapUp(pointer, buttons, details);
    }
  }

  void onDragStart(int pointer, int buttons, DragStartDetails details) {
    for (final c in gestureComponents) {
      c.handleDragStart(pointer, buttons, details);
    }
  }

  void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
    for (final c in gestureComponents) {
      c.handleDragUpdate(pointer, buttons, details);
    }
  }

  void onDragEnd(int pointer, int buttons) {
    for (final c in gestureComponents) {
      c.handleDragEnd(pointer, buttons);
    }
  }

  void onScaleStart(List<TouchDetails> touches, ScaleStartDetails details) {
    for (final c in gestureComponents) {
      c.handleScaleStart(touches, details);
    }
  }

  void onScaleUpdate(List<TouchDetails> touches, ScaleUpdateDetails details) {
    for (final c in gestureComponents) {
      c.handleScaleUpdate(touches, details);
    }
  }

  void onScaleEnd() {
    for (final c in gestureComponents) {
      c.handleScaleEnd();
    }
  }

  void onLongPress(int pointer, int buttons, LongPressStartDetails details) {
    for (final c in gestureComponents) {
      c.handleLongPress(pointer, buttons, details);
    }
  }

  void onMouseHover(PointerHoverEvent details) {
    for (final c in gestureComponents) {
      c.handleMouseHover(details);
    }
  }

  Widget get widget {
    return PointerDetector(
      child: GameWidget(
        game: this,
      ),
      onTapDown: onTapDown,
      onTapUp: onTapUp,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      onScaleStart: onScaleStart,
      onScaleUpdate: onScaleUpdate,
      onScaleEnd: onScaleEnd,
      onLongPress: onLongPress,
      onMouseHover: onMouseHover,
    );
  }
}
