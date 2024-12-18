import 'border_component.dart';
import '../paint/paint.dart';

class TextComponent2 extends BorderComponent {
  ScreenTextConfig config;

  late TextPaint _textPaint;

  String? _text;

  String? get text => _text;

  set text(String? value) {
    _text = value;

    if (_text != null) {
      final metrics = _textPaint.getLineMetrics(_text!);
      width = metrics.width;
      height = metrics.height;
    }
  }

  TextComponent2({
    super.anchor,
    super.position,
    super.priority,
    String? text,
    this.config = const ScreenTextConfig(),
  }) : _text = text {
    _textPaint = getTextPaint(config: config);
  }

  @override
  void render(Canvas canvas) {
    if (!isVisible || text == null) return;

    drawScreenText(canvas, text!, config: config);
  }
}
