**English** | [中文](../zh/gestures.md)

# Gestures

Samsara's gesture system is **fully custom — it does not use any of Flame gesture mixins** (`TapCallbacks`, `DragCallbacks`, etc.). Raw Flutter pointer events are captured by a widget, recognized as high-level gestures, dispatched engine-wide by the `Scene`, and finally resolved per-component by a mixin. Every signature below was verified against the source; behavioral quirks and known bugs are stated as they are.

Public API is exported from two barrels:

- `package:samsara/gestures.dart` — `HandlesGesture`, `TappingDetails`, `PointerDetector`, the detail classes (`TouchDetails`, `PointerMoveDetails`, `PointerMoveUpdateDetails`, `MouseScrollDetails`), Flutter's gesture detail classes (`TapDownDetails`, `TapUpDetails`, `DragStartDetails`, `DragUpdateDetails`, `ScaleStartDetails`, `ScaleUpdateDetails`, `LongPressStartDetails`), `PointerHoverEvent`, and the mouse-button constants `kPrimaryButton` / `kSecondaryButton` / `kTertiaryButton` / `kBackMouseButton` / `kForwardMouseButton` (re-exported from `package:flutter/gestures.dart`).
- `package:samsara/components.dart` — `GestureComponent` plus gesture-aware components such as `SpriteComponent2` and `SpriteButton`.

## The four-layer pipeline

```
 raw pointer events (Flutter Listener + MouseRegion)
        |
        v
+-----------------------------+
| 1. PointerDetector           |  StatefulWidget (lib/widgets/pointer_detector.dart:128).
|    (Flutter widget layer)    |  Recognizes tap / drag / scale / long-press /
|                              |  hover / scroll; heals stale pointer records;
|                              |  force-ends drags at the window edge.
+--------------+---------------+
               | onTapDown / onDragUpdate / onScaleStart / ... (global screen coords)
               v
+-----------------------------+
| 2. Scene.onXxx               |  Scene dispatch (lib/scene/scene.dart). Walks
|    (scene dispatch layer)    |  gestureComponents deepest-first, tracks
|                              |  hoveringComponent & draggingComponent, owns
|                              |  resetStaleGestures().
+--------------+---------------+
               | handleTapDown / handleDragUpdate / ... (same-named handle* methods)
               v
+-----------------------------+
| 3. HandlesGesture.handle*    |  Mixin on GameComponent (lib/gestures/gesture_mixin.dart:37).
|    (component layer)         |  Child-first delegation, hit test via
|                              |  containsPoint, screen->world conversion, then
|                              |  fires the onXxx callback fields.
+--------------+---------------+
               | onTap / onDragUpdate / onMouseEnter / ...
               v
          your callbacks
```

`SceneWidget` (lib/scene/scene_widget.dart:25) performs the 1→2 wiring automatically: it wraps Flame's `GameWidget` in a `PointerDetector`, connects every widget callback to the same-named `Scene` method, and sets `onStaleGestureReset: scene.resetStaleGestures` and `endDragAtWindowEdge: true`. Any scene built with `scene.build(...)` gets this pipeline for free.

Why a custom pipeline instead of Flame's mixins:

- **One unified pipeline for mouse and touch.** Tap, double-tap, long-press, drag (any mouse button), two-finger scale, mouse hover, and mouse-wheel scroll are all recognized simultaneously by the same widget and flow through the same dispatch path.
- **Cross-component drag semantics.** `onDragOver` / `onDragIn` let a component act as a drop target while *another* component is being dragged — something per-component gesture mixins do not model.
- **Desktop window-edge cases.** `endDragAtWindowEdge` works around a Windows `SetCapture` freeze, and `resetStaleGestures` heals stale pointer records that otherwise block all input (see [Scene-level dispatch](#scene-level-dispatch--coordinate-conversion)).

## Quick start: an interactive component

Extend `GestureComponent` (lib/components/gesture_component.dart:4 — a `GameComponent` with `HandlesGesture` mixed in) or add `with HandlesGesture` to your own `GameComponent` subclass, then assign the callback fields:

```dart
import 'package:flame/components.dart';
import 'package:samsara/components.dart';

class MyButton extends GestureComponent {
  MyButton({super.position})
      : super(size: Vector2(160, 60), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    onTap = (button, position) => print('tapped at $position');
    onMouseEnter = () => opacity = 0.7;
    onMouseExit = () => opacity = 1.0;
    onMouseScrollUp = (position) => scale *= 1.1;
    onMouseScrollDown = (position) => scale *= 0.9;
  }
}

// inside a Scene:
world.add(MyButton(position: center));
```

Two gates decide whether a component receives gestures at all (checked at the top of every `handle*` method):

- `enableGesture` — `true` by default on `HandlesGesture`, **but `SpriteComponent2` overrides the default to `false`** and takes an `enableGesture:` constructor parameter to opt in (lib/components/sprite_component2.dart:87).
- `isVisible` — false when hidden explicitly, and for non-HUD components also when off-camera (`scene.camera.canSee(this)`, lib/components/game_component.dart:29). Invisible components receive no gestures.

If you override any `handle*` method in a subclass, it is `@mustCallSuper` — you **must** call `super` or child-component dispatch breaks. The same applies when overriding the `Scene`-level `onTapDown` / `onDragUpdate` / ... dispatch methods (see `example/lib/scene/mainmenu.dart:89` for a correct override).

## `HandlesGesture` reference

Defined in lib/gestures/gesture_mixin.dart:37 as `mixin HandlesGesture on GameComponent`.

### State fields

| Field | Type | Meaning |
| --- | --- | --- |
| `enableGesture` | `bool` | master switch for this component (see gates above) |
| `isPressing` | `bool` | a pointer is currently held down on this component |
| `isDragging` | `bool` | this component is being dragged (backed by an internal drag-start point) |
| `isScaling` | `bool` | this component is being two-finger scaled |
| `isHovering` | `bool` | the mouse cursor is over this component (tracked by `Scene`) |
| `doubleTapTimer` | `Timer?` | internal double-tap window timer |

Static, engine-wide members:

- `static int doubleTapTimeConsider = 400` — double-tap window in milliseconds, shared by all components.
- `static Map<int, TappingDetails> tappingDetails` — registry of every active pointer (`pointer` → `TappingDetails{pointer, button, globalPosition, component}`), recording which component captured each tap-down. `Scene` uses it for drag bookkeeping and stale-gesture healing; `handleScaleEnd` removes only the entries of the pointers that participated in the scale (their tap-up will never arrive once the scale gesture resets the detector state).

### Callback fields

All positions are **component-local** unless noted. `button` is the Flutter button constant that caused the event (see [Mouse buttons](#mouse-buttons)).

| Field | Signature | Fires when |
| --- | --- | --- |
| `onTapDown` | `void Function(int button, Vector2 position)?` | pointer pressed inside the component. Registers the pointer in `tappingDetails`. |
| `onTapUp` | `void Function(int button, Vector2 position)?` | pointer released inside the component (after `onTap`). |
| `onTap` | `void Function(int button, Vector2 position)?` | a click completes inside. Also fires as the second half of a double-tap, and is **synthesized** when a drag ends within 10 px of its start while hovering. |
| `onDoubleTap` | `void Function(int button, Vector2 position)?` | second tap lands within `doubleTapTimeConsider` (400 ms) of the first. Ordering on the second tap: `onTap` → `onDoubleTap` → `onTapUp`. |
| `onLongPress` | `void Function(Vector2 position)?` | pointer held ~400 ms without moving (`longPressTickTimeConsider` at the widget layer). |
| `onDragStart` | `HandlesGesture? Function(int button, Vector2 position)?` | the pointer starts moving while pressed on this component (drag requires a prior `onTapDown` on the same component). **Return the dragged child**; returning `null` means *this* component is the dragged object. The returned component becomes `Scene.draggingComponent`. |
| `onDragUpdate` | `void Function(int button, Vector2 position, Vector2 delta)?` | *this* component is being dragged. **`position` is the camera-converted world position** (screen position for HUD), **not** component-local; `delta` is the world-space movement since the last event. |
| `onDragOver` | `void Function(int button, GameComponent? component)?` | *another* component is dragged across this one. |
| `onDragEnd` | `void Function(Vector2 position)?` | *this* component's drag finishes. `position` is the world/screen position (same conversion as `onDragUpdate`), not component-local. |
| `onDragIn` | `void Function(Vector2 position, GameComponent? component)?` | *another* component is dropped inside this one (fires on the drop target during drag-end). |
| `onScaleStart` | `void Function(List<TouchDetails> touches, ScaleStartDetails details)?` | two touch points are both inside the component. |
| `onScaleUpdate` | `void Function(List<TouchDetails> touches, ScaleUpdateDetails details)?` | the two-finger scale changes; `details.scale` is the distance ratio, `details.rotation` is the rotation angle (radians) of the two-touch line since the scale started. |
| `onScaleEnd` | `void Function()?` | scaling finishes. |
| `onMouseEnter` | `void Function()?` | the cursor starts hovering this component (managed by `Scene`, not the widget). |
| `onMouseHover` | `void Function(Vector2 position)?` | the cursor moves over the component. |
| `onMouseExit` | `void Function()?` | the cursor leaves this component. |
| `onMouseScrollUp` / `onMouseScrollDown` | `void Function(Vector2 position)?` | mouse wheel up / down over the component (`scrollDelta.dy < 0` is up, `> 0` is down). |

Drag/drop semantics in one scenario: while component **A** is dragged across component **B**, B's `onDragOver(button, A)` fires on every move; when the button is released, B's `onDragIn(localPosition, A)` fires. A itself receives `onDragStart`/`onDragUpdate`/`onDragEnd`. Click-synthesis: if the release point is within **10 px** (global screen distance) of the drag-start point **and** the cursor is still hovering the component, `onTap` + `onTapUp` are synthesized — a click that barely moved still counts as a click.

## Scene-level dispatch & coordinate conversion

`Scene` (lib/scene/scene.dart) exposes same-named dispatch methods — `onTapDown`, `onTapUp`, `onDragStart`, `onDragUpdate`, `onDragEnd`, `onScaleStart`, `onScaleUpdate`, `onScaleEnd`, `onLongPress`, `onMouseHover`, `onMouseScroll` — all `@mustCallSuper`.

- **Dispatch order**: `gestureComponents` (lib/scene/scene.dart:189) is `descendants(reversed: true).whereType<HandlesGesture>()` — reverse breadth-first: **deepest descendants first, later-added siblings first**, so the visually top-most component wins.
- **Exclusive vs. broadcast**: tap-down, tap-up, drag-start, long-press, scale-start, and hover stop at the first component whose `handle*` returns non-null; drag-update, drag-end, scale-update, and scroll are broadcast to **all** gesture components (required for `onDragOver`/`onDragIn` drop-target semantics).
- **Child-first recursion**: inside a component, `gestureComponents` (lib/components/game_component.dart:84) is `children.reversed().whereType<HandlesGesture>()`, so children get the event before their parent's own hit test.
- **Hover tracking**: `Scene.hoveringComponent` is updated in `Scene.onMouseHover` — the old component gets `isHovering = false` + `onMouseExit`, the new one `isHovering = true` + `onMouseEnter`. `Scene.draggingComponent` holds the value returned by `onDragStart` for the active drag.

**Coordinate systems.** `PointerDetector` and the `Scene` dispatch methods work in Flutter **global screen coordinates**. Conversion to component space happens inside each `handle*` method:

```
screen (global)                       HUD component        world component
    |  game.camera.globalToLocal  (skipped if isHud)  ->  world position
    |  containsPoint(world/screen position)                (hit test)
    |  toLocal(...)                                        -> component-local position
```

`isHud` is derived automatically: a component mounted under the camera's `Viewport`/`Viewfinder` is HUD (lib/components/game_component.dart:17). Two helpers on `Scene` convert between the spaces manually: `worldPosition2Screen` / `screenPosition2World` (lib/scene/scene.dart:82). Caveat: the `delta` passed to `onDragUpdate` is always camera-converted, even for HUD components.

**Stale-gesture healing (`resetStaleGestures`, lib/scene/scene.dart:242).** On Flutter desktop, dragging out of the window and back can reassign a new pointer id to the same physical press; the old id's records never see a matching pointer-up and stay behind, after which input appears dead. The layered defense:

1. `PointerDetector` clears its own touch records on a fresh pointer-down when leftovers exist and fires `onStaleGestureReset`.
2. `SceneWidget` wires that callback to `scene.resetStaleGestures`, which sets `isPressing = false` on every stale component, clears `HandlesGesture.tappingDetails`, and clears `draggingComponent`.
3. `Scene.onTapDown` calls `resetStaleGestures()` as a fallback when no component consumes a tap-down; `Scene.onTapUp` does the same when an unmatched pointer-up arrives while records exist.

## `PointerDetector`: standalone widget usage

`PointerDetector` (lib/widgets/pointer_detector.dart:128) is an ordinary Flutter `StatefulWidget` and can wrap **any** widget — not only game scenes. `SceneWidget` uses it internally, but you can equally embed it in a plain Flutter UI:

```dart
PointerDetector(
  onTapDown: (pointer, button, details) => print('down $button @ ${details.globalPosition}'),
  onDragUpdate: (pointer, button, details) => ...,
  onMouseScroll: (details) => print(details.scrollDelta),
  child: MyFlutterWidget(),
)
```

### Constructor parameters

| Parameter | Type / default | Notes |
| --- | --- | --- |
| `child` | `Widget?` | the wrapped widget |
| `behavior` | `HitTestBehavior.deferToChild` | passed to the inner `Listener` |
| `cursor` | `MouseCursor.defer` | **dead parameter** — never applied (see [Known limitations](#known-limitations)) |
| `endDragAtWindowEdge` | `bool`, default `false` | when true, a drag is force-ended the moment the pointer leaves the window client area. Workaround for a Windows `SetCapture` issue where moves outside the client area keep arriving and can freeze the engine's ticker. `SceneWidget` always enables it. |
| `longPressTickTimeConsider` | `int`, default `400` | long-press delay in ms |

### Callbacks

| Callback | Signature |
| --- | --- |
| `onTapDown` / `onTapUp` | `void Function(int pointer, int button, TapDownDetails/TapUpDetails details)?` |
| `onDragStart` / `onDragUpdate` | `void Function(int pointer, int button, DragStartDetails/DragUpdateDetails details)?` |
| `onDragEnd` | `void Function(int pointer, int button, TapUpDetails details)?` — note the `TapUpDetails` type; the `button` comes from the original down event because pointer-up loses it |
| `onScaleStart` / `onScaleUpdate` | `void Function(List<TouchDetails> touches, ScaleStartDetails/ScaleUpdateDetails details)?` |
| `onScaleEnd` | `void Function()?` |
| `onLongPress` | `void Function(int pointer, int button, LongPressStartDetails details)?` |
| `onMouseHover` | `void Function(PointerMoveDetails details)?` |
| `onMouseScroll` | `void Function(MouseScrollDetails details)?` |
| `onStaleGestureReset` | `void Function()?` — fires when stale touch records were detected and cleared on a fresh pointer-down |

### Internals

- Drag starts only after the pointer moves **more than 1 px** from its down position; until then the gesture is a potential tap/long-press.
- Move and hover events are **aggregated over a 10 ms timer** (`kMoveTimeDeltaThresholdByMS`) before a single callback fires — up to one tick of input latency by design.
- Two-finger scale: `details.scale` is the ratio of the current finger distance to the initial distance; the focal point is the finger midpoint.
- Long-press is a plain `Timer`; any movement cancels it.
- Hover comes from `PointerHoverEvent`, scroll from `PointerScrollEvent` (`PointerSignalEvent`s that are not scrolls are ignored).
- Detail classes (also re-exported via `samsara/gestures.dart`): `TouchDetails` (`pointer`, `button`, `startLocalPosition`, `startGlobalPosition`, `currentLocalPosition`, `currentGlobalPosition`), `PointerMoveDetails` (`timestamp`, `pointer`, `delta`, `position`, `localPosition`, `button`), `PointerMoveUpdateDetails` (Flutter `DragUpdateDetails`-shaped clone), `MouseScrollDetails` (`scrollDelta`, `position`, `localPosition`, `kind`).

## Mouse buttons

The button constants from `package:flutter/gestures.dart` are re-exported by `samsara/gestures.dart`: `kPrimaryButton` (left), `kSecondaryButton` (right), `kTertiaryButton` (middle), `kBackMouseButton`, `kForwardMouseButton`. Drags fire for any pressed button; check `button` in your handler to distinguish.

A real example — right-drag pans the camera in `example/lib/scene/mainmenu.dart:89`:

```dart
@override
void onDragUpdate(int pointer, int button, DragUpdateDetails details) {
  super.onDragUpdate(pointer, button, details); // keep component dispatch alive

  if (button == kSecondaryButton) {
    camera.moveBy(-details.delta.toVector2());
  }
}
```

## Known limitations

- **`PointerDetector.cursor` is never applied.** The constructor stores it, but `build` ignores it (the `MouseRegion` deliberately sets no cursor). Pass cursors to inner widgets instead.
- **No widget-level enter/exit.** `PointerDetector.onMouseEnter` / `onMouseExit` are commented out in source (lib/widgets/pointer_detector.dart:145). Enter/exit exists only at the `Scene` level, derived from hover hit-testing — standalone `PointerDetector` usage has no enter/exit callbacks.
- **Position quirks in drag callbacks.** `onDragUpdate` / `onDragEnd` receive camera-converted world positions instead of component-local ones, and `onDragUpdate`'s `delta` is camera-converted even for HUD components. Convert manually (`toLocal`) if you need local coordinates there.
- **Move aggregation latency.** Pointer moves and hovers are delivered on a 10 ms timer, so callbacks lag the raw events by up to one tick.

## Runnable demo

The `Components` scene in the example app demonstrates every gesture with a live log: tap, double-tap, long-press, drag (move the sprite by `delta`), hover enter/exit (opacity change), and wheel zoom. See `example/lib/scene/components_scene.dart:99` (the GESTURES area). Run it with:

```bash
cd example
flutter run
```
