import 'package:flutter/material.dart';
// import 'components/text_component2.dart';
// import 'package:flutter/gestures.dart';
import 'package:flame/text.dart';
// ignore: implementation_imports

import 'textstyle_extension.dart';
import 'richtext_node.dart';
import '../extensions.dart';

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

RegExp _tagPattern = RegExp(
  r"<.*?>([^<\/>]*)<\/>",
  caseSensitive: false,
  multiLine: false,
  unicode: true,
);

RegExp _tagContentPattern = RegExp(
  r"(\S+='([^']*)')|(\S+)",
  multiLine: false,
  unicode: true,
);

List<String> getRichTextStream(String source) {
  final List<String> splitedList = [];

  String processingText = source;

  if (_tagPattern.hasMatch(processingText)) {
    while (_tagPattern.hasMatch(processingText)) {
      final match = _tagPattern.firstMatch(processingText)!;
      final matchString = match.group(0)!;
      final before = processingText.substring(0, match.start);
      if (before.isNotEmpty) {
        splitedList.addAll(before.split(''));
      }
      processingText = processingText.substring(match.end);
      splitedList.add(matchString);
    }
    if (processingText.isNotEmpty) {
      splitedList.addAll(processingText.split(''));
    }
  } else {
    splitedList.addAll(processingText.split(''));
  }

  return splitedList;
}

class TagResolveResult {
  String? icon;
  String? link;
  TextStyle? style;

  TagResolveResult({this.icon, this.link, this.style});
}

TagResolveResult _resolveTagStyle(Iterable<RegExpMatch> tagMatches) {
  bool isBold = false;
  bool isItalic = false;
  double? fontSize;
  // bool isIcon = false;
  Color? textColor;
  String? icon;
  String? link;
  for (final tag in tagMatches) {
    final currentTag = tag.group(0)!;
    if (currentTag == 'bold') {
      isBold = true;
    } else if (currentTag == 'italic') {
      isItalic = true;
    } else if (currentTag == 't1') {
      fontSize = _FontSize.t1;
    } else if (currentTag == 't2') {
      fontSize = _FontSize.t2;
    } else if (currentTag == 't3') {
      fontSize = _FontSize.t3;
    } else if (currentTag == 't4') {
      fontSize = _FontSize.t4;
    } else if (currentTag == 't5') {
      fontSize = _FontSize.t5;
    } else if (currentTag == 't6') {
      fontSize = _FontSize.t6;
    } else if (currentTag == 't7') {
      fontSize = _FontSize.t7;
    } else if (currentTag == 'h1') {
      fontSize = _FontSize.h1;
    } else if (currentTag == 'h2') {
      fontSize = _FontSize.h2;
    } else if (currentTag == 'h3') {
      fontSize = _FontSize.h3;
    } else if (currentTag == 'h4') {
      fontSize = _FontSize.h4;
    } else if (currentTag == 'h5') {
      fontSize = _FontSize.h5;
    } else if (currentTag == 'h6') {
      fontSize = _FontSize.h6;
    } else if (currentTag == 'h7') {
      fontSize = _FontSize.h7;
    } else if (currentTag == 'white') {
      textColor = Colors.white;
    } else if (currentTag == 'black') {
      textColor = Colors.black;
    } else if (currentTag == 'grey') {
      textColor = Colors.grey;
    } else if (currentTag == 'red') {
      textColor = Colors.red;
    } else if (currentTag == 'pink') {
      textColor = Colors.pink;
    } else if (currentTag == 'purple') {
      textColor = Colors.purple;
    } else if (currentTag == 'deepPurple') {
      textColor = Colors.deepPurple;
    } else if (currentTag == 'indigo') {
      textColor = Colors.indigo;
    } else if (currentTag == 'blue') {
      textColor = Colors.blue;
    } else if (currentTag == 'lightBlue') {
      textColor = Colors.lightBlue;
    } else if (currentTag == 'cyan') {
      textColor = Colors.cyan;
    } else if (currentTag == 'teal') {
      textColor = Colors.teal;
    } else if (currentTag == 'green') {
      textColor = Colors.green;
    } else if (currentTag == 'lightGreen') {
      textColor = Colors.lightGreen;
    } else if (currentTag == 'lime') {
      textColor = Colors.lime;
    } else if (currentTag == 'yellow') {
      textColor = Colors.yellow;
    } else if (currentTag == 'amber') {
      textColor = Colors.amber;
    } else if (currentTag == 'orange') {
      textColor = Colors.orange;
    } else if (currentTag == 'deepOrange') {
      textColor = Colors.deepOrange;
    } else if (currentTag == 'brown') {
      textColor = Colors.brown;
    } else if (currentTag == 'blueGrey') {
      textColor = Colors.blueGrey;
    } else if (currentTag == 'rank0' || currentTag == 'other') {
      textColor = HexColor.fromString('#A3A3A3');
    } else if (currentTag == 'rank1' || currentTag == 'common') {
      textColor = HexColor.fromString('#CCCCCC');
    } else if (currentTag == 'rank2' || currentTag == 'uncommon') {
      textColor = HexColor.fromString('#FFFFFF');
    } else if (currentTag == 'rank3' || currentTag == 'rare') {
      textColor = HexColor.fromString('#00A6A9');
    } else if (currentTag == 'rank4' || currentTag == 'epic') {
      textColor = HexColor.fromString('#804DC8');
    } else if (currentTag == 'rank5' || currentTag == 'legendary') {
      textColor = HexColor.fromString('#C5C660');
    } else if (currentTag == 'rank6' || currentTag == 'unique') {
      textColor = HexColor.fromString('#62CC39');
    } else if (currentTag == 'rank7' || currentTag == 'mythic') {
      textColor = HexColor.fromString('#F28234');
    } else if (currentTag == 'rank8' || currentTag == 'arcane') {
      textColor = HexColor.fromString('#C65043');
    } else if (currentTag.startsWith('color=\'')) {
      textColor =
          HexColor.fromString(currentTag.substring(7, currentTag.length - 1));
    } else if (currentTag.startsWith('icon=\'')) {
      final iconId = currentTag.substring(7, currentTag.length - 1);
      icon = 'text/$iconId';
    } else if (currentTag.startsWith('link=\'')) {
      // link='character?name=aleph42'
      // 例如：link=character?name=wendy&age=18
      link = currentTag.substring(7, currentTag.length - 1);
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

/// 寻找以\<???>xxxxx<\/>标签包裹的文字，并将其替换为富文本字符串
///
/// 返回的是一个段落列表，每个段落的children则是以标签做分隔的文字块或图片块
///
/// 注意：对于换行，标签内只能使用字面转义换行符'\n'，标签外只能使用实际换行符，否则会导致解析失败
///
/// 支持参数：bold, italic, red, blue, color='#ffffffff', link='xxx', image='', etc....
///
/// 图片会被调整为对应于文字高度的尺寸
///
/// 文字格式不支持不同的文字大小，span的文字样式中不会包含字体大小
///
/// 只能在config中统一设置一个文字大小
///
/// 这个函数生成的TextSpan并非树形结构，而是扁平列表
List<TextSpan> buildFlutterRichText(
  String? source, {
  TextStyle? style,
  // final void Function(String id, String? arg)? onTap,
}) {
  final List<TextSpan> result = [];
  if (source == null && source!.isEmpty) {
    return result;
  }
  final paragraphs = source.split(RegExp(r'\n'));
  for (final paragraph in paragraphs) {
    final List<InlineSpan> spanList = [];
    String processingText = paragraph;
    if (_tagPattern.hasMatch(processingText)) {
      while (_tagPattern.hasMatch(processingText)) {
        final match = _tagPattern.firstMatch(processingText)!;
        final matchString = match.group(0)!;
        final taggedContent = match.group(1)!;
        final before = processingText.substring(0, match.start);
        if (before.isNotEmpty) {
          spanList.add(TextSpan(text: before, style: style));
        }
        processingText = processingText.substring(match.end);
        if (taggedContent.isNotEmpty) {
          String taggedString =
              matchString.substring(1, matchString.indexOf(taggedContent) - 1);
          taggedString = taggedString.replaceAll('\n', '');
          final tags = _tagContentPattern.allMatches(taggedString);
          final tagResolveResult = _resolveTagStyle(tags);

          if (tagResolveResult.icon != null) {
          } else {
            spanList.add(
              TextSpan(
                text: taggedContent,
                style:
                    (style ?? const TextStyle()).merge(tagResolveResult.style),
                // recognizer: route != null
                //     ? (TapGestureRecognizer()
                //       ..onTap = () => onTap?.call(route!, routeArg)
                //       )
                //     : null,
              ),
            );
          }
        }
      }

      if (processingText.isNotEmpty) {
        spanList.add(TextSpan(
            text: processingText.replaceAllEscapedLineBreaks(), style: style));
      }
    } else {
      spanList.add(TextSpan(
          text: processingText.replaceAllEscapedLineBreaks(), style: style));
    }
    // spanList.add(const TextSpan(text: '\n'));
    result.add(TextSpan(children: spanList));
  }

  return result;
}

DocumentRoot buildFlameRichText(
  String source, {
  TextStyle? style,
  // final void Function(String id, String? arg)? onTap,
}) {
  final paragraphs = source.split(RegExp(r'\n'));
  final paragraphNodes = <ParagraphNode>[];
  for (final paragraph in paragraphs) {
    final nodes = <InlineTextNode>[];
    String processingText = paragraph;
    if (_tagPattern.hasMatch(processingText)) {
      while (_tagPattern.hasMatch(processingText)) {
        final match = _tagPattern.firstMatch(processingText)!;
        final matchString = match.group(0)!;
        final taggedContent = match.group(1)!;
        final before = processingText.substring(0, match.start);
        if (before.isNotEmpty) {
          nodes.add(
              RichTextNode(text: before, style: style?.toInlineTextStyle()));
        }
        processingText = processingText.substring(match.end);
        if (taggedContent.isNotEmpty) {
          String taggedString =
              matchString.substring(1, matchString.indexOf(taggedContent) - 1);
          taggedString = taggedString.replaceAll('\n', '');
          final tags = _tagContentPattern.allMatches(taggedString);
          final tagResolveResult = _resolveTagStyle(tags);

          if (tagResolveResult.icon != null) {
          } else {
            nodes.add(
              RichTextNode(
                text: taggedContent,
                style: ((style ?? const TextStyle())
                    .merge(tagResolveResult.style)
                    .toInlineTextStyle()),
                // recognizer: route != null
                //     ? (TapGestureRecognizer()
                //       ..onTap = () => onTap?.call(route!, routeArg)
                //       )
                //     : null,
              ),
            );
          }
        }
      }

      if (processingText.isNotEmpty) {
        nodes.add(
          RichTextNode(
              text: processingText.replaceAllEscapedLineBreaks(),
              style: style?.toInlineTextStyle()),
        );
      }
    } else {
      nodes.add(
        RichTextNode(
            text: processingText.replaceAllEscapedLineBreaks(),
            style: style?.toInlineTextStyle()),
      );
    }
    paragraphNodes.add(ParagraphNode.group(nodes));
  }

  final document = DocumentRoot(paragraphNodes);
  return document;
}
