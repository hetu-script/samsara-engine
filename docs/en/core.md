**English** | [中文](../zh/core.md)

# Samsara Engine — Core

This document covers the heart of the library: the engine singleton, the scene system, the `GameComponent` family, effects, lighting, the task scheduler and the event bus. Everything here is demonstrated by runnable scenes in the example app — most importantly [`example/lib/scene/components_scene.dart`](../../example/lib/scene/components_scene.dart) (components, gestures, effects) and [`example/lib/scene/lighting_scene.dart`](../../example/lib/scene/lighting_scene.dart) (lighting).

Related docs: [gestures.md](gestures.md) (input handling), [hover_info.md](hover_info.md) (tooltips), [richtext.md](richtext.md), [cardgame.md](cardgame.md), [game_dialog.md](game_dialog.md), [misc.md](misc.md) (console / tilemap / markdown wiki).

## 1. Architecture overview

### 1.1 Class hierarchy

```
PositionComponent (package:flame)
└── GameComponent (abstract)                     lib/components/game_component.dart
    ├── BorderComponent                          lib/components/border_component.dart
    │   ├── SpriteComponent2  (+ HandlesGesture) lib/components/sprite_component2.dart
    │   ├── SpriteButton<T>   (+ HandlesGesture) lib/components/ui/sprite_button.dart
    │   ├── DynamicColorProgressIndicator (+ HandlesGesture)
    │   ├── RichTextComponent (+ HandlesGesture) lib/components/ui/rich_text_component.dart
    │   └── Hovertip                             lib/components/ui/hovertip.dart
    ├── GestureComponent (abstract, + HandlesGesture)
    │                                              lib/components/gesture_component.dart
    ├── FadingText / InAndOutSprite / Arrow /
    │   ParticleComponent / Timer / ValueGenerator
    └── TileMap (+ HandlesGesture)               lib/tilemap/tilemap.dart

FlameGame (package:flame)
└── Scene (+ TaskController)                     lib/scene/scene.dart
    └── (your game scenes)

ChangeNotifier (package:flutter)
└── SceneController (abstract)                   lib/scene/scene_controller.dart
    └── SamsaraEngine (+ EventAggregator)        lib/engine.dart

CameraComponent (package:flame)
└── Camera2                                      lib/camera/camera2.dart
```

### 1.2 The widget layer vs. the component layer

A Samsara game is a Flutter app. The two layers are connected by three explicit bridges:

1. **Pointer → scene**: `PointerDetector` ([`lib/widgets/pointer_detector.dart`](../../lib/widgets/pointer_detector.dart)), a Flutter widget, captures pointer/mouse/scroll events and forwards them to the current `Scene`'s `onTapDown` / `onDragUpdate` / `onMouseHover` / etc., which dispatch them depth-first to `HandlesGesture` components. Samsara does not use Flame's gesture mixins at all. See [gestures.md](gestures.md).
2. **Game → Flutter events**: `EventAggregator` ([`lib/event.dart`](../../lib/event.dart)), a plain pub/sub mixin. Game code calls `engine.emit('eventId', args)`; Flutter widgets register with `engine.addEventListener(...)`.
3. **Scene switching → widget rebuilds**: `SceneController` is a `ChangeNotifier`. Every navigation call (`pushScene`, `popScene`, `switchScene`) ends with `notifyListeners()`, so a `context .watch<SamsaraEngine>()` in the widget tree rebuilds and swaps the active `SceneWidget`. This is why the engine must be provided through a `ChangeNotifierProvider` (see §4).

### 1.3 Barrel files

Public API is exposed through root-level barrels:

- `package:samsara/samsara.dart` — the main barrel: engine, scenes, `GameComponent`, `BorderComponent`, all effects (`AdvancedMoveEffect`, `FadeEffect`, `CameraShakeEffect`, `ZoomEffect`, `ConfettiEffect`), `SpriteAnimationWithTicker`, `LightConfig`, console, paint utilities (`ScreenTextConfig`, `drawScreenText`, preset paints/filters), extensions and error types. It also **selectively re-exports** commonly used types so one import is usually enough:
  - `package:flame/components.dart`: `Anchor`, `Vector2`, `CameraComponent`
  - `package:flame/text.dart`: `TextPaint`, `LineMetrics`
  - `dart:ui`: `Offset`, `Rect`, `RRect`, `Radius`, `Canvas`, `Color`, `Paint`, `PaintingStyle`, `Image`, `BlendMode`, `ImageFilter`, `MaskFilter`, `BlurStyle`
  - `package:flutter/material.dart`: `Colors`, `TextStyle`, `TextAlign`, `FontWeight`, `FilterQuality`, `EdgeInsets`, `Curve`, `Curves`
- `package:samsara/components.dart` — the rest of the component library: `SpriteComponent2`, `GestureComponent`, `SpriteButton`, `FadingText`, `InAndOutSprite`, `Arrow`, `ParticleComponent`, `Timer`, `ValueGenerator`, `DynamicColorProgressIndicator`, `RichTextComponent`, `Hovertip`.
- `package:samsara/gestures.dart` — `HandlesGesture` + `PointerDetector` + button constants.
- `package:samsara/effect.dart` — all effects (also re-exported by the main barrel).
- `package:samsara/tilemap.dart`, `package:samsara/cardgame.dart`, `package:samsara/game_dialog.dart`, `package:samsara/hover_info.dart`, `package:samsara/richtext.dart`, `package:samsara/markdown_wiki.dart`.

Not exported by any barrel: the animation state controller (see §10) — import its file directly.

## 2. SamsaraEngine

`SamsaraEngine` ([`lib/engine.dart`](../../lib/engine.dart)) is the top-level object. It extends `SceneController`, mixes in `EventAggregator`, and implements `AudioPlayerInterface` and HetuScript's `HTLogger`. Create one instance for the whole app (normally a global singleton, see §4).

### 2.1 EngineConfig

```dart
const EngineConfig({
  this.name = 'A Samsara Engine Game',
  this.developMode = false,      // load HetuScript sources from assets scripts/
  this.musicVolume = 0.5,
  this.soundEffectVolume = 0.5,
  this.showFps = false,
  this.enableLlm = true,         // WARNING: see below
  this.llmModelId = 'gemma-4-E4B-it-Q5_K_M',
  this.mods = const {},
});
```

> **⚠ GOTCHA — `enableLlm` defaults to `true`.** `init()` will then try to
> load a local GGUF model: it sets `Llama.libraryPath = "llama.dll"` and looks
> for `models/<llmModelId>.gguf` next to the executable, blocking startup until
> the model reports ready (up to ~30 s). Unless you actually ship an LLM and
> use the llm_chat feature, always pass `enableLlm: false` — the example app
> does exactly that in [`example/lib/engine.dart`](../../example/lib/engine.dart).

### 2.2 init()

```dart
Future<void> init(BuildContext context,
    {Map<String, Function> externalFunctions = const {}})
```

Must be called from a widget `initState()` **before any scene is pushed** — the doc comment states this is required for accessing the asset bundle. It is idempotent (a second call returns immediately; check `engine.isInitted`). It:

1. truncates the log file `samsara_engine.log` in the current working directory (`clearLogFile()`);
2. stores `context` for later use (`engine.context`);
3. initializes the embedded HetuScript interpreter — in `developMode` it builds an `HTAssetResourceContext` rooted at `scripts/` so script files are loaded from assets; binds the engine class (`SamsaraEngineClassBinding`) and evaluates the engine binding module, then exposes the engine instance to scripts as the global `engine`;
4. initializes localization (`GameLocalization.init()` — scans the asset manifest for `assets/locale/<languageId>*.json` and merges them);
5. if `enableLlm && llmModelId != null`, initializes the local LLM (see the gotcha above).

LLM extras (only relevant with `enableLlm: true`): `prepareLlamaBaseState(systemPrompt)` warms a reusable base state from a system prompt (call once at startup; the example app does this in [`example/lib/app.dart`](../../example/lib/app.dart)); a chat session then alternates `restoreBaseScope()` / `releaseBaseScope()`; `disposeBaseState()` drops the cached state; `isLlamaReady` / `baseInitialized` report progress.

### 2.3 Loading state

```dart
bool isLoading;
String? loadingTip;
String? loadingMessage;
bool setLoading(bool loading, {String? tip, String? message});
```

`setLoading` flips the flag and calls `notifyListeners()` **only when the value actually changes**, and returns the new state. In the example app a `LoadingScreen` overlay is shown while `engine.isLoading` is true ([`example/lib/app.dart`](../../example/lib/app.dart)). Note the engine does not toggle this itself during `init()` — the app drives it.

### 2.4 Localization

- `String locale(dynamic key, {dynamic interpolations})` — look up a localized string. A non-`List` `interpolations` value is wrapped into a one-element list. `{0}`, `{1}`, … placeholders are replaced (see `StringEx.interpolate` in §10). If the looked-up value is a `List`, one entry is chosen at random; if `key` is a `List`, the entries are localized and joined with `', '`.
- `bool hasLocaleKey(String? key)`
- `String get languageId` — current language; defaults to `'zh'` (`GameLocalization` is created with languages `['en', 'zh']`).
- `void setLanguage(String localeId)` — asserts the language exists.
- `void loadLocaleDataFromJSON(Map localeData)` — merge runtime-provided locale data; each value must be a map containing a `languageId` entry; parsing problems are reported through `warning()` logs.

### 2.5 Logging

```dart
void log(String message, {MessageSeverity severity = MessageSeverity.none});
void debug(String message);
void info(String message);
void warning(String message);
void error(String message);
```

Logs go to the `logger` package `Logger` (custom filter/printer/output) and each `log()` call also schedules an append of a timestamped line to `samsara_engine.log` in `Directory.current` through the engine's own `taskController`. Related API:

- `List<(Level, String)> getLogsRaw()` — raw `(level, text)` pairs;
- `List<String> getLogs({Level? level, bool richText = false})` — strings, optionally filtered to at most the given level (`Level` is re-exported from the logger package by `lib/engine.dart`);
- `clearLogs()`, `Future<void> clearLogFile()`, `Future<void> writeLogFile(String content)`;
- `String stringify(dynamic args)` — Hetu-aware value formatting.

### 2.6 Audio

`SamsaraEngine` implements `AudioPlayerInterface`:

```dart
Bgm get bgm => FlameAudio.bgm;                    // background music
Future<AudioPlayer?> play(String fileName, {double? volume});
```

`play()` plays `sound/<fileName>` from assets via `FlameAudio.play`; when `volume` is omitted it falls back to `config.soundEffectVolume`. Scene BGM is handled by `Scene.onStart`/`onEnd` through the `bgm` object passed to the scene constructor (§3.4).

### 2.7 Events (EventAggregator)

```dart
typedef EventCallback = void Function(dynamic args);

void addEventListener(String listenerId, String eventId, EventCallback callback);
void removeEventListeners(String listenerId);  // removes this id from ALL events
void emit(String eventId, [dynamic args]);
```

- Handlers are keyed `(eventId → listenerId → callback)`; registering the same `listenerId` for the same `eventId` overwrites the previous callback.
- `removeEventListeners` takes only the listener id and unregisters it from every event — there is no per-event removal.
- `emit` synchronously invokes all callbacks for the id (in debug mode it also prints the event and args).

### 2.8 Mods and scripting

HetuScript modules ("mods") can be loaded from asset strings or raw bytes:

```dart
Future<HTBytecodeModule> loadModFromAssetsString(
  String key, {
  required String module,
  List<dynamic> positionalArgs = const [],
  Map<String, dynamic> namedArgs = const {},
  bool isMainMod = false,
});
Future<HTBytecodeModule> loadModFromBytes(Uint8List bytes, {...same...});
void switchMod(String id);   // hetu.interpreter.switchModule(id)
```

Pass `isMainMod: true` for the game's main module (it is globally imported and remembered); loading a non-main mod afterwards automatically switches back to the main module. The conventional file extension for packaged mods is `.mod` (`SamsaraEngine.modFileExtension`). In `developMode` you normally iterate on plain `.ht` sources under `assets/scripts/` instead.

## 3. Scene system

### 3.1 SceneController

`SceneController` ([`lib/scene/scene_controller.dart`](../../lib/scene/scene_controller.dart)) is an abstract `ChangeNotifier` that owns:

- `Scene? scene` — the currently active scene;
- `final _cached = <String, Scene>{}` — **lazy cache** of constructed scenes;
- `final _sceneStack = <String>[]` — the navigation stack (exposed as `List<String> get sceneStack`);
- registered scene constructors and remembered per-scene constructor ids and arguments.

Scene constructors are registered up front:

```dart
void registerSceneConstructor(
    String constructorId, Future<Scene> Function(dynamic arguments) constructor);
```

One constructor can be registered under several ids, and one scene id can be associated with a constructor via `constructorId`.

Navigation API:

| Method | Behavior |
| --- | --- |
| `Future<Scene> pushScene(String sceneId, {String? constructorId, dynamic arguments, bool triggerOnStart = true, void Function()? onAfterLoaded})` | Creates (or resumes from cache) the scene, pushes `sceneId` on the stack, calls `onEnd()` on the previous scene (not awaited), sets `scene.onAfterLoaded`, notifies listeners, then awaits `onStart(arguments)`. If `sceneId` is already current, nothing happens except the optional `onStart` re-trigger — handy for "refresh". |
| `Future<Scene?> popScene({bool clearCache = false})` | Pops the top of the stack, calls `onEnd()`, optionally drops the scene from the cache (**this is the only navigation that releases resources**), then `switchScene`s back to the new top. Refuses (logs an error in debug, returns `null`) when only one scene remains. |
| `Future<Scene?> popSceneTill(String sceneId, {bool clearCache = false})` | Repeatedly pops until `sceneId` is on top. |
| `Future<Scene> switchScene(String sceneId, {dynamic arguments, bool triggerOnStart = true})` | Switches `scene` to an **already cached** scene (asserts `_cached.containsKey(sceneId)`), **without touching the navigation stack**. |
| `void clearCachedScene(String sceneId)` | Removes one scene from the cache and, if present, from the stack and cached arguments. |
| `Future<void> clearAllCachedScene({String? except, dynamic arguments, bool triggerOnStart = false})` | Drops every cached scene except `except` (switching to it if given). Never calls `onEnd()`. |
| `bool hasScene(String id)` / `bool hasSceneInSequence(String id)` | Cache membership vs. stack membership. |

Key semantics to internalize:

- **Lazy caching + resume.** A scene is constructed once; popping without `clearCache` keeps it alive. Re-entering it later resumes the *same instance* with all its components and state intact.
- **`switchScene` does not touch the stack.** It exists for temporary detours: because the stack is unchanged, a later `popScene` still returns to the stack's previous top regardless of what was switched to in between. It asserts the target is already cached (e.g. it was pushed earlier or is the current scene). `popScene` asserts the current scene *is* the stack top, so a `popScene` immediately after a `switchScene` to a non-top scene will fail the debug assert.
- **Constructor ids and arguments are remembered.** If `pushScene` is called without `constructorId`/`arguments`, the values cached from the previous push for that scene id are reused; `popScene` discards the popped scene's cached arguments. `cachedConstructorIds` / `cachedArguments` are also writable in bulk via `loadSceneConstructorIds` / `loadSceneArguments`, and per scene via `setSceneArguments`.
- `lastScene` returns the scene instance for the stack top (`null` when the stack is empty).

### 3.2 Scene

`Scene` ([`lib/scene/scene.dart`](../../lib/scene/scene.dart)) is `abstract class Scene extends FlameGame with TaskController` — each scene is a full Flame game instance with its own camera (`Camera2`), world and component tree. Constructor:

```dart
Scene({
  required this.id,
  Bgm? bgm,                 // pass engine.bgm
  String? bgmFile,          // asset under music/, played by onStart
  double bgmVolume = 0.5,
  bool enableLighting = false,
  Color? backgroundLightingColor,
});
```

The camera is always a `Camera2` configured with the lighting flags (§8).

### 3.3 Scene lifecycle

| Hook | When |
| --- | --- |
| `onLoad()` (`@mustCallSuper`) | Flame mount hook, first time the scene widget is built. The base implementation sets `bounds` from the canvas size and calls `fitScreen()`. |
| `onStart([dynamic arguments = const {}])` (`@mustCallSuper`, `FutureOr<void>`) | Called on **every entry** — including resuming a cached scene — after the controller has made it current, and awaited by `pushScene`/`switchScene`. On the **first** entry it runs *before* `onLoad`, so **do not manipulate components here**; use it to unfreeze/resume state and data. The base implementation starts `bgmFile` through the scene's `bgm` object. |
| `onEnd()` (`@mustCallSuper`) | Called when the scene loses focus (from `pushScene`/`switchScene`/`popScene`, **not awaited**). Resources are **not** released — the scene stays in the cache unless popped with `clearCache: true`. The base implementation stops the BGM. |
| `onMount()` (`@mustCallSuper`) | Fires `onAfterLoaded` **exactly once per scene instance** (guarded by `_isFirstLoad`), on the first mount. |

Caveats:

- Because scenes persist in the cache, `onStart` will be triggered repeatedly; anything you start there (timers, streams) must be safe to re-enter.
- `onAfterLoaded` is wired per-push by the controller and cleared by `popScene`/`switchScene`; the one-shot mount guard means a re-pushed cached scene will **not** fire it again.

### 3.4 Fixed timestep

`Scene.updateTree` quantizes updates:

```dart
static double fixedRate = 1 / 60;
// _dtSum += dt;
// if (_dtSum > fixedRate) { super.updateTree(fixedRate); _dtSum -= fixedRate; }
```

Each tick advances game logic by exactly `1/60` s and at most **one** tick runs per rendered frame. At 60 fps this is transparent; below 60 fps game time runs slower than wall-clock time (no catch-up loop).

### 3.5 Scene helpers

- `Rect bounds` — the canvas bounds, updated in `onLoad` and `onGameResize`.
- Nine anchor getters over `bounds`: `topLeft`, `topCenter`, `topRight`, `centerLeft`, `center`, `centerRight`, `bottomLeft`, `bottomCenter`, `bottomRight`.
- Coordinate conversion (accounting for camera position and zoom): `worldPosition2Screen(Vector2)` / `screenPosition2World(Vector2)`.
- `void fitScreen([Vector2? fitSize])` — snaps the camera to the center of `fitSize ?? size` and sets `viewfinder.zoom` so the whole area is visible (letterboxed to the viewport aspect).
- `void addHintText(String text, {Vector2? position, GameComponent? target, Color? color, TextStyle? textStyle, double duration = 2, double offsetY = 100.0, double horizontalVariation = 30.0, double verticalVariation = 30.0, bool onViewport = true, Anchor anchor = Anchor.center})` — spawns a floating `FadingText` (priority `kHintTextPriority`) that rises `offsetY` px and fades. Requests are queued through an internal `TaskController` with a minimum interval of `kMinHintInterval` (250 ms) between pops, and jittered by the variation parameters. With `onViewport: true` (default) the text is added to the camera viewport (screen space); otherwise to the world.
- `Iterable<HandlesGesture> get gestureComponents` — all descendant gesture components in reverse order (children take priority over parents in event dispatch). See [gestures.md](gestures.md).
- `hoveringComponent` / `draggingComponent` — tracked by the scene's gesture dispatch; `resetStaleGestures()` clears stale press/drag state (called automatically as a self-healing fallback when a pointer down matches no component).

### 3.6 Embedding a scene in the widget tree

```dart
Widget build(
  BuildContext context, {
  Widget Function(BuildContext)? loadingBuilder,
  Map<String, Widget Function(BuildContext, Scene)>? overlayBuilderMap,
  List<String>? initialActiveOverlays,
}) => SceneWidget(...);
```

`SceneWidget` ([`lib/scene/scene_widget.dart`](../../lib/scene/scene_widget.dart)) wraps Flame's `GameWidget` in a `PointerDetector`, forwarding every scene gesture callback (with `endDragAtWindowEdge: true` and `autofocus: false`). The standard pattern is to call `scene.build(context, ...)` from the root widget that watches the engine (§4). A scene may also override `build()` to compose Flutter widgets around the game canvas — the example's `MainMenuScene.build` stacks a `SceneWidget`, a menu button and a `GameDialogController` ([`example/lib/scene/mainmenu.dart`](../../example/lib/scene/mainmenu.dart)). `Scene.overlayUIBuilderMapKey` (`'overlayUI'`) is a conventional key for the overlay map.

## 4. Getting started — project skeleton

This is the minimal framework the example app ([`example/lib`](../../example/lib)) uses to bootstrap a game. Copy the shape, then grow your own scenes.

**1. Engine singleton** — [`example/lib/engine.dart`](../../example/lib/engine.dart):

```dart
import 'package:samsara/samsara.dart';

final SamsaraEngine engine = SamsaraEngine(
  config: const EngineConfig(
    name: 'Samsara Engine Test',
    developMode: true,
    showFps: true,
    enableLlm: false,   // never forget this unless you ship an LLM model
  ),
);

const windowSize = Size(1440.0, 810.0);
```

**2. `main()`** — window/cursor/error plumbing, then `runApp` with a `ChangeNotifierProvider` for the engine (shortened from [`example/lib/main.dart`](../../example/lib/main.dart)):

```dart
void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Route uncaught errors into the engine log + a native dialog,
    // and Flutter framework errors into a custom dialog.
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
          // ...dialog / hover providers as needed
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

**3. App widget** — register constructors, init the engine, push the first scene (from [`example/lib/app.dart`](../../example/lib/app.dart)):

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
    // ...more scenes

    await engine.init(context);   // must run before pushScene
    engine.pushScene('main', onAfterLoaded: () {
      engine.setLoading(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scene = context.watch<SamsaraEngine>().scene;      // bridge #3
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

**4. A scene** — [`example/lib/scene/mainmenu.dart`](../../example/lib/scene/mainmenu.dart) (shortened):

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

That is the whole loop: constructors → `init` → `pushScene` → the watched engine rebuilds the widget tree with `scene.build(...)` → gameplay. From here, read [gestures.md](gestures.md) for input, then the sections below for components, effects and lighting.

## 5. GameComponent

`GameComponent` ([`lib/components/game_component.dart`](../../lib/components/game_component.dart)) is the abstract base of every game object:

```dart
abstract class GameComponent extends PositionComponent
    with HasGameReference<Scene>, HasPaint
    implements SizeProvider, OpacityProvider
```

What it adds over `PositionComponent`:

- **Named paints** — Flame's `HasPaint` mixin: the constructor registers the default paint under `'default'` (`getPaint()` / `setPaint(name, paint)` / `paint` getter-setter). Subclasses register their own, e.g. `BorderComponent` adds `'borderPaint'`, `SpriteButton` adds `'hoverTintPaint'` and `'invalidPaint'`.
- **Opacity** — via `HasPaint`'s `opacity` getter/setter on the default paint; implements Flame's `OpacityProvider`, so it works with Flame's opacity effects and samsara's `FadeEffect`.
- **Visibility** — `bool isVisible` (constructor arg, default `true`). The getter ANDs the field with `scene.camera.canSee(this)` for non-HUD components, and `renderTree` returns early when invisible. Note the camera check requires the component to be mounted in a scene.
- **HUD detection** — `bool get isHud`. Computed once per `onMount()` by walking the parent chain for Flame's `Viewport`/`Viewfinder`; HUD components skip the camera visibility check and receive pointer positions in screen coordinates.
- **Lighting** — `LightConfig? lightConfig` (§8).
- **Load callback** — `FutureOr<void> Function()? onAfterLoaded`; invoked exactly once, on first mount.
- **Gesture plumbing** — `Iterable<HandlesGesture> get gestureComponents`: direct children (reversed) that handle gestures. Actual input handling comes from the `HandlesGesture` mixin — see [gestures.md](gestures.md).

### 5.1 moveTo

```dart
Future<void> moveTo({
  Vector2? toPosition,
  Vector2? toSize,
  double? toAngle,          // radians
  bool clockwise = true,
  required double duration, // seconds
  double delay = 0.0,       // seconds
  Curve curve = Curves.linear,
  void Function()? onChange,
  void Function()? onComplete,
})
```

Animates position, size and/or angle with an `AdvancedMoveEffect` (§7). Semantics:

- Calling with all three targets `null` returns immediately; if the component is already at the requested state, `onComplete` is called and the future completes.
- Any **running `AdvancedMoveEffect`s on this component are cancelled first** (removed from its children) — a new `moveTo` always wins, avoiding concurrent-move conflicts. Calling `moveTo` with the *same* targets as the running move is a no-op.
- `delay` is awaited first (in seconds); `clockwise` picks the rotation direction when `toAngle` is set.
- While the animation runs, `isMoving` is `true`; the future completes when the effect finishes.

### 5.2 snapTo

```dart
void snapTo({Vector2? toPosition, Vector2? toSize, double? toDegree})
```

Instant, non-animated teleport/resize/rotate. `toDegree` takes **degrees** (unlike `moveTo`'s `toAngle`, which is radians) and is converted internally. No-op when nothing would change.

### 5.3 fadeIn / fadeOut

```dart
Future<void> fadeIn({required double duration, void Function()? onComplete})
Future<void> fadeOut({required double duration, void Function()? onComplete})
```

Both attach a samsara `FadeEffect` (§7) and complete with it.

> **⚠ GOTCHA — fade-out removes the component.** samsara's `FadeEffect`
> calls `target.removeFromParent()` when a fade-**out** finishes. Before
> fading the component back in you must re-add it to its parent. See the
> `fader` demo in
> [`example/lib/scene/components_scene.dart`](../../example/lib/scene/components_scene.dart):
>
> ```dart
> fader.fadeOut(duration: 0.8);
> // later:
> world.add(fader);
> fader.fadeIn(duration: 0.8);
> ```

## 6. Other components

All in [`lib/components/`](../../lib/components/); exported by `package:samsara/components.dart` (and the main barrel where noted).

- **`BorderComponent`** (`border_component.dart`, also in the main barrel) — a `GameComponent` that precomputes `border` (`Rect`), `roundBorder` (`RRect`) and `clipRRect` from its size. Constructor args `borderWidth` (default 1.0) and `borderRadius` (default 0.0); the border paint defaults to a thin white stroke and is registered as `'borderPaint'`. `generateBorder()` re-runs automatically when `size` changes (it is attached as a size listener). Exposes `bounds` (absolute-positioned rect). Most UI components extend it.
- **`GestureComponent`** (`gesture_component.dart`) — abstract convenience base: `GameComponent with HandlesGesture`, gestures enabled by default. For anything interactive that doesn't need `BorderComponent`.
- **`SpriteComponent2`** (`sprite_component2.dart`) — a sprite with visibility, tint, fit, clip and zoom. Provide either `spriteId` (lazy loaded from assets on `onLoad` via `game.loadSprite`) or a `Sprite`, or set one later via `sprite=` / `tryLoadSprite()`. Notable behavior:
  - `Color? color` tints the whole canvas (`BlendMode.srcATop`);
  - `BoxFit boxFit` (default `BoxFit.fill`) controls fitting when `autoResize` is off; externally setting `size` turns `autoResize` off automatically;
  - `clipMode` clips rendering to the component rect and enables `zoom` (clamped to **1.0–2.0**) and `clipOffset` via a `ClipAndZoomDecorator` — the pattern used in the example for a scroll-zoomed map tile;
  - **gestures are opt-in**: `enableGesture` defaults to **`false`**.
- **`SpriteButton<T>`** (`ui/sprite_button.dart`) — a `BorderComponent with HandlesGesture` push button. Sprite sets for `sprite`/`borderSprite`/`hoverSprite`/`pressSprite`/`selectedSprite` (each as object or `*Id` loaded from assets), optional `text` with `ScreenTextConfig` (auto-follows `size`), `Color? color` tint, `isEnabled` (disabled buttons render with a greyscale invalid paint), `isSelectable`/`isSelected` (selected sprite state), generic `T? value`, and `onTap`. `useSpriteSrcSize` sizes the button from its sprite. `useSimpleStyle` renders preset rounded-rect fills instead of sprites. Gestures are enabled by default (mixin default).
- **`FadingText`** (`fading_text.dart`) — text that optionally moves up (`movingUpOffset`, `moveUpCurve`) and fades out after `fadeOutAfterDuration` (defaults to half of `duration`) via `FadeEffect`. Used by `Scene.addHintText`.
- **`InAndOutSprite`** (`in_and_out_sprite.dart`) — flies a sprite in from the right edge to the center, holds `stayDuration`, flies out to the left and removes itself. Must be added to a `World` or another `PositionComponent` (throws otherwise). Note: the fly-out reuses `flyInDuration`.
- **`Arrow`** (`arrow.dart`) — a red line (`linePaint`) plus a sprite arrow head; `setPath(from, to)` points the head at `to` and draws the line to its base.
- **`Timer`** (`timer.dart`) — **samsara's own timer component, not Flame's** (`Component` subclass). `Timer(duration, {loop, autoStart = true, autoDispose = true, onStart, onChange, onComplete})`; `onChange` receives the accumulated (uncapped) time each tick; on completion `end()` clamps the timer to `duration` and removes itself if `autoDispose`.
- **`ValueGenerator`** (`value_generator.dart`) — tweens `begin` → `end` (default 0 → 1) over `duration` using `curve` (default `Curves.decelerate`), reporting through `onChange`. `autoStart` defaults to **false** — call `start()`; `pause()`/`reset()`/`finish()`; removes itself when finished.
- **`ParticleComponent`** (`particle_component.dart`) — a `GameComponent` wrapper around a Flame `Particle`: forwards `update`/`render`, removes itself when `particle.shouldRemove`, and — if a `lightConfig` is present — grows `lightConfig.radius` from 0 to its original value over `lightUpDuration` (§8).
- **`DynamicColorProgressIndicator`** (`ui/progress_indicator.dart`) — a bar filled with a `lerpGradient` across `colors` (optional `stops`), `value`/`max`, optional animated transition (`animated`, default true, `animationDuration` default 4 s), `setValue(n, {animated})`, optional centered outlined `label`, `showNumber`/`showNumberAsPercentage` flags.
- **`RichTextComponent`** (`ui/rich_text_component.dart`) — renders the HTML-like rich text markup (`<bold>`, `<red>`, `<icon=...>`, …) inside the game canvas, with optional outline (`config.outlined`), `backgroundColor`, `fontScale` and re-layout via `layout({text, width, height, fontScale})`. Gestures are opt-in (`enableGesture = false`). See [richtext.md](richtext.md).
- **`Hovertip`** (`ui/hovertip.dart`) — static-only API (`show`, `hide`, `hideAll`, `toggle`, `hasTip`) for tooltips drawn in the Flame layer: instances are cached per content string, positioned relative to a target component or screen margins with 13 `HovertipDirection`s, clamped to the viewport, and added to `scene.camera.viewport`. Do not confuse with the Flutter-widget-layer `hover_info` system — they are two separate subsystems; see [hover_info.md](hover_info.md) for the disambiguation.

## 7. Effects

Files under [`lib/effect/`](../../lib/effect/):

| Class | Extends | File |
| --- | --- | --- |
| `AdvancedMoveEffect` | `Effect` | `advanced_move.dart` |
| `FadeEffect` | `Effect` | `fade.dart` |
| `CameraShakeEffect` | `Effect` | `camera_shake.dart` |
| `ZoomEffect` | `Effect` | `zoom.dart` |
| `ConfettiEffect` | `PositionComponent` | `confetti.dart` |

> All effects are exported from `package:samsara/effect.dart`, which the main
> barrel `package:samsara/samsara.dart` also re-exports — a single import
> covers them. (There is no name clash with Flame: Flame 1.38 does not ship a
> `FadeEffect`; its equivalent is `OpacityEffect`.)

- **`AdvancedMoveEffect({Vector2? endPosition, Vector2? endSize, double? endAngle, bool clockwise = true, GameComponent? target, required EffectController controller, void Function()? onChange, super.onComplete})`** — the workhorse behind `GameComponent.moveTo`. Requires at least one target (asserts otherwise); normalizes `endAngle`; interpolates position/size/angle incrementally per frame and snaps exactly to the end values on finish. `onChange` fires after each application. This is what `moveTo` cancels when superseded.
- **`FadeEffect({GameComponent? target, required EffectController controller, bool fadeIn = false, super.onComplete})`** — drives `target.opacity` 0→1 (fade-in) or 1→0; **on finish of a fade-out it removes the target from its parent** (§5.3).
- **`CameraShakeEffect({int intensity = 100, int shift = 10, int frequency = 1, required EffectController controller, super.onComplete})`** — add it to the **scene** (`game.add(...)`); in `onStart` it resolves the game's camera, then biases random shake triggers over the controller's duration: `frequency` is the max number of shakes, `shift` the pixel offset per direction, `intensity` the speed of the return move (it nudges the camera and calls `camera.moveTo2(initialPosition, speed: 100)` to come back).
- **`ZoomEffect(FlameGame game, EffectController controller, {required double zoom, super.onComplete})`** — tweens `game.camera.viewfinder.zoom` from the current value to `zoom`; **asserts the target zoom differs from the current one**.
- **`ConfettiEffect({super.position, required super.size, super.priority})`** — **not an `Effect`** but a `PositionComponent`; add it to `world` (size required). On mount it bursts 150 confetti particles (rect/circle/ triangle/ribbon shapes, preset palette, gravity, fade after ~3.5 s) and removes itself once they are all gone.

Camera helper from [`lib/extensions.dart`](../../lib/extensions.dart):

```dart
extension CameraEx on CameraComponent {
  void moveTo2(Vector2 point, {double speed = double.infinity, double? zoom, void Function()? onComplete});
  void snapTo(Vector2 position);
  void snapBy(Vector2 offset);
}
```

`moveTo2` stops the current camera movement, then tweens the viewfinder position with a `MoveToEffect` at the given `speed`; when `zoom` is provided it additionally adds a `ZoomEffect` to the game (note `onComplete` is only wired to the position effect). Distinct from `GameComponent.moveTo`, which animates a component.

## 8. Lighting

Lighting is a **camera-level render pass**, not a per-component effect. When a scene is created with `enableLighting: true`, `Camera2.renderTree` ([`lib/camera/camera2.dart`](../../lib/camera/camera2.dart)) paints the whole world, then:

1. opens a layer and paints `backgroundLightingColor` (default `Colors.black.withAlpha(200)`) over it with `BlendMode.dstATop` — the darkness;
2. for every qualifying component, punches a hole through that darkness with `BlendMode.clear` + a blurred `MaskFilter`, i.e. the "light";
3. closes the layer.

A component participates by carrying a `LightConfig` ([`lib/lighting/light_config.dart`](../../lib/lighting/light_config.dart)):

```dart
LightConfig({
  Color color = Colors.transparent, // transparent = pure dark-cutter, no hue
  bool isLighted = true,
  required double radius,           // must be > 0 (asserted)
  double blurBorder = 10.0,
  double lightUpDuration = 0.0,     // >0 grows the radius from 0 (see ParticleComponent)
  LightShape shape = LightShape.circle,   // or LightShape.rect
  Vector2? lightCenter,             // absolute; overrides the next two
  Vector2? lightCenterOffset,       // relative to component center
  int flickerRate = 0,              // accepted but currently UNUSED
})
```

- `color`/`hasHue`: a hue-tinting paint is planned but **not implemented** — regardless of `color`, the light currently only cuts through the darkness.
- Setting `blurBorder` rebuilds `lightPaint` (fill + `BlendMode.clear` + `MaskFilter.blur` with the border converted to sigma).
- Light center resolution: `lightCenter` → `component.center + lightCenterOffset` → `component.center`.
- Rect lights draw a rounded rect padded by `radius` around the component.

> **⚠ GOTCHA — direct children only.** `Camera2` only punches light holes
> for **`world.children.whereType<GameComponent>()`** — i.e. *direct children
> of the world* that are visible `GameComponent`s with
> `lightConfig.isLighted == true`. A light nested inside a group/component
> will not glow. `Scene.enableLighting` is a live getter/setter on the camera,
> and `Scene`'s constructor wires the flags through.

Runnable demo: [`example/lib/scene/lighting_scene.dart`](../../example/lib/scene/lighting_scene.dart) — static circle lights, a rect light, and an orbiting light moved with `moveTo` (animated light holes work because `moveTo` updates the component's transform each tick).

## 9. TaskController

[`lib/task.dart`](../../lib/task.dart) — `mixin class TaskController`, a **sequential async task queue** (insertion-ordered map of completers):

```dart
Future<T>? schedule<T>(FutureOr<T> Function() task, {bool isAuto = true, String? id});
void completeTask(String taskId, [dynamic result]);  // for isAuto: false tasks
bool hasTask(String id);
void clearAllTasks();
```

- Tasks run strictly one after another: a new task starts only after every previously scheduled task completed.
- With `isAuto: true` (default) the task's future result auto-completes the slot when the callback returns.
- With `isAuto: false` the slot stays pending until someone calls `completeTask(taskId, [result])` (asserts the id exists); the returned future resolves with the passed result.
- Passing an `id` that is still queued returns **`null`** and prints a debug warning instead of scheduling a duplicate — use ids to deduplicate requests.
- `clearAllTasks()` drops every pending slot without completing them.

`TaskController` is mixed into `Scene` (`with TaskController`), and `SamsaraEngine` owns a standalone `taskController` field. **Convention:** chain animations/transitions through `schedule()` rather than `await`ing raw futures — this keeps concurrent flows (UI, AI, cutscenes) from interleaving mid-animation and mirrors Flame's effect model. `GameComponent.moveTo` and `fadeIn`/`fadeOut` return futures for exactly this kind of chaining.

## 10. Extensions quick reference

[`lib/extensions.dart`](../../lib/extensions.dart) also re-exports `package:flame/extensions.dart` (minus `ListExtension`), so `toVector2()`, `toOffset()`, `toRect()` etc. are available through the samsara barrels.

| Extension | Members |
| --- | --- |
| `IterableEx<T>` | `reversed`, `random`, `randomOrNull` |
| `StringEx` | `replaceAllEscapedLineBreaks()` (literal `\n` → newline), `isBlank` / `isNotBlank`, `nonEmptyValue` (null when blank), `interpolate(List?)` (`{0}` `{1}` …) |
| `PercentageString` (num) | `toPercentageString([fractionDigits = 0])` |
| `DoubleFixed` | `toDoubleAsFixed([n = 2])` |
| `HexColor` (Color) | `fromString` (6/8 hex digits, optional `#`; throws `ArgumentError`), `toHex({leadingHashSign = true})` |
| `Vector2Ex` | `contains(position)`, `operator *` (scale), `moveAlongAngle(angle, distance)` |
| `CornerPosition` (PositionComponent) | `topLeft` … `bottomRight` (8 anchors), plus 8 `absolute*` variants |
| `CameraEx` (CameraComponent) | `moveTo2`, `snapTo`, `snapBy`, `position`, `zoom` |
| `RectEx` | `stretchTo(point)`, `operator +` (Vector2/Offset/Size), `operator *` (scale), `copyWith` |
| `RRectClone` | `copyWith` |
| `FormatHHMMSS` / `MeaningfulEx` (DateTime) | `toYMDHHMMSS()`, `toYMDHHMMSS2()`, `toMeaningful()` |

### Animation module

[`lib/animation/`](../../lib/animation/) (not barrel-exported — import directly):

- `SpriteAnimationWithTicker` (`sprite_animation.dart`) — bundles a Flame `SpriteAnimation` + `SpriteAnimationTicker`. Construct from an `animationId` (loads `animation/<id>` from the image cache; `srcSize` required), a `SpriteSheet` (`from`/`to`/`row` frame range, `stepTime` default 0.5 s, `loop` default true), or a ready `animation`. `load()` is idempotent; `clone()` copies; `update(dt)` and `render(canvas, {position})` drive it (`renderRect` support included).
- `AnimationStateController` (`animation_state_controller.dart`) — a mixin `on GameComponent` for state-machine animation: `addState(state, anim, {isOverlay})` (throws on duplicates), `loadStates()`, `containsState()`, `setState(state, {isOverlay, jumpToEnd})` (unknown states are ignored; returns the ticker-completion future only for non-looping animations), `setCompositeState({startup, recovery, actions, overlays, complete, sound, onComplete})` which chains startup → actions → recovery states sequentially and optionally plays a sound through the `audioPlayer` field. The mixin does not hook `update`/`render` itself — the host component must call `currentAnimation?.update(dt)` / `.render(canvas)` (and the overlay counterparts) each frame.

## See also

- [gestures.md](gestures.md) — `HandlesGesture` + `PointerDetector` in depth.
- [hover_info.md](hover_info.md) — Flutter-layer tooltips vs `Hovertip`.
- [richtext.md](richtext.md) — rich text markup, `RichTextIcons`, `Label`.
- [cardgame.md](cardgame.md) — cards, zones, flip/rotate animations.
- [game_dialog.md](game_dialog.md) — dialogs with avatars and selections.
- [misc.md](misc.md) — console, tilemap, markdown wiki.
