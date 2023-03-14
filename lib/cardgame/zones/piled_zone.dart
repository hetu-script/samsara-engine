import 'dart:async';

import 'package:flutter/material.dart';
import 'package:samsara/task.dart';

import '../../component/game_component.dart';
import '../playing_card.dart';
import '../../paint.dart';

class PiledZone extends GameComponent {
  final String? title;

  late ScreenTextStyle titleStyle;

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

  final CardState? state;

  /// [pileMargin] : 堆叠时第一张牌相对区域的x和y的位移
  ///
  /// [pileOffset] : 堆叠时每张牌相比上一张牌的位移
  PiledZone({
    super.id,
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
      padding: const EdgeInsets.fromLTRB(10, -10, 10, -10),
    );
  }

  @override
  void onLoad() async {
    if (cards.isNotEmpty) {
      sortCards();
    }
  }

  Future<void> addCard(PlayingCard card, {int? index}) {
    assert(!cards.contains(card));

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

    return sortCards(schedule: true);
  }

  /// 整理卡牌
  ///
  /// 如果 animated 为 true，则会用动画过度卡牌整理的过程
  ///
  /// 如果 schedule 为 true，则整理卡牌时会等待上一个动画完成
  Future<void> sortCards(
      {bool pileUp = true, bool animated = true, bool schedule = false}) async {
    final completer = Completer();

    cards.sort((c1, c2) => c1.index.compareTo(c2.index));
    pile.clear();
    // calculate the new position of each hand cards.
    for (var i = 0; i < cards.length; ++i) {
      final card = cards[i];
      pile.add(card.id);
      card.priority = piledCardPriority + (pileUp ? i : -i);
      if (focusedOffset != null) card.focusedOffset = focusedOffset;
      if (focusedPosition != null) card.focusedPosition ??= focusedPosition;
      if (focusedSize != null) card.focusedSize ??= focusedSize;

      final endPosition = Vector2(
        // 如果堆叠方向是向右，则从区域左侧开始计算x偏移
        (pileOffset.x.sign >= 0 ? x : x + width) +
            // 如果堆叠方向是向右，则卡牌 anchor 算作右侧
            (pileOffset.x.sign >= 0 ? card.anchor.x : (1 - card.anchor.x)) *
                piledCardSize.x *
                pileOffset.x.sign +
            i * pileOffset.x +
            pileMargin.x,
        // 如果堆叠方向是向上，则从区域下侧开始计算y偏移
        (pileOffset.y.sign >= 0 ? y : y + height) +
            // 如果堆叠方向是向上，则卡牌 anchor 算作下侧
            (pileOffset.y.sign >= 0 ? card.anchor.y : (1 - card.anchor.y)) *
                piledCardSize.y *
                pileOffset.y.sign +
            i * pileOffset.y +
            pileMargin.y,
      );

      if (animated) {
        Future<void> animation() {
          return card.moveTo(
            position: endPosition,
            size: piledCardSize,
            duration: 0.5,
            curve: Curves.decelerate,
            onComplete: () {
              card.enableGesture = true;
              card.showTitleOnHovering = true;
              card.focusOnHovering = true;
              if (i == cards.length - 1) {
                completer.complete();
              }
            },
          );
        }

        if (schedule) {
          Task.schedule(animation);
        } else {
          animation();
        }
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

  void removeCard(String id) {
    final i = cards.indexWhere((card) => card.id == id);
    if (i == -1) return;

    final card = cards[i];

    final ec = count[card.deckId]!;
    if (ec == 1) {
      count.remove(card.deckId);
    } else {
      count[card.deckId] = ec - 1;
    }

    pile.remove(card.id);
  }

  @override
  void render(Canvas canvas) {
    if (title != null) {
      drawScreenText(canvas, '$title：${cards.length}', style: titleStyle);
    }

    canvas.drawRRect(rborder, DefaultBorderPaint.light);
  }
}
