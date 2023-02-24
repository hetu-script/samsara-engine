import 'package:flutter/material.dart';

import 'html_container.dart';

class HtmlNode {
  final String text;
  final String? tag;
  final String? href;
  final String? fontFamily;
  final String? fontFamilyBold;

  final double fontSize;
  final Map<dynamic, dynamic> textAttributes;
  final Color? color;
  final Color? hrefColor;

  final HtmlContainer? parent;

  HtmlNode({
    this.text = '',
    this.tag,
    this.href,
    this.parent,
    this.fontFamily, //Utilities.interstateLight,
    this.fontSize = 16.0,
    this.fontFamilyBold, // = Utilities.interstateBold,
    this.textAttributes = const {},
    this.hrefColor,
    this.color,
  });

  TextStyle _getStyle() {
    var family = textAttributes.containsKey("bold")
        ? fontFamilyBold ?? fontFamily
        : fontFamily;

    return TextStyle(
      fontStyle: textAttributes.containsKey("italic")
          ? FontStyle.italic
          : FontStyle.normal,
      fontWeight: (textAttributes.containsKey("bold") && fontFamilyBold == null)
          ? FontWeight.bold
          : FontWeight.normal,
      fontSize: fontSize,
      decoration: (href == null || href == "")
          ? TextDecoration.none
          : TextDecoration.underline,
      fontFamily: family,
      color: (href == null || href == "") ? color : null,
    );
  }

  TextSpan renderToWidget() {
    final style = _getStyle();

    // final data = breakLine ? '${text.trim()}/n' : text;

    if (href != null && href != "") {
      return TextSpan(
        text: text,
        style: style,
        // recognizer: TapGestureRecognizer()
        //   ..onTap = () {
        //     onLaunch?.call(this);
        //   },
        // onEnter: (event) => onEnter?.call(event, this),
        // onExit: (event) => onExit?.call(event, this),
      );
    } else {
      return TextSpan(text: text, style: style);
    }
  }
}
