import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:meta/meta.dart';

import 'game_component.dart';
import '../gestures.dart';
import '../paint.dart';

class SpriteButton extends GameComponent with HandlesGesture {
  static final defaultTextStyle = ScreenTextStyle(
    anchor: Anchor.center,
    colorTheme: ScreenTextColorTheme.light,
    textStyle: const TextStyle(fontSize: 16),
  );

  late Paint hoverTintPaint;
  late Paint invalidPaint;
  late Paint shadowPaint;

  Sprite? sprite;
  String? spriteId;
  final bool useSpriteSrcSize;

  Sprite? hoverSprite;
  String? hoverSpriteId;

  Sprite? pressSprite;
  String? pressSpriteId;

  String? title;
  late ScreenTextStyle textStyle;

  late bool _isEnabled;
  set isEnabled(bool value) {
    enableGesture = value;
    _isEnabled = value;
  }

  bool get isEnabled => _isEnabled;

  void Function()? onPressed;

  void renderClip(Canvas canvas) {}

  bool useDefaultRender;

  SpriteButton({
    this.title,
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
    this.onPressed,
    super.borderRadius,
    bool isEnabled = true,
    Image? image,
    this.sprite,
    this.spriteId,
    this.useSpriteSrcSize = false,
    Image? hoverImage,
    this.hoverSprite,
    this.hoverSpriteId,
    Image? pressImage,
    this.pressSprite,
    this.pressSpriteId,
    Paint? hoverTintPaint,
    Paint? invalidPaint,
    Paint? shadowPaint,
    this.useDefaultRender = true,
  }) {
    this.isEnabled = isEnabled;

    if (textStyle != null) {
      this.textStyle =
          textStyle.fillFrom(defaultTextStyle).fillWith(rect: border);
    } else {
      this.textStyle = defaultTextStyle.copyWith(rect: border);
    }

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

    this.invalidPaint = invalidPaint ?? Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..blendMode = BlendMode.luminosity;

    this.shadowPaint = shadowPaint ?? Paint()
      ..imageFilter = ImageFilter.blur(sigmaX: 0.3, sigmaY: 0.3);

    onTap = (buttons, position) {
      onPressed?.call();
    };
  }

  @mustCallSuper
  @override
  void onLoad() async {
    if (spriteId != null && sprite == null) {
      sprite = Sprite(await Flame.images.load(spriteId!));

      if (useSpriteSrcSize) {
        assert(sprite != null);
        size = sprite!.srcSize;
      }
    }
    if (hoverSpriteId != null && hoverSprite == null) {
      hoverSprite = Sprite(await Flame.images.load(hoverSpriteId!));
    }
    if (pressSpriteId != null && pressSprite == null) {
      pressSprite = Sprite(await Flame.images.load(pressSpriteId!));
    }
  }

  @override
  void render(Canvas canvas) {
    if (borderRadius > 0) {
      canvas.save();
      canvas.clipRRect(rrect);
    }

    if (useDefaultRender) {
      if (isEnabled) {
        if (isPressing) {
          if (pressSprite != null) {
            pressSprite?.render(canvas, size: size, overridePaint: paint);
          } else if (sprite != null) {
            sprite?.render(canvas, size: size, overridePaint: paint);
          } else {
            canvas.drawRRect(rrect, PresetPaints.successFill);
          }
        } else if (isHovering) {
          if (hoverSprite != null) {
            hoverSprite?.render(canvas,
                size: size, overridePaint: hoverTintPaint);
          } else if (sprite != null) {
            sprite?.render(canvas, size: size, overridePaint: hoverTintPaint);
          } else {
            canvas.drawRRect(rrect, PresetPaints.lightGreenFill);
          }
        } else {
          if (sprite != null) {
            sprite?.render(canvas, size: size, overridePaint: paint);
          } else {
            canvas.drawRRect(rrect, PresetPaints.successFill);
          }
        }
      } else {
        if (sprite != null) {
          sprite?.render(canvas, size: size, overridePaint: invalidPaint);
        } else {
          canvas.drawRRect(rrect, PresetPaints.invalidFill);
        }
      }

      if (title != null) {
        // if (isEnabled) {
        drawScreenText(
          canvas,
          title!,
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

    renderClip(canvas);

    if (borderRadius > 0) {
      canvas.restore();
    }
  }
}
