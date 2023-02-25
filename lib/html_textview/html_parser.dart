import 'package:html/dom.dart' as dom;
import 'package:flutter/material.dart';

import 'html_container.dart';
import 'html_node.dart';

class HtmlParser {
  final String data;
  final String? fontFamily;
  final String? fontFamilyBold;
  final Color color;
  final Color? linkColor;

  HtmlParser(
    this.data, {
    this.fontFamily,
    this.fontFamilyBold,
    this.color = Colors.black,
    this.linkColor,
  });

  HtmlContainer parse() {
    dom.Element root = dom.Element.html('<div>${data.trim()}</div>'
        .replaceAll('&nbsp;', ' ')
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .replaceAll('<br/>', '\n')
        .replaceAll('</br>', '\n'));

    HtmlContainer container = HtmlContainer();
    _buildNodesToRender(root, container);

    return container;
  }

  dynamic _buildNodesToRender(dom.Node parent, HtmlContainer containerToAdd,
      {Map<dynamic, dynamic>? attributesForChildren}) {
    final attributes = attributesForChildren ?? {};
    for (final node in parent.nodes) {
      if (node is dom.Text && node.text.trim() == '') continue;

      String? local;
      if (node is dom.Element) {
        local = node.localName;
      }

      if (local == null) {
        var newMap = {};

        newMap.addEntries(attributes.entries);

        String? style;

        if (node.attributes.containsKey('style')) {
          style = node.attributes['style'];
        } else {
          if (attributes.containsKey('style')) {
            style = attributes['style'];
          }
        }

        if (style != null && style != '') {
          Map parentStyle = HtmlContainer.parseStyleToMap(attributes['style']);
          Map? childStyle =
              HtmlContainer.parseStyleToMap(node.attributes['style']);

          if (childStyle != null && childStyle.containsKey('color')) {
            if (!parentStyle.containsKey('color')) {
              parentStyle.addAll({'color': childStyle});
            } else {
              parentStyle['color'] = childStyle['color'];
            }
          }

          style = HtmlContainer.styleToString(parentStyle);
        }

        containerToAdd.nodes.add(
          HtmlNode(
            parent: containerToAdd,
            fontFamily: fontFamily,
            fontFamilyBold: fontFamilyBold,
            color: style != null && style != ''
                ? HtmlContainer.parseColor(
                    HtmlContainer.parseElementInStyle(style, 'color'))
                : color,
            text: node
                .toString()
                .substring(1, node.toString().length - 1)
                .replaceAll('&nbsp;', ' '),
            textAttributes: newMap,
            fontSize: containerToAdd.getFontSize(),
            hrefColor: linkColor ?? color,
            href: attributes['href'],
          ),
        );
      }
      if (node.hasChildNodes()) {
        if (node.attributes.isNotEmpty) {
          if (node.attributes.containsKey('href')) {
            attributes.addAll({'href': node.attributes['href']});
          }
        }

        if (local != null && (local == 'strong' || local == 'b')) {
          attributes.addAll({'bold': 1});
        } else if (local != null && (local == 'em' || local == 'i')) {
          attributes.addAll({'italic': 1});
        }

        HtmlContainer? newContainer;
        if (HtmlContainer.isContainer(local)) {
          String? style;
          if (node.attributes.containsKey('style')) {
            style = node.attributes['style'];
          }

          Map newMap = {};
          Map parentStyle = {};
          Map childStyle = {};

          if (attributes.isNotEmpty) {
            if (attributes.containsKey('style')) {
              parentStyle = HtmlContainer.parseStyleToMap(attributes['style']);
            }
            newMap.addEntries(attributes.entries);
          } else {}

          if (style != null && style != '') {
            childStyle = HtmlContainer.parseStyleToMap(style);
            //newList.addAll({'style': style});
          }

          if (parentStyle.isEmpty) {
            newMap.addAll({'style': style});
          } else {
            String mergeStyle;
            childStyle.forEach((key, value) {
              if (parentStyle.containsKey(key)) {
                parentStyle[key] = value;
              } else {
                parentStyle.addAll({key: value});
              }
            });
            mergeStyle = HtmlContainer.styleToString(parentStyle);
            newMap.addAll({'style': mergeStyle});
          }

          newContainer = HtmlContainer(
              type: HtmlContainer.toIdFromTag(local), style: style);
          newContainer.parseStyle();
          attributesForChildren = newMap;
          containerToAdd.nodes.add(newContainer);
        } else {
          String? style;
          if (node.attributes.containsKey('style')) {
            style = node.attributes['style'];

            // todo OVERRIDE STYLES
            attributes.addAll({'style': style});
          }
        }

        var tmp = _buildNodesToRender(node, newContainer ?? containerToAdd,
            attributesForChildren: attributesForChildren);

        _clearAttributes((tmp['element'] as dom.Element).localName, attributes);
        //attributesForChildren.remove('style');
        if (tmp['container'] is HtmlContainer) {
          attributes.addEntries((tmp['container'] as HtmlContainer)
              .attributesForChildren
              .entries);

          attributes.remove('href');
        }
      }
    }

    return {'element': parent, 'container': containerToAdd};
  }

  static void _clearAttributes(
      String? local, Map<dynamic, dynamic> attributesForChildren) {
    switch (local) {
      case 'em':
      case 'i':
        attributesForChildren.remove('italic');
        break;
      case 'b':
      case 'strong':
        attributesForChildren.remove('bold');
        break;
      case 'a':
        attributesForChildren.remove('href');
        break;
    }
  }
}
