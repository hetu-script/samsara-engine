import 'package:flutter/material.dart';

import '../../global.dart';

enum GameDropMenuItems { console, quit }

class GameDropMenu extends StatelessWidget {
  const GameDropMenu({super.key, required this.onSelected});

  final void Function(GameDropMenuItems)? onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(5.0)),
        border: Border.all(color: Colors.white),
      ),
      child: PopupMenuButton<GameDropMenuItems>(
        offset: const Offset(0, 45),
        icon: const Icon(Icons.menu_open),
        tooltip: engine.locale['menu'],
        onSelected: onSelected,
        itemBuilder: (BuildContext context) =>
            <PopupMenuEntry<GameDropMenuItems>>[
          PopupMenuItem<GameDropMenuItems>(
            height: 24.0,
            value: GameDropMenuItems.console,
            child: Container(
              alignment: Alignment.centerLeft,
              width: 100,
              child: Text(engine.locale['console']),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<GameDropMenuItems>(
            height: 24.0,
            value: GameDropMenuItems.quit,
            child: Container(
              alignment: Alignment.centerLeft,
              width: 100,
              child: Text(engine.locale['quit']),
            ),
          ),
        ],
      ),
    );
  }
}
