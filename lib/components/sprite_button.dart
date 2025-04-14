import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:meta/meta.dart';

import 'border_component.dart';
import '../gestures.dart';
import '../paint/paint.dart';

class SpriteButton extends BorderComponent with HandlesGesture {
  static ScreenTextConfig defaultTextConfig =
      ScreenTextConfig(anchor: Anchor.center);

  late Paint hoverTintPaint, unselectedPaint, invalidPaint; // shadowPaint;

  Sprite? sprite;
  String? spriteId;
  final bool useSpriteSrcSize;

  Sprite? borderSprite;
  String? borderSpriteId;

  Sprite? hoverSprite;
  String? hoverSpriteId;

  Sprite? pressSprite;
  String? pressSpriteId;

  Sprite? unselectedSprite;
  String? unselectedSpriteId;

  String? text;
  late ScreenTextConfig textConfig;

  bool isEnabled;

  bool isSelectable;

  bool isSelected;

  void customRender(Canvas canvas) {}

  bool useSimpleStyle;

  SpriteButton({
    this.text,
    ScreenTextConfig? textConfig,
    super.size,
    super.anchor,
    super.priority,
    super.position,
    super.opacity,
    super.children,
    super.scale,
    super.angle,
    void Function(int buttons, Vector2 position)? onTap,
    super.borderRadius,
    this.isEnabled = true,
    this.isSelectable = false,
    this.isSelected = false,
    Image? image,
    this.useSpriteSrcSize = false,
    this.sprite,
    this.spriteId,
    this.borderSprite,
    this.borderSpriteId,
    this.hoverSprite,
    this.hoverSpriteId,
    this.pressSprite,
    this.pressSpriteId,
    this.unselectedSprite,
    this.unselectedSpriteId,
    super.paint,
    Paint? hoverTintPaint,
    Paint? invalidPaint,
    // Paint? shadowPaint,
    this.useSimpleStyle = false,
    super.lightConfig,
    super.isVisible,
  }) {
    if (textConfig != null) {
      this.textConfig =
          textConfig.fillFrom(defaultTextConfig).copyWith(size: size);
    } else {
      this.textConfig = defaultTextConfig.copyWith(size: size);
    }

    size.addListener(() {
      this.textConfig = this.textConfig.copyWith(size: size);
    });

    if (image != null) {
      sprite = Sprite(image);
    }
    if (sprite != null) {
      // _spriteComponent = SpriteComponent(
      //   sprite: sprite,
      //   size: size,
      //   paint: paint,
      // );

      if (useSpriteSrcSize) {
        size = sprite!.srcSize;
      }
    }

    // if (borderImage != null) {
    //   borderSprite = Sprite(borderImage);
    // }

    // if (hoverImage != null) {
    //   hoverSprite = Sprite(hoverImage);
    // }

    // if (pressImage != null) {
    //   pressSprite = Sprite(pressImage);
    // }

    this.hoverTintPaint = hoverTintPaint ?? Paint()
      ..filterQuality = FilterQuality.medium
      ..colorFilter = PresetFilters.brightness(0.3);
    setPaint('hoverTintPaint', this.hoverTintPaint);

    this.invalidPaint = invalidPaint ?? Paint()
      ..color = Colors.white.withAlpha(100)
      ..colorFilter = kColorFilterGreyscale;
    setPaint('invalidPaint', this.invalidPaint);

    // this.shadowPaint = shadowPaint ?? Paint()
    //   ..color = Colors.black.withAlpha(128)
    //   ..imageFilter = ImageFilter.blur(sigmaX: 0.3, sigmaY: 0.3);

    this.onTap = onTap;
  }

  Future<void> tryLoadSprite({
    String? spriteId,
    String? borderSpriteId,
    String? hoverSpriteId,
    String? pressSpriteId,
    String? unselectedSpriteId,
  }) async {
    if (spriteId != null) {
      this.spriteId = spriteId;
    }
    if (this.spriteId != null) {
      sprite = Sprite(await Flame.images.load(this.spriteId!));
      if (useSpriteSrcSize) {
        size = sprite!.srcSize;
      }
    }
    if (borderSpriteId != null) {
      this.borderSpriteId = borderSpriteId;
    }
    if (this.borderSpriteId != null) {
      borderSprite = Sprite(await Flame.images.load(this.borderSpriteId!));
    }
    if (hoverSpriteId != null) {
      this.hoverSpriteId = hoverSpriteId;
    }
    if (this.hoverSpriteId != null) {
      hoverSprite = Sprite(await Flame.images.load(this.hoverSpriteId!));
    }
    if (pressSpriteId != null) {
      this.pressSpriteId = pressSpriteId;
    }
    if (this.pressSpriteId != null) {
      pressSprite = Sprite(await Flame.images.load(this.pressSpriteId!));
    }
    if (unselectedSpriteId != null) {
      this.unselectedSpriteId = unselectedSpriteId;
    }
    if (this.unselectedSpriteId != null) {
      unselectedSprite =
          Sprite(await Flame.images.load(this.unselectedSpriteId!));
    }
  }

  @mustCallSuper
  @override
  void onLoad() async {
    await tryLoadSprite();
  }

  @override
  void render(Canvas canvas) {
    if (!isVisible) return;

    if (isEnabled) {
      borderSprite?.render(canvas, size: size, overridePaint: paint);
      if (isPressing) {
        if (useSimpleStyle) {
          canvas.drawRRect(
            roundBorder,
            PresetPaints.successFill,
          );
        } else if (pressSprite != null) {
          pressSprite?.render(canvas, size: size, overridePaint: paint);
        } else if (hoverSprite != null) {
          hoverSprite?.render(canvas, size: size, overridePaint: paint);
        } else {
          if (isSelectable && !isSelected) {
            unselectedSprite?.render(canvas, size: size, overridePaint: paint);
          } else {
            sprite?.render(canvas, size: size, overridePaint: paint);
          }
        }
      } else if (isHovering) {
        if (useSimpleStyle) {
          canvas.drawRRect(roundBorder, PresetPaints.lightGreenFill);
        } else if (hoverSprite != null) {
          hoverSprite?.render(canvas,
              size: size, overridePaint: hoverTintPaint);
        } else {
          if (isSelectable && !isSelected) {
            unselectedSprite?.render(canvas,
                size: size, overridePaint: hoverTintPaint);
          } else {
            sprite?.render(canvas, size: size, overridePaint: hoverTintPaint);
          }
        }
      } else {
        if (useSimpleStyle) {
          canvas.drawRRect(roundBorder, PresetPaints.successFill);
        } else {
          if (isSelectable && !isSelected) {
            unselectedSprite?.render(canvas, size: size, overridePaint: paint);
          } else {
            sprite?.render(canvas, size: size, overridePaint: paint);
          }
        }
      }
    } else {
      borderSprite?.render(canvas, size: size, overridePaint: invalidPaint);

      if (useSimpleStyle) {
        canvas.drawRRect(roundBorder, PresetPaints.invalidFill);
      } else {
        if (isSelectable && !isSelected) {
          unselectedSprite?.render(canvas,
              size: size, overridePaint: invalidPaint);
        } else {
          sprite?.render(canvas, size: size, overridePaint: invalidPaint);
        }
      }
    }

    if (text != null) {
      if (isEnabled) {
        drawScreenText(
          canvas,
          text!,
          config: textConfig,
        );
      } else {
        drawScreenText(
          canvas,
          text!,
          config: textConfig.copyWith(
            textStyle: textConfig.textStyle
                    ?.copyWith(color: Colors.grey.withAlpha(100)) ??
                TextStyle(color: Colors.grey.withAlpha(100)),
          ),
        );
      }
    }
  }
}
