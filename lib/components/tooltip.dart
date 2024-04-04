import 'dart:math';

import '../extensions.dart';

import '../scene/scene.dart';
import 'game_component.dart';
import 'border_component.dart';
import '../paint.dart';

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
  static final _tooltipInstance = Tooltip();

  static show({
    required Scene scene,
    required GameComponent target,
    TooltipDirection preferredDirection = TooltipDirection.topLeft,
    String? title,
    String? description,
  }) {
    _tooltipInstance.removeFromParent();
    _tooltipInstance.setContent(title: title, description: description);

    final left = target.topLeftPosition.x;
    final top = target.topLeftPosition.y;
    // TODO: 检查是否超出了游戏屏幕
    switch (preferredDirection) {
      case TooltipDirection.topLeft:
        _tooltipInstance.position =
            Vector2(left, top - 10 - _tooltipInstance.height);
      case TooltipDirection.topCenter:
        _tooltipInstance.position = Vector2(
            left - (_tooltipInstance.width - target.width) / 2,
            top - 10 - _tooltipInstance.height);
      case TooltipDirection.topRight:
        _tooltipInstance.position = Vector2(
            left + target.width - _tooltipInstance.width,
            top - 10 - _tooltipInstance.height);
      case TooltipDirection.leftTop:
        _tooltipInstance.position =
            Vector2(left - 10 - _tooltipInstance.width, top);
      case TooltipDirection.leftCenter:
        _tooltipInstance.position = Vector2(left - 10 - _tooltipInstance.width,
            top - (_tooltipInstance.height - target.height) / 2);
      case TooltipDirection.leftBottom:
        _tooltipInstance.position = Vector2(left - 10 - _tooltipInstance.width,
            top + target.height - _tooltipInstance.height);
      case TooltipDirection.rightTop:
        _tooltipInstance.position = Vector2(left + target.width + 10, top);
      case TooltipDirection.rightCenter:
        _tooltipInstance.position = Vector2(left + target.width + 10,
            top - (_tooltipInstance.height - target.height) / 2);
      case TooltipDirection.rightBottom:
        _tooltipInstance.position = Vector2(left + target.width + 10,
            top + target.height - _tooltipInstance.height);
      case TooltipDirection.bottomLeft:
        _tooltipInstance.position = Vector2(left, top + target.height + 10);
      case TooltipDirection.bottomCenter:
        _tooltipInstance.position = Vector2(
            left - (_tooltipInstance.width - target.width) / 2,
            top + target.height + 10);
      case TooltipDirection.bottomRight:
        _tooltipInstance.position = Vector2(
            left + target.width - _tooltipInstance.width,
            top + target.height + 10);
    }
    scene.camera.viewport.add(_tooltipInstance);
  }

  static hide() => _tooltipInstance.removeFromParent();

  static final defaultTitleStyle = ScreenTextStyle(
    anchor: Anchor.topLeft,
    padding: const EdgeInsets.only(top: 10.0, left: 10.0),
    colorTheme: ScreenTextColorTheme.light,
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  );

  static final defaultDescriptionStyle = ScreenTextStyle(
    anchor: Anchor.topLeft,
    padding: const EdgeInsets.only(top: 10.0, left: 10.0),
    colorTheme: ScreenTextColorTheme.light,
    textStyle: const TextStyle(fontSize: 16),
  );

  String? _title;
  late ScreenTextStyle _titleStyle;

  String? _description;
  late ScreenTextStyle _descriptionStyle;

  late final Paint backgroundPaint;

  Tooltip({
    String? title,
    String? description,
    ScreenTextStyle? titleStyle,
    ScreenTextStyle? descriptionStyle,
    super.size,
    super.anchor,
    super.position,
    super.opacity,
    Color? backgroundColor,
    super.borderRadius = 5.0,
    super.borderWidth = 5.0,
    super.borderPaint,
  })  : _title = title,
        _description = description,
        super(priority: 9999999999) {
    _titleStyle = titleStyle?.fillFrom(defaultTitleStyle) ?? defaultTitleStyle;
    _descriptionStyle = descriptionStyle?.fillFrom(defaultDescriptionStyle) ??
        defaultDescriptionStyle;

    _calculateSize();

    backgroundPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = backgroundColor ?? Colors.black.withOpacity(0.6);
  }

  void setContent({String? title, String? description}) {
    bool changed = false;
    if (_title != title || _description != description) changed = true;

    _title = title;
    _description = description?.replaceAllLineBreaks();

    if (changed) _calculateSize();
  }

  void _calculateSize() {
    if (_title == null && _description == null) return;

    double titleHeight = 0,
        titleWidth = 0,
        descriptionHeight = 0,
        descriptionWidth = 0;

    if (_title != null) {
      final titleMetrics = _titleStyle.textPaint.getLineMetrics(_title!);
      titleHeight = titleMetrics.height + kTooltipContentIndent;
      titleWidth = titleMetrics.width;
    }

    if (_description != null) {
      final descriptionMetrics =
          _descriptionStyle.textPaint.getLineMetrics(_description!);
      descriptionHeight = descriptionMetrics.height;
      descriptionWidth = descriptionMetrics.width;
    }

    size = Vector2(
        max(titleWidth, descriptionWidth) + kTooltipContentIndent * 2,
        titleHeight + descriptionHeight + kTooltipContentIndent * 2);

    _titleStyle = _titleStyle.copyWith(rect: border);

    if (_description != null) {
      final descriptionRect =
          Rect.fromLTWH(0.0, titleHeight, width, height - titleHeight);

      _descriptionStyle = _descriptionStyle.copyWith(rect: descriptionRect);
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
        style: _titleStyle,
      );
    }
    if (_description != null) {
      drawScreenText(
        canvas,
        _description!,
        style: _descriptionStyle,
      );
    }
  }
}
