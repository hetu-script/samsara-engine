[English](../en/misc.md) | **中文**

# 其他模块

这些模块功能完整，但当初是为作者自己的游戏项目设计的，API 通用性较弱，在此仅作简要介绍。

## 控制台 Console — `lib/console/`

基于内嵌 [HetuScript](https://github.com/hetu-script) 解释器的游戏内调试控制台（Flutter widget）。

- 入口类：`Console`（`lib/console/console.dart`），从主 barrel `package:samsara/samsara.dart` 导出。
- 需要传入引擎：`Console(engine: engine)`。一般通过
  `showDialog(context: context, builder: (_) => Console(engine: engine))` 打开。
- 显示引擎内存中的日志（`engine.getLogsRaw()`），按日志级别着色。
- `Ctrl+Enter` 将输入作为 HetuScript 代码通过 `engine.hetu.eval(...)` 求值并输出结果；
  `Ctrl+↑` / `Ctrl+↓` 翻阅历史命令；`Esc` 关闭对话框。
- 控制台在 `EngineConfig(developMode: true)` 下最有用：该模式会加载 `scripts/` 目录下的脚本，
  并把全局 `engine` 对象暴露给脚本环境。

最小用法（见 `example/lib/scene/mainmenu.dart`）：

```dart
showDialog(
  context: context,
  builder: (BuildContext context) => Console(engine: engine),
);
```

## 瓦片地图 TileMap — `lib/tilemap/`

支持六边形（竖向/横向）、正交与等距斜视布局的瓦片地图组件，带区域着色、战争迷雾和
寻路移动单位。它为某个特定策略/RPG 项目而写，因此区域、城市、国家、地形类型等概念
都比较定制化。

- 入口类：`TileMap`（`lib/tilemap/tilemap.dart`）——带 `HandlesGesture` 的
  `GameComponent`；由瓦片尺寸、形状和数据构造，从精灵图集渲染地形，并处理瓦片的
  悬停/选中高亮。
- `TileMapTerrain`（`lib/tilemap/terrain.dart`）——单个瓦片：图集格子索引加可选动画。
- `TileMapComponent`（`lib/tilemap/component.dart`）——地图上的可移动单位（NPC 等），
  带走路/游泳动画状态，沿 `TileMapRouteNode`（`lib/tilemap/route.dart`）路径移动。
- 辅助类型：`TileInfo` mixin、`TilePosition`、`TileShape`、`TileRenderDirection`、
  方向枚举、`AnimatedCloud`。
- 区域着色模式常量：`kColorModeNone`、`kColorModeZone`、`kColorModeCity`、`kColorModeNation`。
- Barrel：`package:samsara/tilemap.dart`。

如果你需要通用瓦片地图，建议直接使用 Flame 自带的 tile 组件；本模块更适合作为
"六边形地图 + 战争迷雾 + 寻路" 的参考实现来阅读。

## Markdown 百科 — `lib/markdown_wiki/`

游戏内百科/帮助浏览器（Flutter widget），把打包在资产里的 markdown 页面以树状结构展示。

- 入口类：`MarkdownWiki`（`lib/markdown_wiki/markdown_wiki.dart`）——一个 `Scaffold`，
  左侧 300px 页面树（基于 `animated_tree_view`），右侧可选择的 markdown 渲染面板
  （基于 `flutter_markdown_plus`）；页面标题通过 `engine.locale(...)` 本地化。
- 数据：`WikiPageData` 与 `buildWikiTreeNodesFromData()`
  （`lib/markdown_wiki/node_builder.dart`）从嵌套 Map 数据构建树；页面正文通过
  `rootBundle` 从资产路径加载。
- Barrel：`package:samsara/markdown_wiki.dart`。
- 索引与内容文件的目录结构与作者自己的游戏一致（可参考 `example/wiki/` 的示例结构）；
  该组件更适合作为二次开发的起点，而非开箱即用的通用百科。
