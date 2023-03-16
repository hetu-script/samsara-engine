import 'dart:async';

import '../../component/game_component.dart';
import '../playing_card.dart';
import '../../paint.dart';

class PiledZone extends GameComponent {
  String? ownedByRole;

  final String? title;

  ScreenTextStyle? titleStyle;

  final List<PlayingCard> cards = [];

  /// 按照卡牌 deckId 统计此区域中卡牌的数量
  Map<String, int> count = {};

  /// 按照卡牌 ID 生成的列表，可能出现重复的ID
  List<String> pile = [];

  final int piledCardPriority;
  final Vector2 piledCardSize;
  Vector2? focusedOffset, focusedPosition, focusedSize;

  final Vector2 pileMargin, pileOffset; //, focusOffset;

  final Anchor titleAnchor;
  final EdgeInsets titlePadding;

  final CardState? state;

  /// [pileMargin] : 堆叠时第一张牌相对区域的x和y的位移
  ///
  /// [pileOffset] : 堆叠时每张牌相比上一张牌的位移
  PiledZone({
    super.id,
    this.ownedByRole,
    this.title,
    super.position,
    super.size,
    super.borderRadius = 5.0,
    List<PlayingCard> cards = const [],
    this.piledCardPriority = 0,
    required this.piledCardSize,
    this.focusedOffset,
    this.focusedPosition,
    this.focusedSize,
    Vector2? pileMargin,
    Vector2? pileOffset,
    this.titleAnchor = Anchor.topLeft,
    this.titlePadding = EdgeInsets.zero,
    this.state,
  })  : pileMargin = pileMargin ?? Vector2(10.0, 10.0),
        pileOffset = pileOffset ?? Vector2(50.0, 0.0) {
    if (this.pileMargin.x.sign != 0 && this.pileOffset.x.sign != 0) {
      assert(this.pileMargin.x.sign == this.pileOffset.x.sign, '堆叠位移和方向必须一致！');
    }
    if (this.pileMargin.y.sign != 0 && this.pileOffset.y.sign != 0) {
      assert(this.pileMargin.y.sign == this.pileOffset.y.sign, '堆叠位移和方向必须一致！');
    }

    this.cards.addAll(cards);

    titleStyle = ScreenTextStyle(
      rect: border,
      anchor: titleAnchor,
      padding: titlePadding,
    );
  }

  @override
  void generateBorder() {
    super.generateBorder();

    titleStyle = titleStyle?.copyWith(rect: border);
  }

  @override
  void onLoad() async {
    if (cards.isNotEmpty) {
      sortCards();
    }
  }

  Future<void> addCard(
    PlayingCard card, {
    int? index,
    bool animated = true,
    void Function()? onComplete,
  }) async {
    if (cards.contains(card)) return;

    final ec = count[card.deckId];
    if (ec != null) {
      count[card.deckId] = ec + 1;
    } else {
      count[card.deckId] = 1;
    }

    if (index == null) {
      index = cards.length;
    } else {
      assert(index >= 0);
      if (index > cards.length) {
        index = cards.length;
      }
    }

    card.index = index;
    cards.insert(index, card);
    if (state != null) card.state = state!;

    return sortCards(animated: animated, onComplete: onComplete);
  }

  /// 整理卡牌。如果 animated 为 true，则会用动画过度卡牌整理的过程
  Future<void> sortCards({
    bool pileUp = true,
    bool animated = true,
    void Function()? onComplete,
  }) async {
    final completer = Completer();

    cards.sort((c1, c2) => c1.index.compareTo(c2.index));
    pile.clear();
    // calculate the new position of each hand cards.
    for (var i = 0; i < cards.length; ++i) {
      final card = cards[i];
      pile.add(card.id);
      card.priority = piledCardPriority + (pileUp ? i : -i);

      final endPosition = Vector2(
        // 如果堆叠方向是向右，则从区域左侧开始计算x偏移
        (pileOffset.x.sign >= 0 ? x : x + width) +
            piledCardSize.x *
                (pileOffset.x.sign >= 0 ? card.anchor.x : (1 - card.anchor.x)) *
                (pileOffset.x.sign >= 0 ? 1 : -1) +
            i * pileOffset.x +
            pileMargin.x,
        // 如果堆叠方向是向上，则从区域下侧开始计算y偏移
        (pileOffset.y.sign >= 0 ? y : y + height) +
            piledCardSize.y *
                (pileOffset.y.sign >= 0 ? card.anchor.y : (1 - card.anchor.y)) *
                (pileOffset.y.sign >= 0 ? 1 : -1) +
            i * pileOffset.y +
            pileMargin.y,
      );

      if (card.position == endPosition && card.size == piledCardSize) continue;

      if (focusedOffset != null) card.focusedOffset = focusedOffset;
      if (focusedPosition != null) card.focusedPosition ??= focusedPosition;
      if (focusedSize != null) card.focusedSize ??= focusedSize;

      if (animated) {
        card.moveTo(
          position: endPosition,
          size: piledCardSize,
          duration: 0.5,
          curve: Curves.decelerate,
          onComplete: () {
            onComplete?.call();
            if (i == cards.length - 1) {
              completer.complete();
            }
          },
        );
      } else {
        card.position = endPosition;
        card.size = piledCardSize;
      }
    }

    if (!animated) {
      completer.complete();
    }

    return completer.future;
  }

  bool removeCard(String id) {
    final i = cards.indexWhere((card) => card.id == id);
    if (i == -1) return false;

    final card = cards[i];

    cards.removeAt(i);
    pile.removeAt(i);

    final ec = count[card.deckId]!;
    if (ec == 1) {
      count.remove(card.deckId);
    } else {
      count[card.deckId] = ec - 1;
    }
    return true;
  }

  @override
  void render(Canvas canvas) {
    if (title != null) {
      drawScreenText(canvas, '$title：${cards.length}', style: titleStyle);
    }

    canvas.drawRRect(rborder, DefaultBorderPaint.light);
  }
}
