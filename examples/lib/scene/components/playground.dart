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

    gameRef.fitScreen(size);

    onDragUpdate = (buttons, dragPosition, worldPosition) {
      gameRef.camera.moveTo(gameRef.camera.viewfinder.position - worldPosition);
    };
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(border, DefaultBorderPaint.light);
  }
}
