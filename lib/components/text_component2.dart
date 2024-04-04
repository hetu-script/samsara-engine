import 'package:samsara/components/border_component.dart';
import 'package:samsara/paint.dart';

class TextComponent2 extends BorderComponent {
  static final defaultStyle =
      ScreenTextStyle(textPaint: PresetTextPaints.light);

  String? _text;

  String? get text => _text;

  set text(String? value) {
    _text = value;

    if (_text != null) {
      final metrics = style.textPaint.getLineMetrics(_text!);
      width = metrics.width;
      height = metrics.height;
    }
  }

  late final ScreenTextStyle style;

  TextComponent2({
    super.anchor,
    super.position,
    super.priority,
    String? text,
    ScreenTextStyle? style,
  }) : _text = text {
    if (style != null) {
      this.style = defaultStyle.copyFrom(style);
    } else {
      this.style = defaultStyle;
    }
  }

  @override
  void render(Canvas canvas) {
    if (!isVisible || text == null) return;

    drawScreenText(canvas, text!, style: style);
  }
}
