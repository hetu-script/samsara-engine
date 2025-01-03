import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:samsara/error.dart';
// import 'package:flame_splash_screen/flame_splash_screen.dart';

import 'ui/main_menu.dart';
import 'global.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 对于Flutter没有捕捉到的错误，弹出系统原生对话框
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      alertNativeError(error, stackTrace);
      return false;
    };

    // 对于Flutter捕捉到的错误，弹出Flutter绘制的自定义对话框
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      alertFlutterError(details);
    };

    assert(Platform.isLinux || Platform.isWindows || Platform.isMacOS);
    await windowManager.ensureInitialized();
    // windowManager.addListener(CustomWindowListener());
    await windowManager.setMaximizable(false);
    await windowManager.setResizable(false);
    const windowSize = Size(1440.0, 900.0);
    await windowManager.waitUntilReadyToShow(
        const WindowOptions(
          title: 'Samsara Engine Tests',
          // fullScreen: true,
          size: windowSize,
          maximumSize: windowSize,
          minimumSize: windowSize,
        ), () async {
      await windowManager.show();
      await windowManager.focus();
      engine.info('系统版本：${Platform.operatingSystemVersion}');
    });

    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Heavenly Tribulation Tests',
        home: Scaffold(
          key: mainKey,
          body: const MainMenu(),
          // FlameSplashScreen(
          //   theme: FlameSplashTheme.dark,
          //   showAfter: (context) => const Image(
          //     image: AssetImage('assets/images/hetu_logo_small.png'),
          //   ),
          //   onFinish: (context) => Navigator.pushReplacement<void, void>(
          //     context,
          //     MaterialPageRoute(builder: (context) => const MainMenu()),
          //   ),
          // ),
        ),
        // 控件绘制时发生错误，用一个显示错误信息的控件替代
        builder: (context, widget) {
          ErrorWidget.builder = (FlutterErrorDetails details) {
            String stack = '';
            if (details.stack != null) {
              stack = trimStackTrace(details.stack!);
            }
            final Object exception = details.exception;
            Widget error = ErrorWidget.withDetails(
                message: '$exception\n$stack',
                error: exception is FlutterError ? exception : null);
            if (widget is Scaffold || widget is Navigator) {
              error = Scaffold(body: Center(child: error));
            }
            return error;
          };
          if (widget != null) return widget;
          throw ('error trying to create error widget!');
        },
      ),
    );
  }, alertNativeError);
}
