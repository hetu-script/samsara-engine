import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:samsara/ui/loading_screen.dart';
import 'package:samsara/ui/label.dart';
// import 'package:json5/json5.dart';
import 'package:samsara/widget/markdown_wiki.dart';
import 'package:samsara/widget/embedded_text.dart';

import '../global.dart';
import '../scene/game.dart';
import '../scene/game_overlay.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  @override
  void initState() {
    super.initState();

    engine.registerSceneConstructor('game', ([dynamic data]) async {
      return GameScene(controller: engine, id: 'game', context: context);
    });
  }

  Future<bool> _prepareData() async {
    if (engine.isInitted) return true;
    await engine.init();

    // final localeStrings =
    //     await rootBundle.loadString('assets/locales/chs.json5');
    // final localeData = JSON5.parse(localeStrings);
    // engine.loadLocale(localeData);

    engine.hetu.evalFile('main.ht', globallyImport: true);

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _prepareData(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          throw (snapshot.error!);
        }

        if (!snapshot.hasData || snapshot.data == false) {
          return LoadingScreen(
              text: engine.isInitted ? engine.locale('loading') : 'Loading...');
        } else {
          return Scaffold(
            body: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
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
                            engine.locale('newGame'),
                            width: 100.0,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                        child: ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return Scaffold(
                                  appBar: AppBar(actions: const []),
                                  body: Center(
                                    child: Container(
                                      color: Colors.blueGrey,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5.0, horizontal: 10.0),
                                      child: EmbeddedText(
                                        'test <bold color="#ff0000">text</>',
                                        style: const TextStyle(
                                            color: Colors.white),
                                        onRoute: (route, arg) {
                                          if (kDebugMode) {
                                            print(route);
                                            print(arg);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: const Text('embeded text'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                        child: ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => MarkdownWiki(
                                resourceManager: AssetManager(),
                              ),
                            );
                          },
                          child: const Text('markdown_wiki'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                        child: ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return Scaffold(
                                  appBar: AppBar(),
                                  body: Column(
                                    children: <Widget>[
                                      Positioned(child: Container())
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          child: const Text('error test'),
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 20.0, bottom: 100.0),
                        child: ElevatedButton(
                          onPressed: () {
                            windowManager.close();
                          },
                          child: Label(
                            engine.locale('exit'),
                            width: 100.0,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
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
