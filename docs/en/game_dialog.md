**English** | [中文](../zh/game_dialog.md)

# Game Dialog — Visual-Novel-Style Dialog System

Public API is exported from the barrel file `lib/game_dialog.dart`, which re-exports five source files under `lib/game_dialog/`:

| Source file | Contents |
| --- | --- |
| `lib/game_dialog/game_dialog.dart` | `GameDialog` model, `SceneInfo`, `IllustrationInfo`, `ScreenHintInfo` |
| `lib/game_dialog/game_dialog_controller.dart` | `GameDialogController` overlay widget, illustration layout constants |
| `lib/game_dialog/game_dialog_content.dart` | `GameDialogContent` dialog box widget |
| `lib/game_dialog/selection_dialog.dart` | `SelectionDialog` choice list widget |
| `lib/game_dialog/screen_hint.dart` | `ScreenHint` tutorial overlay widget |

## 1. Overview

The dialog system follows a **model / controller separation**:

- **`GameDialog`** (`lib/game_dialog/game_dialog.dart:56`) is the model. It mixes in `ChangeNotifier` and `TaskController` (see the TaskController section in `core.md`), and holds the entire scripted state: background scenes, illustrations, pending dialog contents, selection data, screen-hint info, and arbitrary stored values. It owns **no UI**.
- **`GameDialogController`** (`lib/game_dialog/game_dialog_controller.dart:15`) is a Flutter widget. It listens to the model via `context.watch<GameDialog>()` and overlays the right widget for the current state: `GameDialogContent` (typewriter dialog box with avatar/name), `SelectionDialog` (choice list), `ScreenHint` (tutorial spotlight), plus full-screen background images and centered illustrations.

A script is a **sequence of scheduled tasks**: each `push*` call appends one task to the model's queue. Interactive tasks (dialog, selection, screen hint) are scheduled with `isAuto: false`, so they block the queue until the player acts; automatic tasks (background swaps, plain code via `pushTask`) complete on their own. `execute()` appends a final cleanup task and returns a `Future` that resolves when the whole script — including waiting for player input — has finished.

All user-facing strings support the samsara rich-text tag syntax (e.g. `'<red>…</>'`, `'<icon=sword></>'`); see `../richtext/readme.md`.

## 2. Setup

The host app creates **one global `GameDialog` instance** and provides it through the widget tree. From `example/lib/engine.dart:15`:

```dart
import 'package:samsara/game_dialog.dart';

final dialog = GameDialog();
```

Provide it (together with `HoverContentState`, which `SelectionDialog` requires — see the caveats) in `main()`, from `example/lib/main.dart:92`:

```dart
runApp(
  MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => engine),
      ChangeNotifierProvider(create: (_) => dialog),
      ChangeNotifierProvider(create: (_) => HoverContentState()),
    ],
    child: ...,
  ),
);
```

Place one `GameDialogController` in each scene's `build()` `Stack`, **above** `SceneWidget`, from `example/lib/scene/dialog_scene.dart:130`:

```dart
@override
Widget build(BuildContext context, {...}) {
  return Scaffold(
    body: Stack(
      children: [
        SceneWidget(scene: this),
        GameDialogController(), // renders dialog UI on top of the game
      ],
    ),
  );
}
```

The main menu does the same in `example/lib/scene/mainmenu.dart:195`. Any scene that can show dialogs needs its own `GameDialogController`; without one in the tree the model state still changes but nothing is rendered.

## 3. `GameDialog` API reference

Import: `package:samsara/game_dialog.dart`. Since it is a `ChangeNotifier`, the controller rebuilds automatically whenever a push/finish method calls `notifyListeners()`.

### Model state fields

| Field | Type | Meaning |
| --- | --- | --- |
| `isOpened` | `bool` | Set to `true` by every push method; reset by `execute()`'s cleanup. |
| `scenes` | `Set<SceneInfo>` | Background image stack. `currentSceneInfo` returns the last one. |
| `prevScene` | `SceneInfo?` | The scene being faded out / replaced, for cross-fade rendering. |
| `illustrations` | `Set<IllustrationInfo>` | Centered illustration images drawn over the background. |
| `contents` | `Map<String, dynamic>` | Pending dialog boxes, keyed by task id. `currentContent` returns the last value. |
| `selectionsData` | `dynamic` | Current selection data (with an auto-assigned `'taskId'`), or `null`. |
| `screenHintInfo` | `ScreenHintInfo?` | Current screen hint, or `null`. Only one can exist at a time. |
| `storedValues` | `Map<String, dynamic>` | Bag of script-defined values (selection results, `flagId` task results, …). |

Value storage: `loadValues(Map<String, dynamic> values)` replaces the whole bag; `dynamic getValue(String key)` reads one entry.

### Dialog content

```dart
void pushDialogRaw(dynamic content, {String? imageId})
```

Pushes one dialog box. `content` may be:

- a `String` — treated as a single line;
- a `List<String>` — treated as the `lines` list;
- a `Map` / `HTStruct` with the keys below (an assert throws for anything else).

Documented data format (`lib/game_dialog/game_dialog.dart:250`):

```dart
{
  'name': 'Pepe the Guide', // speaker name shown above the text
  'icon': 'pepe.png',       // avatar image, relative to assets/images/
  'image': '...',           // documented key; not read by the built-in UI
  'lines': ['line 1', 'line 2'], // each entry is one typewriter line
}
```

The method auto-assigns `resolved['id'] = taskId`; `GameDialogContent` also reads an optional `'characterId'` (passed to `onAvatarPressed` on avatar tap). The task is scheduled with `isAuto: false` — it pauses the script until the player clicks through every line and the widget calls `finishDialog(id)`. If `imageId` is given, a matching illustration is pushed before the dialog and popped right after it, so the picture shows only while that box is on screen.

```dart
void finishDialog(String id)  // removes the content and completes its task
void finishTask(String id)    // completes any pending task by id (no-op if absent)
```

### Selections

```dart
void pushSelectionRaw(dynamic selectionsData)
```

`selectionsData` must be a `Map` / `HTStruct` (assert), in this format (`lib/game_dialog/game_dialog.dart:316`):

```dart
{
  // key under which the player's answer is stored in storedValues
  'id': 'choice',
  'selections': {
    // either a plain text…
    'nothing': 'No thanks',
    // …or a text plus a hover description
    'sword': {
      'text': 'I want a sword <icon=sword></>',
      'description': '<grey>A sharp blade.</> 攻击 +5',
    },
  },
}
```

The method stamps `selectionsData['taskId']` and shows the list with `isAuto: false`. When the player presses an option, `SelectionDialog` calls:

```dart
void finishSelection(String taskId, String dataId, {dynamic value})
```

which stores `storedValues[dataId] = value` (the chosen **key** string), clears `selectionsData`, and completes the task so the script continues.

### Screen hint

```dart
void pushScreenHint({
  required Rect rect,       // highlighted area in logical pixels
  String? text,             // optional hint text drawn below the rect
  void Function()? onTap,   // called when the highlighted area is tapped
  MouseCursor? cursor,      // cursor inside the highlighted area
})
```

`isAuto: false` — the script pauses until the hint is dismissed (tap on the darkened area, or tap inside the highlight which also invokes `onTap`). Programmatic dismissal:

```dart
void finishScreenHint()  // clears screenHintInfo and completes the hint's task
```

### Backgrounds and illustrations

```dart
void pushBackground(String imageId, {bool isFadeIn = false})
void popBackground({String? imageId, isFadeOut = false})
void popAllBackgrounds()
void pushImage(String imageId, {double offsetX = 0.0, double offsetY = 0.0})
void popImage({String? imageId})
void popAllImages()
```

- `imageId` is relative to `assets/images/` — the model prepends that prefix itself.
- `pushBackground` records the previous scene for cross-fading; with `isFadeIn: true` the task is non-auto and is completed by the controller when the 800 ms fade animation finishes. `popBackground(isFadeOut: true)` fades the outgoing scene out the same way. Without fade flags these tasks complete immediately.
- Illustrations are drawn centered horizontally, `150` logical pixels from the top plus `offsetY` (constants `kIllustrationWidth = 600`, `kIllustrationHeight = 900`, `kBaseIllustrationOffsetY = 150` in `lib/game_dialog/game_dialog_controller.dart:10`).

### Arbitrary tasks and running the script

```dart
void pushTask(FutureOr<dynamic> Function() task, {String? flagId})
```

Schedules any function in the queue (auto-completes). Pushes made **inside** the function append after the already-queued tasks — this is how scripts are chained dynamically. If `flagId` is given, the task's return value is saved as `storedValues[flagId]`.

```dart
Future<void>? execute()
```

Appends a cleanup task (`id: 'execution_to_end'`) that clears all state (`isOpened`, scenes, illustrations, contents, selections, screen hint) and notifies listeners. The returned future completes when every task queued before it has completed — i.e. after the player has clicked through the whole script. Call `execute()` once after building a script.

### Reading the player's answer

Two ways, both backed by `storedValues`:

```dart
// 1. Direct lookup by the selection's 'id'
final choice = dialog.getValue('choice'); // e.g. 'sword', or null if never set

// 2. Branching helper — see checkSelected below
if (dialog.checkSelected({'choice': 'sword'}) == true) { ... }
```

```dart
dynamic checkSelected(dynamic data)
```

- `List` — `true` only if `storedValues[key]` is `true` for **every** key.
- `Map` / `HTStruct` — `true` only if every `storedValues[key] == value`.
- `String` — returns the raw stored value for that key.
- anything else — prints a debug warning and returns `null`.

## 4. The sequencing model

The queue lives in the `TaskController` mixin (`lib/task.dart:11`). Each push generates a unique task id via `randomUID(withTime: true)` and calls `schedule(task, id: ..., isAuto: ...)`:

- **`isAuto: true`** (default): the task completes as soon as its function returns. Used by `pushBackground` (without fade), `pushImage`/`popImage`/`popAll*`, and `pushTask`.
- **`isAuto: false`**: the task's completer is only finished by an explicit `finish*` call from the UI — `finishDialog` (player clicked through all lines), `finishSelection` (player picked an option), `finishScreenHint` (hint dismissed), or the controller's fade-animation listener for fade backgrounds. Used by `pushDialogRaw`, `pushSelectionRaw`, `pushScreenHint`, and fade background tasks.

Consequences:

1. Interactive steps serialize automatically: a selection pushed after a dialog cannot appear before the dialog is dismissed, because both are non-auto and the queue runs in order.
2. `pushTask` callbacks run **after** all previously queued steps, so they can inspect earlier results (e.g. `getValue('choice')`) and push follow-up steps. The demo uses exactly this pattern.
3. Pushing without calling `execute()` still runs the queue (the first task starts immediately), but no cleanup happens at the end — `isOpened` stays `true` and popped scenes/illustrations keep rendering. Always finish a script with `execute()`.
4. `execute()` itself is just another scheduled task, so it is safe to push more steps after calling it; they simply append after the cleanup.

## 5. UI components

### `GameDialogController`

`const GameDialogController({...})` — the overlay widget that turns model state into UI. Constructor parameters:

| Parameter | Type | Used for |
| --- | --- | --- |
| `cursor` | `MouseCursor?` | Cursor over the dialog box and selection list. |
| `screenHintCursor` | `MouseCursor?` | Fallback cursor for the screen-hint highlight. |
| `barrierColor` | `Color?` | If set, a `ModalBarrier` is drawn behind everything, blocking game input while a dialog is open. |
| `dialogTextStyle` | `TextStyle?` | Base text style of dialog lines. |
| `dialogDecoration` | `BoxDecoration?` | Decoration of the dialog box container. |
| `onAvatarPressed` | `void Function(dynamic)?` | Called with `data['characterId']` when the avatar is tapped. |
| `selectionButtonStyle` | `fluent.ButtonStyle?` | Style of selection buttons (Fluent UI). |
| `selectionTextStyle` | `TextStyle?` | Text style of selection labels. |

Rendering order inside its `Stack`: barrier → background scene (with 800 ms cross-fade support) → illustrations → dialog content → selection dialog → screen hint. When nothing is active it renders `SizedBox.shrink()`, so it is cheap to leave permanently in the tree.

### `GameDialogContent`

The typewriter dialog box. Usually created by the controller, but it can also be shown standalone:

```dart
static Future<void> show(
  BuildContext context,
  dynamic data, {
  MouseCursor? cursor,
  Color barrierColor = Colors.transparent,
  TextStyle? textStyle,
  BoxDecoration? decoration,
  void Function(dynamic)? onAvatarPressed,
})
```

`GameDialogContent.show` does **not** touch `GameDialog` state — it wraps the widget in a plain `showDialog` and pops via `Navigator` when finished. The data must not contain an `'id'` key (asserted), precisely so the widget takes the pop-instead-of-finish path.

Layout (`lib/game_dialog/game_dialog_content.dart:135`): an 880×190 box at the bottom of the screen (20 px margin) with a Fluent UI `Acrylic` blur layer, a 140×140 `Avatar` on the left, the speaker `name` above a `RichText` line. The line text is tokenized with `getRichTextStream` and revealed one token every 100 ms (rich-text tags render correctly because whole tag spans stay atomic). Tapping once completes the current line instantly; tapping again advances to the next line; after the last line the widget calls `GameDialog.finishDialog(id)` (or `Navigator.pop` in standalone mode).

### `SelectionDialog`

Centered column of `fluent.Button`s (300 wide), one per key in `data['selections']`. When an option's value is a map with a `'description'`, hovering the button shows that description through `HoverContentState` (`package:samsara/hover_info.dart`, direction `topCenter`) — see `hover_info.md`. Pressing a button hides the hover window and finishes the selection.

Standalone use is also possible:

```dart
static Future<String?> show(
  BuildContext context, {
  required dynamic selectionsData,
  MouseCursor? cursor,
  Color? barrierColor,
  fluent.ButtonStyle? buttonStyle,
  TextStyle? textStyle,
})
```

It returns the chosen key. In standalone mode the data must have **no** `'taskId'` (the widget then pops with the key instead of calling `finishSelection`).

### `ScreenHint`

`const ScreenHint({required ScreenHintInfo hintInfo, MouseCursor? cursor, Color? barrierColor, TextStyle? textStyle, Color? borderColor, double? borderRadius})`.

Built by the controller from `pushScreenHint` data; defaults: barrier `Colors.black` at 70% opacity, white border, 4 px corner radius, `SystemMouseCursors.click` inside the highlight. A private `_CutoutOverlayPainter` (`lib/game_dialog/screen_hint.dart:134`) fills the whole screen with the barrier color and punches the highlight rect out with `BlendMode.clear`. A 3 px white border pulses (opacity 0.3 → 1.0, 800 ms, repeating) around the cut-out. Tapping the dark area dismisses the hint; tapping inside it runs `onTap` and then dismisses; optional `text` renders centered 16 px below the highlight.

### `Avatar`

`const Avatar({...})` from `lib/game_dialog/avatar.dart` — a rounded-square icon (`RRectIcon` over `MouseRegion2` from `lib/widgets/ui/`) with an optional name label and tap/hover callbacks. Notable parameters:

| Parameter | Default | Meaning |
| --- | --- | --- |
| `image` / `imageId` / `placeholderId` | `null` | `ImageProvider`, or asset id relative to `assets/images/`. |
| `name` | `null` | Name text. |
| `nameAlignment` | `AvatarNameAlignment.inside` | `inside` overlays the name on the icon's bottom strip; `top` / `bottom` place it outside and grow the widget by 20 px. |
| `size` | `Size(100, 100)` | Icon size. |
| `radius` / `borderColor` / `borderWidth` | `10` / `white54` / `2.0` | Corner and border. |
| `showBorderImage` | `false` | Draws a decorative border image (`illustration/border.png`). |
| `onPressed(data)` / `onEnter(rect)` / `onExit` | `null` | Tap and hover callbacks; `data` is passed through from the `data` parameter. |
| `cursor` | `null` | A `WidgetStateMouseCursor`. |

Note: `Avatar` and `AvatarNameAlignment` are re-exported from `lib/game_dialog.dart`; they are also used internally by `GameDialogContent`.

## 6. Walkthrough: `example/lib/scene/dialog_scene.dart`

The demo scene registers itself as `'dialog'` (`example/lib/app.dart:91`) and contains three sprite buttons: *Back*, *Start Dialog*, and *Screen Hint*. Its `build` stacks `GameDialogController()` over `SceneWidget` (see §2).

*Start Dialog* runs `_runDialogScript()`, a three-act script with a nested task:

```dart
void _runDialogScript() {
  // 1. Dialog box with name, avatar and rich-text lines
  dialog.pushDialogRaw({
    'name': 'Pepe the Guide',
    'icon': 'pepe.png',
    'lines': [
      'Welcome to the <red>Samsara</> dialog demo!',
      'This typewriter dialog is rendered by GameDialogContent.',
      'Click once to skip the line, again to continue.',
    ],
  });

  // 2. Three-option selection; hovering shows hover_info descriptions
  dialog.pushSelectionRaw({
    'id': 'choice',
    'selections': {
      'sword': {
        'text': 'I want a sword <icon=sword></>',
        'description': '<grey>A sharp blade.</> 攻击 +5',
      },
      'spirit': {
        'text': 'I want spirit <icon=spirit></>',
        'description': '<blue>Mystic energy.</> 灵力 +3',
      },
      'nothing': 'No thanks',
    },
  });

  // 3. Runs after the selection completes: reads the answer, then
  //    pushes a closing dialog that echoes the chosen key
  dialog.pushTask(() {
    final choice = dialog.getValue('choice') ?? 'nothing';
    dialog.pushDialogRaw({
      'name': 'Pepe the Guide',
      'icon': 'pepe.png',
      'lines': [
        'You chose: <yellow>$choice</>.',
        'That is the end of the demo. Click to close!',
      ],
    });
  });

  dialog.execute(); // cleanup after everything finishes
}
```

Queue timeline: the first box blocks the queue until clicked through → the selection blocks until an option is pressed, storing `'choice'` → the `pushTask` callback reads `'choice'` and appends the closing box → `execute()`'s cleanup runs last.

*Screen Hint* highlights the *Start Dialog* button by converting its position into a `Rect` (button center ± half size):

```dart
hintButton.onTap = (button, position) {
  dialog.pushScreenHint(
    rect: Rect.fromLTWH(
      scriptButton.position.x - 60,
      scriptButton.position.y - 25,
      120,
      50,
    ),
    text: 'Click the highlighted button',
  );
  dialog.execute();
};
```

The overlay darkens everything except that rect, pulses a white frame around it, and shows the text below; tapping the button (inside the highlight) dismisses the hint and lets `execute()`'s cleanup run.

## 7. Caveats

- **`GameDialogController` must be in the widget tree**, below the `GameDialog` provider and above the game, or pushes only mutate invisible state.
- **`HoverContentState` provider is mandatory.** `SelectionDialog` calls `context.read<HoverContentState>()` unconditionally (hide on press, show/hide on hover), even when no option has a description. Without that provider above the controller you get a `ProviderNotFoundException` at runtime. The example provides it in `example/lib/main.dart:97`.
- **Asset ids are relative to `assets/images/`** for backgrounds, illustrations, avatars (`icon`), and `Avatar.imageId`/`placeholderId`. Do not repeat the prefix yourself.
- **Stale duplicate file**: `lib/game_dialog/game_dialog_state.dart` is an old copy of the model (same `SceneInfo`/`IllustrationInfo` definitions) and is **not** exported from the barrel. Ignore it; `GameDialog` lives in `lib/game_dialog/game_dialog.dart`.
- **Dialog `'image'` key**: the documented content format includes `'image'`, but the built-in `GameDialogContent` never reads it. To show a picture with a dialog, use `pushDialogRaw(content, imageId: '...')` or `pushImage`/`popImage` instead.
- **One selection / one hint at a time**: `selectionsData` and `screenHintInfo` are single slots; pushing again replaces the current one.
- **Never forget `execute()`** at the end of a script, or the final state (backgrounds, `isOpened`) is never cleaned up; conversely, remember that the cleanup also wipes illustrations you may still want.
- **Rich text and icons**: dialog lines and selection texts go through the samsara rich-text pipeline; embedded `<icon=...>` tags require the icons to be registered/preloaded as described in `../richtext/readme.md`.
