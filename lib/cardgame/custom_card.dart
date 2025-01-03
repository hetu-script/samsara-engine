import 'dart:ui';

import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';
import 'package:flame/text.dart';

import '../components/border_component.dart';
import '../extensions.dart';
import 'card.dart';
import '../types.dart';
import '../paint/paint.dart';
import '../richtext/richtext_builder.dart';

class CustomGameCard extends GameCard {
  Vector2? preferredSize;

  String? title, description, extraDescription;
  double extraDescriptionWidth;
  DocumentRoot? _descriptionDocument;
  GroupElement? _descriptionElement;
  ScreenTextConfig? titleConfig,
      descriptionConfig,
      costNumberTextStyle,
      stackNumberTextStyle;

  bool showTitle;
  bool showDescription;
  bool showExtraDescription;
  bool showStackIcon;
  bool showStackNumber;
  bool showCostIcon;
  bool showCostNumber;
  bool showRarityIcon;

  final int cost;
  int modifiedCost;

  /// the sprite id of this card, should be unique among all cards
  final String? maskSpriteId,
      illustrationSpriteId,
      backSpriteId,
      stackIconSpriteId,
      costIconSpriteId,
      rarityIconSpriteId;
  Sprite? maskSprite,
      illustrationSprite,
      backSprite,
      stackIconSprite,
      costIconSprite,
      rarityIconSprite;

  /// the relative padding of the illustration, the actual padding will be calculated from the size
  final EdgeInsets illustrationRelativePaddings,
      rarityIconRelativePaddings,
      titleRelativePaddings,
      descriptionRelativePaddings,
      stackIconRelativePaddings,
      costIconRelativePaddings;
  late Rect _illustrationRect,
      _rarityIconRect,
      _stackIconRect,
      _costIconRect,
      _titleRect,
      _descriptionRect;

  CustomGameCard({
    required super.id,
    super.deckId,
    super.script,
    super.kind,
    super.enablePreview,
    super.data,
    super.ownedByRole,
    super.stack,
    super.spriteId,
    super.sprite,
    super.tags,
    super.priority,
    super.position,
    super.size,
    super.borderRadius,
    super.focusedOffset,
    super.focusedPosition,
    super.focusedSize,
    super.focusedPriority,
    super.focusOnPreviewing,
    super.showBorder,
    super.isFocused,
    super.stayFocused,
    super.isFlipped,
    super.isRotated,
    super.isRotatable,
    super.isEnabled,
    super.anchor,
    super.focusAnimationDuration,
    super.onFocused,
    super.onUnfocused,
    super.onPreviewed,
    super.onUnpreviewed,
    this.preferredSize,
    this.title,
    this.description,
    this.extraDescription,
    this.extraDescriptionWidth = 280.0,
    this.maskSpriteId,
    this.maskSprite,
    this.illustrationSpriteId,
    this.illustrationSprite,
    this.backSpriteId,
    this.backSprite,
    this.stackIconSpriteId,
    this.stackIconSprite,
    this.costIconSpriteId,
    this.costIconSprite,
    this.rarityIconSpriteId,
    this.rarityIconSprite,
    this.titleConfig,
    this.descriptionConfig,
    this.costNumberTextStyle,
    this.stackNumberTextStyle,
    this.cost = 0,
    this.modifiedCost = 0,
    this.illustrationRelativePaddings = EdgeInsets.zero,
    this.rarityIconRelativePaddings = EdgeInsets.zero,
    this.titleRelativePaddings = EdgeInsets.zero,
    this.descriptionRelativePaddings = EdgeInsets.zero,
    this.stackIconRelativePaddings = EdgeInsets.zero,
    this.costIconRelativePaddings = EdgeInsets.zero,
    bool? showTitle,
    bool? showDescription,
    bool? showExtraDescription,
    bool? showStackIcon,
    this.showStackNumber = false,
    bool? showCostIcon,
    this.showCostNumber = false,
    bool? showRarityIcon,
  })  : showTitle = showTitle ?? title != null,
        showDescription = showDescription ?? description != null,
        showExtraDescription = showExtraDescription ?? extraDescription != null,
        showStackIcon = (stackIconSpriteId != null || stackIconSprite != null),
        showCostIcon = (costIconSpriteId != null || costIconSprite != null),
        showRarityIcon =
            (rarityIconSpriteId != null || rarityIconSprite != null) {
    // if (extraDescription != null) {
    //   _extraDescriptionDocument = buildFlameRichText(extraDescription!,
    //       style: descriptionConfig?.textStyle);
    // }
  }

  /// 复制这个卡牌对象，但不会复制onTap之类的交互事件，也不会复制index属性
  @override
  CustomGameCard clone() {
    return CustomGameCard(
      id: id,
      deckId: deckId,
      script: script,
      kind: kind,
      enablePreview: enablePreview,
      data: data,
      ownedByRole: ownedByRole,
      sprite: sprite,
      tags: tags,
      stack: stack,
      priority: priority,
      position: position,
      size: size,
      borderRadius: borderRadius,
      focusedOffset: focusedOffset,
      focusedPosition: focusedPosition,
      focusedSize: focusedSize,
      focusedPriority: focusedPriority,
      focusOnPreviewing: focusOnPreviewing,
      showBorder: showBorder,
      isFocused: isFocused,
      stayFocused: stayFocused,
      isFlipped: isFlipped,
      isRotated: isRotated,
      isRotatable: isRotatable,
      isEnabled: isEnabled,
      anchor: anchor,
      focusAnimationDuration: focusAnimationDuration,
      preferredSize: preferredSize,
      title: title,
      description: description,
      extraDescription: extraDescription,
      extraDescriptionWidth: extraDescriptionWidth,
      illustrationSpriteId: illustrationSpriteId,
      illustrationSprite: illustrationSprite,
      backSpriteId: backSpriteId,
      backSprite: backSprite,
      stackIconSpriteId: stackIconSpriteId,
      stackIconSprite: stackIconSprite,
      costIconSpriteId: costIconSpriteId,
      costIconSprite: costIconSprite,
      rarityIconSpriteId: rarityIconSpriteId,
      rarityIconSprite: rarityIconSprite,
      titleConfig: titleConfig,
      descriptionConfig: descriptionConfig,
      costNumberTextStyle: costNumberTextStyle,
      stackNumberTextStyle: stackNumberTextStyle,
      cost: cost,
      modifiedCost: modifiedCost,
      illustrationRelativePaddings: illustrationRelativePaddings,
      rarityIconRelativePaddings: rarityIconRelativePaddings,
      titleRelativePaddings: titleRelativePaddings,
      descriptionRelativePaddings: descriptionRelativePaddings,
      stackIconRelativePaddings: stackIconRelativePaddings,
      costIconRelativePaddings: costIconRelativePaddings,
      showTitle: showTitle,
      showDescription: showDescription,
      showExtraDescription: showExtraDescription,
      showStackIcon: showStackIcon,
      showStackNumber: showStackNumber,
      showCostIcon: showCostIcon,
      showCostNumber: showCostNumber,
      showRarityIcon: showRarityIcon,
    );
  }

  @override
  void onLoad() async {
    super.onLoad();

    if (maskSpriteId != null) {
      maskSprite = Sprite(await Flame.images.load(maskSpriteId!));
    }
    if (illustrationSpriteId != null) {
      illustrationSprite =
          Sprite(await Flame.images.load(illustrationSpriteId!));
    }
    if (backSpriteId != null) {
      backSprite = Sprite(await Flame.images.load(backSpriteId!));
    }
    // if (countDecorSpriteId != null) {
    //   countDecorSprite =
    //       Sprite(await Flame.images.load('$countDecorSpriteId.png'));
    // }
  }

  @override
  void generateBorder() {
    super.generateBorder();

    _illustrationRect = Rect.fromLTWH(
      illustrationRelativePaddings.left * width,
      illustrationRelativePaddings.top * height,
      width -
          (illustrationRelativePaddings.left +
                  illustrationRelativePaddings.right) *
              width,
      height -
          (illustrationRelativePaddings.top +
                  illustrationRelativePaddings.bottom) *
              height,
    );

    _rarityIconRect = Rect.fromLTWH(
      rarityIconRelativePaddings.left * width,
      rarityIconRelativePaddings.top * height,
      width -
          (rarityIconRelativePaddings.left + rarityIconRelativePaddings.right) *
              width,
      height -
          (rarityIconRelativePaddings.top + rarityIconRelativePaddings.bottom) *
              height,
    );

    _stackIconRect = Rect.fromLTWH(
      stackIconRelativePaddings.left * width,
      stackIconRelativePaddings.top * height,
      width -
          (stackIconRelativePaddings.left + stackIconRelativePaddings.right) *
              width,
      height -
          (stackIconRelativePaddings.top + stackIconRelativePaddings.bottom) *
              height,
    );

    _costIconRect = Rect.fromLTWH(
      costIconRelativePaddings.left * width,
      costIconRelativePaddings.top * height,
      width -
          (costIconRelativePaddings.left + costIconRelativePaddings.right) *
              width,
      height -
          (costIconRelativePaddings.top + costIconRelativePaddings.bottom) *
              height,
    );

    stackNumberTextStyle = (stackNumberTextStyle ?? const ScreenTextConfig())
        .copyWith(
            size: _stackIconRect.size.toVector2(),
            scale: preferredSize != null ? width / preferredSize!.x : 1.0);

    costNumberTextStyle = (costNumberTextStyle ?? const ScreenTextConfig())
        .copyWith(
            size: _costIconRect.size.toVector2(),
            scale: preferredSize != null ? width / preferredSize!.x : 1.0);

    _titleRect = Rect.fromLTWH(
      titleRelativePaddings.left * width,
      titleRelativePaddings.top * height,
      width -
          (titleRelativePaddings.left + titleRelativePaddings.right) * width,
      height -
          (titleRelativePaddings.top + titleRelativePaddings.bottom) * height,
    );
    titleConfig = titleConfig?.copyWith(
        size: _titleRect.size.toVector2(),
        scale: preferredSize != null ? width / preferredSize!.x : 1.0);

    _descriptionRect = Rect.fromLTWH(
      descriptionRelativePaddings.left * width,
      descriptionRelativePaddings.top * height,
      width -
          (descriptionRelativePaddings.left +
                  descriptionRelativePaddings.right) *
              width,
      height -
          (descriptionRelativePaddings.top +
                  descriptionRelativePaddings.bottom) *
              height,
    );
    descriptionConfig = descriptionConfig?.copyWith(
        size: _descriptionRect.size.toVector2(),
        scale: preferredSize != null ? width / preferredSize!.x : 1.0);

    if (description != null) {
      _descriptionDocument =
          buildFlameRichText(description!, style: descriptionConfig?.textStyle);
      final descriptionAnchor = descriptionConfig?.anchor ?? Anchor.topLeft;
      TextAlign descriptionAlign = TextAlign.left;
      if (descriptionAnchor.x == 0.5) {
        descriptionAlign = TextAlign.center;
      } else if (descriptionAnchor.x == 1.0) {
        descriptionAlign = TextAlign.right;
      }

      _descriptionElement = _descriptionDocument!.format(DocumentStyle(
        paragraph:
            BlockStyle(margin: EdgeInsets.zero, textAlign: descriptionAlign),
        text: InlineTextStyle(
            fontScale: preferredSize != null ? width / preferredSize!.x : 1.0),
        width: _descriptionRect.width,
        height: _descriptionRect.height,
      ));
      final descriptionBoundingBox = _descriptionElement!.boundingBox;
      // 文本区域的左中右对齐已经由document.format的textAlign处理
      // 下面只是单独处理垂直方向的对齐
      switch (descriptionAnchor) {
        case Anchor.topLeft:
          _descriptionElement!
              .translate(_descriptionRect.left, _descriptionRect.top);
        case Anchor.topCenter:
          _descriptionElement!
              .translate(_descriptionRect.left, _descriptionRect.top);
        case Anchor.topRight:
          _descriptionElement!
              .translate(_descriptionRect.left, _descriptionRect.top);
        case Anchor.centerLeft:
          _descriptionElement!.translate(
              _descriptionRect.left,
              _descriptionRect.top +
                  (_descriptionRect.height - descriptionBoundingBox.height) /
                      2);
        case Anchor.center:
          _descriptionElement!.translate(
              _descriptionRect.left,
              _descriptionRect.top +
                  (_descriptionRect.height - descriptionBoundingBox.height) /
                      2);
        case Anchor.centerRight:
          _descriptionElement!.translate(
              _descriptionRect.left,
              _descriptionRect.top +
                  (_descriptionRect.height - descriptionBoundingBox.height) /
                      2);
        case Anchor.bottomLeft:
          _descriptionElement!.translate(_descriptionRect.left,
              _descriptionRect.bottom - descriptionBoundingBox.height);
        case Anchor.bottomCenter:
          _descriptionElement!.translate(_descriptionRect.left,
              _descriptionRect.bottom - descriptionBoundingBox.height);
        case Anchor.bottomRight:
          _descriptionElement!.translate(_descriptionRect.left,
              _descriptionRect.bottom - descriptionBoundingBox.height);
        default:
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (isFlipped) {
      backSprite?.renderRect(canvas, border);
    } else {
      illustrationSprite?.renderRect(canvas, _illustrationRect,
          overridePaint: paint);
      sprite?.renderRect(canvas, border, overridePaint: paint);

      if (showTitle && title != null && title?.isNotEmpty == true) {
        drawScreenText(canvas, title!,
            alpha: isEnabled ? 255 : 128,
            position: _titleRect.topLeft,
            config: titleConfig);
      }

      if (showDescription) {
        if (_descriptionElement != null) {
          _descriptionElement!.draw(canvas);
        }
      }

      if (showRarityIcon) {
        rarityIconSprite?.renderRect(canvas, _rarityIconRect,
            overridePaint: paint);
      }

      if (stack > 1) {
        if (showStackIcon) {
          stackIconSprite?.renderRect(canvas, _stackIconRect,
              overridePaint: paint);
        }

        if (showStackNumber) {
          drawScreenText(canvas, '×$stack',
              alpha: isEnabled ? 255 : 128,
              position: _stackIconRect.topLeft,
              config: stackNumberTextStyle);
        }
      }

      if (cost > 0) {
        if (showCostIcon) {
          costIconSprite?.renderRect(canvas, _costIconRect,
              overridePaint: paint);
        }

        if (showCostNumber) {
          drawScreenText(canvas, '$cost',
              alpha: isEnabled ? 255 : 128,
              position: _costIconRect.topLeft,
              config: costNumberTextStyle);
        }
      }
    }
  }
}
