import 'package:flutter/material.dart';
// import 'package:samsara/components/border_component.dart';
// import 'package:flutter/gestures.dart';

import 'extensions.dart';

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

/// 寻找以\<???>xxxxx<\/>标签包裹的文字，并将其替换为富文本字符串
/// 返回一个段落列表，每个段落的children则是以标签做分隔的文字块或图片块
/// 注意：标签内的文字的字面转移换行符'\n'和实际换行符都会被忽略掉，标签之外的换行会生效
/// 支持参数：bold, italic, red, blue, color='#ffffffff', link='xxx', image='', etc....
/// 图片会被调整为对应于文字高度的尺寸
/// 文字格式不支持不同的文字大小，span的文字样式中不会包含字体大小
/// 只能在config中统一设置一个文字大小
/// 如果是用于Flutter显示，可以通过addLineBreaks参数来给每个段落最后手动添加一个换行符
/// 对于Flame内的富文本渲染，则不需要
/// 这个函数生成的TextSpan并非树形结构，而是扁平列表
List<TextSpan> buildRichText(
  String source, {
  TextStyle? style,
  bool addLineBreaks = false,
  // final void Function(String id, String? arg)? onTap,
}) {
  final paragraphs = source.split(RegExp(r'\n'));
  final List<TextSpan> result = [];
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
          bool isBold = false;
          bool isItalic = false;
          // bool isIcon = false;
          Color? textColor;
          // String? route;
          // String? routeArg;
          for (final tag in tags) {
            final currentTag = tag.group(0)!;
            if (currentTag == 'bold') {
              isBold = true;
            } else if (currentTag == 'italic') {
              isItalic = true;
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
            } else if (currentTag.startsWith('color=\'')) {
              textColor = HexColor.fromString(
                  currentTag.substring(7, currentTag.length - 1));
            }
            // else if (currentTag.startsWith('link=\'')) {
            //   // 问号后面的部分会解析为参数，但不会进一步解析
            //   // 例如：route=character?name=wendy&age=18
            //   final routeString = currentTag.substring(7, currentTag.length - 1);
            //   final separaterIndex = routeString.indexOf('?');
            //   if (separaterIndex != -1) {
            //     route = routeString.substring(0, separaterIndex);
            //     routeArg = routeString.substring(separaterIndex + 1);
            //   } else {
            //     route = routeString;
            //   }
            // }
          }

          final resolvedStyle = TextStyle(
            fontWeight: isBold ? FontWeight.bold : null,
            fontStyle: isItalic ? FontStyle.italic : null,
            color: textColor,
          );

          spanList.add(
            TextSpan(
              text: taggedContent,
              style: (style ?? const TextStyle()).merge(resolvedStyle),
              // recognizer: route != null
              //     ? (TapGestureRecognizer()
              //       ..onTap = () => onTap?.call(route!, routeArg)
              //       )
              //     : null,
            ),
          );
        } else {
          // final textPaint = TextPaint(style: style);
          // final textHeight = textPaint.getLineMetrics('sample').height;
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
    if (addLineBreaks) {
      spanList.add(const TextSpan(text: '\n'));
    }
    result.add(TextSpan(children: spanList));
  }

  return result;
}
