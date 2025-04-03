import 'dart:async' show Timer;

import 'package:meta/meta.dart';
import 'package:flutter/gestures.dart';

import '../extensions.dart';
import '../pointer_detector.dart' show TouchDetails, MouseScrollDetails;
import '../components/game_component.dart';

export 'package:flutter/gestures.dart'
    show
        TapDownDetails,
        TapUpDetails,
        DragStartDetails,
        DragUpdateDetails,
        ScaleStartDetails,
        ScaleUpdateDetails,
        LongPressStartDetails;
export '../pointer_detector.dart' show TouchDetails, PointerMoveUpdateDetails;

class TappingDetails {
  int pointer;
  int buttons;
  Vector2 globalPosition;
  HandlesGesture component;

  TappingDetails(
    this.pointer,
    this.buttons,
    this.globalPosition,
    this.component,
  );
}

mixin HandlesGesture on GameComponent {
  static Map<int, TappingDetails> tappingDetails = {};

  bool enableGesture = true;

  /// 此控件是否在被点击
  bool isPressing = false;

  /// 此控件是否在被拖动
  bool isDragging = false;

  /// 此控件是否在被双指缩放
  bool isScalling = false;

  /// 鼠标光标是否在此控件上
  bool isHovering = false;

  /// A specific duration to detect double tap
  int doubleTapTimeConsider = 400;
  Timer? doubleTapTimer;

  void Function(int buttons, Vector2 position)? onTap;
  void Function(int buttons, Vector2 position)? onTapDown;
  void Function(int buttons, Vector2 position)? onTapUp;
  void Function(int buttons, Vector2 position)? onDoubleTap;

  /// 拖动开始时，返回被拖动的子对象
  /// 如果返回null，此时其他对象仍会捕捉到拖动事件，只是无法拿到被拖动的对象
  HandlesGesture? Function(int buttons, Vector2 position)? onDragStart;

  /// 对象自己被拖动时
  void Function(int buttons, Vector2 offset)? onDragUpdate;

  /// 其他对象在此控件中拖动时
  void Function(int buttons, GameComponent? component)? onDragOver;

  /// 此控件被拖动并松开
  void Function(int buttons, Vector2 position)? onDragEnd;

  /// 其他对象拖入此控件并松开
  void Function(int buttons, Vector2 position, GameComponent? component)?
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
          !tappingDetails.containsKey(pointer)) {
        return true;
      }
    }

    if (!enableGesture || !isVisible) return false;

    final pointerPosition = details.globalPosition.toVector2();
    final convertedPointerPosition =
        isHud ? pointerPosition : gameRef.camera.globalToLocal(pointerPosition);
    if (containsPoint(convertedPointerPosition)) {
      isPressing = true;
      tappingDetails[pointer] =
          TappingDetails(pointer, buttons, pointerPosition, this);
      final positionWithinComponent = convertedPointerPosition - position;
      onTapDown?.call(buttons, positionWithinComponent);
      return true;
    }

    return false;
  }

  @mustCallSuper
  bool handleTapUp(int pointer, int buttons, TapUpDetails details) {
    for (final c in gestureComponents) {
      if (c.handleTapUp(pointer, buttons, details) &&
          !tappingDetails.containsKey(pointer)) {
        return true;
      }
    }

    if (!enableGesture || !isVisible) return false;

    final pointerPosition = details.globalPosition.toVector2();
    final convertedPointerPosition =
        isHud ? pointerPosition : gameRef.camera.globalToLocal(pointerPosition);

    if (containsPoint(convertedPointerPosition)) {
      final positionWithinComponent = convertedPointerPosition - position;
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

    if (!enableGesture || !isVisible) return null;

    final pointerPosition = details.globalPosition.toVector2();
    final convertedPointerPosition =
        isHud ? pointerPosition : gameRef.camera.globalToLocal(pointerPosition);
    if (containsPoint(convertedPointerPosition) &&
        tappingDetails.containsKey(pointer)) {
      isDragging = true;
      final detail = tappingDetails[pointer]!;
      final dragPosition = detail.globalPosition;
      final convertedDraggingPosition =
          isHud ? dragPosition : gameRef.camera.globalToLocal(dragPosition);
      final positionWithinComponent = convertedDraggingPosition - position;
      final r = onDragStart?.call(buttons, positionWithinComponent);
      if (r != null) {
        return r;
      } else {
        return this;
      }
    }

    return null;
  }

  @mustCallSuper
  void handleDragUpdate(int pointer, int buttons, DragUpdateDetails details,
      GameComponent? draggingComponent) {
    for (final c in gestureComponents) {
      c.handleDragUpdate(pointer, buttons, details, draggingComponent);
    }

    if (!enableGesture || !isVisible) {
      return;
    }

    final dragPosition = details.globalPosition.toVector2();
    final convertedDraggingPosition =
        isHud ? dragPosition : gameRef.camera.globalToLocal(dragPosition);

    if (isDragging) {
      final delta = game.camera.globalToLocal(details.delta.toVector2());
      onDragUpdate?.call(buttons, delta);
    } else if (containsPoint(convertedDraggingPosition)) {
      onDragOver?.call(buttons, draggingComponent);
    }
  }

  @mustCallSuper
  void handleDragEnd(int pointer, int buttons, TapUpDetails details,
      GameComponent? draggingComponent) {
    for (final c in gestureComponents) {
      c.handleDragEnd(pointer, buttons, details, draggingComponent);
    }

    if (!enableGesture || !isVisible) return;

    final pointerPosition = details.globalPosition.toVector2();
    final convertedPointerPosition =
        isHud ? pointerPosition : gameRef.camera.globalToLocal(pointerPosition);

    // 其他的对象拖入此对象
    if (containsPoint(convertedPointerPosition) && draggingComponent != this) {
      final positionWithinComponent = convertedPointerPosition - position;
      onDragIn?.call(buttons, positionWithinComponent, draggingComponent);
    }

    // handleTapUp(pointer, buttons, details);

    // 此对象拖动结束
    if (isDragging) {
      isDragging = false;
      onDragEnd?.call(buttons, convertedPointerPosition);
    }
  }

  @mustCallSuper
  bool handleScaleStart(List<TouchDetails> touches, ScaleStartDetails details) {
    assert(touches.length == 2);

    for (final c in gestureComponents) {
      c.handleScaleStart(touches, details);
    }

    if (!enableGesture || !isVisible) return false;

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

    if (!enableGesture || !isVisible || !isScalling) return;

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

    if (!enableGesture || !isVisible) return;

    if (isScalling) {
      onScaleEnd?.call();
      isScalling = false;
    }
    tappingDetails.clear();
  }

  @mustCallSuper
  bool handleLongPress(
      int pointer, int buttons, LongPressStartDetails details) {
    for (final c in gestureComponents) {
      if (c.handleLongPress(pointer, buttons, details) &&
          !tappingDetails.containsKey(pointer)) {
        return true;
      }
    }

    if (!enableGesture || !isVisible) return false;

    final pointerPosition = details.globalPosition.toVector2();
    final convertedPointerPosition =
        isHud ? pointerPosition : gameRef.camera.globalToLocal(pointerPosition);
    if (containsPoint(convertedPointerPosition)) {
      final positionWithinComponent = convertedPointerPosition - position;
      onLongPress?.call(positionWithinComponent);
      return true;
    }

    return false;
  }

  @mustCallSuper
  HandlesGesture? handleMouseHover(PointerHoverEvent details) {
    for (final c in gestureComponents) {
      final hoveringChild = c.handleMouseHover(details);
      if (hoveringChild != null) {
        return hoveringChild;
      }
    }

    if (!enableGesture || !isVisible) return null;

    final pointerPosition = details.position.toVector2();
    final convertedPointerPosition =
        isHud ? pointerPosition : gameRef.camera.globalToLocal(pointerPosition);
    if (containsPoint(convertedPointerPosition)) {
      isHovering = true;
      final positionWithinComponent = convertedPointerPosition - position;
      onMouseHover?.call(positionWithinComponent);
      return this;
    } else {
      // if (isHovering) {
      //   isHovering = false;
      //   onMouseExit?.call();
      // }
      return null;
    }
  }

  @mustCallSuper
  bool handleMouseScroll(MouseScrollDetails details) {
    for (final c in gestureComponents) {
      c.handleMouseScroll(details);
    }

    if (!enableGesture || !isVisible) return false;

    final pointerPosition = details.position.toVector2();
    final convertedPointerPosition =
        isHud ? pointerPosition : gameRef.camera.globalToLocal(pointerPosition);
    if (containsPoint(convertedPointerPosition)) {
      if (details.scrollDelta.dy > 0) {
        onMouseScrollDown?.call();
      } else if (details.scrollDelta.dy < 0) {
        onMouseScrollUp?.call();
      }
      return true;
    }

    return false;
  }
}
