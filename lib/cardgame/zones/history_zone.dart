import '../../component/game_component.dart';
import '../../gestures.dart';
import '../../paint.dart';

class HistoryZone extends GameComponent with HandlesGesture {
  final String? title;

  ScreenTextStyle? titleStyle;

  final Anchor titleAnchor;
  final EdgeInsets titlePadding;

  HistoryZone({
    super.id,
    this.title,
    required double x,
    required double y,
    required double width,
    required double height,
    super.borderRadius = 5.0,
    this.titleAnchor = Anchor.topLeft,
    this.titlePadding = EdgeInsets.zero,
  }) : super(
          position: Vector2(x, y),
          size: Vector2(width, height),
        ) {
    titleStyle = ScreenTextStyle(
      rect: border,
      anchor: titleAnchor,
      padding: titlePadding,
    );
  }

  @override
  void generateBorder() {
    super.generateBorder();

    titleStyle = titleStyle?.copyWith(rect: border);
  }

  @override
  void render(Canvas canvas) {
    if (title != null) {
      drawScreenText(canvas, title!, style: titleStyle);
    }

    canvas.drawRRect(rborder, DefaultBorderPaint.light);
  }
}
