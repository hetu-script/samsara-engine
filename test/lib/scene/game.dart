import 'dart:math' as math;

import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';
import 'package:samsara/components/tooltip.dart';
import 'package:flame/flame.dart';
import 'package:samsara/components/sprite_button.dart';
import 'package:flame/components.dart';
// import 'package:samsara/utils/math.dart' as math;
import 'package:samsara/cardgame/cardgame.dart';
import 'package:hetu_script/utils/uid.dart' as utils;

// import '../global.dart';
// import 'components/light_trail.dart';

class GameScene extends Scene {
  final random = math.Random();

  late final SpriteButton condensedCenter;
  late final PiledZone piledZone;

  GameScene({
    required super.id,
    required super.controller,
    required super.context,
  }) : super(enableLighting: false);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    fitScreen();

    final SpriteComponent background = SpriteComponent(
      sprite: Sprite(await Flame.images.load('main2-small.png')),
      size: size,
    );
    world.add(background);

    condensedCenter = SpriteButton(
      anchor: Anchor.center,
      position: center,
      useSimpleStyle: true,
      spriteId: 'light_point.png',
      size: Vector2(50, 50),
      lightConfig: LightConfig(
        radius: 250,
        blurBorder: 500,
      ),
    );

    world.add(condensedCenter);

    final button = SpriteButton(
      anchor: Anchor.center,
      text: 'Condense',
      spriteId: 'button.png',
      useSpriteSrcSize: true,
      position: Vector2(center.x, size.y - 100),
    );
    camera.viewport.add(button);

    button.onMouseEnter = () {
      Tooltip.show(
        scene: this,
        target: button,
        preferredDirection: TooltipDirection.topCenter,
        title: '野堂',
        description:
            '''宋代：陆游\n\n野堂萧飒雪侵冠，历尽人间行路难。病马不收烟草暝，孤桐半落井床寒。长瓶浊酒犹堪醉，败箧残编更细看。此兴不随年共老，未容城角动忧端。''',
      );
    };
    button.onMouseExit = () {
      Tooltip.hide();
    };
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

    final cardSize = Vector2(250, 250 * 1.382);

    piledZone = PiledZone(
      piledCardSize: cardSize,
    );

    final cardId = utils.randomUID();

    button.onTap = (buttons, position) async {
      final card = CustomGameCard(
        id: cardId,
        deckId: cardId,
        preferredSize: cardSize,
        illustrationRelativePaddings:
            const EdgeInsets.fromLTRB(0.06, 0.04, 0.06, 0.42),
        illustrationSpriteId: 'attack_normal.png',
        spriteId: 'border2.png',
        title: '卡牌名字',
        titleRelativePaddings:
            const EdgeInsets.fromLTRB(0.08, 0.469, 0.08, 0.469),
        titleConfig: const ScreenTextConfig(
          anchor: Anchor.topCenter,
          outlined: true,
          textStyle: TextStyle(
            fontSize: 18.0,
            // color: Colors.orange,
            // fontWeight: FontWeight.bold,
          ),
        ),
        // description: '这是一段很长的文字用来测试大段文字在指定区域的自动换行和对齐',
        richDescription: '造成<red>5点</>伤害',
        descriptionRelativePaddings:
            const EdgeInsets.fromLTRB(0.08, 0.581, 0.08, 0.08),
        descriptionConfig: const ScreenTextConfig(
          anchor: Anchor.topLeft,
          // outlined: true,
          textStyle: TextStyle(fontSize: 18.0, color: Colors.black),
          overflow: ScreenTextOverflow.wordwrap,
        ),
      );
      world.add(card);
      piledZone.placeCard(card);
    };
  }

  @override
  void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
    super.onDragUpdate(pointer, buttons, details);

    if (buttons == kSecondaryButton) {
      camera.moveBy(-details.delta.toVector2());
    }
  }
}
