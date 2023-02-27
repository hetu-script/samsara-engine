import 'dart:async';

import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';

import '../playing_card.dart';
import '../../paint/paint.dart';

class PiledZone extends GameComponent with HandlesGesture {
  final String? id;
  final String? title;

  final List<PlayingCard> cards = [];
  final int piledCardPriority;
  final Vector2 piledCardSize;
  Vector2? focusedOffset, focusedPosition, focusedSize;

  final Vector2 pileMargin, pileOffset; //, focusOffset;

  final Anchor titleAnchor;

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
        pileOffset = pileOffset ?? Vector2(50.0, 50.0),
        // focusOffset = focusOffset ?? Vector2.zero(),
        super(
          position: Vector2(x, y),
          size: Vector2(width, height),
        ) {
    this.cards.addAll(cards);
  }

  @override
  void onLoad() async {
    if (cards.isNotEmpty) {
      sortCards();
    }
  }

  /// 如果传入 completer 参数，则会用动画过度卡牌整理的过程
  void sortCards({Completer? completer}) {
    // calculate the new position of each hand cards.
    for (var i = 0; i < cards.length; ++i) {
      final card = cards[i];
      card.priority = piledCardPriority + i;
      card.focusedOffset = focusedOffset;
      card.focusedPosition = focusedPosition;
      card.focusedSize = focusedSize;

      final endPosition = Vector2(
        x + card.anchor.x * piledCardSize.x + i * pileOffset.x + pileMargin.x,
        y + card.anchor.y * piledCardSize.y + i * pileOffset.y + pileMargin.y,
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
            card.showPreview = true;

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
