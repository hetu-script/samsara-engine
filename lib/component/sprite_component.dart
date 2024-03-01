// ignore_for_file: implementation_imports

import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:meta/meta.dart';

import '../component/game_component.dart';

/// A modified version of [SpriteComponent] of Flame,
/// to provide round corners and borders for sprite component.
class SpriteComponent2 extends GameComponent {
  late final SpriteComponent _spriteComponent, _borderSpriteComponent;

  Sprite? sprite;
  String? spriteId;
  final bool useSpriteSrcSize;

  Sprite? borderSprite;
  String? borderSpriteId;

  SpriteComponent2({
    Image? image,
    Image? borderImage,
    this.sprite,
    this.spriteId,
    this.borderSprite,
    this.borderSpriteId,
    Paint? paint,
    Paint? borderPaint,
    this.useSpriteSrcSize = false,
    super.position,
    Vector2? size,
    super.scale,
    super.angle,
    super.anchor,
    super.priority,
    super.borderRadius = 0.0,
    super.opacity,
    super.children,
  }) : super(size: size) {
    assert(image != null || sprite != null || spriteId != null,
        'sprite component must have either image, sprite or spriteId.');
    assert(size != null || useSpriteSrcSize,
        'sprite component must explicitly be given a size or use the srcSize of the sprite.');
    if (image != null) {
      sprite = Sprite(image);
    }
    if (sprite != null) {
      _spriteComponent = SpriteComponent(
        sprite: sprite,
        size: size,
        paint: paint,
      );
      add(_spriteComponent);

      if (useSpriteSrcSize) {
        this.size = sprite!.srcSize;
      }
    }

    if (borderImage != null) {
      borderSprite = Sprite(borderImage);
    }
    if (borderSprite != null) {
      _borderSpriteComponent = SpriteComponent(
        sprite: borderSprite,
        size: size,
        paint: paint,
      );
      add(_borderSpriteComponent);
    }

    if (paint == null) {
      this.paint = Paint()
        ..filterQuality = FilterQuality.medium
        ..color = Colors.white.withOpacity(opacity);
    }

    this.size.addListener(() {
      _spriteComponent.size = this.size;
    });
  }

  @override
  set opacity(double value) {
    super.opacity = value;

    borderPaint.color = borderPaint.color.withOpacity(value);
  }

  @override
  void onLoad() async {
    if (spriteId != null && sprite == null) {
      sprite = Sprite(await Flame.images.load(spriteId!));
      _spriteComponent = SpriteComponent(
        sprite: sprite,
        size: size,
        paint: paint,
      );
      add(_spriteComponent);

      if (useSpriteSrcSize) {
        assert(sprite != null);
        size = sprite!.srcSize;
      }
    }
    if (borderSpriteId != null && borderSprite == null) {
      borderSprite = Sprite(await Flame.images.load(borderSpriteId!));
      _borderSpriteComponent = SpriteComponent(
        sprite: borderSprite,
        size: size,
        paint: paint,
      );
      add(_borderSpriteComponent);
    }
  }

  @mustCallSuper
  @override
  void render(Canvas canvas) {
    if (borderRadius > 0) {
      // canvas.clipRRect(clipRRect);
      canvas.clipRRect(rBorder);
    }
  }
}
