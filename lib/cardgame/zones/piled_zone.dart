import 'dart:async';

import '../../components/border_component.dart';
import '../card.dart';
import '../../paint/paint.dart';

enum PileStructure {
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

  final String? title;

  ScreenTextConfig? titleStyle;

  /// 是否允许堆叠
  final bool allowStack;

  /// 不允许堆叠时，可设置卡牌数量上限
  int limit;

  /// 是否达到了卡牌数量上限
  bool get reachedLimit => !allowStack && limit >= 0 && cards.length >= limit;

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

  /// [pileMargin] : 堆叠时第一张牌相对区域的x和y的位移
  late final Vector2 pileMargin;

  /// [pileOffset] : 堆叠时每张牌相比上一张牌的位移
  late final Vector2 pileOffset; //, focusOffset;

  final PileStructure pileStructure;
  final bool reverseX, reverseY;

  int pileTopPriority;

  final Anchor titleAnchor;
  final EdgeInsets titlePadding;

  // final String? cardState;

  // int _largestIndex = 0;

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
    List<GameCard> cards = const [],
    required this.piledCardSize,
    this.focusedOffset,
    this.focusedPosition,
    this.focusedSize,
    Vector2? pileMargin,
    Vector2? pileOffset,
    this.pileStructure = PileStructure.stack,
    this.reverseX = false,
    this.reverseY = false,
    this.pileTopPriority = 250,
    this.titleAnchor = Anchor.topLeft,
    this.titlePadding = EdgeInsets.zero,
    // this.cardState,
  }) {
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
    if (cards.isNotEmpty) {
      for (var i = 0; i <= cards.length - 1; ++i) {
        final card = cards[i];
        card.index = i;
      }
      this.cards.addAll(cards);
      sortCards(animated: false);
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
      if (reachedLimit) return;

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
        if (reachedLimit) return;
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
    void Function()? onComplete,
  }) async {
    final completer = Completer();

    void onSortComplete() {
      onComplete?.call();
      completer.complete();
    }

    cards.sort((c1, c2) => c1.index.compareTo(c2.index));
    // pile.clear();
    // calculate the new position of each hand cards.
    for (var i = 0; i < cards.length; ++i) {
      final card = cards[i];
      // pile.add(card.id);
      if (pileStructure == PileStructure.queue) {
        card.preferredPriority = priority + pileTopPriority - i;
      } else if (pileStructure == PileStructure.stack) {
        card.preferredPriority = priority + 1 + i;
      }
      card.resetPriority();

      // TODO: 有empty slots时，不重新赋值index
      card.index = i;

      final endPosition = Vector2(
        // 如果堆叠方向是向右，则从区域左侧开始计算x偏移
        (pileOffset.x.sign >= 0 ? x : x + width) +
            piledCardSize.x *
                (pileOffset.x.sign >= 0 ? card.anchor.x : (1 - card.anchor.x)) *
                (pileOffset.x.sign >= 0 ? 1 : -1) +
            card.index * pileOffset.x +
            pileMargin.x,
        // 如果堆叠方向是向上，则从区域下侧开始计算y偏移
        (pileOffset.y.sign >= 0 ? y : y + height) +
            piledCardSize.y *
                (pileOffset.y.sign >= 0 ? card.anchor.y : (1 - card.anchor.y)) *
                (pileOffset.y.sign >= 0 ? 1 : -1) +
            card.index * pileOffset.y +
            pileMargin.y,
      );

      if (card.position == endPosition && card.size == piledCardSize) continue;

      if (focusedOffset != null) card.focusedOffset = focusedOffset;
      if (focusedPosition != null) card.focusedPosition ??= focusedPosition;
      if (focusedSize != null) card.focusedSize ??= focusedSize;

      if (animated) {
        card.enableGesture = false;
        card.moveTo(
          toPosition: endPosition,
          toSize: piledCardSize,
          duration: 0.5,
          curve: Curves.decelerate,
          onComplete: () {
            card.enableGesture = true;
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

  bool removeCardByIndex(int index, {bool sort = true}) {
    if (index < 0 || index >= cards.length) return false;

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
    return true;
  }

  bool removeCardById(String id, {bool sort = true}) {
    final index = cards.indexWhere((card) => card.id == id);

    return removeCardByIndex(index, sort: sort);
  }

  @override
  void render(Canvas canvas) {
    // if (title != null) {
    //   drawScreenText(canvas, '$title：${cards.length}', config: titleStyle);
    // }

    // canvas.drawRRect(rborder, DefaultBorderPaint.light);
  }
}
