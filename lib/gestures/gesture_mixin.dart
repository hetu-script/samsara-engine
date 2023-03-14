import 'dart:async' show Timer;

import 'package:meta/meta.dart';
import 'package:flutter/gestures.dart';
import 'package:flame/components.dart' show PositionType;

import '../extensions.dart';
import '../../widget/pointer_detector.dart' show TouchDetails;
import '../component/game_component.dart';

export 'package:flutter/gestures.dart'
    show
        TapDownDetails,
        TapUpDetails,
        DragStartDetails,
        DragUpdateDetails,
        ScaleStartDetails,
        ScaleUpdateDetails,
        LongPressStartDetails;
export '../../widget/pointer_detector.dart'
    show TouchDetails, PointerMoveUpdateDetails;

mixin HandlesGesture on GameComponent {
  bool enableGesture = true;

  Map<int, Vector2> tapPositions = {};
  bool get isPressing => tapPositions.isNotEmpty;
  bool isDragging = false, isScalling = false, isHovering = false;

  /// A specific duration to detect double tap
  int doubleTapTimeConsider = 400;
  Timer? doubleTapTimer;

  void Function(int buttons, Vector2 position)? onTap;
  void Function(int buttons, Vector2 position)? onTapDown;
  void Function(int buttons, Vector2 position)? onTapUp;
  void Function(int buttons, Vector2 position)? onDoubleTap;
  void Function()? onTapCancel;

  /// 返回拖动的对象，如果返回null，则会使用该对象本身
  HandlesGesture? Function(int buttons, Vector2 dragPosition)? onDragStart;
  void Function(int buttons, Vector2 dragPosition, Vector2 worldPosition)?
      onDragUpdate;
  void Function(int buttons, Vector2 dragPosition, Vector2 worldPosition)?
      onDragEnd;
  void Function(int buttons, Vector2 position, GameComponent component)?
      onDragIn;
  void Function(List<TouchDetails> touches, ScaleStartDetails details)?
      onScaleStart;
  void Function(List<TouchDetails> touches, ScaleUpdateDetails details)?
      onScaleUpdate;
  void Function()? onScaleEnd;
  void Function(Vector2 position)? onLongPress;
  void Function()? onMouseEnter;
  void Function(Vector2 position)? onMouseHover;
  void Function()? onMouseExit;

  @mustCallSuper
  bool handleTapDown(int pointer, int buttons, TapDownDetails details) {
    for (final c in gestureComponents) {
      if (c.handleTapDown(pointer, buttons, details) &&
          !tapPositions.containsKey(pointer)) {
        return true;
      }
    }

    if (!enableGesture) return false;

    final pointerPosition = details.globalPosition.toVector2();
    final convertedPointerPosition = positionType != PositionType.game
        ? pointerPosition
        : gameRef.camera.screenToWorld(pointerPosition);
    final positionWithinComponent = convertedPointerPosition - position;
    if (containsPoint(convertedPointerPosition)) {
      tapPositions[pointer] = positionWithinComponent;
      onTapDown?.call(buttons, positionWithinComponent);
      return true;
    }

    return false;
  }

  @mustCallSuper
  void handleTapUp(int pointer, int buttons, TapUpDetails details) {
    for (final c in gestureComponents) {
      c.handleTapUp(pointer, buttons, details);
    }

    if (!enableGesture) return;

    final pointerPosition = details.globalPosition.toVector2();
    final convertedPointerPosition = positionType != PositionType.game
        ? pointerPosition
        : gameRef.camera.screenToWorld(pointerPosition);
    final positionWithinComponent = convertedPointerPosition - position;
    if (containsPoint(convertedPointerPosition)) {
      if (doubleTapTimer?.isActive ?? false) {
        doubleTapTimer?.cancel();
        if (tapPositions.containsKey(pointer)) {
          onTap?.call(buttons, positionWithinComponent);
          onDoubleTap?.call(buttons, positionWithinComponent);
        } else {
          doubleTapTimer =
              Timer(Duration(milliseconds: doubleTapTimeConsider), () {
            doubleTapTimer?.cancel();
          });
        }
      } else {
        onTap?.call(buttons, positionWithinComponent);
        doubleTapTimer =
            Timer(Duration(milliseconds: doubleTapTimeConsider), () {
          doubleTapTimer?.cancel();
        });
      }
      onTapUp?.call(buttons, positionWithinComponent);
    } else {
      onTapCancel?.call();
    }

    tapPositions.remove(pointer);
  }

  @mustCallSuper
  HandlesGesture? handleDragStart(
      int pointer, int buttons, DragStartDetails details) {
    for (final c in gestureComponents) {
      final r = c.handleDragStart(pointer, buttons, details);
      if (r != null) {
        return r;
      }
    }

    if (!enableGesture) return null;

    final pointerPosition = details.globalPosition.toVector2();
    final convertedPointerPosition = positionType != PositionType.game
        ? pointerPosition
        : gameRef.camera.screenToWorld(pointerPosition);
    if (containsPoint(convertedPointerPosition)) {
      isDragging = true;
      assert(tapPositions.containsKey(pointer));
      final dragPosition = tapPositions[pointer]!;
      final r = onDragStart?.call(buttons, dragPosition);
      if (r != null) {
        return r;
      } else {
        return this;
      }
    }

    return null;
  }

  @mustCallSuper
  void handleDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
    for (final c in gestureComponents) {
      c.handleDragUpdate(pointer, buttons, details);
    }

    if (!enableGesture || !isDragging || !tapPositions.containsKey(pointer)) {
      return;
    }

    final pointerPosition = details.globalPosition.toVector2();
    final convertedPointerPosition = positionType != PositionType.game
        ? pointerPosition
        : gameRef.camera.screenToWorld(pointerPosition);
    final dragPosition = tapPositions[pointer]!;
    onDragUpdate?.call(buttons, dragPosition, convertedPointerPosition);
  }

  @mustCallSuper
  void handleDragEnd(int pointer, int buttons, TapUpDetails details,
      GameComponent? draggingComponent) {
    for (final c in gestureComponents) {
      c.handleDragEnd(pointer, buttons, details, draggingComponent);
    }

    if (!enableGesture) return;

    final pointerPosition = details.globalPosition.toVector2();
    final convertedPointerPosition = positionType != PositionType.game
        ? pointerPosition
        : gameRef.camera.screenToWorld(pointerPosition);
    if (isDragging && (tapPositions.containsKey(pointer))) {
      isDragging = false;
      assert(tapPositions.containsKey(pointer));
      final dragPosition = tapPositions[pointer]!;
      onDragEnd?.call(buttons, dragPosition, convertedPointerPosition);
      tapPositions.remove(pointer);
    }

    if (containsPoint(convertedPointerPosition) &&
        draggingComponent != null &&
        draggingComponent != this) {
      final positionWithinComponent = convertedPointerPosition - position;
      onDragIn?.call(buttons, positionWithinComponent, draggingComponent);
    }
  }

  @mustCallSuper
  void handleScaleStart(List<TouchDetails> touches, ScaleStartDetails details) {
    assert(touches.length == 2);

    for (final c in gestureComponents) {
      c.handleScaleStart(touches, details);
    }

    if (!enableGesture) return;

    final pointerPosition1 = touches[0].currentGlobalPosition.toVector2();
    final convertedPointerPosition1 = positionType != PositionType.game
        ? pointerPosition1
        : gameRef.camera.screenToWorld(pointerPosition1);
    final pointerPosition2 = touches[1].currentGlobalPosition.toVector2();
    final convertedPointerPosition2 = positionType != PositionType.game
        ? pointerPosition2
        : gameRef.camera.screenToWorld(pointerPosition2);
    if (containsPoint(convertedPointerPosition1) &&
        containsPoint(convertedPointerPosition2)) {
      isScalling = true;
      onScaleStart?.call(touches, details);
    } else {
      handleScaleEnd();
    }
  }

  @mustCallSuper
  void handleScaleUpdate(
      List<TouchDetails> touches, ScaleUpdateDetails details) {
    assert(touches.length == 2);

    for (final c in gestureComponents) {
      c.handleScaleUpdate(touches, details);
    }

    if (!enableGesture || !isScalling) return;

    final pointerPosition1 = touches[0].currentGlobalPosition.toVector2();
    final convertedPointerPosition1 = positionType != PositionType.game
        ? pointerPosition1
        : gameRef.camera.screenToWorld(pointerPosition1);
    final pointerPosition2 = touches[1].currentGlobalPosition.toVector2();
    final convertedPointerPosition2 = positionType != PositionType.game
        ? pointerPosition2
        : gameRef.camera.screenToWorld(pointerPosition2);
    if (containsPoint(convertedPointerPosition1) &&
        containsPoint(convertedPointerPosition2)) {
      onScaleUpdate?.call(touches, details);
    } else {
      handleScaleEnd();
    }
  }

  @mustCallSuper
  void handleScaleEnd() {
    for (final c in gestureComponents) {
      c.handleScaleEnd();
    }

    if (!enableGesture) return;

    if (isScalling) {
      onScaleEnd?.call();
      isScalling = false;
    }
    tapPositions.clear();
  }

  @mustCallSuper
  bool handleLongPress(
      int pointer, int buttons, LongPressStartDetails details) {
    for (final c in gestureComponents) {
      if (c.handleLongPress(pointer, buttons, details) &&
          !tapPositions.containsKey(pointer)) {
        return true;
      }
    }

    if (!enableGesture) return false;

    final pointerPosition = details.globalPosition.toVector2();
    final convertedPointerPosition = positionType != PositionType.game
        ? pointerPosition
        : gameRef.camera.screenToWorld(pointerPosition);
    final positionWithinComponent = convertedPointerPosition - position;
    if (containsPoint(convertedPointerPosition)) {
      onLongPress?.call(positionWithinComponent);
      return true;
    }

    return false;
  }

  @mustCallSuper
  bool handleMouseHover(PointerHoverEvent details) {
    for (final c in gestureComponents) {
      if (c.handleMouseHover(details)) {
        return true;
      }
    }

    if (!enableGesture) return false;

    final pointerPosition = details.position.toVector2();
    final convertedPointerPosition = positionType != PositionType.game
        ? pointerPosition
        : gameRef.camera.screenToWorld(pointerPosition);
    final positionWithinComponent = convertedPointerPosition - position;
    if (containsPoint(convertedPointerPosition)) {
      if (!isHovering) {
        isHovering = true;
        onMouseEnter?.call();
      }
      onMouseHover?.call(positionWithinComponent);
      return true;
    } else {
      if (isHovering) {
        onMouseExit?.call();
        isHovering = false;
      }
      return false;
    }
  }
}
