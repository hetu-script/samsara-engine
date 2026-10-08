[English](../en/core.md) | **中文**

# Samsara Engine —— 核心模块

本文档覆盖本库的核心：引擎单例、场景系统、`GameComponent` 组件家族、特效、光照、任务调度器与事件总线。文中所有内容都有 example 工程中的可运行场景作为演示，最重要的是 [`example/lib/scene/components_scene.dart`](../../example/lib/scene/components_scene.dart)（组件、手势、特效）和 [`example/lib/scene/lighting_scene.dart`](../../example/lib/scene/lighting_scene.dart)（光照）。

相关文档：[gestures.md](gestures.md)（输入处理）、[hover_info.md](hover_info.md)（悬浮提示）、[richtext.md](richtext.md)（富文本）、[cardgame.md](cardgame.md)（卡牌）、[game_dialog.md](game_dialog.md)（对话）、[misc.md](misc.md)（控制台 / 瓦片地图 / markdown wiki）。

## 1. 架构概览

### 1.1 类层次结构

```
PositionComponent (package:flame)
└── GameComponent (抽象基类)                      lib/components/game_component.dart
    ├── BorderComponent                          lib/components/border_component.dart
    │   ├── SpriteComponent2  (+ HandlesGesture) lib/components/sprite_component2.dart
    │   ├── SpriteButton<T>   (+ HandlesGesture) lib/components/ui/sprite_button.dart
    │   ├── DynamicColorProgressIndicator (+ HandlesGesture)
    │   ├── RichTextComponent (+ HandlesGesture) lib/components/ui/rich_text_component.dart
    │   └── Hovertip                             lib/components/ui/hovertip.dart
    ├── GestureComponent（抽象便捷基类，+ HandlesGesture）
    │                                              lib/components/gesture_component.dart
    ├── FadingText / InAndOutSprite / Arrow /
    │   ParticleComponent / Timer / ValueGenerator
    └── TileMap (+ HandlesGesture)               lib/tilemap/tilemap.dart

FlameGame (package:flame)
└── Scene (+ TaskController)                     lib/scene/scene.dart
    └── （你自己的场景）

ChangeNotifier (package:flutter)
└── SceneController（抽象类）                    lib/scene/scene_controller.dart
    └── SamsaraEngine (+ EventAggregator)        lib/engine.dart

CameraComponent (package:flame)
└── Camera2                                      lib/camera/camera2.dart
```

### 1.2 Widget 控件层 vs Flame 组件层

一个 Samsara 游戏本质上是一个 Flutter 应用。两个层之间由三座显式的"桥"连接：

1. **指针 → 场景**：`PointerDetector`（[`lib/widgets/pointer_detector.dart`](../../lib/widgets/pointer_detector.dart)）是一个 Flutter 控件，它捕获指针/鼠标/滚轮事件，并转发给当前 `Scene` 的 `onTapDown` / `onDragUpdate` / `onMouseHover` 等回调，再由场景以深度优先方式分发给 `HandlesGesture` 组件。Samsara 完全不使用 Flame 的手势 mixin。详见 [gestures.md](gestures.md)。
2. **游戏 → Flutter 事件**：`EventAggregator`（[`lib/event.dart`](../../lib/event.dart)），一个普通的发布/订阅 mixin。游戏代码调用 `engine.emit('eventId', args)`；Flutter 控件通过 `engine.addEventListener(...)` 注册监听。
3. **场景切换 → 控件重建**：`SceneController` 是 `ChangeNotifier`。每次导航调用（`pushScene`、`popScene`、`switchScene`）最后都会 `notifyListeners()`，因此控件树中 `context.watch<SamsaraEngine>()` 的位置会重建并替换当前显示的 `SceneWidget`。这就是为什么引擎必须通过 `ChangeNotifierProvider` 提供（见 §4）。

### 1.3 桶文件（barrel）

公开 API 通过根目录下的桶文件暴露：

- `package:samsara/samsara.dart` —— 主桶文件：引擎、场景、`GameComponent`、`BorderComponent`、全部特效（`AdvancedMoveEffect`、`FadeEffect`、`CameraShakeEffect`、`ZoomEffect`、`ConfettiEffect`）、`SpriteAnimationWithTicker`、`LightConfig`、控制台、绘制工具（`ScreenTextConfig`、`drawScreenText`、预设 Paint/Filter）、扩展和错误类型。它还**选择性重导出**了常用类型，通常只需这一个 import：
  - `package:flame/components.dart`：`Anchor`、`Vector2`、`CameraComponent`
  - `package:flame/text.dart`：`TextPaint`、`LineMetrics`
  - `dart:ui`：`Offset`、`Rect`、`RRect`、`Radius`、`Canvas`、`Color`、`Paint`、`PaintingStyle`、`Image`、`BlendMode`、`ImageFilter`、`MaskFilter`、`BlurStyle`
  - `package:flutter/material.dart`：`Colors`、`TextStyle`、`TextAlign`、`FontWeight`、`FilterQuality`、`EdgeInsets`、`Curve`、`Curves`
- `package:samsara/components.dart` —— 组件库的其余部分：`SpriteComponent2`、`GestureComponent`、`SpriteButton`、`FadingText`、`InAndOutSprite`、`Arrow`、`ParticleComponent`、`Timer`、`ValueGenerator`、`DynamicColorProgressIndicator`、`RichTextComponent`、`Hovertip`。
- `package:samsara/gestures.dart` —— `HandlesGesture` + `PointerDetector` + 鼠标按键常量。
- `package:samsara/effect.dart` —— 全部特效（也被主桶文件重导出）。
- `package:samsara/tilemap.dart`、`package:samsara/cardgame.dart`、`package:samsara/game_dialog.dart`、`package:samsara/hover_info.dart`、`package:samsara/richtext.dart`、`package:samsara/markdown_wiki.dart`。

没有被任何桶文件导出的内容：动画状态控制器（见 §10）——需要直接 import 对应文件。

## 2. SamsaraEngine

`SamsaraEngine`（[`lib/engine.dart`](../../lib/engine.dart)）是顶层对象。它继承 `SceneController`，混入 `EventAggregator`，并实现 `AudioPlayerInterface` 与 HetuScript 的 `HTLogger`。整个应用只创建一个实例（通常是全局单例，见 §4）。

### 2.1 EngineConfig

```dart
const EngineConfig({
  this.name = 'A Samsara Engine Game',
  this.developMode = false,      // 从 assets 的 scripts/ 加载河图源码
  this.musicVolume = 0.5,
  this.soundEffectVolume = 0.5,
  this.showFps = false,
  this.enableLlm = true,         // 警告：见下文
  this.llmModelId = 'gemma-4-E4B-it-Q5_K_M',
  this.mods = const {},
});
```

> **⚠ 注意 —— `enableLlm` 默认为 `true`。** 此时 `init()` 会尝试加载本地 GGUF 模型：它设置 `Llama.libraryPath = "llama.dll"`，并在可执行文件旁边寻找 `models/<llmModelId>.gguf`，在模型就绪之前阻塞启动（最长约 30 秒）。除非你确实要发布 LLM 并使用 llm_chat 功能，否则务必传 `enableLlm: false` —— example 工程在 [`example/lib/engine.dart`](../../example/lib/engine.dart) 中正是这么做的。

### 2.2 init()

```dart
Future<void> init(BuildContext context,
    {Map<String, Function> externalFunctions = const {}})
```

必须在控件的 `initState()` 中调用，且**要在推送任何场景之前**——源码注释说明这是为了访问 asset bundle。该方法是幂等的（第二次调用直接返回；可用 `engine.isInitted` 查询）。它会依次：

1. 清空当前工作目录下的日志文件 `samsara_engine.log`（`clearLogFile()`）；
2. 保存 `context` 供后续使用（`engine.context`）；
3. 初始化内嵌的 HetuScript 解释器——`developMode` 下会以 `scripts/` 为根目录构建 `HTAssetResourceContext`，从 assets 加载脚本文件；绑定引擎类（`SamsaraEngineClassBinding`）并求值引擎绑定模块，然后把引擎实例以全局变量 `engine` 暴露给脚本；
4. 初始化本地化（`GameLocalization.init()`——扫描 asset manifest 中 `assets/locale/<languageId>*.json` 并合并）；
5. 若 `enableLlm && llmModelId != null`，初始化本地 LLM（见上面的注意）。

LLM 相关补充（仅在 `enableLlm: true` 时有意义）：`prepareLlamaBaseState(systemPrompt)` 用系统提示词预热一个可复用的基础 state（启动时调用一次即可；example 工程在 [`example/lib/app.dart`](../../example/lib/app.dart) 中这么做）；聊天会话随后交替调用 `restoreBaseScope()` / `releaseBaseScope()`；`disposeBaseState()` 丢弃缓存的 state；`isLlamaReady` / `baseInitialized` 报告进度。

### 2.3 加载状态

```dart
bool isLoading;
String? loadingTip;
String? loadingMessage;
bool setLoading(bool loading, {String? tip, String? message});
```

`setLoading` 只在数值**实际变化时**翻转标志并调用 `notifyListeners()`，并返回新状态。example 工程中在 `engine.isLoading` 为 true 时显示 `LoadingScreen` 覆盖层（[`example/lib/app.dart`](../../example/lib/app.dart)）。注意引擎自身不会在 `init()` 期间切换这个标志——由应用来驱动。

### 2.4 本地化

- `String locale(dynamic key, {dynamic interpolations})` —— 按 key 查找本地化字符串。非 `List` 的 `interpolations` 会被包装成单元素列表。`{0}`、`{1}` …占位符会被替换（见 §10 的 `StringEx.interpolate`）。如果查到的值是 `List`，会随机选取一条；如果 `key` 是 `List`，则分别本地化后用 `', '` 拼接。
- `bool hasLocaleKey(String? key)`
- `String get languageId` —— 当前语言；默认 `'zh'`（`GameLocalization` 创建时带语言 `['en', 'zh']`）。
- `void setLanguage(String localeId)` —— 断言该语言存在。
- `void loadLocaleDataFromJSON(Map localeData)` —— 合并运行时提供的本地化数据；每个 value 必须是包含 `languageId` 条目的 Map；解析问题通过 `warning()` 日志报告。

### 2.5 日志

```dart
void log(String message, {MessageSeverity severity = MessageSeverity.none});
void debug(String message);
void info(String message);
void warning(String message);
void error(String message);
```

日志进入 `logger` 包的 `Logger`（自定义 filter/printer/output），并且每次 `log()` 调用还会通过引擎自己的 `taskController` 调度一行带时间戳的内容追加到 `Directory.current` 下的 `samsara_engine.log`。相关 API：

- `List<(Level, String)> getLogsRaw()` —— 原始的 `(level, text)` 对；
- `List<String> getLogs({Level? level, bool richText = false})` —— 字符串列表，可按不高于给定 level 过滤（`Level` 由 `lib/engine.dart` 从 logger 包重导出）；
- `clearLogs()`、`Future<void> clearLogFile()`、`Future<void> writeLogFile(String content)`；
- `String stringify(dynamic args)` —— 河语感知的值格式化。

### 2.6 音频

`SamsaraEngine` 实现 `AudioPlayerInterface`：

```dart
Bgm get bgm => FlameAudio.bgm;                    // 背景音乐
Future<AudioPlayer?> play(String fileName, {double? volume});
```

`play()` 通过 `FlameAudio.play` 播放 assets 中的 `sound/<fileName>`；`volume` 省略时回退到 `config.soundEffectVolume`。场景 BGM 由 `Scene.onStart`/`onEnd` 通过传给场景构造函数的 `bgm` 对象处理（§3.4）。

### 2.7 事件（EventAggregator）

```dart
typedef EventCallback = void Function(dynamic args);

void addEventListener(String listenerId, String eventId, EventCallback callback);
void removeEventListeners(String listenerId);  // 从所有事件中移除该 id
void emit(String eventId, [dynamic args]);
```

- 处理器按键 `(eventId → listenerId → callback)` 存储；同一 `listenerId` 对同一 `eventId` 重复注册会覆盖旧回调。
- `removeEventListeners` 只接受 listener id，会把该 id 从**每一个**事件中注销——没有按单个事件移除的 API。
- `emit` 同步调用该事件的所有回调（debug 模式下还会打印事件与参数）。

### 2.8 Mod 与脚本

HetuScript 模块（"mod"）可以从 asset 字符串或字节加载：

```dart
Future<HTBytecodeModule> loadModFromAssetsString(
  String key, {
  required String module,
  List<dynamic> positionalArgs = const [],
  Map<String, dynamic> namedArgs = const {},
  bool isMainMod = false,
});
Future<HTBytecodeModule> loadModFromBytes(Uint8List bytes, {...同上...});
void switchMod(String id);   // hetu.interpreter.switchModule(id)
```

游戏主模块传 `isMainMod: true`（会被全局导入并记住）；之后加载非主 mod 会自动切回主模块。打包 mod 的约定扩展名是 `.mod`（`SamsaraEngine.modFileExtension`）。`developMode` 下通常直接迭代 `assets/scripts/` 下的 `.ht` 源文件。

## 3. 场景系统

### 3.1 SceneController

`SceneController`（[`lib/scene/scene_controller.dart`](../../lib/scene/scene_controller.dart)）是抽象的 `ChangeNotifier`，它持有：

- `Scene? scene` —— 当前激活的场景；
- `final _cached = <String, Scene>{}` —— 已构造场景的**惰性缓存**；
- `final _sceneStack = <String>[]` —— 导航栈（以 `List<String> get sceneStack` 暴露）；
- 已注册的场景构造器，以及按场景记忆的构造器 id 与参数。

场景构造器需要提前注册：

```dart
void registerSceneConstructor(
    String constructorId, Future<Scene> Function(dynamic arguments) constructor);
```

一个构造器可以注册多个 id；一个场景 id 也可以通过 `constructorId` 关联到某个构造器。

导航 API：

| 方法 | 行为 |
| --- | --- |
| `Future<Scene> pushScene(String sceneId, {String? constructorId, dynamic arguments, bool triggerOnStart = true, void Function()? onAfterLoaded})` | 创建（或从缓存恢复）场景，把 `sceneId` 压栈，对原场景调用 `onEnd()`（不 await），设置 `scene.onAfterLoaded`，通知监听者，然后 await `onStart(arguments)`。如果 `sceneId` 就是当前场景，除了可选地再次触发 `onStart` 外什么都不做——适合"刷新"用途。 |
| `Future<Scene?> popScene({bool clearCache = false})` | 弹出栈顶，调用 `onEnd()`，可选地把场景从缓存中丢弃（**这是唯一会释放资源的导航操作**），然后 `switchScene` 回新的栈顶。只剩一个场景时拒绝操作（debug 下记录错误并返回 `null`）。 |
| `Future<Scene?> popSceneTill(String sceneId, {bool clearCache = false})` | 持续弹出直到 `sceneId` 位于栈顶。 |
| `Future<Scene> switchScene(String sceneId, {dynamic arguments, bool triggerOnStart = true})` | 把 `scene` 切换到一个**已缓存**的场景（断言 `_cached.containsKey(sceneId)`），**不触碰导航栈**。 |
| `void clearCachedScene(String sceneId)` | 从缓存中移除一个场景；若它在栈中，同时从栈和缓存参数中移除。 |
| `Future<void> clearAllCachedScene({String? except, dynamic arguments, bool triggerOnStart = false})` | 丢弃除 `except` 之外的所有缓存场景（如有则切换到它）。绝不调用 `onEnd()`。 |
| `bool hasScene(String id)` / `bool hasSceneInSequence(String id)` | 缓存成员 vs. 栈成员。 |

必须理解的几个语义：

- **惰性缓存 + 恢复。** 一个场景只构造一次；不带 `clearCache` 的 pop 会保持它存活。之后再次进入会恢复**同一个实例**，其组件与状态原样保留。
- **`switchScene` 不动栈。** 它用于临时绕行：因为栈没变，之后调用 `popScene` 时无论中途切换到了什么，都会正确回到栈中的前一个场景。它断言目标已缓存（例如之前 push 过，或就是当前场景）。`popScene` 断言当前场景*就是*栈顶，因此在 `switchScene` 切到非栈顶场景之后立刻 `popScene` 会触发 debug 断言。
- **构造器 id 和参数会被记住。** 如果 `pushScene` 调用时未提供 `constructorId`/`arguments`，则复用该场景 id 上次 push 时缓存的值；`popScene` 会丢弃被弹出场景的缓存参数。`cachedConstructorIds` / `cachedArguments` 也可以通过 `loadSceneConstructorIds` / `loadSceneArguments` 批量写入，通过 `setSceneArguments` 按场景写入。
- `lastScene` 返回栈顶对应的场景实例（栈空时为 `null`）。

### 3.2 Scene

`Scene`（[`lib/scene/scene.dart`](../../lib/scene/scene.dart)）即 `abstract class Scene extends FlameGame with TaskController` —— 每个场景都是一个完整的 Flame 游戏实例，拥有自己的相机（`Camera2`）、world 与组件树。构造函数：

```dart
Scene({
  required this.id,
  Bgm? bgm,                 // 传 engine.bgm
  String? bgmFile,          // music/ 下的资源，由 onStart 播放
  double bgmVolume = 0.5,
  bool enableLighting = false,
  Color? backgroundLightingColor,
});
```

相机始终是按光照参数配置过的 `Camera2`（§8）。

### 3.3 场景生命周期

| 钩子 | 触发时机 |
| --- | --- |
| `onLoad()`（`@mustCallSuper`） | Flame 的挂载钩子，场景控件首次构建时调用。基类实现会根据画布尺寸设置 `bounds` 并调用 `fitScreen()`。 |
| `onStart([dynamic arguments = const {}])`（`@mustCallSuper`，`FutureOr<void>`） | **每次进入**时调用——包括恢复缓存场景——在控制器将其设为当前场景之后，并由 `pushScene`/`switchScene` await。**首次**进入时它在 `onLoad` *之前*执行，因此**不要在这里做组件操作**；它适合用来解冻/恢复之前冻结的状态与数据。基类实现会通过场景的 `bgm` 对象播放 `bgmFile`。 |
| `onEnd()`（`@mustCallSuper`） | 场景失去焦点时调用（由 `pushScene`/`switchScene`/`popScene` 触发，**不 await**）。资源**不会**释放——除非带 `clearCache: true` pop，否则场景留在缓存中。基类实现会停止 BGM。 |
| `onMount()`（`@mustCallSuper`） | 在首次挂载时触发一次 `onAfterLoaded`（由 `_isFirstLoad` 保护）。 |

注意：

- 因为场景会持续存在于缓存中，`onStart` 会被反复触发；在其中启动的任何内容（计时器、流）都必须可重入。
- `onAfterLoaded` 由控制器在每次 push 时接线、被 `popScene`/`switchScene` 清除；由于一次性挂载保护，重新 push 一个已缓存场景**不会**再次触发它。

### 3.4 固定时间步长

`Scene.updateTree` 对更新做了量化：

```dart
static double fixedRate = 1 / 60;
// _dtSum += dt;
// if (_dtSum > fixedRate) { super.updateTree(fixedRate); _dtSum -= fixedRate; }
```

每个 tick 让游戏逻辑恰好推进 `1/60` 秒，且每渲染帧最多运行**一个** tick。60 fps 下完全透明；低于 60 fps 时游戏时间会比墙上时钟慢（没有追帧循环）。

### 3.5 场景辅助成员

- `Rect bounds` —— 画布边界，在 `onLoad` 和 `onGameResize` 中更新。
- 基于 `bounds` 的九个锚点 getter：`topLeft`、`topCenter`、`topRight`、`centerLeft`、`center`、`centerRight`、`bottomLeft`、`bottomCenter`、`bottomRight`。
- 坐标换算（考虑相机位置与缩放）：`worldPosition2Screen(Vector2)` / `screenPosition2World(Vector2)`。
- `void fitScreen([Vector2? fitSize])` —— 把相机对准 `fitSize ?? size` 的中心，并设置 `viewfinder.zoom`，使整个区域可见（按视口宽高比留黑边）。
- `void addHintText(String text, {Vector2? position, GameComponent? target, Color? color, TextStyle? textStyle, double duration = 2, double offsetY = 100.0, double horizontalVariation = 30.0, double verticalVariation = 30.0, bool onViewport = true, Anchor anchor = Anchor.center})` —— 生成一个上浮 `offsetY` 像素后淡出的漂浮 `FadingText` 文本（优先级 `kHintTextPriority`）。请求经由内部 `TaskController` 排队，弹出间隔至少 `kMinHintInterval`（250 ms），并按 variation 参数随机抖动。`onViewport: true`（默认）时文本加到相机 viewport（屏幕坐标系）；否则加到 world。
- `Iterable<HandlesGesture> get gestureComponents` —— 以逆序返回所有子孙手势组件（事件分发时子组件优先于父组件）。见 [gestures.md](gestures.md)。
- `hoveringComponent` / `draggingComponent` —— 由场景的手势分发跟踪；`resetStaleGestures()` 用于清理残留的按下/拖动状态（当某次按下没有任何组件响应时会作为自愈兜底自动调用）。

### 3.6 把场景嵌入控件树

```dart
Widget build(
  BuildContext context, {
  Widget Function(BuildContext)? loadingBuilder,
  Map<String, Widget Function(BuildContext, Scene)>? overlayBuilderMap,
  List<String>? initialActiveOverlays,
}) => SceneWidget(...);
```

`SceneWidget`（[`lib/scene/scene_widget.dart`](../../lib/scene/scene_widget.dart)）把 Flame 的 `GameWidget` 包在 `PointerDetector` 里，转发每一个场景手势回调（并带 `endDragAtWindowEdge: true` 与 `autofocus: false`）。标准做法是在监听引擎的根控件里调用 `scene.build(context, ...)`（§4）。场景也可以重写 `build()`，在游戏画布周围组合 Flutter 控件——example 中 `MainMenuScene.build` 就把 `SceneWidget`、菜单按钮和 `GameDialogController` 叠在了一起（[`example/lib/scene/mainmenu.dart`](../../example/lib/scene/mainmenu.dart)）。`Scene.overlayUIBuilderMapKey`（`'overlayUI'`）是 overlay 映射的约定键。

## 4. 快速开始——项目骨架

以下是 example 工程（[`example/lib`](../../example/lib)）用于引导游戏的最小框架。照着搭出骨架，然后逐步加上自己的场景。

**1. 引擎单例** —— [`example/lib/engine.dart`](../../example/lib/engine.dart)：

```dart
import 'package:samsara/samsara.dart';

final SamsaraEngine engine = SamsaraEngine(
  config: const EngineConfig(
    name: 'Samsara Engine Test',
    developMode: true,
    showFps: true,
    enableLlm: false,   // 除非要发布 LLM 模型，否则永远不要忘了这项
  ),
);

const windowSize = Size(1440.0, 810.0);
```

**2. `main()`** —— 窗口/光标/错误处理，然后用 `ChangeNotifierProvider` 提供引擎并 `runApp`（节选改编自 [`example/lib/main.dart`](../../example/lib/main.dart)）：

```dart
void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 把未捕获的错误导入引擎日志 + 系统原生对话框，
    // 把 Flutter 框架错误导入自定义对话框。
    PlatformDispatcher.instance.onError = (error, stackTrace) { ... };
    FlutterError.onError = (details) { ... };

    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
        const WindowOptions(title: 'Samsara Demo', size: windowSize),
        () async {
      await windowManager.show();
      await windowManager.focus();
    });

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => engine),
          // ...按需添加 dialog / hover 等 provider
        ],
        child: MaterialApp(
          home: MouseRegion(
            cursor: GameCursor(name: 'default'),
            child: GameApp(),
          ),
        ),
      ),
    );
  }, alertNativeError);
}
```

**3. 应用控件** —— 注册构造器、初始化引擎、推送首个场景（来自 [`example/lib/app.dart`](../../example/lib/app.dart)）：

```dart
class _GameAppState extends State<GameApp> {
  @override
  void initState() {
    super.initState();
    engine.setLoading(true);
    _initEngine();
  }

  Future<void> _initEngine() async {
    engine.bgm.initialize();

    engine.registerSceneConstructor('main', ([dynamic args]) async {
      return MainMenuScene(id: 'main', bgm: engine.bgm);
    });
    engine.registerSceneConstructor('components', ([dynamic args]) async {
      return ComponentsScene(id: 'components');
    });
    // ...更多场景

    await engine.init(context);   // 必须在 pushScene 之前运行
    engine.pushScene('main', onAfterLoaded: () {
      engine.setLoading(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scene = context.watch<SamsaraEngine>().scene;      // 桥 #3
    final isLoading = context.watch<SamsaraEngine>().isLoading;
    return Scaffold(
      body: Stack(
        children: [
          scene?.build(context,
                loadingBuilder: (context) => const LoadingScreen()) ??
              const LoadingScreen(),
          if (isLoading) const LoadingScreen(),
        ],
      ),
    );
  }
}
```

**4. 一个场景** —— [`example/lib/scene/mainmenu.dart`](../../example/lib/scene/mainmenu.dart)（节选）：

```dart
class MainMenuScene extends Scene {
  MainMenuScene({required super.id, super.bgm, super.bgmFile});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final background = SpriteComponent(
      sprite: Sprite(await Flame.images.load('main2-small.png')),
      size: size,
    );
    world.add(background);

    final button = SpriteButton(
      anchor: Anchor.center,
      text: 'Components',
      spriteId: 'button.png',
      useSpriteSrcSize: true,
      position: Vector2(center.x, center.y),
    );
    button.onTap = (button, position) => engine.pushScene('components');
    world.add(button);
  }
}
```

整个闭环就是如此：注册构造器 → `init` → `pushScene` → 被监听的引擎触发控件树重建并显示 `scene.build(...)` → 开始游戏。接下来请阅读 [gestures.md](gestures.md) 了解输入，然后继续看下面的组件、特效与光照章节。

## 5. GameComponent

`GameComponent`（[`lib/components/game_component.dart`](../../lib/components/game_component.dart)）是所有游戏对象的抽象基类：

```dart
abstract class GameComponent extends PositionComponent
    with HasGameReference<Scene>, HasPaint
    implements SizeProvider, OpacityProvider
```

它在 `PositionComponent` 之上新增的能力：

- **具名 Paint** —— Flame 的 `HasPaint` mixin：构造函数把默认 paint 注册为 `'default'`（`getPaint()` / `setPaint(name, paint)` / `paint` 读写）。子类注册自己的，例如 `BorderComponent` 增加 `'borderPaint'`，`SpriteButton` 增加 `'hoverTintPaint'` 和 `'invalidPaint'`。
- **不透明度** —— 通过 `HasPaint` 在默认 paint 上的 `opacity` 读写实现；实现了 Flame 的 `OpacityProvider`，因此可与 Flame 的不透明度特效及 samsara 的 `FadeEffect` 配合。
- **可见性** —— `bool isVisible`（构造参数，默认 `true`）。getter 会把字段与非 HUD 组件的 `scene.camera.canSee(this)` 做与运算；`renderTree` 在不可见时提前返回。注意相机检查要求组件已挂载到场景中。
- **HUD 检测** —— `bool get isHud`。在每次 `onMount()` 时通过沿父链查找 Flame 的 `Viewport`/`Viewfinder` 计算；HUD 组件跳过相机可见性检查，并以屏幕坐标接收指针位置。
- **光照** —— `LightConfig? lightConfig` 字段（§8）。
- **加载回调** —— `FutureOr<void> Function()? onAfterLoaded`；仅在首次挂载时调用一次。
- **手势配套** —— `Iterable<HandlesGesture> get gestureComponents`：可处理手势的直接子组件（逆序）。真正的输入处理来自 `HandlesGesture` mixin——见 [gestures.md](gestures.md)。

### 5.1 moveTo

```dart
Future<void> moveTo({
  Vector2? toPosition,
  Vector2? toSize,
  double? toAngle,          // 弧度
  bool clockwise = true,
  required double duration, // 秒
  double delay = 0.0,       // 秒
  Curve curve = Curves.linear,
  void Function()? onChange,
  void Function()? onComplete,
})
```

用 `AdvancedMoveEffect`（§7）动画化位置、尺寸和/或角度。语义：

- 三个目标全为 `null` 时立即返回；如果组件已处于目标状态，则调用 `onComplete` 并返回。
- **先取消组件上正在运行的 `AdvancedMoveEffect`**（从其 children 中移除）——新的 `moveTo` 总是胜出，避免并发移动冲突。以与运行中移动*相同*的目标调用 `moveTo` 则是空操作。
- `delay` 会先被 await（单位为秒）；设置 `toAngle` 时 `clockwise` 决定旋转方向。
- 动画运行期间 `isMoving` 为 `true`；动画结束时返回的 future 完成。

### 5.2 snapTo

```dart
void snapTo({Vector2? toPosition, Vector2? toSize, double? toDegree})
```

瞬时的、无动画的传送/变形/旋转。`toDegree` 接收**角度制**（注意与 `moveTo` 的 `toAngle` 弧度制不同），内部会做转换。没有变化时为空操作。

### 5.3 fadeIn / fadeOut

```dart
Future<void> fadeIn({required double duration, void Function()? onComplete})
Future<void> fadeOut({required double duration, void Function()? onComplete})
```

两者都附加一个 samsara 的 `FadeEffect`（§7），并随其完成而完成。

> **⚠ 注意——淡出会移除组件。** samsara 的 `FadeEffect` 在**淡出**结束时会调用 `target.removeFromParent()`。要让组件重新淡入，必须先把它加回父级。见 [`example/lib/scene/components_scene.dart`](../../example/lib/scene/components_scene.dart) 中的 `fader` 演示：
>
> ```dart
> fader.fadeOut(duration: 0.8);
> // 之后：
> world.add(fader);
> fader.fadeIn(duration: 0.8);
> ```

## 6. 其他组件

全部位于 [`lib/components/`](../../lib/components/)，由 `package:samsara/components.dart` 导出（部分也进了主桶文件）。

- **`BorderComponent`**（`border_component.dart`，也在主桶文件中）—— 一个会根据自身尺寸预先计算 `border`（`Rect`）、`roundBorder`（`RRect`）和 `clipRRect` 的 `GameComponent`。构造参数 `borderWidth`（默认 1.0）与 `borderRadius`（默认 0.0）；边框 paint 默认是细白色描边，注册为 `'borderPaint'`。`generateBorder()` 会在 `size` 变化时自动重算（作为尺寸监听器挂接）。暴露 `bounds`（绝对位置矩形）。绝大多数 UI 组件继承它。
- **`GestureComponent`**（`gesture_component.dart`）—— 抽象便捷基类：`GameComponent with HandlesGesture`，手势默认启用。适合不需要 `BorderComponent` 的可交互对象。
- **`SpriteComponent2`**（`sprite_component2.dart`）—— 带可见性、着色、适配、裁剪与缩放的精灵组件。提供 `spriteId`（在 `onLoad` 中通过 `game.loadSprite` 从 assets 惰性加载）或 `Sprite` 之一，也可以之后用 `sprite=` / `tryLoadSprite()` 设置。值得注意的行为：
  - `Color? color` 给整个画布着色（`BlendMode.srcATop`）；
  - `BoxFit boxFit`（默认 `BoxFit.fill`）在 `autoResize` 关闭时控制适配；外部设置 `size` 会自动关闭 `autoResize`；
  - `clipMode` 把渲染裁剪到组件矩形，并启用 `zoom`（被限制在 **1.0–2.0**）和 `clipOffset`，其实现是 `ClipAndZoomDecorator`——example 中用它做滚轮缩放的地图块；
  - **手势是可选的**：`enableGesture` 默认为 **`false`**。
- **`SpriteButton<T>`**（`ui/sprite_button.dart`）—— `BorderComponent with HandlesGesture` 的按钮。精灵集合：`sprite`/`borderSprite`/`hoverSprite`/`pressSprite`/`selectedSprite`（每种都可以传对象或 `*Id` 从 assets 加载），可选 `text` 配 `ScreenTextConfig`（自动跟随 `size`），`Color? color` 着色，`isEnabled`（禁用时以灰度 invalid paint 渲染），`isSelectable`/`isSelected`（选中精灵态），泛型 `T? value`，以及 `onTap`。`useSpriteSrcSize` 让按钮尺寸取自精灵。`useSimpleStyle` 用预设圆角矩形填充代替精灵绘制。手势默认启用（mixin 默认值）。
- **`FadingText`**（`fading_text.dart`）—— 可选地上浮（`movingUpOffset`、`moveUpCurve`）并在 `fadeOutAfterDuration`（默认为 `duration` 的一半）之后通过 `FadeEffect` 淡出的文字。被 `Scene.addHintText` 使用。
- **`InAndOutSprite`**（`in_and_out_sprite.dart`）—— 让精灵从右缘飞入到中心，停留 `stayDuration`，再向左飞出并移除自身。必须添加到 `World` 或另一个 `PositionComponent`（否则抛错）。注意：飞出阶段复用的是 `flyInDuration`。
- **`Arrow`**（`arrow.dart`）—— 红线（`linePaint`）加精灵箭头：`setPath(from, to)` 让箭头指向 `to`，并把线画到箭头底部。
- **`Timer`**（`timer.dart`）—— **samsara 自己的计时器组件，不是 Flame 的**（`Component` 子类）。`Timer(duration, {loop, autoStart = true, autoDispose = true, onStart, onChange, onComplete})`；`onChange` 每 tick 收到累计（未封顶）时间；完成时 `end()` 把计时器钳制到 `duration`，并在 `autoDispose` 时移除自身。
- **`ValueGenerator`**（`value_generator.dart`）—— 用 `curve`（默认 `Curves.decelerate`）在 `duration` 内从 `begin` 过渡到 `end`（默认 0 → 1），通过 `onChange` 上报。`autoStart` 默认为 **false** —— 需要调用 `start()`；`pause()`/`reset()`/`finish()`；完成时移除自身。
- **`ParticleComponent`**（`particle_component.dart`）—— 包装 Flame `Particle` 的 `GameComponent`：转发 `update`/`render`，在 `particle.shouldRemove` 时移除自身；如果存在 `lightConfig`，还会在 `lightUpDuration` 内把 `lightConfig.radius` 从 0 增长到原值（§8）。
- **`DynamicColorProgressIndicator`**（`ui/progress_indicator.dart`）—— 用 `lerpGradient` 在 `colors`（可选 `stops`）上取色的进度条。`value`/`max`，可选动画过渡（`animated` 默认 true，`animationDuration` 默认 4 秒），`setValue(n, {animated})`，可选居中描边 `label`，`showNumber`/`showNumberAsPercentage` 开关。
- **`RichTextComponent`**（`ui/rich_text_component.dart`）—— 在游戏画布内渲染 HTML 风格的富文本标记（`<bold>`、`<red>`、`<icon=...>` …），支持可选描边（`config.outlined`）、`backgroundColor`、`fontScale`，以及通过 `layout({text, width, height, fontScale})` 重新排版。手势是可选的（`enableGesture = false`）。见 [richtext.md](richtext.md)。
- **`Hovertip`**（`ui/hovertip.dart`）—— 纯静态 API（`show`、`hide`、`hideAll`、`toggle`、`hasTip`）的 Flame 层悬浮提示：实例按内容字符串缓存，可相对于目标组件或屏幕边距定位，提供 13 个 `HovertipDirection`，位置会被钳制在视口内，并添加到 `scene.camera.viewport`。不要与 Flutter 控件层的 `hover_info` 系统混淆——这是两套独立子系统；区分说明见 [hover_info.md](hover_info.md)。

## 7. 特效

文件位于 [`lib/effect/`](../../lib/effect/)：

| 类 | 继承 | 文件 |
| --- | --- | --- |
| `AdvancedMoveEffect` | `Effect` | `advanced_move.dart` |
| `FadeEffect` | `Effect` | `fade.dart` |
| `CameraShakeEffect` | `Effect` | `camera_shake.dart` |
| `ZoomEffect` | `Effect` | `zoom.dart` |
| `ConfettiEffect` | `PositionComponent` | `confetti.dart` |

> 全部特效均由 `package:samsara/effect.dart` 导出，主桶文件 `package:samsara/samsara.dart` 也重导出了它——一个 import 即可覆盖。（与 Flame 没有命名冲突：Flame 1.38 没有 `FadeEffect`，其等价物是 `OpacityEffect`。）

- **`AdvancedMoveEffect({Vector2? endPosition, Vector2? endSize, double? endAngle, bool clockwise = true, GameComponent? target, required EffectController controller, void Function()? onChange, super.onComplete})`** —— `GameComponent.moveTo` 背后的主力。要求至少一个目标（否则断言失败）；对 `endAngle` 做归一化；每帧增量插值位置/尺寸/角度，并在结束时精确吸附到目标值。`onChange` 在每次应用后触发。`moveTo` 被新调用取代时取消的就是它。
- **`FadeEffect({GameComponent? target, required EffectController controller, bool fadeIn = false, super.onComplete})`** —— 驱动 `target.opacity` 0→1（淡入）或 1→0；**淡出结束时会把 target 从父级移除**（§5.3）。
- **`CameraShakeEffect({int intensity = 100, int shift = 10, int frequency = 1, required EffectController controller, super.onComplete})`** —— 把它加到**场景**上（`game.add(...)`）；`onStart` 中解析游戏相机，然后在控制器时长内做有偏随机触发：`frequency` 是最大震动次数，`shift` 是每个方向的像素偏移，`intensity` 是回移速度（它先挪动相机，再调用 `camera.moveTo2(initialPosition, speed: 100)` 移回）。
- **`ZoomEffect(FlameGame game, EffectController controller, {required double zoom, super.onComplete})`** —— 把 `game.camera.viewfinder.zoom` 从当前值补间到 `zoom`；**断言目标缩放与当前值不同**。
- **`ConfettiEffect({super.position, required super.size, super.priority})`** —— **不是 `Effect`**，而是 `PositionComponent`；添加到 `world`（size 必填）。挂载时喷射 150 个彩带粒子（矩形/圆形/三角形/飘带四种形状，预设调色板，带重力，约 3.5 秒后淡出），并在粒子全部消失后移除自身。

来自 [`lib/extensions.dart`](../../lib/extensions.dart) 的相机辅助：

```dart
extension CameraEx on CameraComponent {
  void moveTo2(Vector2 point, {double speed = double.infinity, double? zoom, void Function()? onComplete});
  void snapTo(Vector2 position);
  void snapBy(Vector2 offset);
}
```

`moveTo2` 先停止当前相机移动，再以给定 `speed` 用 `MoveToEffect` 补间 viewfinder 位置；提供 `zoom` 时再向游戏添加一个 `ZoomEffect`（注意 `onComplete` 只接在位置特效上）。注意与 `GameComponent.moveTo` 区分——后者动画的是组件。

## 8. 光照

光照是**相机级的渲染 pass**，而不是按组件生效的特效。当以 `enableLighting: true` 创建场景时，`Camera2.renderTree`（[`lib/camera/camera2.dart`](../../lib/camera/camera2.dart)）会绘制整个 world，然后：

1. 打开一个 layer，用 `BlendMode.dstATop` 把 `backgroundLightingColor`（默认 `Colors.black.withAlpha(200)`）涂在上面——即"黑暗"；
2. 为每个符合条件的组件，用 `BlendMode.clear` + 模糊 `MaskFilter` 在黑暗上打出洞——即"光"；
3. 关闭 layer。

组件通过携带 `LightConfig`（[`lib/lighting/light_config.dart`](../../lib/lighting/light_config.dart)）参与光照：

```dart
LightConfig({
  Color color = Colors.transparent, // 透明 = 纯打洞，无色调
  bool isLighted = true,
  required double radius,           // 必须 > 0（断言）
  double blurBorder = 10.0,
  double lightUpDuration = 0.0,     // >0 时半径从 0 增长（见 ParticleComponent）
  LightShape shape = LightShape.circle,   // 或 LightShape.rect
  Vector2? lightCenter,             // 绝对坐标；优先于下面两项
  Vector2? lightCenterOffset,       // 相对组件中心的偏移
  int flickerRate = 0,              // 已接受但目前未使用
})
```

- `color`/`hasHue`：色调着色 paint 在计划中但**尚未实现**——无论 `color` 是什么，当前的光只会穿透黑暗。
- 设置 `blurBorder` 会重建 `lightPaint`（fill + `BlendMode.clear` + `MaskFilter.blur`，border 会转换为 sigma）。
- 光心解析顺序：`lightCenter` → `component.center + lightCenterOffset` → `component.center`。
- 矩形光会绘制绕组件外扩 `radius` 的圆角矩形。

> **⚠ 注意——仅直接子组件生效。** `Camera2` 只对 `world.children.whereType<GameComponent>()` 打光洞——即 **world 的直接子组件**中可见、且 `lightConfig.isLighted == true` 的 `GameComponent`。嵌套在分组/组件内部的光源不会发光。`Scene.enableLighting` 是相机上的实时 getter/setter，场景构造函数会把这些参数接进去。

可运行演示：[`example/lib/scene/lighting_scene.dart`](../../example/lib/scene/lighting_scene.dart)——静态圆形光、一个矩形光，以及一个用 `moveTo` 绕圈移动的光（移动光洞可以工作，因为 `moveTo` 每帧更新组件变换）。

## 9. TaskController

[`lib/task.dart`](../../lib/task.dart) —— `mixin class TaskController`，一个**顺序执行异步任务**的队列（按插入顺序存放 completer）：

```dart
Future<T>? schedule<T>(FutureOr<T> Function() task, {bool isAuto = true, String? id});
void completeTask(String taskId, [dynamic result]);  // 用于 isAuto: false 的任务
bool hasTask(String id);
void clearAllTasks();
```

- 任务严格一个接一个运行：新任务要等之前所有已排任务完成后才开始。
- `isAuto: true`（默认）时，回调返回后自动完成该槽位，future 得到结果。
- `isAuto: false` 时槽位保持挂起，直到有人调用 `completeTask(taskId, [result])`（断言 id 存在）；返回的 future 以传入的结果完成。
- 传入仍在队列中的 `id` 会返回 **`null`** 并在 debug 下打印警告，而不会重复入队——可用 id 来去重。
- `clearAllTasks()` 丢弃所有待处理槽位且不完成它们。

`TaskController` 混入在 `Scene` 中（`with TaskController`），`SamsaraEngine` 则拥有一个独立的 `taskController` 字段。**约定：** 用 `schedule()` 链接动画/过渡，而不是直接 `await` 裸 future——这可以避免多个并发流程（UI、AI、过场动画）在动画中途交错，也与 Flame 的特效模型一致。`GameComponent.moveTo` 和 `fadeIn`/`fadeOut` 返回 future 正是为了这种链接。

## 10. 扩展速查

[`lib/extensions.dart`](../../lib/extensions.dart) 还重导出了 `package:flame/extensions.dart`（隐藏 `ListExtension`），因此 `toVector2()`、`toOffset()`、`toRect()` 等也可经由 samsara 桶文件使用。

| 扩展 | 成员 |
| --- | --- |
| `IterableEx<T>` | `reversed`、`random`、`randomOrNull` |
| `StringEx` | `replaceAllEscapedLineBreaks()`（字面 `\n` → 换行）、`isBlank` / `isNotBlank`、`nonEmptyValue`（空白时为 null）、`interpolate(List?)`（`{0}` `{1}` …） |
| `PercentageString`（num） | `toPercentageString([fractionDigits = 0])` |
| `DoubleFixed` | `toDoubleAsFixed([n = 2])` |
| `HexColor`（Color） | `fromString`（6/8 位十六进制，可选 `#` 前缀；非法时抛 `ArgumentError`）、`toHex({leadingHashSign = true})` |
| `Vector2Ex` | `contains(position)`、`operator *`（缩放）、`moveAlongAngle(angle, distance)` |
| `CornerPosition`（PositionComponent） | `topLeft` … `bottomRight`（8 个锚点），另有 8 个 `absolute*` 变体 |
| `CameraEx`（CameraComponent） | `moveTo2`、`snapTo`、`snapBy`、`position`、`zoom` |
| `RectEx` | `stretchTo(point)`、`operator +`（Vector2/Offset/Size）、`operator *`（缩放）、`copyWith` |
| `RRectClone` | `copyWith` |
| `FormatHHMMSS` / `MeaningfulEx`（DateTime） | `toYMDHHMMSS()`、`toYMDHHMMSS2()`、`toMeaningful()` |

### 动画模块

[`lib/animation/`](../../lib/animation/)（未被桶文件导出——直接 import）：

- `SpriteAnimationWithTicker`（`sprite_animation.dart`）—— 打包 Flame `SpriteAnimation` + `SpriteAnimationTicker`。可用 `animationId`（从图片缓存加载 `animation/<id>`；必须提供 `srcSize`）、`SpriteSheet`（`from`/`to`/`row` 帧范围，`stepTime` 默认 0.5 秒，`loop` 默认 true）或现成的 `animation` 构造。`load()` 幂等；`clone()` 复制；`update(dt)` 与 `render(canvas, {position})` 驱动播放（支持 `renderRect`）。
- `AnimationStateController`（`animation_state_controller.dart`）—— 声明在 `GameComponent` 上的 mixin，实现动画状态机：`addState(state, anim, {isOverlay})`（重复则抛错）、`loadStates()`、`containsState()`、`setState(state, {isOverlay, jumpToEnd})`（未知状态会被忽略；仅对非循环动画返回 ticker 完成的 future）、`setCompositeState({startup, recovery, actions, overlays, complete, sound, onComplete})`——按 startup → actions → recovery 的顺序链式切换状态，并可通过 `audioPlayer` 字段播放音效。该 mixin 本身不挂钩 `update`/`render`——宿主组件必须每帧自行调用 `currentAnimation?.update(dt)` / `.render(canvas)`（overlay 同理）。

## 另见

- [gestures.md](gestures.md) —— `HandlesGesture` + `PointerDetector` 深入解析。
- [hover_info.md](hover_info.md) —— Flutter 层悬浮提示与 `Hovertip` 的区分。
- [richtext.md](richtext.md) —— 富文本标记、`RichTextIcons`、`Label`。
- [cardgame.md](cardgame.md) —— 卡牌、区域、翻转/旋转动画。
- [game_dialog.md](game_dialog.md) —— 带头像与选项的游戏对话框。
- [misc.md](misc.md) —— 控制台、瓦片地图、markdown wiki。
