# Samsara Engine — Project Guidelines

## Overview

Samsara is a Dart/Flutter utility library wrapping the **Flame game engine**. It provides reusable subsystems: scene management, gesture handling, hex tilemaps, card games, rich text rendering, dialog systems, animation task scheduling, and more.

## Architecture

### Class Hierarchy

```
PositionComponent (Flame)
  └─ GameComponent (abstract base for all game objects)
      ├─ GestureComponent (+ HandlesGesture mixin)
      ├─ TileMap (hex tilemap + HandlesGesture)
      ├─ BorderComponent, SpriteComponent2, etc.

FlameGame (Flame)
  └─ Scene (+ TaskController mixin) — standalone game instances

SceneController (abstract + ChangeNotifier)
  └─ SamsaraEngine (+ EventAggregator, HTLogger) — top-level engine
```

### Key Subsystems

| Module     | Path               | Purpose                                         |
| ---------- | ------------------ | ----------------------------------------------- |
| Scene      | `lib/scene/`       | Stack-based scene navigation with lazy caching  |
| Components | `lib/components/`  | Base game objects with paint management         |
| Gestures   | `lib/gestures/`    | Unified pointer/touch/drag/scale mixin          |
| TileMap    | `lib/tilemap/`     | Hexagonal tilemap with terrain/routing          |
| Card Game  | `lib/cardgame/`    | Card mechanics, zones, flip/rotate animations   |
| Effects    | `lib/effect/`      | Camera shake, fade, confetti, zoom              |
| Task       | `lib/task.dart`    | Sequential async animation scheduling           |
| Event      | `lib/event.dart`   | Pub/sub between Flame components and Flutter    |
| Rich Text  | `lib/richtext/`    | HTML-like rich text builder for Flutter & Flame |
| Dialog     | `lib/game_dialog/` | In-game dialog with avatar & selection          |
| Console    | `lib/console/`     | In-game HetuScript console                      |
| Paint      | `lib/paint/`       | Custom TextPaint and TextElement wrappers       |

### Barrel Exports

Public API is exposed via barrel files at `lib/` root: `samsara.dart`, `engine.dart`, `components.dart`, `tilemap.dart`, `cardgame.dart`, etc.

## Conventions

- **Scene lifecycle**: scenes are lazily constructed, cached in `SceneController`, and navigated via `pushScene`/`popScene`/`switchScene`
- **Task scheduling**: use `TaskController.schedule()` for sequential async work (animations, transitions) — never `await` raw futures for chained animations
- **Event communication**: use `EventAggregator.emit()`/`addEventListener()` to bridge Flame game state to Flutter widget layer
- **Component paint**: use `GameComponent.setPaint(name, paint)` for named paint state management
- **Opacity**: implement `OpacityProvider` and use `FadeEffect` for fade-in/out

## Pitfalls

- Path dependencies (`hetu_script`, `fluent_ui`) must exist as sibling folders — `flutter pub get` will fail otherwise
- Gesture mixin methods (`onTapDown`, `onDragUpdate`, etc.) should call `super` to preserve the chain
- `Scene` extends `FlameGame` — each scene is a full game instance, not a lightweight object
