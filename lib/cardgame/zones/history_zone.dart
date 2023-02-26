import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';

import '../../paint/paint.dart';

class HistoryZone extends GameComponent with HandlesGesture {
  final String? id;
  final String? title;

  final Anchor titleAnchor;

  HistoryZone({
    this.id,
    this.title,
    required double x,
    required double y,
    required double width,
    required double height,
    super.borderRadius = 5.0,
    this.titleAnchor = Anchor.topLeft,
  }) : super(
          position: Vector2(x, y),
          size: Vector2(width, height),
        );

  @override
  void render(Canvas canvas) {
    if (title != null) {
      drawScreenText(
        canvas,
        title!,
        rect: border,
        anchor: titleAnchor,
        marginLeft: 10,
        marginTop: -10,
        marginRight: 10,
        marginBottom: -10,
      );
    }

    canvas.drawRRect(rborder, borderPaint);
  }
}
