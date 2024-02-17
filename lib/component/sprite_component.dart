// ignore_for_file: implementation_imports

import 'dart:ui';

import 'package:flame/components.dart' hide SpriteComponent;
import 'package:flame/flame.dart';
import 'package:meta/meta.dart';

import '../component/game_component.dart';

/// A modified version of [SpriteComponent2] of Flame.
class SpriteComponent2 extends GameComponent {
  static Paint defaultPaint = Paint()
    ..filterQuality = FilterQuality.medium
    ..color = Colors.white;

  Sprite? sprite;

  String? spriteId;

  SpriteComponent2({
    Image? image,
    Vector2? srcPosition,
    Vector2? srcSize,
    this.sprite,
    this.spriteId,
    Paint? paint,
    super.position,
    Vector2? size,
    super.scale,
    super.angle,
    super.anchor,
    super.priority,
    super.children,
  }) {
    assert(image != null || sprite != null || spriteId != null,
        'sprite component must have either image, sprite or spriteId.');
    if (image != null) {
      sprite = Sprite(image, srcPosition: srcPosition, srcSize: srcSize);
    }

    if (size == null) {
      if (sprite != null) {
        this.size = sprite!.srcSize;
      }
    } else {
      this.size = size;
    }

    if (paint != null) {
      this.paint = paint;
    }
  }

  @override
  void onLoad() async {
    if (spriteId != null) {
      sprite = Sprite(await Flame.images.load(spriteId!));
      size = sprite!.srcSize;
    }
  }

  @mustCallSuper
  @override
  void render(Canvas canvas) {
    sprite?.renderRect(
      canvas,
      border,
      overridePaint: defaultPaint,
    );
  }
}
