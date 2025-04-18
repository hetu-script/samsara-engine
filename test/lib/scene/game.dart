import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';
import 'package:flame/flame.dart';
import 'package:samsara/components/sprite_button.dart';
import 'package:flame/components.dart';
import 'package:samsara/cardgame/cardgame.dart';
import 'package:hetu_script/utils/uid.dart' as utils;
import 'package:window_manager/window_manager.dart';
import 'package:samsara/widgets/markdown_wiki.dart';
import 'package:samsara/richtext.dart';
import 'package:samsara/task.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flame/game.dart';

// import 'ui/drop_menu.dart';
import '../app.dart';
import '../noise_test.dart';

const richTextSource = 'rich text is <yellow italic>awesome</> !!!';

class GameScene extends Scene {
  final random = math.Random();

  late final PiledZone piledZone;

  CustomGameCard? card;

  final TaskController taskController = TaskController();

  final fluent.FlyoutController menuController = fluent.FlyoutController();

  GameScene({
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

    final SpriteComponent background = SpriteComponent(
      sprite: Sprite(await Flame.images.load('main2-small.png')),
      size: size,
    );
    world.add(background);

    final cardSize = Vector2(350 * 0.74, 350);

    piledZone = PiledZone(
      piledCardSize: cardSize,
    );

    final button = SpriteButton(
      anchor: Anchor.center,
      text: 'Condense',
      spriteId: 'button.png',
      useSpriteSrcSize: true,
      position: center,
    );
    button.onTap = (button, position) async {
      if (card == null) {
        card = CustomGameCard(
          position: center,
          preferredSize: cardSize,
          id: utils.randomUID(),
          illustrationRelativePaddings:
              const EdgeInsets.fromLTRB(0.074, 0.135, 0.074, 0.235),
          illustrationSpriteId: 'attack_normal.png',
          spriteId: 'border4.png',
          title: '无名剑法',
          titleRelativePaddings:
              const EdgeInsets.fromLTRB(0.2, 0.05, 0.2, 0.865),
          titleConfig: ScreenTextConfig(
            anchor: Anchor.center,
            outlined: true,
            textStyle: TextStyle(
              color: Colors.white,
              fontSize: 15.0,
            ),
          ),
          description: '卡牌描述\n词条 2',
          descriptionRelativePaddings:
              const EdgeInsets.fromLTRB(0.108, 0.735, 0.108, 0.08),
          descriptionConfig: const ScreenTextConfig(
            anchor: Anchor.center,
            textStyle: TextStyle(
              fontFamily: 'NotoSansMono',
              // fontFamily: GameUI.fontFamily,
              fontSize: 16.0,
              color: Colors.black,
            ),
            overflow: ScreenTextOverflow.wordwrap,
          ),
          glowSpriteId: 'glow2.png',
          showGlow: true,
        );
        world.add(card!);
        // piledZone.placeCard(card!);
        card!.moveTo(
          duration: 0.5,
          toPosition: Vector2.zero(),
          toSize: cardSize * 1.5,
        );
      } else {
        card!
            .moveTo(
          duration: 0.5,
          toPosition: center,
          toSize: Vector2.zero(),
        )
            .then((_) {
          card!.removeFromParent();
          // piledZone.removeCardById(card!.id);
          card = null;
        });
      }
    };
    background.add(button);
  }

  @override
  void onDragUpdate(int pointer, int button, DragUpdateDetails details) {
    super.onDragUpdate(pointer, button, details);

    if (button == kSecondaryButton) {
      camera.moveBy(-details.delta.toVector2());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: this),
          PointerDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: onTapDown,
            onTapUp: onTapUp,
            onDragStart: onDragStart,
            onDragUpdate: onDragUpdate,
            onDragEnd: onDragEnd,
            onScaleStart: onScaleStart,
            onScaleUpdate: onScaleUpdate,
            onScaleEnd: onScaleEnd,
            onLongPress: onLongPress,
            onMouseHover: onMouseHover,
            onMouseScroll: onMouseScroll,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return Scaffold(
                            appBar: AppBar(actions: const []),
                            body: Center(
                              child: Container(
                                color: Colors.blueGrey,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 5.0, horizontal: 10.0),
                                child: RichText(
                                  text: TextSpan(
                                    children: buildFlutterRichText(
                                      richTextSource,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: const Text('embeded text'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => MarkdownWiki(
                          resourceManager: AssetManager(),
                        ),
                      );
                    },
                    child: const Text('markdown_wiki'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return const NoiseTest();
                          });
                    },
                    child: Label(
                      'noise test',
                      width: 100.0,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                  child: ElevatedButton(
                    onPressed: () {
                      windowManager.close();
                    },
                    child: Label(
                      engine.locale('exit'),
                      width: 100.0,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                          fluent.MenuFlyoutSubItem(
                            text: Text('sub_items'),
                            items: (context) {
                              return <fluent.MenuFlyoutItemBase>[
                                fluent.MenuFlyoutItem(
                                  text: const Text('sub_item1'),
                                  onPressed: () {},
                                ),
                                fluent.MenuFlyoutItem(
                                  text: const Text('sub_item2'),
                                  onPressed: () {},
                                ),
                              ];
                            },
                          ),
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
