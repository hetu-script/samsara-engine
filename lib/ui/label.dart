import 'package:flutter/material.dart';

import '../richtext.dart';
import 'mouse_region2.dart';

class Label extends StatelessWidget {
  Label(
    this.richTextSource, {
    this.width,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 5.0),
    this.textAlign = TextAlign.center,
    this.textStyle,
    this.backgroundColor,
    this.cursor = MouseCursor.defer,
    this.onMouseEnter,
    this.onMouseExit,
  }) : super(key: GlobalKey());

  final String richTextSource;
  final double? width, height;
  final EdgeInsetsGeometry padding;
  final TextAlign textAlign;
  final TextStyle? textStyle;
  final Color? backgroundColor;

  final MouseCursor cursor;
  final void Function(Rect rect)? onMouseEnter;
  final void Function()? onMouseExit;

  @override
  Widget build(BuildContext context) {
    return MouseRegion2(
      cursor: cursor,
      onMouseEnter: onMouseEnter,
      onMouseExit: onMouseExit,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        color: backgroundColor,
        child: RichText(
          textAlign: textAlign,
          text: TextSpan(
            children: buildFlutterRichText(
              richTextSource,
              style: (Theme.of(context).textTheme.bodyMedium ?? TextStyle())
                  .merge(textStyle),
            ),
          ),
        ),
      ),
    );
  }
}

class LabelsWrap extends StatelessWidget {
  const LabelsWrap(
    this.text, {
    super.key,
    this.minWidth = 0.0,
    this.minHeight = 0.0,
    this.padding,
    this.children = const <Widget>[],
  });

  final String text;

  final double minWidth, minHeight;

  final EdgeInsetsGeometry? padding;

  final Iterable<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minWidth,
        minHeight: minHeight,
      ),
      child: Wrap(
        children: [
          Label(
            text,
            textAlign: TextAlign.left,
          ),
          ...children,
        ],
      ),
    );
  }
}
