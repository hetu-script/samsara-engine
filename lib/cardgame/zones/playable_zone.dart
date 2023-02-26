import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';

import '../playing_card.dart';
import '../../paint/paint.dart';

abstract class PlayableZone extends GameComponent with HandlesGesture {
  final String? id;
  final String? title;

  bool isHighlighted = false;

  PlayingCard? card;

  String? defense1, defense2, attack1, attack2;

  // @override
  // bool get enableGesture => card == null;

  final void Function()? onInteract, onRemoveCard;

  final bool mustRotateCard;

  final String kind;

  PlayableZone({
    this.id,
    this.title,
    required double x,
    required double y,
    required double width,
    required double height,
    super.borderRadius = 5.0,
    this.card,
    super.priority,
    required this.kind,
    this.onInteract,
    this.onRemoveCard,
    this.mustRotateCard = false,
  }) : super(
          position: Vector2(x, y),
          size: Vector2(width, height),
        );

  @override
  void render(Canvas canvas) {
    if (isHighlighted) {
      canvas.drawRRect(rborder, borderPaintFocused);
    } else {
      canvas.drawRRect(rborder, borderPaint);
    }

    if (title != null) {
      drawScreenText(
        canvas,
        title!,
        rect: border,
        anchor: Anchor.bottomCenter,
        marginBottom: -10,
      );
    }

    if (card?.title != null) {
      drawScreenText(
        canvas,
        card!.title!,
        rect: border,
        anchor: Anchor.topCenter,
        marginTop: -10,
        style: ScreenTextStyle.warning,
      );
    }

    if (attack1 != null) {
      drawScreenText(
        canvas,
        attack1!,
        rect: border,
        anchor: Anchor.bottomLeft,
        marginLeft: -30,
        style: ScreenTextStyle.warning,
      );
    }

    if (attack2 != null) {
      drawScreenText(
        canvas,
        attack2!,
        rect: border,
        anchor: Anchor.bottomLeft,
        marginLeft: -30,
        marginBottom: 20,
        style: ScreenTextStyle.warning,
      );
    }

    if (defense1 != null) {
      drawScreenText(
        canvas,
        defense1!,
        rect: border,
        anchor: Anchor.bottomRight,
        marginRight: -30,
        style: ScreenTextStyle.warning,
      );
    }

    if (defense2 != null) {
      drawScreenText(
        canvas,
        defense2!,
        rect: border,
        anchor: Anchor.bottomRight,
        marginRight: -30,
        marginBottom: 20,
        style: ScreenTextStyle.warning,
      );
    }
  }

  @override
  void onTap(int pointer, int buttons, TapUpDetails details) {
    onInteract?.call();
  }
}
