**English** | [中文](../zh/misc.md)

# Miscellaneous Modules

These modules are functional but were designed for the author's own game
project, so their APIs are less generic. They are documented here briefly.

## Console — `lib/console/`

An in-game debug console (Flutter widget) backed by the embedded
[HetuScript](https://github.com/hetu-script) interpreter.

- Entry class: `Console` (`lib/console/console.dart`), exported from the main
  barrel `package:samsara/samsara.dart`.
- Requires the engine: `Console(engine: engine)`. Typically shown via
  `showDialog(context: context, builder: (_) => Console(engine: engine))`.
- Displays the engine's in-memory logs (`engine.getLogsRaw()`), color-coded by
  log level.
- `Ctrl+Enter` evaluates the input as HetuScript code through
  `engine.hetu.eval(...)` and logs the result; `Ctrl+↑` / `Ctrl+↓` navigate
  command history; `Esc` closes the dialog.
- Because scripts run inside the engine's Hetu interpreter, the console is
  most useful together with `EngineConfig(developMode: true)`, where script
  files under `scripts/` are loaded and the global `engine` object is exposed
  to scripts.

Minimal usage (see `example/lib/scene/mainmenu.dart`):

```dart
showDialog(
  context: context,
  builder: (BuildContext context) => Console(engine: engine),
);
```

## TileMap — `lib/tilemap/`

A tilemap component supporting hexagonal (vertical/horizontal), orthogonal
and isometric layouts, with terrain zones, fog of war and route-following
actors. It was built for a specific strategy/RPG project, so several concepts
(zones, cities, nations, terrain types) are opinionated.

- Entry class: `TileMap` (`lib/tilemap/tilemap.dart`) — a `GameComponent`
  with `HandlesGesture`; constructed from tile size, shape and data, it
  renders terrain sprites from a sprite sheet and handles tile hover /
  selection paints.
- `TileMapTerrain` (`lib/tilemap/terrain.dart`) — a single tile: sprite sheet
  cell index plus optional animations.
- `TileMapComponent` (`lib/tilemap/component.dart`) — a movable actor on the
  map (NPC/unit) with walk/swim animation states; follows a path of
  `TileMapRouteNode`s (`lib/tilemap/route.dart`).
- Supporting types: `TileInfo` mixin, `TilePosition`, `TileShape`,
  `TileRenderDirection`, direction enums, `AnimatedCloud`.
- Zone coloring modes via constants `kColorModeNone`, `kColorModeZone`,
  `kColorModeCity`, `kColorModeNation`.
- Barrel: `package:samsara/tilemap.dart`.

If you need a generic tilemap, prefer building on Flame's own tile components;
this module is best read as a reference implementation of a hex map with
fog-of-war and routing.

## Markdown Wiki — `lib/markdown_wiki/`

An in-game wiki / help browser (Flutter widget) that renders a tree of
markdown pages bundled as assets.

- Entry class: `MarkdownWiki` (`lib/markdown_wiki/markdown_wiki.dart`) — a
  `Scaffold` with a 300px page tree on the left (via `animated_tree_view`)
  and a selectable markdown pane on the right
  (`flutter_markdown_plus`); page titles are localized through
  `engine.locale(...)`.
- Data: `WikiPageData` + `buildWikiTreeNodesFromData()`
  (`lib/markdown_wiki/node_builder.dart`) build the tree from nested map data;
  page content is loaded from asset paths via `rootBundle`.
- Barrel: `package:samsara/markdown_wiki.dart`.
- The expected index/content file layout matches the author's own game (see
  `example/wiki/` for a sample structure); treat the widget as a starting
  point rather than a drop-in generic wiki.
