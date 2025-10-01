import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/samsara.dart';

import 'scene/game.dart';
import 'global.dart';

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
  bool _isLoading = false, _isInitted = false;

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
    engine.bgm.initialize();

    engine.registerSceneConstructor('game', ([dynamic args]) async {
      return GameScene(id: 'game', context: context, bgm: engine.bgm);
    });
  }

  // FutureBuilder 根据返回值是否为null来判断是否成功，因此这里无论如何需要返回一个值
  Future<bool> _initEngine() async {
    if (_isLoading) return false;
    _isLoading = true;

    if (!_isInitted) {
      // 刚打开游戏，需要初始化引擎，载入数据，debug模式下还要初始化一个游戏存档用于测试
      await engine.init(context);
      _isInitted = true;

      engine.pushScene('game');
    } else {
      // 游戏已经初始化完毕，此时根据当前状态读取或切换场景
      assert(engine.isInitted);
    }

    _isLoading = false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initEngine(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          throw Exception('${snapshot.error}\n${snapshot.stackTrace}');
        } else if (!snapshot.hasData) {
          return const LoadingScreen();
        } else {
          final scene = context.watch<SamsaraEngine>().scene;
          return Scaffold(
            body: Stack(
              children: [
                scene?.build(
                      context,
                      loadingBuilder: (context) => LoadingScreen(),
                    ) ??
                    const SizedBox.shrink(),
              ],
            ),
          );
        }
      },
    );
  }
}
