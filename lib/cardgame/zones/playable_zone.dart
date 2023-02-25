import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';
import 'package:flame/game.dart';

import '../playing_card.dart';
import '../../paint/paint.dart';

abstract class PlayableZone extends GameComponent with HandlesGesture {
  @override
  Camera get camera => gameRef.camera;

  final String id;
  final String? title;

  final double borderRadius;
  late final Rect border;
  late final RRect rborder;

  bool isHighlighted = false;

  PlayingCard? card;

  String? defense1, defense2, attack1, attack2;

  // @override
  // bool get enableGesture => card == null;

  final void Function()? onInteract, onRemoveCard;

  final bool mustRotateCard;

  final String kind;

  PlayableZone({
    required this.id,
    this.title,
    required double x,
    required double y,
    required double width,
    required double height,
    this.borderRadius = 5.0,
    this.card,
    super.priority,
    required this.kind,
    this.onInteract,
    this.onRemoveCard,
    this.mustRotateCard = false,
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
