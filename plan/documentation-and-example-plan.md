# Samsara Engine 文档补全与 example 项目改造计划

> 状态：**已完成**（决策点见文末）。全部 7 步执行完毕，lib 与 example 的 `flutter analyze` 均无问题。

## 一、库现状分析摘要

经过对 `lib/` 全量代码和 `test/` 项目的分析，当前状态如下：

**模块全景**（按文档优先级分组）：

| 分组 | 模块 | 状态 |
|---|---|---|
| 重点文档化 | 核心（engine / scene / components / effect / lighting / task / event / camera） | 无文档 |
| 重点文档化 | 手势（gestures/gesture_mixin + widgets/pointer_detector） | 无文档 |
| 重点文档化 | hover_info | 无文档 |
| 重点文档化 | richtext | 已有 `docs/richtext/readme.md`（纯中文，内容较完整准确） |
| 较详细文档化 | cardgame（泛用性较高） | 无文档 |
| 较详细文档化 | game_dialog（泛用性较高） | 无文档 |
| 一笔带过 | console / tilemap / markdown_wiki | 无文档，设计较专用 |
| 不文档化 | llm_chat / localization / logger / utils / painter / widgets 杂项 | 内部实现细节 |

**关键发现**（影响文档与示例写法）：

1. 手势系统完全不使用 Flame 的手势 mixin，链路为 `PointerDetector`(Flutter widget) → `Scene.onXxx` 分发 → `HandlesGesture.handleXxx`（深度优先、子组件优先）。
2. `GameComponent.moveTo` 是实例方法，`CameraEx.moveTo2` 是扩展方法，两者需区分说明。
3. 光照是相机级渲染 pass：`Camera2.renderTree` 只处理 **world 直接子级** 且 `lightConfig.isLighted == true` 的 GameComponent；`enableLlm` 默认 `true` 会在 `init()` 加载本地 LLM（新用户易踩坑，文档需提示关闭）。
4. `lib/components.dart` barrel 漏导出 `SpriteComponent2`（本次修复）。
5. richtext 的闭合标签固定为 `</>`；`link=` 标签已解析但点击功能被注释掉（文档如实标注）。
6. hover_info 是 **Flutter widget 层** 的 tooltip（依赖 provider 的 `HoverContentState`），与 Flame 层的 `Hovertip`（`lib/components/ui/hovertip.dart`）是两套东西，文档需消歧，示例场景两者都演示。
7. `test/` 项目目前只有 1 个 `MainMenuScene` 场景；`light_point.dart`、`light_trail.dart`、`noise_test.dart`、`drop_menu.dart` 是未被引用的孤儿代码；tilemap/cardgame/wiki 的资产已声明但无对应场景。

## 二、docs 文档计划（已确认：en/zh 镜像目录）

### 目录结构

```
docs/
├── README.md                  # 文档索引（英文）
├── README_ZH.md               # 文档索引（中文）
├── en/
│   ├── core.md                # 引擎/场景/组件/特效/光照/任务/事件 + Getting Started 框架
│   ├── gestures.md            # HandlesGesture + PointerDetector
│   ├── hover_info.md          # hover_info（Flutter 层）+ Hovertip（Flame 层）消歧
│   ├── richtext.md            # 富文本系统
│   ├── cardgame.md            # 卡牌系统（较详细）
│   ├── game_dialog.md         # 游戏对话系统（较详细）
│   └── misc.md                # console / tilemap / markdown_wiki 简要
└── zh/
    ├── core.md
    ├── gestures.md
    ├── hover_info.md
    ├── richtext.md            # 在现有 docs/richtext/readme.md 基础上修订扩充迁入
    ├── cardgame.md
    ├── game_dialog.md
    └── misc.md
```

（原有 `docs/richtext/readme.md` 迁移为 `docs/zh/richtext.md` 并修订：示例路径 `test/` → `example/`、补充 `getRichTextStream`、`RichTextIcons` 完整流程、`Label` widget。）

### 各文档内容大纲

**1. core（最重要，篇幅最大）**

- 架构总览：类层次图（GameComponent / Scene / SceneController / SamsaraEngine）、Flame 组件层 vs Flutter widget 层的划分与三座桥梁（PointerDetector、EventAggregator、ChangeNotifier+Provider）
- `SamsaraEngine`：EngineConfig 各字段、`init(context)` 的时机与前提、本地化、日志、音频、事件总线；明确提示 `enableLlm` 默认 true 的坑
- `Scene` 架构：场景注册（`registerSceneConstructor`）、懒加载缓存、`pushScene / popScene / popSceneTill / switchScene / clearCachedScene` 语义差异（switchScene 不动栈）、`onStart/onEnd` 生命周期（onStart 每次进入都触发、资源不自动释放）、固定步长 update、bounds/坐标换算、fitScreen、`addHintText`
- `SceneWidget` 与 Flutter 嵌入方式（`scene.build(...)`、loadingBuilder、overlayBuilderMap）
- `GameComponent`：setPaint 命名画刷、isVisible（含 camera.canSee 联动）、isHud、onAfterLoaded、fadeIn/fadeOut、snapTo、**moveTo**（参数全解）
- 其他组件简介：BorderComponent、SpriteComponent2、GestureComponent、SpriteButton、FadingText、InAndOutSprite、Arrow、Timer、ValueGenerator、ParticleComponent、RichTextComponent、Hovertip
- Effect：AdvancedMoveEffect、FadeEffect（淡出后自动移除目标）、CameraShakeEffect、ZoomEffect、ConfettiEffect
- 光照：LightConfig 全字段、Scene 的 enableLighting/backgroundLightingColor、"仅 world 直接子级生效"的限制、ParticleComponent 的 lightUpDuration
- TaskController、EventAggregator 使用约定
- **Getting Started：基于本库的 Flame 项目代码框架**——以 example 项目为蓝本的最小可运行骨架，逐文件讲解

**2. gestures**：链路图；HandlesGesture 全部回调字段表（含 onDragOver/onDragIn 语义）、super 调用要求、坐标系说明；PointerDetector 参数与回调、endDragAtWindowEdge 动机；已知限制如实写（scale 旋转角恒 0、widget 层无 onMouseEnter/Exit）；完整自定义组件示例。

**3. hover_info**：与 Hovertip 消歧；HoverContentState + provider 挂载要求；show/hide/setDetailed 生命周期、12 方向定位；字符串内容自动走 richtext 渲染；完整接入示例。

**4. richtext**：保留修订现有中文内容 + 英文版；补充 `getRichTextStream`、`RichTextIcons`、`Label`。

**5. cardgame（较详细）**：GameCard（id/kind/tags/链表 pile/翻转旋转/focus/usable 阶段）、CustomGameCard（数据驱动渲染、colored cost sprite 注册）、DrawingZone、PiledZone（PileStyle）、PlayingCardClassBinding；配 example 场景代码讲解。

**6. game_dialog（较详细）**：GameDialog 模型（ChangeNotifier + TaskController，背景/插画/对话内容/选项/屏幕提示数据）、GameDialogController（监听并叠加 GameDialogContent / SelectionDialog / ScreenHint）、Avatar 与 AvatarNameAlignment、内容数据格式 `{name, icon, image, lines}`、任务队列 execute 流程；配 example 场景代码讲解。

**7. misc**：console / tilemap / markdown_wiki 各一段（用途、入口类、设计局限说明、最小提示）。

## 三、README 重写计划（已确认）

- 根 `README.md` = **英文版**（默认），开头放置中文版本链接
- 根 `README_ZH.md` = **中文版**，文档链接全部指向 `docs/zh/`
- 当前 README（内部规范内容）被替换；规范内容 AGENTS.md 已有，不丢失
- 内容：项目简介、特性列表、模块一览表（链接 docs）、快速开始骨架、example 运行方式、path 依赖注意事项

## 四、test → example 改造计划（已确认）

### 4.1 重命名

- `git mv test example`
- `example/pubspec.yaml`：`name: test` → `name: samsara_example`
- 更新引用点：`.vscode/launch.json`、`AGENTS.md`（CLAUDE.md 不动）
- Windows runner 改名（已确认）：`windows/CMakeLists.txt`（project/BINARY_NAME）、`runner/main.cpp`（窗口标题字符串）、`runner/Runner.rc` 中 "test" → "samsara_example" / "example"
- 资产路径全部为 bundle 相对路径，不受影响；改名后 `flutter pub get` 重新生成 lock

### 4.2 示例场景规划（已确认：7 个场景，同一游戏内，不分模块子目录）

| 场景 | id | 演示内容 |
|---|---|---|
| MainMenuScene | `main` | 入口导航：按钮跳转各演示场景（pushScene/popScene 用例），保留现有背景与菜单 |
| ComponentsScene | `components` | GameComponent 三合一：moveTo/fade/snap、SpriteComponent2（boxFit/clip/zoom）、SpriteButton；手势（tap/doubleTap/drag 拖放/scale/longPress/hover/滚轮，实时日志）；特效（CameraShake、Zoom、Confetti） |
| LightingScene | `lighting` | enableLighting + LightConfig，复用 light_point/light_trail 思路 |
| RichTextScene | `richtext` | RichTextComponent 各标签 + Flutter 层 Label 对照 |
| HoverScene | `hover` | Hovertip（Flame 层）+ hover_info（Flutter 层）双演示 |
| CardGameScene | `cardgame` | DrawingZone/PiledZone、发牌、翻转、拖动卡牌 |
| DialogScene | `dialog` | GameDialog 对话流程：头像/台词/选项分支/屏幕提示 |

实现说明：

- 图片与音乐资源**使用 assets 目录中现有的**（button.png、light_point.png、light_trail_*.png、icon/、pepe.png 等），不新增；若实现中发现必须补充的资源，先告知用户再决定
- 孤儿文件保留（用户未选删除）；lighting 示例新写组件，不依赖孤儿文件
- 保留 main.dart 启动序列（窗口、光标、图标注册、错误处理）作为框架示范
- tilemap / wiki 不做示例场景
- 验证：`flutter analyze`（lib + example），环境允许再 `flutter build windows`

## 五、执行顺序

1. ✅ 确认计划与决策点
2. test → example 重命名 + 引用点修正 + SpriteComponent2 导出修复
3. example 示例场景实现
4. docs 文档撰写（en/zh 镜像）
5. README.md（英文）+ README_ZH.md（中文）+ docs 索引
6. AGENTS.md 更新
7. 最终验证：`flutter analyze`（lib + example）、链接检查

## 六、决策点（已确认）

1. **双语组织**：docs 下 `en/` 与 `zh/` 镜像目录；根 README.md 默认英文 + README_ZH.md（英文版内链接中文版；中文版的文档链接指向 zh/ 文档）
2. **example 场景**：components/gesture/effects 合并为一个场景；lighting/richtext/hover 各自独立；另加 cardgame 场景与 game_dialog 场景（共 7 个）；cardgame 与 game_dialog 文档较详细
3. **顺带修复**：✅ 修复 SpriteComponent2 导出；✅ Windows runner 改名；❌ 不删孤儿文件
4. **规范文件**：只更新 AGENTS.md，CLAUDE.md 不动
