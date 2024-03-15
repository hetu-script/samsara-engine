import 'dart:async' show Timer;

import 'package:meta/meta.dart';
import 'package:flutter/gestures.dart';

import '../extensions.dart';
import '../../widget/pointer_detector.dart'
    show TouchDetails, MouseScrollDetails;
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

class TapPosition {
  int pointer;
  int buttons;
  Vector2 positionWithinComponent;

  TapPosition(
    this.pointer,
    this.buttons,
    this.positionWithinComponent,
  );
}

mixin HandlesGesture on GameComponent {
  bool enableGesture = true;

  Map<int, TapPosition> tapPositions = {};
  bool get isPressing => tapPositions.isNotEmpty;
  bool isDragging = false, isScalling = false, isHovering = false;
  // Vector2? lastDragPosition;

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
  void Function(int buttons, Vector2 dragPosition, Vector2 dragOffset)?
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
  void Function()? onMouseScrollUp, onMouseScrollDown;

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
    final convertedPointerPosition =
        isHud ? pointerPosition : gameRef.camera.globalToLocal(pointerPosition);
    final positionWithinComponent = convertedPointerPosition - position;
    if (containsPoint(convertedPointerPosition)) {
      tapPositions[pointer] =
          TapPosition(pointer, buttons, positionWithinComponent);
      onTapDown?.call(buttons, positionWithinComponent);
      return true;
    }

    return false;
  }

  @mustCallSuper
  bool handleTapUp(int pointer, int buttons, TapUpDetails details) {
    for (final c in gestureComponents) {
      c.handleTapUp(pointer, buttons, details);
    }

    if (!enableGesture) return false;

    final pointerPosition = details.globalPosition.toVector2();
    final convertedPointerPosition =
        isHud ? pointerPosition : gameRef.camera.globalToLocal(pointerPosition);
    final positionWithinComponent = convertedPointerPosition - position;

    if (tapPositions.containsKey(pointer)) {
      // use stored tap positions because this will be lost on tap up event.
      buttons = tapPositions[pointer]!.buttons;
      tapPositions.remove(pointer);
      if (containsPoint(convertedPointerPosition)) {
        onTap?.call(buttons, positionWithinComponent);
        if (doubleTapTimer?.isActive ?? false) {
          doubleTapTimer?.cancel();
          onDoubleTap?.call(buttons, positionWithinComponent);
        } else {
          doubleTapTimer =
              Timer(Duration(milliseconds: doubleTapTimeConsider), () {
            doubleTapTimer?.cancel();
          });
        }
        onTapUp?.call(buttons, positionWithinComponent);
        return true;
      }
    } else {
      onTapCancel?.call();
    }

    return false;
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
    final convertedPointerPosition =
        isHud ? pointerPosition : gameRef.camera.globalToLocal(pointerPosition);
    if (containsPoint(convertedPointerPosition) &&
        tapPositions.containsKey(pointer)) {
      isDragging = true;
      final dragPosition = tapPositions[pointer]!;
      final r =
          onDragStart?.call(buttons, dragPosition.positionWithinComponent);
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

    // final pointerPosition = details.globalPosition.toVector2();
    // final convertedPointerPosition =
    //     isHud ? pointerPosition : gameRef.camera.globalToLocal(pointerPosition);
    if (tapPositions.containsKey(pointer)) {
      final dragPosition = tapPositions[pointer]!.positionWithinComponent;
      onDragUpdate?.call(buttons, dragPosition, details.delta.toVector2());
    }
  }

  @mustCallSuper
  void handleDragEnd(int pointer, int buttons, TapUpDetails details,
      GameComponent? draggingComponent) {
    for (final c in gestureComponents) {
      c.handleDragEnd(pointer, buttons, details, draggingComponent);
    }

    if (!enableGesture) return;

    final pointerPosition = details.globalPosition.toVector2();
    final convertedPointerPosition =
        isHud ? pointerPosition : gameRef.camera.globalToLocal(pointerPosition);

    if (containsPoint(convertedPointerPosition) &&
        draggingComponent != null &&
        draggingComponent != this) {
      final positionWithinComponent = convertedPointerPosition - position;
      onDragIn?.call(buttons, positionWithinComponent, draggingComponent);
    }

    final isDragWithInComponent = handleTapUp(pointer, buttons, details);

    if (isDragging && (tapPositions.containsKey(pointer))) {
      isDragging = false;
      tapPositions.remove(pointer);
      if (!isDragWithInComponent) {
        final dragPosition = tapPositions[pointer]!.positionWithinComponent;
        onDragEnd?.call(buttons, dragPosition, convertedPointerPosition);
      }
    }
  }

  @mustCallSuper
  bool handleScaleStart(List<TouchDetails> touches, ScaleStartDetails details) {
    assert(touches.length == 2);

    for (final c in gestureComponents) {
      c.handleScaleStart(touches, details);
    }

    if (!enableGesture) return false;

    final pointerPosition1 = touches[0].currentGlobalPosition.toVector2();
    final convertedPointerPosition1 = isHud
        ? pointerPosition1
        : gameRef.camera.globalToLocal(pointerPosition1);
    final pointerPosition2 = touches[1].currentGlobalPosition.toVector2();
    final convertedPointerPosition2 = isHud
        ? pointerPosition2
        : gameRef.camera.globalToLocal(pointerPosition2);
    if (containsPoint(convertedPointerPosition1) &&
        containsPoint(convertedPointerPosition2)) {
      isScalling = true;
      onScaleStart?.call(touches, details);
      return true;
    } else {
      handleScaleEnd();
    }

    return false;
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
    final convertedPointerPosition1 = isHud
        ? pointerPosition1
        : gameRef.camera.globalToLocal(pointerPosition1);
    final pointerPosition2 = touches[1].currentGlobalPosition.toVector2();
    final convertedPointerPosition2 = isHud
        ? pointerPosition2
        : gameRef.camera.globalToLocal(pointerPosition2);
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
    final convertedPointerPosition =
        isHud ? pointerPosition : gameRef.camera.globalToLocal(pointerPosition);
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
    final convertedPointerPosition =
        isHud ? pointerPosition : gameRef.camera.globalToLocal(pointerPosition);
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

  @mustCallSuper
  void handleMouseScroll(MouseScrollDetails details) {
    for (final c in gestureComponents) {
      c.handleMouseScroll(details);
    }

    if (!enableGesture) return;

    final pointerPosition = details.position.toVector2();
    final convertedPointerPosition =
        isHud ? pointerPosition : gameRef.camera.globalToLocal(pointerPosition);
    if (containsPoint(convertedPointerPosition)) {
      if (details.scrollDelta.dy > 0) {
        onMouseScrollDown?.call();
      } else if (details.scrollDelta.dy < 0) {
        onMouseScrollUp?.call();
      }
    }
  }
}
