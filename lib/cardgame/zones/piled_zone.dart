import 'dart:async';

import 'package:flutter/material.dart';

import '../../component/game_component.dart';
import '../../gestures.dart';
import '../playing_card.dart';
import '../../paint/paint.dart';

class PiledZone extends GameComponent with HandlesGesture {
  final String? id;
  final String? title;

  late ScreenTextStyle titleStyle;

  final List<PlayingCard> cards = [];
  final int piledCardPriority;
  final Vector2 piledCardSize;
  Vector2? focusedOffset, focusedPosition, focusedSize;

  final Vector2 pileMargin, pileOffset; //, focusOffset;

  final Anchor titleAnchor;

  /// [pileMargin] : 堆叠时第一张牌相对区域的x和y的位移
  ///
  /// [pileOffset] : 堆叠时每张牌相比上一张牌的位移
  PiledZone({
    this.id,
    this.title,
    required double x,
    required double y,
    required double width,
    required double height,
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
  })  : pileMargin = pileMargin ?? Vector2(10.0, 10.0),
        pileOffset = pileOffset ?? Vector2(50.0, 0.0),
        // focusOffset = focusOffset ?? Vector2.zero(),
        super(
          position: Vector2(x, y),
          size: Vector2(width, height),
        ) {
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

  /// 如果传入 completer 参数，则会用动画过度卡牌整理的过程
  void sortCards({bool pileUp = true, Completer? completer}) {
    // calculate the new position of each hand cards.
    for (var i = 0; i < cards.length; ++i) {
      final card = cards[i];
      card.priority = piledCardPriority + (pileUp ? i : -i);
      card.focusedOffset ??= focusedOffset;
      card.focusedPosition ??= focusedPosition;
      card.focusedSize ??= focusedSize;

      final endPosition = Vector2(
        // 如果堆叠方向是向右，则从区域右侧开始计算x偏移
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

      if (completer == null) {
        card.position = endPosition;
        card.size = piledCardSize;
      } else {
        card.moveTo(
          position: endPosition,
          size: piledCardSize,
          duration: 0.4,
          curve: Curves.decelerate,
          onComplete: () {
            card.enableGesture = true;
            // card.focusOffset = focusOffset;
            card.showTitleOnHovering = true;
            // card.generateBorder();
            card.focusOnHovering = true;

            if (i == cards.length - 1) {
              completer.complete();
            }
          },
        );
      }
    }
  }

  void addCard(PlayingCard card, Completer completer) {
    card.state = CardState.hand;
    cards.add(card);

    sortCards(completer: completer);
  }

  void removeCard(String id) {
    cards.removeWhere((card) => card.id == id);
  }

  @override
  void render(Canvas canvas) {
    if (title != null) {
      drawScreenText(canvas, '$title：${cards.length}', style: titleStyle);
    }

    canvas.drawRRect(rborder, DefaultBorderPaint.light);
  }
}
