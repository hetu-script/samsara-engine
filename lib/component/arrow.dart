import 'package:flame/components.dart';
import 'package:samsara/samsara.dart';

class Arrow extends GameComponent {
  Sprite sprite;
  late final SpriteComponent sc;

  Offset fromPoint = Offset.zero;
  Offset toPoint = Offset.zero;

  Paint linePaint = Paint()
    ..color = const Color.fromARGB(255, 255, 0, 0)
    ..strokeWidth = 5.0;

  Arrow({
    required this.sprite,
    super.priority,
  });

  @override
  void onLoad() {
    sc = SpriteComponent(
      sprite: sprite,
      anchor: Anchor.bottomCenter,
    );
    add(sc);
  }

  void setPath(Vector2 fromPoint, Vector2 toPoint) {
    sc.position = toPoint;
    sc.lookAt(fromPoint);

    final offsetToPos =
        toPoint.moveAlongAngle(radians(90) + sc.angle, -sc.height);
    this.toPoint = offsetToPos.toOffset();

    this.fromPoint = fromPoint.toOffset();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawLine(fromPoint, toPoint, linePaint);
  }
}
