import 'dart:math' as math;

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

import '../engine.dart';

class MainMenuScene extends Scene {
  final random = math.Random();

  late FpsComponent fps;

  final fluent.FlyoutController menuController = fluent.FlyoutController();

  final List<dynamic> wikiData = [];

  late final TreeNode<WikiPageData> wikiTreeNodes;

  MainMenuScene({
    required super.id,
    // required super.controller,
    required super.context,
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

    final button1 = SpriteButton(
      anchor: Anchor.center,
      text: 'Board Game',
      spriteId: 'button.png',
      useSpriteSrcSize: true,
      position: center,
    );
    button1.onTap = (button, position) async {};
    background.add(button1);

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

    if (engine.config.debugMode || engine.config.showFps) {
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
        ],
      ),
    );
  }
}
