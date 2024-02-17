import '../event.dart';
import '../cardgame/cardgame.dart';

abstract class CardGameEvents {
  static const cardFocused = 'card_focused';
  static const cardPreviewed = 'card_previewed';

  static const battleStarted = 'battle_started';
  static const battleEnded = 'battle_ended';
}

class CardEvent extends GameEvent {
  final PlayingCard card;

  const CardEvent.cardFocused({super.scene, required this.card})
      : super(name: CardGameEvents.cardFocused);

  const CardEvent.cardPreviewed({super.scene, required this.card})
      : super(name: CardGameEvents.cardPreviewed);
}

class CardGameEvent extends GameEvent {
  final bool? heroWon;

  const CardGameEvent.battleStarted({super.scene})
      : heroWon = null,
        super(name: CardGameEvents.battleStarted);

  const CardGameEvent.battleEnded({super.scene, required this.heroWon})
      : super(name: CardGameEvents.battleEnded);
}
