import 'dart:async';

import '../../components/border_component.dart';
import '../card.dart';
import '../../paint/paint.dart';

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

  /// 是否允许堆叠
  final bool allowStack;

  /// 不允许堆叠时，可设置卡牌数量上限
  int limit;

  /// 是否达到了卡牌数量上限
  bool get isFull => !allowStack && limit >= 0 && cards.length >= limit;

  /// 不允许堆叠时，可设置是否为非紧凑型牌堆
  /// 即卡牌摆放时允许中间有空位
  // final bool allowEmptySlots;

  /// 按照卡牌 deckId 保存
  // Map<String, PlayingCard> cards = {};

  Map<String, int> count = {};
  List<GameCard> cards = [];

  bool containsCard(String deckId) => count.containsKey(deckId);

  /// 按照卡牌 ID 生成的列表，可能出现重复的ID
  // List<String> pile = [];

  final Vector2 piledCardSize;
  Vector2? focusedOffset, focusedPosition, focusedSize;

  /// [pileStartPosition] : 堆叠时的起始位置
  /// 如果此值为 null，则根据如下规则设定：
  /// 如果卡牌被添加到 zone 上，则起始位置为 (0,0)
  /// 否则起始位置为 zone 自己的位置
  Vector2? pileStartPosition;

  /// [pileMargin] : 堆叠时第一张牌相对起始点的x和y的位移
  late Vector2 pileMargin;

  /// [pileOffset] : 堆叠时每张牌相比上一张牌的位移
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

  @override
  set isVisible(bool value) {
    super.isVisible = value;
    for (final card in cards) {
      card.isVisible = value;
    }
  }

  /// [pileMargin] : 堆叠时第一张牌相对区域的x和y的位移
  ///
  /// [pileOffset] : 堆叠时每张牌相比上一张牌的位移
  PiledZone({
    this.ownedBy,
    this.title,
    super.priority,
    super.position,
    super.size,
    super.borderRadius = 5.0,
    this.allowStack = false,
    this.limit = -1,
    // this.allowEmptySlots = false,
    List<GameCard>? cards,
    required this.piledCardSize,
    this.focusedOffset,
    this.focusedPosition,
    this.focusedSize,
    this.pileStartPosition,
    Vector2? pileMargin,
    Vector2? pileOffset,
    this.pileStyle = PileStyle.stack,
    this.reverseX = false,
    this.reverseY = false,
    // this.pileTopPriority = 5000,
    this.titleAnchor = Anchor.topLeft,
    this.titlePadding = EdgeInsets.zero,
    // this.cardState,
    this.onPileChanged,
    int? cardBasePriority,
  }) : cardBasePriority =
            cardBasePriority ?? (pileStyle == PileStyle.stack ? 0 : 5000) {
    pileMargin ??= Vector2(10.0, 10.0);
    pileOffset ??= Vector2(50.0, 0.0);

    this.pileMargin = Vector2(
        pileMargin.x * (reverseX ? -1 : 1), pileMargin.y * (reverseY ? -1 : 1));
    this.pileOffset = Vector2(
        pileOffset.x * (reverseX ? -1 : 1), pileOffset.y * (reverseY ? -1 : 1));

    if (this.pileMargin.x.sign != 0 && this.pileOffset.x.sign != 0) {
      assert(this.pileMargin.x.sign == this.pileOffset.x.sign, '堆叠位移和方向必须一致！');
    }
    if (this.pileMargin.y.sign != 0 && this.pileOffset.y.sign != 0) {
      assert(this.pileMargin.y.sign == this.pileOffset.y.sign, '堆叠位移和方向必须一致！');
    }
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

    final existedNumber = count[card.deckId];
    if (allowStack && existedNumber != null) {
      count[card.deckId] = existedNumber + 1;
      final existedCard = cards.singleWhere((c) => c.deckId == card.deckId);
      existedCard.stack += 1;
      return;
    }

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

    if (existedNumber == null) {
      count[card.deckId] = 1;
    } else {
      count[card.deckId] = existedNumber + 1;
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
    // calculate the new position of each hand cards.
    for (var i = 0; i < cards.length; ++i) {
      final card = cards[i];

      Vector2 startPosition;

      if (pileStartPosition != null) {
        startPosition = pileStartPosition!;
      } else {
        if (card.parent == this) {
          startPosition = Vector2.zero();
        } else {
          startPosition = Vector2(
              // 如果堆叠方向是向右，则从区域左侧开始计算x偏移
              (pileOffset.x.sign >= 0 ? position.x : position.x + width),
              // 如果堆叠方向是向上，则从区域下侧开始计算y偏移
              (pileOffset.y.sign >= 0 ? position.y : position.y + height));
        }
      }

      // TODO: 有empty slots时，不重新赋值index
      card.index = i;

      setCardPriority(card, i);

      final endPosition = Vector2(
        startPosition.x +
            piledCardSize.x *
                (pileOffset.x.sign >= 0 ? card.anchor.x : (1 - card.anchor.x)) *
                (pileOffset.x.sign >= 0 ? 1 : -1) +
            card.index * pileOffset.x +
            pileMargin.x,
        startPosition.y +
            piledCardSize.y *
                (pileOffset.y.sign >= 0 ? card.anchor.y : (1 - card.anchor.y)) *
                (pileOffset.y.sign >= 0 ? 1 : -1) +
            card.index * pileOffset.y +
            pileMargin.y,
      );

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
    if (allowStack && card.stack > 1) {
      --card.stack;
    } else {
      cards.removeAt(index);
      // pile.removeAt(cardIndex);
    }

    final ec = count[card.deckId]!;
    if (ec == 1) {
      count.remove(card.deckId);
    } else {
      count[card.deckId] = ec - 1;
    }

    card.removeFromParent();
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

  // @override
  // void render(Canvas canvas) {
  //   // if (title != null) {
  //   //   drawScreenText(canvas, '$title：${cards.length}', config: titleStyle);
  //   // }

  //   // canvas.drawRRect(rborder, DefaultBorderPaint.light);
  // }
}
