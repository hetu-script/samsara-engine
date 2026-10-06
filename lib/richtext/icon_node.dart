// ignore: implementation_imports
import 'package:flame/src/text/nodes/inline_text_node.dart';
import 'package:flame/text.dart';
// import 'package:flutter/material.dart';
import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';

import '../samsara.dart';

/// An [InlineTextNode] representing an icon.
class InlineIconNode extends InlineTextNode {
  InlineIconNode({
    required this.spriteId,
    InlineTextStyle? style,
  }) {
    this.style = style ?? InlineTextStyle();
  }

  final String spriteId;

  @override
  void fillStyles(DocumentStyle stylesheet, InlineTextStyle parentTextStyle) {
    style = parentTextStyle.copyWith(style);
  }

  @override
  TextNodeLayoutBuilder get layoutBuilder => _InlineIconLayoutBuilder(this);
}

class _InlineIconLayoutBuilder extends TextNodeLayoutBuilder {
  _InlineIconLayoutBuilder(this.node);

  final InlineIconNode node;

  bool _isDone = false;

  @override
  bool get isDone => _isDone;

  @override
  InlineIconElement? layOutNextLine(
    double availableWidth, {
    required bool isStartOfLine,
  }) {
    if (_isDone) return null;
    _isDone = true;
    // 图标高度与文字渲染尺寸一致，见 inline_text_style2.dart 的换算公式
    final style = node.style;
    final height = (style.fontSize ?? 16.0) * (style.fontScale ?? 1.0);
    return InlineIconElement(node.spriteId, height: height);
  }
}

/// [InlineIconElement] is a class that represents a single icon,
/// prepared for rendering.
class InlineIconElement extends InlineTextElement {
  InlineIconElement(String spriteId, {required double height})
    : sprite = Sprite(Flame.images.fromCache(spriteId)) {
    final srcSize = sprite.srcSize;
    _size = Vector2(srcSize.x * (height / srcSize.y), height);
    // baseline 为 0、ascent 为图标全高：图标底部与文字基线对齐
    _box = LineMetrics(ascent: height, width: _size.x);
  }

  final Sprite sprite;
  late final Vector2 _size;
  late final LineMetrics _box;

  @override
  LineMetrics get metrics => _box;

  /// Moves the element by ([dx], [dy]) relative to its current location.
  @override
  void translate(double dx, double dy) {
    _box.translate(dx, dy);
  }

  /// Renders the element on the [canvas], at coordinates determined during the
  /// layout.
  @override
  void draw(Canvas canvas) {
    sprite.render(canvas, position: Vector2(_box.left, _box.top), size: _size);
  }
}
