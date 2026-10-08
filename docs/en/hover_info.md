**English** | [中文](../zh/hover_info.md)

# Hover Tooltips

Samsara ships **two independent tooltip systems**. They share the same idea — show a floating info box on mouse hover — but live in different layers and are not interchangeable:

| | A. `hover_info` | B. `Hovertip` |
| --- | --- | --- |
| Layer | Flutter widget layer | Flame component layer |
| Import | `package:samsara/hover_info.dart` | `package:samsara/components.dart` |
| Anchor | a screen-space `Rect` (from a Flutter widget) | a `GameComponent` or screen position |
| Rendering | `HoverInfo` widget in the widget tree | component added to `scene.camera.viewport` (HUD) |
| Use for | Flutter overlays: menus, dialogs, labels next to the game surface | in-world game objects: sprites, tiles, buttons inside the scene |

Rule of thumb: if the trigger is a **Flutter widget**, use `hover_info`; if the trigger is a **game component**, use `Hovertip`. The runnable demo `example/lib/scene/hover_scene.dart` shows both side by side.

---

## A. `hover_info` — Flutter widget layer

Sources: `lib/hover_info/hover_content.dart`, `lib/hover_info/hover_info.dart`, barrel `lib/hover_info.dart`.

### Setup: provide `HoverContentState`

`HoverContentState` (lib/hover_info/hover_content.dart:38) is the show/hide controller, a `ChangeNotifier`. The library **does not create a provider for it** — the host app must register one above any widget that reads it. The example app does this in `example/lib/main.dart:97`:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => HoverContentState()),
    // ...other providers
  ],
  child: MyApp(),
)
```

Without this provider, `context.read<HoverContentState>()` throws.

### `HoverContentState` API

```dart
class HoverContentState extends ChangeNotifier {
  bool isDetailed = false;
  HoverContent? content;
  String? currentId;

  void setCurrentId(String? id);

  void show({
    required Rect rect,                            // screen-space rect of the hovered widget
    dynamic data,                                  // String (rich text) or Widget
    double maxWidth = kHoverInfoMaxWidth,          // 360
    HoverContentDirection direction = HoverContentDirection.bottomCenter,
    TextAlign textAlign = TextAlign.center,
    dynamic Function(bool isDetailed)? contentBuilder,
  });

  void setDetailed(bool detailed);
  void hide();
}
```

- `show` asserts `data != null || contentBuilder != null`. When only `contentBuilder` is passed, the initial data is `contentBuilder!(isDetailed)`; it also stores the builder for later `setDetailed` calls.
- `setDetailed` is a no-op when the flag is unchanged; otherwise it flips `isDetailed` and **regenerates** the content through the stored `contentBuilder`, preserving `rect`, `maxWidth`, `direction` and `textAlign`, then notifies.
- `hide` clears the stored builder and `content` (only when something is shown) and notifies.
- `setCurrentId` only records an id on the state (used by apps to track which entity the tooltip belongs to); the library itself does not interpret it.
- `kHoverInfoMaxWidth` is `360.0` (lib/hover_info/hover_content.dart:5).

### `HoverContent` and `HoverContentDirection`

`HoverContent` (lib/hover_info/hover_content.dart:22) is the immutable data holder produced by `show`: `rect`, `data`, `maxWidth`, `direction`, `textAlign`.

`HoverContentDirection` has 12 values — the first word is the side of the tooltip relative to the rect, the second is the anchor along that side:

```
topLeft, topCenter, topRight,
leftTop, leftCenter, leftBottom,
rightTop, rightCenter, rightBottom,
bottomLeft, bottomCenter, bottomRight
```

### The `HoverInfo` widget — and the stale-data gotcha

```dart
const HoverInfo(
  this.content, {
  super.key,
  this.backgroundColor = Colors.black87,
});
```

`HoverInfo` (lib/hover_info/hover_info.dart:89) is the floating box. Behavior verified from source:

- It **gates visibility on the provider** — `context.read<HoverContentState>().content == null` renders `SizedBox.shrink()` — but it **renders its constructor `content` parameter**. Feed it the state's *current* content or it displays stale data.
- Correct wiring: rebuild on state changes and pass the fresh content, e.g. a `Consumer<HoverContentState>` as in `example/lib/scene/hover_scene.dart:153`:

```dart
Consumer<HoverContentState>(
  builder: (context, hoverState, _) {
    final content = hoverState.content;
    if (content == null) return const SizedBox.shrink();
    return HoverInfo(content);
  },
),
```

- Positioning: a `SingleChildLayoutDelegate` places the box relative to `content.rect` per `direction`, with a `kHoverInfoIndent` (10) gap, clamped so the box never leaves the screen (lib/hover_info/hover_info.dart:69).
- The box is wrapped in `IgnorePointer` — it never intercepts input.
- Padding is fixed at `EdgeInsets.symmetric(horizontal: 20, vertical: 10)`; width is constrained by `content.maxWidth`.

### Rich-text content

If `data` is a `String`, it is rendered as rich text via `buildFlutterRichText` (lib/hover_info/hover_info.dart:118), so markup tags such as `<red>…</>` and `<icon=sword></>` work — see `richtext.md`. If `data` is a `Widget`, it is inserted as-is. Anything else renders an empty box.

### Triggering from widgets

`Label` (lib/widgets/ui/label.dart:6) supplies the screen-space `Rect` you need: its `onMouseEnter: void Function(Rect rect)?` receives the widget's global bounds computed by `MouseRegion2` through `RenderBox.localToGlobal` (lib/widgets/ui/mouse_region2.dart:34). `Label` also renders its own text as rich text.

```dart
Label(
  '<bold>Hover me</>',
  width: 300,
  onMouseEnter: (rect) {
    context.read<HoverContentState>().show(
          rect: rect,
          data: '<red>Rich</> Flutter-side tooltip text',
          direction: HoverContentDirection.topCenter,
        );
  },
  onMouseExit: () => context.read<HoverContentState>().hide(),
),
```

In-library usage of the same pattern: `lib/game_dialog/selection_dialog.dart:127` shows each option's `description` above the button on hover and hides it on exit (and again on selection, line 115).

### Brief / detailed content switching

Pass `contentBuilder` to `show` and toggle with `setDetailed`. The builder receives the current `isDetailed` flag, so one call site can serve both verbosity levels:

```dart
context.read<HoverContentState>().show(
  rect: rect,
  direction: HoverContentDirection.topCenter,
  contentBuilder: (isDetailed) => isDetailed
      ? '<bold>Long description</> with <blue>details</>'
      : '<bold>Short description</>',
);

// elsewhere, e.g. a "detail" button:
context.read<HoverContentState>().setDetailed(true);
```

`HoverInfo` watches `isDetailed`, so the open tooltip rebuilds with the regenerated content.

---

## B. `Hovertip` — Flame component layer

Source: `lib/components/ui/hovertip.dart`, exported from `package:samsara/components.dart`. `Hovertip` extends `BorderComponent` and is managed entirely through static methods; instances are cached singletons added to `scene.camera.viewport`, so they draw as HUD above the world.

### Direction enum

`HovertipDirection` has 13 values — the 12 directional ones plus `none`, which places the tooltip center at the target center:

```
none,
topLeft, topCenter, topRight,
leftTop, leftCenter, leftBottom,
rightTop, rightCenter, rightBottom,
bottomLeft, bottomCenter, bottomRight
```

### Static API

```dart
class Hovertip extends BorderComponent {
  static ScreenTextConfig defaultContentConfig;
  static Paint backgroundPaint;                 // black, alpha 200

  static void show({
    required Scene scene,
    GameComponent? target,                     // anchor component (world or HUD)
    String? content,                           // rich-text string
    ScreenTextConfig? config,
    HovertipDirection? direction,              // defaults to bottomCenter when targeting
    double width = kHovertipDefaultWidth,      // 360
    Vector2? position,                         // screen position when target is null
    EdgeInsets? margin,                        // screen-edge margins when target is null
  });

  static void hide([GameComponent? target]);   // hide global or one target's tooltip
  static void hideAll();
  static void toggle(GameComponent target, {required Scene scene, bool justShow = false});
  static bool hasTip(GameComponent target);
}
```

Constants: `kHovertipScreenIndent = 10.0`, `kHovertipContentIndent = 10.0`, `kHovertipBackgroundBorderRadius = 5.0`, `kHovertipDefaultWidth = 360.0`.

Semantics verified from source:

- `show` asserts `target != null || position != null`. It first calls `hideAll()`, so only one tooltip is visible at a time.
- Tooltip instances are cached by their escaped content string, and registered per target (or as a single global instance when only `position` is given).
- With a `target`, the anchor is `target.absoluteTopLeftPosition`, converted through `scene.camera.localToGlobal` (and scaled by `camera.zoom`) unless the target `isHud`. The final position is clamped inside the camera viewport.
- With only `position`, that screen position is used directly. With only `margin`, the tooltip is pinned to the corresponding screen edge, and `direction` selects the cross-axis alignment (e.g. `margin.left` plus `leftCenter` centers it vertically at the left edge).
- Content is trimmed and rendered with `buildFlameRichText`, so the same rich-text tags as in `richtext.md` work here too. Style it with the static `defaultContentConfig` / per-call `config` and the static `backgroundPaint`.
- Instance members: `setContent(String content, {ScreenTextConfig? config, required double width})` and the `content` getter. `toggle` mounts/unmounts a target's tooltip; `hasTip` reports whether a target has one.

### Triggering from a game component

Give a `GameComponent` gesture handling (see `gestures.md` and `core.md`) and assign the mouse callbacks — exactly what `example/lib/scene/hover_scene.dart:50` does:

```dart
final target = SpriteComponent2(
  spriteId: 'pepe.png',
  position: Vector2(400, 300),
  size: Vector2.all(140),
  anchor: Anchor.center,
  enableGesture: true,
);
target.onMouseEnter = () {
  Hovertip.show(
    scene: this,
    target: target,
    content: '<yellow>Hovertip:</> Flame-side tooltip rendered into the camera viewport.',
    direction: HovertipDirection.bottomCenter,
  );
};
target.onMouseExit = () => Hovertip.hideAll();
world.add(target);
```

---

## Runnable demo

`example/lib/scene/hover_scene.dart` demonstrates both systems side by side: three sprites show per-component `Hovertip`s (Flame layer), while two `Label`s below the game surface drive `HoverInfo` through `HoverContentState` (Flutter layer) — including the `Consumer` wiring that avoids the stale-content gotcha.
