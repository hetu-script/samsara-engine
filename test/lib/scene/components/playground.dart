import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';
// import 'package:samsara/component/sprite_component.dart';
// import 'package:samsara/effect/fade_effect.dart';
// import 'package:flame/effects.dart';
// import 'package:samsara/component/in_and_out_sprite.dart';

class PlayGround extends GameComponent with HandlesGesture {
  // late final StatusBar status;

  PlayGround({
    required double width,
    required double height,
  }) : super(size: Vector2(width, height)) {
    onTapDown = (int buttons, Vector2 position) {
      // final c = SpriteComponent2(spriteId: 'pepe.png', anchor: Anchor.center);
      // c.position = details.globalPosition.toVector2();
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
  }

  @override
  Future<void> onLoad() async {
    // status = StatusBar(size: Vector2(100, 20));
    // status.position = center;
    // add(status);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(border, DefaultBorderPaint.light);
  }
}
