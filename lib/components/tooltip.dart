// import 'dart:math';
import 'dart:ui';

import '../extensions.dart';

import '../scene/scene.dart';
import 'game_component.dart';
import 'border_component.dart';
import '../paint/paint.dart';
import '../richtext.dart';

enum TooltipDirection {
  topLeft,
  topCenter,
  topRight,
  leftTop,
  leftCenter,
  leftBottom,
  rightTop,
  rightCenter,
  rightBottom,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

const kTooltipContentIndent = 10.0;
const kTooltipBackgroundBorderRadius = 5.0;

class Tooltip extends BorderComponent {
  static Tooltip instance = Tooltip();

  static const defaultContentConfig = ScreenTextConfig(
      anchor: Anchor.topLeft,
      padding: EdgeInsets.only(bottom: 10.0, left: 10.0, right: 10.0),
      textStyle: TextStyle(fontSize: 14.0),
      overflow: ScreenTextOverflow.wordwrap);

  static bool _doHide = false;

  static show({
    required Scene scene,
    required GameComponent target,
    String? content,
    ScreenTextConfig? config,
    TooltipDirection direction = TooltipDirection.topLeft,
    double width = 280.0,
  }) {
    _doHide = false;

    instance.removeFromParent();
    instance.setContent(content: content, config: config, width: width);

    final targetPosition = target.absoluteTopLeftPosition;
    final targetPositionGlobal = scene.camera.localToGlobal(targetPosition);
    final targetSizeGlobal = target.size * scene.camera.zoom;

    Vector2 calculatedPosition;
    switch (direction) {
      case TooltipDirection.topLeft:
        calculatedPosition = Vector2(
            targetSizeGlobal.x, targetPositionGlobal.y - 10 - instance.height);
      case TooltipDirection.topCenter:
        calculatedPosition = Vector2(
            targetPositionGlobal.x - (instance.width - targetSizeGlobal.x) / 2,
            targetPositionGlobal.y - 10 - instance.height);
      case TooltipDirection.topRight:
        calculatedPosition = Vector2(
            targetPositionGlobal.x + targetSizeGlobal.x - instance.width,
            targetPositionGlobal.y - 10 - instance.height);
      case TooltipDirection.leftTop:
        calculatedPosition = Vector2(
            targetPositionGlobal.x - 10 - instance.width,
            targetPositionGlobal.y);
      case TooltipDirection.leftCenter:
        calculatedPosition = Vector2(
            targetPositionGlobal.x - 10 - instance.width,
            targetPositionGlobal.y -
                (instance.height - targetSizeGlobal.y) / 2);
      case TooltipDirection.leftBottom:
        calculatedPosition = Vector2(
            targetPositionGlobal.x - 10 - instance.width,
            targetPositionGlobal.y + targetSizeGlobal.y - instance.height);
      case TooltipDirection.rightTop:
        calculatedPosition = Vector2(
            targetPositionGlobal.x + targetSizeGlobal.x + 10,
            targetPositionGlobal.y);
      case TooltipDirection.rightCenter:
        calculatedPosition = Vector2(
            targetPositionGlobal.x + targetSizeGlobal.x + 10,
            targetPositionGlobal.y -
                (instance.height - targetSizeGlobal.y) / 2);
      case TooltipDirection.rightBottom:
        calculatedPosition = Vector2(
            targetPositionGlobal.x + targetSizeGlobal.x + 10,
            targetPositionGlobal.y + targetSizeGlobal.y - instance.height);
      case TooltipDirection.bottomLeft:
        calculatedPosition = Vector2(targetPositionGlobal.x,
            targetPositionGlobal.y + targetSizeGlobal.y + 10);
      case TooltipDirection.bottomCenter:
        calculatedPosition = Vector2(
            targetPositionGlobal.x - (instance.width - targetSizeGlobal.x) / 2,
            targetPositionGlobal.y + targetSizeGlobal.y + 10);
      case TooltipDirection.bottomRight:
        calculatedPosition = Vector2(
            targetPositionGlobal.x + targetSizeGlobal.x - instance.width,
            targetPositionGlobal.y + targetSizeGlobal.y + 10);
    }

    // 检查是否超出了游戏屏幕
    if (calculatedPosition.x < 0) {
      calculatedPosition.x = 0;
    }
    if (calculatedPosition.y < 0) {
      calculatedPosition.y = 0;
    }
    if (calculatedPosition.x + instance.width > scene.camera.viewport.size.x) {
      calculatedPosition.x = scene.camera.viewport.size.x - instance.width;
    }
    if (calculatedPosition.y + instance.height > scene.camera.viewport.size.y) {
      calculatedPosition.y = scene.camera.viewport.size.y - instance.height;
    }

    instance.position = calculatedPosition;
    scene.camera.viewport.add(instance);
  }

  /// hide其实会等待半秒。
  /// 如果 50ms 之内没有其他代码执行show()，才会最终隐藏窗口。
  /// 这是为了避免某些时候不同Future中的的隐藏和显示窗口的命令互相冲突。
  static void hide() async {
    _doHide = true;
    await Future.delayed(Duration(milliseconds: 50));
    if (_doHide == true) {
      instance.removeFromParent();
    }
  }

  String _content = '';
  DocumentRoot? _contentDocument;
  GroupElement? _contentElement;
  late ScreenTextConfig contentConfig;
  // late TextPaint _contentPaint;

  late final Paint backgroundPaint;

  Tooltip({
    ScreenTextConfig? contentConfig,
    super.borderRadius = 5.0,
    super.borderWidth = 5.0,
    super.borderPaint,
  }) : super(priority: 9999999999) {
    this.contentConfig = (contentConfig ?? const ScreenTextConfig())
        .fillFrom(defaultContentConfig);
    // _contentPaint = getTextPaint(config: contentConfig);

    backgroundPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black.withAlpha(200);
  }

  void setContent(
      {String? content, ScreenTextConfig? config, required double width}) {
    final escapedContent = content?.replaceAllEscapedLineBreaks() ?? '';
    if (_content != escapedContent) {
      _content = escapedContent;
      contentConfig = contentConfig.copyFrom(config);
      _contentDocument =
          buildFlameRichText(escapedContent, style: contentConfig.textStyle);
      _calculateSize(width: width);
    }
  }

  void _calculateSize({required double width}) {
    if (_contentDocument == null) return;

    // double preferredHeight = contentHeight + kTooltipContentIndent * 2;
    // size = Vector2(preferredWidth, preferredHeight);

    // if (_content != null) {
    //   _contentRect = Rect.fromLTWH(
    //     kTooltipContentIndent,
    //     kTooltipContentIndent,
    //     width - kTooltipContentIndent * 2,
    //     height - kTooltipContentIndent * 2,
    //   );

    //   contentConfig =
    //       contentConfig.copyWith(size: _contentRect.size.toVector2());
    // }

    double contentWidth = width - kTooltipContentIndent * 2;
    final contentAnchor = contentConfig.anchor ?? Anchor.topLeft;
    TextAlign contentAlign = TextAlign.left;
    if (contentAnchor.x == 0.5) {
      contentAlign = TextAlign.center;
    } else if (contentAnchor.x == 1.0) {
      contentAlign = TextAlign.right;
    }

    _contentElement = _contentDocument!.format(DocumentStyle(
      paragraph: BlockStyle(margin: EdgeInsets.zero, textAlign: contentAlign),
      text: contentConfig.textStyle?.toInlineTextStyle(),
      width: contentWidth,
    ));
    final boundingBox = _contentElement!.boundingBox;
    size = Vector2(width, boundingBox.height + kTooltipContentIndent * 2);
    // 文本区域的左中右对齐已经由document.format的textAlign处理
    // 下面只是单独处理垂直方向的对齐
    switch (contentAnchor) {
      case Anchor.topLeft:
        _contentElement!
            .translate(kTooltipContentIndent, kTooltipContentIndent);
      case Anchor.topCenter:
        _contentElement!
            .translate(kTooltipContentIndent, kTooltipContentIndent);
      case Anchor.topRight:
        _contentElement!
            .translate(kTooltipContentIndent, kTooltipContentIndent);
      case Anchor.centerLeft:
        _contentElement!.translate(
            0, kTooltipContentIndent + (height - boundingBox.height) / 2);
      case Anchor.center:
        _contentElement!.translate(
            0, kTooltipContentIndent + (height - boundingBox.height) / 2);
      case Anchor.centerRight:
        _contentElement!.translate(
            0, kTooltipContentIndent + (height - boundingBox.height) / 2);
      case Anchor.bottomLeft:
        _contentElement!.translate(kTooltipContentIndent,
            height - kTooltipContentIndent - boundingBox.height);
      case Anchor.bottomCenter:
        _contentElement!.translate(kTooltipContentIndent,
            height - kTooltipContentIndent - boundingBox.height);
      case Anchor.bottomRight:
        _contentElement!.translate(kTooltipContentIndent,
            height - kTooltipContentIndent - boundingBox.height);
      default:
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(roundBorder, borderPaint);
    canvas.drawRRect(roundBorder, backgroundPaint);

    if (_contentElement != null) {
      _contentElement!.draw(canvas);
    }

    // if (_content != null) {
    //   drawScreenText(
    //     canvas,
    //     _content!,
    //     position: _contentRect.topLeft,
    //     textPaint: _contentPaint,
    //     config: contentConfig,
    //   );
    // }
  }
}
