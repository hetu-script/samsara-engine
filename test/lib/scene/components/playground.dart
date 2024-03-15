import 'package:flame/components.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';
import 'package:samsara/component/sprite_button.dart';
// import 'package:samsara/effect/fade_effect.dart';
// import 'package:flame/effects.dart';
// import 'package:samsara/component/in_and_out_sprite.dart';
import 'package:samsara/component/arrow.dart';
import 'package:samsara/component/tooltip.dart';
import 'package:flame/flame.dart';

class PlayGround extends GameComponent with HandlesGesture {
  // late final StatusBar status;

  late Arrow arrow;

  Vector2 mousePos = Vector2.zero();

  PlayGround({
    required double width,
    required double height,
  }) : super(size: Vector2(width, height)) {
    onTapDown = (int buttons, Vector2 position) {
      // final c = SpriteButton(spriteId: 'pepe.png', anchor: Anchor.center);
      // c.position = position;
      // c.add(FadeEffect(target: c, controller: EffectController(duration: 1.0)));
      // add(c);

      // final c2 = FadingText(
      //   'hit!\n100',
      //   movingUpOffset: 50,
      //   duration: 0.8,
      //   fadeOutAfterDuration: 0.3,
      //   textPaint: DefaultTextPaint.danger.copyWith(
      //     (textStyle) => textStyle.copyWith(fontSize: 16),
      //   ),
      // );
      // c2.position = position;
      // add(c2);

      // add(InAndOutSprite('pepe',
      //     flyInDuration: 0.4, stayDuration: 0.4, flyOutDuration: 0.4));
    };

    onMouseHover = (position) {
      // arrow.setPath(center, position);

      // sprite.position = position;
      // // mousePos = position;
      // sprite.lookAt(center);

      // mousePos = position.moveAlongAngle(radians(90) + sprite.angle, -20);
      // final dist = center.distanceTo(mousePos);
      // sprite.scale = Vector2(1, dist / 90);
    };
  }

  @override
  Future<void> onLoad() async {
    final SpriteComponent background = SpriteComponent(
      sprite: Sprite(await Flame.images.load('main2-small.png')),
      size: size,
    );
    add(background);

    final button = SpriteButton(
      spriteId: 'pepe.png',
      // anchor: Anchor.center,
      useSpriteSrcSize: true,
      borderRadius: 20.0,
      position: center,
    );

    button.onMouseEnter = () {
      Tooltip.show(
        scene: gameRef,
        target: button,
        preferredDirection: TooltipDirection.rightTop,
        title: '野堂',
        description:
            '''宋代：陆游\n\n野堂萧飒雪侵冠，历尽人间行路难。\n病马不收烟草暝，孤桐半落井床寒。\n长瓶浊酒犹堪醉，败箧残编更细看。\n此兴不随年共老，未容城角动忧端。''',
      );
    };
    button.onMouseExit = () {
      Tooltip.hide();
    };

    add(button);

    // status = StatusBar(size: Vector2(100, 20));
    // status.position = center;
    // add(status);
    // arrow = Arrow(sprite: Sprite(await Flame.images.load('arrow.png')));
    // add(arrow);

    // arrow.isVisible = false;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(border, PresetPaints.light);
  }

  @override
  void update(double dt) {}
}
