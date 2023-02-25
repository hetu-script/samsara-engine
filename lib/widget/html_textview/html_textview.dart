import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'html_container.dart';
import 'html_parser.dart';
import 'html_node.dart';

class HtmlTextView extends StatelessWidget {
  final String data;
  final String? fontFamily;
  final String? fontFamilyBold;
  final Color? linkColor;

  final void Function(PointerEnterEvent event, HtmlNode node)? onMouseEnterLink;
  final void Function(PointerExitEvent event, HtmlNode node)? onMouseExitLink;
  final void Function(HtmlNode node)? onLaunchLink;

  const HtmlTextView(
    this.data, {
    super.key,
    this.fontFamily,
    this.fontFamilyBold,
    this.linkColor,
    this.onMouseEnterLink,
    this.onMouseExitLink,
    this.onLaunchLink,
  });

  @override
  Widget build(BuildContext context) {
    HtmlParser parser = HtmlParser(
      data,
      fontFamilyBold: fontFamilyBold,
      fontFamily: fontFamily,
      linkColor: linkColor,
    );
    HtmlContainer html = parser.parse();

    return Container(
      padding: const EdgeInsets.all(0.0),
      child: html.renderToWidget(),
    );
  }
}
