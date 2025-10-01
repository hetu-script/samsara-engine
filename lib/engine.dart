import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_flutter/hetu_script_flutter.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as path;
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_audio/bgm.dart';
import 'package:flutter_custom_cursor/cursor_manager.dart';
import 'package:image/image.dart' as img2;
import 'package:hetu_script/bytecode/bytecode_module.dart';

import 'binding/engine_binding.dart';
import '../event.dart';
import 'localization/localization.dart';
import 'extensions.dart' show HexColor;
import 'scene/scene_controller.dart';
import 'logger/printer.dart';
import 'logger/output.dart';
import 'tilemap/tilemap.dart';

class EngineConfig {
  final String name;
  final bool debugMode;
  final bool desktop;
  final double musicVolume;
  final double soundEffectVolume;
  final Map<String, String> cursors;
  final Map<String, dynamic> mods;
  final bool showFps;

  const EngineConfig({
    this.name = 'A Samsara Engine Game',
    this.desktop = false,
    this.debugMode = false,
    this.musicVolume = 0.5,
    this.soundEffectVolume = 0.5,
    this.mods = const {},
    this.cursors = const {},
    this.showFps = false,
  });
}

abstract class AudioPlayerInterface {
  Bgm get bgm;
  Future<AudioPlayer?> play(String fileName, {double? volume});
}

class SamsaraEngine extends SceneController
    with EventAggregator
    implements HTLogger, AudioPlayerInterface {
  static const modeFileExtension = '.mod';

  final EngineConfig config;

  String get name => config.name;

  Map<String, dynamic> get mods => config.mods;

  late BuildContext context;

  bool isLoading = false;

  bool setLoading(bool value) {
    if (isLoading != value) {
      isLoading = value;
      notifyListeners();
    }
    return isLoading;
  }

  SamsaraEngine({
    this.config = const EngineConfig(),
  }) {
    logger = Logger(
      filter: null,
      printer: _loggerPrinter,
      output: _loggerOutput,
    );
    _locale = GameLocalization();
  }

  final CustomLoggerPrinter _loggerPrinter = CustomLoggerPrinter();
  final CustomLoggerOutput _loggerOutput = CustomLoggerOutput();

  late final Logger logger;

  late final GameLocalization _locale;

  bool hasLocaleKey(String? key) => _locale.hasLocaleString(key);

  String locale(dynamic key, {dynamic interpolations}) {
    if (interpolations != null && interpolations is! List) {
      interpolations = [interpolations];
    }
    key ??= 'null';
    return _locale.getLocaleString(key, interpolations: interpolations);
  }

  late final String? _mainModName;

  String get languageId => _locale.languageId;

  void loadLocaleDataFromJSON(Map localeData) {
    _locale.loadData(localeData);
    if (_locale.errors.isNotEmpty) {
      for (final error in _locale.errors) {
        warn(error);
      }
    }
    debug('samsara: loaded ${localeData.length} locale strings...');
  }

  void setLanguage(String localeId) {
    assert(_locale.hasLanguage(localeId));
    info(
        'samsara: set current language to [${_locale.getLanguageName(localeId)}]');
    _locale.languageId = localeId;
  }

  void loadTileMapZoneColors(TileMap map, List colorsData) {
    final List<Map<int, Color>> convertedList = [];
    for (final colorData in colorsData) {
      final colorInfo = Map<int, Color>.from(colorData.map((key, value) {
        final color = HexColor.fromString(value);
        final paint = Paint()
          ..style = PaintingStyle.fill
          ..color = color;
        map.cachedPaints[color] = paint;
        return MapEntry(key as int, color);
      }));
      convertedList.add(colorInfo);
    }
    map.zoneColors.clear();
    map.zoneColors.addAll(convertedList);
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

  Future<HTBytecodeModule> loadModFromAssetsString(
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
      positionalArgs: positionalArgs,
      namedArgs: namedArgs,
    );
    if (!isMainMod && _mainModName != null) {
      switchMod(_mainModName!);
    }

    return hetu.interpreter.cachedModules[module]!;
  }

  Future<HTBytecodeModule> loadModFromBytes(
    Uint8List bytes, {
    required String module,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    bool isMainMod = false,
  }) async {
    if (isMainMod) _mainModName = module;
    hetu.loadBytecode(
      bytes: bytes,
      module: module,
      globallyImport: isMainMod,
      positionalArgs: positionalArgs,
      namedArgs: namedArgs,
    );
    if (!isMainMod && _mainModName != null) {
      switchMod(_mainModName!);
    }

    return hetu.interpreter.cachedModules[module]!;
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
  //     invokeFunc: 'main',
  //     positionalArgs: positionalArgs,
  //     namedArgs: namedArgs,
  //   );
  //   if (!isMainMod && _mainModName != null) switchMod(_mainModName!);
  // }

  void switchMod(String id) => hetu.interpreter.switchModule(id);

  /// Initialize the engine, must be called within
  /// the initState() of Flutter widget,
  /// for accessing the assets bundle resources.
  Future<void> init(
    BuildContext context, {
    Map<String, Function> externalFunctions = const {},
    Set<String> mods = const {},
  }) async {
    if (_isInitted) return;
    // isLoading = true;
    // notifyListeners();

    this.context = context;
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
          showDartStackTrace: false,
          // showDartStackTrace: config.debugMode,
          showHetuStackTrace: true,
          stackTraceDisplayCountLimit: 10,
          allowVariableShadowing: false,
          allowImplicitNullToZeroConversion: true,
          allowImplicitEmptyValueToFalseConversion: true,
          resolveExternalFunctionsDynamically: true,
        ),
        sourceContext: sourceContext,
        locale: HTLocaleSimplifiedChinese(),
        logger: this,
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
    hetu.eval(
      kHetuEngineBindingSource,
      // filename: 'engine.ht',
      globallyImport: true,
      type: HTResourceType.hetuModule,
    );

    hetu.assign('engine', this);

    await _locale.init();

    _isInitted = true;
    // isLoading = false;
    // notifyListeners();
  }

  Future<void> registerCursors() async {
    if (config.cursors.isNotEmpty) {
      for (final name in config.cursors.keys) {
        await registerCursor(
          name: name,
          assetPath: config.cursors[name]!,
        );
      }
    }
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

  List<OutputEvent> getLogEvents() => _loggerOutput.events;
  List<String> getLogs() => _loggerOutput.logs;

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

  Level _getLogLevel(MessageSeverity severity) {
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
        return Level.trace;
    }
  }

  @override
  void log(String message, {MessageSeverity severity = MessageSeverity.none}) {
    logger.log(_getLogLevel(severity), message);
  }

  @override
  void debug(String message) => log(message, severity: MessageSeverity.debug);

  @override
  void info(String message) => log(message, severity: MessageSeverity.info);

  @override
  void warn(String message) => log(message, severity: MessageSeverity.warn);

  @override
  void error(String message) => log(message, severity: MessageSeverity.error);

  @override
  Bgm get bgm => FlameAudio.bgm;

  @override
  Future<AudioPlayer?> play(String fileName, {double? volume}) async {
    return FlameAudio.play('sound/$fileName',
        volume: volume ?? config.musicVolume);
  }

  final _cursorManager = CursorManager.instance;

  Future<String> registerCursor({
    required String name,
    required String assetPath,
    int? width,
    int? height,
  }) async {
    final byte = await rootBundle.load(assetPath);
    final memoryCursorDataRawPNG = byte.buffer.asUint8List();
    final img = img2.decodePng(memoryCursorDataRawPNG)!;
    final memoryCursorDataRawBGRA =
        (img.getBytes(order: img2.ChannelOrder.bgra)).buffer.asUint8List();
    // register this cursor
    final cursorName = await CursorManager.instance.registerCursor(CursorData()
      ..name = name
      ..buffer =
          Platform.isWindows ? memoryCursorDataRawBGRA : memoryCursorDataRawPNG
      ..height = width ?? img.height
      ..width = height ?? img.width
      ..hotX = 0
      ..hotY = 0);

    return cursorName;
  }

  String? _cursor;
  String? get cursor => _cursor;

  Future<void> setCursor(String name) async {
    _cursor = name;
    await _cursorManager.setSystemCursor(name);
  }
}
