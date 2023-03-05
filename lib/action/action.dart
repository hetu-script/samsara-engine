import 'dart:async';

final List<GameAction> gameActions = [];

class GameAction {
  final String? id;
  Completer? completer;

  GameAction({
    this.id,
    required this.completer,
  });

  GameAction.empty() : id = null;
}

Future<void> waitAllActions() async {
  bool check(GameAction action) =>
      action.completer != null ? !action.completer!.isCompleted : false;

  int index = gameActions.indexWhere(check);
  if (index == -1) return;

  do {
    final action = gameActions[index];
    await action.completer!.future;
    index = gameActions.indexWhere(check);
  } while (index != -1);
}
