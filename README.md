# Samsara Engine

**English** | [中文](README_ZH.md)

A Dart/Flutter utility library wrapping the [Flame game engine](https://flame-engine.org/).
It adds the pieces Flame leaves to you: scene management with a navigation
stack, a unified gesture system, rich text, game dialogs, card game
primitives, lighting, and a sequential animation task scheduler.

## Features

| Module | Highlights | Guide |
|---|---|---|
| Core | `SamsaraEngine`, stack-based scene navigation with lazy caching, `GameComponent` base with named paints / `moveTo` / fades, camera effects, dark-overlay lighting, `TaskController`, event bus | [docs/en/core.md](docs/en/core.md) |
| Gestures | One mixin (`HandlesGesture`) + one widget (`PointerDetector`) for tap, double-tap, drag & drop, two-finger scale, long-press, hover and mouse scroll — unified for mouse and touch | [docs/en/gestures.md](docs/en/gestures.md) |
| Hover tooltips | Flutter-layer `hover_info` tooltips with 12-direction positioning, and Flame-layer `Hovertip` for in-world objects | [docs/en/hover_info.md](docs/en/hover_info.md) |
| Rich text | HTML-like tags (`<bold>`, `<h2>`, `<red>`, `<legendary>`, `color='#ffd700'`, inline `<icon=...>`) rendered in both Flutter widgets and Flame components | [docs/en/richtext.md](docs/en/richtext.md) |
| Card game | Card model with pile linked-list semantics, flip/rotate/focus animations, data-driven card faces, draw & pile zones | [docs/en/cardgame.md](docs/en/cardgame.md) |
| Game dialog | Visual-novel style dialog model + overlay controller: conversations, selections, tutorial screen hints | [docs/en/game_dialog.md](docs/en/game_dialog.md) |
| Misc | In-game HetuScript console, hex tilemap with fog of war, markdown wiki — project-specific, documented briefly | [docs/en/misc.md](docs/en/misc.md) |

Full index: [docs/README.md](docs/README.md)

## Quick start

```dart
import 'package:samsara/samsara.dart';

// 1. A scene is a full Flame game instance.
class MainScene extends Scene {
  MainScene({required super.id});

  @override
  Future<void> onLoad() async {
    super.onLoad();
    final button = SpriteButton(
      anchor: Anchor.center,
      text: 'Hello',
      spriteId: 'button.png',
      useSpriteSrcSize: true,
      position: center,
    );
    button.onTap = (button, position) =>
        addHintText('Hello samsara!', position: center);
    world.add(button);
  }
}

// 2. The engine owns the scene stack.
final engine = SamsaraEngine(config: const EngineConfig(enableLlm: false));

// 3. In your root StatefulWidget's initState:
//    engine.registerSceneConstructor('main', ([args]) async => MainScene(id: 'main'));
//    await engine.init(context);
//    engine.pushScene('main');
// 4. In build(): provide the engine with Provider and render the current scene —
//    context.watch<SamsaraEngine>().scene?.build(context)
```

The complete, commented project skeleton (window setup, loading screen,
error handling) is in [docs/en/core.md](docs/en/core.md#4-getting-started--project-skeleton) and
runs as the [`example/`](example/) app.

## Example app

```bash
cd example
flutter pub get
flutter run -d windows
```

The example app is a single game whose main menu pushes one demo scene per
module: components & gestures & effects, lighting, rich text, hover tooltips,
card game, and game dialog.

## Dependencies

`hetu_script`, `hetu_script_flutter` and `fluent_ui` are resolved via relative
paths to sibling directories (`../hetu-script/...`, `../fluent_ui`), so those
repositories must sit next to this one or `flutter pub get` will fail.

## License

See [LICENSE](LICENSE).
