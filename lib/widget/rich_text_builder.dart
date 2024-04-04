import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../extensions.dart' show HexColor;

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

// 寻找以<???>xxxxx</>括起来的文字，并将其替换为可以点击、hover等交互的控件
// 支持参数：bold, italic, red, blue, color='xxx', link='xxx'
List<TextSpan> buildRichText(
  String source, {
  TextStyle? style,
  final void Function(String id, String? arg)? onTap,
}) {
  final List<TextSpan> spanList = [];

  String processingText = source;

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
        final tagsString =
            matchString.substring(1, matchString.indexOf(taggedContent) - 1);
        final tags = _tagContentPattern.allMatches(tagsString);
        bool isBold = false;
        bool isItalic = false;
        Color? textColor;
        String? route;
        String? routeArg;
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
          } else if (currentTag.startsWith('link=\'')) {
            // link 的参数会直接放在问号后面
            // 例如：route=character?wendy3233
            final routeString = currentTag.substring(7, currentTag.length - 1);
            final separaterIndex = routeString.indexOf('?');
            if (separaterIndex != -1) {
              route = routeString.substring(0, separaterIndex);
              routeArg = routeString.substring(separaterIndex + 1);
            } else {
              route = routeString;
            }
          }
        }

        final resolvedStyle = TextStyle(
          fontWeight: isBold ? FontWeight.bold : null,
          fontStyle: isItalic ? FontStyle.italic : null,
          color: textColor,
        );

        spanList.add(
          TextSpan(
            text: taggedContent,
            style: style != null ? style.merge(resolvedStyle) : resolvedStyle,
            recognizer: route != null
                ? (TapGestureRecognizer()
                  ..onTap = () => onTap?.call(route!, routeArg))
                : null,
          ),
        );
      }
    }

    if (processingText.isNotEmpty) {
      spanList.add(TextSpan(text: processingText, style: style));
    }
  } else {
    spanList.add(TextSpan(text: processingText, style: style));
  }

  return spanList;
}
