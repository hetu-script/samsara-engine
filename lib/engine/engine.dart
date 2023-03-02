import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_flutter/hetu_script_flutter.dart';

import '../binding/game_binding.dart';
import '../../event/event.dart';
import '../localization/localization.dart';
import '../utils/color.dart';
import '../scene/scene_controller.dart';
import '../logger/printer.dart';
import '../logger/output.dart';

class EngineConfig {
  final String name;
  final bool debugMode;
  final bool isOnDesktop;
  final bool showMissingLocaleStringPlaceHolder;

  const EngineConfig({
    this.name = 'A Samsara Engine Game',
    this.debugMode = false,
    this.isOnDesktop = false,
    this.showMissingLocaleStringPlaceHolder = true,
  });
}

class SamsaraEngine with SceneController, EventAggregator {
  final EngineConfig config;

  String get name => config.name;

  SamsaraEngine({
    this.config = const EngineConfig(),
  }) {
    logger = Logger(
      filter: null,
      printer: _loggerPrinter,
      output: _loggerOutput,
    );
    locale = GameLocalization(
      showMissingLocaleStringPlaceHolder:
          config.showMissingLocaleStringPlaceHolder,
    );
  }

  final CustomLoggerPrinter _loggerPrinter = CustomLoggerPrinter();
  final CustomLoggerOutput _loggerOutput = CustomLoggerOutput();

  late final Logger logger;

  late final GameLocalization locale;

  late final String? _mainModName;

  void loadLocale(dynamic localeData) {
    locale.loadData(localeData);
  }

  List<Map<int, Color>> colors = [];

  void loadColors(List colorsList) {
    for (final Map colorData in colorsList) {
      final data = colorData
          .map((key, value) => MapEntry(key as int, HexColor.fromHex(value)));
      colors.add(data);
    }
  }

  late Hetu hetu;
  bool isLoaded = false;

  // HTStruct createStruct([Map<String, dynamic> jsonData = const {}]) =>
  //     hetu.interpreter.createStructfromJson(jsonData);

  dynamic fetch(
    String varName, {
    String? moduleName,
  }) =>
      hetu.interpreter.fetch(
        varName,
        moduleName: moduleName,
      );

  dynamic assign(
    String varName,
    dynamic value, {
    String? moduleName,
  }) =>
      hetu.interpreter.assign(
        varName,
        value,
        moduleName: moduleName,
      );

  invoke(String funcName,
          {String? namespaceName,
          String? moduleName,
          List<dynamic> positionalArgs = const [],
          Map<String, dynamic> namedArgs = const {},
          List<HTType> typeArgs = const []}) =>
      hetu.interpreter.invoke(funcName,
          namespaceName: namespaceName,
          moduleName: moduleName,
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          typeArgs: typeArgs);

  Future<void> loadModFromAssets(
    String key, {
    required String moduleName,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    bool isMainMod = false,
  }) async {
    if (isMainMod) _mainModName = moduleName;
    hetu.evalFile(
      key,
      moduleName: moduleName,
      globallyImport: isMainMod,
      invokeFunc: 'init',
      positionalArgs: positionalArgs,
      namedArgs: namedArgs,
    );
    if (!isMainMod && _mainModName != null) switchMod(_mainModName!);
  }

  Future<void> loadModFromBytes(
    Uint8List bytes, {
    required String moduleName,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    bool isMainMod = false,
  }) async {
    if (isMainMod) _mainModName = moduleName;
    hetu.loadBytecode(
      bytes: bytes,
      moduleName: moduleName,
      globallyImport: isMainMod,
      invokeFunc: 'init',
      positionalArgs: positionalArgs,
      namedArgs: namedArgs,
    );
    if (!isMainMod && _mainModName != null) switchMod(_mainModName!);
  }

  void switchMod(String id) => hetu.interpreter.switchModule(id);

  /// Initialize the engine, must be called within
  /// the initState() of Flutter widget,
  /// for accessing the assets bundle resources.
  Future<void> init(
      {Map<String, Function> externalFunctions = const {}}) async {
    if (isLoaded) return;
    if (config.debugMode) {
      const root = 'scripts/';
      final filterConfig = HTFilterConfig(root);
      final sourceContext = HTAssetResourceContext(
        root: root,
        includedFilter: [filterConfig],
      );
      hetu = Hetu(
        config: HetuConfig(
          printPerformanceStatistics: config.debugMode,
          showDartStackTrace: config.debugMode,
          showHetuStackTrace: true,
          allowVariableShadowing: false,
          allowImplicitNullToZeroConversion: true,
          allowImplicitEmptyValueToFalseConversion: true,
          resolveExternalFunctionsDynamically: true,
        ),
        sourceContext: sourceContext,
      );
      await hetu.initFlutter(
        locale: HTLocaleSimplifiedChinese(),
        externalFunctions: externalFunctions,
        externalClasses: [
          SamsaraEngineClassBinding(),
        ],
      );
    } else {
      hetu = Hetu(
        config: HetuConfig(
          showHetuStackTrace: true,
          allowImplicitNullToZeroConversion: true,
          allowImplicitEmptyValueToFalseConversion: true,
        ),
      );
      hetu.init(
        locale: HTLocaleSimplifiedChinese(),
        externalFunctions: externalFunctions,
        externalClasses: [
          SamsaraEngineClassBinding(),
        ],
      );
    }

    // hetu.interpreter.bindExternalFunction('print', info, override: true);

    hetu.eval(kHetuEngineBindingSource, fileName: 'samsara_engine_binding.ht');

    isLoaded = true;
  }

  // @override
  // Future<Scene> createScene(String key, [Map<String, dynamic>? args]) async {
  //   final scene = await super.createScene(key, args);
  //   broadcast(SceneEvent.created(sceneKey: key));
  //   return scene;
  // }

  // @override
  // void leaveScene(String key) {
  //   super.leaveScene(key);
  //   broadcast(SceneEvent.ended(sceneKey: key));
  // }

  List<String> getLog() => _loggerOutput.log;

  String _stringify(dynamic args) {
    if (args is List) {
      if (isLoaded) {
        return args.map((e) => hetu.lexicon.stringify(e)).join(' ');
      } else {
        return args.map((e) => e.toString()).join(' ');
      }
    } else {
      if (isLoaded) {
        return hetu.lexicon.stringify(args);
      } else {
        return args.toString();
      }
    }
  }

  void log(dynamic content) {
    _loggerOutput.log.add(_stringify(content));
  }

  void debug(dynamic content) {
    logger.d(_stringify(content));
  }

  void info(dynamic content) {
    logger.i(_stringify(content));
  }

  void warn(dynamic content) {
    logger.w(_stringify(content));
  }

  void error(dynamic content) {
    logger.e(_stringify(content));
  }
}
