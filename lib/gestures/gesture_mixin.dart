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

  int? tapPointer;
  bool isDragging = false, isScalling = false, isHovering = false;

  /// A specific duration to detect double tap
  int doubleTapTimeConsider = 400;
  Timer? doubleTapTimer;

  void onTap(int pointer, int buttons, TapUpDetails details) {}

  void onTapDown(int pointer, int buttons, TapDownDetails details) {}

  void onTapUp(int pointer, int buttons, TapUpDetails details) {}

  void onDoubleTap(int pointer, int buttons, TapUpDetails details) {}

  void onTapCancel() {}

  void onDragStart(int pointer, int buttons, DragStartDetails details) {}

  void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {}

  void onDragEnd(int pointer, int buttons) {}

  void onScaleStart(List<TouchDetails> touches, ScaleStartDetails details) {}

  void onScaleUpdate(List<TouchDetails> touches, ScaleUpdateDetails details) {}

  void onScaleEnd() {}

  void onLongPress(int buttons, LongPressStartDetails details) {}

  void onMouseEnter() {}

  void onMouseHover(PointerHoverEvent details) {}

  void onMouseExit() {}

  @mustCallSuper
  bool handleTapDown(int pointer, int buttons, TapDownDetails details) {
    for (final c in gestureComponents.toList().reversed) {
      if (c.handleTapDown(pointer, buttons, details) && tapPointer != pointer) {
        return true;
      }
    }

    if (!enableGesture || (tapPointer != null)) {
      return false;
    }

    final pointerPosition = details.globalPosition.toVector2();
    final convertedPointerPosition = positionType != PositionType.game
        ? pointerPosition
        : gameRef.camera.screenToWorld(pointerPosition);
    if (containsPoint(convertedPointerPosition)) {
      tapPointer = pointer;
      onTapDown(pointer, buttons, details);
      return true;
    }

    return false;
  }

  @mustCallSuper
  bool handleTapUp(int pointer, int buttons, TapUpDetails details) {
    for (final c in gestureComponents.toList().reversed) {
      if (c.handleTapUp(pointer, buttons, details) && tapPointer != pointer) {
        return true;
      }
    }

    if (!enableGesture || (tapPointer != pointer)) {
      tapPointer = null;
      return false;
    }

    final pointerPosition = details.globalPosition.toVector2();
    final convertedPointerPosition = positionType != PositionType.game
        ? pointerPosition
        : gameRef.camera.screenToWorld(pointerPosition);
    if (containsPoint(convertedPointerPosition)) {
      if (doubleTapTimer?.isActive ?? false) {
        doubleTapTimer?.cancel();
        if (tapPointer == pointer) {
          onTap(pointer, buttons, details);
          onDoubleTap(pointer, buttons, details);
        } else {
          doubleTapTimer =
              Timer(Duration(milliseconds: doubleTapTimeConsider), () {
            doubleTapTimer?.cancel();
          });
        }
      } else {
        onTap(pointer, buttons, details);
        doubleTapTimer =
            Timer(Duration(milliseconds: doubleTapTimeConsider), () {
          doubleTapTimer?.cancel();
        });
      }
      onTapUp(pointer, buttons, details);
      tapPointer = null;
      return true;
    } else {
      onTapCancel();
    }

    tapPointer = null;
    return false;
  }

  @mustCallSuper
  void handleDragStart(int pointer, int buttons, DragStartDetails details) {
    for (final c in gestureComponents.toList().reversed) {
      c.handleDragStart(pointer, buttons, details);
    }

    if (!enableGesture) return;

    final pointerPosition = details.globalPosition.toVector2();
    final convertedPointerPosition = positionType != PositionType.game
        ? pointerPosition
        : gameRef.camera.screenToWorld(pointerPosition);
    if (containsPoint(convertedPointerPosition)) {
      isDragging = true;
      onDragStart(pointer, buttons, details);
    }
  }

  @mustCallSuper
  void handleDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
    for (final c in gestureComponents.toList().reversed) {
      c.handleDragUpdate(pointer, buttons, details);
    }

    if (!enableGesture || !isDragging) return;

    final pointerPosition = details.globalPosition.toVector2();
    final convertedPointerPosition = positionType != PositionType.game
        ? pointerPosition
        : gameRef.camera.screenToWorld(pointerPosition);
    if (containsPoint(convertedPointerPosition)) {
      onDragUpdate(pointer, buttons, details);
    } else {
      handleDragEnd(pointer, buttons);
      if ((tapPointer != null) && (tapPointer == pointer)) {
        onTapCancel();
        tapPointer = null;
      }
    }
  }

  @mustCallSuper
  void handleDragEnd(int pointer, int buttons) {
    for (final c in gestureComponents.toList().reversed) {
      c.handleDragEnd(pointer, buttons);
    }

    if (!enableGesture) return;

    if (isDragging && (tapPointer == pointer)) {
      isDragging = false;
      onDragEnd(pointer, buttons);
    }
    tapPointer = null;
  }

  @mustCallSuper
  void handleScaleStart(List<TouchDetails> touches, ScaleStartDetails details) {
    assert(touches.length == 2);

    for (final c in gestureComponents.toList().reversed) {
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
      onScaleStart(touches, details);
    } else {
      handleScaleEnd();
    }
  }

  @mustCallSuper
  void handleScaleUpdate(
      List<TouchDetails> touches, ScaleUpdateDetails details) {
    assert(touches.length == 2);

    for (final c in gestureComponents.toList().reversed) {
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
      onScaleUpdate(touches, details);
    } else {
      handleScaleEnd();
    }
  }

  @mustCallSuper
  void handleScaleEnd() {
    for (final c in gestureComponents.toList().reversed) {
      c.handleScaleEnd();
    }

    if (!enableGesture) return;

    if (isScalling) {
      onScaleEnd();
      isScalling = false;
    }
    tapPointer = null;
  }

  @mustCallSuper
  bool handleLongPress(
      int pointer, int buttons, LongPressStartDetails details) {
    for (final c in gestureComponents.toList().reversed) {
      if (c.handleLongPress(pointer, buttons, details) &&
          tapPointer != pointer) {
        return true;
      }
    }

    if (!enableGesture || tapPointer != pointer) return false;

    final pointerPosition = details.globalPosition.toVector2();
    final convertedPointerPosition = positionType != PositionType.game
        ? pointerPosition
        : gameRef.camera.screenToWorld(pointerPosition);
    if (containsPoint(convertedPointerPosition)) {
      onLongPress(buttons, details);
      return true;
    }

    return false;
  }

  @mustCallSuper
  bool handleMouseHover(PointerHoverEvent details) {
    for (final c in gestureComponents.toList().reversed) {
      if (c.handleMouseHover(details)) {
        return true;
      }
    }

    if (!enableGesture) return false;

    final pointerPosition = details.position.toVector2();
    final convertedPointerPosition = positionType != PositionType.game
        ? pointerPosition
        : gameRef.camera.screenToWorld(pointerPosition);
    if (containsPoint(convertedPointerPosition)) {
      if (!isHovering) {
        isHovering = true;
        onMouseEnter();
      }
      onMouseHover(details);
      return true;
    } else {
      if (isHovering) {
        onMouseExit();
        isHovering = false;
      }
      return false;
    }
  }
}
