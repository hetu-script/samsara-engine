import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_flutter/hetu_script_flutter.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as path;
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_audio/bgm.dart';

import 'binding/engine_binding.dart';
import '../event/event.dart';
import 'localization/localization.dart';
import 'utils/color.dart';
import 'scene/scene_controller.dart';
import 'logger/printer.dart';
import 'logger/output.dart';

class EngineConfig {
  final String name;
  final bool debugMode;
  final bool isOnDesktop;

  const EngineConfig({
    this.name = 'A Samsara Engine Game',
    this.debugMode = false,
    this.isOnDesktop = false,
  });
}

class SamsaraEngine with SceneController, EventAggregator implements HTLogger {
  static const modeFileExtension = '.mod';

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
    locale = GameLocalization();
  }

  final CustomLoggerPrinter _loggerPrinter = CustomLoggerPrinter();
  final CustomLoggerOutput _loggerOutput = CustomLoggerOutput();

  late final Logger logger;

  late final GameLocalization locale;

  late final String? _mainModName;

  void loadLocale(Map localeData) {
    info('载入本地化字符串……');
    locale.loadData(localeData);
  }

  void setLocale(String localeId) {
    assert(locale.hasLanguage(localeId));
    info('设置当前语言为 [${locale.getLanguageName(localeId)}]');
    locale.languageId = localeId;
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
  bool _isInitted = false;
  bool get isInitted => _isInitted;

  // HTStruct createStruct([Map<String, dynamic> jsonData = const {}]) =>
  //     hetu.interpreter.createStructfromJson(jsonData);

  // dynamic fetch(String id, {String? moduleName}) =>
  //     hetu.interpreter.fetch(id, module: moduleName);

  // dynamic assign(String id, dynamic value, {String? module}) =>
  //     hetu.interpreter.assign(id, value, module: module);

  Future<void> loadModFromAssetsString(
    String key, {
    required String module,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    bool isMainMod = false,
  }) async {
    if (isMainMod) _mainModName = module;
    hetu.evalFile(
      key,
      module: module,
      globallyImport: isMainMod,
      invoke: 'init',
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
      module: moduleName,
      globallyImport: isMainMod,
      invoke: 'init',
      positionalArgs: positionalArgs,
      namedArgs: namedArgs,
    );
    if (!isMainMod && _mainModName != null) switchMod(_mainModName!);
  }

  // Future<void> loadModFromApplicationDirectory(
  //   String key, {
  //   required String moduleName,
  //   List<dynamic> positionalArgs = const [],
  //   Map<String, dynamic> namedArgs = const {},
  //   bool isMainMod = false,
  // }) async {
  //   if (isMainMod) _mainModName = moduleName;

  //   final appDirectory = await getApplicationDocumentsDirectory();
  //   String modsFolder;

  //   if (key.endsWith(''))
  //     path.join(appDirectory.path, 'Heavenly Tribulation', 'mods', key);

  //   hetu.loadBytecode(
  //     bytes: bytes,
  //     moduleName: moduleName,
  //     globallyImport: isMainMod,
  //     invokeFunc: 'init',
  //     positionalArgs: positionalArgs,
  //     namedArgs: namedArgs,
  //   );
  //   if (!isMainMod && _mainModName != null) switchMod(_mainModName!);
  // }

  void switchMod(String id) => hetu.interpreter.switchModule(id);

  /// Initialize the engine, must be called within
  /// the initState() of Flutter widget,
  /// for accessing the assets bundle resources.
  Future<void> init({
    Map<String, Function> externalFunctions = const {},
    Set<String> modules = const {'cardGame'},
  }) async {
    if (_isInitted) return;
    if (config.debugMode) {
      const root = 'scripts/';
      final filterConfig = HTFilterConfig(root);
      final sourceContext = HTAssetResourceContext(
        root: root,
        includedFilter: [filterConfig],
      );
      hetu = Hetu(
        config: HetuConfig(
          // printPerformanceStatistics: config.debugMode,
          showDartStackTrace: config.debugMode,
          showHetuStackTrace: true,
          stackTraceDisplayCountLimit: 10,
          allowVariableShadowing: false,
          allowImplicitNullToZeroConversion: true,
          allowImplicitEmptyValueToFalseConversion: true,
          resolveExternalFunctionsDynamically: true,
        ),
        sourceContext: sourceContext,
        locale: HTLocaleSimplifiedChinese(),
      );
      await hetu.initFlutter(
        externalFunctions: externalFunctions,
      );
    } else {
      hetu = Hetu(
        config: HetuConfig(
          showHetuStackTrace: true,
          allowImplicitNullToZeroConversion: true,
          allowImplicitEmptyValueToFalseConversion: true,
        ),
        locale: HTLocaleSimplifiedChinese(),
        logger: this,
      );
      hetu.init(
        externalFunctions: externalFunctions,
      );
    }

    /// add engine class binding into script.
    hetu.interpreter.bindExternalClass(SamsaraEngineClassBinding());
    try {
      hetu.eval(
        kHetuEngineBindingSource,
        // filename: 'engine.ht',
        globallyImport: true,
        type: HTResourceType.hetuModule,
      );
    } catch (e) {
      if (kDebugMode) print(e);
    }

    // if (modules.contains('cardGame')) {
    //   /// add playing card class binding into script.
    //   hetu.interpreter.bindExternalClass(PlayingCardClassBinding());
    //   hetu.sourceContext.addResource(
    //     'playing_card.ht',
    //     HTSource(
    //       kHetuPlayingCardBindingSource,
    //       filename: 'playing_card_binding.ht',
    //       type: HTResourceType.hetuModule,
    //     ),
    //   );
    // }

    // hetu.interpreter.bindExternalFunction('print', info, override: true);

    hetu.assign('engine', this);

    await locale.init();

    _isInitted = true;
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

  String stringify(dynamic args) {
    if (args is List) {
      if (isInitted) {
        return args.map((e) => hetu.lexicon.stringify(e)).join(' ');
      } else {
        return args.map((e) => e.toString()).join(' ');
      }
    } else {
      if (isInitted) {
        return hetu.lexicon.stringify(args);
      } else {
        return args.toString();
      }
    }
  }

  Level getLogLevel(MessageSeverity severity) {
    switch (severity.weight) {
      case 1:
        return Level.debug;
      case 2:
        return Level.info;
      case 3:
        return Level.warning;
      case 4:
        return Level.error;
      default:
        return Level.all;
    }
  }

  @override
  void log(String message, {MessageSeverity severity = MessageSeverity.none}) {
    logger.log(getLogLevel(severity), message);
  }

  @override
  void debug(String message) => log(message, severity: MessageSeverity.debug);

  @override
  void info(String message) => log(message, severity: MessageSeverity.info);

  @override
  void warn(String message) => log(message, severity: MessageSeverity.warn);

  @override
  void error(String message) => log(message, severity: MessageSeverity.error);

  Future<AudioPlayer?> playSound(String fileName, {double volume = 1}) async {
    try {
      return FlameAudio.play(fileName, volume: volume);
    } catch (e) {
      if (kDebugMode) {
        error(e.toString());
        return null;
      } else {
        rethrow;
      }
    }
  }

  void playBGM(String fileName, {double volume = 1}) async {
    try {
      await FlameAudio.bgm.play(fileName, volume: volume);
    } catch (e) {
      if (kDebugMode) {
        error(e.toString());
      } else {
        rethrow;
      }
    }
  }

  Bgm get bgm => FlameAudio.bgm;
}
