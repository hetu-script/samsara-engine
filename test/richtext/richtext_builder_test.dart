import 'dart:ui' as ui;

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samsara/richtext.dart';

void main() {
  test('slashes and tokenization remain intact', () {
    const source = 'A/B <red>https://example.com/a/b</> C/D';
    expect(getRichTextStream(source), [
      'A',
      '/',
      'B',
      ' ',
      '<red>https://example.com/a/b</>',
      ' ',
      'C',
      '/',
      'D',
    ]);

    final paragraphs = buildFlutterRichText(source);
    expect(paragraphs, hasLength(1));
    final spans = paragraphs.single.children!.whereType<TextSpan>().toList();
    expect(
      spans.map((span) => span.text).join(),
      'A/B https://example.com/a/b C/D',
    );
    expect(spans[1].style?.color, Colors.red);
  });

  test('multiline tags work in Flutter and Flame', () {
    const source = '<bold>first/second\nthird/fourth</>';
    final paragraphs = buildFlutterRichText(source);
    expect(paragraphs, hasLength(2));
    expect(
      paragraphs[0].children!.whereType<TextSpan>().first.text,
      'first/second',
    );
    expect(
      paragraphs[1].children!.whereType<TextSpan>().first.text,
      'third/fourth',
    );
    expect(
      paragraphs[0].children!.whereType<TextSpan>().first.style?.fontWeight,
      FontWeight.bold,
    );

    final document = buildFlameRichText(source);
    expect(document.children, hasLength(2));
  });

  test('quoted attributes and icon ids keep their values', () {
    RichTextIcons.register('verification/icon', 'icon/sword.png');
    addTearDown(() => RichTextIcons.unregister('verification/icon'));

    const source = "<color='#ffd700' link='character?name=a/b&age=18'>gold</>"
        '<icon=verification/icon></>';
    final spans = buildFlutterRichText(
      source,
      style: const TextStyle(fontSize: 18),
    ).single.children!;
    expect(
      spans.whereType<TextSpan>().single.style?.color,
      const Color(0xffffd700),
    );
    final icon = spans.whereType<WidgetSpan>().single;
    expect(icon.alignment, PlaceholderAlignment.middle);
    expect(icon.style?.fontSize, 18);

    final document = buildFlameRichText(source);
    final paragraph = document.children.single as ParagraphNode;
    final group = paragraph.child as GroupTextNode;
    expect(group.children, hasLength(2));
  });

  test('Flame icons are vertically centered within the text line', () async {
    const iconId = 'verification/centered-icon';
    const imageId = 'verification/centered-icon.png';
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 4, 4), ui.Paint());
    final image = await recorder.endRecording().toImage(4, 4);
    Flame.images.add(imageId, image);
    RichTextIcons.register(iconId, imageId);
    addTearDown(() {
      RichTextIcons.unregister(iconId);
      Flame.images.clear(imageId);
    });

    final document = buildFlameRichText('A<icon=$iconId></>A');
    final root = document.format(DocumentStyle(
      paragraph: BlockStyle(margin: EdgeInsets.zero),
      text: InlineTextStyle(fontSize: 20, height: 1.5),
      width: 300,
    ));
    final paragraph = root.children.single as GroupElement;
    final line = paragraph.children.single as GroupTextElement;
    final textMetrics = line.children.first.metrics;
    final iconMetrics = line.children[1].metrics;

    double verticalCenter(LineMetrics metrics) =>
        (metrics.top + metrics.bottom) / 2;
    expect(iconMetrics.height, 20);
    expect(
      verticalCenter(iconMetrics),
      closeTo(verticalCenter(textMetrics), 0.001),
    );
  });
}
