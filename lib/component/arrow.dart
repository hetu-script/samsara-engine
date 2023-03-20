import 'dart:async';

import 'package:flame/components.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/component/sprite_component.dart';

class Arrow extends GameComponent {
  Sprite sprite;
  late final SpriteComponent2 arrow;

  Offset fromPoint = Offset.zero;
  Offset toPoint = Offset.zero;

  Paint linePaint = Paint()
    ..color = const Color.fromARGB(255, 255, 0, 0)
    ..strokeWidth = 5.0;

  Arrow({required this.sprite});

  @override
  FutureOr<void> onLoad() {
    assert(parent is PositionComponent);

    size = (parent as PositionComponent).size;

    arrow = SpriteComponent2(
      sprite: sprite,
      anchor: Anchor.bottomCenter,
    );
    add(arrow);
  }

  void setPath(Vector2 fromPoint, Vector2 toPoint) {
    arrow.position = toPoint;
    arrow.lookAt(fromPoint);

    final offsetToPos =
        toPoint.moveAlongAngle(radians(90) + arrow.angle, -arrow.height);
    this.toPoint = offsetToPos.toOffset();

    this.fromPoint = fromPoint.toOffset();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawLine(fromPoint, toPoint, linePaint);
  }

  @override
  void renderTree(Canvas canvas) {
    if (isVisible) {
      super.renderTree(canvas);
    }
  }
}
