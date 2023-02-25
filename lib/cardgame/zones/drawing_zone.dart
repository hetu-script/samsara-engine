import 'dart:async';

import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';
import 'package:flame/game.dart';
import 'package:flame/effects.dart';
import 'package:flame/components.dart';

import '../playing_card.dart';
import '../action.dart';
import '../../../paint/paint.dart';

class DrawingZone extends GameComponent with HandlesGesture {
  @override
  Camera get camera => gameRef.camera;

  final String id;

  final double borderRadius;
  late final Rect border;
  late final RRect rborder;

  final Vector2 drawedCardPosition, drawedCardSize;

  final List<PlayingCard> cards;

  Anchor tooltipAnchor;

  DrawingZone({
    required this.id,
    double x = 0,
    double y = 0,
    required double width,
    required double height,
    this.borderRadius = 5.0,
    required this.cards,
    required this.drawedCardPosition,
    required this.drawedCardSize,
    this.tooltipAnchor = Anchor.topCenter,
  }) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
    generateBorder();
  }

  void generateBorder() {
    border = Rect.fromLTWH(0, 0, width, height);
    rborder =
        RRect.fromLTRBR(0, 0, width, height, Radius.circular(borderRadius));
  }

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
    final drawingAnimation = AdvancedMoveEffect(
      target: card,
      controller: EffectController(duration: 0.6, curve: Curves.easeIn),
      startPosition: card.position,
      endPosition: drawedCardPosition,
      startSize: card.size,
      endSize: drawedCardSize,
      onChange: () {
        card.generateBorder();
      },
      onComplete: () {
        if (flip) {
          card.isFlipped = false;
        }
        Future.delayed(const Duration(milliseconds: 400)).then((value) {
          card.position = drawedCardPosition;
          card.size = drawedCardSize;
          card.generateBorder();
          // drawingAction.complete();
          onFinish?.call(card, drawingAction);
        });
      },
    );
    card.add(drawingAnimation);
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
