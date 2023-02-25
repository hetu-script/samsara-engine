import 'package:samsara/event.dart';
import 'package:samsara/cardgame/cardgame.dart';

abstract class CardEvents extends Events {
  static const cardFocused = 'card_focused';
  static const cardUnfocused = 'card_unfocused';
}

class CardEvent extends GameEvent {
  final PlayingCard component;

  const CardEvent.cardFocused({super.scene, required this.component})
      : super(name: CardEvents.cardFocused);

  const CardEvent.cardUnfocused({super.scene, required this.component})
      : super(name: CardEvents.cardUnfocused);
}
