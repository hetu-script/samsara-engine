import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:samsara/ui/loading_screen.dart';
import 'package:samsara/ui/label.dart';
// import 'package:json5/json5.dart';
import 'package:samsara/widgets/markdown_wiki.dart';
import 'package:samsara/richtext.dart';
// import 'package:flame/flame.dart';

import '../global.dart';
import '../scene/game.dart';
import '../scene/game_overlay.dart';

const richTextSource = 'rich text is <yellow italic>awesome</> !!!';

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

    // await Flame.images.load('text/sword.png');

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _prepareData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          if (snapshot.hasError) {
            throw Exception('${snapshot.error}\n${snapshot.stackTrace}');
          }
          return LoadingScreen(
            text: engine.isInitted ? engine.locale('loading') : 'Loading...',
            showClose: snapshot.hasError,
          );
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
                                      child: RichText(
                                        text: TextSpan(
                                          children: buildFlutterRichText(
                                            richTextSource,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                            ),
                                          ),
                                        ),
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
