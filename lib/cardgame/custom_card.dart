import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';
import 'package:hetu_script/utils/collection.dart';

import 'card.dart';
import '../samsara.dart';
import '../components/ui/rich_text_component.dart';

/// 卡牌标题的排列方式
enum CardTitleLayout {
  /// 顶部横排
  horizontalTop,

  /// 从右上角向下竖排
  verticalRightTop,
}

/// 彩色费用图标的排列方向
enum ColoredCostDirection {
  up,
  down,
  left,
  right,
}

/// 彩色费用图标的布局方式
enum ColoredCostLayout {
  /// 平铺：几点费用就画几个图标
  pips,

  /// 紧凑：每种颜色只画一个图标，图标上写数量数字
  compact,
}

class CustomGameCard extends GameCard {
  /// 颜色id -> 费用图标的注册表，所有卡牌共享
  static final Map<String, Sprite> coloredCostSprites = {};

  /// 注册一个颜色的费用图标，spriteId 和 sprite 必须提供其中一个
  static Future<void> registerColoredCostSprite(
    String colorId, {
    String? spriteId,
    Sprite? sprite,
  }) async {
    assert(spriteId != null || sprite != null);
    coloredCostSprites[colorId] =
        sprite ?? Sprite(await Flame.images.load(spriteId!));
  }

  static void unregisterColoredCostSprite(String colorId) {
    coloredCostSprites.remove(colorId);
  }

  /// 卡牌的原始数据，可能是一个Json，或者一个河图struct对象，
  /// 也可能是 null，例如资源牌这种情况。
  dynamic data;

  Vector2? preferredSize;

  String? _title;
  String? _verticalTitle;
  String? get title => _title;
  set title(String? value) {
    _title = value;
    _verticalTitle = value?.split('').join('\n');
  }

  String? _description;
  String? get description => _description;
  set description(String? value) {
    _description = value;
    _generateDescription();
  }

  final RichTextComponent _descriptionComponent = RichTextComponent();

  ScreenTextConfig? titleConfig;
  ScreenTextConfig? descriptionConfig;
  ScreenTextConfig? costNumberTextConfig;
  ScreenTextConfig? stackNumberTextConfig;
  ScreenTextConfig? coloredCostNumberTextConfig;

  bool showGlow;
  bool showTitle;
  bool showDescription;

  CardTitleLayout titleLayout;
  bool showStackIcon;
  bool showStackNumber;
  bool showCostIcon;
  bool showCostNumber;
  bool showColoredCost;
  bool showRarityIcon;
  bool showGenreIcon;

  final int cost;
  int modifiedCost;

  /// the sprite id of this card, should be unique among all cards
  String? glowSpriteId;
  String? illustrationSpriteId;
  String? backSpriteId;
  String? stackIconSpriteId;
  String? costIconSpriteId;
  String? rarityIconSpriteId;
  String? genreIconSpriteId;
  String? descriptionBackgroundSpriteId;

  Sprite? glowSprite;
  Color? glowColor;
  Sprite? illustrationSprite;
  Sprite? backSprite;
  Sprite? stackIconSprite;
  Sprite? costIconSprite;
  Sprite? rarityIconSprite;
  Sprite? genreIconSprite;
  Sprite? descriptionBackgroundSprite;

  /// the relative padding of the illustration, the actual padding will be calculated from the size
  final Rect titleRelativeRect;
  final Rect descriptionRelativeRect;
  final Rect illustrationRelativeRect;
  final Rect stackIconRelativeRect;
  final Rect costIconRelativeRect;
  final Rect rarityIconRelativeRect;
  final Rect genreIconRelativeRect;

  /// 彩色费用第一个图标的相对位置，其余图标沿 coloredCostDirection
  /// 按 coloredCostIconMargin 的间隔依次排列
  final Rect coloredCostIconRelativeRect;
  final ColoredCostDirection coloredCostDirection;

  /// 相邻彩色费用图标的间隔，实际间隔会随卡牌缩放
  final double coloredCostIconMargin;

  /// 彩色费用图标的布局方式（平铺 pip 或紧凑单图标 + 数字）
  final ColoredCostLayout coloredCostLayout;
  late Rect _titleRect;
  late Rect _descriptionRect;
  double _heightDiff = 0;
  late Rect _illustrationRect;
  late Rect _stackIconRect;
  late Rect _costIconRect;
  late Rect _rarityIconRect;
  late Rect _genreIconRect;
  late Rect _coloredCostIconRect;

  /// Wether this card is shown in a library (isFiltered == false) or not (isFiltered == true).
  bool isFiltered = false;

  Paint glowPaint = Paint()..filterQuality = FilterQuality.medium;

  CustomGameCard({
    required super.id,
    super.uniqueId,
    super.index = 0,
    super.script,
    super.kind,
    this.data,
    super.ownedByRole,
    super.stack,
    super.spriteId,
    super.sprite,
    super.tags,
    super.priority,
    super.position,
    Vector2? size,
    super.borderRadius,
    super.focusedOffset,
    super.focusedPosition,
    super.focusedSize,
    super.focusedPriority,
    super.showBorder,
    super.isFocused,
    super.stayFocused,
    super.isFlipped,
    super.isRotated,
    super.isRotatable,
    super.isEnabled,
    super.onFocused,
    super.onUnfocused,
    super.anchor,
    this.preferredSize,
    String? title,
    String? description,
    this.titleConfig,
    this.descriptionConfig,
    this.illustrationSpriteId,
    this.illustrationSprite,
    this.backSpriteId,
    this.backSprite,
    this.glowSpriteId,
    this.glowSprite,
    this.glowColor,
    this.stackIconSpriteId,
    this.stackIconSprite,
    this.costIconSpriteId,
    this.costIconSprite,
    this.rarityIconSpriteId,
    this.rarityIconSprite,
    this.genreIconSpriteId,
    this.genreIconSprite,
    this.descriptionBackgroundSpriteId,
    this.descriptionBackgroundSprite,
    this.costNumberTextConfig,
    this.stackNumberTextConfig,
    this.coloredCostNumberTextConfig,
    this.cost = 0,
    int? modifiedCost,
    this.illustrationRelativeRect = Rect.zero,
    this.titleRelativeRect = Rect.zero,
    this.descriptionRelativeRect = Rect.zero,
    this.stackIconRelativeRect = Rect.zero,
    this.costIconRelativeRect = Rect.zero,
    this.rarityIconRelativeRect = Rect.zero,
    this.genreIconRelativeRect = Rect.zero,
    this.coloredCostIconRelativeRect = Rect.zero,
    this.coloredCostDirection = ColoredCostDirection.right,
    this.coloredCostIconMargin = 0,
    this.coloredCostLayout = ColoredCostLayout.pips,
    this.titleLayout = CardTitleLayout.horizontalTop,
    this.showGlow = false,
    bool? showTitle,
    bool? showDescription,
    bool? showStackIcon,
    bool? showCostIcon,
    bool? showColoredCost,
    bool? showRarityIcon,
    bool? showGenreIcon,
    this.showStackNumber = false,
    this.showCostNumber = false,
  })  : modifiedCost = modifiedCost ?? cost,
        showTitle = showTitle ?? title != null,
        showDescription = showDescription ?? description != null,
        showStackIcon = showStackIcon ??
            (stackIconSpriteId != null || stackIconSprite != null),
        showCostIcon = showCostIcon ??
            (costIconSpriteId != null || costIconSprite != null),
        showColoredCost = showColoredCost ?? (data?['coloredCost'] != null),
        showRarityIcon = showRarityIcon ??
            (rarityIconSpriteId != null || rarityIconSprite != null),
        showGenreIcon = showGenreIcon ??
            (genreIconSpriteId != null || genreIconSprite != null),
        super(size: size ?? preferredSize) {
    this.title = title;

    this.description = description;

    if (glowColor != null) {
      glowPaint.colorFilter =
          ui.ColorFilter.mode(glowColor!, ui.BlendMode.modulate);
    }
  }

  /// 复制这个卡牌对象，但不会复制onTap之类的交互事件，也不会复制index属性
  @override
  CustomGameCard clone({bool deepCopyData = false}) {
    return CustomGameCard(
      id: id,
      uniqueId: uniqueId,
      script: script,
      kind: kind,
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
      glowColor: glowColor,
      stackIconSpriteId: stackIconSpriteId,
      stackIconSprite: stackIconSprite,
      costIconSpriteId: costIconSpriteId,
      costIconSprite: costIconSprite,
      rarityIconSpriteId: rarityIconSpriteId,
      rarityIconSprite: rarityIconSprite,
      genreIconSpriteId: genreIconSpriteId,
      genreIconSprite: genreIconSprite,
      descriptionBackgroundSpriteId: descriptionBackgroundSpriteId,
      descriptionBackgroundSprite: descriptionBackgroundSprite,
      costNumberTextConfig: costNumberTextConfig,
      stackNumberTextConfig: stackNumberTextConfig,
      coloredCostNumberTextConfig: coloredCostNumberTextConfig,
      cost: cost,
      modifiedCost: modifiedCost,
      illustrationRelativeRect: illustrationRelativeRect,
      rarityIconRelativeRect: rarityIconRelativeRect,
      titleRelativeRect: titleRelativeRect,
      descriptionRelativeRect: descriptionRelativeRect,
      stackIconRelativeRect: stackIconRelativeRect,
      costIconRelativeRect: costIconRelativeRect,
      genreIconRelativeRect: genreIconRelativeRect,
      coloredCostIconRelativeRect: coloredCostIconRelativeRect,
      coloredCostDirection: coloredCostDirection,
      coloredCostIconMargin: coloredCostIconMargin,
      coloredCostLayout: coloredCostLayout,
      showTitle: showTitle,
      showDescription: showDescription,
      showStackIcon: showStackIcon,
      showCostIcon: showCostIcon,
      showColoredCost: showColoredCost,
      showRarityIcon: showRarityIcon,
      showGenreIcon: showGenreIcon,
      showStackNumber: showStackNumber,
      showCostNumber: showCostNumber,
      titleLayout: titleLayout,
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
    String? genreIconSpriteId,
    String? descriptionBackgroundSpriteId,
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
    if (genreIconSpriteId != null) {
      this.genreIconSpriteId = genreIconSpriteId;
    }
    if (this.genreIconSpriteId != null) {
      genreIconSprite =
          Sprite(await Flame.images.load(this.genreIconSpriteId!));
    }
    if (descriptionBackgroundSpriteId != null) {
      this.descriptionBackgroundSpriteId = descriptionBackgroundSpriteId;
    }
    if (this.descriptionBackgroundSpriteId != null) {
      descriptionBackgroundSprite =
          Sprite(await Flame.images.load(this.descriptionBackgroundSpriteId!));
    }
  }

  @override
  void onLoad() async {
    super.onLoad();

    await tryLoadSprite();
  }

  void _generateDescription() {
    if (_description == null) return;

    _descriptionComponent.text = _description;
  }

  /// 从 data['coloredCost'] 读取有序 (颜色id, 数量) 对列表，
  /// 兼容 Map 或者河图 struct 等支持 keys 和 [] 操作的对象；
  /// 数量为 0 或负数的条目跳过；data['coloredCost'] 为 null 时返回 null
  List<(String, int)>? _coloredCostEntries() {
    final coloredCost = data?['coloredCost'];
    if (coloredCost == null) return null;

    final result = <(String, int)>[];
    for (final key in coloredCost.keys) {
      final count = coloredCost[key];
      if (count is! num || count <= 0) continue;
      result.add((key.toString(), count.toInt()));
    }
    return result;
  }

  /// 第 index 个彩色费用图标相对基准图标的偏移量
  Offset _coloredCostIconOffset(int index, double scale) {
    final (dx, dy) = switch (coloredCostDirection) {
      ColoredCostDirection.right => (1.0, 0.0),
      ColoredCostDirection.left => (-1.0, 0.0),
      ColoredCostDirection.down => (0.0, 1.0),
      ColoredCostDirection.up => (0.0, -1.0),
    };
    final step = Offset(
            dx * _coloredCostIconRect.width, dy * _coloredCostIconRect.height) +
        Offset(dx, dy) * coloredCostIconMargin;
    return step * scale * index.toDouble();
  }

  @override
  void generateBorder() {
    super.generateBorder();

    double fontScale = preferredSize != null ? width / preferredSize!.x : 1.0;
    if (fontScale < 0) {
      fontScale = 0;
    }

    _illustrationRect = Rect.fromLTWH(
      illustrationRelativeRect.left * width,
      illustrationRelativeRect.top * height,
      illustrationRelativeRect.width * width,
      illustrationRelativeRect.height * height,
    );

    _rarityIconRect = Rect.fromLTWH(
      rarityIconRelativeRect.left * width,
      rarityIconRelativeRect.top * height,
      rarityIconRelativeRect.width * width,
      rarityIconRelativeRect.height * height,
    );

    _genreIconRect = Rect.fromLTWH(
      genreIconRelativeRect.left * width,
      genreIconRelativeRect.top * height,
      genreIconRelativeRect.width * width,
      genreIconRelativeRect.height * height,
    );

    _stackIconRect = Rect.fromLTWH(
      stackIconRelativeRect.left * width,
      stackIconRelativeRect.top * height,
      stackIconRelativeRect.width * width,
      stackIconRelativeRect.height * height,
    );

    _costIconRect = Rect.fromLTWH(
      costIconRelativeRect.left * width,
      costIconRelativeRect.top * height,
      costIconRelativeRect.width * width,
      costIconRelativeRect.height * height,
    );

    _coloredCostIconRect = Rect.fromLTWH(
      coloredCostIconRelativeRect.left * width,
      coloredCostIconRelativeRect.top * height,
      coloredCostIconRelativeRect.width * width,
      coloredCostIconRelativeRect.height * height,
    );

    stackNumberTextConfig = (stackNumberTextConfig ?? const ScreenTextConfig())
        .copyWith(size: _stackIconRect.size.toVector2(), scale: fontScale);

    costNumberTextConfig = (costNumberTextConfig ?? const ScreenTextConfig())
        .copyWith(size: _costIconRect.size.toVector2(), scale: fontScale);

    _titleRect = Rect.fromLTWH(
      titleRelativeRect.left * width,
      titleRelativeRect.top * height,
      titleRelativeRect.width * width,
      titleRelativeRect.height * height,
    );
    titleConfig = titleConfig?.copyWith(
        size: _titleRect.size.toVector2(), scale: fontScale);

    _descriptionRect = Rect.fromLTWH(
      descriptionRelativeRect.left * width,
      descriptionRelativeRect.top * height,
      descriptionRelativeRect.width * width,
      descriptionRelativeRect.height * height,
    );

    _descriptionComponent.config = (descriptionConfig ?? ScreenTextConfig())
        .copyWith(size: _descriptionRect.size.toVector2());

    _descriptionComponent.layout(
        width: _descriptionRect.width,
        height: _descriptionRect.height,
        fontScale: fontScale);

    _descriptionRect = Rect.fromLTWH(
      descriptionRelativeRect.left * width,
      descriptionRelativeRect.top * height,
      descriptionRelativeRect.width * width,
      math.max(descriptionRelativeRect.height * height,
          _descriptionComponent.textAreaHeight ?? 0),
    );

    _generateDescription();

    _heightDiff =
        _descriptionComponent.textAreaHeight ?? 0 - _descriptionRect.height;
    if (_heightDiff > 0) {
      _descriptionRect = Rect.fromLTWH(
          _descriptionRect.left,
          _descriptionRect.top - _heightDiff,
          _descriptionRect.width,
          _descriptionRect.height + _heightDiff);
    }
  }

  @override
  void render(Canvas canvas) {
    if (!isVisible) return;

    if (showGlow) {
      glowSprite?.renderRect(canvas, border, overridePaint: glowPaint);
    }

    if (isFlipped) {
      backSprite?.renderRect(canvas, border);
    } else {
      illustrationSprite?.renderRect(canvas, _illustrationRect,
          overridePaint: paint);

      descriptionBackgroundSprite?.renderRect(canvas, _descriptionRect);

      sprite?.renderRect(canvas, border, overridePaint: paint);

      if (showDescription) {
        _descriptionComponent.renderAt(canvas,
            Offset(_descriptionRect.left, _descriptionRect.top + _heightDiff));
      }

      if (showRarityIcon) {
        rarityIconSprite?.renderRect(canvas, _rarityIconRect,
            overridePaint: paint);
      }

      if (showGenreIcon) {
        genreIconSprite?.renderRect(canvas, _genreIconRect,
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
              config: stackNumberTextConfig);
        }
      }

      final costColor = modifiedCost > cost
          ? Colors.red
          : (modifiedCost < cost ? Colors.green : Colors.white);
      final coloredCostEntries = showColoredCost ? _coloredCostEntries() : null;
      if (coloredCostEntries != null) {
        // 彩色费用：从基准位置起沿 coloredCostDirection 依次排列，
        // 未注册的颜色跳过且不留空位
        final fontScale =
            preferredSize != null ? width / preferredSize!.x : 1.0;
        var iconIndex = 0;
        for (final (colorId, count) in coloredCostEntries) {
          final iconSprite = coloredCostSprites[colorId];
          if (iconSprite == null) continue;
          switch (coloredCostLayout) {
            case ColoredCostLayout.pips:
              for (var i = 0; i < count; ++i) {
                iconSprite.renderRect(
                    canvas,
                    _coloredCostIconRect
                        .shift(_coloredCostIconOffset(iconIndex, fontScale)),
                    overridePaint: paint);
                ++iconIndex;
              }
            case ColoredCostLayout.compact:
              final rect = _coloredCostIconRect
                  .shift(_coloredCostIconOffset(iconIndex, fontScale));
              iconSprite.renderRect(canvas, rect, overridePaint: paint);
              drawScreenText(
                canvas,
                '$count',
                alpha: isEnabled ? 255 : 128,
                position: rect.topLeft,
                config: (coloredCostNumberTextConfig ??
                        const ScreenTextConfig())
                    .copyWith(size: rect.size.toVector2(), scale: fontScale),
              );
              ++iconIndex;
          }
        }
      } else {
        if (showCostIcon) {
          costIconSprite?.renderRect(canvas, _costIconRect,
              overridePaint: paint);
        }

        if (showCostNumber) {
          drawScreenText(
            canvas,
            '$modifiedCost',
            alpha: isEnabled ? 255 : 128,
            position: _costIconRect.topLeft,
            color: costColor,
            config: costNumberTextConfig,
          );
        }
      }

      if (showTitle && title != null && title?.isNotEmpty == true) {
        switch (titleLayout) {
          case CardTitleLayout.horizontalTop:
            drawScreenText(canvas, title!,
                alpha: isEnabled ? 255 : 128,
                position: _titleRect.topLeft,
                config: titleConfig);
          case CardTitleLayout.verticalRightTop:
            drawScreenText(canvas, _verticalTitle!,
                alpha: isEnabled ? 255 : 128,
                position: _titleRect.topLeft,
                config: titleConfig?.copyWith(anchor: Anchor.topRight));
        }
      }
    }
  }
}
