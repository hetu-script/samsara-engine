import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:samsara/components/border_component.dart';
import 'package:samsara/extensions.dart';

import 'card.dart';
import '../types.dart';
import '../paint/paint.dart';
import '../rich_text_builder.dart';

class CustomGameCard extends GameCard {
  Vector2? preferredSize;

  String? title, description;
  List<TextSpan>? richDescription;
  ScreenTextConfig? titleConfig,
      descriptionConfig,
      costNumberTextStyle,
      stackNumberTextStyle;

  bool showTitle;
  bool showDescription;
  bool showStackIcon;
  bool showStackNumber;
  bool showCostIcon;
  bool showCostNumber;
  bool showRarityIcon;

  final int cost;
  int modifiedCost;

  /// the sprite id of this card, should be unique among all cards
  final String? illustrationSpriteId,
      backSpriteId,
      stackIconSpriteId,
      costIconSpriteId,
      rarityIconSpriteId;
  Sprite? illustrationSprite,
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
    required super.deckId,
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
    super.anchor,
    super.focusAnimationDuration,
    super.onFocused,
    super.onUnfocused,
    super.onPreviewed,
    super.onUnpreviewed,
    this.preferredSize,
    this.title,
    this.description,
    String? richDescription,
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
    bool? showStackIcon,
    this.showStackNumber = false,
    bool? showCostIcon,
    this.showCostNumber = false,
    bool? showRarityIcon,
  })  : showTitle = showTitle ?? title != null,
        showDescription =
            showDescription ?? description != null || richDescription != null,
        showStackIcon = (stackIconSpriteId != null || stackIconSprite != null),
        showCostIcon = (costIconSpriteId != null || costIconSprite != null),
        showRarityIcon =
            (rarityIconSpriteId != null || rarityIconSprite != null) {
    if (richDescription != null) {
      this.richDescription =
          buildRichText(richDescription, style: descriptionConfig?.textStyle);
    }
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
      anchor: anchor,
      focusAnimationDuration: focusAnimationDuration,
      preferredSize: preferredSize,
      title: title,
      description: description,
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
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.clipRect(border);

    if (isFlipped) {
      backSprite?.renderRect(canvas, border);
    } else {
      illustrationSprite?.renderRect(canvas, _illustrationRect,
          overridePaint: isEnabled ? paint : invalidPaint);
      sprite?.renderRect(canvas, border,
          overridePaint: isEnabled ? paint : invalidPaint);

      if (showTitle && title != null && title?.isNotEmpty == true) {
        drawScreenText(canvas, title!,
            position: _titleRect.topLeft, config: titleConfig);
      }

      if (showDescription) {
        if (description != null && description?.isNotEmpty == true) {
          drawScreenText(canvas, description!,
              position: _descriptionRect.topLeft, config: descriptionConfig);
        } else if (richDescription != null) {
          drawScreenRichText(
            canvas,
            richDescription!,
            position: _descriptionRect.topLeft,
            config: descriptionConfig,
            // debugMode: true,
          );
        }
      }

      if (showRarityIcon) {
        rarityIconSprite?.renderRect(canvas, _rarityIconRect,
            overridePaint: isEnabled ? paint : invalidPaint);
      }

      if (stack > 1) {
        if (showStackIcon) {
          stackIconSprite?.renderRect(canvas, _stackIconRect,
              overridePaint: isEnabled ? paint : invalidPaint);
        }

        if (showStackNumber) {
          drawScreenText(canvas, '×$stack',
              position: _stackIconRect.topLeft, config: stackNumberTextStyle);
        }
      }

      if (cost > 0) {
        if (showCostIcon) {
          costIconSprite?.renderRect(canvas, _costIconRect,
              overridePaint: isEnabled ? paint : invalidPaint);
        }

        if (showCostNumber) {
          drawScreenText(canvas, '$cost',
              position: _costIconRect.topLeft, config: costNumberTextStyle);
        }
      }
    }

    canvas.restore();
  }
}
