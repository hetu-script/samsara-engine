import 'package:flame/components.dart' hide SpriteComponent;
import 'package:flame/effects.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flame/flame.dart';
// import 'package:flame/effects.dart';

import '../gestures/gesture_mixin.dart';
import '../component/game_component.dart';
import 'zones/playable_zone.dart';
import '../../paint/paint.dart';

enum CardState {
  deck,
  hand,
  placed,
  ready,
  discarded,
  destroyed,
}

class PlayingCard extends GameComponent with HandlesGesture {
  int _savedPriority = 0;
  late Vector2 _savedPosition, _savedSize;

  String? ownedPlayerId;

  final String? id, kind, title;
  TextPaint? titlePaint;
  final int cost;
  final Set<String> tags = {};

  /// 卡牌的原始数据，可能是一个Json，或者一个河图struct对象，
  /// 也可能是 null，例如资源牌这种情况。
  final dynamic data;

  /// the sprite id of this card, should be unique among all cards
  final String? frontSpriteId, backSpriteId, illustrationSpriteId;
  final Vector2 illustrationOffset;
  Sprite? frontSprite, backSprite, illustrationSprite;

  bool showPreview;
  bool showTitleOnHovering;
  bool showCount;
  bool showBorder = false;
  Vector2? focusedOffset, focusedPosition, focusedSize;
  bool _isFocused = false;
  bool stayFocused = false;
  bool isFlipped;
  bool isRotated = false;
  bool isRotatable;

  Map<CardState, void Function()?> useEventHandlers = {};
  Map<CardState, void Function()?> cancelEventHandlers = {};

  CardState state;
  PlayableZone? zone;

  void Function()? onFocused, onUnfocused;
  double focusAnimationDuration;

  int count;
  Sprite? countDecorSprite;
  String? countDecorSpriteId;
  TextPaint countPaint;

  PlayingCard({
    this.data,
    this.id,
    this.kind,
    this.title,
    this.titlePaint,
    this.ownedPlayerId,
    this.frontSpriteId,
    this.frontSprite,
    this.illustrationSpriteId,
    this.illustrationSprite,
    this.backSpriteId,
    this.backSprite,
    this.cost = 0,
    this.count = 1,
    this.countDecorSprite,
    this.countDecorSpriteId,
    TextPaint? countPaint,
    Set<String> tags = const {},
    double x = 0,
    double y = 0,
    required double width,
    required double height,
    super.borderRadius,
    Vector2? illustrationOffset,
    this.focusedOffset,
    this.focusedPosition,
    this.focusedSize,
    this.showPreview = false,
    this.showTitleOnHovering = false,
    this.showCount = false,
    this.isFlipped = false,
    this.isRotatable = false,
    super.anchor,
    super.priority,
    bool enableGesture = true,
    this.state = CardState.deck,
    this.onFocused,
    this.onUnfocused,
    this.focusAnimationDuration = 0.25,
  })  : countPaint = TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        illustrationOffset = illustrationOffset ?? Vector2.zero(),
        // focusOffset = focusOffset ?? Vector2.zero(),
        super(
          position: Vector2(x, y),
          size: Vector2(width, height),
        ) {
    _savedPosition = position.clone();
    _savedSize = position.clone();
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
    if (countDecorSpriteId != null) {
      countDecorSprite =
          Sprite(await Flame.images.load('$countDecorSpriteId.png'));
    }
  }

  void setFocused(bool value) {
    if (_isFocused == value) return;

    _isFocused = value;
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

  @override
  void onMouseEnter() {
    if (showPreview) {
      setFocused(true);
    }
  }

  @override
  void onMouseExit() {
    if (showPreview && !stayFocused) {
      setFocused(false);
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
  void onTap(int pointer, int buttons, TapUpDetails details) {
    use();
  }

  @override
  void render(Canvas canvas) {
    if (isFlipped) {
      backSprite?.renderRect(canvas, border);
    } else {
      frontSprite?.renderRect(canvas, border);
    }

    if (showBorder) {
      canvas.drawRect(border, borderPaintSelected);
    }

    if ((showTitleOnHovering && isHovering) || _isFocused) {
      if (title != null) {
        drawScreenText(
          canvas,
          title!,
          textPaint: titlePaint,
          rect: border,
          anchor: Anchor.topCenter,
          marginTop: 5,
        );
      }
    }

    if (showCount && count > 0) {
      drawScreenText(
        canvas,
        '$count',
        textPaint: countPaint,
        rect: border,
        anchor: Anchor.bottomCenter,
        background: countDecorSprite,
      );
    }
  }
}
