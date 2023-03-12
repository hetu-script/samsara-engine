import 'package:flame/components.dart' hide SpriteComponent;
import 'package:flame/effects.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flame/flame.dart';
// import 'package:flame/effects.dart';

import '../gestures/gesture_mixin.dart';
import '../component/game_component.dart';
import 'zones/playable_zone.dart';
import '../paint.dart';
// import '../extensions.dart';

enum CardState {
  none,
  deck,
  hand,
  placed,
  ready,
  discarded,
  destroyed,
}

class PlayingCard extends GameComponent with HandlesGesture {
  static ScreenTextStyle defaultTitleStyle = const ScreenTextStyle(
        anchor: Anchor.topCenter,
        padding: EdgeInsets.only(top: 8),
      ),
      defaultDescriptionStyle = const ScreenTextStyle(
        anchor: Anchor.center,
        outlined: false,
        colorTheme: ScreenTextColorTheme.dark,
      ),
      defaultStackStyle = ScreenTextStyle(
        textPaint: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        anchor: Anchor.bottomCenter,
        padding: const EdgeInsets.only(bottom: -20),
        outlined: true,
      );

  int _savedPriority = 0;
  late Vector2 _savedPosition, _savedSize;

  final String id;
  final String? kind, title, description;
  final int cost;
  final Set<String> tags;

  late ScreenTextStyle titleStyle, descriptionStyle, costStyle, stackStyle;

  /// 堆叠数量，一张卡牌可以代表一叠同名卡牌。
  int stack;

  /// 卡牌位置索引，一般由父组件管理。
  int index = 0;

  bool enablePreview;
  bool showTitle;
  bool showTitleOnHovering;
  bool showDescription;
  bool descriptionOutlined;
  bool showStack;

  /// 卡牌的原始数据，可能是一个Json，或者一个河图struct对象，
  /// 也可能是 null，例如资源牌这种情况。
  final dynamic data;

  String? ownedPlayerId;

  /// the sprite id of this card, should be unique among all cards
  final String? frontSpriteId, backSpriteId, illustrationSpriteId;
  final Vector2 illustrationOffset;
  Sprite? frontSprite, backSprite, illustrationSprite;

  Vector2? focusedOffset, focusedPosition, focusedSize;

  bool focusOnHovering;
  bool showBorder;
  bool isFocused;
  bool stayFocused;
  bool isFlipped;
  bool isRotated;
  bool isRotatable;

  Map<CardState, void Function()?> useEventHandlers = {};
  Map<CardState, void Function()?> cancelEventHandlers = {};

  CardState state;
  PlayableZone? zone;

  void Function()? onFocused, onUnfocused, onPreviewed, onUnpreviewed;
  double focusAnimationDuration;

  late Rect descriptionRect;

  PlayingCard({
    required this.id,
    this.kind,
    this.title,
    ScreenTextStyle? titleStyle,
    this.enablePreview = false,
    this.showTitle = false,
    this.showTitleOnHovering = false,
    this.description,
    ScreenTextStyle? descriptionStyle,
    this.showDescription = false,
    this.descriptionOutlined = false,
    this.data,
    this.ownedPlayerId,
    this.frontSpriteId,
    this.frontSprite,
    this.illustrationSpriteId,
    this.illustrationSprite,
    this.backSpriteId,
    this.backSprite,
    this.cost = 0,
    Set<String>? tags,
    this.stack = 1,
    this.showStack = false,
    ScreenTextStyle? stackStyle,
    super.position,
    super.size,
    super.borderRadius,
    Vector2? illustrationOffset,
    this.focusedOffset,
    this.focusedPosition,
    this.focusedSize,
    this.focusOnHovering = false,
    this.showBorder = false,
    this.isFocused = false,
    this.stayFocused = false,
    this.isFlipped = false,
    this.isRotated = false,
    this.isRotatable = false,
    super.anchor,
    super.priority,
    bool enableGesture = true,
    this.state = CardState.none,
    this.onFocused,
    this.onUnfocused,
    this.onPreviewed,
    this.onUnpreviewed,
    this.focusAnimationDuration = 0.25,
  })  : tags = tags ?? {},
        illustrationOffset = illustrationOffset ?? Vector2.zero() {
    _savedPosition = position.clone();
    _savedSize = size.clone();

    if (titleStyle != null) {
      this.titleStyle =
          titleStyle.fillFrom(defaultTitleStyle).fillWith(rect: border);
    } else {
      this.titleStyle = defaultTitleStyle.copyWith(rect: border);
    }

    if (descriptionStyle != null) {
      this.descriptionStyle =
          descriptionStyle.fillFrom(defaultTitleStyle).fillWith(
                rect: Rect.fromLTWH(
                  (width - width * 0.8) / 2,
                  height * 0.6,
                  width * 0.8,
                  height * 0.3,
                ),
              );
    } else {
      this.descriptionStyle = defaultDescriptionStyle.copyWith(
        rect: Rect.fromLTWH(
          (width - width * 0.8) / 2,
          height * 0.6,
          width * 0.8,
          height * 0.3,
        ),
      );
    }

    if (stackStyle != null) {
      this.stackStyle =
          stackStyle.fillFrom(defaultStackStyle).fillWith(rect: border);
    } else {
      this.stackStyle = defaultStackStyle.copyWith(rect: border);
    }

    this.enableGesture = enableGesture;

    onMouseEnter = () {
      if (enablePreview) {
        onPreviewed?.call();
      }
      if (focusOnHovering) {
        setFocused(true);
      }
    };

    onMouseExit = () {
      if (enablePreview) {
        onUnpreviewed?.call();
      }
      if (focusOnHovering && !stayFocused) {
        setFocused(false);
      }
    };
  }

  /// 复制这个卡牌对象，但不会复制onTap之类的交互事件，也不会复制index属性
  PlayingCard clone() {
    return PlayingCard(
      id: id,
      kind: kind,
      title: title,
      titleStyle: titleStyle,
      enablePreview: enablePreview,
      showTitle: showTitle,
      showTitleOnHovering: showTitleOnHovering,
      description: description,
      descriptionStyle: descriptionStyle,
      showDescription: showDescription,
      descriptionOutlined: descriptionOutlined,
      data: data,
      ownedPlayerId: ownedPlayerId,
      frontSpriteId: frontSprite == null ? frontSpriteId : null,
      frontSprite: frontSprite,
      illustrationSpriteId:
          illustrationSprite == null ? illustrationSpriteId : null,
      illustrationSprite: illustrationSprite,
      backSpriteId: backSprite == null ? backSpriteId : null,
      backSprite: backSprite,
      cost: cost,
      tags: tags,
      stack: stack,
      showStack: showStack,
      stackStyle: stackStyle,
      position: position,
      size: size,
      borderRadius: borderRadius,
      illustrationOffset: illustrationOffset,
      focusedOffset: focusedOffset,
      focusedPosition: focusedPosition,
      focusedSize: focusedSize,
      focusOnHovering: focusOnHovering,
      showBorder: showBorder,
      isFocused: isFocused,
      stayFocused: stayFocused,
      isFlipped: isFlipped,
      isRotated: isRotated,
      isRotatable: isRotatable,
      anchor: anchor,
      priority: priority,
      enableGesture: enableGesture,
      state: state,
      onFocused: onFocused,
      onUnfocused: onUnfocused,
      onPreviewed: onPreviewed,
      onUnpreviewed: onUnpreviewed,
      focusAnimationDuration: focusAnimationDuration,
    );
  }

  @override
  Future<void> onLoad() async {
    if (frontSpriteId != null) {
      frontSprite = Sprite(await Flame.images.load('cards/$frontSpriteId.png'));
    }
    if (illustrationSpriteId != null) {
      illustrationSprite = Sprite(
          await Flame.images.load('illustrations/$illustrationSpriteId.png'));
    }
    if (backSpriteId != null) {
      backSprite = Sprite(await Flame.images.load('$backSpriteId.png'));
    }
    // if (countDecorSpriteId != null) {
    //   countDecorSprite =
    //       Sprite(await Flame.images.load('$countDecorSpriteId.png'));
    // }
  }

  void setFocused(bool value) {
    if (isFocused == value) return;

    isFocused = value;
    if (value) {
      _savedPriority = priority;
      priority = 1000;
      _savedPosition = position.clone();
      _savedSize = size.clone();

      Vector2? endPosition;
      if (focusedOffset != null) {
        endPosition = position + focusedOffset!;
      } else if (focusedPosition != null) {
        endPosition = focusedPosition!;
      }
      if (endPosition != null) {
        moveTo(
          position: endPosition,
          size: focusedSize,
          duration: focusAnimationDuration,
        );
      }

      onFocused?.call();
    } else {
      if (stayFocused) return;
      priority = _savedPriority;
      moveTo(
        position: _savedPosition,
        size: _savedSize,
        duration: focusAnimationDuration,
      );
      onUnfocused?.call();
    }
  }

  /// 只能向逆时针方向旋转 90°，或者恢复正常状态
  ///
  /// 返回值代表是否成功旋转
  ///
  /// 参数不为 null 时，true 代表进行旋转，false 代表恢复正常
  bool rotate([bool? value, double degree = -90]) {
    if (value == null) {
      if (isRotated) {
        isRotated = false;
        final effect = RotateEffect.to(0, EffectController(duration: 0.2));
        add(effect);
      } else {
        isRotated = true;
        final effect =
            RotateEffect.to(radians(degree), EffectController(duration: 0.2));
        add(effect);
      }
      return true;
    } else {
      if (isRotated && !value) {
        isRotated = false;
        final effect = RotateEffect.to(0, EffectController(duration: 0.2));
        add(effect);
        return true;
      } else if (!isRotated && value) {
        isRotated = true;
        final effect =
            RotateEffect.to(radians(degree), EffectController(duration: 0.2));
        add(effect);
        return true;
      }
    }
    return false;
  }

  /// 注册一个使用卡牌的处理函数
  void onUse(CardState state, void Function()? handler) {
    useEventHandlers[state] = handler;
  }

  /// 注册一个取消使用的处理函数
  void onCancel(CardState state, void Function()? handler) {
    cancelEventHandlers[state] = handler;
  }

  /// 使用卡牌，在不同的状态下有不同的处理函数
  void use() {
    final handler = useEventHandlers[state];
    handler?.call();
  }

  /// 取消使用，在不同的状态下有不同的处理函数
  void cancel() {
    final handler = cancelEventHandlers[state];
    handler?.call();
  }

  @override
  void render(Canvas canvas, {Vector2? position}) {
    if (isFlipped) {
      backSprite?.renderRect(canvas, border);
    } else {
      frontSprite?.renderRect(canvas, border);
    }

    if (showBorder) {
      canvas.drawRect(border, DefaultBorderPaint.primary);
    }

    if ((showTitleOnHovering && isHovering) || isFocused || showTitle) {
      if (title != null) {
        drawScreenText(canvas, title!, style: titleStyle);
      }
    }

    // canvas.drawRect(descriptionRect, borderPaintSelected);
    if (showDescription && description != null) {
      drawScreenText(canvas, description!, style: descriptionStyle);
    }

    if (showStack && stack > 0) {
      drawScreenText(canvas, '×$stack', style: stackStyle);
    }
  }
}
