import 'package:flutter/material.dart';
import 'package:flame/effects.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/components.dart';

import '../engine.dart';

/// 演示 GameComponent 动画、手势分发以及特效三个子系统。
class ComponentsScene extends Scene {
  ComponentsScene({required super.id});

  late final RichTextComponent _gestureLog;

  bool _moverAtStart = true;
  bool _faderVisible = true;
  bool _cameraZoomed = false;
  double _clipZoom = 1.0;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final backButton = SpriteButton(
      anchor: Anchor.center,
      text: 'Back',
      spriteId: 'button.png',
      useSpriteSrcSize: true,
      position: Vector2(70.0, 40.0),
    );
    backButton.onTap = (button, position) {
      engine.popScene();
    };
    world.add(backButton);

    // === GAMECOMPONENT 区域 ===

    // moveTo：点击在两个位置之间往复移动
    final moverStart = Vector2(220.0, 260.0);
    final moverEnd = Vector2(520.0, 260.0);
    final mover = SpriteComponent2(
      spriteId: 'glow2.png',
      position: moverStart.clone(),
      size: Vector2.all(110.0),
      anchor: Anchor.center,
      enableGesture: true,
      clipMode: true,
    );
    mover.onTap = (button, position) {
      _moverAtStart = !_moverAtStart;
      mover.moveTo(
        toPosition: _moverAtStart ? moverStart : moverEnd,
        duration: 0.8,
        curve: Curves.easeInOut,
      );
    };
    // 滚轮缩放演示 clipMode + zoom（zoom 被限制在 1.0 ~ 2.0）
    mover.onMouseScrollUp = (position) {
      _clipZoom = (_clipZoom + 0.2).clamp(1.0, 2.0);
      mover.zoom = _clipZoom;
    };
    mover.onMouseScrollDown = (position) {
      _clipZoom = (_clipZoom - 0.2).clamp(1.0, 2.0);
      mover.zoom = _clipZoom;
    };
    world.add(mover);

    // fadeIn / fadeOut / snapTo / boxFit
    final faderHome = Vector2(220.0, 390.0);
    final faderAway = Vector2(520.0, 390.0);
    final fader = SpriteComponent2(
      spriteId: 'pepe.png',
      position: faderHome.clone(),
      size: Vector2.all(110.0),
      anchor: Anchor.center,
      boxFit: BoxFit.contain,
      enableGesture: true,
    );
    fader.onTap = (button, position) {
      if (_faderVisible) {
        _faderVisible = false;
        // 库中 FadeEffect 在淡出结束时会将组件移出父级，
        // 因此再次淡入前需要重新挂回 world
        fader.fadeOut(duration: 0.8);
      } else {
        _faderVisible = true;
        world.add(fader);
        fader.fadeIn(duration: 0.8);
      }
    };
    fader.onDoubleTap = (button, position) {
      fader.snapTo(
        toPosition: (fader.position == faderHome) ? faderAway : faderHome,
      );
    };
    world.add(fader);

    // === GESTURES 区域 ===

    final draggable = SpriteComponent2(
      spriteId: 'pepe.png',
      position: Vector2(1060.0, 280.0),
      size: Vector2.all(150.0),
      anchor: Anchor.center,
      enableGesture: true,
    );
    draggable.onTap = (button, position) => _showGesture('onTap');
    draggable.onDoubleTap = (button, position) => _showGesture('onDoubleTap');
    draggable.onLongPress = (position) => _showGesture('onLongPress');
    draggable.onDragStart = (button, position) {
      _showGesture('onDragStart');
      return null;
    };
    draggable.onDragUpdate = (button, position, delta) {
      draggable.position += delta;
    };
    draggable.onDragEnd = (position) => _showGesture('onDragEnd');
    draggable.onMouseEnter = () {
      draggable.opacity = 0.6;
      _showGesture('onMouseEnter');
    };
    draggable.onMouseExit = () {
      draggable.opacity = 1.0;
      _showGesture('onMouseExit');
    };
    draggable.onMouseScrollUp = (position) {
      draggable.scale = draggable.scale * 1.1;
      _showGesture('onMouseScrollUp');
    };
    draggable.onMouseScrollDown = (position) {
      draggable.scale = draggable.scale * 0.9;
      _showGesture('onMouseScrollDown');
    };
    world.add(draggable);

    _gestureLog = RichTextComponent(
      text: '<grey>hover / click / drag the image</>',
      size: Vector2(360.0, 70.0),
      position: Vector2(880.0, 430.0),
      config: const ScreenTextConfig(textAlign: TextAlign.center),
    );
    world.add(_gestureLog);

    // === EFFECTS 区域 ===

    final shakeButton = SpriteButton(
      anchor: Anchor.center,
      text: 'Camera Shake',
      spriteId: 'button.png',
      useSpriteSrcSize: true,
      position: Vector2(400.0, 620.0),
    );
    shakeButton.onTap = (button, position) {
      add(CameraShakeEffect(
        controller: EffectController(duration: 0.5),
        intensity: 80,
        shift: 12,
        frequency: 4,
      ));
    };
    world.add(shakeButton);

    final zoomButton = SpriteButton(
      anchor: Anchor.center,
      text: 'Camera Zoom',
      spriteId: 'button.png',
      useSpriteSrcSize: true,
      position: Vector2(720.0, 620.0),
    );
    zoomButton.onTap = (button, position) {
      _cameraZoomed = !_cameraZoomed;
      if (_cameraZoomed) {
        camera.moveTo2(center + Vector2(180.0, 120.0), speed: 300.0, zoom: 1.5);
      } else {
        camera.moveTo2(center, speed: 300.0, zoom: 1.0);
      }
    };
    world.add(zoomButton);

    final confettiButton = SpriteButton(
      anchor: Anchor.center,
      text: 'Confetti',
      spriteId: 'button.png',
      useSpriteSrcSize: true,
      position: Vector2(1040.0, 620.0),
    );
    confettiButton.onTap = (button, position) {
      world.add(ConfettiEffect(size: size));
    };
    world.add(confettiButton);
  }

  void _showGesture(String name) {
    _gestureLog.text = '<yellow>Last gesture:</>\n<bold>$name</>';
  }

  void _drawAreaLabel(Canvas canvas, String text, double left, double top) {
    drawScreenText(
      canvas,
      text,
      config: ScreenTextConfig(
        size: size,
        anchor: Anchor.topLeft,
        padding: EdgeInsets.only(left: left, top: top),
        textStyle: const TextStyle(fontSize: 16, color: Colors.white70),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    drawScreenText(
      canvas,
      'Components Demo',
      config: ScreenTextConfig(
        size: size,
        anchor: Anchor.topCenter,
        padding: const EdgeInsets.only(top: 15.0),
        textStyle: const TextStyle(fontSize: 24.0, color: Colors.white),
      ),
    );
    _drawAreaLabel(
        canvas,
        'GAMECOMPONENT: moveTo / fadeIn-fadeOut / snapTo / boxFit-zoom',
        80.0,
        110.0);
    _drawAreaLabel(
        canvas,
        'GESTURES: tap / double-tap / long-press / drag / hover / scroll',
        830.0,
        110.0);
    _drawAreaLabel(
        canvas, 'EFFECTS: camera shake / camera zoom / confetti', 80.0, 540.0);
  }

  @override
  Widget build(
    BuildContext context, {
    Widget Function(BuildContext)? loadingBuilder,
    Map<String, Widget Function(BuildContext, Scene)>? overlayBuilderMap,
    List<String>? initialActiveOverlays,
  }) {
    return Scaffold(
      body: Stack(
        children: [
          SceneWidget(scene: this),
        ],
      ),
    );
  }
}
