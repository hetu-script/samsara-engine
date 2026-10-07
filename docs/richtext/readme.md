# RichText 富文本渲染

`lib/richtext/` 提供了一套轻量的标签式富文本框架：**同一段带标签的文本**，既可以在 Flutter 层用 `RichText` 组件渲染，也可以在 Flame 游戏画布上用 `TextNode` 体系渲染，两端视觉一致。

公开 API 通过根目录的 `lib/richtext.dart` 桶文件导出（同时 re-export 了 `package:flame/text.dart` 与 `Label` 组件）。

## 标签语法

文本中用 `<标签 属性>内容</>` 标记富文本片段，闭合标签统一写作 `</>`（不需要与开标签同名）：

```dart
'这是一段<bold red>加粗的红字</>，后面是默认样式。'
'多标签可以<bold italic t5>空格分隔</>。'
'十六进制颜色：<color='#ffd700'>金色传说</>'
'内嵌图标：攻击力 <icon=sword></> +10'
```

规则说明：

- 标签与标签之间用空格分隔，一个开标签内可以写任意多个标签。
- 属性值可以用单引号包裹（如 `color='#ffffffff'`、`icon='sword'`），也可以不带引号（如 `color=#ffd700`）；**值中包含空格时必须加引号**。
- 标签**不支持嵌套**，每个 `<...></>` 片段是独立的扁平 span。
- 换行支持真实的 `\n` 字符，也支持字面转义序列 `\\n`（普通文本部分会自动转换）。
- 如果带标签的内容本身跨多行，框架会自动把标签按行拆分（`_normalizeMultilineTags`），等价于每行各自包一层同样的标签。

## 可用标签一览

### 文字样式

| 标签 | 效果 |
| --- | --- |
| `bold` | 加粗 |
| `italic` | 斜体 |

### 字号

`h*` 标签为标题字号，`t*` 为逐级缩小的正文字号：

| 标签 | 字号 | 标签 | 字号 |
| --- | --- | --- | --- |
| `h7` | 48 | `t7` | 20 |
| `h6` | 44 | `t6` | 18 |
| `h5` | 40 | `t5` | 16 |
| `h4` | 36 | `t4` | 14 |
| `h3` | 32 | `t3` | 12 |
| `h2` | 28 | `t2` | 10 |
| `h1` | 24 | `t1` | 8 |

### 颜色

Material 预设颜色名（均为 `Colors.xxx`）：

```
white black grey red pink purple deepPurple indigo blue lightBlue
cyan teal green lightGreen lime yellow amber deepOrange brown blueGrey
```

品质色（`RankedColors`，适合物品稀有度），两个名字等价：

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
'<color='#80ffd700'>半透明金色</>' // 格式为 #AARRGGBB，经 HexColor.fromString 解析
```

### 图标与链接

- `icon=xxx` — 内嵌图标，`xxx` 是 `RichTextIcons` 注册的 id（见下文「内嵌图标」）。图标内容部分通常留空：`<icon=sword></>`。图标会被缩放到与当前文字等高。
- `link='xxx'` — 链接路由，解析格式形如 `link='character?name=wendy&age=18'`。**目前仅解析出字符串，点击手势（recognizer）代码处于注释状态，尚未生效。**

## 在 Flutter 中使用

`buildFlutterRichText` 把源字符串解析为扁平的 `List<TextSpan>`，直接喂给 `RichText`：

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

也可以直接使用封装好的 `Label` 组件（自带鼠标悬停回调，来自 `lib/widgets/ui/label.dart`）：

```dart
Label(
  '血量：<red>120</> / 200',
  textStyle: TextStyle(fontSize: 16),
  onMouseEnter: (rect) => showTooltip(rect),
  onMouseExit: hideTooltip,
)
```

## 在 Flame 中使用

`buildFlameRichText` 返回 Flame 文本体系的 `DocumentRoot`，再调用 `format` 排版为可绘制的元素：

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

绝大多数情况下不需要手写上面的流程，直接用现成的 `RichTextComponent`（`lib/components/ui/rich_text_component.dart`）即可，它封装了排版、对齐、描边和背景色：

```dart
RichTextComponent(
  size: Vector2(200, 60),
  text: '任务完成度：<yellow bold>80%</>',
  fontScale: 1.2,
  config: ScreenTextConfig(
    anchor: Anchor.center,      // 垂直方向对齐
    textAlign: TextAlign.center, // 水平方向对齐
    outlined: true,             // 黑色描边
    textStyle: TextStyle(fontSize: 14, color: Colors.white),
  ),
  backgroundColor: Colors.black54,
);
```

## 内嵌图标

图标 id 与资源路径的映射通过 `RichTextIcons` 注册表管理，建议在游戏启动时统一注册并预载（参考 `test/lib/main.dart`）：

```dart
// 路径相对于 assets/images/，需含扩展名
RichTextIcons.registerAll({
  'sword': 'icon/sword.png',
  'spirit': 'icon/spirit.png',
});

// 批量载入 Flame 图片缓存（Flame 侧渲染必需）
await RichTextIcons.preload();
```

之后在富文本中使用 `<icon=sword></>`：

- **Flutter 端**：渲染为 `WidgetSpan` + `Image.asset('assets/images/icon/sword.png')`，尺寸取当前文字字号。
- **Flame 端**：渲染为 `InlineIconElement`，从 `Flame.images` 缓存取图，高度为 `fontSize * fontScale`，宽度按原图宽高比缩放，底部与文字基线对齐。

注册表其余方法：`register(id, path)`、`unregister(id)`、`clear()`、`contains(id)`、`resolveFlutterAsset(id)`（返回 `assets/images/...` 完整路径）、`resolveFlameKey(id)`（返回缓存 key）。

## 辅助 API

| API | 说明 |
| --- | --- |
| `getRichTextStream(source)` | 把源字符串切成 token 流：标签片段整体保留，其余文本拆成单字符。可用于打字机逐字显示等场景。 |
| `TextStyle.toInlineTextStyle({fontScale})` | 扩展方法，Flutter `TextStyle` → Flame `InlineTextStyle`。 |
| `InlineTextStyle.asTextStyle2()` / `asTextRenderer2()` | 扩展方法，把 Flame 样式转回 Flutter `TextStyle` / `TextPaint`，会应用 `fontSize * fontScale` 换算。 |
| `RichTextNode` | Flame `InlineTextNode` 子类，按字符（`characters`）切分做贪心折行。 |
| `InlineIconNode` / `InlineIconElement` | Flame 侧的内嵌图标节点与已排版元素。 |
| `TagResolveResult` | 标签解析结果（`icon` / `link` / `style`），一般仅供内部使用。 |

## 注意事项

- 标签闭合符是固定的 `</>`，写 `</bold>` 之类的具名闭合标签无法被识别。
- 未注册的 `icon` id 在解析时会被静默忽略（`resolveXxx` 返回 `null`），该标签连同内容一起不显示。
- Flame 侧使用图标前必须 `await RichTextIcons.preload()`（或自行保证图片已进入 `Flame.images` 缓存），否则取图会抛异常。
- 标签内的字号样式（`t*`/`h*`）在两端都会生效，并覆盖传入的基础 `style` 的字号；未指定字号标签时继承基础样式。
