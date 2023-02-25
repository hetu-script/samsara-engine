import 'dart:async';

class GameAction {
  Completer? completer;

  GameAction({
    required this.completer,
  });

  GameAction.empty();
}

final List<GameAction> gameActions = [];

Future<void> waitAllActions() async {
  bool check(GameAction action) =>
      action.completer != null ? !action.completer!.isCompleted : false;

  while (gameActions.any(check)) {
    await gameActions.firstWhere(check).completer!.future;
  }
}
