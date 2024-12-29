import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:meta/meta.dart';

import 'border_component.dart';
import '../gestures.dart';
import '../paint/paint.dart';

class SpriteButton extends BorderComponent with HandlesGesture {
  static const defaultTextConfig = ScreenTextConfig(
    anchor: Anchor.center,
    textStyle: TextStyle(fontSize: 16),
    outlined: true,
  );

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

  late bool _isEnabled;
  set isEnabled(bool value) {
    enableGesture = value;
    _isEnabled = value;
  }

  bool get isEnabled => _isEnabled;

  bool isSelectable;

  bool isSelected;

  void customRender(Canvas canvas) {}

  bool useDefaultRender;
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
    bool isEnabled = true,
    this.isSelectable = false,
    this.isSelected = false,
    Image? image,
    this.sprite,
    this.spriteId,
    this.useSpriteSrcSize = false,
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
    this.useDefaultRender = true,
    this.useSimpleStyle = false,
    super.lightConfig,
    super.isVisible,
  }) {
    this.isEnabled = isEnabled;

    if (textConfig != null) {
      this.textConfig =
          textConfig.fillFrom(defaultTextConfig).fillWith(size: size);
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
      // ..filterQuality = FilterQuality.medium
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

  Future<void> tryLoadSprite() async {
    if (spriteId != null) {
      sprite = Sprite(await Flame.images.load(spriteId!));

      if (useSpriteSrcSize) {
        assert(sprite != null);
        size = sprite!.srcSize;
      }
    }
    if (borderSpriteId != null) {
      borderSprite = Sprite(await Flame.images.load(borderSpriteId!));
    }
    if (hoverSpriteId != null) {
      hoverSprite = Sprite(await Flame.images.load(hoverSpriteId!));
    }
    if (pressSpriteId != null) {
      pressSprite = Sprite(await Flame.images.load(pressSpriteId!));
    }
    if (unselectedSpriteId != null) {
      unselectedSprite = Sprite(await Flame.images.load(unselectedSpriteId!));
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

    if (!useDefaultRender) {
      customRender(canvas);
    } else {
      if (isEnabled) {
        if (borderSprite != null) {
          borderSprite?.render(canvas, size: size, overridePaint: paint);
        }
        if (isPressing) {
          if (pressSprite != null) {
            pressSprite?.render(canvas, size: size, overridePaint: paint);
          } else if (hoverSprite != null) {
            hoverSprite?.render(canvas, size: size, overridePaint: paint);
          } else if (sprite != null) {
            if (isSelectable && !isSelected) {
              unselectedSprite?.render(canvas,
                  size: size, overridePaint: paint);
            } else {
              sprite?.render(canvas, size: size, overridePaint: paint);
            }
          } else if (useSimpleStyle) {
            canvas.drawRRect(
              roundBorder,
              PresetPaints.successFill,
            );
          }
        } else if (isHovering) {
          if (hoverSprite != null) {
            hoverSprite?.render(canvas,
                size: size, overridePaint: hoverTintPaint);
          } else if (sprite != null) {
            if (isSelectable && !isSelected) {
              unselectedSprite?.render(canvas,
                  size: size, overridePaint: hoverTintPaint);
            } else {
              sprite?.render(canvas, size: size, overridePaint: hoverTintPaint);
            }
          } else if (useSimpleStyle) {
            canvas.drawRRect(roundBorder, PresetPaints.lightGreenFill);
          }
        } else {
          if (sprite != null) {
            if (isSelectable && !isSelected) {
              unselectedSprite?.render(canvas,
                  size: size, overridePaint: paint);
            } else {
              sprite?.render(canvas, size: size, overridePaint: paint);
            }
          } else if (useSimpleStyle) {
            canvas.drawRRect(roundBorder, PresetPaints.successFill);
          }
        }
      } else {
        if (borderSprite != null) {
          borderSprite?.render(canvas, size: size, overridePaint: invalidPaint);
        }
        if (sprite != null) {
          if (isSelectable && !isSelected) {
            unselectedSprite?.render(canvas,
                size: size, overridePaint: invalidPaint);
          } else {
            sprite?.render(canvas, size: size, overridePaint: invalidPaint);
          }
        } else if (useSimpleStyle) {
          canvas.drawRRect(roundBorder, PresetPaints.invalidFill);
        }
      }

      if (text != null) {
        // if (isEnabled) {
        drawScreenText(
          canvas,
          text!,
          config: textConfig,
        );
        // } else {
        //   drawScreenText(
        //     canvas,
        //     text!,
        //     style: textStyle.copyWith(
        //       textStyle: textStyle.textStyle?.copyWith(
        //             color: Colors.grey.withOpacity(opacity),
        //           ) ??
        //           TextStyle(
        //             color: Colors.grey.withOpacity(opacity),
        //             fontSize: 12.0,
        //           ),
        //     ),
        //   );
        // }
      }
    }
  }
}
