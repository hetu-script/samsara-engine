import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';
import 'package:flame/text.dart';
import 'package:hetu_script/utils/collection.dart';

import '../extensions.dart';
import 'card.dart';
import '../paint/paint.dart';
import '../richtext/richtext_builder.dart';

class CustomGameCard extends GameCard {
  /// 卡牌的原始数据，可能是一个Json，或者一个河图struct对象，
  /// 也可能是 null，例如资源牌这种情况。
  dynamic data;

  Vector2? preferredSize;

  String? title;

  String? _description;
  String? get description => _description;
  set description(String? value) {
    _description = value;
    _generateDescription();
  }

  DocumentRoot? _descriptionDocument;
  GroupElement? _descriptionElement;
  ScreenTextConfig? titleConfig;
  ScreenTextConfig? descriptionConfig;
  ScreenTextConfig? costNumberTextStyle;
  ScreenTextConfig? stackNumberTextStyle;

  bool showGlow;
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
  String? glowSpriteId;
  String? illustrationSpriteId;
  String? backSpriteId;
  String? stackIconSpriteId;
  String? costIconSpriteId;
  String? rarityIconSpriteId;
  Sprite? glowSprite;
  Sprite? illustrationSprite;
  Sprite? backSprite;
  Sprite? stackIconSprite;
  Sprite? costIconSprite;
  Sprite? rarityIconSprite;

  /// the relative padding of the illustration, the actual padding will be calculated from the size
  final EdgeInsets titleRelativePaddings;
  final EdgeInsets descriptionRelativePaddings;
  final EdgeInsets illustrationRelativePaddings;
  final EdgeInsets stackIconRelativePaddings;
  final EdgeInsets costIconRelativePaddings;
  final EdgeInsets rarityIconRelativePaddings;
  late Rect _titleRect;
  late Rect _descriptionRect;
  late Rect _illustrationRect;
  late Rect _stackIconRect;
  late Rect _costIconRect;
  late Rect _rarityIconRect;

  /// Wether this card is shown in a library (isFiltered == false) or not (isFiltered == true).
  bool isFiltered = false;

  CustomGameCard({
    required super.id,
    super.deckId,
    super.script,
    super.kind,
    super.enablePreview,
    this.data,
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
    super.onFocused,
    super.onUnfocused,
    super.onPreviewed,
    super.onUnpreviewed,
    super.anchor,
    this.preferredSize,
    this.title,
    String? description,
    this.titleConfig,
    this.descriptionConfig,
    this.illustrationSpriteId,
    this.illustrationSprite,
    this.backSpriteId,
    this.backSprite,
    this.glowSpriteId,
    this.glowSprite,
    this.stackIconSpriteId,
    this.stackIconSprite,
    this.costIconSpriteId,
    this.costIconSprite,
    this.rarityIconSpriteId,
    this.rarityIconSprite,
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
    this.showGlow = false,
    bool? showTitle,
    bool? showDescription,
    bool? showStackIcon,
    this.showStackNumber = false,
    bool? showCostIcon,
    this.showCostNumber = false,
    bool? showRarityIcon,
  })  : showTitle = showTitle ?? title != null,
        showDescription = showDescription ?? description != null,
        showStackIcon = (stackIconSpriteId != null || stackIconSprite != null),
        showCostIcon = (costIconSpriteId != null || costIconSprite != null),
        showRarityIcon =
            (rarityIconSpriteId != null || rarityIconSprite != null) {
    this.description = description;
  }

  /// 复制这个卡牌对象，但不会复制onTap之类的交互事件，也不会复制index属性
  @override
  CustomGameCard clone({bool deepCopyData = false}) {
    return CustomGameCard(
      id: id,
      deckId: deckId,
      script: script,
      kind: kind,
      enablePreview: enablePreview,
      // 拷贝的卡牌的底层数据也会被拷贝，这样在对局中可以修改卡牌的数据而不影响原始卡牌
      data: deepCopyData ? deepCopy(data) : data,
      ownedByRole: ownedByRole,
      stack: stack,
      spriteId: spriteId,
      sprite: sprite,
      tags: tags,
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
      preferredSize: preferredSize,
      title: title,
      description: _description,
      titleConfig: titleConfig,
      descriptionConfig: descriptionConfig,
      illustrationSpriteId: illustrationSpriteId,
      illustrationSprite: illustrationSprite,
      backSpriteId: backSpriteId,
      backSprite: backSprite,
      glowSpriteId: glowSpriteId,
      glowSprite: glowSprite,
      stackIconSpriteId: stackIconSpriteId,
      stackIconSprite: stackIconSprite,
      costIconSpriteId: costIconSpriteId,
      costIconSprite: costIconSprite,
      rarityIconSpriteId: rarityIconSpriteId,
      rarityIconSprite: rarityIconSprite,
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

  Future<void> tryLoadSprite({
    String? spriteId,
    String? illustrationSpriteId,
    String? backSpriteId,
    String? glowSpriteId,
    String? stackIconSpriteId,
    String? costIconSpriteId,
    String? rarityIconSpriteId,
  }) async {
    if (spriteId != null) {
      this.spriteId = spriteId;
    }
    if (this.spriteId != null) {
      sprite = Sprite(await Flame.images.load(this.spriteId!));
    }
    if (illustrationSpriteId != null) {
      this.illustrationSpriteId = illustrationSpriteId;
    }
    if (this.illustrationSpriteId != null) {
      illustrationSprite =
          Sprite(await Flame.images.load(this.illustrationSpriteId!));
    }
    if (backSpriteId != null) {
      this.backSpriteId = backSpriteId;
    }
    if (this.backSpriteId != null) {
      backSprite = Sprite(await Flame.images.load(this.backSpriteId!));
    }
    if (glowSpriteId != null) {
      this.glowSpriteId = glowSpriteId;
    }
    if (this.glowSpriteId != null) {
      glowSprite = Sprite(await Flame.images.load(this.glowSpriteId!));
    }
    if (stackIconSpriteId != null) {
      this.stackIconSpriteId = stackIconSpriteId;
    }
    if (this.stackIconSpriteId != null) {
      stackIconSprite =
          Sprite(await Flame.images.load(this.stackIconSpriteId!));
    }
    if (costIconSpriteId != null) {
      this.costIconSpriteId = costIconSpriteId;
    }
    if (this.costIconSpriteId != null) {
      costIconSprite = Sprite(await Flame.images.load(this.costIconSpriteId!));
    }
    if (rarityIconSpriteId != null) {
      this.rarityIconSpriteId = rarityIconSpriteId;
    }
    if (this.rarityIconSpriteId != null) {
      rarityIconSprite =
          Sprite(await Flame.images.load(this.rarityIconSpriteId!));
    }
  }

  @override
  void onLoad() async {
    super.onLoad();

    if (glowSpriteId != null) {
      glowSprite = Sprite(await Flame.images.load(glowSpriteId!));
    }
    if (illustrationSpriteId != null) {
      illustrationSprite =
          Sprite(await Flame.images.load(illustrationSpriteId!));
    }
    if (backSpriteId != null) {
      backSprite = Sprite(await Flame.images.load(backSpriteId!));
    }
  }

  void _generateDescription() {
    if (_description == null) return;

    double fontScale = preferredSize != null ? width / preferredSize!.x : 1.0;
    if (fontScale < 0) {
      fontScale = 0;
    }

    _descriptionDocument =
        buildFlameRichText(_description!, style: descriptionConfig?.textStyle);
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
      text: InlineTextStyle(fontScale: fontScale),
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
                (_descriptionRect.height - descriptionBoundingBox.height) / 2);
      case Anchor.center:
        _descriptionElement!.translate(
            _descriptionRect.left,
            _descriptionRect.top +
                (_descriptionRect.height - descriptionBoundingBox.height) / 2);
      case Anchor.centerRight:
        _descriptionElement!.translate(
            _descriptionRect.left,
            _descriptionRect.top +
                (_descriptionRect.height - descriptionBoundingBox.height) / 2);
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

  @override
  void generateBorder() {
    super.generateBorder();

    double fontScale = preferredSize != null ? width / preferredSize!.x : 1.0;
    if (fontScale < 0) {
      fontScale = 0;
    }

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
        .copyWith(size: _stackIconRect.size.toVector2(), scale: fontScale);

    costNumberTextStyle = (costNumberTextStyle ?? const ScreenTextConfig())
        .copyWith(size: _costIconRect.size.toVector2(), scale: fontScale);

    _titleRect = Rect.fromLTWH(
      titleRelativePaddings.left * width,
      titleRelativePaddings.top * height,
      width -
          (titleRelativePaddings.left + titleRelativePaddings.right) * width,
      height -
          (titleRelativePaddings.top + titleRelativePaddings.bottom) * height,
    );
    titleConfig = titleConfig?.copyWith(
        size: _titleRect.size.toVector2(), scale: fontScale);

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
        size: _descriptionRect.size.toVector2(), scale: fontScale);

    if (_description != null) {
      _generateDescription();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!isVisible) return;

    if (showGlow) {
      glowSprite?.renderRect(canvas, border, overridePaint: paint);
    }

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
