import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/bgm.dart';

// import '../lighting/lighting_config.dart';
import '../components/game_component.dart';
import '../extensions.dart';
import 'scene_controller.dart';
import '../widgets/pointer_detector.dart';
import '../gestures/gesture_mixin.dart';
// import '../components/border_component.dart';
import '../lighting/camera2.dart';
import '../lighting/world2.dart';
import '../components/fading_text.dart';
import '../paint/paint.dart';

const kHintTextPriority = 1000000;

abstract class Scene extends FlameGame {
  static const overlayUIBuilderMapKey = 'overlayUI';

  final String id;
  final SceneController controller;
  final BuildContext context;

  Rect bounds = Rect.zero;

  String? bgmFile;
  double bgmVolume;

  GameComponent? draggingComponent;

  Vector2 topLeft = Vector2.zero(),
      topCenter = Vector2.zero(),
      topRight = Vector2.zero(),
      centerLeft = Vector2.zero(),
      center = Vector2.zero(),
      centerRight = Vector2.zero(),
      bottomLeft = Vector2.zero(),
      bottomCenter = Vector2.zero(),
      bottomRight = Vector2.zero();

  late final Bgm bgm;

  bool get enableLighting => (camera as Camera2).enableLighting;
  set enableLighting(bool value) => (camera as Camera2).enableLighting = value;

  Scene({
    required this.id,
    required this.controller,
    required this.context,
    this.bgmFile,
    this.bgmVolume = 0.5,
    bool enableLighting = false,
    Color? backgroundLightingColor,
  }) : super(
          camera: Camera2(
            enableLighting: enableLighting,
            backgroundLightingColor: backgroundLightingColor,
          ),
          world: World2(),
        ) {
    // camera.viewfinder.anchor = Anchor.topLeft;
    bgm = Bgm();
  }

  void addHintText(
    String text, {
    Vector2? position,
    GameComponent? target,
    Color? color,
    TextStyle? textStyle,
    double duration = 2,
    double offsetY = 100.0,
    double horizontalVariation = 30.0,
    double verticalVariation = 30.0,
  }) {
    assert(position != null || target != null);
    Vector2 p = position ?? target!.position;

    final r = math.Random();
    final c = FadingText(
      text,
      position: Vector2(
        p.x + r.nextDouble() * horizontalVariation - horizontalVariation / 2,
        p.y + r.nextDouble() * verticalVariation - verticalVariation,
      ),
      movingUpOffset: offsetY,
      duration: duration,
      config: ScreenTextConfig(
        anchor: Anchor.center,
        textStyle: TextStyle(
          color: color ?? Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ).merge(
          (textStyle ?? TextStyle()),
        ),
      ),
      priority: kHintTextPriority,
    );
    world.add(c);
  }

  void leave({bool clearCache = false}) async {
    if (clearCache) {
      controller.clearCache(id);
    }
    if (bgm.isPlaying) {
      try {
        await bgm.stop();
      } catch (e) {
        controller.error(e.toString());
      }
    }
  }

  @mustCallSuper
  @override
  void onLoad() async {
    fitScreen();
    if (bgm.isPlaying) {
      bgm.stop();
    } else {
      bgm.initialize();
    }
    if (bgmFile != null) {
      try {
        await bgm.play('audio/music/$bgmFile', volume: bgmVolume);
      } catch (e) {
        controller.error(e.toString());
      }
    }
  }

  @mustCallSuper
  @override
  void onDispose() async {
    bgm.stop();
  }

  @override
  @mustCallSuper
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    topCenter.x = center.x = bottomCenter.x = size.x / 2;
    topRight.x = centerRight.x = bottomRight.x = size.x;
    centerLeft.y = center.y = centerRight.y = size.y / 2;
    bottomLeft.y = bottomCenter.y = bottomRight.y = size.y;

    bounds = Rect.fromLTWH(0, 0, size.x, size.y);
  }

  Iterable<HandlesGesture> get gestureComponents =>
      descendants(reversed: true).whereType<HandlesGesture>();

  /// zoom the camera to a certain size
  void fitScreen([Vector2? fitSize]) {
    Vector2 toSize = fitSize ?? size;

    camera.snapTo(toSize / 2);

    final toSizeRatio = toSize.x / toSize.y;
    final gameViewPortRatio = size.x / size.y;
    double scaleFactor;
    if (gameViewPortRatio > toSizeRatio) {
      // 可视区域更宽
      scaleFactor = size.y / toSize.y;
      // final newWidth = toSize.x * scaleFactor;
      // camera.moveTo(Vector2(-(size.x - newWidth) / 2, 0));
    } else {
      // 可视区域更窄
      scaleFactor = size.x / toSize.x;
      // final newHeight = toSize.y * scaleFactor;
      // camera.moveTo(Vector2(0, -(size.y - newHeight) / 2));
    }
    camera.viewfinder.zoom = scaleFactor;

    // camera = CameraComponent.withFixedResolution(
    //   width: toSize.x,
    //   height: toSize.y,
    // );
  }

  @mustCallSuper
  void onTapDown(int pointer, int buttons, TapDownDetails details) {
    for (final c in gestureComponents) {
      if (c.handleTapDown(pointer, buttons, details)) {
        return;
      }
    }
  }

  @mustCallSuper
  void onTapUp(int pointer, int buttons, TapUpDetails details) {
    for (final c in gestureComponents) {
      if (c.handleTapUp(pointer, buttons, details)) {
        return;
      }
    }
  }

  @mustCallSuper
  void onDragStart(int pointer, int buttons, DragStartDetails details) {
    for (final c in gestureComponents) {
      final r = c.handleDragStart(pointer, buttons, details);
      if (r != null) {
        draggingComponent = r;
        return;
      }
    }
  }

  @mustCallSuper
  void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
    for (final c in gestureComponents) {
      c.handleDragUpdate(pointer, buttons, details, draggingComponent);
    }
  }

  @mustCallSuper
  void onDragEnd(int pointer, int buttons, TapUpDetails details) {
    for (final c in gestureComponents) {
      c.handleDragEnd(pointer, buttons, details, draggingComponent);
    }
    draggingComponent = null;
  }

  @mustCallSuper
  void onScaleStart(List<TouchDetails> touches, ScaleStartDetails details) {
    for (final c in gestureComponents) {
      if (c.handleScaleStart(touches, details)) {
        return;
      }
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
      if (c.handleLongPress(pointer, buttons, details)) {
        return;
      }
    }
  }

  HandlesGesture? hoveringComponent;

  @mustCallSuper
  void onMouseHover(PointerHoverEvent details) {
    void exitPreviousHoveringComponent([HandlesGesture? component]) {
      if (hoveringComponent == component) return;

      hoveringComponent?.onMouseExit?.call();
      hoveringComponent?.isHovering = false;
      hoveringComponent = component;

      component?.onMouseEnter?.call();
    }

    for (final c in gestureComponents) {
      final enteredComponent = c.handleMouseHover(details);
      if (enteredComponent != null) {
        exitPreviousHoveringComponent(enteredComponent);
        return;
      }
    }
    exitPreviousHoveringComponent();
  }

  @mustCallSuper
  void onMouseScroll(MouseScrollDetails details) {
    for (final c in gestureComponents) {
      c.handleMouseScroll(details);
    }
  }
}
