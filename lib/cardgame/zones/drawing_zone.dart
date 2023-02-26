import 'dart:async';

import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';

import '../playing_card.dart';
import '../action.dart';
import '../../../paint/paint.dart';

class DrawingZone extends GameComponent with HandlesGesture {
  final String? id;

  final Vector2 drawedCardPosition, drawedCardSize;

  final List<PlayingCard> cards;

  Anchor tooltipAnchor;

  DrawingZone({
    this.id,
    double x = 0,
    double y = 0,
    required double width,
    required double height,
    super.borderRadius = 5.0,
    required this.cards,
    required this.drawedCardPosition,
    required this.drawedCardSize,
    this.tooltipAnchor = Anchor.topCenter,
  }) : super(
          position: Vector2(x, y),
          size: Vector2(width, height),
        );

  // @override
  // Future<void> onLoad() async {
  //   super.onLoad();
  // }

  Future<void> drawOneCard({
    void Function(PlayingCard card, Completer completer)? onFinish,
    bool flip = true,
  }) async {
    if (cards.isEmpty) {
      return;
    }

    final drawingAction = Completer();
    // 不知道为什么，不能将下面的操作提取到 action.dart文件中，
    // 而只能以 inline 形式复制到这里使用才可以
    // await waitAllActions();
    bool check(GameAction action) =>
        action.completer != null ? !action.completer!.isCompleted : false;
    while (gameActions.any(check)) {
      await gameActions.firstWhere(check).completer!.future;
    }

    gameActions.add(GameAction(completer: drawingAction));
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
        Future.delayed(const Duration(milliseconds: 400)).then((value) {
          // drawingAction.complete();
          onFinish?.call(card, drawingAction);
        });
      },
    );
    return drawingAction.future;
  }

  @override
  void render(Canvas canvas) {
    if (isHovering) {
      drawScreenText(
        canvas,
        '数量：${cards.length}',
        rect: border,
        anchor: tooltipAnchor,
        marginTop: -30,
        marginBottom: -30,
      );
      // canvas.drawRRect(border, borderPaintFocused);
    }
    //  else {
    canvas.drawRRect(rborder, borderPaint);
    // }

    // for (final card in cards) {
    //   card.render(canvas, position: card.position);
    // }
  }

  @override
  void onTap(int pointer, int buttons, TapUpDetails details) {
    // drawOneCard();
  }

  @override
  void update(double dt) {
    //   _drawingAnimation?.update(dt);
  }
}
