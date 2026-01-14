import 'dart:io';
import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_flutter/hetu_script_flutter.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_audio/bgm.dart';
import 'package:flutter_custom_cursor/cursor_manager.dart';
import 'package:image/image.dart' as img2;
import 'package:hetu_script/bytecode/bytecode_module.dart';
import 'package:path/path.dart' as path;
import 'package:llama_cpp_dart/llama_cpp_dart.dart';

import 'binding/engine_binding.dart';
import '../event.dart';
import 'localization/localization.dart';
import 'extensions.dart' show HexColor, StringEx;
import 'scene/scene_controller.dart';
import 'logger/printer.dart';
import 'logger/output.dart';
import 'logger/filter.dart';
import 'tilemap/tilemap.dart';
import 'task.dart';

export 'package:logger/src/log_level.dart';

const logFilename = 'samsara_engine.log';

class EngineConfig {
  final String name;
  final bool debugMode;
  final bool desktop;
  final double musicVolume;
  final double soundEffectVolume;
  final Map<String, dynamic> mods;
  final bool showFps;

  const EngineConfig({
    this.name = 'A Samsara Engine Game',
    this.desktop = false,
    this.debugMode = false,
    this.musicVolume = 0.5,
    this.soundEffectVolume = 0.5,
    this.mods = const {},
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

  final TaskController taskController = TaskController();

  EngineConfig config;

  math.Random random = math.Random(DateTime.now().millisecondsSinceEpoch);

  String get name => config.name;

  Map<String, dynamic> get mods => config.mods;

  late BuildContext context;

  bool isLoading = false;

  String? loadingTip;
  String? loadingMessage;

  bool setLoading(bool loading, {String? tip, String? message}) {
    if (isLoading != loading) {
      isLoading = loading;
      loadingTip = tip;
      loadingMessage = message;
      notifyListeners();
    }
    return isLoading;
  }

  SamsaraEngine({
    this.config = const EngineConfig(),
  }) {
    logger = Logger(
      filter: CustomLoggerFilter(), // 使用自定义过滤器，在所有模式下都允许日志记录
      printer: CustomLoggerPrinter(),
      output: _loggerOutput,
    );
    _locale = GameLocalization();
  }

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
        warning(error);
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
          ..color = color.withAlpha(120);
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

  // LLM 相关
  late final LlamaParent llamaParent;
  bool _isLlamaReady = false;
  bool get isLlamaReady => _isLlamaReady;

  // 预热 state
  LlamaScope? _baseScope;
  LlamaScope? get baseScope => _baseScope;

  Uint8List? _baseState;
  bool _baseInitialized = false;
  bool get baseInitialized => _baseInitialized;

  Future<void> _initLlama() async {
    // 1. 配置模型参数 (请根据你的实际路径修改)
    Llama.libraryPath = "llama.dll";

    String exePath = Platform.resolvedExecutable;
    String exeDir = path.dirname(exePath);

    String modelPath = path.join(exeDir, "models/gemma-3n-E2B-it-Q8_0.gguf");

    // 目前采用CPU 模式
    final modelParams = ModelParams()..mainGpu = -1;

    // Gemma 3 理论支持 128k，但实际使用建议：
    // - 16384 (16k): 适合内存有限的系统，响应快
    // - 32768 (32k): 平衡性能和容量，推荐用于聊天应用
    // - 65536 (64k): 需要 16GB+ 内存，适合长对话
    // - 131072 (128k): 需要 32GB+ 内存，CPU 模式下会很慢
    final contextParams = ContextParams()
      ..nCtx = 32768 // 上下文窗口大小
      ..nBatch = 2048; // 批处理大小：每次处理的最大 token 数
    // 必须 <= nCtx，建议设置为 512/1024/2048
    // 更大的值允许更长的 prompt，但消耗更多内存

    // 调整采样参数以提高响应质量
    final samplerParams = SamplerParams()
      ..temp = 0.7
      ..topK = 64
      ..topP = 0.95
      ..penaltyRepeat = 1.1;

    final loadCommand = LlamaLoad(
      path: modelPath,
      modelParams: modelParams,
      contextParams: contextParams,
      samplingParams: samplerParams,
      // verbose: kDebugMode,
    );

    llamaParent = LlamaParent(loadCommand);

    await llamaParent.init();

    // 等待模型就绪，最多30秒
    int attempts = 0;
    while (llamaParent.status != LlamaStatus.ready && attempts < 60) {
      await Future.delayed(const Duration(milliseconds: 500));
      attempts++;
    }

    _isLlamaReady = true;
  }

  /// 预热 systemprompt 并保存 state 到内存
  /// 这个方法应该在游戏启动时，或基础设定发生较大变化时调用
  /// 预热完成后，每个对话都可以快速从这个 state 开始
  Future<void> prepareLlamaBaseState(String systemPrompt) async {
    if (!_isLlamaReady) {
      throw ("Llama not ready, cannot prepare base state");
    }
    final prompt = systemPrompt.trim();
    assert(prompt.isNotBlank);

    if (_baseInitialized || _baseState != null) {
      info("llm base state already initialized, disposing previous state...");
      disposeBaseState();
    }

    info("preparing llm base state (this will take 10-30 seconds)...");

    _baseScope = LlamaScope(llamaParent);

    // 创建 Completer 用于等待处理完成
    final completer = Completer<void>();
    StreamSubscription? completionSubscription;

    try {
      final history = ChatHistory();
      history.addMessage(
        role: Role.system,
        content: prompt,
      );

      final formattedPrompt = history.exportFormat(
        ChatFormat.gemma,
        leaveLastAssistantOpen: false,
      );

      // 监听完成事件
      completionSubscription = llamaParent.completions.listen((event) {
        if (event.success && !completer.isCompleted) {
          info("llm base state processing completed");
          completer.complete();
        }
      });

      // 发送 prompt 让模型处理
      await llamaParent.sendPrompt(formattedPrompt, scope: _baseScope);

      bool timeout = false;
      // 等待处理完成（通过监听 completions 事件）
      await completer.future.timeout(
        const Duration(minutes: 3), // 最多等待3分钟
        onTimeout: () {
          warning("base state preparation timed out after 3 minutes");
          timeout = true;
        },
      );

      // 处理完成后，立即停止
      await llamaParent.stop();

      if (!timeout) {
        // 保存 state 到内存
        _baseState = await _baseScope!.saveState();
        _baseInitialized = true;

        final stateSize = _baseState!.length / 1024 / 1024;
        info(
          "llm base state prepared successfully! "
          "state size: ${stateSize.toStringAsFixed(2)} MB",
        );
      }
    } catch (e) {
      error("failed to prepare base state: $e");
      rethrow;
    } finally {
      // 取消监听
      await completionSubscription?.cancel();
    }
  }

  /// 从预热的 state 恢复
  void restoreBaseScope() async {
    if (!isLlamaReady ||
        !baseInitialized ||
        _baseScope == null ||
        _baseState == null) {
      throw 'llama model is not ready or base state not initialized!';
    }

    await _baseScope!.loadState(_baseState!);
  }

  /// 清理基础 state（例如在需要重新加载世界信息时）
  void disposeBaseState() {
    _baseState = null;
    _baseInitialized = false;
    info("base state cleared");
  }

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

    await clearLogFile();

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

    await _initLlama();

    _isInitted = true;
    // isLoading = false;
    // notifyListeners();
  }

  Future<void> registerCursors(Map<String, String> cursors) async {
    if (cursors.isNotEmpty) {
      for (final name in cursors.keys) {
        await registerCursor(
          name: name,
          assetPath: cursors[name]!,
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

  List<(Level, String)> getLogsRaw() => _loggerOutput.logs;

  List<String> getLogs({
    Level? level,
    bool richText = false,
  }) {
    if (level != null) {
      return _loggerOutput.logs
          .where((element) => element.$1 <= level)
          .map((e) => e.$2)
          .toList();
    } else {
      return _loggerOutput.logs.map((e) => e.$2).toList();
    }
  }

  void clearLogs() {
    _loggerOutput.logs.clear();
  }

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

  /// clear log file
  Future<void> clearLogFile() async {
    final directory = Directory.current;
    final logPath = path.join(directory.path, logFilename);
    final logSaveFile = File(logPath);
    if (logSaveFile.existsSync()) {
      // 使用 FileMode.write 打开文件，这将立即清空文件内容
      final sink = logSaveFile.openWrite(mode: FileMode.write);
      // 不写入任何内容，直接关闭 sink
      await sink.close();
    }
  }

  Future<void> writeLogFile(String content) async {
    final directory = Directory.current;
    final logPath = path.join(directory.path, logFilename);
    final logSaveFile = File(logPath);
    if (!logSaveFile.existsSync()) {
      logSaveFile.createSync(recursive: true);
    }
    final sink = logSaveFile.openWrite(mode: FileMode.append);
    sink.writeln(content);
    await sink.flush();
    await sink.close();
  }

  @override
  void log(String message, {MessageSeverity severity = MessageSeverity.none}) {
    logger.log(_getLogLevel(severity), message);
    taskController.schedule(() async {
      await writeLogFile(
          '[${DateTime.now().toIso8601String()}] [${severity.name.toUpperCase()}]: $message');
    });
  }

  @override
  void debug(String message) => log(message, severity: MessageSeverity.debug);

  @override
  void info(String message) => log(message, severity: MessageSeverity.info);

  @override
  void warning(String message) =>
      log(message, severity: MessageSeverity.warning);

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
