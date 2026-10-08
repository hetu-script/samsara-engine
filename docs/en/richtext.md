**English** | [中文](../zh/richtext.md)

# RichText

`lib/richtext/` provides a lightweight tag-based rich text framework: **the same tagged source string** can be rendered in Flutter with `RichText`, or on the Flame game canvas with the `TextNode` system — both ends share one tag syntax and produce visually consistent output.

The public API is exported through the barrel file `package:samsara/richtext.dart` (`lib/richtext.dart`): the parse/build functions, the icon registry, the `Label` widget, plus a re-export of `package:flame/text.dart` (Flame's text layout types such as `DocumentRoot`, `DocumentStyle`, and `InlineTextStyle` come from there; `GroupElement` is additionally exported by `richtext_builder.dart`).

## Tag syntax

Rich text fragments are marked up as `<tag attr='value'>content</>`. The closing tag is always written `</>`:

```dart
'A <bold red>bold red phrase</>, then back to the default style.'
'Multiple tags separated by spaces: <bold italic t5>like this</>.'
'Hex color: <color=\'#ffd700\'>gold legend</>'
'Inline icon: attack power <icon=sword></> +10'
```

Rules:

- Any number of tags may be written inside one opener, separated by spaces.
- **The closing tag must be written `</>`** and never carries a name; a named closer (e.g. `</bold>`) prevents the whole fragment from matching and is output as literal text.
- Attribute values may be single-quoted (e.g. `color='#ffd700'`, `icon='sword'`) or bare (e.g. `color=#ffd700`); **values containing spaces must be quoted**.
- Tags **do not nest** — each `<...></>` fragment is an independent flat span.
- Tag content cannot contain `<`, `/`, or `>` (enforced by the parser's character set); a fragment whose content contains `/` (e.g. `<red>and/or</>`) is not recognized as a tag and is output literally.
- Line breaks support both a real `\n` character and the literal escape sequence `\\n` (plain-text portions are converted automatically — see `StringEx.replaceAllEscapedLineBreaks` in `lib/extensions.dart`).
- If tagged content spans multiple lines, the framework splits the tags per line automatically (`_normalizeMultilineTags`), equivalent to wrapping each line in the same tags.
- Tags are matched against literals in the source and are **case-sensitive**: `<red>` works, `<RED>` is not recognized.

## Tag reference

### Text style

| Tag | Effect |
| --- | --- |
| `bold` | Bold |
| `italic` | Italic |

### Font sizes

`h*` tags are heading sizes, `t*` are body sizes; a size tag **overrides** the font size of the base style (see "Caveats"):

| Tag | Size | Tag | Size |
| --- | --- | --- | --- |
| `h1` | 24 | `t1` | 8 |
| `h2` | 28 | `t2` | 10 |
| `h3` | 32 | `t3` | 12 |
| `h4` | 36 | `t4` | 14 |
| `h5` | 40 | `t5` | 16 |
| `h6` | 44 | `t6` | 18 |
| `h7` | 48 | `t7` | 20 |

### Colors

Material color names (all map to `Colors.xxx`):

```
white black grey red pink purple deepPurple indigo blue lightBlue
cyan teal green lightGreen lime yellow amber orange deepOrange brown blueGrey
```

Rarity colors (`RankedColors`, defined in `lib/colors.dart`, handy for item rarities); the two names in each row are equivalent:

| Tag | Meaning |
| --- | --- |
| `rank0` / `common` | Common |
| `rank1` / `rare` | Rare |
| `rank2` / `epic` | Epic |
| `rank3` / `legendary` | Legendary |
| `rank4` / `mythic` | Mythic |
| `rank5` / `arcane` | Arcane |

Custom hex colors:

```dart
'<color=\'#ffd700\'>gold legend</>'
'<color=\'#ffd700cc\'>gold with alpha</>'
```

The format is `#RRGGBB` or `#RRGGBBAA` (alpha in the last two digits); the `#` prefix is optional. Parsed by `HexColor.fromString` (`lib/extensions.dart`); an invalid digit count throws an `ArgumentError`.

### Icons and links

- `icon=xxx` — inline icon, where `xxx` is an id registered in `RichTextIcons` (see "Inline icons" below). The content part is usually left empty: `<icon=sword></>`. The icon is scaled to the current text height.
- `link='xxx'` — link route, parsed in a form like `link='character?name=wendy&age=18'`. **Currently the value is only parsed into `TagResolveResult.link`; the tap gesture recognizer code is commented out and has no effect.**

## Inline icons

The mapping between icon ids and asset paths is managed by the `RichTextIcons` static registry (`lib/richtext/icon_registry.dart`). Paths are relative to `assets/images/` and must include the file extension. Register everything at game startup and preload, as in `example/lib/main.dart`:

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

// Batch-load into the Flame image cache (required for Flame-side rendering)
await RichTextIcons.preload();
```

Full registry API:

| Method | Description |
| --- | --- |
| `register(String id, String path)` | Register a single icon |
| `registerAll(Map<String, String> icons)` | Register in batch |
| `unregister(String id)` | Remove a single registration |
| `clear()` | Clear the registry |
| `contains(String id)` | Whether the id is registered |
| `resolveFlutterAsset(String id)` | Full Flutter path `assets/images/<path>`, or `null` if unregistered |
| `resolveFlameKey(String id)` | Flame image cache key (the registered `path`), or `null` if unregistered |
| `preload()` | Batch-load all registered icons into the `Flame.images` cache |

Then reference icons in rich text with `<icon=sword></>`. Rendering on each side:

- **Flutter side**: a `WidgetSpan` (`PlaceholderAlignment.middle`) + `Image.asset`, with width and height set to the merged style's `fontSize ?? 14`.
- **Flame side**: an `InlineIconNode` (`lib/richtext/icon_node.dart`); the image is fetched from the `Flame.images` cache at layout time, with height `fontSize * fontScale` (default `fontSize` 16), width scaled by the source aspect ratio, and the bottom aligned to the text baseline.

## Using it in Flutter

`buildFlutterRichText` (`lib/richtext/richtext_builder.dart`) parses the source string into a flat `List<TextSpan>` — one `TextSpan` per paragraph, paragraphs joined by `TextSpan('\n')` — which can be fed straight into `RichText`:

```dart
import 'package:samsara/richtext.dart';

RichText(
  text: TextSpan(
    children: buildFlutterRichText(
      'Loot: <epic>epic weapon</> <icon=sword></>',
      style: const TextStyle(fontSize: 14), // base style; tag styles merge onto it
    ),
  ),
)
```

Behavior notes: a `null` or empty `source` returns an empty list; tag styles merge onto the base `style`; paragraphs without a size tag inherit the base style's font size.

There is also a ready-made `Label` widget (`lib/widgets/ui/label.dart`) with mouse-hover callbacks, built on `buildFlutterRichText` + `RichText`:

```dart
Label(
  'HP: <red>120</> / 200 <icon=spirit></>',
  textStyle: const TextStyle(fontSize: 16),
  onMouseEnter: (rect) => showTooltip(rect),
  onMouseExit: hideTooltip,
)
```

Full `Label` parameters (first one is positional):

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `richTextSource` | `String` | — | Positional, the tagged source text |
| `width` / `height` | `double?` | `null` | Container size |
| `padding` | `EdgeInsetsGeometry?` | `null` | Container padding |
| `textAlign` | `TextAlign` | `TextAlign.center` | Text alignment |
| `textStyle` | `TextStyle?` | `null` | Merged on top of the default style |
| `backgroundColor` | `Color?` | `null` | Container background color |
| `cursor` | `MouseCursor` | `MouseCursor.defer` | Hover cursor |
| `onMouseEnter` | `void Function(Rect)?` | `null` | Mouse-enter callback (receives the widget's Rect) |
| `onMouseExit` | `void Function()?` | `null` | Mouse-exit callback |

The default style takes `fontFamily` / `fontSize` from `Theme.of(context).textTheme.bodySmall` and merges `textStyle` onto it. Real usage of `Label` can be seen in `example/lib/scene/mainmenu.dart` and `example/lib/scene/richtext_scene.dart`.

`LabelsWrap` is a companion flow-layout container (`ConstrainedBox` + `Wrap`) with parameters `minWidth` (default 0), `minHeight` (default 0), `padding`, and `children` — handy for a row of `Label`s.

## Using it in Flame

`buildFlameRichText` (`lib/richtext/richtext_builder.dart`) returns a Flame `DocumentRoot` with one `ParagraphNode.group` per line; icons become `InlineIconNode`s. The returned document must then be laid out via `format`, which produces a drawable `GroupElement`:

```dart
import 'package:samsara/richtext.dart';

final document = buildFlameRichText(
  'Loot: <epic>epic weapon</> <icon=sword></>',
  style: const TextStyle(fontSize: 14),
);

final element = document.format(DocumentStyle(
  paragraph: BlockStyle(margin: EdgeInsets.zero, textAlign: TextAlign.left),
  text: const TextStyle(fontSize: 14).toInlineTextStyle(fontScale: 1.0),
  width: 200,   // layout area width; text wraps automatically beyond it
  height: 100,
));

// draw it in a component's render()
element.draw(canvas);
```

**You must `await RichTextIcons.preload()` before laying out**: icon elements fetch their image via `Flame.images.fromCache` at layout time and throw if it is missing.

In most cases you should not hand-write the flow above — use `RichTextComponent` (`lib/components/ui/rich_text_component.dart`) instead. It combines `BorderComponent` + `HandlesGesture` and encapsulates building, layout, horizontal/vertical alignment, outlining, and background color:

```dart
RichTextComponent(
  size: Vector2(200, 60),
  text: 'Progress: <yellow bold>80%</>',
  fontScale: 1.2,
  config: const ScreenTextConfig(
    anchor: Anchor.center,       // vertical alignment (default topLeft)
    textAlign: TextAlign.center, // horizontal alignment (default left)
    outlined: true,              // second black stroke pass
    textStyle: TextStyle(fontSize: 14, color: Colors.white),
  ),
  backgroundColor: Colors.black54,
);
```

Constructor parameters (`size` / `position` / `anchor` / `isVisible` / `priority` are inherited from `BorderComponent`):

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `size` | `Vector2?` | `null` | Layout area size (text wraps at the `DocumentStyle` width) |
| `position` | `Vector2?` | `null` | Component position |
| `anchor` | `Anchor` | topLeft | The component's own anchor |
| `isVisible` / `priority` | — | — | Visibility and render priority |
| `text` | `String?` | `null` | Initial rich text source |
| `fontScale` | `double` | `1.0` | Global font size scale |
| `config` | `ScreenTextConfig` | `const ScreenTextConfig()` | Layout config (alignment, outline, base style, etc.) |
| `enableGesture` | `bool` | `false` | Whether to enable gestures |
| `backgroundColor` | `Color?` | `null` | Background color (`null` = transparent) |

Commonly used members:

| Member | Description |
| --- | --- |
| `text` | Getter / setter. Assigning rebuilds the document and re-lays it out; passing `null` clears the content; unchanged text skips the rebuild. |
| `layout({text, width, height, fontScale})` | Incrementally change the text or layout parameters and **force** a re-layout (even if the text is unchanged). |
| `textAreaHeight` | Read-only, the actual height of the laid-out text area (`double?`). |
| `backgroundColor` | Getter / setter, updates the background immediately. |
| `render(canvas)` / `renderAt(canvas, offset)` | Draw the background, outline, and text at the component's position / at a given offset. |

Alignment behavior: horizontal alignment is handled by `config.textAlign` through `DocumentStyle`; vertical alignment by `config.anchor` — `top*` no offset, `center*` centered, `bottom*` flush to the bottom. When `config.outlined == true`, the same document is laid out and drawn a second time with a black stroke paint (`strokeWidth` 2.5) to produce an outline effect.

## Auxiliary APIs

| API | Description |
| --- | --- |
| `getRichTextStream(String source)` | Splits the source into a token stream: each `<...></>` tag fragment is kept whole as a single token, all other text is split into single characters. Useful for typewriter-style reveal effects (example below). |
| `TextStyle.toInlineTextStyle({double? fontScale})` | Extension (`lib/richtext/textstyle_extension.dart`): Flutter `TextStyle` → Flame `InlineTextStyle`, mapping color, font size, weight, shadows, and more. |
| `InlineTextStyle.asTextStyle2()` / `asTextRenderer2()` | Extensions (`lib/richtext/inline_text_style2.dart`, exported by the barrel): Flame `InlineTextStyle` back to Flutter `TextStyle` / `TextPaint`, applying the `fontSize * fontScale` conversion. |
| `RichTextNode` | Flame `InlineTextNode` subclass (`lib/richtext/richtext_node.dart`) that greedily wraps per character (`characters`). |
| `InlineIconNode` / `InlineIconElement` | Flame-side inline icon node and laid-out element (`lib/richtext/icon_node.dart`). |
| `TagResolveResult` | Tag parse result (`icon` / `link` / `style`); mostly for internal use. |

Typewriter example:

```dart
final tokens = getRichTextStream('Loot: <epic>epic weapon</>!');
// ['L', 'o', 'o', 't', ':', ' ', '<epic>epic weapon</>', '!']
// The consumer re-joins tokens progressively and hands the result to
// RichTextComponent / Label, yielding a per-character typewriter that
// still respects tag styling.
```

## Caveats

- The closing tag is always `</>`; a named closer (`</bold>`) prevents the whole fragment from matching and is output literally.
- Tags are case-sensitive; camelCase color names (e.g. `deepPurple`, `lightBlue`) must be written exactly as in the tables.
- An unregistered `icon` id: `resolveXxx` returns `null`; if the content is empty the whole tag produces nothing, but if the content is non-empty the content is still rendered with the merged style (just without the icon).
- You must `await RichTextIcons.preload()` before rendering icons on the Flame side (or otherwise ensure the images are in the `Flame.images` cache); otherwise image fetch throws at layout time.
- Size tags (`t*` / `h*`) override the font size of the passed-in base `style` on both sides; without a size tag the base style is inherited.
- `link=` is parsed but not clickable (recognizer code is commented out).
- The `color=` format is `#RRGGBB` or `#RRGGBBAA` (alpha last — not `#AARRGGBB`); an invalid digit count throws an `ArgumentError`.
- With `asTextStyle2()` / `asTextRenderer2()`, a null `InlineTextStyle.fontSize` is passed through as-is (no scaling applied); set `fontSize` when you need the `fontScale` multiplication.
- Tag content cannot contain `<`, `/`, or `>`; fragments whose content contains `/` are not recognized as tags.

## Runnable demo

The example project includes `example/lib/scene/richtext_scene.dart` (`RichTextScene`, registered with the id `'richtext'` in `example/lib/app.dart`), which demonstrates both ends sharing the same tag syntax: `RichTextComponent` on the Flame side and `Label` on the Flutter side, covering bold/italic, font sizes, colors, rarity colors, inline icons, and multiline text. Icon registration and preload live in `example/lib/main.dart`.
