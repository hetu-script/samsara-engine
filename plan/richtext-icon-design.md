# 富文本内嵌图标（icon=）功能设计文档

## 1. 背景与需求

`lib/richtext/richtext_builder.dart` 包含两套平行的富文本格式化算法：

- `buildFlutterRichText()` → 产出 `List<TextSpan>`，供 Flutter 组件层使用（`Label` 等）
- `buildFlameRichText()` → 产出 Flame 的 `DocumentRoot`，供游戏内组件使用（`RichTextComponent`、`Hovertip`、`GameDialog` 等）

两者共用同一套标签语法 `<tag1 tag2 attr='value'>内容</>` 和同一个标签解析器 `_resolveTagStyle()`。

**新需求**：支持 `<icon=xxx></>` 语法，在富文本中内嵌显示自定义图标；图标资源通过类的 static 方法在游戏载入时注册（id → 资源路径）。Flame 侧与 Flutter 侧渲染结果需保持一致。

**结论：可行。** 现有架构已经为此预留了半数基础设施，改动集中在解析器收尾和两个 builder 的分支补全，不需要改变整体架构。

## 2. 现状分析

### 2.1 已有的半成品支持

| 位置 | 现状 |
| --- | --- |
| `richtext_builder.dart:173` | `_resolveTagStyle` 已能解析 `icon=` 标签，但硬编码拼成 `'text/$iconId'` 路径，语义僵硬 |
| `richtext_builder.dart:278` | Flutter builder 中 `if (tagResolveResult.icon != null) {}` 是**空分支**——图标被静默丢弃 |
| `richtext_builder.dart:342` | Flame builder 中 icon 分支**被注释掉**——图标标签被当作普通文字渲染 |
| `lib/richtext/icon_node.dart` | 已实现 `InlineIconNode` / `InlineIconElement`（Flame 侧渲染 sprite 的节点），但**未导出、未被使用** |

### 2.2 现有基础设施的问题点

1. **`InlineIconElement` 不缩放**（`icon_node.dart:60`）：直接以 sprite 原始像素尺寸作为 `LineMetrics`，不会随字号 / `fontScale` 调整。builder 的文档注释明确写了"图片会被调整为对应于文字高度的尺寸"，这是未兑现的设计意图。
2. **标签值带引号问题**：`_tagContentPattern` 的 group(0) 是完整的 `icon='sword'`（含引号），`_resolveTagStyle` 用 `substring(5)` 截取后引号仍在。`HexColor.fromString` 不剥离引号，说明 `color='#ffffffff'` 带引号写法目前实际上会抛异常——`icon=` 实现时应改用 `tagMatch.group(2)`（正则已捕获不含引号的值），顺带修复 `color=`、`link=`。
3. **空内容门槛**：两个 builder 都用 `if (taggedContent.isNotEmpty)` 包住标签解析，而图标标签通常是空内容的 `<icon=sword></>`，永远进不了分支。需要调整流程：先解析标签，再按"是否为图标"分流。
4. **Flame 图片缓存**：`InlineIconElement` 用 `Flame.images.fromCache(spriteId)`，要求图片**预先载入缓存**，否则运行时报错。注册接口需要承担预加载职责。
5. **路径体系差异**：Flame 的 `images` 缓存以 `assets/images/` 为隐含前缀（key 为 `icon/sword.png`），Flutter 的 `Image.asset` 需要完整路径 `assets/images/icon/sword.png`。注册表需要同时服务两种路径。

### 2.3 测试工程现状

- 图标资源已就位：`test/assets/images/icon/` 下有 11 个 png（sword、quest、spirit 等）
- 旧设计遗留：`test/assets/images/text/sword.png`（对应硬编码 `'text/'` 前缀的旧思路）
- **`test/pubspec.yaml` 的 assets 列表尚未包含 `assets/images/icon/`**——接入时必须补上，否则资源不会打包
- 实验入口：`test/lib/scene/mainmenu.dart:62` 已有一个 `RichTextComponent` 实例，可直接改文本做 Flame 侧验证

## 3. 设计方案

### 3.1 图标注册表（新增）

新建 `lib/richtext/icon_registry.dart`，提供 static 注册接口：

```dart
abstract class RichTextIcons {
  static final Map<String, String> _registry = {};

  /// [id] 标签中引用的图标 id；[path] 相对于 assets/images/ 的路径（含扩展名）
  static void register(String id, String path);
  static void registerAll(Map<String, String> icons);
  static void unregister(String id);
  static void clear();
  static bool contains(String id);

  /// Flame 缓存 key：path 本身（如 'icon/sword.png'）
  static String? resolveFlameKey(String id);

  /// Flutter 资源路径：'assets/images/$path'
  static String? resolveFlutterAsset(String id);

  /// 将已注册图标批量载入 Flame.images 缓存（在游戏 loading 阶段 await）
  static Future<void> preload();
}
```

要点：

- `register()` 同步、幂等，允许重复注册覆盖（热更新场景）
- `preload()` 内部对所有已注册 path 调 `Flame.images.load(path)`；未 preload 时 Flame 侧渲染给出明确错误信息而非裸异常
- 注册表不感知字号——尺寸由渲染侧按上下文决定

### 3.2 标签解析调整（richtext_builder.dart）

1. `_resolveTagStyle` 的 `icon=` 分支改为：**`TagResolveResult.icon` 直接存图标 id**（剥离引号后），不再拼 `'text/'` 前缀。路径拼接职责移交注册表。
2. 取属性值统一改用 `tagMatch.group(2) ?? group(0)` 的方式剥离引号，顺带修复 `color=`、`link=` 的引号问题。
3. 两个 builder 的循环体内调整顺序：**先解析标签得到 `TagResolveResult`，再分流**：
   - `icon != null` → 走图标分支（`taggedContent` 作为未注册时的降级显示文字，可为空）
   - 否则 `taggedContent.isNotEmpty` → 走原有文字分支

### 3.3 Flutter 侧渲染

`buildFlutterRichText()` 的图标分支：图标已注册时，向 `spanList` 添加：

```dart
WidgetSpan(
  alignment: PlaceholderAlignment.middle,
  child: Image.asset(
    RichTextIcons.resolveFlutterAsset(iconId)!,
    width: iconSize, height: iconSize,  // 默认 = 有效 fontSize
  ),
)
```

- `iconSize` 取合并后样式的 `fontSize`：`baseStyle.merge(tagStyle).fontSize ?? 14`（14 是 Flutter `TextStyle` 缺省字号）。注意标签字号会参与合并——`<h3 icon=sword></>` 的图标自动变成 32px
- 已知限制：`RichText` 会对文字应用 `MediaQuery.textScaler`，但不会缩放 `WidgetSpan` 里的图片；桌面端通常 textScaler = 1.0，接受此限制
- 未注册 id → 降级为普通文字 span 显示 `taggedContent`（内容为空则显示 `[icon:id]` 便于排查）
- `WidgetSpan` 是 `InlineSpan` 子类，可直接进入现有扁平 `spanList`，不影响段落结构

### 3.4 Flame 侧渲染

`buildFlameRichText()` 的图标分支：图标已注册时，向 `nodes` 添加 `InlineIconNode(spriteId: flameKey)`；未注册时降级为 `RichTextNode` 文字。

同时改造 `icon_node.dart`：

1. **缩放**：`InlineIconNode` 在 `fillStyles()` 阶段拿到的父样式**保证有 `fontSize`**——`DocumentStyle` 构造函数会将传入样式与 `DocumentStyle.defaultTextStyle`（fontSize 恒为 16.0，见 flame-1.38.2 `document_style.dart:128`）合并，再由 `DocumentRoot.format()` 逐层下传。因此图标边长 = `style.fontSize! * (style.fontScale ?? 1.0)`（与 `inline_text_style2.dart:14` 的实际文字渲染尺寸公式一致），无需回退值；sprite 按宽高比缩放到该边长内，`LineMetrics` 报告缩放后的尺寸
2. **基线对齐**：`LineMetrics` 设置合适的 `baseline`（建议 `baseline = 图标高度 × 0.8`，与普通文字基线接近），让图标底部与文字基线对齐（而不是顶部对齐），混排时视觉居中偏下
3. **描边重复**：`RichTextComponent` 的 outline 模式会对同一 document 二次 format，图标 sprite 会被画两次（描边对 sprite 无意义）。可在 element 中忽略 foreground 为 stroke 的样式，或接受现状（同位置重叠绘制，视觉无副作用）。建议接受现状，文档注明

### 3.5 导出

`lib/richtext.dart` barrel 增加：

```dart
export 'richtext/icon_node.dart';
export 'richtext/icon_registry.dart';
```

## 4. 测试工程接入步骤（供实际运行验证）

1. `test/pubspec.yaml` assets 增加一行：`- assets/images/icon/`
2. `test/lib/main.dart` 在 `runApp` 前注册并预加载：

```dart
RichTextIcons.registerAll({
  'sword': 'icon/sword.png',
  'quest': 'icon/quest.png',
  'spirit': 'icon/spirit.png',
  // ... 其余 8 个
});
await RichTextIcons.preload();
```

3. Flame 侧验证：修改 `mainmenu.dart:62` 的 `RichTextComponent` 文本，例如：

```
"<icon=sword></><red>攻击力</> <icon=quest></>任务\n第二行 <icon=spirit></>"
```

4. Flutter 侧验证：在场景 overlay 或现有 widget 树中加一个 `Label("<icon=sword></>物品说明文字")`，对比两侧渲染一致性

## 5. 边界情况与决策点

| 问题 | 建议 |
| --- | --- |
| 图标尺寸 | 自动跟随有效字号：`fontSize * fontScale`，正方形内等比缩放（解析链见 3.3/3.4）；预留 `size=` 显式参数作为后续扩展，`_tagContentPattern` 已支持多属性，无需改正则 |
| 未注册 id | 降级渲染为文字，不抛异常；debug 模式下输出日志 |
| 未调用 preload | Flame 侧首次渲染时检测缓存缺失，给出指向 `RichTextIcons.preload()` 的明确报错 |
| 空内容 `<icon=x></>` | 正常渲染图标（本次改造的核心路径） |
| 带内容 `<icon=x> fallback </>` | 内容仅作为未注册时的降级文字 |
| 图标与换行 | 图标作为整体参与 Flame 的行布局（`layOutNextLine` 宽度超限时换行），Flutter 侧由 `RichText` 自动处理 |
| outline 模式 | 图标不描边，接受二次绘制（见 3.4-3） |

## 6. 实施清单（预估改动量）

| 文件 | 改动 |
| --- | --- |
| `lib/richtext/icon_registry.dart` | 新增（约 60 行） |
| `lib/richtext/richtext_builder.dart` | `_resolveTagStyle` 引号处理 + icon 语义改为 id；两个 builder 的 icon 分支（各约 15 行） |
| `lib/richtext/icon_node.dart` | 缩放 + 基线对齐（约 30 行改动） |
| `lib/richtext.dart` | 两行 export |
| `test/pubspec.yaml` | 一行 assets 声明 |
| `test/lib/main.dart` | 注册 + preload（约 15 行） |
| `test/lib/scene/mainmenu.dart` | 演示文本 |

总计约 150 行，全部为增量式改动，不破坏现有 API 与标签语法。
