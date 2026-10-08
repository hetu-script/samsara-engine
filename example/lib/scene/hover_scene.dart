import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/components.dart';
import 'package:samsara/richtext.dart';
import 'package:samsara/hover_info.dart';

import '../engine.dart';

/// 演示两套悬浮提示系统：
/// - Flame 层 Hovertip：由组件的 onMouseEnter/onMouseExit 触发
/// - Flutter 层 hover_info：由 Label 的 onMouseEnter/onMouseExit 触发
///   并通过 HoverContentState 驱动 HoverInfo 浮层
class HoverScene extends Scene {
  HoverScene({required super.id});

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

    // Flame 层悬浮提示：悬停显示 Hovertip，移出隐藏
    final flameTips = <(String, String)>[
      (
        'pepe.png',
        '<yellow>Hovertip:</> Flame-side tooltip rendered into the camera viewport.'
      ),
      (
        'glow.png',
        '<red>Rich text</> and icons <icon=sword></> work inside a Hovertip.'
      ),
      (
        'glow2.png',
        'Each component shows its own tooltip content on mouse enter.'
      ),
    ];
    for (var i = 0; i < flameTips.length; ++i) {
      final (spriteId, tip) = flameTips[i];
      final target = SpriteComponent2(
        spriteId: spriteId,
        position: Vector2(400.0 + i * 320.0, 300.0),
        size: Vector2.all(140.0),
        anchor: Anchor.center,
        enableGesture: true,
      );
      target.onMouseEnter = () {
        Hovertip.show(
          scene: this,
          target: target,
          content: tip,
          direction: HovertipDirection.bottomCenter,
        );
      };
      target.onMouseExit = () {
        Hovertip.hideAll();
      };
      world.add(target);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    drawScreenText(
      canvas,
      'Hover Demo',
      config: ScreenTextConfig(
        size: size,
        anchor: Anchor.topCenter,
        padding: const EdgeInsets.only(top: 15.0),
        textStyle: const TextStyle(fontSize: 24.0, color: Colors.white),
      ),
    );
    drawScreenText(
      canvas,
      'Hover the images for Flame-side Hovertip, or the labels below for Flutter-side HoverInfo',
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
          // Flutter 层悬浮提示：Label + HoverContentState + HoverInfo
          Positioned(
            left: 120.0,
            bottom: 90.0,
            child: Label(
              '<bold>Hover me (bottom tooltip)</>',
              width: 300.0,
              textStyle: const TextStyle(fontSize: 20.0, color: Colors.white),
              backgroundColor: Colors.black38,
              onMouseEnter: (rect) {
                context.read<HoverContentState>().show(
                      rect: rect,
                      data: '<red>Rich</> Flutter-side tooltip text',
                      direction: HoverContentDirection.topCenter,
                    );
              },
              onMouseExit: () {
                context.read<HoverContentState>().hide();
              },
            ),
          ),
          Positioned(
            right: 120.0,
            bottom: 90.0,
            child: Label(
              '<bold>Hover me (left tooltip)</>',
              width: 300.0,
              textStyle: const TextStyle(fontSize: 20.0, color: Colors.white),
              backgroundColor: Colors.black38,
              onMouseEnter: (rect) {
                context.read<HoverContentState>().show(
                      rect: rect,
                      data:
                          '<blue>Another</> hover_info tooltip <icon=wiki></>',
                      direction: HoverContentDirection.leftCenter,
                    );
              },
              onMouseExit: () {
                context.read<HoverContentState>().hide();
              },
            ),
          ),
          // HoverInfo 只在 HoverContentState.content 非空时渲染，
          // 用 Consumer 把最新的 content 喂给控件
          Consumer<HoverContentState>(
            builder: (context, hoverState, _) {
              final content = hoverState.content;
              if (content == null) {
                return const SizedBox.shrink();
              }
              return HoverInfo(content);
            },
          ),
        ],
      ),
    );
  }
}
