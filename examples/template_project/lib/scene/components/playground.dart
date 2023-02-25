import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';
import 'package:samsara/paint/paint.dart';

import '../../global.dart';

class PlayGround extends GameComponent with HandlesGesture {
  late Rect border;

  PlayGround({
    required double width,
    required double height,
  }) {
    width = width;
    height = height;
    generateBorder();
  }

  void generateBorder() {
    border = Rect.fromLTWH(0, 0, width, height);
  }

  void centerGame() {
    final gameViewPortSize = gameRef.size;
    engine.info('游戏界面可视区域大小：${gameViewPortSize.x}x${gameViewPortSize.y}');
    final padRatio = width / height;
    final sizeRatio = gameViewPortSize.x / gameViewPortSize.y;
    if (sizeRatio > padRatio) {
      // 可视区域更宽
      final scaleFactor = gameViewPortSize.y / height;
      scale = Vector2(scaleFactor, scaleFactor);
      final newWidth = width * scaleFactor;
      x = (gameViewPortSize.x - newWidth) / 2;
    } else {
      // 可视区域更窄
      final scaleFactor = gameViewPortSize.y / height;
      scale = Vector2(scaleFactor, scaleFactor);
      final newHeight = height * scaleFactor;
      y = (gameViewPortSize.y - newHeight) / 2;
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    centerGame();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(border, borderPaint);
  }

  @override
  void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
    gameRef.camera.snapTo(gameRef.camera.position - details.delta.toVector2());

    super.onDragUpdate(pointer, buttons, details);
  }
}
