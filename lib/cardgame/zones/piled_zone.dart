import 'dart:async';
import 'dart:math' as math;

import '../card.dart';
import '../../samsara.dart';

enum PileStyle {
  /// new cards put to bottom of pile
  queue,

  /// new cards put on top of pile
  stack,

  /// new cards put in random place in pile
  /// shuffle,
}

class PiledZone extends BorderComponent {
  String? ownedBy;

  bool isOwnedBy(String? player) {
    if (player == null) return false;
    return ownedBy == player;
  }

  String? title;

  ScreenTextConfig? titleStyle;

  /// 不允许堆叠时，可设置卡牌数量上限
  int limit;

  /// 是否达到了卡牌数量上限
  bool get isFull => limit >= 0 && cards.length >= limit;

  /// 不允许堆叠时，可设置是否为非紧凑型牌堆
  /// 即卡牌摆放时允许中间有空位
  // final bool allowEmptySlots;

  List<GameCard> cards = [];

  bool containsCard(String uniqueId) =>
      cards.any((card) => card.uniqueId == uniqueId);

  /// 按照卡牌 ID 生成的列表，可能出现重复的ID
  // List<String> pile = [];

  final Vector2 piledCardSize;
  Vector2? focusedOffset, focusedPosition, focusedSize;

  /// [pileStartPosition] : 堆叠时的起始位置
  /// 如果此值为 null，则根据如下规则设定：
  /// 如果卡牌被添加到 zone 上，则起始位置为 (0,0)
  /// 否则起始位置为 zone 自己的位置
  Vector2? pileStartPosition;

  /// [pileOffset] : 每张牌相比上一张牌的位移
  late Vector2 pileOffset; //, focusOffset;

  final PileStyle pileStyle;
  final bool reverseX, reverseY;

  // int pileTopPriority;

  final Anchor titleAnchor;
  final EdgeInsets titlePadding;

  int cardBasePriority;

  // final String? cardState;

  // int _largestIndex = 0;

  void Function()? onPileChanged;

  /// 当牌堆中某张牌被focus时，是否自动将其他牌散开以避免重叠
  final bool spreadOnFocus;

  /// 散开时的额外间距
  final double spreadMargin;

  /// 是否将卡牌整体在组件区域内居中排列
  final bool centerCards;

  Vector2 _centeringOffset = Vector2.zero();

  @override
  set isVisible(bool value) {
    super.isVisible = value;
    for (final card in cards) {
      card.isVisible = value;
    }
  }

  /// [pileOffset] : 堆叠时每张牌相比上一张牌的位移
  PiledZone({
    this.ownedBy,
    this.title,
    super.priority,
    super.position,
    super.size,
    super.borderRadius = 5.0,
    this.limit = -1,
    // this.allowEmptySlots = false,
    List<GameCard>? cards,
    required this.piledCardSize,
    this.focusedOffset,
    this.focusedPosition,
    this.focusedSize,
    this.pileStartPosition,
    Vector2? pileOffset,
    this.pileStyle = PileStyle.stack,
    this.reverseX = false,
    this.reverseY = false,
    // this.pileTopPriority = 5000,
    this.titleAnchor = Anchor.topLeft,
    this.titlePadding = EdgeInsets.zero,
    // this.cardState,
    this.onPileChanged,
    this.spreadOnFocus = false,
    this.spreadMargin = 0,
    this.centerCards = false,
    int? cardBasePriority,
    super.isVisible,
  }) : cardBasePriority =
            cardBasePriority ?? (pileStyle == PileStyle.stack ? 0 : 5000) {
    pileOffset ??= Vector2(0.0, 0.0);

    this.pileOffset = Vector2(
        pileOffset.x * (reverseX ? -1 : 1), pileOffset.y * (reverseY ? -1 : 1));

    if (limit < -1) limit = -1;

    // _largestIndex = cards.length - 1;
    if (cards != null) {
      this.cards = cards;
      if (this.cards.isNotEmpty) {
        for (var i = 0; i <= cards.length - 1; ++i) {
          final card = cards[i];
          card.index = i;
        }
        sortCards(animated: false);
      }
    }

    titleStyle = ScreenTextConfig(
      size: size,
      anchor: titleAnchor,
      padding: titlePadding,
    );
  }

  @override
  void generateBorder() {
    super.generateBorder();

    titleStyle = titleStyle?.copyWith(size: size);
  }

  @override
  void onLoad() async {
    if (cards.isNotEmpty) {
      sortCards();
    }
  }

  /// 在加入卡牌之前进行一些预操作
  /// 例如修改卡牌大小样式，移除过多的卡牌等
  /// 通常用返回false表示加入失败
  /// override 这个函数时，可以修改返回类型，比如改成String 用来返回具体原因
  dynamic tryAddCard(
    GameCard card, {
    int? index,
    bool animated = true,
    bool clone = false,
  }) {
    if (clone) {
      card = card.clone();
      game.world.add(card);
    }
    placeCard(card, index: index, animated: animated);

    return true;
  }

  /// 将一个已经存在并显示的卡牌，移动到堆叠区域并添加到列表
  /// TODO: [insertAndRearrangeAll]如果为真，并且[allowEmptySlots]为真。并且目前有空位，则在向已经有卡牌的位置插入新卡牌时，会将已有的卡牌向后移动让出位置
  Future<void> placeCard(
    GameCard card, {
    int? index,
    // bool insertAndRearrangeAll = false,
    bool animated = true,
    void Function()? onComplete,
  }) async {
    if (cards.contains(card)) return;

    if (index == null) {
      if (isFull) return;

      index = cards.length;
    } else {
      assert(index >= 0);
      // if (allowEmptySlots) {
      // PlayingCard? existedCard;
      // for (final c in cards) {
      //   if (c.index == index) {
      //     existedCard = c;
      //   }
      // }
      // if (existedCard != null) {
      //   // existedCard.index =
      // }
      // } else {
      if (index >= cards.length) {
        if (isFull) return;
        index = cards.length;
      } else {
        for (var i = index; i < cards.length; ++i) {
          final existedCard = cards[i];
          ++existedCard.index;
        }
      }
      // }
      // if (index > _largestIndex) {
      //   _largestIndex = index;
      // }
    }

    card.index = index;
    cards.add(card);
    card.pile = this;
    // if (cardState != null) card.state = cardState!;

    // card.onAddedToPileZone?.call(this);

    onPileChanged?.call();
    return sortCards(animated: animated, onComplete: onComplete);
  }

  Future<void> reorderCard(
    int oldIndex,
    int newIndex, {
    bool insertAndRearrangeAll = false,
  }) async {
    GameCard? cardOnOldIndex;
    // PlayingCard? cardOnNewIndex;

    if (oldIndex != newIndex) {
      // if (allowEmptySlots) {
      //   for (final card in cards) {
      //     if (card.index == oldIndex) {
      //       cardOnOldIndex = card;
      //     } else if (card.index == newIndex) {
      //       cardOnNewIndex = card;
      //     }
      //   }

      //   cardOnOldIndex?.index = newIndex;
      //   cardOnNewIndex?.index = oldIndex;
      // } else {
      assert(oldIndex >= 0 && oldIndex < cards.length);
      cardOnOldIndex = cards[oldIndex];

      if (newIndex < 0) newIndex = 0;
      if (newIndex >= cards.length) newIndex = cards.length - 1;
      // cardOnNewIndex = cards[newIndex];

      cardOnOldIndex.index = newIndex;
      if (oldIndex < newIndex) {
        for (var i = oldIndex + 1; i <= newIndex; ++i) {
          final card = cards[i];
          --card.index;
        }
      } else {
        for (var i = newIndex; i < oldIndex; ++i) {
          final card = cards[i];
          ++card.index;
        }
      }
      // }
    }

    return sortCards();
  }

  /// 整理卡牌。如果 animated 为 true，则会用动画过度卡牌整理的过程
  Future<void> sortCards({
    bool animated = true,
    int? basePriority,
    void Function()? onComplete,
    bool reversed = false,
  }) async {
    basePriority ??= cardBasePriority;

    final completer = Completer();
    void onSortComplete() {
      onComplete?.call();
      completer.complete();
    }

    void setCardPriority(GameCard card, int index) {
      // pile.add(card.id);
      if (pileStyle == PileStyle.queue) {
        card.preferredPriority = basePriority! - index;
      } else if (pileStyle == PileStyle.stack) {
        card.preferredPriority = basePriority! + index;
      }
      card.resetPriority();
    }

    cards.sort((c1, c2) =>
        reversed ? c2.index.compareTo(c1.index) : c1.index.compareTo(c2.index));
    // pile.clear();

    // TODO: 有empty slots时，不重新赋值index
    for (var i = 0; i < cards.length; ++i) {
      cards[i].index = i;
      setCardPriority(cards[i], i);
    }

    _updateCenteringOffset();

    for (var i = 0; i < cards.length; ++i) {
      final card = cards[i];

      final endPosition = getCardNormalPosition(card, i);

      if (focusedOffset != null) card.focusedOffset = focusedOffset;
      if (focusedPosition != null) card.focusedPosition ??= focusedPosition;
      if (focusedSize != null) card.focusedSize ??= focusedSize;

      if (animated) {
        // card.enableGesture = false;
        card.moveTo(
          toPosition: endPosition,
          toSize: piledCardSize,
          duration: 0.5,
          curve: Curves.decelerate,
          onComplete: () {
            // card.enableGesture = true;
            if (i == cards.length - 1) {
              onSortComplete();
            }
          },
        );
      } else {
        card.position = endPosition;
        card.size = piledCardSize;
      }
    }

    if (!animated) {
      onSortComplete();
    }

    return completer.future;
  }

  GameCard? removeCardByIndex(int index, {bool sort = true}) {
    if (index < 0 || index >= cards.length) return null;

    final card = cards[index];
    card.removeFromParent();

    cards.removeAt(index);

    if (sort) {
      sortCards();
    }

    onPileChanged?.call();
    return card;
  }

  GameCard? removeCardById(String id, {bool sort = true}) {
    final index = cards.indexWhere((card) => card.id == id);

    return removeCardByIndex(index, sort: sort);
  }

  void _updateCenteringOffset() {
    if (!centerCards || cards.isEmpty) {
      _centeringOffset = Vector2.zero();
      return;
    }

    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;

    for (var i = 0; i < cards.length; ++i) {
      final card = cards[i];
      final pos = _getCardRawPosition(card, i);
      final left = pos.x - card.anchor.x * piledCardSize.x;
      final top = pos.y - card.anchor.y * piledCardSize.y;
      minX = math.min(minX, left);
      minY = math.min(minY, top);
      maxX = math.max(maxX, left + piledCardSize.x);
      maxY = math.max(maxY, top + piledCardSize.y);
    }

    final bboxCenter = Vector2((minX + maxX) / 2, (minY + maxY) / 2);

    final isChildOfSelf = cards.first.parent == this;
    final zoneCenter = isChildOfSelf
        ? Vector2(width / 2, height / 2)
        : Vector2(position.x + width / 2, position.y + height / 2);

    _centeringOffset = zoneCenter - bboxCenter;
  }

  /// 不含居中偏移的原始位置
  Vector2 _getCardRawPosition(GameCard card, int index) {
    Vector2 startPosition;

    if (pileStartPosition != null) {
      startPosition = pileStartPosition!;
    } else {
      if (card.parent == this) {
        startPosition = Vector2.zero();
      } else {
        startPosition = Vector2(
            (pileOffset.x.sign >= 0 ? position.x : position.x + width),
            (pileOffset.y.sign >= 0 ? position.y : position.y + height));
      }
    }

    return Vector2(
      startPosition.x +
          piledCardSize.x *
              (pileOffset.x.sign >= 0 ? card.anchor.x : (1 - card.anchor.x)) *
              (pileOffset.x.sign >= 0 ? 1 : -1) +
          index * pileOffset.x,
      startPosition.y +
          piledCardSize.y *
              (pileOffset.y.sign >= 0 ? card.anchor.y : (1 - card.anchor.y)) *
              (pileOffset.y.sign >= 0 ? 1 : -1) +
          index * pileOffset.y,
    );
  }

  /// 计算指定卡牌在指定索引处的正常位置（不含散开偏移）
  Vector2 getCardNormalPosition(GameCard card, int index) {
    return _getCardRawPosition(card, index) + _centeringOffset;
  }

  /// 当牌堆中的卡牌focus状态变化时调用，用于散开/恢复卡牌位置
  void onCardFocusChanged(GameCard card, bool focused) {
    if (!spreadOnFocus) return;
    // 无论是聚焦还是取消聚焦，都根据当前实际状态来决定散开或恢复
    GameCard? currentFocused;
    for (final c in cards) {
      if (c.isFocused) {
        currentFocused = c;
        break;
      }
    }
    if (currentFocused != null) {
      _applySpread(currentFocused);
    } else {
      _resetSpread();
    }
  }

  /// 将其他卡牌散开，为聚焦的卡牌腾出空间
  void _applySpread(GameCard focusedCard) {
    final focusIndex = cards.indexOf(focusedCard);
    if (focusIndex < 0) return;

    // 只在使用focusedOffset（卡牌相对位移放大）时才散开，
    // 使用focusedPosition（卡牌跳到固定位置）时不需要散开
    if (focusedCard.focusedOffset == null) return;

    final normalW = piledCardSize.x;
    final normalH = piledCardSize.y;
    final focusedW = focusedCard.focusedSize?.x ?? normalW;
    final focusedH = focusedCard.focusedSize?.y ?? normalH;
    final dx = focusedCard.focusedOffset!.x;
    final dy = focusedCard.focusedOffset!.y;

    // 聚焦卡牌在各方向的最大扩展量，前后卡牌使用相同的偏移值
    final spreadX = (focusedW - normalW) / 2 + dx.abs() + spreadMargin;
    final spreadY = (focusedH - normalH) / 2 + dy.abs() + spreadMargin;

    for (var i = 0; i < cards.length; ++i) {
      final card = cards[i];
      if (card.isFocused) continue;

      final normalPos = getCardNormalPosition(card, card.index);

      double shiftX = 0, shiftY = 0;
      if (pileOffset.x != 0) {
        shiftX = (i < focusIndex ? -1 : 1) * spreadX;
        if (pileOffset.x < 0) shiftX = -shiftX;
      }
      if (pileOffset.y != 0) {
        shiftY = (i < focusIndex ? -1 : 1) * spreadY;
        if (pileOffset.y < 0) shiftY = -shiftY;
      }

      card.snapTo(toPosition: normalPos + Vector2(shiftX, shiftY));
    }
  }

  /// 恢复所有卡牌到正常位置
  void _resetSpread() {
    for (var i = 0; i < cards.length; ++i) {
      final card = cards[i];
      if (card.isFocused) continue;
      final normalPos = getCardNormalPosition(card, card.index);
      card.snapTo(toPosition: normalPos);
    }
  }

  // @override
  // void render(Canvas canvas) {
  //   // if (title != null) {
  //   //   drawScreenText(canvas, '$title：${cards.length}', config: titleStyle);
  //   // }

  //   // canvas.drawRRect(rborder, DefaultBorderPaint.light);
  // }
}
