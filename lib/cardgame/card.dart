import 'dart:async';

import 'package:flame/components.dart' hide SpriteComponent;
import 'package:flame/effects.dart';
import 'package:flame/flame.dart';
// import 'package:flame/effects.dart';

import '../components/sprite_button.dart';
import '../components/game_component.dart';
import '../paint.dart';
import '../extensions.dart';
import 'zones/piled_zone.dart';
// import '../mixin.dart';
import '../task.dart';

class Card extends SpriteButton with HasTaskController {
  static final ScreenTextStyle defaultTitleStyle = ScreenTextStyle(
        anchor: Anchor.topCenter,
        padding: const EdgeInsets.only(top: 8),
        outlined: true,
      ),
      defaultDescriptionStyle = ScreenTextStyle(
        anchor: Anchor.center,
        colorTheme: ScreenTextColorTheme.dark,
        outlined: true,
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

  late Vector2 _savedPosition, _savedSize;

  /// 卡牌id，不同的id对应不同的插画和标题。
  final String id;
  String? ownedByRole;

  bool ownedBy(String? player) {
    if (player == null) return false;
    return ownedByRole == player;
  }

  PiledZone? pile;
  void removeFromPile() {
    pile?.removeCardByIndex(index);
    pile = null;
  }

  /// 组牌id，有可能不同id的卡牌具有相同的名字和规则效果，组牌时他们被视作同一张牌，共享数量上限
  final String deckId;

  /// 卡牌脚本函数名
  final String? script;

  final String? kind, description;
  final int cost;
  final Set<String> tags;

  ScreenTextStyle? titleStyle, descriptionStyle, costStyle, stackStyle;

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

  /// the sprite id of this card, should be unique among all cards
  final String? backSpriteId, illustrationSpriteId;
  final double illustrationHeightRatio;
  late Rect _illustrationRect;
  Sprite? backSprite, illustrationSprite;

  Vector2? focusedOffset, focusedPosition, focusedSize;
  int? focusedPriority;

  bool focusOnPreviewing;
  bool showBorder;
  bool isFocused;
  bool stayFocused;
  bool isFlipped;
  bool isRotated;
  bool isRotatable;

  // Map<String, void Function()?> useEventHandlers = {};
  // Map<String, void Function()?> cancelEventHandlers = {};

  String? state;

  /// 该卡牌在某种卡牌状态，以及某个游戏阶段，是否可以使用
  final Map<String, Map<String, bool>> _usableState = {};

  GameComponent? zone;

  void Function()? onFocused, onUnfocused, onPreviewed, onUnpreviewed;
  double focusAnimationDuration;
  int preferredPriority = 0;

  void resetPriority() {
    priority = preferredPriority;
  }

  int previewPriority;

  Rect? descriptionPadding;

  Card({
    required this.id,
    required this.deckId,
    this.script,
    this.kind,
    super.text,
    ScreenTextStyle? titleStyle,
    this.enablePreview = false,
    this.showTitle = false,
    this.showTitleOnHovering = false,
    this.description,
    ScreenTextStyle? descriptionStyle,
    this.showDescription = false,
    this.descriptionOutlined = false,
    this.descriptionPadding,
    this.data,
    this.ownedByRole,
    super.spriteId,
    super.sprite,
    this.illustrationSpriteId,
    this.illustrationSprite,
    this.backSpriteId,
    this.backSprite,
    this.cost = 0,
    Set<String>? tags,
    this.stack = 1,
    this.showStack = false,
    ScreenTextStyle? stackStyle,
    super.priority,
    super.position,
    super.size,
    super.borderRadius,
    this.illustrationHeightRatio = 1.0,
    this.focusedOffset,
    this.focusedPosition,
    this.focusedSize,
    this.focusedPriority,
    this.focusOnPreviewing = false,
    this.showBorder = false,
    this.isFocused = false,
    this.stayFocused = false,
    this.isFlipped = false,
    this.isRotated = false,
    this.isRotatable = false,
    super.isEnabled,
    super.anchor,
    bool enableGesture = true,
    this.state,
    this.focusAnimationDuration = 0.15,
    this.onFocused,
    this.onUnfocused,
    this.onPreviewed,
    this.onUnpreviewed,
    this.previewPriority = 200,
  })  : tags = tags ?? {},
        super(useDefaultRender: false) {
    _savedPosition = position.clone();
    _savedSize = size.clone();
    preferredPriority = priority;

    this.enableGesture = enableGesture;

    if (titleStyle != null) {
      this.titleStyle =
          titleStyle.fillFrom(defaultTitleStyle).copyWith(rect: border);
    } else {
      this.titleStyle = defaultTitleStyle.copyWith(rect: border);
    }

    if (stackStyle != null) {
      this.stackStyle =
          stackStyle.fillFrom(defaultStackStyle).copyWith(rect: border);
    } else {
      this.stackStyle = defaultStackStyle.copyWith(rect: border);
    }

    if (descriptionStyle != null) {
      this.descriptionStyle = descriptionStyle
          .fillFrom(defaultTitleStyle)
          .copyWith(
            rect: descriptionPadding != null
                ? Rect.fromLTWH(
                    descriptionPadding!.left,
                    descriptionPadding!.top,
                    width -
                        (descriptionPadding!.right - descriptionPadding!.left),
                    height -
                        (descriptionPadding!.bottom - descriptionPadding!.top))
                : Rect.fromLTWH(
                    (width - width * 0.8) / 2,
                    height * 0.6,
                    width * 0.8,
                    height * 0.3,
                  ),
          );
    } else {
      this.descriptionStyle = defaultDescriptionStyle.copyWith(rect: border);
    }

    onMouseEnter = () {
      if (enablePreview) {
        onPreviewed?.call();
        if (focusOnPreviewing) {
          schedule(() => setFocused(true));
        }
      }
    };

    onMouseExit = () {
      if (enablePreview) {
        onUnpreviewed?.call();
        if (focusOnPreviewing) {
          schedule(() => setFocused(false));
        }
      }
    };
  }

  @override
  void generateBorder() {
    super.generateBorder();

    titleStyle = titleStyle?.copyWith(rect: border);
    stackStyle = stackStyle?.copyWith(rect: border);
    descriptionStyle = descriptionStyle?.copyWith(
      rect: descriptionPadding != null
          ? Rect.fromLTWH(
              descriptionPadding!.left,
              descriptionPadding!.top,
              width - (descriptionPadding!.right - descriptionPadding!.left),
              height - (descriptionPadding!.bottom - descriptionPadding!.top))
          : Rect.fromLTWH(
              (width - width * 0.8) / 2,
              height * 0.6,
              width * 0.8,
              height * 0.3,
            ),
    );

    _illustrationRect =
        Rect.fromLTWH(0, 0, width, height * illustrationHeightRatio);
  }

  /// 复制这个卡牌对象，但不会复制onTap之类的交互事件，也不会复制index属性
  Card clone() {
    return Card(
      id: id,
      deckId: deckId,
      script: script,
      kind: kind,
      text: text,
      titleStyle: titleStyle,
      enablePreview: enablePreview,
      showTitle: showTitle,
      showTitleOnHovering: showTitleOnHovering,
      description: description,
      descriptionStyle: descriptionStyle,
      showDescription: showDescription,
      descriptionOutlined: descriptionOutlined,
      descriptionPadding: descriptionPadding,
      data: data,
      ownedByRole: ownedByRole,
      sprite: sprite,
      illustrationSprite: illustrationSprite,
      backSprite: backSprite,
      cost: cost,
      tags: tags,
      stack: stack,
      showStack: showStack,
      stackStyle: stackStyle,
      priority: priority,
      position: position,
      size: size,
      borderRadius: borderRadius,
      illustrationHeightRatio: illustrationHeightRatio,
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
      enableGesture: enableGesture,
      state: state,
      focusAnimationDuration: focusAnimationDuration,
    );
  }

  void setUsable(String state, String phase) {
    Map<String, bool>? p = _usableState[state];
    p ??= _usableState[state] = <String, bool>{};
    p[phase] = true;
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

  Future<void> setFocused(bool value) async {
    if (isFocused == value) return;
    isFocused = value;
    if (value) {
      if (focusedPriority != null) {
        priority = focusedPriority!;
      }

      _savedPosition = position.clone();
      _savedSize = size.clone();

      Vector2? endPosition;
      if (focusedOffset != null) {
        endPosition = position + focusedOffset!;
      } else if (focusedPosition != null) {
        endPosition = focusedPosition!;
      }
      await moveTo(
        toPosition: endPosition,
        toSize: focusedSize,
        duration: focusAnimationDuration,
      );

      onFocused?.call();
    } else {
      enableGesture = true;
      // if (!stayFocused) {
      await moveTo(
        toPosition: _savedPosition,
        toSize: _savedSize,
        duration: focusAnimationDuration,
      );

      resetPriority();
      onUnfocused?.call();
      // }
    }
  }

  /// 只能向逆时针方向旋转 90°，或者恢复正常状态
  ///
  /// 返回值代表是否成功旋转
  ///
  /// 参数不为 null 时，true 代表进行旋转，false 代表恢复正常
  Future<void> rotate([bool? value, double degree = -90]) async {
    if (isRotated == value) return;

    final completer = Completer();
    if (value == null) {
      if (isRotated) {
        isRotated = false;
        final effect = RotateEffect.to(
          0,
          EffectController(duration: 0.2),
          onComplete: () {
            completer.complete();
          },
        );
        add(effect);
      } else {
        isRotated = true;
        final effect = RotateEffect.to(
          radians(degree),
          EffectController(duration: 0.2),
          onComplete: () {
            completer.complete();
          },
        );
        add(effect);
      }
    } else {
      if (isRotated && !value) {
        isRotated = false;
        final effect = RotateEffect.to(
          0,
          EffectController(duration: 0.2),
          onComplete: () {
            completer.complete();
          },
        );
        add(effect);
      } else if (!isRotated && value) {
        isRotated = true;
        final effect = RotateEffect.to(
          radians(degree),
          EffectController(duration: 0.2),
          onComplete: () {
            completer.complete();
          },
        );
        add(effect);
      }
    }
    return completer.future;
  }

  // /// 注册一个使用卡牌的处理函数
  // void onUse(String state, void Function()? handler) {
  //   useEventHandlers[state] = handler;
  // }

  // /// 注册一个取消使用的处理函数
  // void onCancel(String state, void Function()? handler) {
  //   cancelEventHandlers[state] = handler;
  // }

  // /// 使用卡牌，在不同的状态下有不同的处理函数
  // void use() {
  //   final handler = useEventHandlers[state];
  //   handler?.call();
  // }

  // /// 取消使用，在不同的状态下有不同的处理函数
  // void cancel() {
  //   final handler = cancelEventHandlers[state];
  //   handler?.call();
  // }

  @override
  void customRender(Canvas canvas) {
    if (isFlipped) {
      backSprite?.renderRect(canvas, border);
    } else {
      illustrationSprite?.renderRect(canvas, _illustrationRect,
          overridePaint: isEnabled ? paint : invalidPaint);
      sprite?.renderRect(canvas, border,
          overridePaint: isEnabled ? paint : invalidPaint);
    }

    if ((showTitleOnHovering && isHovering) || isFocused || showTitle) {
      if (text != null) {
        drawScreenText(canvas, text!, style: titleStyle);
      }
    }

    // canvas.drawRect(descriptionRect, borderPaintSelected);
    if (showDescription && description != null) {
      drawScreenText(
        canvas,
        description!,
        style: descriptionStyle,
      );
    }

    if (showStack && stack > 0) {
      drawScreenText(canvas, '×$stack', style: stackStyle);
    }
  }
}
