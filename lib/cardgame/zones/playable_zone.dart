import '../../component/game_component.dart';
import '../../gestures.dart';
import '../playing_card.dart';
import '../../paint.dart';

abstract class PlayableZone extends GameComponent with HandlesGesture {
  final String? id;
  final String? title;

  bool isHighlighted = false;

  PlayingCard? card;

  String? defense1, defense2, attack1, attack2;
  late ScreenTextStyle titleStyle,
      cardTitleStyle,
      defense1Style,
      defense2Style,
      attack1Style,
      attack2Style;

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
        ) {
    titleStyle = ScreenTextStyle(
      rect: border,
      anchor: Anchor.bottomCenter,
      padding: const EdgeInsets.only(bottom: -10),
    );
    cardTitleStyle = ScreenTextStyle(
      rect: border,
      anchor: Anchor.topCenter,
      padding: const EdgeInsets.only(top: -10),
      colorTheme: ScreenTextColorTheme.warning,
    );
    attack1Style = ScreenTextStyle(
      rect: border,
      anchor: Anchor.bottomLeft,
      padding: const EdgeInsets.only(left: -30),
      colorTheme: ScreenTextColorTheme.warning,
    );
    attack2Style = ScreenTextStyle(
      rect: border,
      anchor: Anchor.bottomLeft,
      padding: const EdgeInsets.only(left: -30, bottom: 20),
      colorTheme: ScreenTextColorTheme.warning,
    );
    defense1Style = ScreenTextStyle(
      rect: border,
      anchor: Anchor.bottomRight,
      padding: const EdgeInsets.only(right: -30),
      colorTheme: ScreenTextColorTheme.warning,
    );
    defense2Style = ScreenTextStyle(
      rect: border,
      anchor: Anchor.bottomRight,
      padding: const EdgeInsets.only(right: -30, bottom: -10),
      colorTheme: ScreenTextColorTheme.warning,
    );
  }

  @override
  void render(Canvas canvas) {
    if (isHighlighted) {
      canvas.drawRRect(rborder, DefaultBorderPaint.warning);
    } else {
      canvas.drawRRect(rborder, DefaultBorderPaint.light);
    }

    if (title != null) {
      drawScreenText(canvas, title!, style: titleStyle);
    }

    if (card?.title != null) {
      drawScreenText(canvas, card!.title!, style: cardTitleStyle);
    }

    if (attack1 != null) {
      drawScreenText(canvas, attack1!, style: attack1Style);
    }

    if (attack2 != null) {
      drawScreenText(canvas, attack2!, style: attack2Style);
    }

    if (defense1 != null) {
      drawScreenText(canvas, defense1!, style: defense1Style);
    }

    if (defense2 != null) {
      drawScreenText(canvas, defense2!, style: defense2Style);
    }
  }

  @override
  void onTap(int buttons, Vector2 position) {
    onInteract?.call();
  }
}
