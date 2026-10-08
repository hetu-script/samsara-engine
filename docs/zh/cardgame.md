[English](../en/cardgame.md) | **中文**

# 卡牌游戏模块

卡牌模块（`lib/cardgame/`）基于核心组件系统提供了一套可复用的 2D 卡牌游戏原语：带牌堆语义和内置动画的卡牌模型、数据驱动的卡面渲染，以及两个逻辑区域容器（牌堆与手牌区）。公开 API 由桶文件 `lib/cardgame.dart` 导出：

```dart
import 'package:samsara/cardgame.dart';
```

**适用范围**：本模块提供的是"对象"——卡牌、牌堆、手牌、抽牌、翻转、拖动、聚焦。它**不实现游戏规则**。胜利条件、费用支付、指定目标、回合结构等都需要自行实现。

| 类 | 源码位置 | 作用 |
| --- | --- | --- |
| `GameCard` | `lib/cardgame/card.dart` | 卡牌基类：身份标识、牌堆归属、翻转/旋转/聚焦状态、可用性 |
| `CustomGameCard` | `lib/cardgame/custom_card.dart` | 数据驱动卡面渲染的 `GameCard`（标题、费用、描述、图标） |
| `PiledZone` | `lib/cardgame/zones/piled_zone.dart` | 有序牌堆（卡组、弃牌堆等），自动布局 |
| `DrawingZone` | `lib/cardgame/zones/drawing_zone.dart` | 手牌/抽牌区，带揭示时长 |
| `PileStyle` | `lib/cardgame/zones/piled_zone.dart` | `queue` 与 `stack` 两种排序策略 |
| `PlayingCardClassBinding` | `lib/binding/playingcard_binding.dart` | 河图脚本绑定（见 [脚本绑定](#脚本绑定)） |

---

## GameCard

`GameCard`（`lib/cardgame/card.dart:13`）继承 `BorderComponent`，并混入 `HandlesGesture`（全部指针回调，见 [gestures.md](gestures.md)）与 `TaskController`（串行异步任务，见 [core.md](core.md) 的任务章节）。

### 构造函数

```dart
GameCard({
  required String id,
  String? uniqueId,
  int index = 0,
  String? script,
  String? kind,
  String? ownedByRole,
  int stack = 1,
  String? spriteId,
  Sprite? sprite,
  Set<String>? tags,
  Vector2? position,
  Vector2? size,
  double borderRadius = 0.0,
  Anchor anchor = Anchor.topLeft,
  int priority = 0,
  Vector2? focusedOffset,
  Vector2? focusedPosition,
  Vector2? focusedSize,
  int focusedPriority = 0,
  bool showBorder = false,
  bool isFocused = false,
  bool stayFocused = false,
  bool isFlipped = false,
  bool isRotated = false,
  bool isRotatable = false,
  bool isEnabled = true,
  bool enableGesture = true,
  int? preferredPriority,
  void Function()? onFocused,
  void Function()? onUnfocused,
})
```

### 身份字段

| 字段 | 含义 |
| --- | --- |
| `id` | 卡牌 id——对应插画与标题。不同的卡可以共用同一个 id。 |
| `uniqueId` | 组牌 id（`lib/cardgame/card.dart:41`）。不同 id 的卡可能拥有相同的名字和规则效果；组牌时它们被视作同一张卡，共享数量上限。默认为 `id`。 |
| `kind` | 自由分类字符串，如 `'spell'` / `'unit'`。 |
| `tags` | 任意标签的 `Set<String>`。 |
| `stack` | 这一张对象代表几张实体卡（一个对象即可代表一叠同名卡）。 |
| `script` | 该卡对应的河图脚本函数名。 |
| `ownedByRole` / `ownedBy(player)` | 持有者 id 及归属判断辅助方法。 |
| `index` | 在所属区域内的位置索引，由区域维护——请勿手动设置。 |

> 注意：`GameCard` 还声明了 `GameCard? prev, next` 字段（`lib/cardgame/card.dart:57`），但这两个字段在库中**从未被读写**。牌堆顺序由区域的 `cards` 列表加上每张卡的 `index` 维护；请把 `prev`/`next` 视为保留的无效字段。

### 牌堆归属

一张卡同一时刻至多属于一个 `PiledZone`，通过 `card.pile` 引用：

```dart
void removeFromPile({bool removeFromGame = false, bool updateIndex = true})
```

该方法委托给 `PiledZone.removeCardByUniqueId`。`removeFromGame: true` 会同时把组件从游戏树上移除；`updateIndex: false` 跳过剩余卡片的重新编号（批量移除时好用：多次传 `false`，最后统一调用一次 `zone.updateIndices()`）。

### 翻转 / 旋转 / 聚焦

- **翻转是纯状态，不是方法**：`isFlipped` 是公开的 bool，切换后瞬间换面——`CustomGameCard` 在翻转时绘制 `backSprite`，否则绘制完整卡面。示例中的写法是 `card.isFlipped = !card.isFlipped`。
- **旋转有动画**（`lib/cardgame/card.dart:249`）：

  ```dart
  Future<void> rotate([bool? value, double degree = -90])
  ```

  `value == null` 时切换状态；否则 `true` 旋转、`false` 恢复。内部使用 `RotateEffect`，时长 0.2 秒。默认为逆时针 90°。（源码注释说返回值表示是否旋转成功，但实际签名返回 `Future<void>`——如需知道动画结束时机请 `await` 它。）

- **聚焦**放大/浮起卡牌（`lib/cardgame/card.dart:184`）：

  ```dart
  Future<void> setFocused(bool value, {double duration = 0})
  ```

  聚焦时，卡牌保存当前位置/尺寸，`priority` 增加 `focusedPriority`，然后移动到 `focusedPosition`，或保存位置加 `focusedOffset`，并缩放到 `focusedSize`（均为构造参数）。`duration > 0` 时用 `moveTo` 播放动画，否则用 `snapTo` 瞬移。取消聚焦时恢复保存的位置/尺寸并调用 `resetPriority()`（恢复 `preferredPriority`）。过渡前后触发 `onFocused` / `onUnfocused`。若卡牌处于 `spreadOnFocus` 的牌堆中，聚焦时牌堆会自动把相邻卡牌推开。

### 可用性与启用状态

卡牌可按（状态，阶段）对标记可用性（`lib/cardgame/card.dart:178`）：

```dart
void setUsable(String state, String phase)
```

该映射没有公开的读取接口——它是私有字段，由你自己的规则代码（或脚本，见[脚本绑定](#脚本绑定)）查询。例如：`card.setUsable('inHand', 'mainPhase')`。

`isEnabled = false` 会把卡牌画刷切换为灰度的 `'invalid'` 画刷（`kColorFilterGreyscale`），呈现"不可使用"的暗淡效果；重新设为 `true` 时恢复 `'default'` 画刷。

### 手势回调

来自 `HandlesGesture`（`lib/gestures/gesture_mixin.dart:59-94`），可直接赋值在每张卡上：

```dart
card.onTap       = (button, position) { ... };                  // void Function(int, Vector2)?
card.onDoubleTap = (button, position) { ... };
card.onDragStart = (button, position) => card;                  // 返回被拖动的对象（HandlesGesture?）
card.onDragUpdate = (button, position, delta) { card.position += delta; };
card.onDragEnd   = (position) { ... };
card.onMouseEnter = () { ... };  card.onMouseExit = () { ... };
```

还可使用：`onTapDown`、`onTapUp`、`onDragOver`、`onDragIn`、`onScaleStart/Update/End`、`onLongPress`、`onMouseHover`。当 `enableGesture == false` 或卡牌不可见时，手势处理会被整体跳过。

若要彻底禁用一张卡的交互：

```dart
void clearInteraction()   // lib/cardgame/card.dart:301
```

它会禁用手势、清除聚焦状态、置空 `onTapUp`/`onMouseEnter`/`onMouseExit`，并重置优先级。

### 动画辅助与任务链

`GameCard` 继承自 `GameComponent`：

```dart
Future<void> moveTo({
  Vector2? toPosition,
  Vector2? toSize,
  double? toAngle,
  bool clockwise = true,
  required double duration,
  double delay = 0.0,
  Curve curve = Curves.linear,
  void Function()? onChange,
  void Function()? onComplete,
})                              // lib/components/game_component.dart:145

void snapTo({Vector2? toPosition, Vector2? toSize, double? toDegree })
                                // lib/components/game_component.dart:118
```

由于卡牌混入了 `TaskController`，动画可以排队执行、互不重叠：

```dart
card.schedule(() => card.moveTo(toPosition: target, duration: 0.4));
card.schedule(() => card.rotate(true));   // 移动完成后才执行
```

参见 [core.md](core.md) 的任务章节。

### 克隆

```dart
GameCard clone()   // lib/cardgame/card.dart:142
```

复制身份、状态与视觉配置，但**不复制**手势回调和 `index`——克隆后需要重新接线交互。`tags` 集合按引用共享。

---

## CustomGameCard

`CustomGameCard`（`lib/cardgame/custom_card.dart:38`）在 `GameCard` 基础上提供完全数据驱动的卡面：标题、费用（普通或彩色）、富文本描述、插画、光晕，以及若干图标槽位（堆叠/费用/稀有度/类型），全部通过**相对矩形**布局——即占卡牌宽高比例的分数，因此一套设计可缩放到任意卡牌尺寸。

### 构造函数（分组节选）

```dart
CustomGameCard({
  // --- GameCard 透传：id、uniqueId、index、script、kind、ownedByRole、
  // --- stack、tags、priority、position、borderRadius、anchor、聚焦参数、
  // --- isFlipped / isRotated / isRotatable / isEnabled、onFocused / onUnfocused
  required super.id,

  // --- 数据与尺寸
  dynamic data,                    // 卡牌底层数据（类 JSON 的 Map 或河图 struct），可为 null
  Vector2? size,                   // 实际尺寸；缺省回退到 preferredSize
  Vector2? preferredSize,          // 设计尺寸；驱动 fontScale = width / preferredSize.x

  // --- 卡面内容
  String? title,
  String? description,             // 富文本——<red>...</> 等标签有效（见 richtext.md）
  String? illustrationSpriteId,  Sprite? illustrationSprite,
  String? backSpriteId,          Sprite? backSprite,
  String? spriteId,              Sprite? sprite,          // 覆盖在最上层的卡框图
  String? glowSpriteId,          Sprite? glowSprite,
  Color? glowColor,
  String? stackIconSpriteId,     String? costIconSpriteId,
  String? rarityIconSpriteId,    String? genreIconSpriteId,
  String? descriptionBackgroundSpriteId,
  int cost = 0,
  int? modifiedCost,               // 默认为 cost

  // --- 文本配置（见 lib/paint/）
  ScreenTextConfig? titleConfig, descriptionConfig, tagsConfig,
  ScreenTextConfig? costNumberTextConfig, stackNumberTextConfig, coloredCostNumberTextConfig,

  // --- 布局（所有 Rect 均为占卡牌尺寸的 0..1 相对比例）
  Rect illustrationRelativeRect = Rect.zero,
  Rect titleRelativeRect = Rect.zero,
  Rect descriptionRelativeRect = Rect.zero,
  Rect tagsRelativeRect = Rect.zero,
  Rect stackIconRelativeRect = Rect.zero,
  Rect costIconRelativeRect = Rect.zero,
  Rect rarityIconRelativeRect = Rect.zero,
  Rect genreIconRelativeRect = Rect.zero,
  Rect coloredCostIconRelativeRect = Rect.zero,
  String tagsSeparator = ' ',

  // --- 枚举
  CardTitleLayout titleLayout = CardTitleLayout.normal,
  ColoredCostDirection coloredCostDirection = ColoredCostDirection.right,
  ColoredCostLayout coloredCostLayout = ColoredCostLayout.pips,
  double coloredCostIconMargin = 0,

  // --- 显隐开关（可空 bool，缺省按内容自动推断，见下文）
  bool showGlow = false,
  bool? showTitle, showDescription, showTags,
  bool? showStackIcon, showCostIcon, showColoredCost, showRarityIcon, showGenreIcon,
  bool showStackNumber = false, showCostNumber = false,
})
```

显隐开关传 `null` 时按内容自动推断：`showTitle` ⇔ 提供了 title，`showDescription` ⇔ 提供了 description，`showTags` ⇔ tags 非空，`showColoredCost` ⇔ `data['coloredCost'] != null`，各图标开关 ⇔ 提供了对应 sprite。

`isFlipped` 为 true 时只绘制 `backSprite`，整个卡面（插画、描述、图标、标题、标签）全部跳过。

### 布局枚举

```dart
enum CardTitleLayout {
  normal,           // 按 titleRelativeRect 横排
  verticalRightTop, // 从卡牌右上角向下竖排，忽略 titleRelativeRect
}

enum ColoredCostDirection { up, down, left, right }  // 图标排列方向
enum ColoredCostLayout { pips, compact }             // pips：每点一个图标；compact：单图标 + 数字
```

### 彩色费用

`data['coloredCost']` 是 `Map`，形如 `颜色id → 数量`；数量可以是纯数字，也可以是 `{'base': int, 'isDynamic': bool}`。图标来自一个**静态的、应用级共享注册表**：

```dart
static Future<void> registerColoredCostSprite(
  String colorId, {String? spriteId, Sprite? sprite})   // 两者至少提供一个
static void unregisterColoredCostSprite(String colorId)
static final Map<String, Sprite> coloredCostSprites;    // 只读访问
```

在启动时（Flame 图片加载就绪后）注册一次：

```dart
await CustomGameCard.registerColoredCostSprite('red', spriteId: 'cost_red.png');
```

未注册的颜色在渲染时跳过且不留空位。`pips` 模式（非动态）下每点绘制一个图标，从 `coloredCostIconRelativeRect` 出发沿 `coloredCostDirection` 按 `coloredCostIconMargin` 间隔排列（间隔随 `fontScale` 缩放）；动态条目与 `compact` 模式绘制单个图标加数字（动态 0 显示 `'X'`，动态非 0 显示 `'$count+X'`）。若存在 `data['originalColoredCost']`（由你的费用求值代码写入的基线），数量相对基线减少标黄、增加标红。

没有彩色费用可显示时，走普通费用路径：绘制 `costIconSprite` 并以文本显示 `modifiedCost`——高于 `cost` 标红、低于 `cost` 标绿、相等为白色。

### `generateBorder()` 陷阱

所有相对矩形与描述的富文本排版都在 `generateBorder()` 中计算（`lib/cardgame/custom_card.dart:496` 重写），而 `BorderComponent` 构造函数在 `CustomGameCard` 自身构造体给 `title`/`description` 赋值**之前**就调用了它。如果卡牌的最终尺寸在构造时已知，之后没有任何东西会再次触发布局，描述就会按过期（或零）尺寸排版。

**推荐写法（取自 `example/lib/scene/cardgame_scene.dart:60`）**：构造完成后、加入组件树之前，再手动调用一次 `generateBorder()`：

```dart
final card = CustomGameCard(
  id: 'demo_card',
  size: cardSize,
  preferredSize: cardSize,     // 缩放/聚焦时启用 fontScale
  title: 'Card',
  description: '<red>Attack +1</>',
  titleRelativeRect: const Rect.fromLTWH(0.1, 0.02, 0.8, 0.1),
  descriptionRelativeRect: const Rect.fromLTWH(0.08, 0.64, 0.84, 0.3),
  // ...
);
// 尺寸与内容就位后重新生成边框区域，
// 让描述文本按卡牌实际宽度排版。
card.generateBorder();
world.add(card);              // onLoad() 会按 spriteId 加载各 sprite
```

### 克隆

```dart
CustomGameCard clone({bool deepCopyData = false})
```

契约与 `GameCard.clone` 相同（不复制手势回调与 `index`）。`deepCopyData: true` 会深拷贝底层 `data`（借助河图的 `deepCopy`），对局中的数据修改不会影响原始卡牌定义。

---

## 区域（Zones）

两个区域都继承 `BorderComponent`。**重点**：区域只是*逻辑*容器——它们的 `render()` 在源码中已被注释掉，什么都不会绘制（没有边框、没有标题、没有卡牌）。所有视觉效果，包括区域标签，都要由场景自己负责（示例就是在 `Scene.render` 里自行绘制 "Deck (n)" / "Hand (n)" 文字的）。另外注意两个区域都不是 `HandlesGesture`；交互请接线在卡牌上。

### DrawingZone——手牌区

`lib/cardgame/zones/drawing_zone.dart:7`。持有一个外部所有的卡牌列表，作为手牌/抽牌区：

```dart
DrawingZone({
  String? ownedBy,
  Vector2? position,
  Vector2? size,
  double borderRadius = 5.0,
  int priority = 0,
  required List<GameCard> cards,          // 共享引用的实时手牌列表
  required Vector2 drawedCardPosition,    // 抽出的牌落点
  required Vector2 drawedCardSize,        // 落点处的尺寸
  double revealDuration = 0.5,            // 抽牌完成前的延迟
  Anchor tooltipAnchor = Anchor.topCenter,
  EdgeInsets tooltipPadding = EdgeInsets.zero,
})
```

```dart
Future<GameCard> drawOneCard({bool flip = true})   // 断言 cards 非空
```

`drawOneCard` 弹出 `cards` 的**最后一张**，用 `moveTo` 播动画（0.6 秒，`Curves.easeIn`）飞到 `drawedCardPosition`/`drawedCardSize`，`flip` 为 true 时翻开，之后延迟 `revealDuration` 秒完成。它不会替你选槽位——总是飞向唯一的 `drawedCardPosition`，多张手牌时后续位置需要自行布局。

### PiledZone——牌堆

`lib/cardgame/zones/piled_zone.dart:22`。有序牌堆（卡组、弃牌堆等），它*会*为卡牌排版：

```dart
const kPiledCardFocusedPriority = 1000;

enum PileStyle {
  queue,   // 新牌放到牌堆底部
  stack,   // 新牌放到牌堆顶
}

PiledZone({
  String? ownedBy,
  String? title,                          // 仅保存，无任何渲染
  Vector2? position,
  Vector2? size,
  double borderRadius = 5.0,
  int priority = 0,
  int limit = -1,                         // 卡牌数量上限；-1 为不限（<-1 会收敛为 -1）
  List<GameCard>? cards,
  required Vector2 piledCardSize,         // 所有卡牌统一缩放到该尺寸
  Vector2? focusedOffset, focusedPosition, focusedSize,  // 会传播给成员卡牌
  int focusedPriority = kPiledCardFocusedPriority,
  Vector2? pileStartPosition,             // 布局起点覆盖
  Vector2? pileOffset,                    // 每张牌相对上一张的位移；默认 (0, 0)
  PileStyle pileStyle = PileStyle.stack,
  bool reverseX = false, reverseY = false,  // 取反 pileOffset 对应分量
  Anchor titleAnchor = Anchor.topLeft,
  EdgeInsets titlePadding = EdgeInsets.zero,
  void Function()? onPileChanged,         // 增/删/排序后触发
  bool spreadOnFocus = false,             // 聚焦时推开相邻卡牌
  double spreadMargin = 0,
  bool centerCards = false,               // 整堆在区域内居中
  int? cardBasePriority,                  // 默认：stack → 0，queue → 5000
  bool isVisible = true,                  // setter 会传播给成员卡牌
})
```

核心操作：

```dart
bool get isFull;                                     // limit >= 0 && cards.length >= limit
dynamic tryAddCard(GameCard card, {bool clone = false, int? index});  // 重写以预处理/校验
void placeCard(GameCard card, {int? index, void Function()? onComplete});  // 无动画
Future<void> sortCards({bool animated = true, int? basePriority, void Function()? onComplete, bool reversed = false});
Future<void> reorderCard(int oldIndex, int newIndex, {bool insertAndRearrangeAll = false});
void shuffle();
GameCard? removeCardByUniqueId(String uniqueId, {bool removeFromGame = false, bool updateIndex = true});
GameCard? removeCardByIndex(int index, {bool removeFromGame = false, bool updateIndex = true});
void updateIndices();                                // 批量移除后统一重新编号
Vector2 getCardNormalPosition(GameCard card, int index);
```

需要注意的语义：

- **`PileStyle.stack`** 给每张卡 `preferredPriority = base + index`——靠后的卡牌渲染在上层；**`PileStyle.queue`** 使用 `base - index`。`cardBasePriority` 默认值不同（0 与 5000），是为了让队列式牌堆默认位于其他元素之上。
- **`sortCards`** 是布局引擎：按 `index` 排序后，把每张卡移动（动画 0.4 秒 `Curves.decelerate`，`animated: false` 时瞬移）到 `起点 + index * pileOffset` 并缩放到 `piledCardSize`。起点取 `pileStartPosition`；卡牌是区域子节点时取 `(0,0)`；否则取区域自身位置（负偏移时做相应调整）。`centerCards` 开启后整堆还会额外平移到区域中心。
- **`tryAddCard`** 处理模板克隆（`clone: true` 时克隆卡牌并加入 `game.world`）、把卡牌从原牌堆移除，然后放置。可重写它以实现规则校验（如 `if (isFull) return false;`）——返回类型为 dynamic，你也可以返回字符串说明拒绝原因。
- **`placeCard` 是"发了不管"**——它声明为 `void ... async`，不播动画；如需牌堆平滑重排，请随后调用 `sortCards()`。
- **`removeCardByIndex`/`removeCardByUniqueId`** 返回被移除的卡牌（失败返回 `null`）；`removeFromGame: true` 会同时把它从组件树上移除。
- **聚焦散开**：开启 `spreadOnFocus: true` 后，成员卡牌聚焦会触发 `setSpreadCenter`，把其余卡牌向外推开"聚焦尺寸差的一半 + `spreadMargin`"，保证聚焦卡不被遮挡。

### 区域不渲染任何东西——卡牌位置自己排

由于区域什么都不画，*卡牌在区域内的位置*由负责摆放的一方决定。`PiledZone` 通过 `sortCards` 自动完成；手牌通常手动排列。示例中的做法（`example/lib/scene/cardgame_scene.dart:22-23`）：

```dart
Vector2 _handSlot(int index) =>
    Vector2(_handPos.x + 50.0 + index * 102.0, _handPos.y + 85.0);
```

每张抽到的牌只是被 `moveTo` 到自己的槽位；`DrawingZone` 只持有列表与抽牌动画。

---

## 串起来：示例场景讲解

`example/lib/scene/cardgame_scene.dart` 演示了完整流程：点击牌堆抽牌、手牌可拖动、双击翻转。节略版：

```dart
class CardGameScene extends Scene {
  static final _kCardSize = Vector2(90.0, 126.0);
  static final _kDeckPos = Vector2(180.0, 360.0);
  static final _kHandPos = Vector2(380.0, 560.0);

  late final PiledZone _deck;
  final List<GameCard> _handCards = [];

  Vector2 _handSlot(int index) =>
      Vector2(_kHandPos.x + 50.0 + index * 102.0, _kHandPos.y + 85.0);

  @override
  Future<void> onLoad() async {
    // 1. 构造牌堆：十张背面朝上的 CustomGameCard。
    final deckCards = <GameCard>[];
    for (var i = 0; i < 10; ++i) {
      final card = CustomGameCard(
        id: 'demo_card_$i',
        size: _kCardSize.clone(),
        preferredSize: _kCardSize,
        anchor: Anchor.center,
        isFlipped: true,                       // 牌堆里背面朝上
        spriteId: 'border4.png',               // 卡框
        illustrationSpriteId: i.isEven ? 'pepe.png' : 'glow.png',
        backSpriteId: 'attack_normal.png',
        title: 'Card $i',
        titleRelativeRect: const Rect.fromLTWH(0.1, 0.02, 0.8, 0.1),
        illustrationRelativeRect: const Rect.fromLTWH(0.08, 0.14, 0.84, 0.46),
        description: '<red>攻击 +$i</>\n<grey>demo card</>',   // 富文本
        descriptionRelativeRect: const Rect.fromLTWH(0.08, 0.64, 0.84, 0.3),
      );
      card.generateBorder();    // 按真实尺寸重新布局（见上文陷阱）
      deckCards.add(card);
      world.add(card);          // 必须加入组件树，onLoad 才会加载图片
    }

    // 2. 牌堆：卡牌斜向重叠，只有顶牌响应点击。
    _deck = PiledZone(
      position: _kDeckPos.clone(),
      size: _kCardSize.clone(),
      piledCardSize: _kCardSize.clone(),
      pileStartPosition: _kDeckPos.clone(),
      pileOffset: Vector2(2.0, -2.0),
      cards: deckCards,        // 加载时自动 sortCards
    );
    for (final card in deckCards) {
      card.onTap = (button, position) {
        if (identical(_deck.cards.last, card)) _drawCardToHand();  // 仅顶牌
      };
    }
    world.add(_deck);

    // 3. 手牌区：共享 _handCards；抽牌动画落在 0 号槽位。
    world.add(DrawingZone(
      position: _kHandPos.clone(),
      size: Vector2(1010.0, 170.0),
      cards: _handCards,
      drawedCardPosition: _handSlot(0),
      drawedCardSize: _kCardSize.clone(),
    ));
  }

  Future<void> _drawCardToHand() async {
    if (_deck.cards.isEmpty || _handCards.length >= 10) return;
    final card = _deck.removeCardByIndex(_deck.cards.length - 1);
    if (card == null) return;

    // 手牌交互：双击翻转，拖动移动（临时抬高 priority 避免被遮挡）
    card.onDoubleTap = (b, p) => card.isFlipped = !card.isFlipped;
    card.onDragStart = (b, p) { card.priority = 1000; return null; };
    card.onDragUpdate = (b, p, delta) => card.position += delta;
    card.onDragEnd = (p) => card.priority = card.preferredPriority;

    _handCards.add(card);
    await card.moveTo(toPosition: _handSlot(_handCards.length - 1),
        duration: 0.5, curve: Curves.decelerate);
    card.isFlipped = false;    // 到位后翻开
  }
}
```

场景自己的 `render()` 绘制 "Deck (n)" / "Hand (n)" 标签，牌堆抽空时用 `addHintText` 给出提示——区域本身保持不可见。

---

## 脚本绑定

`PlayingCardClassBinding`（`lib/binding/playingcard_binding.dart`）以 external class 名 `PlayingCard` 将 `GameCard` 实例暴露给 [河图脚本（HetuScript）](https://hetu.dev)。目前唯一绑定的成员是：

```dart
card.setUsable(state, phase);   // 脚本侧：card.setUsable('inHand', 'mainPhase')
```

因此脚本端的卡牌逻辑（费用求值、效果结算，`kHetuPlayingCardBindingSource` 中声明的 `loadLocale(data)` 等）可以直接按游戏阶段标记卡牌可用性，无需回到 Dart 层；配合 `GameCard.script` 即可把卡牌与其脚本函数关联起来。

---

## 注意事项

- **区域纯属逻辑容器**。`DrawingZone.render` 与 `PiledZone.render` 均已注释——区域不绘制边框、标题或卡牌投影。区域框与标签请自行绘制（示例在 `Scene.render` 中处理）。
- **手牌布局需手动**。`DrawingZone` 只把每张抽到的牌飞向唯一的 `drawedCardPosition`；多张手牌排槽由你的代码负责。
- **`CustomGameCard` 构造完成后请调用 `generateBorder()`**，否则标题/描述文本会按过期尺寸排版。见上文[陷阱](#generateborder-陷阱)。
- **`GameCard.prev`/`next` 是死字段**——牌堆顺序由 `PiledZone.cards` + `index` 维护；不要基于 `prev`/`next` 写逻辑。
- **翻转是瞬时的**。只有 `rotate` 和 `setFocused` 有动画；如需翻牌动画，请自行组合（例如在切换 `isFlipped` 前后加一个 X 轴缩放补间）。
- **`PiledZone.placeCard` 不播动画**（其 Future 也无法 await）；需要平滑重排请调用 `sortCards()`。`sortCards` 返回的 Future 可以 await，也适合交给 `TaskController` 调度。
- **`PiledZone` 不是手势目标**（没有 `HandlesGesture`）；点击/拖动请接线在卡牌上。
- **图片在 `onLoad` 中按传入的 id 加载**（`spriteId`、`illustrationSpriteId`、`backSpriteId` 等）——卡牌必须加入组件树（如 `world.add(card)`），且对应图片文件需在应用的 assets 中声明，id 才能解析成功。
- **`clone()` 共享 `tags`**，且丢弃手势回调与 `index`；克隆体需要重新接线交互。
- **`DrawingZone.drawOneCard` 断言列表非空**，且永远取最后一张——空牌堆请自行判空。
