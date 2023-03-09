import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import 'scene_controller.dart';
import '../widget/pointer_detector.dart';
import '../gestures/gesture_mixin.dart';
import 'scene_widget.dart';

abstract class Scene extends FlameGame {
  static const overlayUIBuilderMapKey = 'overlayUI';

  final String id;
  final SceneController controller;

  Vector2 topLeft = Vector2.zero(),
      topCenter = Vector2.zero(),
      topRight = Vector2.zero(),
      centerLeft = Vector2.zero(),
      center = Vector2.zero(),
      centerRight = Vector2.zero(),
      bottomLeft = Vector2.zero(),
      bottomCenter = Vector2.zero(),
      bottomRight = Vector2.zero();

  Scene({
    required this.id,
    required this.controller,
  });

  void end() {
    controller.leaveScene(id);
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);

    topCenter.x = center.x = bottomCenter.x = size.x / 2;
    topRight.x = centerRight.x = bottomRight.x = size.x;
    centerLeft.y = center.y = centerRight.y = size.y / 2;
    bottomLeft.y = bottomCenter.y = bottomRight.y = size.y;
  }

  Iterable<HandlesGesture> get gestureComponents =>
      children.whereType<HandlesGesture>().cast<HandlesGesture>();

  /// zoom the camera to a certain size
  void fitScreen(Vector2 toSize) {
    // engine.info('游戏界面可视区域大小：${size.x}x${size.y}');
    final toSizeRatio = toSize.x / toSize.y;
    final gameViewPortRatio = size.x / size.y;
    double scaleFactor;
    if (gameViewPortRatio > toSizeRatio) {
      // 可视区域更宽
      scaleFactor = size.y / toSize.y;
      final newWidth = toSize.x * scaleFactor;
      camera.snapTo(Vector2(-(size.x - newWidth) / 2, 0));
    } else {
      // 可视区域更窄
      scaleFactor = size.x / toSize.x;
      final newHeight = toSize.y * scaleFactor;
      camera.snapTo(Vector2(0, -(size.y - newHeight) / 2));
    }
    camera.zoom = scaleFactor;
  }

  @mustCallSuper
  void onTapDown(int pointer, int buttons, TapDownDetails details) {
    for (final c in gestureComponents) {
      c.handleTapDown(pointer, buttons, details);
    }
  }

  @mustCallSuper
  void onTapUp(int pointer, int buttons, TapUpDetails details) {
    for (final c in gestureComponents) {
      c.handleTapUp(pointer, buttons, details);
    }
  }

  @mustCallSuper
  void onDragStart(int pointer, int buttons, DragStartDetails details) {
    for (final c in gestureComponents) {
      c.handleDragStart(pointer, buttons, details);
    }
  }

  @mustCallSuper
  void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
    for (final c in gestureComponents) {
      c.handleDragUpdate(pointer, buttons, details);
    }
  }

  @mustCallSuper
  void onDragEnd(int pointer, int buttons) {
    for (final c in gestureComponents) {
      c.handleDragEnd(pointer, buttons);
    }
  }

  @mustCallSuper
  void onScaleStart(List<TouchDetails> touches, ScaleStartDetails details) {
    for (final c in gestureComponents) {
      c.handleScaleStart(touches, details);
    }
  }

  @mustCallSuper
  void onScaleUpdate(List<TouchDetails> touches, ScaleUpdateDetails details) {
    for (final c in gestureComponents) {
      c.handleScaleUpdate(touches, details);
    }
  }

  @mustCallSuper
  void onScaleEnd() {
    for (final c in gestureComponents) {
      c.handleScaleEnd();
    }
  }

  @mustCallSuper
  void onLongPress(int pointer, int buttons, LongPressStartDetails details) {
    for (final c in gestureComponents) {
      c.handleLongPress(pointer, buttons, details);
    }
  }

  @mustCallSuper
  void onMouseHover(PointerHoverEvent details) {
    for (final c in gestureComponents) {
      c.handleMouseHover(details);
    }
  }

  SceneWidget getWidget({
    Key? key,
    required Scene scene,
    Map<String, Widget Function(BuildContext, Scene)>? overlayBuilderMap,
  }) {
    return SceneWidget(
      key: key,
      scene: this,
      overlayBuilderMap: overlayBuilderMap,
    );
  }
}
