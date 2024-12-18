import 'dart:async';
// import 'dart:ui';

import 'package:flame/components.dart' hide SpriteComponent;
import 'package:flame/effects.dart';
import 'package:flame/flame.dart';
// import 'package:flutter/widgets.dart';
// import 'package:flame/effects.dart';

import '../components/border_component.dart';
import '../components/game_component.dart';
import '../paint/paint.dart';
import 'zones/piled_zone.dart';
// import '../mixin.dart';
import '../task.dart';
import '../gestures.dart';

class GameCard extends BorderComponent with HandlesGesture, HasTaskController {
  late Vector2 _savedPosition, _savedSize;

  /// 卡牌id，不同的id对应不同的插画和标题。
  final String id;
  String? ownedByRole;

  Sprite? sprite;
  String? spriteId;

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

  final String? kind;
  final Set<String> tags;

  /// 卡牌位置索引，一般由父组件管理。
  int index = 0;

  /// 堆叠数量，一张卡牌可以代表一叠同名卡牌。
  int stack;

  /// 卡牌的原始数据，可能是一个Json，或者一个河图struct对象，
  /// 也可能是 null，例如资源牌这种情况。
  final dynamic data;

  Vector2? focusedOffset, focusedPosition, focusedSize;
  int? focusedPriority;

  bool focusOnPreviewing;
  bool showBorder;
  bool isFocused;
  bool stayFocused;
  bool isFlipped;
  bool isRotated;
  bool isRotatable;

  /// 该卡牌在某种卡牌状态，以及某个游戏阶段，是否可以使用
  final Map<String, Map<String, bool>> _usableState = {};

  GameComponent? zone;

  void Function()? onFocused, onUnfocused, onPreviewed, onUnpreviewed;
  double focusAnimationDuration;
  int preferredPriority = 0;

  void resetPriority() {
    priority = preferredPriority;
  }

  bool enablePreview;

  // bool isEnabled;
  late bool _isEnabled;
  bool get isEnabled => _isEnabled;
  set isEnabled(bool value) {
    _isEnabled = value;
    if (value) {
      paint = getPaint('default');
    } else {
      paint = getPaint('invalid');
    }
  }

  GameCard({
    required this.id,
    String? deckId,
    this.script,
    this.kind,
    this.enablePreview = false,
    this.data,
    this.ownedByRole,
    this.stack = 1,
    this.spriteId,
    this.sprite,
    Set<String>? tags,
    super.priority,
    super.position,
    super.size,
    super.borderRadius,
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
    super.anchor,
    this.focusAnimationDuration = 0.15,
    this.onFocused,
    this.onUnfocused,
    this.onPreviewed,
    this.onUnpreviewed,
    // this.isEnabled = true,
    bool isEnabled = true,
  })  : deckId = deckId ?? id,
        tags = tags ?? {} {
    _savedPosition = position.clone();
    _savedSize = size.clone();
    preferredPriority = priority;

    final invalidPaint = Paint()..colorFilter = kColorFilterGreyscale;
    setPaint('invalid', invalidPaint);
    this.isEnabled = isEnabled;

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

  /// 复制这个卡牌对象，但不会复制onTap之类的交互事件，也不会复制index属性
  GameCard clone() {
    return GameCard(
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
    );
  }

  @override
  void onLoad() async {
    if (spriteId != null) {
      sprite = Sprite(await Flame.images.load(spriteId!));
    }
  }

  void setUsable(String state, String phase) {
    Map<String, bool>? p = _usableState[state];
    p ??= _usableState[state] = <String, bool>{};
    p[phase] = true;
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

  /// 旋转一定角度，或者恢复正常状态，默认逆时针方向旋转 90°
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

  @override
  void render(Canvas canvas) {
    sprite?.render(canvas, size: size, overridePaint: paint);
  }
}