# Samsara Engine

[English](README.md) | **中文**

一个基于 [Flame 游戏引擎](https://flame-engine.org/) 的 Dart/Flutter 工具库，
补齐了 Flame 本身不提供的能力：带导航栈的场景管理、统一手势系统、富文本、
游戏对话、卡牌机制、光照以及顺序动画任务调度。

## 功能模块

| 模块 | 亮点 | 文档 |
|---|---|---|
| 核心 | `SamsaraEngine`、带懒加载缓存的场景栈导航、`GameComponent` 基类（命名画刷 / `moveTo` / 淡入淡出）、相机特效、暗色遮罩光照、`TaskController`、事件总线 | [docs/zh/core.md](docs/zh/core.md) |
| 手势 | 一个 mixin（`HandlesGesture`）加一个 widget（`PointerDetector`）统一处理点击、双击、拖放、双指缩放、长按、悬停与滚轮，鼠标触摸通用 | [docs/zh/gestures.md](docs/zh/gestures.md) |
| 悬停提示 | Flutter 层 `hover_info` 提示（12 方向定位）与 Flame 层 `Hovertip` 组件 | [docs/zh/hover_info.md](docs/zh/hover_info.md) |
| 富文本 | 类 HTML 标签（`<bold>`、`<h2>`、`<red>`、`<legendary>`、`color='#ffd700'`、内嵌 `<icon=...>`），Flutter 控件与 Flame 组件通用 | [docs/zh/richtext.md](docs/zh/richtext.md) |
| 卡牌 | 带牌堆链表语义的卡牌模型、翻面/旋转/聚焦动画、数据驱动卡面、抽牌区与牌堆区 | [docs/zh/cardgame.md](docs/zh/cardgame.md) |
| 游戏对话 | 视觉小说式对话模型 + 浮层控制器：会话、选项分支、教学屏幕提示 | [docs/zh/game_dialog.md](docs/zh/game_dialog.md) |
| 其他 | 游戏内 HetuScript 控制台、带战争迷雾的六边形地图、markdown 百科——为特定项目设计，仅简要文档 | [docs/zh/misc.md](docs/zh/misc.md) |

完整索引：[docs/README_ZH.md](docs/README_ZH.md)

## 快速开始

```dart
import 'package:samsara/samsara.dart';

// 1. 场景是一个完整的 Flame 游戏实例
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

// 2. 引擎持有场景栈
final engine = SamsaraEngine(config: const EngineConfig(enableLlm: false));

// 3. 在根 StatefulWidget 的 initState 中：
//    engine.registerSceneConstructor('main', ([args]) async => MainScene(id: 'main'));
//    await engine.init(context);
//    engine.pushScene('main');
// 4. 在 build() 中：用 Provider 提供引擎，并渲染当前场景——
//    context.watch<SamsaraEngine>().scene?.build(context)
```

完整且带注释的项目骨架（窗口设置、加载屏、错误处理）见
[docs/zh/core.md](docs/zh/core.md)，并可直接运行 [`example/`](example/) 示例应用查看。

## 示例应用

```bash
cd example
flutter pub get
flutter run -d windows
```

示例应用是一个单独的游戏，主菜单可以进入各模块的演示场景：组件与手势与特效、
光照、富文本、悬停提示、卡牌、游戏对话。

## 依赖说明

`hetu_script`、`hetu_script_flutter` 与 `fluent_ui` 通过相对路径依赖
（`../hetu-script/...`、`../fluent_ui`），这些仓库必须放在本仓库的同级目录，
否则 `flutter pub get` 会失败。

## 许可证

见 [LICENSE](LICENSE)。
