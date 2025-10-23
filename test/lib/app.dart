import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/samsara.dart';

import 'scene/mainmenu.dart';
import 'engine.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.canvas,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.center,
            child: Text(
              engine.isInitted ? engine.locale('loading') : 'Loading...',
              style: const TextStyle(
                fontSize: 18.0,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GameApp extends StatefulWidget {
  const GameApp({super.key});

  @override
  State<GameApp> createState() => _GameAppState();
}

class _GameAppState extends State<GameApp> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    super.dispose();
    _focusNode.dispose();
    // engine.removeEventListener(id);
    engine.bgm.dispose();
  }

  @override
  void initState() {
    super.initState();

    engine.setLoading(true);

    _initEngine();
  }

  // FutureBuilder 根据返回值是否为null来判断是否成功，因此这里无论如何需要返回一个值
  Future<void> _initEngine() async {
    engine.bgm.initialize();

    engine.registerSceneConstructor('main', ([dynamic args]) async {
      return MainMenuScene(id: 'main', context: context, bgm: engine.bgm);
    });

    // 刚打开游戏，需要初始化引擎，载入数据，debug模式下还要初始化一个游戏存档用于测试
    await engine.init(context);

    engine.pushScene('main', onAfterLoaded: () {
      engine.setLoading(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scene = context.watch<SamsaraEngine>().scene;
    final isLoading = context.watch<SamsaraEngine>().isLoading;
    return Scaffold(
      body: Stack(
        children: [
          scene?.build(
                context,
                loadingBuilder: (context) => const LoadingScreen(),
              ) ??
              const LoadingScreen(),
          if (isLoading) const LoadingScreen(),
        ],
      ),
    );
  }
}
