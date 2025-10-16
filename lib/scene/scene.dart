import 'dart:math' as math;
import 'dart:async';

// import 'package:flutter/gestures.dart';
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
import '../components/fading_text.dart';
import 'scene_widget.dart';
import '../task.dart';

const kHintTextPriority = 999999999;

abstract class Scene extends FlameGame with TaskController {
  static const overlayUIBuilderMapKey = 'overlayUI';
  static final random = math.Random();

  final String id;
  // final SceneController controller;
  final BuildContext context;

  Rect bounds = Rect.zero;

  final Bgm? bgm;
  String? bgmFile;
  double bgmVolume;

  HandlesGesture? hoveringComponent;
  HandlesGesture? draggingComponent;

  Vector2 get topLeft => bounds.topLeft.toVector2();
  Vector2 get topCenter => bounds.topCenter.toVector2();
  Vector2 get topRight => bounds.topCenter.toVector2();
  Vector2 get centerLeft => bounds.centerLeft.toVector2();
  Vector2 get center => bounds.center.toVector2();
  Vector2 get centerRight => bounds.centerRight.toVector2();
  Vector2 get bottomLeft => bounds.bottomLeft.toVector2();
  Vector2 get bottomCenter => bounds.bottomCenter.toVector2();
  Vector2 get bottomRight => bounds.bottomRight.toVector2();

  bool get enableLighting => (camera as Camera2).enableLighting;
  set enableLighting(bool value) => (camera as Camera2).enableLighting = value;

  /// 此参数由 SceneController 管理
  // Completer? completer;

  final _hintTextController = TaskController();

  void Function()? onAfterLoaded;

  bool _isFirstLoad = true;

  Scene({
    required this.id,
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

    _hintTextController.schedule(() async {
      await Future.delayed(Duration(milliseconds: 500));
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
    });
  }

  /// 这个函数在进入场景时被调用，通常用来进行恢复之前冻结和终止的一些操作
  /// 不要在这里进行涉及 component 的操作，这个函数执行时机在 onLoad 之前
  /// 注意因为场景本身始终存在于缓存中，因此这个函数可能会反复触发
  @mustCallSuper
  FutureOr<void> onStart([dynamic arguments = const {}]) async {
    if (bgm == null) return;

    if (bgmFile != null) {
      if (bgm!.isPlaying) {
        await bgm!.stop();
      }
      await bgm!.play('music/$bgmFile', volume: bgmVolume);
    }
  }

  /// 这个函数在退出场景时被调用，通常用来清理数据等
  /// 注意此时场景的资源并未被施放，场景本身仍然存在于缓存中
  /// 如果要释放资源，应在调用 controller.popScene() 时带上参数 clearCache: true
  @mustCallSuper
  FutureOr<void> onEnd() async {
    if (bgm == null) return;

    if (bgmFile != null) {
      await bgm!.stop();
    }
  }

  @mustCallSuper
  @override
  void onLoad() async {
    bounds = Rect.fromLTWH(0, 0, size.x, size.y);

    fitScreen();
  }

  @mustCallSuper
  @override
  void onMount() {
    if (_isFirstLoad) {
      _isFirstLoad = false;
      onAfterLoaded?.call();
    }
  }

  @override
  @mustCallSuper
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

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
  void onTapDown(int pointer, int button, TapDownDetails details) {
    for (final c in gestureComponents) {
      if (c.handleTapDown(pointer, button, details)) {
        return;
      }
    }
  }

  @mustCallSuper
  void onTapUp(int pointer, int button, TapUpDetails details) {
    if (HandlesGesture.tappingDetails.containsKey(pointer)) {
      // use stored tap positions because this will be lost on tap up event.
      final detail = HandlesGesture.tappingDetails[pointer]!;
      if (detail.button == button) {
        detail.component.isPressing = false;
      }
      HandlesGesture.tappingDetails.remove(pointer);
    }

    for (final c in gestureComponents) {
      if (c.handleTapUp(pointer, button, details)) {
        return;
      }
    }
  }

  @mustCallSuper
  void onDragStart(int pointer, int button, DragStartDetails details) {
    for (final c in gestureComponents) {
      final r = c.handleDragStart(pointer, button, details);
      if (r != null) {
        draggingComponent = r;
        return;
      }
    }
  }

  @mustCallSuper
  void onDragUpdate(int pointer, int button, DragUpdateDetails details) {
    for (final c in gestureComponents) {
      c.handleDragUpdate(pointer, button, details, draggingComponent);
    }
  }

  @mustCallSuper
  void onDragEnd(int pointer, int button, TapUpDetails details) {
    for (final c in gestureComponents) {
      c.handleDragEnd(pointer, button, details, draggingComponent);
    }

    if (HandlesGesture.tappingDetails.containsKey(pointer)) {
      // use stored tap positions because this will be lost on tap up event.
      final detail = HandlesGesture.tappingDetails[pointer]!;
      detail.component.isPressing = false;
      HandlesGesture.tappingDetails.remove(pointer);
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
  void onLongPress(int pointer, int button, LongPressStartDetails details) {
    for (final c in gestureComponents) {
      if (c.handleLongPress(pointer, button, details)) {
        return;
      }
    }
  }

  @mustCallSuper
  void onMouseHover(PointerMoveDetails details) {
    void mouseEnter([HandlesGesture? entered]) {
      if (hoveringComponent == entered) return;

      hoveringComponent?.onMouseExit?.call();
      hoveringComponent?.isHovering = false;
      hoveringComponent = entered;

      entered?.onMouseEnter?.call();
      entered?.isHovering = true;
    }

    for (final c in gestureComponents) {
      final entered = c.handleMouseHover(details);
      if (entered != null) {
        mouseEnter(entered);
        return;
      }
    }
    mouseEnter();
  }

  @mustCallSuper
  void onMouseScroll(MouseScrollDetails details) {
    for (final c in gestureComponents) {
      c.handleMouseScroll(details);
    }
  }

  Widget build(
    BuildContext context, {
    Widget Function(BuildContext)? loadingBuilder,
    Map<String, Widget Function(BuildContext, Scene)>? overlayBuilderMap,
    List<String>? initialActiveOverlays,
  }) =>
      SceneWidget(
        scene: this,
        loadingBuilder: loadingBuilder,
        overlayBuilderMap: overlayBuilderMap,
        initialActiveOverlays: initialActiveOverlays,
      );
}
