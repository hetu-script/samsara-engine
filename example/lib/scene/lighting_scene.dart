import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/components.dart';

import '../engine.dart';

/// 演示相机级光照渲染：黑暗遮罩上被光源“穿透”出洞。
/// 只有 world 的直接子组件且 lightConfig.isLighted 为 true 才会发光。
class LightingScene extends Scene {
  LightingScene({required super.id})
      : super(
          enableLighting: true,
          backgroundLightingColor: Colors.black.withValues(alpha: 0.85),
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final background = SpriteComponent(
      sprite: Sprite(await Flame.images.load('main2-small.png')),
      size: size,
    );
    world.add(background);

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

    // 静态圆形光源
    final glowLight = SpriteComponent2(
      spriteId: 'glow.png',
      position: Vector2(300.0, 300.0),
      size: Vector2.all(90.0),
      anchor: Anchor.center,
      lightConfig: LightConfig(radius: 130.0, blurBorder: 30.0),
    );
    world.add(glowLight);

    final pointLight = SpriteComponent2(
      spriteId: 'light_point.png',
      position: Vector2(1100.0, 240.0),
      size: Vector2.all(60.0),
      anchor: Anchor.center,
      lightConfig: LightConfig(radius: 85.0, blurBorder: 15.0),
    );
    world.add(pointLight);

    // 矩形光源
    final rectLight = SpriteComponent2(
      spriteId: 'glow.png',
      position: Vector2(1150.0, 590.0),
      size: Vector2(220.0, 130.0),
      anchor: Anchor.center,
      lightConfig: LightConfig(
        radius: 20.0,
        blurBorder: 25.0,
        shape: LightShape.rect,
      ),
    );
    world.add(rectLight);

    // 缓慢绕圈移动的光源，展示移动光洞
    final orbitLight = SpriteComponent2(
      spriteId: 'light_point.png',
      position: Vector2(500.0, 600.0),
      size: Vector2.all(50.0),
      anchor: Anchor.center,
      lightConfig: LightConfig(radius: 100.0, blurBorder: 20.0),
    );
    world.add(orbitLight);
    _orbit(orbitLight, Vector2(500.0, 600.0), 180.0);
  }

  void _orbit(SpriteComponent2 light, Vector2 orbitCenter, double radius) {
    _orbitStep = (_orbitStep + 1) % _orbitPoints.length;
    light.moveTo(
      toPosition: orbitCenter +
          Vector2(
            _orbitPoints[_orbitStep].x * radius,
            _orbitPoints[_orbitStep].y * radius,
          ),
      duration: 1.6,
      curve: Curves.easeInOut,
      onComplete: () => _orbit(light, orbitCenter, radius),
    );
  }

  // 预计算的八方向偏移，避免每帧三角函数
  final _orbitPoints = <Vector2>[
    Vector2(1.0, 0.0),
    Vector2(0.7, 0.7),
    Vector2(0.0, 1.0),
    Vector2(-0.7, 0.7),
    Vector2(-1.0, 0.0),
    Vector2(-0.7, -0.7),
    Vector2(0.0, -1.0),
    Vector2(0.7, -0.7),
  ];
  int _orbitStep = 0;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    drawScreenText(
      canvas,
      'Lighting Demo',
      config: ScreenTextConfig(
        size: size,
        anchor: Anchor.topCenter,
        padding: const EdgeInsets.only(top: 15.0),
        textStyle: const TextStyle(fontSize: 24.0, color: Colors.white),
      ),
    );
    drawScreenText(
      canvas,
      'Lights only work on direct children of world: static circles, a rect, and an orbiting one',
      config: ScreenTextConfig(
        size: size,
        anchor: Anchor.topLeft,
        padding: const EdgeInsets.only(left: 80.0, top: 100.0),
        textStyle: const TextStyle(fontSize: 16.0, color: Colors.white70),
      ),
    );
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
