**English** | [中文](../zh/cardgame.md)

# Card Game Module

The card game module (`lib/cardgame/`) provides reusable 2D card-game primitives built on top of the core component system: a card model with pile semantics and built-in animations, a data-driven card face renderer, and two logical zone containers (deck pile and hand). It is exported from the barrel file `lib/cardgame.dart`:

```dart
import 'package:samsara/cardgame.dart';
```

Scope: this module gives you the *objects* — cards, piles, hands, drawing, flipping, dragging, focusing. It does **not** implement game rules. Win conditions, mana/cost payment, targeting, and turn structure are all up to you.

| Class | Source | Role |
| --- | --- | --- |
| `GameCard` | `lib/cardgame/card.dart` | Base card: identity, pile membership, flip/rotate/focus state, usability |
| `CustomGameCard` | `lib/cardgame/custom_card.dart` | `GameCard` with data-driven face rendering (title, cost, description, icons) |
| `PiledZone` | `lib/cardgame/zones/piled_zone.dart` | Ordered pile (deck, discard, etc.) with automatic layout |
| `DrawingZone` | `lib/cardgame/zones/drawing_zone.dart` | Hand / draw zone with reveal timing |
| `PileStyle` | `lib/cardgame/zones/piled_zone.dart` | `queue` vs `stack` ordering policy |
| `PlayingCardClassBinding` | `lib/binding/playingcard_binding.dart` | HetuScript exposure (see [Script binding](#script-binding)) |

---

## GameCard

`GameCard` (`lib/cardgame/card.dart:13`) extends `BorderComponent` and mixes in `HandlesGesture` (all pointer callbacks, see [gestures.md](gestures.md)) and `TaskController` (sequential async tasks, see the task section in [core.md](core.md)).

### Constructor

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

### Identity fields

| Field | Meaning |
| --- | --- |
| `id` | Card id — identifies the card's illustration/title. Different cards can share an id. |
| `uniqueId` | Deck-building id (`lib/cardgame/card.dart:41`). Cards with *different* ids may share a name and rules; for deck building they count as the same card toward a copy limit. Defaults to `id`. |
| `kind` | Free-form category string, e.g. `'spell'` / `'unit'`. |
| `tags` | `Set<String>` of arbitrary labels. |
| `stack` | How many physical cards this one object represents (a single object can stand in for a stack of identical cards). |
| `script` | Name of the HetuScript function backing this card. |
| `ownedByRole` / `ownedBy(player)` | Owner id and helper to test ownership. |
| `index` | Position index inside its zone, maintained by the zone — do not set it manually. |

> Note: `GameCard` also declares `GameCard? prev, next` (`lib/cardgame/card.dart:57`), but these fields are **never read or written anywhere in the library**. Pile order is tracked by the zone's `cards` list plus each card's `index`; treat `prev`/`next` as reserved/unused.

### Pile membership

A card belongs to at most one `PiledZone` at a time, referenced by `card.pile`:

```dart
void removeFromPile({bool removeFromGame = false, bool updateIndex = true})
```

This delegates to `PiledZone.removeCardByUniqueId`. `removeFromGame: true` also removes the component from the game tree; `updateIndex: false` skips re-indexing the remaining cards (useful when removing several cards in a batch, then calling `zone.updateIndices()` once).

### Flip / rotate / focus

- **Flip** is plain state, not a method: `isFlipped` is a public bool. Toggling it switches faces instantly — `CustomGameCard` renders `backSprite` when flipped and the full face otherwise. The demo flips with `card.isFlipped = !card.isFlipped`.
- **Rotate** is animated (`lib/cardgame/card.dart:249`):

  ```dart
  Future<void> rotate([bool? value, double degree = -90])
  ```

  `value == null` toggles; otherwise `true` rotates, `false` restores. Uses `RotateEffect` over 0.2 s. Default is 90° counter-clockwise. (The source doc comment says the return value reports success, but the signature returns `Future<void>` — await it to know when the animation finished.)

- **Focus** enlarges/lifts the card (`lib/cardgame/card.dart:184`):

  ```dart
  Future<void> setFocused(bool value, {double duration = 0})
  ```

  When focused, the card saves its current position/size, raises its `priority` by `focusedPriority`, and moves to `focusedPosition`, or to the saved position plus `focusedOffset`, resizing to `focusedSize` (all constructor params). With `duration > 0` the move is animated via `moveTo`; otherwise it `snapTo`s instantly. Unfocusing restores the saved position/size and calls `resetPriority()` (restores `preferredPriority`). `onFocused` / `onUnfocused` fire around the transition. If the card sits in a pile with `spreadOnFocus`, the pile shifts its neighbors aside automatically.

### Usability and enabled state

Cards can be marked usable per (state, phase) pair (`lib/cardgame/card.dart:178`):

```dart
void setUsable(String state, String phase)
```

There is no public getter — the map is private and meant to be consulted by your own rules code (or from scripts, see [Script binding](#script-binding)). Example: `card.setUsable('inHand', 'mainPhase')`.

`isEnabled = false` swaps the card's paint to a grayscale `'invalid'` paint (`kColorFilterGreyscale`), giving a dimmed "can't play this" look; setting it back to true restores the `'default'` paint.

### Gesture callbacks

From `HandlesGesture` (`lib/gestures/gesture_mixin.dart:59-94`), directly assignable on every card:

```dart
card.onTap       = (button, position) { ... };                  // void Function(int, Vector2)?
card.onDoubleTap = (button, position) { ... };
card.onDragStart = (button, position) => card;                  // returns the dragged object (HandlesGesture?)
card.onDragUpdate = (button, position, delta) { card.position += delta; };
card.onDragEnd   = (position) { ... };
card.onMouseEnter = () { ... };  card.onMouseExit = () { ... };
```

Also available: `onTapDown`, `onTapUp`, `onDragOver`, `onDragIn`, `onScaleStart/Update/End`, `onLongPress`, `onMouseHover`. Gesture handlers are skipped entirely while `enableGesture == false` or the card is invisible.

To permanently neutralize a card:

```dart
void clearInteraction()   // lib/cardgame/card.dart:301
```

This disables gestures, clears focus state, nulls `onTapUp`/`onMouseEnter`/`onMouseExit`, and resets priority.

### Animation helpers and task chaining

`GameCard` inherits from `GameComponent`:

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

Because cards mix in `TaskController`, animations on a card can be queued so they never overlap:

```dart
card.schedule(() => card.moveTo(toPosition: target, duration: 0.4));
card.schedule(() => card.rotate(true));   // runs after the move completes
```

See the task section in [core.md](core.md).

### Cloning

```dart
GameCard clone()   // lib/cardgame/card.dart:142
```

Copies identity, state and visual config but **not** gesture callbacks or `index` — wire interactions on the clone separately. The `tags` set is shared by reference.

---

## CustomGameCard

`CustomGameCard` (`lib/cardgame/custom_card.dart:38`) extends `GameCard` with a fully data-driven face: title, cost (plain or colored), rich-text description, illustration, glow, and icon slots (stack/cost/rarity/genre), all laid out from **relative rects** — fractions of the card size, so one design scales to any card size.

### Constructor (grouped)

```dart
CustomGameCard({
  // --- GameCard passthrough: id, uniqueId, index, script, kind, ownedByRole,
  // --- stack, tags, priority, position, borderRadius, anchor, focus params,
  // --- isFlipped / isRotated / isRotatable / isEnabled, onFocused / onUnfocused
  required super.id,

  // --- data & sizing
  dynamic data,                    // underlying card data (JSON-like Map or Hetu struct); may be null
  Vector2? size,                   // actual size; falls back to preferredSize
  Vector2? preferredSize,          // design size; drives fontScale = width / preferredSize.x

  // --- face content
  String? title,
  String? description,             // rich text — <red>...</> tags work (see richtext.md)
  String? illustrationSpriteId,  Sprite? illustrationSprite,
  String? backSpriteId,          Sprite? backSprite,
  String? spriteId,              Sprite? sprite,          // frame image drawn over everything
  String? glowSpriteId,          Sprite? glowSprite,
  Color? glowColor,
  String? stackIconSpriteId,     String? costIconSpriteId,
  String? rarityIconSpriteId,    String? genreIconSpriteId,
  String? descriptionBackgroundSpriteId,
  int cost = 0,
  int? modifiedCost,               // defaults to cost

  // --- text configs (see lib/paint/)
  ScreenTextConfig? titleConfig, descriptionConfig, tagsConfig,
  ScreenTextConfig? costNumberTextConfig, stackNumberTextConfig, coloredCostNumberTextConfig,

  // --- layout (all Rects are relative 0..1 fractions of card size)
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

  // --- enums
  CardTitleLayout titleLayout = CardTitleLayout.normal,
  ColoredCostDirection coloredCostDirection = ColoredCostDirection.right,
  ColoredCostLayout coloredCostLayout = ColoredCostLayout.pips,
  double coloredCostIconMargin = 0,

  // --- visibility flags (nullable bools with smart defaults, see below)
  bool showGlow = false,
  bool? showTitle, showDescription, showTags,
  bool? showStackIcon, showCostIcon, showColoredCost, showRarityIcon, showGenreIcon,
  bool showStackNumber = false, showCostNumber = false,
})
```

Visibility flags default smartly when left `null`: `showTitle` ⇔ title given, `showDescription` ⇔ description given, `showTags` ⇔ tags non-empty, `showColoredCost` ⇔ `data['coloredCost'] != null`, icon flags ⇔ the corresponding sprite was provided.

When `isFlipped` is true only `backSprite` is drawn; the entire face (illustration, description, icons, title, tags) is skipped.

### Layout enums

```dart
enum CardTitleLayout {
  normal,           // laid out inside titleRelativeRect, horizontal
  verticalRightTop, // vertical column down from the card's top-right corner, ignores titleRelativeRect
}

enum ColoredCostDirection { up, down, left, right }  // direction icons are laid out in
enum ColoredCostLayout { pips, compact }             // pips: one icon per point; compact: one icon + number
```

### Colored cost

`data['coloredCost']` is a `Map` of `colorId → amount`, where amount is either a plain number or `{'base': int, 'isDynamic': bool}`. Icons come from a **static, app-wide registry** shared by all cards:

```dart
static Future<void> registerColoredCostSprite(
  String colorId, {String? spriteId, Sprite? sprite})   // at least one of the two is required
static void unregisterColoredCostSprite(String colorId)
static final Map<String, Sprite> coloredCostSprites;    // read-only access
```

Register once at startup (after Flame images are available):

```dart
await CustomGameCard.registerColoredCostSprite('red', spriteId: 'cost_red.png');
```

Unregistered colors are skipped at render time without leaving a gap. In `pips` mode (non-dynamic) one icon is drawn per point, laid out from `coloredCostIconRelativeRect` along `coloredCostDirection` spaced by `coloredCostIconMargin` (scaled by `fontScale`); dynamic entries and `compact` mode draw a single icon with a number (`'X'` for a dynamic zero, `'$count+X'` for dynamic). If `data['originalColoredCost']` (a baseline written by your cost-evaluation code) exists, reduced amounts render yellow and increased amounts red.

When no colored cost is shown, the plain cost path renders `costIconSprite` plus `modifiedCost` as text — colored red when above `cost`, green when below, white otherwise.

### The `generateBorder()` gotcha

All relative rects and the description's rich-text layout are computed in `generateBorder()` (overridden at `lib/cardgame/custom_card.dart:496`), which the `BorderComponent` constructor runs **before** `CustomGameCard`'s own constructor body assigns `title`/`description`. If the card's final size is already known at construction, nothing re-triggers layout afterwards, and the description would be laid out against a stale/zero size.

**Pattern (taken from `example/lib/scene/cardgame_scene.dart:60`):** after constructing the card, call `generateBorder()` again before adding it to the tree:

```dart
final card = CustomGameCard(
  id: 'demo_card',
  size: cardSize,
  preferredSize: cardSize,     // enables fontScale on zoom/resize
  title: 'Card',
  description: '<red>Attack +1</>',
  titleRelativeRect: const Rect.fromLTWH(0.1, 0.02, 0.8, 0.1),
  descriptionRelativeRect: const Rect.fromLTWH(0.08, 0.64, 0.84, 0.3),
  // ...
);
// Re-run border/text layout now that the real size and content are in place,
// so the description is typeset at the card's actual width.
card.generateBorder();
world.add(card);              // onLoad() loads spriteId-based sprites
```

### Cloning

```dart
CustomGameCard clone({bool deepCopyData = false})
```

Same contract as `GameCard.clone` (no gesture callbacks, no index). `deepCopyData: true` deep-copies the underlying `data` (via Hetu's `deepCopy`) so in-match mutations don't touch the original card definition.

---

## Zones

Both zones extend `BorderComponent`. **Important:** zones are *logical* containers — their `render()` methods are commented out in source and they draw nothing (no border, no title, no cards). All visuals, including zone labels, are your scene's job (see how the demo draws "Deck (n)" / "Hand (n)" text itself). Also note neither zone is a `HandlesGesture`; interactivity is wired on the cards themselves.

### DrawingZone — the hand

`lib/cardgame/zones/drawing_zone.dart:7`. A hand/draw zone holding an externally-owned card list:

```dart
DrawingZone({
  String? ownedBy,
  Vector2? position,
  Vector2? size,
  double borderRadius = 5.0,
  int priority = 0,
  required List<GameCard> cards,          // the live hand list (shared reference)
  required Vector2 drawedCardPosition,    // where a drawn card lands
  required Vector2 drawedCardSize,        // the size it lands at
  double revealDuration = 0.5,            // delay before the draw completes
  Anchor tooltipAnchor = Anchor.topCenter,
  EdgeInsets tooltipPadding = EdgeInsets.zero,
})
```

```dart
Future<GameCard> drawOneCard({bool flip = true})   // asserts cards is not empty
```

`drawOneCard` pops the **last** card of `cards`, animates it with `moveTo` (0.6 s, `Curves.easeIn`) to `drawedCardPosition`/`drawedCardSize`, unflips it when `flip` is true, then completes after `revealDuration` seconds. It does not pick a slot for you — it always flies to the single `drawedCardPosition`, so multi-card hands position subsequent cards themselves.

### PiledZone — the pile

`lib/cardgame/zones/piled_zone.dart:22`. An ordered pile (deck, discard pile, etc.) that *does* lay out its cards:

```dart
const kPiledCardFocusedPriority = 1000;

enum PileStyle {
  queue,   // new cards go to the bottom
  stack,   // new cards go on top
}

PiledZone({
  String? ownedBy,
  String? title,                          // stored, but nothing renders it
  Vector2? position,
  Vector2? size,
  double borderRadius = 5.0,
  int priority = 0,
  int limit = -1,                         // max cards; -1 = unlimited (< -1 clamps to -1)
  List<GameCard>? cards,
  required Vector2 piledCardSize,         // every card is resized to this
  Vector2? focusedOffset, focusedPosition, focusedSize,  // propagated to member cards
  int focusedPriority = kPiledCardFocusedPriority,
  Vector2? pileStartPosition,             // layout origin override
  Vector2? pileOffset,                    // per-card offset; defaults to (0, 0)
  PileStyle pileStyle = PileStyle.stack,
  bool reverseX = false, reverseY = false,  // negate pileOffset components
  Anchor titleAnchor = Anchor.topLeft,
  EdgeInsets titlePadding = EdgeInsets.zero,
  void Function()? onPileChanged,         // fires after add/remove/reorder
  bool spreadOnFocus = false,             // push neighbors aside on focus
  double spreadMargin = 0,
  bool centerCards = false,               // center the whole pile in the zone
  int? cardBasePriority,                  // default: stack → 0, queue → 5000
  bool isVisible = true,                  // setter propagates to member cards
})
```

Core operations:

```dart
bool get isFull;                                     // limit >= 0 && cards.length >= limit
dynamic tryAddCard(GameCard card, {bool clone = false, int? index});  // override to preprocess/validate
void placeCard(GameCard card, {int? index, void Function()? onComplete});  // no animation
Future<void> sortCards({bool animated = true, int? basePriority, void Function()? onComplete, bool reversed = false});
Future<void> reorderCard(int oldIndex, int newIndex, {bool insertAndRearrangeAll = false});
void shuffle();
GameCard? removeCardByUniqueId(String uniqueId, {bool removeFromGame = false, bool updateIndex = true});
GameCard? removeCardByIndex(int index, {bool removeFromGame = false, bool updateIndex = true});
void updateIndices();                                // renumber after batch removal
Vector2 getCardNormalPosition(GameCard card, int index);
```

Semantics that matter:

- **`PileStyle.stack`** gives each card `preferredPriority = base + index` — later cards render on top; **`PileStyle.queue`** uses `base - index`. The different `cardBasePriority` defaults (0 vs 5000) keep queue piles above other elements by default.
- **`sortCards`** is the layout engine: it sorts by `index`, then moves every card (animated 0.4 s `Curves.decelerate`, or instantly when `animated: false`) to `start + index * pileOffset` and resizes it to `piledCardSize`. `start` is `pileStartPosition` if given, `(0,0)` if cards are children of the zone, otherwise the zone's own position (adjusted for negative offsets). With `centerCards`, the whole pile is additionally shifted to the zone's center.
- **`tryAddCard`** handles clone-from-template (`clone: true` clones the card and adds it to `game.world`), removes the card from any previous pile, then places it. Override it to enforce rules (e.g. `if (isFull) return false;`) — the dynamic return type lets you return a rejection reason string instead.
- **`placeCard` is fire-and-forget** — it is declared `void ... async` and never animates; call `sortCards()` afterwards if you want the pile to rearrange smoothly.
- **`removeCardByIndex`/`removeCardByUniqueId`** return the removed card (or `null`); `removeFromGame: true` also removes it from the component tree.
- **Spread on focus**: with `spreadOnFocus: true`, focusing a member card calls `setSpreadCenter`, shifting all other cards outward by half the focused size delta plus `spreadMargin` so the focused card is never covered.

### Zones render nothing — lay out cards yourself

Because zones draw nothing, *where cards sit inside a zone* is controlled by whoever positions them. `PiledZone` does it for you via `sortCards`; a hand is usually arranged manually. From the demo (`example/lib/scene/cardgame_scene.dart:22-23`):

```dart
Vector2 _handSlot(int index) =>
    Vector2(_handPos.x + 50.0 + index * 102.0, _handPos.y + 85.0);
```

Each drawn card is simply `moveTo`-ed into its slot; the `DrawingZone` only owns the list and the draw animation.

---

## Putting it together: the demo scene

`example/lib/scene/cardgame_scene.dart` shows the whole loop: a deck you click to draw from, a hand of draggable cards, double-tap to flip. Abbreviated:

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
    // 1. Build the deck: ten face-down CustomGameCards.
    final deckCards = <GameCard>[];
    for (var i = 0; i < 10; ++i) {
      final card = CustomGameCard(
        id: 'demo_card_$i',
        size: _kCardSize.clone(),
        preferredSize: _kCardSize,
        anchor: Anchor.center,
        isFlipped: true,                       // face-down in the deck
        spriteId: 'border4.png',               // frame
        illustrationSpriteId: i.isEven ? 'pepe.png' : 'glow.png',
        backSpriteId: 'attack_normal.png',
        title: 'Card $i',
        titleRelativeRect: const Rect.fromLTWH(0.1, 0.02, 0.8, 0.1),
        illustrationRelativeRect: const Rect.fromLTWH(0.08, 0.14, 0.84, 0.46),
        description: '<red>攻击 +$i</>\n<grey>demo card</>',   // rich text
        descriptionRelativeRect: const Rect.fromLTWH(0.08, 0.64, 0.84, 0.3),
      );
      card.generateBorder();    // re-layout text at the real size (see above)
      deckCards.add(card);
      world.add(card);          // must be in the tree for onLoad to load sprites
    }

    // 2. The pile: cards overlap diagonally, top card clickable.
    _deck = PiledZone(
      position: _kDeckPos.clone(),
      size: _kCardSize.clone(),
      piledCardSize: _kCardSize.clone(),
      pileStartPosition: _kDeckPos.clone(),
      pileOffset: Vector2(2.0, -2.0),
      cards: deckCards,        // sorted on load
    );
    for (final card in deckCards) {
      card.onTap = (button, position) {
        if (identical(_deck.cards.last, card)) _drawCardToHand();  // top only
      };
    }
    world.add(_deck);

    // 3. The hand: shares _handCards; the draw animation lands at slot 0.
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

    // hand interactions: double-tap flips, drag moves (priority bump
    // keeps the dragged card above the rest)
    card.onDoubleTap = (b, p) => card.isFlipped = !card.isFlipped;
    card.onDragStart = (b, p) { card.priority = 1000; return null; };
    card.onDragUpdate = (b, p, delta) => card.position += delta;
    card.onDragEnd = (p) => card.priority = card.preferredPriority;

    _handCards.add(card);
    await card.moveTo(toPosition: _handSlot(_handCards.length - 1),
        duration: 0.5, curve: Curves.decelerate);
    card.isFlipped = false;    // reveal once it arrives
  }
}
```

The scene's own `render()` draws the "Deck (n)" / "Hand (n)" labels and an `addHintText` hint when the deck runs dry — the zones themselves stay invisible.

---

## Script binding

`PlayingCardClassBinding` (`lib/binding/playingcard_binding.dart`) exposes `GameCard` instances to [HetuScript](https://hetu.dev) under the external class name `PlayingCard`. Currently the only bound member is:

```dart
card.setUsable(state, phase);   // from scripts: card.setUsable('inHand', 'mainPhase')
```

Your script-side card logic (cost evaluation, effect resolution, the `loadLocale(data)` declared in `kHetuPlayingCardBindingSource`) can therefore mark cards usable per game phase without any Dart round-trips; pair it with `GameCard.script` to associate a card with its script function.

---

## Caveats

- **Zones are logical only.** `DrawingZone.render` and `PiledZone.render` are commented out — no borders, titles, or card shadows are drawn by the zone. Draw zone frames/labels yourself (as the demo does in `Scene.render`).
- **Hand layout is manual.** `DrawingZone` flies every drawn card to the single `drawedCardPosition`; positioning multiple hand cards into slots is your code's job.
- **Call `generateBorder()` after constructing a `CustomGameCard`** whose size/content are final, or title/description text will be laid out against a stale size. See [the gotcha](#the-generateborder-gotcha) above.
- **`GameCard.prev`/`next` are dead fields** — pile order lives in `PiledZone.cards` + `index`; don't build logic on `prev`/`next`.
- **`flip` is instant state.** Only `rotate` and `setFocused` animate; if you need a flip animation, compose one yourself (e.g. scale-X tween between two `isFlipped` states).
- **`PiledZone.placeCard` does not animate** (and its future is unawaitable); call `sortCards()` for animated rearrangement. `sortCards` itself is a `TaskController`-scheduled-friendly future you can await.
- **`PiledZone` is not a gesture target** (no `HandlesGesture`); wire taps/drags on the cards.
- **Sprites load in `onLoad`** from the ids you pass (`spriteId`, `illustrationSpriteId`, `backSpriteId`, ...) — cards must be added to the component tree (e.g. `world.add(card)`) and the image files declared in your app's assets for the ids to resolve.
- **`clone()` shares `tags`** and drops gesture callbacks and `index`; re-wire interactions on clones.
- **`DrawingZone.drawOneCard` asserts a non-empty list** and always takes the last card — guard empty piles yourself.
