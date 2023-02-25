import 'dart:async';

import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';

import '../playing_card.dart';
import '../../paint/paint.dart';

class PiledZone extends GameComponent with HandlesGesture {
  final String? id;
  final String? title;

  final double borderRadius;
  late final Rect border;
  late final RRect rborder;

  final List<PlayingCard> cards = [];
  final int piledCardPriority;
  final Vector2 piledCardSize;

  final Vector2 pileMargin, pileOffset, focusOffset;

  final Anchor titleAnchor;
  final bool isVericalPile;

  PiledZone({
    this.id,
    this.title,
    required double x,
    required double y,
    required double width,
    required double height,
    this.borderRadius = 5.0,
    List<PlayingCard> cards = const [],
    this.piledCardPriority = 0,
    required this.piledCardSize,
    Vector2? pileMargin,
    Vector2? pileOffset,
    Vector2? focusOffset,
    this.titleAnchor = Anchor.topLeft,
    this.isVericalPile = false,
  })  : pileMargin = pileMargin ?? Vector2(10.0, 10.0),
        pileOffset = pileOffset ?? Vector2(50.0, 50.0),
        focusOffset = focusOffset ?? Vector2.zero() {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    generateBorder();
    this.cards.addAll(cards);
  }

  @override
  void onLoad() async {
    if (cards.isNotEmpty) {
      sortCards();
    }
  }

  void generateBorder() {
    border = Rect.fromLTWH(0, 0, width, height);
    rborder =
        RRect.fromLTRBR(0, 0, width, height, Radius.circular(borderRadius));
  }

  /// 如果传入 completer 参数，则会用动画过度卡牌整理的过程
  void sortCards({Completer? completer}) {
    // calculate the new position of each hand cards.
    for (var i = 0; i < cards.length; ++i) {
      final card = cards[i];
      card.priority = piledCardPriority + i;

      final endPosition = Vector2(
          x + (isVericalPile ? 0 : i * pileOffset.x) + pileMargin.x,
          y + (isVericalPile ? i * pileOffset.y : 0) + pileMargin.y);

      if (completer == null) {
        card.position = endPosition;
        card.size = piledCardSize;
      } else {
        final drawingAnimation = AdvancedMoveEffect(
          target: card,
          controller: EffectController(duration: 0.4, curve: Curves.decelerate),
          startPosition: card.position,
          endPosition: endPosition,
          startSize: card.size,
          endSize: piledCardSize,
          onChange: () {
            card.generateBorder();
          },
          onComplete: () {
            card.enableGesture = true;
            card.focusOffset = focusOffset;
            card.showTitleOnHovering = true;

            card.position = endPosition;
            card.size = piledCardSize;
            card.generateBorder();
            card.showPreview = true;

            if (i == cards.length - 1) {
              completer.complete();
            }
          },
        );
        card.add(drawingAnimation);
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
      drawScreenText(
        canvas,
        '$title：${cards.length}',
        rect: border,
        anchor: titleAnchor,
        marginLeft: 10,
        marginTop: -10,
        marginRight: 10,
        marginBottom: -10,
      );
    }

    canvas.drawRRect(rborder, borderPaint);
  }
}
