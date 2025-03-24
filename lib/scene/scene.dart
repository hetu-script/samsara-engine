import 'dart:math' as math;
// import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/bgm.dart';

// import '../lighting/lighting_config.dart';
import '../components/game_component.dart';
import '../extensions.dart';
// import 'scene_controller.dart';
import '../pointer_detector.dart';
import '../gestures/gesture_mixin.dart';
// import '../components/border_component.dart';
import '../camera/camera2.dart';
import '../camera/world2.dart';
import '../components/fading_text.dart';
import 'scene_widget.dart';

const kHintTextPriority = 999999999;

abstract class Scene extends FlameGame {
  static const overlayUIBuilderMapKey = 'overlayUI';

  final String id;
  // final SceneController controller;
  final BuildContext context;

  Rect bounds = Rect.zero;

  final Bgm? bgm;
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

  bool get enableLighting => (camera as Camera2).enableLighting;
  set enableLighting(bool value) => (camera as Camera2).enableLighting = value;

  /// 此参数由 SceneController 管理
  // Completer? completer;

  Scene({
    required this.id,
    // required this.controller,
    required this.context,
    this.bgm,
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
    bool onViewport = true,
  }) {
    assert(position != null || target != null);
    Vector2 targetPosition =
        position ?? (onViewport ? target!.absoluteCenter : target!.center);

    final random = math.Random();
    final component = FadingText(
      text,
      position: Vector2(
        targetPosition.x +
            random.nextDouble() * horizontalVariation -
            horizontalVariation / 2,
        targetPosition.y +
            random.nextDouble() * verticalVariation -
            verticalVariation,
      ),
      movingUpOffset: offsetY,
      duration: duration,
      textStyle: TextStyle(
        color: color ?? Colors.white,
      ).merge(textStyle),
      priority: kHintTextPriority,
    );
    if (onViewport) {
      camera.viewport.add(component);
    } else {
      world.add(component);
    }
  }

  /// 这个函数在进入场景时被调用，通常用来进行恢复之前冻结和终止的一些操作
  /// 不要在这里进行涉及 component 的操作，这个函数执行时机在 onLoad 之前
  /// 注意因为场景本身始终存在于缓存中，因此这个函数可能会反复触发
  @mustCallSuper
  void onStart([Map<String, dynamic> arguments = const {}]) async {
    if (bgm == null) return;

    if (bgmFile != null) {
      if (bgm!.isPlaying) {
        await bgm!.stop();
      }
      await bgm!.play('music/$bgmFile', volume: bgmVolume);
    }
  }

  /// 这个函数在场景参数被改变时触发
  /// 通常意味着当前已经在此场景中时，某些事件试图调用此场景的某些功能
  void onTrigger(dynamic arguments) {}

  /// 这个函数在退出场景时被调用，通常用来清理数据等
  /// 注意此时场景的资源并未被施放，场景本身仍然存在于缓存中
  /// 如果要释放资源，应在调用 controller.popScene() 时带上参数 clearCache: true
  @mustCallSuper
  void onEnd() async {
    if (bgm == null) return;

    if (bgmFile != null) {
      await bgm!.stop();
    }
  }

  @mustCallSuper
  @override
  void onLoad() async {
    fitScreen();
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

  Widget build(BuildContext context) => SceneWidget(scene: this);
}
