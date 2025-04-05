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

  Sprite? _sprite;
  String? _spriteId;
  String? get spriteId => _spriteId;
  final bool useSpriteSrcSize;

  Sprite? _borderSprite;
  String? _borderSpriteId;

  Sprite? _hoverSprite;
  String? _hoverSpriteId;

  Sprite? _pressSprite;
  String? _pressSpriteId;

  Sprite? _unselectedSprite;
  String? _unselectedSpriteId;

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
    Sprite? sprite,
    String? spriteId,
    this.useSpriteSrcSize = false,
    Sprite? borderSprite,
    String? borderSpriteId,
    Sprite? hoverSprite,
    String? hoverSpriteId,
    Sprite? pressSprite,
    String? pressSpriteId,
    Sprite? unselectedSprite,
    String? unselectedSpriteId,
    super.paint,
    Paint? hoverTintPaint,
    Paint? invalidPaint,
    // Paint? shadowPaint,
    this.useSimpleStyle = false,
    super.lightConfig,
    super.isVisible,
  })  : _borderSpriteId = borderSpriteId,
        _borderSprite = borderSprite,
        _hoverSpriteId = hoverSpriteId,
        _hoverSprite = hoverSprite,
        _pressSpriteId = pressSpriteId,
        _pressSprite = pressSprite,
        _unselectedSpriteId = unselectedSpriteId,
        _unselectedSprite = unselectedSprite,
        _spriteId = spriteId,
        _sprite = sprite {
    this.isEnabled = isEnabled;

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
        size = sprite.srcSize;
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
      _spriteId = spriteId;
    }
    if (_spriteId != null) {
      _sprite = Sprite(await Flame.images.load(_spriteId!));
    }
    if (useSpriteSrcSize && _sprite != null) {
      size = _sprite!.srcSize;
    }

    if (borderSpriteId != null) {
      _borderSpriteId = borderSpriteId;
    }
    if (_borderSpriteId != null) {
      _borderSprite = Sprite(await Flame.images.load(_borderSpriteId!));
    }
    if (hoverSpriteId != null) {
      _hoverSpriteId = hoverSpriteId;
    }
    if (_hoverSpriteId != null) {
      _hoverSprite = Sprite(await Flame.images.load(_hoverSpriteId!));
    }
    if (pressSpriteId != null) {
      _pressSpriteId = pressSpriteId;
    }
    if (_pressSpriteId != null) {
      _pressSprite = Sprite(await Flame.images.load(_pressSpriteId!));
    }
    if (unselectedSpriteId != null) {
      _unselectedSpriteId = unselectedSpriteId;
    }
    if (_unselectedSpriteId != null) {
      _unselectedSprite = Sprite(await Flame.images.load(_unselectedSpriteId!));
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
      if (_borderSprite != null) {
        _borderSprite?.render(canvas, size: size, overridePaint: paint);
      }
      if (isPressing) {
        if (useSimpleStyle) {
          canvas.drawRRect(
            roundBorder,
            PresetPaints.successFill,
          );
        } else if (_pressSprite != null) {
          _pressSprite?.render(canvas, size: size, overridePaint: paint);
        } else if (_hoverSprite != null) {
          _hoverSprite?.render(canvas, size: size, overridePaint: paint);
        } else {
          if (isSelectable && !isSelected) {
            _unselectedSprite?.render(canvas, size: size, overridePaint: paint);
          } else {
            _sprite?.render(canvas, size: size, overridePaint: paint);
          }
        }
      } else if (isHovering) {
        if (useSimpleStyle) {
          canvas.drawRRect(roundBorder, PresetPaints.lightGreenFill);
        } else if (_hoverSprite != null) {
          _hoverSprite?.render(canvas,
              size: size, overridePaint: hoverTintPaint);
        } else {
          if (isSelectable && !isSelected) {
            _unselectedSprite?.render(canvas,
                size: size, overridePaint: hoverTintPaint);
          } else {
            _sprite?.render(canvas, size: size, overridePaint: hoverTintPaint);
          }
        }
      } else {
        if (useSimpleStyle) {
          canvas.drawRRect(roundBorder, PresetPaints.successFill);
        } else {
          if (isSelectable && !isSelected) {
            _unselectedSprite?.render(canvas, size: size, overridePaint: paint);
          } else {
            _sprite?.render(canvas, size: size, overridePaint: paint);
          }
        }
      }
    } else {
      if (_borderSprite != null) {
        _borderSprite?.render(canvas, size: size, overridePaint: invalidPaint);
      }

      if (useSimpleStyle) {
        canvas.drawRRect(roundBorder, PresetPaints.invalidFill);
      } else {
        if (isSelectable && !isSelected) {
          _unselectedSprite?.render(canvas,
              size: size, overridePaint: invalidPaint);
        } else {
          _sprite?.render(canvas, size: size, overridePaint: invalidPaint);
        }
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
