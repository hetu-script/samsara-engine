[English](../en/game_dialog.md) | **中文**

# Game Dialog —— 视觉小说式对话系统

公开 API 由桶文件 `lib/game_dialog.dart` 统一导出，该文件 re-export 了 `lib/game_dialog/` 下的五个源文件：

| 源文件 | 内容 |
| --- | --- |
| `lib/game_dialog/game_dialog.dart` | `GameDialog` 模型、`SceneInfo`、`IllustrationInfo`、`ScreenHintInfo` |
| `lib/game_dialog/game_dialog_controller.dart` | `GameDialogController` 覆盖层控件、立绘布局常量 |
| `lib/game_dialog/game_dialog_content.dart` | `GameDialogContent` 对话框控件 |
| `lib/game_dialog/selection_dialog.dart` | `SelectionDialog` 选项列表控件 |
| `lib/game_dialog/screen_hint.dart` | `ScreenHint` 教学高亮控件 |

## 1. 概述

对话系统采用**模型 / 控制器分离**架构：

- **`GameDialog`**（`lib/game_dialog/game_dialog.dart:56`）是模型。它以 mixin 方式组合了 `ChangeNotifier` 与 `TaskController`（见 `core.md` 的 TaskController 一节），持有全部脚本状态：背景场景、立绘、待显示的对话内容、选择数据、屏幕提示信息以及任意存储值。它本身**不包含任何 UI**。
- **`GameDialogController`**（`lib/game_dialog/game_dialog_controller.dart:15`）是 Flutter 控件。它通过 `context.watch<GameDialog>()` 监听模型，并按当前状态覆盖对应的控件：`GameDialogContent`（带头像与名字的打字机对话框）、`SelectionDialog`（选项列表）、`ScreenHint`（教学聚光），外加全屏背景图与居中立绘。

一段脚本就是**一串排入队列的任务**：每个 `push*` 调用向模型的队列追加一个任务。交互式任务（对话、选择、屏幕提示）以 `isAuto: false` 排入，会阻塞队列直到玩家操作；自动任务（背景切换、`pushTask` 的普通代码）自行完成。`execute()` 在队尾追加一个清理任务，并返回一个 `Future`——它在整段脚本（包括等待玩家输入）全部结束后完成。

所有面向玩家的字符串都支持 samsara 富文本标签语法（如 `'<red>…</>'`、`'<icon=sword></>'`），参见 `../richtext/readme.md`。

## 2. 接入

宿主应用创建**一个全局 `GameDialog` 实例**，并沿控件树提供。见 `example/lib/engine.dart:15`：

```dart
import 'package:samsara/game_dialog.dart';

final dialog = GameDialog();
```

在 `main()` 中提供它（同时提供 `SelectionDialog` 所必需的 `HoverContentState`，见「注意事项」），见 `example/lib/main.dart:92`：

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

在每个场景的 `build()` 的 `Stack` 中、`SceneWidget` **之上**放置一个 `GameDialogController`，见 `example/lib/scene/dialog_scene.dart:130`：

```dart
@override
Widget build(BuildContext context, {...}) {
  return Scaffold(
    body: Stack(
      children: [
        SceneWidget(scene: this),
        GameDialogController(), // 在游戏画面之上渲染对话 UI
      ],
    ),
  );
}
```

主菜单同样如此（`example/lib/scene/mainmenu.dart:195`）。任何可能弹出对话的场景都需要自己的 `GameDialogController`；缺少它时模型状态仍会变化，但不会有任何渲染。

## 3. `GameDialog` API 参考

导入：`package:samsara/game_dialog.dart`。由于它是 `ChangeNotifier`，控制器会在任何 push/finish 方法调用 `notifyListeners()` 时自动重建。

### 模型状态字段

| 字段 | 类型 | 含义 |
| --- | --- | --- |
| `isOpened` | `bool` | 每个 push 方法都会将其置为 `true`；由 `execute()` 的清理逻辑重置。 |
| `scenes` | `Set<SceneInfo>` | 背景图栈。`currentSceneInfo` 返回最后一个。 |
| `prevScene` | `SceneInfo?` | 正在淡出 / 被替换的场景，用于交叉淡入淡出渲染。 |
| `illustrations` | `Set<IllustrationInfo>` | 叠加在背景之上的居中立绘。 |
| `contents` | `Map<String, dynamic>` | 待显示的对话框，以任务 id 为键。`currentContent` 返回最后一个值。 |
| `selectionsData` | `dynamic` | 当前选择数据（含自动写入的 `'taskId'`），无则为 `null`。 |
| `screenHintInfo` | `ScreenHintInfo?` | 当前屏幕提示，无则为 `null`。同时最多存在一个。 |
| `storedValues` | `Map<String, dynamic>` | 脚本定义的数值袋（选择结果、`flagId` 任务结果等）。 |

数值存储：`loadValues(Map<String, dynamic> values)` 整体替换；`dynamic getValue(String key)` 读取单个条目。

### 对话内容

```dart
void pushDialogRaw(dynamic content, {String? imageId})
```

推送一个对话框。`content` 可以是：

- `String` —— 视为单行文本；
- `List<String>` —— 视为 `lines` 列表；
- 带有以下键的 `Map` / `HTStruct`（其他类型会触发 assert 抛出异常）。

文档约定的数据格式（`lib/game_dialog/game_dialog.dart:250`）：

```dart
{
  'name': 'Pepe the Guide', // 显示在文本上方的说话人名字
  'icon': 'pepe.png',       // 头像图片，相对于 assets/images/
  'image': '...',           // 文档中列出，但内置 UI 并不读取
  'lines': ['line 1', 'line 2'], // 每个元素是一行打字机文本
}
```

该方法会自动写入 `resolved['id'] = taskId`；`GameDialogContent` 还会读取可选的 `'characterId'`（点按头像时传给 `onAvatarPressed`）。任务以 `isAuto: false` 排入——玩家逐行点完、控件调用 `finishDialog(id)` 之前，脚本会一直暂停。如果传了 `imageId`，会在该对话之前推入对应立绘、之后立即弹出，因此图片只在这一个对话框显示期间出现。

```dart
void finishDialog(String id)  // 移除该对话内容并完成任务
void finishTask(String id)    // 按 id 完成任意未完成任务（不存在则为无操作）
```

### 选择

```dart
void pushSelectionRaw(dynamic selectionsData)
```

`selectionsData` 必须是 `Map` / `HTStruct`（assert），格式如下（`lib/game_dialog/game_dialog.dart:316`）：

```dart
{
  // 玩家答案将以该键存入 storedValues
  'id': 'choice',
  'selections': {
    // 可以是纯文本……
    'nothing': 'No thanks',
    // ……也可以是文本加悬停描述
    'sword': {
      'text': 'I want a sword <icon=sword></>',
      'description': '<grey>A sharp blade.</> 攻击 +5',
    },
  },
}
```

该方法会把 `selectionsData['taskId']` 写入数据并显示列表（`isAuto: false`）。玩家按下某个选项时，`SelectionDialog` 会调用：

```dart
void finishSelection(String taskId, String dataId, {dynamic value})
```

它把 `storedValues[dataId] = value`（所选选项的 **key** 字符串）、清空 `selectionsData` 并完成任务，脚本由此继续。

### 屏幕提示

```dart
void pushScreenHint({
  required Rect rect,       // 高亮区域（逻辑像素）
  String? text,             // 可选，显示在高亮区域下方的提示文字
  void Function()? onTap,   // 点按高亮区域时触发
  MouseCursor? cursor,      // 高亮区域内的鼠标光标
})
```

`isAuto: false` —— 直到提示被解除（点按变暗区域，或点按高亮区——后者还会触发 `onTap`）脚本才会继续。编程方式解除：

```dart
void finishScreenHint()  // 清空 screenHintInfo 并完成提示的任务
```

### 背景与立绘

```dart
void pushBackground(String imageId, {bool isFadeIn = false})
void popBackground({String? imageId, isFadeOut = false})
void popAllBackgrounds()
void pushImage(String imageId, {double offsetX = 0.0, double offsetY = 0.0})
void popImage({String? imageId})
void popAllImages()
```

- `imageId` 相对于 `assets/images/` —— 模型会自动补上该前缀。
- `pushBackground` 会记录上一个场景用于交叉淡化；`isFadeIn: true` 时任务为非自动，由控制器在 800 ms 淡入动画结束后完成任务。`popBackground(isFadeOut: true)` 以同样方式淡出被弹出的场景。不带淡入淡出标记时任务立即完成。
- 立绘水平居中绘制，顶部位置为 `150` 逻辑像素加 `offsetY`（常量 `kIllustrationWidth = 600`、`kIllustrationHeight = 900`、`kBaseIllustrationOffsetY = 150`，见 `lib/game_dialog/game_dialog_controller.dart:10`）。

### 任意任务与运行脚本

```dart
void pushTask(FutureOr<dynamic> Function() task, {String? flagId})
```

把任意函数排入队列（自动完成）。在函数体内进行的 push 会追加到**已排队任务之后**——动态拼接脚本正是靠这一机制。若传入 `flagId`，任务的返回值会保存为 `storedValues[flagId]`。

```dart
Future<void>? execute()
```

追加一个清理任务（`id: 'execution_to_end'`），清空全部状态（`isOpened`、场景、立绘、对话内容、选择、屏幕提示）并通知监听者。返回的 future 在排在前面的所有任务都完成后才完成——也就是玩家点完整段脚本之后。编排好一段脚本后调用一次 `execute()`。

### 读取玩家的选择结果

两种方式，底层都是 `storedValues`：

```dart
// 1. 按选择的 'id' 直接取值
final choice = dialog.getValue('choice'); // 例如 'sword'，未选择过则为 null

// 2. 分支判断辅助函数 —— 见下面的 checkSelected
if (dialog.checkSelected({'choice': 'sword'}) == true) { ... }
```

```dart
dynamic checkSelected(dynamic data)
```

- `List` —— 仅当**每个**键的 `storedValues[key]` 都为 `true` 时返回 `true`。
- `Map` / `HTStruct` —— 仅当每个 `storedValues[key] == value` 时返回 `true`。
- `String` —— 返回该键对应的原始存储值。
- 其他类型 —— 打印 debug 警告并返回 `null`。

## 4. 任务队列模型

队列由 `TaskController` mixin（`lib/task.dart:11`）维护。每次 push 通过 `randomUID(withTime: true)` 生成唯一任务 id，并调用 `schedule(task, id: ..., isAuto: ...)`：

- **`isAuto: true`**（默认）：任务函数返回后即自动完成。`pushBackground`（无淡入）、`pushImage`/`popImage`/`popAll*`、`pushTask` 属于此类。
- **`isAuto: false`**：任务的 completer 只能由 UI 显式调用 `finish*` 完成——`finishDialog`（玩家点完所有行）、`finishSelection`（玩家选定选项）、`finishScreenHint`（提示解除），或控制器中淡入淡出动画的监听（针对带淡入淡出的背景任务）。`pushDialogRaw`、`pushSelectionRaw`、`pushScreenHint` 属于此类。

由此得出几条推论：

1. 交互步骤自动串行：排在对话之后的选择不会提前出现，因为二者都是非自动任务，队列按顺序执行。
2. `pushTask` 回调在**之前排队的所有步骤之后**运行，因此可以读取先前步骤的结果（如 `getValue('choice')`）并追加后续步骤。示例正是这么做的。
3. 不调用 `execute()` 队列也会运行（第一个任务立即开始），但结尾不会有清理——`isOpened` 保持 `true`，弹出的场景/立绘会继续渲染。脚本务必以 `execute()` 收尾。
4. `execute()` 本身也只是一个排队任务，因此在调用它之后再 push 新步骤是安全的，这些步骤会追加在清理任务之后。

## 5. UI 组件

### `GameDialogController`

`const GameDialogController({...})` —— 把模型状态渲染为 UI 的覆盖层控件。构造参数：

| 参数 | 类型 | 用途 |
| --- | --- | --- |
| `cursor` | `MouseCursor?` | 对话框与选择列表上的光标。 |
| `screenHintCursor` | `MouseCursor?` | 屏幕提示高亮区的兜底光标。 |
| `barrierColor` | `Color?` | 若设置，会在所有内容背后绘制 `ModalBarrier`，对话打开时阻断游戏输入。 |
| `dialogTextStyle` | `TextStyle?` | 对话文本的基础样式。 |
| `dialogDecoration` | `BoxDecoration?` | 对话框容器的装饰。 |
| `onAvatarPressed` | `void Function(dynamic)?` | 点按头像时以 `data['characterId']` 调用。 |
| `selectionButtonStyle` | `fluent.ButtonStyle?` | 选项按钮样式（Fluent UI）。 |
| `selectionTextStyle` | `TextStyle?` | 选项文字样式。 |

其 `Stack` 内的渲染顺序：屏障 → 背景场景（支持 800 ms 交叉淡化）→ 立绘 → 对话内容 → 选择对话框 → 屏幕提示。没有任何内容时渲染 `SizedBox.shrink()`，因此可以长期留在控件树中，开销极小。

### `GameDialogContent`

打字机对话框。通常由控制器创建，但也可以独立弹出：

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

`GameDialogContent.show` **不会**改动 `GameDialog` 状态——它把控件包进普通的 `showDialog`，结束时通过 `Navigator` 弹出。数据不能包含 `'id'` 键（有 assert），这样控件才会走「直接 pop 而非 finish」的分支。

布局（`lib/game_dialog/game_dialog_content.dart:135`）：屏幕底部一个 880×190 的框（下边距 20 px），内衬 Fluent UI 的 `Acrylic` 模糊层；左侧为 140×140 的 `Avatar`，说话人 `name` 在上、`RichText` 行文本在下。行文本用 `getRichTextStream` 切分为 token，每 100 ms 显示一个（富文本标签作为整体原子渲染，因此着色与图标都正确）。点按一次立即补全当前行；再次点按进入下一行；最后一行结束后控件调用 `GameDialog.finishDialog(id)`（独立模式下则 `Navigator.pop`）。

### `SelectionDialog`

一列居中、`fluent.Button`（宽 300）样式的按钮，每个键对应 `data['selections']` 中的一项。当选项的值是含 `'description'` 的 map 时，悬停按钮会通过 `HoverContentState`（`package:samsara/hover_info.dart`，方向 `topCenter`）显示该描述——见 `hover_info.md`。按下按钮会先隐藏悬停窗口，再完成选择。

也可以独立使用：

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

返回所选键。独立模式下数据必须**不含** `'taskId'`（此时控件以返回值 pop，而不是调用 `finishSelection`）。

### `ScreenHint`

`const ScreenHint({required ScreenHintInfo hintInfo, MouseCursor? cursor, Color? barrierColor, TextStyle? textStyle, Color? borderColor, double? borderRadius})`。

由控制器根据 `pushScreenHint` 的数据构建；默认值：屏障色为 70% 不透明度的 `Colors.black`，白色边框，圆角 4 px，高亮区内光标为 `SystemMouseCursors.click`。私有类 `_CutoutOverlayPainter`（`lib/game_dialog/screen_hint.dart:134`）先用屏障色铺满全屏，再用 `BlendMode.clear` 挖出高亮矩形。高亮区外框有一圈 3 px 的白色脉冲边框（不透明度 0.3 → 1.0，800 ms 往复）。点按变暗区域解除提示；点按高亮区先执行 `onTap` 再解除；传入 `text` 时以 16 px 字号居中显示在高亮区下方。

### `Avatar`

`lib/game_dialog/avatar.dart` 中的 `const Avatar({...})` —— 基于 `lib/widgets/ui/` 的 `RRectIcon` 与 `MouseRegion2` 实现的圆角方形头像，带可选名字标签与点按/悬停回调。主要参数：

| 参数 | 默认值 | 含义 |
| --- | --- | --- |
| `image` / `imageId` / `placeholderId` | `null` | `ImageProvider`，或相对于 `assets/images/` 的资源 id。 |
| `name` | `null` | 名字文本。 |
| `nameAlignment` | `AvatarNameAlignment.inside` | `inside` 把名字叠加在图标底部的色条上；`top` / `bottom` 放在图标外侧，控件高度增加 20 px。 |
| `size` | `Size(100, 100)` | 图标尺寸。 |
| `radius` / `borderColor` / `borderWidth` | `10` / `white54` / `2.0` | 圆角与边框。 |
| `showBorderImage` | `false` | 绘制装饰性边框图（`illustration/border.png`）。 |
| `onPressed(data)` / `onEnter(rect)` / `onExit` | `null` | 点按与悬停回调；`data` 原样来自 `data` 参数。 |
| `cursor` | `null` | `WidgetStateMouseCursor`。 |

注意：`Avatar` 与 `AvatarNameAlignment` 已随 `lib/game_dialog.dart` 桶文件导出，同时也是 `GameDialogContent` 的内部构件。

## 6. 实例解析：`example/lib/scene/dialog_scene.dart`

示例场景以 `'dialog'` 注册（`example/lib/app.dart:91`），包含三个精灵按钮：*Back*、*Start Dialog* 和 *Screen Hint*。其 `build` 把 `GameDialogController()` 叠在 `SceneWidget` 之上（见 §2）。

*Start Dialog* 触发 `_runDialogScript()`——一段三幕、内含嵌套任务的脚本：

```dart
void _runDialogScript() {
  // 1. 带名字、头像与富文本行内容的对话框
  dialog.pushDialogRaw({
    'name': 'Pepe the Guide',
    'icon': 'pepe.png',
    'lines': [
      'Welcome to the <red>Samsara</> dialog demo!',
      'This typewriter dialog is rendered by GameDialogContent.',
      'Click once to skip the line, again to continue.',
    ],
  });

  // 2. 三选一；悬停选项可通过 hover_info 显示描述
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

  // 3. 在选择完成后运行：读取答案，再推入一个回显所选键的收尾对话
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

  dialog.execute(); // 全部结束后清理
}
```

队列时间线：第一个框阻塞队列直到被点完 → 选择阻塞队列直到按下选项，并写入 `'choice'` → `pushTask` 回调读取 `'choice'` 并追加收尾框 → `execute()` 的清理最后运行。

*Screen Hint* 通过把按钮坐标换算成 `Rect`（按钮中心 ± 半宽/半高）来高亮 *Start Dialog* 按钮：

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

覆盖层会压暗高亮矩形之外的整个屏幕，在其周围脉冲显示白色线框，并在下方显示提示文字；点按按钮（高亮区内）即解除提示，让 `execute()` 的清理得以执行。

## 7. 注意事项

- **`GameDialogController` 必须在控件树中**，位于 `GameDialog` provider 之下、游戏画面之上，否则 push 只会改动不可见的状态。
- **`HoverContentState` provider 必不可少。** `SelectionDialog` 会无条件调用 `context.read<HoverContentState>()`（按下时隐藏，悬停时显示/隐藏），即使没有任何选项带描述也是如此。若控制器上方没有该 provider，运行时会抛出 `ProviderNotFoundException`。示例在 `example/lib/main.dart:97` 提供了它。
- **资源 id 相对于 `assets/images/`**：背景、立绘、头像（`icon`）以及 `Avatar.imageId`/`placeholderId` 都是如此，不要自己重复加前缀。
- **过期重复文件**：`lib/game_dialog/game_dialog_state.dart` 是模型的旧拷贝（含有相同的 `SceneInfo`/`IllustrationInfo` 定义），且**未**被桶文件导出。请忽略它；`GameDialog` 位于 `lib/game_dialog/game_dialog.dart`。
- **对话的 `'image'` 键**：文档列出的内容格式里虽然有 `'image'`，但内置的 `GameDialogContent` 并不读取它。若要在对话期间显示图片，请改用 `pushDialogRaw(content, imageId: '...')` 或 `pushImage`/`popImage`。
- **选择与提示同时只有一个**：`selectionsData` 和 `screenHintInfo` 都是单槽位；重复 push 会替换当前内容。
- **别忘了 `execute()`**：脚本结尾不调用它，最终状态（背景、`isOpened`）永远不会被清理；反过来也要记住清理会把立绘一并抹掉，若还需要保留就不要让 `execute()` 过早运行。
- **富文本与图标**：对话行与选项文本都经过 samsara 富文本管线；内嵌 `<icon=...>` 标签需要按 `../richtext/readme.md` 所述注册并预载图标。
