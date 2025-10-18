import 'package:samsara/gestures.dart';

import '../border_component.dart';
import '../../paint/paint.dart';
import '../../extensions.dart';
import '../../richtext.dart';

class RichTextComponent extends BorderComponent with HandlesGesture {
  ScreenTextConfig config;

  String? _text;
  DocumentRoot? _ducument;
  GroupElement? _outlinedElement;
  GroupElement? _element;

  String? get text => _text;

  RichTextComponent({
    super.size,
    super.position,
    super.anchor,
    super.isVisible,
    super.priority,
    String? text,
    this.config = const ScreenTextConfig(),
    bool enableGesture = false,
  }) {
    this.text = text;
    this.enableGesture = enableGesture;
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
        config.copyWith(size: size);
        _ducument = buildFlameRichText(escapedContent, style: config.textStyle);

        final contentAnchor = config.anchor ?? Anchor.topLeft;
        TextAlign contentAlign = TextAlign.left;
        if (contentAnchor.x == 0.5) {
          contentAlign = TextAlign.center;
        } else if (contentAnchor.x == 1.0) {
          contentAlign = TextAlign.right;
        }
        // TODO: 将这部分代码同意挪到一个element的extension上
        _element = _ducument!.format(DocumentStyle(
          paragraph:
              BlockStyle(margin: EdgeInsets.zero, textAlign: contentAlign),
          text: config.textStyle?.toInlineTextStyle(),
          width: width,
          height: height,
        ));
        if (config.outlined == true) {
          _outlinedElement = _ducument!.format(DocumentStyle(
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
            _outlinedElement?.translate(0, 0);
          case Anchor.topCenter:
            _element!.translate(0, 0);
            _outlinedElement?.translate(0, 0);
          case Anchor.topRight:
            _element!.translate(0, 0);
            _outlinedElement?.translate(0, 0);
          case Anchor.centerLeft:
            _element!.translate(0, (height - boundingBox.height) / 2);
            _outlinedElement?.translate(0, (height - boundingBox.height) / 2);
          case Anchor.center:
            _element!.translate(0, (height - boundingBox.height) / 2);
            _outlinedElement?.translate(0, (height - boundingBox.height) / 2);
          case Anchor.centerRight:
            _element!.translate(0, (height - boundingBox.height) / 2);
            _outlinedElement?.translate(0, (height - boundingBox.height) / 2);
          case Anchor.bottomLeft:
            _element!.translate(0, height - boundingBox.height);
            _outlinedElement?.translate(0, height - boundingBox.height);
          case Anchor.bottomCenter:
            _element!.translate(0, height - boundingBox.height);
            _outlinedElement?.translate(0, height - boundingBox.height);
          case Anchor.bottomRight:
            _element!.translate(0, height - boundingBox.height);
            _outlinedElement?.translate(0, height - boundingBox.height);
          default:
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!isVisible || text == null) return;

    _outlinedElement?.draw(canvas);
    _element?.draw(canvas);
  }
}
