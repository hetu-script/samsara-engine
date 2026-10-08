[English](../en/richtext.md) | **中文**

# RichText 富文本渲染

`lib/richtext/` 提供了一套轻量的标签式富文本框架：**同一段带标签的文本**，既可以在 Flutter 层用 `RichText` 渲染，也可以在 Flame 游戏画布上用 `TextNode` 体系渲染，两端共享同一套标签语法与视觉样式。

公开 API 通过桶文件 `package:samsara/richtext.dart`（`lib/richtext.dart`）导出：解析构建函数、图标注册表、`Label` 组件，并 re-export 了 `package:flame/text.dart`（`DocumentRoot`、`DocumentStyle`、`InlineTextStyle` 等 Flame 文本排版类型都来自这里；`GroupElement` 由 `richtext_builder.dart` 额外导出）。

## 标签语法

文本中用 `<标签 属性>内容</>` 标记富文本片段，闭合标签统一写作 `</>`：

```dart
'这是一段<bold red>加粗的红字</>，后面是默认样式。'
'多标签可以<bold italic t5>空格分隔</>。'
'十六进制颜色：<color=\'#ffd700\'>金色传说</>'
'内嵌图标：攻击力 <icon=sword></> +10'
```

规则说明：

- 开标签内可以写任意多个标签，用空格分隔。
- **闭合标签固定写作 `</>`**，不需要与开标签同名；写具名闭合（如 `</bold>`）会使整个片段无法匹配，按原文输出。
- 属性值可以用单引号包裹（如 `color='#ffd700'`、`icon='sword'`），也可以裸写（如 `color=#ffd700`）；**值中包含空格时必须加引号**。
- 标签**不支持嵌套**，每个 `<...></>` 片段是独立的扁平 span。
- 标签内容不能包含 `<`、`/`、`>` 字符（由解析正则的字符集决定），内容里带 `/` 的片段（如 `<red>and/or</>`）无法被识别为标签，会按原文输出。
- 换行支持真实的 `\n` 字符，也支持字面转义序列 `\\n`（普通文本部分会自动转换，见 `lib/extensions.dart` 的 `StringEx.replaceAllEscapedLineBreaks`）。
- 带标签的内容本身跨多行时，框架会自动把标签按行拆分（`_normalizeMultilineTags`），等价于每行各自包一层同样的标签。
- 标签按源码中的字面量匹配，**大小写敏感**：`<red>` 有效，`<RED>` 不会被识别。

## 可用标签一览

### 文字样式

| 标签 | 效果 |
| --- | --- |
| `bold` | 加粗 |
| `italic` | 斜体 |

### 字号

`h*` 标签为标题字号，`t*` 为正文字号；字号标签会**覆盖**传入基础样式的字号（详见「注意事项」）：

| 标签 | 字号 | 标签 | 字号 |
| --- | --- | --- | --- |
| `h1` | 24 | `t1` | 8 |
| `h2` | 28 | `t2` | 10 |
| `h3` | 32 | `t3` | 12 |
| `h4` | 36 | `t4` | 14 |
| `h5` | 40 | `t5` | 16 |
| `h6` | 44 | `t6` | 18 |
| `h7` | 48 | `t7` | 20 |

### 颜色

Material 预设颜色名（均为 `Colors.xxx`）：

```
white black grey red pink purple deepPurple indigo blue lightBlue
cyan teal green lightGreen lime yellow amber orange deepOrange brown blueGrey
```

品质色（`RankedColors`，定义于 `lib/colors.dart`，适合物品稀有度），两个名字等价：

| 标签 | 含义 |
| --- | --- |
| `rank0` / `common` | 普通 |
| `rank1` / `rare` | 稀有 |
| `rank2` / `epic` | 史诗 |
| `rank3` / `legendary` | 传说 |
| `rank4` / `mythic` | 神话 |
| `rank5` / `arcane` | 奥术 |

自定义十六进制颜色：

```dart
'<color=\'#ffd700\'>金色传说</>'
'<color=\'#ffd700cc\'>带透明度的金色</>'
```

格式为 `#RRGGBB` 或 `#RRGGBBAA`（透明度在最后两位），`#` 前缀可省略；经 `HexColor.fromString` 解析（`lib/extensions.dart`），位数非法时抛出 `ArgumentError`。

### 图标与链接

- `icon=xxx` — 内嵌图标，`xxx` 是 `RichTextIcons` 注册的 id（见下文「内嵌图标」）。图标内容部分通常留空：`<icon=sword></>`。图标会缩放到与当前文字等高。
- `link='xxx'` — 链接路由，解析格式形如 `link='character?name=wendy&age=18'`。**目前仅解析出字符串存入 `TagResolveResult.link`，点击手势（recognizer）代码处于注释状态，尚未生效。**

## 内嵌图标

图标 id 与资源路径的映射通过 `RichTextIcons`（`lib/richtext/icon_registry.dart`）静态注册表管理。路径相对于 `assets/images/`、需含扩展名。建议在游戏启动时统一注册并预载，参考 `example/lib/main.dart`：

```dart
RichTextIcons.registerAll({
  'cultivate': 'icon/cultivate.png',
  'information': 'icon/information.png',
  'inventory': 'icon/inventory.png',
  'library': 'icon/library.png',
  'material': 'icon/material.png',
  'quest': 'icon/quest.png',
  'shard': 'icon/shard.png',
  'spirit': 'icon/spirit.png',
  'stats': 'icon/stats.png',
  'sword': 'icon/sword.png',
  'wiki': 'icon/wiki.png',
});

// 批量载入 Flame 图片缓存（Flame 侧渲染必需）
await RichTextIcons.preload();
```

注册表完整 API：

| 方法 | 说明 |
| --- | --- |
| `register(String id, String path)` | 注册单个图标 |
| `registerAll(Map<String, String> icons)` | 批量注册 |
| `unregister(String id)` | 移除单个注册 |
| `clear()` | 清空注册表 |
| `contains(String id)` | 查询 id 是否已注册 |
| `resolveFlutterAsset(String id)` | 返回 Flutter 侧完整路径 `assets/images/<path>`，未注册返回 `null` |
| `resolveFlameKey(String id)` | 返回 Flame 图片缓存 key（即注册时的 `path`），未注册返回 `null` |
| `preload()` | 把所有已注册图标批量载入 `Flame.images` 缓存 |

之后在富文本中用 `<icon=sword></>` 引用，两端的渲染方式：

- **Flutter 端**：`WidgetSpan`（`PlaceholderAlignment.middle`）+ `Image.asset`，宽高取合并后样式的 `fontSize ?? 14`。
- **Flame 端**：`InlineIconNode`（`lib/richtext/icon_node.dart`），排版时从 `Flame.images` 缓存取图，高度为 `fontSize * fontScale`（`fontSize` 缺省 16），宽度按原图宽高比缩放，底部与文字基线对齐。

## 在 Flutter 中使用

`buildFlutterRichText`（`lib/richtext/richtext_builder.dart`）把源字符串解析为扁平的 `List<TextSpan>`，每个自然段一个 `TextSpan`（段间以 `TextSpan('\n')` 连接），直接喂给 `RichText`：

```dart
import 'package:samsara/richtext.dart';

RichText(
  text: TextSpan(
    children: buildFlutterRichText(
      '获得 <epic>史诗武器</> <icon=sword></>',
      style: const TextStyle(fontSize: 14), // 基础样式，标签样式 merge 在其上
    ),
  ),
)
```

行为要点：`source` 为 `null` 或空串时返回空列表；标签样式合并到基础 `style` 上；未设字号标签时继承基础样式的字号。

也可以直接使用封装好的 `Label` 组件（`lib/widgets/ui/label.dart`，自带鼠标悬停回调，底层就是 `buildFlutterRichText` + `RichText`）：

```dart
Label(
  '血量：<red>120</> / 200 <icon=spirit></>',
  textStyle: const TextStyle(fontSize: 16),
  onMouseEnter: (rect) => showTooltip(rect),
  onMouseExit: hideTooltip,
)
```

`Label` 完整参数（首个为位置参数）：

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `richTextSource` | `String` | — | 位置参数，带标签的源文本 |
| `width` / `height` | `double?` | `null` | 容器尺寸 |
| `padding` | `EdgeInsetsGeometry?` | `null` | 容器内边距 |
| `textAlign` | `TextAlign` | `TextAlign.center` | 文本对齐 |
| `textStyle` | `TextStyle?` | `null` | 合并到默认样式之上 |
| `backgroundColor` | `Color?` | `null` | 容器背景色 |
| `cursor` | `MouseCursor` | `MouseCursor.defer` | 悬停鼠标指针 |
| `onMouseEnter` | `void Function(Rect)?` | `null` | 鼠标进入回调（回调收到控件 Rect） |
| `onMouseExit` | `void Function()?` | `null` | 鼠标移出回调 |

默认样式取 `Theme.of(context).textTheme.bodySmall` 的 `fontFamily` / `fontSize`，再与 `textStyle` 合并。`Label` 的实际使用示例见 `example/lib/scene/mainmenu.dart` 与 `example/lib/scene/richtext_scene.dart`。

`LabelsWrap` 是配套的流式布局容器（`ConstrainedBox` + `Wrap`），参数为 `minWidth`（默认 0）、`minHeight`（默认 0）、`padding`、`children`，适合一排多个 `Label` 的场景。

## 在 Flame 中使用

`buildFlameRichText`（`lib/richtext/richtext_builder.dart`）返回 Flame 文本体系的 `DocumentRoot`，每行文本一个 `ParagraphNode.group`；图标解析为 `InlineIconNode`。返回后需要调用 `format` 排版为可绘制的 `GroupElement`：

```dart
import 'package:samsara/richtext.dart';

final document = buildFlameRichText(
  '获得 <epic>史诗武器</> <icon=sword></>',
  style: const TextStyle(fontSize: 14),
);

final element = document.format(DocumentStyle(
  paragraph: BlockStyle(margin: EdgeInsets.zero, textAlign: TextAlign.left),
  text: const TextStyle(fontSize: 14).toInlineTextStyle(fontScale: 1.0),
  width: 200,   // 排版区域宽度，超出自动折行
  height: 100,
));

// 在组件的 render 中绘制
element.draw(canvas);
```

**在排版之前必须 `await RichTextIcons.preload()`**：图标元素在排版时才通过 `Flame.images.fromCache` 取图，未预载会抛异常。

绝大多数情况下不需要手写上面的流程，直接用现成的 `RichTextComponent`（`lib/components/ui/rich_text_component.dart`）即可。它是 `BorderComponent` + `HandlesGesture` 的组合，封装了构建、排版、水平/垂直对齐、描边与背景色：

```dart
RichTextComponent(
  size: Vector2(200, 60),
  text: '任务完成度：<yellow bold>80%</>',
  fontScale: 1.2,
  config: const ScreenTextConfig(
    anchor: Anchor.center,       // 垂直方向对齐（默认 topLeft）
    textAlign: TextAlign.center, // 水平方向对齐（默认 left）
    outlined: true,              // 黑色描边第二遍绘制
    textStyle: TextStyle(fontSize: 14, color: Colors.white),
  ),
  backgroundColor: Colors.black54,
);
```

构造函数参数（`size` / `position` / `anchor` / `isVisible` / `priority` 继承自 `BorderComponent`）：

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `size` | `Vector2?` | `null` | 排版区域尺寸（超出按 `DocumentStyle` 宽度折行） |
| `position` | `Vector2?` | `null` | 组件位置 |
| `anchor` | `Anchor` | 左上 | 组件自身的锚点 |
| `isVisible` / `priority` | — | — | 可见性与绘制优先级 |
| `text` | `String?` | `null` | 初始富文本源 |
| `fontScale` | `double` | `1.0` | 整体字号缩放 |
| `config` | `ScreenTextConfig` | `const ScreenTextConfig()` | 排版配置（对齐、描边、基础样式等） |
| `enableGesture` | `bool` | `false` | 是否启用手势 |
| `backgroundColor` | `Color?` | `null` | 背景色（`null` 为透明） |

常用成员：

| 成员 | 说明 |
| --- | --- |
| `text` | getter / setter。赋值即重建文档并重新排版；传 `null` 清空内容；文本未变化时跳过重建。 |
| `layout({text, width, height, fontScale})` | 增量修改文本或排版参数并**强制**重排（即使文本未变）。 |
| `textAreaHeight` | 只读，已排版文本区域的实际高度（`double?`）。 |
| `backgroundColor` | getter / setter，即时更新背景绘制。 |
| `render(canvas)` / `renderAt(canvas, offset)` | 在组件位置 / 指定偏移处绘制背景、描边与正文。 |

对齐行为：水平方向由 `config.textAlign` 经 `DocumentStyle` 处理；垂直方向由 `config.anchor` 处理——`top*` 不偏移、`center*` 居中、`bottom*` 贴底。`config.outlined == true` 时，会用黑色描边画笔（`strokeWidth` 2.5）对同一文档做第二遍排版绘制，形成描边效果。

## 辅助 API

| API | 说明 |
| --- | --- |
| `getRichTextStream(String source)` | 把源字符串切成 token 流：`<...></>` 标签片段整体保留为一个 token，其余文本拆成单字符。适合打字机逐字显示等场景（见下例）。 |
| `TextStyle.toInlineTextStyle({double? fontScale})` | 扩展方法（`lib/richtext/textstyle_extension.dart`），Flutter `TextStyle` → Flame `InlineTextStyle`，完整映射颜色、字号、字重、阴影等字段。 |
| `InlineTextStyle.asTextStyle2()` / `asTextRenderer2()` | 扩展方法（`lib/richtext/inline_text_style2.dart`，已随桶文件导出），把 Flame `InlineTextStyle` 转回 Flutter `TextStyle` / `TextPaint`，会做 `fontSize * fontScale` 换算。 |
| `RichTextNode` | Flame `InlineTextNode` 子类（`lib/richtext/richtext_node.dart`），按字符（`characters`）切分做贪心折行。 |
| `InlineIconNode` / `InlineIconElement` | Flame 侧的内嵌图标节点与已排版元素（`lib/richtext/icon_node.dart`）。 |
| `TagResolveResult` | 标签解析结果（`icon` / `link` / `style`），一般仅供内部使用。 |

打字机示例：

```dart
final tokens = getRichTextStream('获得 <epic>史诗武器</>！');
// ['获', '得', ' ', '<epic>史诗武器</>', '！']
// 消费端逐 token 拼回源文本再交给 RichTextComponent / Label 渲染，
// 即可实现标签样式下仍逐字显示的打字机效果。
```

## 注意事项

- 闭合标签是固定的 `</>`；具名闭合（`</bold>`）会使整个片段无法匹配，按原文输出。
- 标签大小写敏感，颜色名中的驼峰（如 `deepPurple`、`lightBlue`）须按表中写法。
- 未注册的 `icon` id：`resolveXxx` 返回 `null`，若内容为空则整个标签不输出；若内容非空，内容仍会按合并后的样式渲染（只是没有图标）。
- Flame 侧使用图标前必须 `await RichTextIcons.preload()`（或自行保证图片已进入 `Flame.images` 缓存），否则在排版取图时抛异常。
- 字号标签（`t*` / `h*`）在两端都会覆盖传入基础 `style` 的字号；未指定字号标签时继承基础样式。
- `link=` 目前仅解析、不响应点击（recognizer 代码处于注释状态）。
- `color=` 的格式是 `#RRGGBB` 或 `#RRGGBBAA`（透明度在最后两位，不是 `#AARRGGBB`），位数非法会抛 `ArgumentError`。
- `asTextStyle2()` / `asTextRenderer2()` 在 `InlineTextStyle.fontSize` 为 null 时按原样透传（不做缩放换算）；需要 `fontScale` 换算时请设置 `fontSize`。
- 标签内容不能包含 `<`、`/`、`>` 字符，内容含 `/` 的片段不会被识别为标签。

## 运行示例

示例工程中的 `example/lib/scene/richtext_scene.dart`（`RichTextScene`，在 `example/lib/app.dart` 中以 id `'richtext'` 注册）演示了两端共享同一套标签语法：Flame 侧用 `RichTextComponent`，Flutter 侧用 `Label`，涵盖加粗/斜体、字号、颜色、品质色、内嵌图标与多行文本。图标注册与预载见 `example/lib/main.dart`。
