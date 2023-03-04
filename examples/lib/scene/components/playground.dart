import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';

class PlayGround extends GameComponent with HandlesGesture {
  PlayGround({
    required double width,
    required double height,
  }) : super(size: Vector2(width, height));

  @override
  Future<void> onLoad() async {
    super.onLoad();

    fitScreen();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(border, DefaultBorderPaint.light);
  }

  @override
  void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
    gameRef.camera.snapTo(gameRef.camera.position - details.delta.toVector2());

    super.onDragUpdate(pointer, buttons, details);
  }
}
