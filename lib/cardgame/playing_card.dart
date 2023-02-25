import 'package:flame/components.dart' hide SpriteComponent;
import 'package:flame/effects.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flame/game.dart';
import 'package:flame/flame.dart';
// import 'package:samsara/utils/math.dart';
import 'package:samsara/samsara.dart';
// import 'package:flame/effects.dart';

import 'package:samsara/gestures.dart';

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
  @override
  Camera get camera => gameRef.camera;

  late Rect border;
  late Rect cardRect;

  int _savedPriority = 0;
  Vector2 _savedOffset = Vector2.zero();

  String? playerId;
  final String id;
  final String? title;
  final int cost;
  final String? kind;

  /// 卡牌的原始数据，可能是一个Json，或者一个河图struct对象，
  /// 也可能是 null，例如资源牌这种情况。
  final dynamic data;

  Sprite? frontSprite;
  Sprite? backSprite;

  bool showPreview;
  bool showTitleOnHovering;
  bool showFocusBorder = false;
  Vector2 focusOffset;
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

  PlayingCard({
    this.data,
    this.playerId,
    required this.id,
    this.title,
    this.cost = 0,
    this.kind,
    double x = 0,
    double y = 0,
    required double width,
    required double height,
    this.showPreview = false,
    this.showTitleOnHovering = false,
    this.isFlipped = false,
    this.isRotatable = false,
    super.anchor,
    super.priority,
    bool enableGesture = true,
    this.state = CardState.deck,
    this.onFocused,
    this.onUnfocused,
  }) : focusOffset = Vector2.zero() {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    generateBorder();

    this.enableGesture = enableGesture;
  }

  void generateBorder() {
    border = Rect.fromLTWH(0, 0, width, height);
  }

  @override
  Future<void> onLoad() async {
    frontSprite = Sprite(await Flame.images.load('cards/$id.png'));
    backSprite = Sprite(await Flame.images.load('cardback.png'));
  }

  void setFocused(bool value) {
    if (_isFocused == value) return;

    _isFocused = value;
    if (value) {
      _savedPriority = priority;
      priority = 1000;
      _savedOffset = position.clone();
      position += focusOffset;
      onFocused?.call();
    } else {
      priority = _savedPriority;
      position = _savedOffset;
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
    if (showPreview) {
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

    if (showFocusBorder) {
      canvas.drawRect(border, borderPaintSelected);
    }

    if (showTitleOnHovering && isHovering) {
      if (title != null) {
        drawScreenText(canvas, title!,
            rect: border, anchor: Anchor.topCenter, marginTop: 5);
      }
      // renderTextAtPosition(canvas, '费用：$cost', Vector2(10, 25));
    }
  }
}
