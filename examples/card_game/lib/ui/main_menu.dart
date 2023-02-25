import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:samsara/flutter_ui/loading_screen.dart';
import 'package:samsara/flutter_ui/label.dart';
import 'package:flutter/services.dart';
import 'package:json5/json5.dart';

import '../global.dart';
import '../scene/cardgame.dart';
import 'overlay/main_game.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  @override
  void initState() {
    super.initState();

    engine.registerSceneConstructor('cardGame', ([dynamic data]) async {
      return CardGameScene(controller: engine);
    });
  }

  Future<bool> _prepareData() async {
    if (engine.isLoaded) return true;
    await engine.init();

    final localeStrings =
        await rootBundle.loadString('assets/locales/chs.json5');
    final localeData = JSON5.parse(localeStrings);
    engine.loadLocale(localeData);

    final cardsDataString =
        await rootBundle.loadString('assets/cards/cards.json5');
    cardsData = JSON5.parse(cardsDataString);

    engine.hetu.evalFile('main.ht', globallyImport: true);

    engine.isLoaded = true;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _prepareData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return LoadingScreen(
              text: engine.isLoaded ? engine.locale['loading'] : 'Loading...');
        } else {
          final menus = <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => MainGameOverlay(),
                  );
                },
                child: Label(
                  engine.locale['newGame'],
                  width: 100.0,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20.0, bottom: 100.0),
              child: ElevatedButton(
                onPressed: () {
                  windowManager.close();
                },
                child: Label(
                  engine.locale['exit'],
                  width: 100.0,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ];

          return Scaffold(
            body: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: menus,
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
