import '../../event.dart';
import '../cardgame.dart';

abstract class CardEvents extends GameEvents {
  static const cardFocused = 'card_focused';
  static const cardUnfocused = 'card_unfocused';
  static const cardPreviewed = 'card_previewed';
  static const cardUnpreviewed = 'card_unpreviewed';
}

class CardEvent extends GameEvent {
  final PlayingCard card;

  const CardEvent.cardFocused({super.scene, required this.card})
      : super(name: CardEvents.cardFocused);

  const CardEvent.cardUnfocused({super.scene, required this.card})
      : super(name: CardEvents.cardUnfocused);

  const CardEvent.cardPreviewed({super.scene, required this.card})
      : super(name: CardEvents.cardPreviewed);

  const CardEvent.cardUnpreviewed({super.scene, required this.card})
      : super(name: CardEvents.cardUnpreviewed);
}
