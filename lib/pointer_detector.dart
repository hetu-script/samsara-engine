import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';

import 'package:hetu_script/utils/math.dart';

export 'package:flutter/gestures.dart' show PointerHoverEvent;

class TouchDetails {
  int pointer;
  int buttons;
  Offset startLocalPosition;
  Offset startGlobalPosition;
  Offset currentLocalPosition;
  Offset currentGlobalPosition;

  TouchDetails(
    this.pointer,
    this.buttons,
    this.startGlobalPosition,
    this.startLocalPosition,
  )   : currentLocalPosition = startLocalPosition,
        currentGlobalPosition = startGlobalPosition;
}

const kMoveTimeDeltaThresholdByMS = 50;

class PointerMoveDetails {
  int timestamp;
  int pointer;
  Offset delta;
  Offset position;
  Offset? localPosition;
  int? buttons;

  PointerMoveDetails({
    required this.timestamp,
    required this.pointer,
    required this.delta,
    required this.position,
    this.localPosition,
    this.buttons,
  });
}

class PointerMoveUpdateDetails {
  /// Creates details for a [PointerMoveUpdateDetails].
  ///
  /// The [delta] argument must not be null.
  ///
  /// If [primaryDelta] is non-null, then its value must match one of the
  /// coordinates of [delta] and the other coordinate must be zero.
  ///
  /// The [globalPosition] argument must be provided and must not be null.
  PointerMoveUpdateDetails({
    this.sourceTimeStamp,
    this.delta = Offset.zero,
    this.primaryDelta,
    required this.globalPosition,
    Offset? localPosition,
  })  : assert(
          primaryDelta == null ||
              (primaryDelta == delta.dx && delta.dy == 0.0) ||
              (primaryDelta == delta.dy && delta.dx == 0.0),
        ),
        localPosition = localPosition ?? globalPosition;

  /// Recorded timestamp of the source pointer event that triggered the drag
  /// event.
  ///
  /// Could be null if triggered from proxied events such as accessibility.
  final Duration? sourceTimeStamp;

  /// The amount the pointer has moved in the coordinate space of the event
  /// receiver since the previous update.
  ///
  /// Defaults to zero if not specified in the constructor.
  final Offset delta;

  /// The amount the pointer has moved along the primary axis in the coordinate
  /// space of the event receiver since the previous
  /// update.
  final double? primaryDelta;

  /// The pointer's global position when it triggered this update.
  ///
  /// See also:
  ///
  ///  * [localPosition], which is the [globalPosition] transformed to the
  ///    coordinate space of the event receiver.
  final Offset globalPosition;

  /// The local position in the coordinate system of the event receiver at
  /// which the pointer contacted the screen.
  ///
  /// Defaults to [globalPosition] if not specified in the constructor.
  final Offset localPosition;
}

class MouseScrollDetails {
  /// Creates a [MouseScrollDetails] data object.
  MouseScrollDetails({
    required this.kind,
    required this.scrollDelta,
    this.position = Offset.zero,
    Offset? localPosition,
  }) : localPosition = localPosition ?? position;

  final Offset scrollDelta;

  /// The global position at which the pointer contacted the screen.
  final Offset position;

  /// The local position at which the pointer contacted the screen.
  final Offset localPosition;

  /// The kind of the device that initiated the event.
  final PointerDeviceKind kind;
}

///  A widget that detects gestures.
/// * Supports Tap, Drag(start, update, end), Scale(start, update, end) and Long Press
/// * All callbacks be used simultaneously
///
/// For handle rotate event, please use rotateAngle on onScaleUpdate.
class PointerDetector extends StatefulWidget {
  /// Creates a widget that detects gestures.
  const PointerDetector({
    super.key,
    this.child,
    this.cursor = MouseCursor.defer,
    this.onTapDown,
    this.onTapUp,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
    this.onLongPress,
    this.longPressTickTimeConsider = 400,
    this.onMouseHover,
    // this.onMouseEnter,
    // this.onMouseExit,
    this.onMouseScroll,
    this.behavior = HitTestBehavior.deferToChild,
  });

  /// The widget below this widget in the tree.
  final Widget? child;

  final HitTestBehavior behavior;

  final MouseCursor cursor;

  final void Function(int pointer, int buttons, TapDownDetails details)?
      onTapDown;
  final void Function(int pointer, int buttons, TapUpDetails details)? onTapUp;

  /// A pointer has contacted the screen with a primary button and has begun to move.
  final void Function(int pointer, int buttons, DragStartDetails details)?
      onDragStart;

  /// A pointer that is in contact with the screen with a primary button and moving has moved again.
  final void Function(int pointer, int buttons, DragUpdateDetails details)?
      onDragUpdate;

  /// A pointer that was previously in contact with the screen with a primary
  /// button and moving is no longer in contact with the screen and was moving
  /// at a specific velocity when it stopped contacting the screen.
  final void Function(int pointer, int buttons, TapUpDetails details)?
      onDragEnd;

  /// The pointers in contact with the screen have established a focal point and
  /// initial scale of 1.0.
  final void Function(List<TouchDetails> touches, ScaleStartDetails details)?
      onScaleStart;

  /// The pointers in contact with the screen have indicated a new focal point
  /// and/or scale.
  ///
  /// =============================================
  ///
  /// **changedFocusPoint** the current focus point
  ///
  /// **scale** the scale value
  ///
  /// **rotationAngle** the rotate angle in radians - using for rotate
  final void Function(List<TouchDetails> touches, ScaleUpdateDetails details)?
      onScaleUpdate;

  /// The pointers are no longer in contact with the screen.
  final void Function()? onScaleEnd;

  /// A pointer has remained in contact with the screen at the same location for a long period of time
  ///
  /// @param
  final void Function(int pointer, int buttons, LongPressStartDetails details)?
      onLongPress;

  /// A specific duration to detect long press
  final int longPressTickTimeConsider;

  // final void Function(PointerEnterEvent details)? onMouseEnter;
  final void Function(PointerMoveDetails details)? onMouseHover;
  // final void Function(PointerExitEvent details)? onMouseExit;

  final void Function(MouseScrollDetails details)? onMouseScroll;

  @override
  PointerDetectorState createState() => PointerDetectorState();
}

enum _GestureState {
  pointerDown,
  dragStart,
  scaleStart,
  scalling,
  longPress,
  none,
}

class PointerDetectorState extends State<PointerDetector> {
  final _touchDetails = <TouchDetails>[];
  double _initialScaleDistance = 0;
  _GestureState _gestureState = _GestureState.none;
  Timer? _longPressTimer;
  // var _lastTouchUpPos = const Offset(0, 0);
  PointerMoveDetails? _lastMoveDetail;
  Timer? _lastMoveTimer;
  PointerMoveDetails? _lastHoverDetail;
  Timer? _lastHoverTimer;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: widget.behavior,
      onPointerDown: onPointerDown,
      onPointerUp: onPointerUp,
      onPointerMove: onPointerMove,
      onPointerCancel: onPointerUp,
      onPointerSignal: onPointerSignal,
      onPointerHover: onMouseHover,
      child: widget.child,
    );
  }

  void onPointerDown(PointerDownEvent event) {
    _touchDetails.add(TouchDetails(
        event.pointer, event.buttons, event.position, event.localPosition));

    if (touchCount == 1) {
      _gestureState = _GestureState.pointerDown;
      widget.onTapDown?.call(
          event.pointer,
          event.buttons,
          TapDownDetails(
              globalPosition: event.position,
              localPosition: event.localPosition,
              kind: event.kind));

      if (widget.onLongPress != null) {
        _longPressTimer?.cancel();
        _longPressTimer =
            Timer(Duration(milliseconds: widget.longPressTickTimeConsider), () {
          if (touchCount == 1 && _touchDetails[0].pointer == event.pointer) {
            _gestureState = _GestureState.longPress;
            widget.onLongPress!(
              event.pointer,
              event.buttons,
              LongPressStartDetails(
                  globalPosition: event.position,
                  localPosition: event.localPosition),
            );
          }
        });
      }
    } else if (touchCount == 2) {
      _gestureState = _GestureState.scaleStart;
    } else {
      _gestureState = _GestureState.none;
    }
  }

  void initScaleAndRotate() {
    _initialScaleDistance = (_touchDetails[0].currentLocalPosition -
            _touchDetails[1].currentLocalPosition)
        .distance;
  }

  void onPointerMove(PointerMoveEvent event) {
    if (_lastMoveDetail != null) {
      _lastMoveDetail!.delta += event.delta;
      _lastMoveDetail!.position = event.position;
    } else {
      _lastMoveDetail = PointerMoveDetails(
        pointer: event.pointer,
        buttons: event.buttons,
        timestamp: event.timeStamp.inMilliseconds,
        delta: event.delta,
        position: event.position,
        localPosition: event.localPosition,
      );
      _lastMoveTimer = Timer(
        Duration(milliseconds: kMoveTimeDeltaThresholdByMS),
        () {
          _lastMoveTimer!.cancel();
          _lastMoveTimer = null;
          assert(_lastMoveDetail != null);
          final moveDetail = _lastMoveDetail!;
          _lastMoveDetail = null;

          final touches = _touchDetails
              .where((detail) => detail.pointer == moveDetail.pointer);
          if (touches.isEmpty) return;
          assert(touches.length == 1);
          final touchDetail = touches.first;

          final distance = Offset(
                  touchDetail.currentLocalPosition.dx -
                      moveDetail.localPosition!.dx,
                  touchDetail.currentLocalPosition.dy -
                      moveDetail.localPosition!.dy)
              .distance;

          touchDetail.currentLocalPosition = moveDetail.localPosition!;
          touchDetail.currentGlobalPosition = moveDetail.position;
          _longPressTimer?.cancel();

          switch (_gestureState) {
            case _GestureState.pointerDown:
              //print('move distance: ' + distance.toString());
              if (distance > 1) {
                _gestureState = _GestureState.dragStart;
                touchDetail.startGlobalPosition = moveDetail.position;
                touchDetail.startLocalPosition = moveDetail.localPosition!;
                widget.onDragStart?.call(
                  moveDetail.pointer,
                  moveDetail.buttons!,
                  DragStartDetails(
                    sourceTimeStamp:
                        Duration(milliseconds: moveDetail.timestamp),
                    globalPosition: moveDetail.position,
                    localPosition: moveDetail.localPosition,
                  ),
                );
              }
            case _GestureState.dragStart:
              if (widget.onDragUpdate != null) {
                widget.onDragUpdate!(
                  moveDetail.pointer,
                  moveDetail.buttons!,
                  DragUpdateDetails(
                    sourceTimeStamp:
                        Duration(milliseconds: moveDetail.timestamp),
                    delta: moveDetail.delta,
                    globalPosition: moveDetail.position,
                    localPosition: moveDetail.localPosition,
                  ),
                );
              }
            case _GestureState.scaleStart:
              touchDetail.startGlobalPosition =
                  touchDetail.currentGlobalPosition;
              touchDetail.startLocalPosition = touchDetail.currentLocalPosition;
              _gestureState = _GestureState.scalling;
              initScaleAndRotate();
              if (widget.onScaleStart != null) {
                final centerGlobal = (_touchDetails[0].currentGlobalPosition +
                        _touchDetails[1].currentGlobalPosition) /
                    2;
                final centerLocal = (_touchDetails[0].currentLocalPosition +
                        _touchDetails[1].currentLocalPosition) /
                    2;
                widget.onScaleStart!(
                    _touchDetails,
                    ScaleStartDetails(
                        focalPoint: centerGlobal,
                        localFocalPoint: centerLocal));
              }
            case _GestureState.scalling:
              if (widget.onScaleUpdate != null) {
                final rotation =
                    _angleBetweenLines(_touchDetails[0], _touchDetails[1]);
                final newDistance = (_touchDetails[0].currentLocalPosition -
                        _touchDetails[1].currentLocalPosition)
                    .distance;
                final centerGlobal = (_touchDetails[0].currentGlobalPosition +
                        _touchDetails[1].currentGlobalPosition) /
                    2;
                final centerLocal = (_touchDetails[0].currentLocalPosition +
                        _touchDetails[1].currentLocalPosition) /
                    2;
                widget.onScaleUpdate!(
                    _touchDetails,
                    ScaleUpdateDetails(
                        focalPoint: centerGlobal,
                        localFocalPoint: centerLocal,
                        scale: newDistance / _initialScaleDistance,
                        rotation: rotation));
              }
            default:
              touchDetail.startGlobalPosition =
                  touchDetail.currentGlobalPosition;
              touchDetail.startLocalPosition = touchDetail.currentLocalPosition;
          }
        },
      );
    }
  }

  double _angleBetweenLines(TouchDetails f, TouchDetails s) {
    double angle1 = math.atan2(
        f.currentLocalPosition.dy - s.currentLocalPosition.dy,
        f.currentLocalPosition.dx - s.currentLocalPosition.dx);
    double angle2 = math.atan2(
        f.currentLocalPosition.dy - s.currentLocalPosition.dy,
        f.currentLocalPosition.dx - s.currentLocalPosition.dx);

    double angle = degrees(angle1 - angle2) % 360;
    if (angle < -180.0) angle += 360.0;
    if (angle > 180.0) angle -= 360.0;
    return radians(angle);
  }

  void onPointerUp(PointerEvent event) {
    // use the original detail's buttons information instead
    // because this information will be lost in the pointerUp event.
    final originalDetail =
        _touchDetails.singleWhere((detail) => detail.pointer == event.pointer);
    final tapUpDetail = TapUpDetails(
        globalPosition: event.position,
        localPosition: event.localPosition,
        kind: event.kind);
    if (_gestureState == _GestureState.pointerDown ||
        _gestureState == _GestureState.longPress) {
      widget.onTapUp?.call(event.pointer, originalDetail.buttons, tapUpDetail);
    } else if (_gestureState == _GestureState.scaleStart ||
        _gestureState == _GestureState.scalling) {
      _gestureState = _GestureState.none;
      widget.onScaleEnd?.call();
    } else if (_gestureState == _GestureState.dragStart) {
      _gestureState = _GestureState.none;
      widget.onDragEnd?.call(event.pointer, event.buttons, tapUpDetail);
    } else if (_gestureState == _GestureState.none && touchCount == 2) {
      _gestureState = _GestureState.scaleStart;
    } else {
      _gestureState = _GestureState.none;
    }

    _touchDetails.removeWhere((detail) => detail.pointer == event.pointer);
    // _lastTouchUpPos = event.localPosition;
  }

  void onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;

    final mouseScrollDetail = MouseScrollDetails(
        scrollDelta: event.scrollDelta,
        position: event.position,
        localPosition: event.localPosition,
        kind: event.kind);
    widget.onMouseScroll?.call(mouseScrollDetail);
  }

  void onMouseHover(PointerHoverEvent event) {
    if (_lastHoverDetail != null) {
      _lastHoverDetail!.delta += event.delta;
      _lastHoverDetail!.position = event.position;
    } else {
      _lastHoverDetail = PointerMoveDetails(
        pointer: event.pointer,
        timestamp: event.timeStamp.inMilliseconds,
        delta: event.delta,
        position: event.position,
        localPosition: event.localPosition,
      );
      _lastHoverTimer = Timer(
        Duration(milliseconds: kMoveTimeDeltaThresholdByMS),
        () {
          _lastHoverTimer!.cancel();
          _lastHoverTimer = null;
          assert(_lastHoverDetail != null);
          widget.onMouseHover?.call(_lastHoverDetail!);
          _lastHoverDetail = null;
        },
      );
    }
  }

  // void onMouseEnter(PointerEnterEvent event) {
  //   widget.onMouseEnter?.call(event);
  // }

  // void onMouseExit(PointerExitEvent event) {
  //   widget.onMouseExit?.call(event);
  // }

  get touchCount => _touchDetails.length;
}
