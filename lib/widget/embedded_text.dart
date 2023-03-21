import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../utils/color.dart';

// 寻找以<bold color='#343434'>xxxxx</>括起来的文字，并将其替换为可以点击、hover等交互的控件
// 支持参数：bold, color, route
class EmbeddedText extends StatelessWidget {
  final String text;

  final void Function(String route, String? arg)? onRoute;

  final TextStyle? style;

  const EmbeddedText(
    this.text, {
    super.key,
    this.onRoute,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = style ?? DefaultTextStyle.of(context).style;
    final List<TextSpan> spanList = [];

    RegExp regExp = RegExp(
      r'<.*?>(.*)<\/>',
      caseSensitive: false,
      multiLine: false,
      unicode: true,
    );

    RegExp contentRegExp = RegExp(
      r'(\S+="([^"]*)")|(\S+)',
      multiLine: false,
      unicode: true,
    );

    String tmp = text;

    if (regExp.hasMatch(tmp)) {
      int splitPosition = 0;
      while (regExp.hasMatch(tmp)) {
        final match = regExp.firstMatch(text)!;
        final matchString = match.group(0)!;
        final taggedContent = match.group(1)!;
        splitPosition = tmp.indexOf(matchString);
        if (splitPosition > 0) {
          spanList.add(
            TextSpan(
              text: tmp.substring(0, splitPosition),
            ),
          );
        }
        final tagsString =
            matchString.substring(1, matchString.indexOf(taggedContent) - 1);
        final tags = contentRegExp.allMatches(tagsString);
        bool isBold = false;
        Color? textColor;
        String? route;
        String? routeArg;
        for (final tag in tags) {
          final currentTag = tag.group(0)!;
          if (currentTag == 'bold') {
            isBold = true;
          } else if (currentTag.startsWith('color="')) {
            textColor = HexColor.fromHex(
                currentTag.substring(7, currentTag.length - 1));
          } else if (currentTag.startsWith('route="')) {
            // route 的参数会直接放在问号后面
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
        spanList.add(
          TextSpan(
            text: taggedContent,
            style: defaultStyle.copyWith(
              fontWeight: isBold ? FontWeight.bold : null,
              color: textColor,
            ),
            recognizer: route != null
                ? (TapGestureRecognizer()
                  ..onTap = () {
                    onRoute?.call(route!, routeArg);
                  })
                : null,
          ),
        );
        tmp = tmp.substring(tmp.indexOf(matchString) + matchString.length);
      }

      if (tmp.isNotEmpty) {
        spanList.add(
          TextSpan(
            text: tmp,
          ),
        );
      }
    } else {
      spanList.add(
        TextSpan(
          text: tmp,
        ),
      );
    }

    return RichText(
        text: TextSpan(
      style: defaultStyle, //不加这一行会看不到字
      children: spanList,
    ));
  }
}
