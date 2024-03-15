import 'dart:math';

import '../extensions.dart';

import '../scene/scene.dart';
import 'game_component.dart';
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

class Tooltip extends GameComponent {
  static final _tooltipInstance = Tooltip();

  static show({
    required Scene scene,
    required GameComponent target,
    TooltipDirection preferredDirection = TooltipDirection.topLeft,
    String? title,
    String? description,
  }) {
    assert(title != null || description != null);
    _tooltipInstance.setContent(title: title, description: description);

    // TODO: 检查是否超出了游戏屏幕
    switch (preferredDirection) {
      case TooltipDirection.topLeft:
        _tooltipInstance.position =
            Vector2(target.x, target.y - 10 - _tooltipInstance.height);
      case TooltipDirection.topCenter:
        _tooltipInstance.position = Vector2(
            target.x - (_tooltipInstance.width - target.width) / 2,
            target.y - 10 - _tooltipInstance.height);
      case TooltipDirection.topRight:
        _tooltipInstance.position = Vector2(
            target.x + target.width - _tooltipInstance.width,
            target.y - 10 - _tooltipInstance.height);
      case TooltipDirection.leftTop:
        _tooltipInstance.position =
            Vector2(target.x - 10 - _tooltipInstance.width, target.y);
      case TooltipDirection.leftCenter:
        _tooltipInstance.position = Vector2(
            target.x - 10 - _tooltipInstance.width,
            target.y - (_tooltipInstance.height - target.height) / 2);
      case TooltipDirection.leftBottom:
        _tooltipInstance.position = Vector2(
            target.x - 10 - _tooltipInstance.width,
            target.y + target.height - _tooltipInstance.height);
      case TooltipDirection.rightTop:
        _tooltipInstance.position =
            Vector2(target.x + target.width + 10, target.y);
      case TooltipDirection.rightCenter:
        _tooltipInstance.position = Vector2(target.x + target.width + 10,
            target.y - (_tooltipInstance.height - target.height) / 2);
      case TooltipDirection.rightBottom:
        _tooltipInstance.position = Vector2(target.x + target.width + 10,
            target.y + target.height - _tooltipInstance.height);
      case TooltipDirection.bottomLeft:
        _tooltipInstance.position =
            Vector2(target.x, target.y + target.height + 10);
      case TooltipDirection.bottomCenter:
        _tooltipInstance.position = Vector2(
            target.x - (_tooltipInstance.width - target.width) / 2,
            target.y + target.height + 10);
      case TooltipDirection.bottomRight:
        _tooltipInstance.position = Vector2(
            target.x + target.width - _tooltipInstance.width,
            target.y + target.height + 10);
    }
    scene.world.add(_tooltipInstance);
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
    assert(title != null || description != null);
    bool changed = false;
    if (_title != title || _description != description) changed = true;

    _title = title;
    _description = description?.replaceAllLineBreaks();

    if (changed) _calculateSize();
  }

  void _calculateSize() {
    if (_title == null && _description == null) return;

    final titleMetrics = _titleStyle.textPaint.getLineMetrics(_title!);
    final descriptionMetrics =
        _descriptionStyle.textPaint.getLineMetrics(_description!);

    double h = 0;
    if (titleMetrics.height != 0) {
      h = titleMetrics.height + 20;
    }

    if (descriptionMetrics.height != 0) {
      h += descriptionMetrics.height + 10;
    }

    size = Vector2(max(titleMetrics.width, descriptionMetrics.width) + 20, h);

    _titleStyle = _titleStyle.copyWith(rect: border);

    if (_description != null) {
      final descriptionRect = Rect.fromLTWH(0.0, titleMetrics.height + 10.0,
          width, height - titleMetrics.height - 10.0);

      _descriptionStyle = _descriptionStyle.copyWith(rect: descriptionRect);
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(border, backgroundPaint);

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
