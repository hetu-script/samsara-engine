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

  @override
  bool get isDone => true;

  @override
  InlineIconElement? layOutNextLine(
    double availableWidth, {
    required bool isStartOfLine,
  }) {
    return InlineIconElement(node.spriteId);
  }
}

/// [InlineIconElement] is a class that represents a single icon,
/// prepared for rendering.
class InlineIconElement extends InlineTextElement {
  InlineIconElement(String spriteId) {
    sprite = Sprite(Flame.images.fromCache(spriteId));
  }

  Vector2 position = Vector2.zero();

  late Sprite sprite;

  @override
  LineMetrics get metrics {
    return LineMetrics(
      width: sprite.srcSize.x,
      height: sprite.srcSize.y,
    );
  }

  @override
  void render(
    Canvas canvas,
    Vector2 position, {
    Anchor anchor = Anchor.topLeft,
  }) {
    final box = metrics;
    translate(
      position.x - box.width * anchor.x,
      position.y - box.height * anchor.y - box.top,
    );
    draw(canvas);
  }

  /// Moves the element by ([dx], [dy]) relative to its current location.
  @override
  void translate(double dx, double dy) {
    position.translate(dx, dy);
  }

  /// Renders the element on the [canvas], at coordinates determined during the
  /// layout.
  ///
  /// In order to render the element at a different location, consider either
  /// calling the [translate] method, or applying a translation transform to the
  /// canvas itself.
  @override
  void draw(Canvas canvas) {
    sprite.render(canvas, position: position);
  }

  @override
  Rect get boundingBox => metrics.toRect();
}
