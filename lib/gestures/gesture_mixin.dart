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

  void onTap(int buttons, Vector2 position) {}

  void onTapDown(int buttons, Vector2 position) {}

  void onTapUp(int buttons, Vector2 position) {}

  void onDoubleTap(int buttons, Vector2 position) {}

  void onTapCancel() {}

  void onDragStart(int buttons) {}

  void onDragUpdate(int buttons, Vector2 worldPosition) {}

  void onDragEnd(int buttons, Vector2 worldPosition) {}

  void onDragIn(int buttons, Vector2 position, GameComponent component) {}

  void onScaleStart(List<TouchDetails> touches, ScaleStartDetails details) {}

  void onScaleUpdate(List<TouchDetails> touches, ScaleUpdateDetails details) {}

  void onScaleEnd() {}

  void onLongPress(Vector2 position) {}

  void onMouseEnter() {}

  void onMouseHover(Vector2 position) {}

  void onMouseExit() {}

  @mustCallSuper
  bool handleTapDown(int pointer, int buttons, TapDownDetails details) {
    for (final c in gestureComponents.toList().reversed) {
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
      onTapDown(buttons, positionWithinComponent);
      return true;
    }

    return false;
  }

  @mustCallSuper
  void handleTapUp(int pointer, int buttons, TapUpDetails details) {
    for (final c in gestureComponents.toList().reversed) {
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
          onTap(buttons, positionWithinComponent);
          onDoubleTap(buttons, positionWithinComponent);
        } else {
          doubleTapTimer =
              Timer(Duration(milliseconds: doubleTapTimeConsider), () {
            doubleTapTimer?.cancel();
          });
        }
      } else {
        onTap(buttons, positionWithinComponent);
        doubleTapTimer =
            Timer(Duration(milliseconds: doubleTapTimeConsider), () {
          doubleTapTimer?.cancel();
        });
      }
      onTapUp(buttons, positionWithinComponent);
    } else {
      onTapCancel();
    }

    tapPositions.remove(pointer);
  }

  @mustCallSuper
  bool handleDragStart(int pointer, int buttons, DragStartDetails details) {
    for (final c in gestureComponents.toList().reversed) {
      if (c.handleDragStart(pointer, buttons, details)) {
        return true;
      }
    }

    if (!enableGesture) return false;

    final pointerPosition = details.globalPosition.toVector2();
    final convertedPointerPosition = positionType != PositionType.game
        ? pointerPosition
        : gameRef.camera.screenToWorld(pointerPosition);
    if (containsPoint(convertedPointerPosition)) {
      isDragging = true;
      onDragStart(buttons);
      return true;
    }

    return false;
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
    onDragUpdate(buttons, convertedPointerPosition);
  }

  @mustCallSuper
  void handleDragEnd(int pointer, int buttons, TapUpDetails details,
      GameComponent draggingComponent) {
    for (final c in gestureComponents.toList().reversed) {
      c.handleDragEnd(pointer, buttons, details, draggingComponent);
    }

    if (!enableGesture) return;

    final pointerPosition = details.globalPosition.toVector2();
    final convertedPointerPosition = positionType != PositionType.game
        ? pointerPosition
        : gameRef.camera.screenToWorld(pointerPosition);
    if (isDragging && (tapPositions.containsKey(pointer))) {
      isDragging = false;
      tapPositions.remove(pointer);
      onDragEnd(buttons, convertedPointerPosition);
    }

    if (containsPoint(convertedPointerPosition)) {
      final positionWithinComponent = convertedPointerPosition - position;
      onDragIn(buttons, positionWithinComponent, draggingComponent);
    }
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
    tapPositions.clear();
  }

  @mustCallSuper
  bool handleLongPress(
      int pointer, int buttons, LongPressStartDetails details) {
    for (final c in gestureComponents.toList().reversed) {
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
      onLongPress(positionWithinComponent);
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
    final positionWithinComponent = convertedPointerPosition - position;
    if (containsPoint(convertedPointerPosition)) {
      if (!isHovering) {
        isHovering = true;
        onMouseEnter();
      }
      onMouseHover(positionWithinComponent);
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
