import 'package:flutter/material.dart';
import 'package:flame/text.dart';

import 'textstyle_extension.dart';
import 'richtext_node.dart';
import 'icon_node.dart';
import 'icon_registry.dart';
import '../extensions.dart';
import '../colors.dart';

export 'package:flame/src/text/elements/group_element.dart';

abstract class _FontSize {
  static const double t1 = 8;
  static const double t2 = 10;
  static const double t3 = 12;
  static const double t4 = 14;
  static const double t5 = 16;
  static const double t6 = 18;
  static const double t7 = 20;
  static const double h1 = 24;
  static const double h2 = 28;
  static const double h3 = 32;
  static const double h4 = 36;
  static const double h5 = 40;
  static const double h6 = 44;
  static const double h7 = 48;
}

final _tagPattern = RegExp(
  r'<(?<tags>[^<>\r\n]*)>(?<content>[^<>]*)</>',
  unicode: true,
);

final _tagContentPattern = RegExp(
  r"([^\s=]+)(?:='([^']*)'|=([^\s]*))?",
  unicode: true,
);

class _RichTextSegment {
  const _RichTextSegment.text(String text)
      : source = text,
        tags = null,
        content = null;

  const _RichTextSegment.tag({
    required this.source,
    required this.tags,
    required this.content,
  });

  final String source;
  final String? tags;
  final String? content;

  bool get isTag => tags != null;
}

Iterable<_RichTextSegment> _parseRichText(String source) sync* {
  if (source.isEmpty) {
    yield const _RichTextSegment.text('');
    return;
  }

  var lastEnd = 0;

  for (final match in _tagPattern.allMatches(source)) {
    if (match.start > lastEnd) {
      yield _RichTextSegment.text(source.substring(lastEnd, match.start));
    }
    yield _RichTextSegment.tag(
      source: match.group(0)!,
      tags: match.namedGroup('tags')!,
      content: match.namedGroup('content')!,
    );
    lastEnd = match.end;
  }

  if (lastEnd < source.length) {
    yield _RichTextSegment.text(source.substring(lastEnd));
  }
}

List<String> getRichTextStream(String source) {
  final tokens = <String>[];

  for (final segment in _parseRichText(source)) {
    if (segment.isTag) {
      tokens.add(segment.source);
    } else {
      tokens.addAll(segment.source.split(''));
    }
  }

  return tokens;
}

class TagResolveResult {
  final String? icon;
  final String? link;
  final TextStyle style;

  TagResolveResult({this.icon, this.link, required this.style});
}

TagResolveResult _resolveTagStyle(Iterable<RegExpMatch> tagMatches) {
  bool isBold = false;
  bool isItalic = false;
  double? fontSize;
  // bool isIcon = false;
  Color? textColor;
  String? icon;
  String? link;
  for (final tagMatch in tagMatches) {
    final tag = tagMatch.group(0)!;
    if (tag == 'bold') {
      isBold = true;
    } else if (tag == 'italic') {
      isItalic = true;
    } else if (tag == 't1') {
      fontSize = _FontSize.t1;
    } else if (tag == 't2') {
      fontSize = _FontSize.t2;
    } else if (tag == 't3') {
      fontSize = _FontSize.t3;
    } else if (tag == 't4') {
      fontSize = _FontSize.t4;
    } else if (tag == 't5') {
      fontSize = _FontSize.t5;
    } else if (tag == 't6') {
      fontSize = _FontSize.t6;
    } else if (tag == 't7') {
      fontSize = _FontSize.t7;
    } else if (tag == 'h1') {
      fontSize = _FontSize.h1;
    } else if (tag == 'h2') {
      fontSize = _FontSize.h2;
    } else if (tag == 'h3') {
      fontSize = _FontSize.h3;
    } else if (tag == 'h4') {
      fontSize = _FontSize.h4;
    } else if (tag == 'h5') {
      fontSize = _FontSize.h5;
    } else if (tag == 'h6') {
      fontSize = _FontSize.h6;
    } else if (tag == 'h7') {
      fontSize = _FontSize.h7;
    } else if (tag == 'white') {
      textColor = Colors.white;
    } else if (tag == 'black') {
      textColor = Colors.black;
    } else if (tag == 'grey') {
      textColor = Colors.grey;
    } else if (tag == 'red') {
      textColor = Colors.red;
    } else if (tag == 'pink') {
      textColor = Colors.pink;
    } else if (tag == 'purple') {
      textColor = Colors.purple;
    } else if (tag == 'deepPurple') {
      textColor = Colors.deepPurple;
    } else if (tag == 'indigo') {
      textColor = Colors.indigo;
    } else if (tag == 'blue') {
      textColor = Colors.blue;
    } else if (tag == 'lightBlue') {
      textColor = Colors.lightBlue;
    } else if (tag == 'cyan') {
      textColor = Colors.cyan;
    } else if (tag == 'teal') {
      textColor = Colors.teal;
    } else if (tag == 'green') {
      textColor = Colors.green;
    } else if (tag == 'lightGreen') {
      textColor = Colors.lightGreen;
    } else if (tag == 'lime') {
      textColor = Colors.lime;
    } else if (tag == 'yellow') {
      textColor = Colors.yellow;
    } else if (tag == 'amber') {
      textColor = Colors.amber;
    } else if (tag == 'orange') {
      textColor = Colors.orange;
    } else if (tag == 'deepOrange') {
      textColor = Colors.deepOrange;
    } else if (tag == 'brown') {
      textColor = Colors.brown;
    } else if (tag == 'blueGrey') {
      textColor = Colors.blueGrey;
    } else if (tag == 'rank0' || tag == 'common') {
      textColor = RankedColors.common;
    } else if (tag == 'rank1' || tag == 'rare') {
      textColor = RankedColors.rare;
    } else if (tag == 'rank2' || tag == 'epic') {
      textColor = RankedColors.epic;
    } else if (tag == 'rank3' || tag == 'legendary') {
      textColor = RankedColors.legendary;
    } else if (tag == 'rank4' || tag == 'mythic') {
      textColor = RankedColors.mythic;
    } else if (tag == 'rank5' || tag == 'arcane') {
      textColor = RankedColors.arcane;
    } else if (tag.startsWith('color=')) {
      textColor = HexColor.fromString(tagMatch.group(2) ?? tag.substring(6));
    } else if (tag.startsWith('icon=')) {
      // group(2) 是不含引号的属性值（当使用 icon='xxx' 形式时）
      icon = tagMatch.group(2) ?? tag.substring(5);
    } else if (tag.startsWith('link=')) {
      // link='character?name=aleph42'
      // 例如：link=character?name=wendy&age=18
      link = tagMatch.group(2) ?? tag.substring(5);
      // TODO: 进一步解析
      // final separaterIndex = routeString.indexOf('?');
      // if (separaterIndex != -1) {
      //   route = routeString.substring(0, separaterIndex);
      //   routeArg = routeString.substring(separaterIndex + 1);
      // } else {
      //   route = routeString;
      // }
    }
  }
  final resolvedStyle = TextStyle(
    fontWeight: isBold ? FontWeight.bold : null,
    fontStyle: isItalic ? FontStyle.italic : null,
    fontSize: fontSize,
    color: textColor,
  );
  return TagResolveResult(icon: icon, link: link, style: resolvedStyle);
}

String _normalizeMultilineTags(String source) {
  final matches = _tagPattern.allMatches(source).toList();
  if (matches.isEmpty) return source;

  final buffer = StringBuffer();
  var lastEnd = 0;

  for (final match in matches) {
    final matchString = match.group(0)!;
    final tags = match.namedGroup('tags')!;
    final taggedContent = match.namedGroup('content')!;

    buffer.write(source.substring(lastEnd, match.start));

    if (taggedContent.contains('\n')) {
      final lines = taggedContent.split('\n');
      buffer.write(lines.map((line) => '<$tags>$line</>').join('\n'));
    } else {
      buffer.write(matchString);
    }

    lastEnd = match.end;
  }

  if (lastEnd < source.length) {
    buffer.write(source.substring(lastEnd));
  }

  return buffer.toString();
}

/// 寻找以\<???>xxxxx<\/>标签包裹的文字，并将其替换为富文本字符串
///
/// 返回的是一个段落列表，每个段落的children则是以标签做分隔的文字块或图片块
///
/// 注意：对于换行，支持在标签内外使用实际换行符或字面转义换行符'\n'
///
/// 支持参数：bold, italic, red, blue, color='#ffffffff', icon=xxx, link='xxx', etc....
///
/// 图标通过 `<icon=xxx></>` 语法内嵌显示，xxx 为 [RichTextIcons.register]
/// 注册的 id，图标尺寸与文字大小一致
///
/// 图标会被调整为对应于文字高度的尺寸
///
/// 文字格式不支持不同的文字大小，span的文字样式中不会包含字体大小
///
/// 只能在config中统一设置一个文字大小
///
/// 这个函数生成的TextSpan并非树形结构，而是扁平列表
List<TextSpan> buildFlutterRichText(
  String? source, {
  TextStyle? style,
}) {
  if (source == null || source.isEmpty) {
    return const [];
  }

  final result = <TextSpan>[];
  final paragraphs = _normalizeMultilineTags(source).trim().split('\n');
  for (var i = 0; i < paragraphs.length; ++i) {
    final spans = <InlineSpan>[];

    for (final segment in _parseRichText(paragraphs[i])) {
      if (!segment.isTag) {
        spans.add(TextSpan(
          text: segment.source.replaceAllEscapedLineBreaks(),
          style: style,
        ));
        continue;
      }

      final tagResolveResult = _resolveTagStyle(
        _tagContentPattern.allMatches(segment.tags!),
      );
      final mergedStyle =
          (style ?? const TextStyle()).merge(tagResolveResult.style);
      final iconId = tagResolveResult.icon;
      final iconAsset =
          iconId != null ? RichTextIcons.resolveFlutterAsset(iconId) : null;

      if (iconAsset != null) {
        final iconSize = mergedStyle.fontSize ?? 14.0;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            style: mergedStyle,
            child: Image.asset(
              iconAsset,
              width: iconSize,
              height: iconSize,
            ),
          ),
        );
      } else if (segment.content!.isNotEmpty) {
        spans.add(TextSpan(
          text: segment.content,
          style: mergedStyle,
        ));
      }
    }

    if (i < paragraphs.length - 1) {
      spans.add(const TextSpan(text: '\n'));
    }
    result.add(TextSpan(children: spans));
  }

  return result;
}

DocumentRoot buildFlameRichText(
  String source, {
  TextStyle? style,
}) {
  final paragraphs = _normalizeMultilineTags(source).split('\n');
  final paragraphNodes = <ParagraphNode>[];

  for (final paragraph in paragraphs) {
    final nodes = <InlineTextNode>[];

    for (final segment in _parseRichText(paragraph)) {
      if (!segment.isTag) {
        nodes.add(RichTextNode(
          text: segment.source.replaceAllEscapedLineBreaks(),
          style: style?.toInlineTextStyle(),
        ));
        continue;
      }

      final tagResolveResult = _resolveTagStyle(
        _tagContentPattern.allMatches(segment.tags!),
      );
      final iconId = tagResolveResult.icon;
      final flameKey =
          iconId != null ? RichTextIcons.resolveFlameKey(iconId) : null;

      if (flameKey != null) {
        nodes.add(InlineIconNode(spriteId: flameKey));
      } else if (segment.content!.isNotEmpty) {
        nodes.add(RichTextNode(
          text: segment.content!,
          style: (style ?? const TextStyle())
              .merge(tagResolveResult.style)
              .toInlineTextStyle(),
        ));
      }
    }

    paragraphNodes.add(ParagraphNode.group(nodes));
  }

  return DocumentRoot(paragraphNodes);
}
