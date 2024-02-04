import 'dart:async';

import 'package:flame/components.dart' hide Timer;
import 'package:flame/effects.dart';
import 'package:flame/flame.dart';

import '../component/game_component.dart';
import '../scene/scene.dart';
import 'timer.dart';

class InAndOutSprite extends GameComponent {
  final String spriteId;
  Sprite? sprite;

  final double flyInDuration, stayDuration, flyOutDuration;

  void Function()? onComplete;

  InAndOutSprite(
    this.spriteId, {
    super.size,
    required this.flyInDuration,
    required this.stayDuration,
    required this.flyOutDuration,
    super.priority = 10000,
    this.onComplete,
  }) : super(anchor: Anchor.center);

  @override
  FutureOr<void> onLoad() async {
    sprite = Sprite(await Flame.images.load('$spriteId.png'));

    if (size == Vector2.zero()) {
      size = sprite!.srcSize;
    }

    Vector2 startPos, stayPos, endPos;

    if (parent is World) {
      final middleLine = game.size.y / 2;
      startPos = Vector2(game.size.x + width / 2, middleLine);
      stayPos = game.center;
      endPos = Vector2(-width / 2, middleLine);
    } else if (parent is PositionComponent) {
      final p = parent as PositionComponent;
      final middleLine = p.size.y / 2;
      startPos = Vector2(p.size.x + width / 2, middleLine);
      stayPos = p.center;
      endPos = Vector2(-width / 2, middleLine);
    } else {
      throw 'it\'s not support to add a InAndOutSprite component into a non PositionComponent!';
    }

    position = startPos;

    add(MoveEffect.to(
      stayPos,
      EffectController(
        curve: Curves.easeIn,
        duration: flyInDuration,
      ),
      onComplete: () {
        add(Timer(
          stayDuration,
          onComplete: () {
            add(MoveEffect.to(
                endPos,
                EffectController(
                  curve: Curves.easeIn,
                  duration: flyInDuration,
                ), onComplete: () {
              removeFromParent();
              onComplete?.call();
            }));
          },
        ));
      },
    ));
  }

  @override
  void render(Canvas canvas) {
    sprite?.renderRect(canvas, border);
  }
}
