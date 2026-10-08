[English](../en/hover_info.md) | **中文**

# 悬浮提示（Hover Tooltip）

Samsara 内置**两套相互独立的悬浮提示系统**。它们的思路相同——鼠标悬停时弹出信息框——但工作层级不同，不能混用：

| | A. `hover_info` | B. `Hovertip` |
| --- | --- | --- |
| 层级 | Flutter 控件层 | Flame 组件层 |
| 导入 | `package:samsara/hover_info.dart` | `package:samsara/components.dart` |
| 锚点 | 屏幕坐标 `Rect`（来自 Flutter 控件） | `GameComponent` 或屏幕位置 |
| 渲染方式 | 控件树中的 `HoverInfo` widget | 添加到 `scene.camera.viewport` 的组件（HUD） |
| 适用场景 | Flutter 浮层：菜单、对话框、游戏画面旁的标签 | 游戏世界内的对象：精灵、地块、场景内按钮 |

简单判断：触发者是 **Flutter 控件**就用 `hover_info`；触发者是**游戏组件**就用 `Hovertip`。可运行示例 `example/lib/scene/hover_scene.dart` 并排演示了两套系统。

---

## A. `hover_info` —— Flutter 控件层

源码：`lib/hover_info/hover_content.dart`、`lib/hover_info/hover_info.dart`，桶文件 `lib/hover_info.dart`。

### 初始化：提供 `HoverContentState`

`HoverContentState`（lib/hover_info/hover_content.dart:38）是控制显示/隐藏的状态类，继承自 `ChangeNotifier`。库本身**不会替你创建 provider**——宿主应用必须在所有用到它的控件之上注册一个。示例应用在 `example/lib/main.dart:97` 中这样做：

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => HoverContentState()),
    // ……其他 provider
  ],
  child: MyApp(),
)
```

缺少这个 provider 时，`context.read<HoverContentState>()` 会直接抛异常。

### `HoverContentState` API

```dart
class HoverContentState extends ChangeNotifier {
  bool isDetailed = false;
  HoverContent? content;
  String? currentId;

  void setCurrentId(String? id);

  void show({
    required Rect rect,                            // 被悬停控件的屏幕坐标矩形
    dynamic data,                                  // String（富文本）或 Widget
    double maxWidth = kHoverInfoMaxWidth,          // 360
    HoverContentDirection direction = HoverContentDirection.bottomCenter,
    TextAlign textAlign = TextAlign.center,
    dynamic Function(bool isDetailed)? contentBuilder,
  });

  void setDetailed(bool detailed);
  void hide();
}
```

- `show` 断言 `data != null || contentBuilder != null`。只传 `contentBuilder` 时，初始内容为 `contentBuilder!(isDetailed)`；同时会把该 builder 保存下来供后续 `setDetailed` 使用。
- `setDetailed` 在开关未变化时直接返回；否则翻转 `isDetailed` 并通过保存的 `contentBuilder` **重新生成**内容，同时保留 `rect`、`maxWidth`、`direction`、`textAlign`，然后通知监听者。
- `hide` 清空保存的 builder 和 `content`（仅在当前有内容时），并通知监听者。
- `setCurrentId` 只在状态上记录一个 id（供应用自行追踪提示框属于哪个实体），库本身不解释它。
- `kHoverInfoMaxWidth` 为 `360.0`（lib/hover_info/hover_content.dart:5）。

### `HoverContent` 与 `HoverContentDirection`

`HoverContent`（lib/hover_info/hover_content.dart:22）是 `show` 生成的不可变数据载体：`rect`、`data`、`maxWidth`、`direction`、`textAlign`。

`HoverContentDirection` 共 12 个取值——第一个词表示提示框位于矩形的哪一侧，第二个词表示沿该侧的锚点对齐方式：

```
topLeft, topCenter, topRight,
leftTop, leftCenter, leftBottom,
rightTop, rightCenter, rightBottom,
bottomLeft, bottomCenter, bottomRight
```

### `HoverInfo` 控件 —— 以及"过期数据"陷阱

```dart
const HoverInfo(
  this.content, {
  super.key,
  this.backgroundColor = Colors.black87,
});
```

`HoverInfo`（lib/hover_info/hover_info.dart:89）是浮动信息框本身。源码验证过的行为：

- 它的**可见性由 provider 状态决定**——`context.read<HoverContentState>().content == null` 时渲染 `SizedBox.shrink()`——但**渲染的却是构造参数 `content`**。必须把状态里的*当前* content 喂给它，否则会显示过期数据。
- 正确接法：在状态变化时重建并传入最新的 content，例如像 `example/lib/scene/hover_scene.dart:153` 那样用 `Consumer<HoverContentState>`：

```dart
Consumer<HoverContentState>(
  builder: (context, hoverState, _) {
    final content = hoverState.content;
    if (content == null) return const SizedBox.shrink();
    return HoverInfo(content);
  },
),
```

- 定位：由 `SingleChildLayoutDelegate` 按 `direction` 把信息框放到 `content.rect` 旁边，间隔 `kHoverInfoIndent`（10），并被夹紧在屏幕范围内（lib/hover_info/hover_info.dart:69）。
- 信息框包裹在 `IgnorePointer` 中——永远不会拦截输入。
- 内边距固定为 `EdgeInsets.symmetric(horizontal: 20, vertical: 10)`；宽度受 `content.maxWidth` 约束。

### 富文本内容

若 `data` 是 `String`，会通过 `buildFlutterRichText` 渲染成富文本（lib/hover_info/hover_info.dart:118），因此 `<red>…</>`、`<icon=sword></>` 等标记都能用——见 `richtext.md`。若 `data` 是 `Widget`，则原样插入。其他类型渲染为空框。

### 从控件触发

`Label`（lib/widgets/ui/label.dart:6）能提供所需的屏幕坐标 `Rect`：它的 `onMouseEnter: void Function(Rect rect)?` 回调会通过 `MouseRegion2` 用 `RenderBox.localToGlobal` 算出控件的全局边界（lib/widgets/ui/mouse_region2.dart:34）。`Label` 自身的文本同样是富文本渲染。

```dart
Label(
  '<bold>悬停我</>',
  width: 300,
  onMouseEnter: (rect) {
    context.read<HoverContentState>().show(
          rect: rect,
          data: '<red>富文本</> Flutter 层提示文字',
          direction: HoverContentDirection.topCenter,
        );
  },
  onMouseExit: () => context.read<HoverContentState>().hide(),
),
```

库内部也用了同样的模式：`lib/game_dialog/selection_dialog.dart:127` 在悬停选项时把其 `description` 显示到按钮上方，移出时隐藏（选中时也会再隐藏一次，见第 115 行）。

### 简略 / 详细内容切换

调用 `show` 时传入 `contentBuilder`，再用 `setDetailed` 切换。builder 会收到当前 `isDetailed` 标志，因此同一代码点可以同时服务两种详略程度：

```dart
context.read<HoverContentState>().show(
  rect: rect,
  direction: HoverContentDirection.topCenter,
  contentBuilder: (isDetailed) => isDetailed
      ? '<bold>很长的描述</>，含<blue>详情</>'
      : '<bold>简短描述</>',
);

// 在别处，例如"详情"按钮中：
context.read<HoverContentState>().setDetailed(true);
```

`HoverInfo` 内部监听了 `isDetailed`，所以打开着的提示框会用重新生成的内容自动重建。

---

## B. `Hovertip` —— Flame 组件层

源码：`lib/components/ui/hovertip.dart`，由 `package:samsara/components.dart` 导出。`Hovertip` 继承自 `BorderComponent`，全部通过静态方法管理；实例是被缓存的单例，添加到 `scene.camera.viewport` 中，因此以 HUD 形式绘制在游戏世界之上。

### 方向枚举

`HovertipDirection` 共 13 个取值——12 个方向值之外还有 `none`，表示把提示框中心放到目标中心：

```
none,
topLeft, topCenter, topRight,
leftTop, leftCenter, leftBottom,
rightTop, rightCenter, rightBottom,
bottomLeft, bottomCenter, bottomRight
```

### 静态 API

```dart
class Hovertip extends BorderComponent {
  static ScreenTextConfig defaultContentConfig;
  static Paint backgroundPaint;                 // 黑色，alpha 200

  static void show({
    required Scene scene,
    GameComponent? target,                     // 锚定组件（世界或 HUD）
    String? content,                           // 富文本字符串
    ScreenTextConfig? config,
    HovertipDirection? direction,              // 有 target 时默认为 bottomCenter
    double width = kHovertipDefaultWidth,      // 360
    Vector2? position,                         // 无 target 时的屏幕位置
    EdgeInsets? margin,                        // 无 target 时的屏幕边缘留白
  });

  static void hide([GameComponent? target]);   // 隐藏全局或某个 target 的提示框
  static void hideAll();
  static void toggle(GameComponent target, {required Scene scene, bool justShow = false});
  static bool hasTip(GameComponent target);
}
```

常量：`kHovertipScreenIndent = 10.0`、`kHovertipContentIndent = 10.0`、`kHovertipBackgroundBorderRadius = 5.0`、`kHovertipDefaultWidth = 360.0`。

源码验证过的语义：

- `show` 断言 `target != null || position != null`。它会先调用 `hideAll()`，因此同一时间只有一个提示框可见。
- 提示框实例按转义后的内容字符串缓存；并按 target 注册（仅给 `position` 时则作为唯一的全局实例）。
- 传入 `target` 时，锚点是 `target.absoluteTopLeftPosition`，除非 target `isHud`，否则经 `scene.camera.localToGlobal` 转换（尺寸乘以 `camera.zoom`）。最终位置会被夹紧在相机视口内。
- 只给 `position` 时直接使用该屏幕坐标；只给 `margin` 时提示框钉在对应屏幕边缘，`direction` 决定另一轴的对齐（例如 `margin.left` 配 `leftCenter` 表示左边缘垂直居中）。
- 内容经 trim 后用 `buildFlameRichText` 渲染，因此 `richtext.md` 中的同一套富文本标记在这里同样可用。样式通过静态的 `defaultContentConfig` / 每次调用的 `config` 以及静态的 `backgroundPaint` 调整。
- 实例成员：`setContent(String content, {ScreenTextConfig? config, required double width})` 和 `content` getter。`toggle` 挂载/卸载某个 target 的提示框，`hasTip` 查询某个 target 是否已有提示框。

### 从游戏组件触发

给 `GameComponent` 加上手势处理（见 `gestures.md` 与 `core.md`），然后赋值鼠标回调——`example/lib/scene/hover_scene.dart:50` 正是这样做的：

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

## 可运行示例

`example/lib/scene/hover_scene.dart` 并排演示了两套系统：三个精灵在悬停时显示各自的 `Hovertip`（Flame 层），游戏画面下方的两个 `Label` 则通过 `HoverContentState` 驱动 `HoverInfo`（Flutter 层）——其中包括了避免过期数据陷阱的 `Consumer` 接法。
