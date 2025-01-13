import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';
import 'package:flame/flame.dart';
import 'package:samsara/components/sprite_button.dart';
import 'package:flame/components.dart';
// import 'package:samsara/utils/math.dart' as math;
import 'package:samsara/cardgame/cardgame.dart';
import 'package:hetu_script/utils/uid.dart' as utils;
import 'package:window_manager/window_manager.dart';
import 'package:samsara/ui/label.dart';
import 'package:samsara/widgets/markdown_wiki.dart';
import 'package:samsara/richtext.dart';

import 'ui/drop_menu.dart';
import '../app.dart';

const richTextSource = 'rich text is <yellow italic>awesome</> !!!';

class GameScene extends Scene {
  final random = math.Random();

  late final PiledZone piledZone;

  CustomGameCard? card;

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
      onTap: (buttons, position) async {
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
      },
    );
    // camera.viewport.add(button);
    background.add(button);

    // button.onMouseEnter = () {
    //   Hovertip.show(
    //     scene: this,
    //     target: button,
    //     direction: HovertipDirection.topCenter,
    //     width: 360,
    //     content:
    //         '''<yellow>野堂</>\n\n<yellow>宋代：陆游</>\n\n野堂萧飒雪侵冠，历尽人间行路难。\n病马不收烟草暝，孤桐半落井床寒。\n长瓶浊酒犹堪醉，败箧残编更细看。\n此兴不随年共老，未容城角动忧端。''',
    //     config: ScreenTextConfig(anchor: Anchor.topCenter),
    //   );
    // };
    // button.onMouseExit = () {
    //   Hovertip.hide(button);
    // };
    button.onDragUpdate = (int buttons, Vector2 offset) {
      button.position += offset;
    };

    // button.onTap = (buttons, position) async {
    //   final coordinates1 =
    //       getDividingPointsFromCircle(center.x, center.y, 200, 24);
    //   world.addAll([
    //     LightTrail(
    //       radius: 200,
    //       index: 0,
    //       points: coordinates1,
    //     ),
    //     LightTrail(
    //       radius: 200,
    //       index: 8,
    //       points: coordinates1,
    //     ),
    //     LightTrail(
    //       radius: 200,
    //       index: 16,
    //       points: coordinates1,
    //     ),
    //   ]);

    //   final coordinates2 =
    //       getDividingPointsFromCircle(center.x, center.y, 350, 30);
    //   world.addAll([
    //     LightTrail(
    //       radius: 350,
    //       index: 0,
    //       points: coordinates2,
    //     ),
    //     LightTrail(
    //       radius: 350,
    //       index: 6,
    //       points: coordinates2,
    //     ),
    //     LightTrail(
    //       radius: 350,
    //       index: 12,
    //       points: coordinates2,
    //     ),
    //     LightTrail(
    //       radius: 350,
    //       index: 18,
    //       points: coordinates2,
    //     ),
    //     LightTrail(
    //       radius: 350,
    //       index: 24,
    //       points: coordinates2,
    //     ),
    //   ]);

    //   final coordinates3 =
    //       getDividingPointsFromCircle(center.x, center.y, 500, 36);
    //   world.addAll([
    //     LightTrail(
    //       radius: 500,
    //       index: 0,
    //       points: coordinates3,
    //     ),
    //     LightTrail(
    //       radius: 500,
    //       index: 4,
    //       points: coordinates3,
    //     ),
    //     LightTrail(
    //       radius: 500,
    //       index: 8,
    //       points: coordinates3,
    //     ),
    //     LightTrail(
    //       radius: 500,
    //       index: 12,
    //       points: coordinates3,
    //     ),
    //     LightTrail(
    //       radius: 500,
    //       index: 16,
    //       points: coordinates3,
    //     ),
    //     LightTrail(
    //       radius: 500,
    //       index: 20,
    //       points: coordinates3,
    //     ),
    //     LightTrail(
    //       radius: 500,
    //       index: 24,
    //       points: coordinates3,
    //     ),
    //     LightTrail(
    //       radius: 500,
    //       index: 28,
    //       points: coordinates3,
    //     ),
    //     LightTrail(
    //       radius: 500,
    //       index: 32,
    //       points: coordinates3,
    //     ),
    //   ]);
    // };
  }

  @override
  void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
    super.onDragUpdate(pointer, buttons, details);

    if (buttons == kSecondaryButton) {
      camera.moveBy(-details.delta.toVector2());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SceneWidget(scene: this),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
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
                  padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
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
                  padding: const EdgeInsets.only(top: 20.0, bottom: 100.0),
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
            child: MainGameDropMenu(
              onSelected: (MainGameDropMenuItems item) async {
                switch (item) {
                  case MainGameDropMenuItems.console:
                    showDialog(
                      context: context,
                      builder: (BuildContext context) => Console(
                        engine: engine,
                      ),
                    );
                  case MainGameDropMenuItems.quit:
                    windowManager.close();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
