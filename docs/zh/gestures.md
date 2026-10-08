[English](../en/gestures.md) | **中文**

# 手势系统

Samsara 的手势系统是**完全自定义的——不使用 Flame 的任何手势 mixin**（`TapCallbacks`、`DragCallbacks` 等）。原始 Flutter 指针事件由 widget 捕获，识别为高级手势，由 `Scene` 在引擎内统一分发，最后由各组件上的 mixin 解析。下文所有签名均已对照源码核实；行为上的怪癖与已知 bug 均如实说明。

公开 API 通过两个桶文件导出：

- `package:samsara/gestures.dart` —— `HandlesGesture`、`TappingDetails`、`PointerDetector`、detail 类（`TouchDetails`、`PointerMoveDetails`、`PointerMoveUpdateDetails`、`MouseScrollDetails`）、Flutter 手势 detail 类（`TapDownDetails`、`TapUpDetails`、`DragStartDetails`、`DragUpdateDetails`、`ScaleStartDetails`、`ScaleUpdateDetails`、`LongPressStartDetails`）、`PointerHoverEvent`，以及鼠标按键常量 `kPrimaryButton` / `kSecondaryButton` / `kTertiaryButton` / `kBackMouseButton` / `kForwardMouseButton`（re-export 自 `package:flutter/gestures.dart`）。
- `package:samsara/components.dart` —— `GestureComponent`，以及自带手势能力的组件如 `SpriteComponent2`、`SpriteButton`。

## 四层管线

```
 原始指针事件（Flutter Listener + MouseRegion）
        |
        v
+-----------------------------+
| 1. PointerDetector           |  StatefulWidget（lib/widgets/pointer_detector.dart:128）。
|    （Flutter widget 层）     |  识别 tap / drag / scale / long-press /
|                              |  hover / scroll；自愈陈旧指针记录；
|                              |  在窗口边缘强制结束拖动。
+--------------+---------------+
               | onTapDown / onDragUpdate / onScaleStart / ...（全局屏幕坐标）
               v
+-----------------------------+
| 2. Scene.onXxx               |  Scene 分发（lib/scene/scene.dart）。以
|    （场景分发层）            |  gestureComponents 深度优先遍历，维护
|                              |  hoveringComponent 与 draggingComponent，
|                              |  持有 resetStaleGestures()。
+--------------+---------------+
               | handleTapDown / handleDragUpdate / ...（同名 handle* 方法）
               v
+-----------------------------+
| 3. HandlesGesture.handle*    |  GameComponent 上的 mixin
|    （组件层）                |  （lib/gestures/gesture_mixin.dart:37）。子组件优先
|                              |  委派，containsPoint 命中测试，屏幕->世界坐标
|                              |  转换，然后触发 onXxx 回调字段。
+--------------+---------------+
               | onTap / onDragUpdate / onMouseEnter / ...
               v
          你的回调函数
```

`SceneWidget`（lib/scene/scene_widget.dart:25）自动完成第 1→2 层的接线：它把 Flame 的 `GameWidget` 包在 `PointerDetector` 里，把每个 widget 回调接到 `Scene` 的同名方法上，并设置 `onStaleGestureReset: scene.resetStaleGestures` 与 `endDragAtWindowEdge: true`。任何用 `scene.build(...)` 构建的场景都自带这条管线。

为什么不用 Flame 的 mixin，而要自定义管线：

- **鼠标与触摸统一处理。** 点击、双击、长按、拖动（任意鼠标键）、双指缩放、鼠标悬停、滚轮滚动，全部由同一个 widget 同时识别，并流经同一条分发路径。
- **跨组件拖放语义。** `onDragOver` / `onDragIn` 让某个组件在*另一个*组件被拖动时充当放置目标——这是按组件的 gesture mixin 无法表达的。
- **桌面端窗口边界问题。** `endDragAtWindowEdge` 规避 Windows `SetCapture` 冻结；`resetStaleGestures` 自愈会阻断一切输入的陈旧指针记录（详见[场景级分发](#场景级分发与坐标转换)）。

## 快速上手：可交互组件

继承 `GestureComponent`（lib/components/gesture_component.dart:4 —— 混入了 `HandlesGesture` 的 `GameComponent`），或在你自己的 `GameComponent` 子类上加 `with HandlesGesture`，然后赋值回调字段：

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

// 在 Scene 中：
world.add(MyButton(position: center));
```

每个 `handle*` 方法开头有两个开关，决定组件能否收到手势：

- `enableGesture` —— `HandlesGesture` 上默认为 `true`，**但 `SpriteComponent2` 把默认值改成了 `false`**，需要通过构造参数 `enableGesture:` 显式开启（lib/components/sprite_component2.dart:87）。
- `isVisible` —— 显式隐藏时为 false；非 HUD 组件在镜头外时（`scene.camera.canSee(this)`，lib/components/game_component.dart:29）同样为 false。不可见的组件收不到任何手势。

如果你在子类中重写了任何 `handle*` 方法，注意它是 `@mustCallSuper`——**必须**调用 `super`，否则子组件的分发会断掉。重写 `Scene` 层的 `onTapDown` / `onDragUpdate` / ... 分发方法时同理（正确的重写示例见 `example/lib/scene/mainmenu.dart:89`）。

## `HandlesGesture` 参考

定义于 lib/gestures/gesture_mixin.dart:37：`mixin HandlesGesture on GameComponent`。

### 状态字段

| 字段 | 类型 | 含义 |
| --- | --- | --- |
| `enableGesture` | `bool` | 该组件的手势总开关（见上文） |
| `isPressing` | `bool` | 有指针正按在该组件上 |
| `isDragging` | `bool` | 该组件正被拖动（内部记录拖动起点） |
| `isScaling` | `bool` | 该组件正被双指缩放 |
| `isHovering` | `bool` | 鼠标光标位于该组件上（由 `Scene` 维护） |
| `doubleTapTimer` | `Timer?` | 内部双击窗口计时器 |

静态（引擎级）成员：

- `static int doubleTapTimeConsider = 400` —— 双击判定窗口（毫秒），所有组件共享。
- `static Map<int, TappingDetails> tappingDetails` —— 所有活动指针的注册表（`pointer` → `TappingDetails{pointer, button, globalPosition, component}`），记录每个 tap-down 被哪个组件捕获。`Scene` 用它做拖动记账和陈旧手势自愈；`handleScaleEnd` 只移除参与本次缩放的指针条目（缩放手势重置检测器状态后，这些指针的 tap-up 永远不会到来）。

### 回调字段

除特别注明外，所有 `position` 均为**组件本地坐标**。`button` 是触发事件的 Flutter 按键常量（见[鼠标按键](#鼠标按键)）。

| 字段 | 签名 | 触发时机 |
| --- | --- | --- |
| `onTapDown` | `void Function(int button, Vector2 position)?` | 指针在组件内按下。会把指针注册进 `tappingDetails`。 |
| `onTapUp` | `void Function(int button, Vector2 position)?` | 指针在组件内松开（在 `onTap` 之后）。 |
| `onTap` | `void Function(int button, Vector2 position)?` | 组件内完成一次点击。双击的第二下也会触发；拖动结束点距起点 10 px 以内且仍悬停时会被**合成触发**。 |
| `onDoubleTap` | `void Function(int button, Vector2 position)?` | 第二下点击落在首个点击的 `doubleTapTimeConsider`（400 ms）窗口内。第二下的触发顺序：`onTap` → `onDoubleTap` → `onTapUp`。 |
| `onLongPress` | `void Function(Vector2 position)?` | 指针按住约 400 ms 未移动（widget 层的 `longPressTickTimeConsider`）。 |
| `onDragStart` | `HandlesGesture? Function(int button, Vector2 position)?` | 指针在组件上按住并开始移动（拖动要求同一组件上先发生 `onTapDown`）。**返回值是被拖动的子对象**；返回 `null` 表示拖动对象就是*本组件*。返回值会成为 `Scene.draggingComponent`。 |
| `onDragUpdate` | `void Function(int button, Vector2 position, Vector2 delta)?` | *本组件*正被拖动。**`position` 是经过相机转换的世界坐标**（HUD 组件为屏幕坐标），**不是**组件本地坐标；`delta` 是自上个事件以来的世界坐标位移。 |
| `onDragOver` | `void Function(int button, GameComponent? component)?` | *另一个*组件被拖过本组件。 |
| `onDragEnd` | `void Function(Vector2 position)?` | *本组件*的拖动结束。`position` 为世界/屏幕坐标（转换方式同 `onDragUpdate`），不是组件本地坐标。 |
| `onDragIn` | `void Function(Vector2 position, GameComponent? component)?` | *另一个*组件被释放在本组件内部（拖动结束时在放置目标上触发）。 |
| `onScaleStart` | `void Function(List<TouchDetails> touches, ScaleStartDetails details)?` | 两个触摸点都在组件内。 |
| `onScaleUpdate` | `void Function(List<TouchDetails> touches, ScaleUpdateDetails details)?` | 双指缩放变化；`details.scale` 为距离比值，`details.rotation` 为两触点连线自缩放开始以来的旋转角（弧度）。 |
| `onScaleEnd` | `void Function()?` | 缩放结束。 |
| `onMouseEnter` | `void Function()?` | 光标开始悬停该组件（由 `Scene` 管理，而非 widget）。 |
| `onMouseHover` | `void Function(Vector2 position)?` | 光标在组件上移动。 |
| `onMouseExit` | `void Function()?` | 光标离开该组件。 |
| `onMouseScrollUp` / `onMouseScrollDown` | `void Function(Vector2 position)?` | 鼠标滚轮向上 / 向下（`scrollDelta.dy < 0` 为向上，`> 0` 为向下）。 |

用一条完整流程说明拖放语义：组件 **A** 被拖过组件 **B** 时，每次移动都会触发 B 的 `onDragOver(button, A)`；松开按键时触发 B 的 `onDragIn(localPosition, A)`。A 自己则收到 `onDragStart`/`onDragUpdate`/`onDragEnd`。点击合成：若松开位置距拖动起点 **10 px** 以内（全局屏幕距离）**且**光标仍悬停在组件上，则合成 `onTap` + `onTapUp`——几乎没移动的"拖动"仍算点击。

## 场景级分发与坐标转换

`Scene`（lib/scene/scene.dart）暴露了同名分发方法——`onTapDown`、`onTapUp`、`onDragStart`、`onDragUpdate`、`onDragEnd`、`onScaleStart`、`onScaleUpdate`、`onScaleEnd`、`onLongPress`、`onMouseHover`、`onMouseScroll`——全部带 `@mustCallSuper`。

- **分发顺序**：`gestureComponents`（lib/scene/scene.dart:189）即 `descendants(reversed: true).whereType<HandlesGesture>()`——反向广度优先：**最深的后代优先，同层后添加的兄弟优先**，因此视觉上最顶层的组件先命中。
- **独占与广播**：tap-down、tap-up、drag-start、long-press、scale-start、hover 在第一个 `handle*` 返回非空的组件处停止；drag-update、drag-end、scale-update、scroll 则**广播给所有**手势组件（`onDragOver`/`onDragIn` 的放置目标语义要求如此）。
- **子组件优先递归**：组件内部，`gestureComponents`（lib/components/game_component.dart:84）为 `children.reversed().whereType<HandlesGesture>()`，子组件先于父组件自身的命中测试拿到事件。
- **悬停跟踪**：`Scene.hoveringComponent` 在 `Scene.onMouseHover` 中更新——旧组件置 `isHovering = false` 并触发 `onMouseExit`，新组件置 `isHovering = true` 并触发 `onMouseEnter`。`Scene.draggingComponent` 保存 `onDragStart` 返回的值，即当前被拖动的组件。

**坐标系。** `PointerDetector` 与 `Scene` 分发方法工作在 Flutter **全局屏幕坐标**。到组件坐标的转换发生在各 `handle*` 方法内部：

```
屏幕（全局）                        HUD 组件               世界组件
    |  game.camera.globalToLocal（isHud 时跳过） ->  世界坐标
    |  containsPoint（世界/屏幕坐标做命中测试）
    |  toLocal(...)                                -> 组件本地坐标
```

`isHud` 自动推导：挂载在相机 `Viewport`/`Viewfinder` 之下的组件即为 HUD（lib/components/game_component.dart:17）。`Scene` 上还有两个手动换算辅助方法：`worldPosition2Screen` / `screenPosition2World`（lib/scene/scene.dart:82）。注意：`onDragUpdate` 的 `delta` 始终经过相机转换，即使对 HUD 组件也是如此。

**陈旧手势自愈（`resetStaleGestures`，lib/scene/scene.dart:242）。** Flutter 桌面端把指针拖出窗口再拖回时，同一次物理按住可能被分配新的 pointer id；旧 id 的记录永远等不到匹配的 pointer-up 而残留，之后输入就像死掉一样。分层防御：

1. `PointerDetector` 在收到新的 pointer-down 且存在残留记录时，清理自身的触摸记录并触发 `onStaleGestureReset`。
2. `SceneWidget` 把该回调接到 `scene.resetStaleGestures`：为每个残留组件置 `isPressing = false`、清空 `HandlesGesture.tappingDetails`、清空 `draggingComponent`。
3. `Scene.onTapDown` 在没有任何组件消费本次按下时兜底调用 `resetStaleGestures()`；`Scene.onTapUp` 在收到无法匹配的 pointer-up 且记录表非空时同样兜底。

## `PointerDetector`：独立 widget 用法

`PointerDetector`（lib/widgets/pointer_detector.dart:128）是普通的 Flutter `StatefulWidget`，可以包裹**任意** widget——不限于游戏场景。`SceneWidget` 在内部使用它，但你也可以直接把它嵌进普通 Flutter UI：

```dart
PointerDetector(
  onTapDown: (pointer, button, details) => print('down $button @ ${details.globalPosition}'),
  onDragUpdate: (pointer, button, details) => ...,
  onMouseScroll: (details) => print(details.scrollDelta),
  child: MyFlutterWidget(),
)
```

### 构造参数

| 参数 | 类型 / 默认值 | 说明 |
| --- | --- | --- |
| `child` | `Widget?` | 被包裹的 widget |
| `behavior` | `HitTestBehavior.deferToChild` | 传给内部 `Listener` |
| `cursor` | `MouseCursor.defer` | **无效参数**——从未被应用（见[已知限制](#已知限制)） |
| `endDragAtWindowEdge` | `bool`，默认 `false` | 开启后，拖动中的指针离开窗口客户区瞬间会强制结束拖动。用于规避 Windows `SetCapture` 问题：指针在客户区外持续产生 move 事件，可能挂起引擎的 Ticker。`SceneWidget` 始终开启。 |
| `longPressTickTimeConsider` | `int`，默认 `400` | 长按延迟（毫秒） |

### 回调

| 回调 | 签名 |
| --- | --- |
| `onTapDown` / `onTapUp` | `void Function(int pointer, int button, TapDownDetails/TapUpDetails details)?` |
| `onDragStart` / `onDragUpdate` | `void Function(int pointer, int button, DragStartDetails/DragUpdateDetails details)?` |
| `onDragEnd` | `void Function(int pointer, int button, TapUpDetails details)?` —— 注意是 `TapUpDetails` 类型；`button` 取自最初的 down 事件，因为 pointer-up 会丢失该信息 |
| `onScaleStart` / `onScaleUpdate` | `void Function(List<TouchDetails> touches, ScaleStartDetails/ScaleUpdateDetails details)?` |
| `onScaleEnd` | `void Function()?` |
| `onLongPress` | `void Function(int pointer, int button, LongPressStartDetails details)?` |
| `onMouseHover` | `void Function(PointerMoveDetails details)?` |
| `onMouseScroll` | `void Function(MouseScrollDetails details)?` |
| `onStaleGestureReset` | `void Function()?` —— 新 pointer-down 时检测到并清理了残留触摸记录后触发 |

### 内部实现

- 指针移动**超过 1 px** 才开始拖动；在此之前手势仍可能是点击/长按。
- move 与 hover 事件先**经 10 ms 定时器聚合**（`kMoveTimeDeltaThresholdByMS`）再触发一次回调——设计上最多引入一个 tick 的输入延迟。
- 双指缩放：`details.scale` 为当前指距与初始指距之比；焦点为两指中点。
- 长按用普通 `Timer` 实现；任何移动都会取消它。
- hover 来自 `PointerHoverEvent`，滚轮来自 `PointerScrollEvent`（非滚轮的 `PointerSignalEvent` 被忽略）。
- detail 类（也经 `samsara/gestures.dart` re-export）：`TouchDetails`（`pointer`、`button`、`startLocalPosition`、`startGlobalPosition`、`currentLocalPosition`、`currentGlobalPosition`）、`PointerMoveDetails`（`timestamp`、`pointer`、`delta`、`position`、`localPosition`、`button`）、`PointerMoveUpdateDetails`（仿 Flutter `DragUpdateDetails` 的克隆）、`MouseScrollDetails`（`scrollDelta`、`position`、`localPosition`、`kind`）。

## 鼠标按键

按键常量 re-export 自 `package:flutter/gestures.dart`、由 `samsara/gestures.dart` 透出：`kPrimaryButton`（左键）、`kSecondaryButton`（右键）、`kTertiaryButton`（中键）、`kBackMouseButton`、`kForwardMouseButton`。拖动对任意按下的键都会触发；在处理器里检查 `button` 来区分。

真实示例——右键拖动平移相机（`example/lib/scene/mainmenu.dart:89`）：

```dart
@override
void onDragUpdate(int pointer, int button, DragUpdateDetails details) {
  super.onDragUpdate(pointer, button, details); // 保持组件分发可用

  if (button == kSecondaryButton) {
    camera.moveBy(-details.delta.toVector2());
  }
}
```

## 已知限制

- **`PointerDetector.cursor` 从未被应用。** 构造函数保存了它，但 `build` 忽略了它（`MouseRegion` 有意不设置光标）。请改传给内层 widget。
- **widget 层没有 enter/exit。** `PointerDetector.onMouseEnter` / `onMouseExit` 在源码中被注释掉了（lib/widgets/pointer_detector.dart:145）。enter/exit 仅在 `Scene` 层存在，由悬停命中测试推导——单独使用 `PointerDetector` 时没有 enter/exit 回调。
- **拖动回调中的坐标怪癖。** `onDragUpdate` / `onDragEnd` 收到的是经相机转换的世界坐标而非组件本地坐标；且 `onDragUpdate` 的 `delta` 即使对 HUD 组件也经过相机转换。若需要本地坐标，请自行 `toLocal` 转换。
- **移动聚合延迟。** 指针移动与悬停经 10 ms 定时器投递，回调最多滞后原始事件一个 tick。

## 可运行示例

example 应用的 `Components` 场景演示了全部手势并带实时日志：点击、双击、长按、拖动（用 `delta` 移动精灵）、悬停进出（透明度变化）、滚轮缩放。见 `example/lib/scene/components_scene.dart:99`（GESTURES 区域）。运行方式：

```bash
cd example
flutter run
```
