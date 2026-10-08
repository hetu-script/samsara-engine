[English](README.md) | **中文**

# Samsara Engine 文档

Samsara 是一个基于 [Flame 游戏引擎](https://flame-engine.org/) 的 Dart/Flutter
工具库。本目录存放各模块的指南文档；大部分模块的可运行示例都在
[`example/`](../example/) 示例应用中（每个示例是一个独立场景）。

## 指南目录

| 模块 | 文档 | 内容 |
|---|---|---|
| 核心 | [core.md](zh/core.md) | 引擎、场景系统、GameComponent 家族、特效、光照、任务调度器、事件——以及完整的项目上手骨架 |
| 手势 | [gestures.md](zh/gestures.md) | `HandlesGesture` mixin 与 `PointerDetector` 组件：点击 / 双击 / 拖放 / 缩放 / 长按 / 悬停 / 滚轮 |
| 悬停提示 | [hover_info.md](zh/hover_info.md) | Flutter 层的 `hover_info` 提示与 Flame 层的 `Hovertip` 组件 |
| 富文本 | [richtext.md](zh/richtext.md) | 同时用于 Flutter 控件与 Flame 组件的类 HTML 富文本标签、内嵌图标 |
| 卡牌 | [cardgame.md](zh/cardgame.md) | 带牌堆语义的卡牌模型、数据驱动的卡面渲染、抽牌区/牌堆区 |
| 游戏对话 | [game_dialog.md](zh/game_dialog.md) | 视觉小说风格的对话流程、选项分支、屏幕提示 |
| 其他 | [misc.md](zh/misc.md) | 项目专用模块的简要说明：控制台、瓦片地图、markdown 百科 |

## 阅读顺序

初次接触本库？请从 [core.md](zh/core.md) 开始——其中的"快速开始"一节会带你
搭建一个完整项目，其他所有模块都建立在该文描述的场景/组件模型之上。
