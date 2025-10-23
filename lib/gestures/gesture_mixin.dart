import 'dart:async' show Timer;

import 'package:meta/meta.dart';
import 'package:flutter/gestures.dart';

import '../extensions.dart';
import '../widgets/pointer_detector.dart'
    show TouchDetails, MouseScrollDetails, PointerMoveDetails;
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
export '../widgets/pointer_detector.dart'
    show TouchDetails, PointerMoveUpdateDetails;

class TappingDetails {
  int pointer;
  int button;
  Vector2 globalPosition;
  HandlesGesture component;

  TappingDetails(
    this.pointer,
    this.button,
    this.globalPosition,
    this.component,
  );
}

mixin HandlesGesture on GameComponent {
  /// A specific duration to detect double tap
  static int doubleTapTimeConsider = 400;

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
  Timer? doubleTapTimer;

  void Function(int button, Vector2 position)? onTap;
  void Function(int button, Vector2 position)? onTapDown;
  void Function(int button, Vector2 position)? onTapUp;
  void Function(int button, Vector2 position)? onDoubleTap;

  /// 拖动开始时，返回被拖动的子对象
  /// 如果返回null，此时其他对象仍会捕捉到拖动事件，只是无法拿到被拖动的对象
  HandlesGesture? Function(int button, Vector2 position)? onDragStart;

  /// 对象自己被拖动时
  void Function(int button, Vector2 position, Vector2 delta)? onDragUpdate;

  /// 其他对象在此控件中拖动时
  void Function(int button, GameComponent? component)? onDragOver;

  /// 此控件被拖动并松开
  void Function(int button, Vector2 position)? onDragEnd;

  /// 其他对象拖入此控件并松开
  void Function(int button, Vector2 position, GameComponent? component)?
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
  bool handleTapDown(int pointer, int button, TapDownDetails details) {
    if (!enableGesture || !isVisible) return false;

    for (final c in gestureComponents) {
      if (c.handleTapDown(pointer, button, details) &&
          !tappingDetails.containsKey(pointer)) {
        return true;
      }
    }

    final pointerPosition = details.globalPosition.toVector2();
    final convertedPointerPosition =
        isHud ? pointerPosition : game.camera.globalToLocal(pointerPosition);

    final isContained = containsPoint(convertedPointerPosition);
    if (isContained) {
      isPressing = true;
      tappingDetails[pointer] =
          TappingDetails(pointer, button, pointerPosition, this);
      final positionWithinComponent = convertedPointerPosition - position;
      onTapDown?.call(button, positionWithinComponent);
      return true;
    }

    return false;
  }

  @mustCallSuper
  bool handleTapUp(int pointer, int button, TapUpDetails details) {
    if (!enableGesture || !isVisible) return false;

    for (final c in gestureComponents) {
      if (c.handleTapUp(pointer, button, details) &&
          !tappingDetails.containsKey(pointer)) {
        return true;
      }
    }

    final pointerPosition = details.globalPosition.toVector2();
    final convertedPointerPosition =
        isHud ? pointerPosition : game.camera.globalToLocal(pointerPosition);

    final isContained = containsPoint(convertedPointerPosition);
    if (isContained) {
      final positionWithinComponent = convertedPointerPosition - position;
      onTap?.call(button, positionWithinComponent);
      if (doubleTapTimer?.isActive ?? false) {
        doubleTapTimer?.cancel();
        onDoubleTap?.call(button, positionWithinComponent);
      } else {
        doubleTapTimer =
            Timer(Duration(milliseconds: doubleTapTimeConsider), () {
          doubleTapTimer?.cancel();
        });
      }
      onTapUp?.call(button, positionWithinComponent);
      return true;
    }

    return false;
  }

  @mustCallSuper
  HandlesGesture? handleDragStart(
      int pointer, int button, DragStartDetails details) {
    if (!enableGesture || !isVisible) return null;

    for (final c in gestureComponents) {
      final r = c.handleDragStart(pointer, button, details);
      if (r != null) {
        return r;
      }
    }

    final pointerPosition = details.globalPosition.toVector2();
    final convertedPointerPosition =
        isHud ? pointerPosition : game.camera.globalToLocal(pointerPosition);
    if (containsPoint(convertedPointerPosition) &&
        tappingDetails.containsKey(pointer)) {
      isDragging = true;
      final detail = tappingDetails[pointer]!;
      final dragPosition = detail.globalPosition;
      final convertedDraggingPosition =
          isHud ? dragPosition : game.camera.globalToLocal(dragPosition);
      final positionWithinComponent = convertedDraggingPosition - position;
      final r = onDragStart?.call(button, positionWithinComponent);
      if (r != null) {
        return r;
      } else {
        return this;
      }
    }

    return null;
  }

  @mustCallSuper
  void handleDragUpdate(int pointer, int button, DragUpdateDetails details,
      GameComponent? draggingComponent) {
    if (!enableGesture || !isVisible) return;

    for (final c in gestureComponents) {
      c.handleDragUpdate(pointer, button, details, draggingComponent);
    }

    final dragPosition = details.globalPosition.toVector2();
    final convertedDraggingPosition =
        isHud ? dragPosition : game.camera.globalToLocal(dragPosition);

    if (isDragging) {
      final delta = game.camera.globalToLocal(details.delta.toVector2());
      onDragUpdate?.call(button, convertedDraggingPosition, delta);
    } else if (containsPoint(convertedDraggingPosition)) {
      onDragOver?.call(button, draggingComponent);
    }
  }

  @mustCallSuper
  void handleDragEnd(int pointer, int button, TapUpDetails details,
      GameComponent? draggingComponent) {
    if (!enableGesture || !isVisible) return;

    for (final c in gestureComponents) {
      c.handleDragEnd(pointer, button, details, draggingComponent);
    }

    final pointerPosition = details.globalPosition.toVector2();
    final convertedPointerPosition =
        isHud ? pointerPosition : game.camera.globalToLocal(pointerPosition);

    // 其他的对象拖入此对象
    if (containsPoint(convertedPointerPosition) && draggingComponent != this) {
      final positionWithinComponent = convertedPointerPosition - position;
      onDragIn?.call(button, positionWithinComponent, draggingComponent);
    }

    // handleTapUp(pointer, button, details);

    // 此对象拖动结束
    if (isDragging) {
      isDragging = false;
      onDragEnd?.call(button, convertedPointerPosition);
    }
  }

  @mustCallSuper
  bool handleScaleStart(List<TouchDetails> touches, ScaleStartDetails details) {
    if (!enableGesture || !isVisible) return false;

    assert(touches.length == 2);

    for (final c in gestureComponents) {
      c.handleScaleStart(touches, details);
    }

    final pointerPosition1 = touches[0].currentGlobalPosition.toVector2();
    final convertedPointerPosition1 =
        isHud ? pointerPosition1 : game.camera.globalToLocal(pointerPosition1);
    final pointerPosition2 = touches[1].currentGlobalPosition.toVector2();
    final convertedPointerPosition2 =
        isHud ? pointerPosition2 : game.camera.globalToLocal(pointerPosition2);
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
    if (!enableGesture || !isVisible || !isScalling) return;

    assert(touches.length == 2);

    for (final c in gestureComponents) {
      c.handleScaleUpdate(touches, details);
    }

    final pointerPosition1 = touches[0].currentGlobalPosition.toVector2();
    final convertedPointerPosition1 =
        isHud ? pointerPosition1 : game.camera.globalToLocal(pointerPosition1);
    final pointerPosition2 = touches[1].currentGlobalPosition.toVector2();
    final convertedPointerPosition2 =
        isHud ? pointerPosition2 : game.camera.globalToLocal(pointerPosition2);
    if (containsPoint(convertedPointerPosition1) &&
        containsPoint(convertedPointerPosition2)) {
      onScaleUpdate?.call(touches, details);
    } else {
      handleScaleEnd();
    }
  }

  @mustCallSuper
  void handleScaleEnd() {
    if (!enableGesture || !isVisible) return;

    for (final c in gestureComponents) {
      c.handleScaleEnd();
    }

    if (isScalling) {
      onScaleEnd?.call();
      isScalling = false;
    }
    tappingDetails.clear();
  }

  @mustCallSuper
  bool handleLongPress(int pointer, int button, LongPressStartDetails details) {
    if (!enableGesture || !isVisible) return false;

    for (final c in gestureComponents) {
      if (c.handleLongPress(pointer, button, details) &&
          !tappingDetails.containsKey(pointer)) {
        return true;
      }
    }

    final pointerPosition = details.globalPosition.toVector2();
    final convertedPointerPosition =
        isHud ? pointerPosition : game.camera.globalToLocal(pointerPosition);

    final isContained = containsPoint(convertedPointerPosition);
    if (isContained) {
      final positionWithinComponent = convertedPointerPosition - position;
      onLongPress?.call(positionWithinComponent);
      return true;
    }

    return false;
  }

  @mustCallSuper
  HandlesGesture? handleMouseHover(PointerMoveDetails details) {
    if (!enableGesture || !isVisible) return null;

    for (final c in gestureComponents) {
      final hoveringChild = c.handleMouseHover(details);
      if (hoveringChild != null) {
        return hoveringChild;
      }
    }

    final pointerPosition = details.position.toVector2();
    final convertedPointerPosition =
        isHud ? pointerPosition : game.camera.globalToLocal(pointerPosition);
    final isContained = containsPoint(convertedPointerPosition);
    if (isContained) {
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
        isHud ? pointerPosition : game.camera.globalToLocal(pointerPosition);
    final isContained = containsPoint(convertedPointerPosition);
    if (isContained) {
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
