import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:meta/meta.dart';

import 'border_component.dart';
import '../gestures.dart';
import '../paint.dart';

class SpriteButton extends BorderComponent with HandlesGesture {
  static final defaultTextStyle = ScreenTextStyle(
    anchor: Anchor.center,
    colorTheme: ScreenTextColorTheme.light,
    textStyle: const TextStyle(fontSize: 16),
    outlined: true,
  );

  late Paint hoverTintPaint, darkenedPaint, invalidPaint, shadowPaint;

  Sprite? sprite;
  String? spriteId;
  final bool useSpriteSrcSize;

  Sprite? borderSprite;
  String? borderSpriteId;

  Sprite? hoverSprite;
  String? hoverSpriteId;

  Sprite? pressSprite;
  String? pressSpriteId;

  String? text;
  late ScreenTextStyle textStyle;

  late bool _isEnabled;
  set isEnabled(bool value) {
    enableGesture = value;
    _isEnabled = value;
  }

  bool isDarkened;

  bool get isEnabled => _isEnabled;

  void customRender(Canvas canvas) {}

  bool useDefaultRender;
  bool useSimpleStyle;

  SpriteButton({
    this.text,
    ScreenTextStyle? textStyle,
    super.size,
    super.anchor,
    super.priority,
    super.position,
    super.opacity,
    super.children,
    super.paint,
    super.scale,
    super.angle,
    void Function(int buttons, Vector2 position)? onTap,
    super.borderRadius,
    bool isEnabled = true,
    this.isDarkened = false,
    Image? image,
    this.sprite,
    this.spriteId,
    this.useSpriteSrcSize = false,
    Image? borderImage,
    this.borderSprite,
    this.borderSpriteId,
    Image? hoverImage,
    this.hoverSprite,
    this.hoverSpriteId,
    Image? pressImage,
    this.pressSprite,
    this.pressSpriteId,
    Paint? hoverTintPaint,
    Paint? darkenedPaint,
    Paint? invalidPaint,
    Paint? shadowPaint,
    this.useDefaultRender = true,
    this.useSimpleStyle = false,
    super.lightConfig,
    super.isVisible,
  }) {
    this.isEnabled = isEnabled;

    if (textStyle != null) {
      this.textStyle =
          textStyle.fillFrom(defaultTextStyle).fillWith(rect: border);
    } else {
      this.textStyle = defaultTextStyle.copyWith(rect: border);
    }

    size.addListener(() {
      this.textStyle =
          this.textStyle.copyWith(rect: Rect.fromLTWH(0, 0, size.x, size.y));
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

    if (borderImage != null) {
      borderSprite = Sprite(borderImage);
    }

    if (hoverImage != null) {
      hoverSprite = Sprite(hoverImage);
    }

    if (pressImage != null) {
      pressSprite = Sprite(pressImage);
    }

    this.hoverTintPaint = hoverTintPaint ?? Paint()
      ..filterQuality = FilterQuality.medium
      ..color = Colors.white.withOpacity(opacity)
      ..colorFilter = PredefinedFilters.brightness(0.3);
    setPaint('hoverTintPaint', this.hoverTintPaint);

    this.darkenedPaint = darkenedPaint ?? Paint()
      ..color = Colors.black
      ..blendMode = BlendMode.luminosity;
    setPaint('darkenedPaint', this.darkenedPaint);

    this.invalidPaint = invalidPaint ?? Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..blendMode = BlendMode.luminosity;

    this.shadowPaint = shadowPaint ?? Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..imageFilter = ImageFilter.blur(sigmaX: 0.3, sigmaY: 0.3);

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
  }

  @mustCallSuper
  @override
  void onLoad() async {
    await tryLoadSprite();
  }

  @override
  void render(Canvas canvas) {
    if (!isVisible) return;

    if (borderRadius > 0) {
      canvas.save();
      canvas.clipRRect(roundBorder);
    }

    if (!useDefaultRender) {
      customRender(canvas);
    } else {
      if (isEnabled) {
        if (borderSprite != null) {
          borderSprite?.render(canvas,
              size: size, overridePaint: isDarkened ? darkenedPaint : paint);
        }
        if (isPressing) {
          if (pressSprite != null) {
            pressSprite?.render(canvas,
                size: size, overridePaint: isDarkened ? darkenedPaint : paint);
          } else if (hoverSprite != null) {
            hoverSprite?.render(canvas,
                size: size, overridePaint: isDarkened ? darkenedPaint : paint);
          } else if (sprite != null) {
            sprite?.render(canvas,
                size: size, overridePaint: isDarkened ? darkenedPaint : paint);
          } else if (useSimpleStyle) {
            canvas.drawRRect(roundBorder, PresetPaints.successFill);
          }
        } else if (isHovering) {
          if (hoverSprite != null) {
            hoverSprite?.render(canvas,
                size: size, overridePaint: hoverTintPaint);
          } else if (sprite != null) {
            sprite?.render(canvas, size: size, overridePaint: hoverTintPaint);
          } else if (useSimpleStyle) {
            canvas.drawRRect(roundBorder, PresetPaints.lightGreenFill);
          }
        } else {
          if (sprite != null) {
            sprite?.render(canvas,
                size: size, overridePaint: isDarkened ? darkenedPaint : paint);
          } else if (useSimpleStyle) {
            canvas.drawRRect(roundBorder, PresetPaints.successFill);
          }
        }
      } else {
        if (borderSprite != null) {
          if (opacity != 1) {
            borderSprite?.render(canvas, size: size, overridePaint: paint);
          } else {
            borderSprite?.render(canvas,
                size: size, overridePaint: invalidPaint);
          }
        }
        if (sprite != null) {
          if (opacity != 1) {
            sprite?.render(canvas, size: size, overridePaint: paint);
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
          style: textStyle,
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

    if (borderRadius > 0) {
      canvas.restore();
    }
  }
}
