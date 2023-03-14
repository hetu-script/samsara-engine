import 'dart:async';

import 'package:flutter/material.dart';

import '../../component/game_component.dart';
import '../../gestures.dart';
import '../playing_card.dart';
import '../../paint.dart';

class DrawingZone extends GameComponent with HandlesGesture {
  final Vector2 drawedCardPosition, drawedCardSize;

  /// the duration of the drawed card reveal time.
  double revealDuration;

  final List<PlayingCard> cards;

  Anchor tooltipAnchor;

  late ScreenTextStyle piledNumberStyle;

  DrawingZone({
    super.id,
    super.position,
    super.size,
    super.borderRadius = 5.0,
    required this.cards,
    required this.drawedCardPosition,
    required this.drawedCardSize,
    this.revealDuration = 0.4,
    this.tooltipAnchor = Anchor.topCenter,
  }) {
    piledNumberStyle = ScreenTextStyle(
      rect: border,
      anchor: tooltipAnchor,
      padding: const EdgeInsets.only(top: -30, bottom: -30),
    );
  }

  // @override
  // Future<void> onLoad() async {
  //   super.onLoad();
  // }

  Future<PlayingCard> drawOneCard({bool flip = true}) async {
    assert(cards.isNotEmpty);

    // final drawingAction = Completer();
    // 不知道为什么，不能将下面的操作提取到 action.dart文件中，
    // 而只能以 inline 形式复制到这里使用才可以
    // await waitAllActions();
    // bool check(GameAction action) =>
    //     action.completer != null ? !action.completer!.isCompleted : false;
    // while (gameActions.any(check)) {
    //   await gameActions.firstWhere(check).completer!.future;
    // }

    // gameActions.add(GameAction(completer: drawingAction));

    final completer = Completer<PlayingCard>();
    final card = cards.last;
    cards.removeLast();
    card.moveTo(
      position: drawedCardPosition,
      size: drawedCardSize,
      duration: 0.6,
      curve: Curves.easeIn,
      onComplete: () {
        if (flip) {
          card.isFlipped = false;
        }
        Future.delayed(Duration(milliseconds: (revealDuration * 1000).toInt()))
            .then((value) {
          completer.complete(card);
        });
      },
    );

    return completer.future;
  }

  @override
  void render(Canvas canvas) {
    if (isHovering) {
      drawScreenText(
        canvas,
        '数量：${cards.length}',
        style: piledNumberStyle,
      );
      // canvas.drawRRect(border, borderPaintFocused);
    }
    //  else {
    canvas.drawRRect(rborder, DefaultBorderPaint.light);
    // }

    // for (final card in cards) {
    //   card.render(canvas, position: card.position);
    // }
  }

  // @override
  // void onTap(int buttons, Vector2 position) {
  //   // drawOneCard();
  // }

  @override
  void update(double dt) {
    //   _drawingAnimation?.update(dt);
  }
}
