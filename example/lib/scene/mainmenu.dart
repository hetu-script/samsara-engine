import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';
import 'package:flame/flame.dart';
import 'package:samsara/components/ui/sprite_button.dart';
import 'package:flame/components.dart';
import 'package:window_manager/window_manager.dart';
import 'package:samsara/markdown_wiki.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:samsara/llm_chat/llm_chat.dart';
import 'package:samsara/game_dialog.dart';
import 'package:samsara/components/ui/rich_text_component.dart';
import 'package:samsara/richtext.dart';

import '../engine.dart';
import '../prompt.dart';

class MainMenuScene extends Scene {
  late FpsComponent fps;

  final fluent.FlyoutController menuController = fluent.FlyoutController();

  final List<dynamic> wikiData = [];

  late final TreeNode<WikiPageData> wikiTreeNodes;

  MainMenuScene({
    required super.id,
    // required super.controller,
    // required super.context,
    super.bgm,
    super.bgmFile,
    super.bgmVolume = 0.5,
  }) : super(enableLighting: false);

  @override
  Future<void> onLoad() async {
    super.onLoad();

    fps = FpsComponent();

    final SpriteComponent background = SpriteComponent(
      // position: Vector2(-size.x / 2, -size.y / 2),
      sprite: Sprite(await Flame.images.load('main2-small.png')),
      size: size,
    );
    world.add(background);

    final title = RichTextComponent(
      text: "<bold h2>Samsara Engine</>\n<grey>showcase scenes</>",
      size: Vector2(400.0, 90.0),
      position: Vector2(center.x - 200.0, 40.0),
      config: ScreenTextConfig(textAlign: TextAlign.center),
    );
    world.add(title);

    final demoScenes = <(String, String)>[
      ('Components', 'components'),
      ('Lighting', 'lighting'),
      ('RichText', 'richtext'),
      ('Hover', 'hover'),
      ('CardGame', 'cardgame'),
      ('Dialog', 'dialog'),
    ];

    // 导航按钮：纵向排列，间距 70px
    const buttonSpacing = 70.0;
    final firstY = center.y - (demoScenes.length - 1) * buttonSpacing / 2;
    for (var i = 0; i < demoScenes.length; ++i) {
      final (label, sceneId) = demoScenes[i];
      final button = SpriteButton(
        anchor: Anchor.center,
        text: label,
        spriteId: 'button.png',
        useSpriteSrcSize: true,
        position: Vector2(center.x, firstY + i * buttonSpacing),
      );
      button.onTap = (button, position) {
        engine.pushScene(sceneId);
      };
      world.add(button);
    }

    engine.setLoading(false);
  }

  @override
  void onDragUpdate(int pointer, int button, DragUpdateDetails details) {
    super.onDragUpdate(pointer, button, details);

    if (button == kSecondaryButton) {
      camera.moveBy(-details.delta.toVector2());
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    fps.update(dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (engine.config.developMode || engine.config.showFps) {
      drawScreenText(
        canvas,
        'FPS: ${fps.fps.toStringAsFixed(0)}',
        config: ScreenTextConfig(
          textStyle: const TextStyle(fontSize: 20),
          size: size,
          anchor: Anchor.topCenter,
          padding: const EdgeInsets.only(top: 40),
        ),
      );
    }
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
          Positioned(
            right: 0,
            top: 0,
            child: fluent.FlyoutTarget(
              controller: menuController,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: fluent.IconButton(
                  icon: Icon(fluent.FluentIcons.collapse_menu),
                  onPressed: () {
                    menuController.showFlyout(builder: (context) {
                      return fluent.MenuFlyout(
                        items: [
                          fluent.MenuFlyoutItem(
                            text: const Text('console'),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) => Console(
                                  engine: engine,
                                ),
                              );
                            },
                          ),
                          fluent.MenuFlyoutItem(
                            text: const Text('llm chat'),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) => ChatView(
                                  engine: engine,
                                  systemPrompt: kSystemPromptTemplate2,
                                ),
                              );
                            },
                          ),
                          fluent.MenuFlyoutItem(
                            text: const Text('quit'),
                            onPressed: () {
                              windowManager.close();
                            },
                          ),
                        ],
                      );
                    });
                  },
                ),
              ),
            ),
          ),
          // Flutter 侧富文本图标验证
          Positioned(
            left: 20,
            bottom: 20,
            child: Label(
              "<icon=sword></><red>攻击力 +5</> <icon=spirit></>灵力<icon=quest></>",
              textStyle: const TextStyle(fontSize: 20),
            ),
          ),
          GameDialogController(),
        ],
      ),
    );
  }
}
