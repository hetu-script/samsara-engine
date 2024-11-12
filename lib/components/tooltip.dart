import 'dart:math';

import '../extensions.dart';

import '../scene/scene.dart';
import 'game_component.dart';
import 'border_component.dart';
import '../paint/paint.dart';

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
  static Tooltip instance = Tooltip(maxWidth: 300.0);

  static void setTitleStyle(ScreenTextConfig config) {
    instance.titleConfig = config.copyWith(size: instance.size);
  }

  static void setDescriptionStyle(ScreenTextConfig config) {
    instance.descriptionConfig = config.copyWith(size: instance.size);
  }

  static show({
    required Scene scene,
    required GameComponent target,
    TooltipDirection preferredDirection = TooltipDirection.topLeft,
    String? title,
    String? description,
  }) {
    instance.removeFromParent();
    instance.setContent(title: title, description: description);

    final left = target.topLeftPosition.x;
    final top = target.topLeftPosition.y;
    // TODO: 检查是否超出了游戏屏幕
    switch (preferredDirection) {
      case TooltipDirection.topLeft:
        instance.position = Vector2(left, top - 10 - instance.height);
      case TooltipDirection.topCenter:
        instance.position = Vector2(left - (instance.width - target.width) / 2,
            top - 10 - instance.height);
      case TooltipDirection.topRight:
        instance.position = Vector2(
            left + target.width - instance.width, top - 10 - instance.height);
      case TooltipDirection.leftTop:
        instance.position = Vector2(left - 10 - instance.width, top);
      case TooltipDirection.leftCenter:
        instance.position = Vector2(left - 10 - instance.width,
            top - (instance.height - target.height) / 2);
      case TooltipDirection.leftBottom:
        instance.position = Vector2(
            left - 10 - instance.width, top + target.height - instance.height);
      case TooltipDirection.rightTop:
        instance.position = Vector2(left + target.width + 10, top);
      case TooltipDirection.rightCenter:
        instance.position = Vector2(left + target.width + 10,
            top - (instance.height - target.height) / 2);
      case TooltipDirection.rightBottom:
        instance.position = Vector2(
            left + target.width + 10, top + target.height - instance.height);
      case TooltipDirection.bottomLeft:
        instance.position = Vector2(left, top + target.height + 10);
      case TooltipDirection.bottomCenter:
        instance.position = Vector2(left - (instance.width - target.width) / 2,
            top + target.height + 10);
      case TooltipDirection.bottomRight:
        instance.position = Vector2(
            left + target.width - instance.width, top + target.height + 10);
    }
    scene.camera.viewport.add(instance);
  }

  static hide() => instance.removeFromParent();

  static const defaultTitleConfig = ScreenTextConfig(
      anchor: Anchor.topLeft,
      padding: EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
      textStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      overflow: ScreenTextOverflow.wordwrap);

  static const defaultDescriptionConfig = ScreenTextConfig(
      anchor: Anchor.topLeft,
      padding: EdgeInsets.only(bottom: 10.0, left: 10.0, right: 10.0),
      textStyle: TextStyle(fontSize: 24),
      overflow: ScreenTextOverflow.wordwrap);

  String? _title, _description;
  late ScreenTextConfig titleConfig, descriptionConfig;
  late TextPaint _titleTextPaint, _descriptionTextPaint;
  Rect _titleRect, _descriptionRect;

  late final Paint backgroundPaint;

  double? minWidth, maxWidth;

  Tooltip({
    String? title,
    String? description,
    ScreenTextConfig? titleConfig,
    ScreenTextConfig? descriptionConfig,
    super.size,
    super.anchor,
    super.position,
    super.opacity,
    Color? backgroundColor,
    super.borderRadius = 5.0,
    super.borderWidth = 5.0,
    super.borderPaint,
    this.minWidth,
    this.maxWidth,
  })  : _title = title,
        _titleRect = Rect.zero,
        _description = description,
        _descriptionRect = Rect.zero,
        super(priority: 9999999999) {
    if (minWidth != null && maxWidth != null) {
      assert(minWidth! <= maxWidth!);
    }

    this.titleConfig =
        (titleConfig ?? const ScreenTextConfig()).fillFrom(defaultTitleConfig);
    _titleTextPaint = getTextPaint(config: titleConfig);
    this.descriptionConfig = (descriptionConfig ?? const ScreenTextConfig())
        .fillFrom(defaultDescriptionConfig);
    _descriptionTextPaint = getTextPaint(config: descriptionConfig);

    _calculateSize();

    backgroundPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = backgroundColor ?? Colors.black.withOpacity(0.6);
  }

  void setContent({String? title, String? description}) {
    bool changed = false;
    if (_title != title || _description != description) changed = true;

    _title = title;
    _description = description?.replaceAllEscapedLineBreaks();

    if (changed) _calculateSize();
  }

  void _calculateSize() {
    if (_title == null && _description == null) return;

    double titleHeight = 0,
        titleWidth = 0,
        descriptionHeight = 0,
        descriptionWidth = 0;

    if (_title != null) {
      final titleMetrics = _titleTextPaint.getLineMetrics(_title!);
      titleHeight = titleMetrics.height + kTooltipContentIndent;
      titleWidth = titleMetrics.width;
      _titleRect = Rect.fromLTWH(0.0, 0.0, width, titleHeight);
    }

    if (_description != null) {
      final descriptionMetrics =
          _descriptionTextPaint.getLineMetrics(_description!);
      descriptionHeight = descriptionMetrics.height;
      descriptionWidth = descriptionMetrics.width;
    }

    double preferredWidth =
        max(titleWidth, descriptionWidth) + kTooltipContentIndent * 2;

    bool widthChanged = false;
    if (maxWidth != null) {
      double realMaxWidth = maxWidth! + kTooltipContentIndent * 2;
      if (preferredWidth > realMaxWidth) {
        preferredWidth = realMaxWidth;
        widthChanged = true;
      }
    } else if (minWidth != null && preferredWidth < minWidth!) {
      preferredWidth = minWidth!;
      widthChanged = true;
    }

    if (widthChanged) {
      // 重新计算高度
      if (_title != null) {
        final titleLines = getWrappedText(_title!,
            maxWidth: preferredWidth - kTooltipContentIndent * 2,
            textPaint: _titleTextPaint);
        titleHeight = getLinesHeight(titleLines.length, _titleTextPaint);
        _titleRect = Rect.fromLTWH(
          0,
          0,
          width,
          titleHeight,
        );
      }

      if (_description != null) {
        final descriptionLines = getWrappedText(_description!,
            maxWidth: preferredWidth - kTooltipContentIndent * 2,
            textPaint: _descriptionTextPaint);
        descriptionHeight =
            getLinesHeight(descriptionLines.length, _descriptionTextPaint);
      }
    }

    double preferredHeight =
        titleHeight + descriptionHeight + kTooltipContentIndent * 3;
    size = Vector2(preferredWidth, preferredHeight);

    titleConfig = titleConfig.copyWith(size: size);

    if (_description != null) {
      _descriptionRect = Rect.fromLTWH(
        0,
        titleHeight + kTooltipContentIndent * 2,
        width,
        height - titleHeight - kTooltipContentIndent * 2,
      );

      descriptionConfig =
          descriptionConfig.copyWith(size: _descriptionRect.size.toVector2());
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(roundBorder, borderPaint);
    canvas.drawRRect(roundBorder, backgroundPaint);

    if (_title != null) {
      drawScreenText(
        canvas,
        _title!,
        position: _titleRect.topLeft,
        textPaint: _titleTextPaint,
        config: titleConfig,
      );
    }
    if (_description != null) {
      drawScreenText(
        canvas,
        _description!,
        position: _descriptionRect.topLeft,
        textPaint: _descriptionTextPaint,
        config: descriptionConfig,
      );
    }
  }
}
