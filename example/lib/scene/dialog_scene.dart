import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/components.dart';
import 'package:samsara/game_dialog.dart';

import '../engine.dart';

/// 演示游戏内对话框系统：使用全局 GameDialog 编排一段脚本——
/// 带名字和头像的对话 → 选项选择（悬停选项显示 hover_info 描述）→ 收尾对话。
class DialogScene extends Scene {
  DialogScene({required super.id});

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

    final scriptButton = SpriteButton(
      anchor: Anchor.center,
      text: 'Start Dialog',
      spriteId: 'button.png',
      useSpriteSrcSize: true,
      position: center - Vector2(0.0, 80.0),
    );
    scriptButton.onTap = (button, position) {
      _runDialogScript();
    };
    world.add(scriptButton);

    final hintButton = SpriteButton(
      anchor: Anchor.center,
      text: 'Screen Hint',
      spriteId: 'button.png',
      useSpriteSrcSize: true,
      position: center + Vector2(0.0, 20.0),
    );
    hintButton.onTap = (button, position) {
      dialog.pushScreenHint(
        rect: Rect.fromLTWH(
          scriptButton.position.x - 60,
          scriptButton.position.y - 25,
          120,
          50,
        ),
        text: 'Click the highlighted button',
      );
      dialog.execute();
    };
    world.add(hintButton);

    final illustrationButton = SpriteButton(
      anchor: Anchor.center,
      text: 'Illustrations',
      spriteId: 'button.png',
      useSpriteSrcSize: true,
      position: center + Vector2(0.0, 120.0),
    );
    illustrationButton.onTap = (button, position) {
      dialog.pushImage('pepe.png', offsetX: -180);
      dialog.pushImage('light_trail_500.png', offsetX: 180);
      dialog.pushDialogRaw({
        'name': 'Pepe the Guide',
        'icon': 'pepe.png',
        'lines': [
          'The small avatar and the larger light trail use their own sizes.',
          'Both are aligned to the bottom center without a fixed illustration box.',
        ],
      });
      dialog.execute();
    };
    world.add(illustrationButton);

    final resetButton = SpriteButton(
      anchor: Anchor.center,
      text: 'Reset Dialog',
      spriteId: 'button.png',
      useSpriteSrcSize: true,
      position: center + Vector2(0.0, 220.0),
    );
    resetButton.onTap = (button, position) {
      dialog.reset();
    };
    world.add(resetButton);
  }

  @override
  void onEnd() {
    dialog.reset();
    super.onEnd();
  }

  void _runDialogScript() {
    // 1. 带名字和头像的对话
    dialog.pushDialogRaw({
      'name': 'Pepe the Guide',
      'icon': 'pepe.png',
      'lines': [
        'Welcome to the <red>Samsara</> dialog demo!',
        'This typewriter dialog is rendered by GameDialogContent.',
        'Click once to skip the line, again to continue.',
      ],
    });

    // 2. 选项：悬停选项按钮可通过 hover_info 显示描述
    dialog.pushSelectionRaw({
      'id': 'choice',
      'selections': {
        'sword': {
          'text': 'I want a sword',
          'description': '<grey>A sharp blade.</> 攻击 +5',
        },
        'spirit': {
          'text': 'I want spirit',
          'description': '<blue>Mystic energy.</> 灵力 +3',
        },
        'nothing': 'No thanks',
      },
    });

    // 3. 收尾对话，读取之前选择的结果
    dialog.pushTask(() {
      final choice = dialog.getValue('choice') ?? 'nothing';
      dialog.pushDialogRaw({
        'name': 'Pepe the Guide',
        'icon': 'pepe.png',
        'lines': [
          'You chose: <yellow>$choice</>.',
          'That is the end of the demo. Click to close!',
        ],
      });
    });

    dialog.execute();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    drawScreenText(
      canvas,
      'Dialog Demo',
      config: ScreenTextConfig(
        size: size,
        anchor: Anchor.topCenter,
        padding: const EdgeInsets.only(top: 15.0),
        textStyle: const TextStyle(fontSize: 24.0, color: Colors.white),
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
          // 本场景的对话框渲染控制器
          GameDialogController(
            dialogFrameBuilder: (context, child) {
              return Container(
                width: 880,
                height: 190,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xF2050914),
                  border: Border.all(color: const Color(0xFF4A899C), width: 2),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: child,
              );
            },
            dialogAvatarSize: const Size(120, 120),
            dialogAvatarMargin: EdgeInsets.zero,
            selectionButtonBuilder: (context, key, text, onPressed) {
              return SizedBox(
                width: 240,
                child: OutlinedButton(
                  onPressed: onPressed,
                  child: Text(text, textAlign: TextAlign.center),
                ),
              );
            },
            screenHintBorderColor: const Color(0xFF58DFFF),
          ),
        ],
      ),
    );
  }
}
