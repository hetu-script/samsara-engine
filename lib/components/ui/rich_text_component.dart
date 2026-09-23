import 'package:samsara/gestures.dart';

import '../../richtext.dart';
import '../../samsara.dart';

class RichTextComponent extends BorderComponent with HandlesGesture {
  ScreenTextConfig config;

  String? _text;
  DocumentRoot? _ducument;
  GroupElement? _outline;
  GroupElement? _element;

  double fontScale;

  String? get text => _text;

  void layout({
    String? text,
    double? width,
    double? height,
    double? fontScale,
  }) {
    final t = text ?? _text;
    if (t == null) return;

    if (width != null) this.width = width;
    if (height != null) this.height = height;
    if (fontScale != null) this.fontScale = fontScale;

    _text = null; // 绕过 setter 的去重判断
    text = t;
  }

  double? get textAreaHeight => _element?.height;

  Color? _backgroundColor;
  Color? get backgroundColor => _backgroundColor;
  Paint _backgroundPaint = Paint()..color = Colors.transparent;
  set backgroundColor(Color? value) {
    _backgroundColor = value;

    _backgroundPaint = Paint()..color = value ?? Colors.transparent;
  }

  RichTextComponent({
    super.size,
    super.position,
    super.anchor,
    super.isVisible,
    super.priority,
    String? text,
    this.fontScale = 1.0,
    this.config = const ScreenTextConfig(),
    bool enableGesture = false,
    Color? backgroundColor,
  }) {
    this.text = text;
    this.enableGesture = enableGesture;
    this.backgroundColor = backgroundColor;
  }

  set text(String? value) {
    if (value == null) {
      _text = null;
      _ducument = null;
      _element = null;
    } else {
      final escapedContent = value.replaceAllEscapedLineBreaks();
      if (_text != escapedContent) {
        _text = escapedContent;
        _ducument = buildFlameRichText(escapedContent, style: config.textStyle);

        final contentAnchor = config.anchor ?? Anchor.topLeft;
        TextAlign contentAlign = config.textAlign ?? TextAlign.left;
        final inlineTextStyle = (config.textStyle ?? TextStyle())
            .copyWith()
            .toInlineTextStyle(fontScale: fontScale);
        // TODO: 将这部分代码同意挪到一个element的extension上
        _element = _ducument!.format(DocumentStyle(
          paragraph:
              BlockStyle(margin: EdgeInsets.zero, textAlign: contentAlign),
          text: inlineTextStyle,
          width: width,
          height: height,
        ));
        if (config.outlined == true) {
          _outline = _ducument!.format(DocumentStyle(
            paragraph:
                BlockStyle(margin: EdgeInsets.zero, textAlign: contentAlign),
            text: (config.textStyle ?? TextStyle())
                .copyWith(
                  foreground: Paint()
                    ..strokeWidth = 2.5
                    ..color = Colors.black
                    ..style = PaintingStyle.stroke,
                )
                .toInlineTextStyle(),
            width: width,
            height: height,
          ));
        }
        final boundingBox = _element!.boundingBox;
        // 文本区域的左中右对齐已经由document.format的textAlign处理
        // 下面只是单独处理垂直方向的对齐
        switch (contentAnchor) {
          case Anchor.topLeft:
            _element!.translate(0, 0);
            _outline?.translate(0, 0);
          case Anchor.topCenter:
            _element!.translate(0, 0);
            _outline?.translate(0, 0);
          case Anchor.topRight:
            _element!.translate(0, 0);
            _outline?.translate(0, 0);
          case Anchor.centerLeft:
            _element!.translate(0, (height - boundingBox.height) / 2);
            _outline?.translate(0, (height - boundingBox.height) / 2);
          case Anchor.center:
            _element!.translate(0, (height - boundingBox.height) / 2);
            _outline?.translate(0, (height - boundingBox.height) / 2);
          case Anchor.centerRight:
            _element!.translate(0, (height - boundingBox.height) / 2);
            _outline?.translate(0, (height - boundingBox.height) / 2);
          case Anchor.bottomLeft:
            _element!.translate(0, height - boundingBox.height);
            _outline?.translate(0, height - boundingBox.height);
          case Anchor.bottomCenter:
            _element!.translate(0, height - boundingBox.height);
            _outline?.translate(0, height - boundingBox.height);
          case Anchor.bottomRight:
            _element!.translate(0, height - boundingBox.height);
            _outline?.translate(0, height - boundingBox.height);
          default:
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!isVisible || text == null) return;

    canvas.drawRect(border, _backgroundPaint);
    _outline?.draw(canvas);
    _element?.draw(canvas);
  }

  void renderAt(Canvas canvas, Offset offset) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    canvas.drawRect(border, _backgroundPaint);
    _outline?.draw(canvas);
    _element?.draw(canvas);

    canvas.restore();
  }
}
