**English** | [中文](README_ZH.md)

# Samsara Engine Documentation

Samsara is a Dart/Flutter utility library wrapping the
[Flame game engine](https://flame-engine.org/). This directory contains the
module guides; runnable demos for most modules live in the
[`example/`](../example/) app (each demo is a separate scene).

## Guides

| Module | Doc | What it covers |
|---|---|---|
| Core | [core.md](en/core.md) | Engine, scene system, GameComponent family, effects, lighting, task scheduler, events — plus a full getting-started project skeleton |
| Gestures | [gestures.md](en/gestures.md) | `HandlesGesture` mixin and the `PointerDetector` widget: tap / double-tap / drag & drop / scale / long-press / hover / scroll |
| Hover tooltips | [hover_info.md](en/hover_info.md) | The Flutter-layer `hover_info` tooltip and the Flame-layer `Hovertip` component |
| Rich text | [richtext.md](en/richtext.md) | HTML-like rich text tags for both Flutter widgets and Flame components, inline icons |
| Card game | [cardgame.md](en/cardgame.md) | Card model with pile semantics, data-driven card faces, draw/pile zones |
| Game dialog | [game_dialog.md](en/game_dialog.md) | Visual-novel style dialog sequences, selections, screen hints |
| Misc | [misc.md](en/misc.md) | Brief notes on the project-specific modules: console, tilemap, markdown wiki |

## Reading order

New to the library? Start with [core.md](en/core.md) — its "Getting Started"
section walks through bootstrapping a project, and every other module builds
on the scene/component model described there.
