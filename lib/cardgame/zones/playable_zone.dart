import '../../component/game_component.dart';
import '../../gestures.dart';
import '../playing_card.dart';
import '../../paint.dart';

abstract class PlayableZone extends GameComponent with HandlesGesture {
  @override
  String get id => super.id!;
  String? ownedByRole;
  String? gameView;

  bool ownedBy(String? player) {
    if (player == null) return false;
    return ownedByRole == player;
  }

  final String? title;

  bool isHighlighted = false;

  PlayingCard? card;

  String? defense1, defense2, attack1, attack2;
  ScreenTextStyle? titleStyle,
      cardTitleStyle,
      defense1Style,
      defense2Style,
      attack1Style,
      attack2Style;

  // @override
  // bool get enableGesture => card == null;

  final void Function(PlayableZone zone)? onInteract;

  final bool needRotate;
  final bool needFlip;

  final String kind;

  PlayableZone({
    required String id,
    this.ownedByRole,
    this.gameView,
    this.title,
    super.position,
    super.size,
    super.borderRadius = 5.0,
    this.card,
    super.priority,
    required this.kind,
    this.onInteract,
    this.needRotate = false,
    this.needFlip = false,
  }) : super(id: id) {
    titleStyle = ScreenTextStyle(
      rect: border,
      anchor: Anchor.bottomCenter,
      padding: const EdgeInsets.only(bottom: -5),
    );
    cardTitleStyle = ScreenTextStyle(
      rect: border,
      anchor: Anchor.topCenter,
      padding: const EdgeInsets.only(top: -5),
      colorTheme: ScreenTextColorTheme.warning,
    );
    attack1Style = ScreenTextStyle(
      rect: border,
      anchor: Anchor.bottomLeft,
      padding: const EdgeInsets.only(left: -35),
      colorTheme: ScreenTextColorTheme.warning,
    );
    attack2Style = ScreenTextStyle(
      rect: border,
      anchor: Anchor.bottomLeft,
      padding: const EdgeInsets.only(left: -35, bottom: 20),
      colorTheme: ScreenTextColorTheme.warning,
    );
    defense1Style = ScreenTextStyle(
      rect: border,
      anchor: Anchor.bottomRight,
      padding: const EdgeInsets.only(right: -35),
      colorTheme: ScreenTextColorTheme.warning,
    );
    defense2Style = ScreenTextStyle(
      rect: border,
      anchor: Anchor.bottomRight,
      padding: const EdgeInsets.only(right: -35, bottom: -10),
      colorTheme: ScreenTextColorTheme.warning,
    );

    onTap = (buttons, position) {
      onInteract?.call(this);
    };
  }

  @override
  void generateBorder() {
    super.generateBorder();

    titleStyle = titleStyle?.copyWith(rect: border);
    cardTitleStyle = cardTitleStyle?.copyWith(rect: border);
    attack1Style = attack1Style?.copyWith(rect: border);
    attack2Style = attack2Style?.copyWith(rect: border);
    defense1Style = defense1Style?.copyWith(rect: border);
    defense2Style = defense2Style?.copyWith(rect: border);
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

    if (card != null) {
      if (gameView == ownedByRole || !card!.isFlipped) {
        drawScreenText(canvas, card!.title!, style: cardTitleStyle);
      }
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
}
