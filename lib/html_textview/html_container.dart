import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'html_node.dart';

enum HTMLContainerType {
  div,
  p,
  h1,
  h2,
  h3,
  h4,
  h5,
  h6,
  unknown,
}

class HtmlContainer {
  final HTMLContainerType type;
  Color? color;
  final String? style;
  final Map<dynamic, dynamic> attributesForChildren = {};
  final List<dynamic> nodes = [];

  TextAlign textAlign;

  HtmlContainer({
    this.type = HTMLContainerType.div,
    this.textAlign = TextAlign.left,
    this.style,
    this.color,
  });

  static HTMLContainerType toIdFromTag(String? tag) {
    switch (tag) {
      case 'div':
        return HTMLContainerType.div;
      case 'p':
        return HTMLContainerType.p;
      case 'h1':
        return HTMLContainerType.h1;
      case 'h2':
        return HTMLContainerType.h2;
      case 'h3':
        return HTMLContainerType.h3;
      case 'h4':
        return HTMLContainerType.h4;
      case 'h5':
        return HTMLContainerType.h5;
      case 'h6':
        return HTMLContainerType.h6;
      default:
        return HTMLContainerType.unknown;
    }
  }

  static bool isContainer(String? tag) {
    return tag == 'div' ||
        tag == 'p' ||
        tag == 'h1' ||
        tag == 'h2' ||
        tag == 'h3' ||
        tag == 'h4' ||
        tag == 'h5' ||
        tag == 'h6';
  }

  static TextSpan renderChildren(HtmlContainer container,
      [List<TextSpan>? contents]) {
    contents ??= [];
    container.parseStyle();
    for (final node in container.nodes) {
      if (node is HtmlNode) {
        contents.add(node.renderToWidget());
      } else if (node is HtmlContainer) {
        contents.add(renderChildren(node));
      }
    }

    return TextSpan(children: contents);
  }

  Widget renderToWidget() {
    parseStyle();
    List<Widget> contents = [];
    for (var node in nodes) {
      if (node is HtmlContainer) {
        contents.add(
          RichText(
            text: renderChildren(node),
            textAlign: node.textAlign,
            softWrap: true,
          ),
        );
      } else if (node is HtmlNode) {
        contents.add(
          Text(
            node.text,
            style: const TextStyle(fontSize: 12),
          ),
        );
      }
    }

    return Column(
      children: contents,
    );
  }

  void parseStyle() {
    if (style == null) return;

    List<String> styles = style!.split(';');
    if (styles.isNotEmpty) {
      final stylesMap = {};
      for (var item in styles) {
        if (item != '') {
          stylesMap.addAll({
            item.split(':')[0].trimLeft().trimRight():
                item.split(':')[1].trimLeft().trimRight()
          });
        }
      }

      if (stylesMap.containsKey('text-align')) {
        if (stylesMap['text-align'].toString().contains('center')) {
          textAlign = TextAlign.center;
        } else if (stylesMap['text-align'].toString().contains('right')) {
          textAlign = TextAlign.right;
        } else {
          textAlign = TextAlign.left;
        }
      }

      if (stylesMap.containsKey('color')) {
        color = parseColor(stylesMap['color']);
      } else {
        color = null;
      }
    }
  }

  static dynamic parseStyleToMap(String? style) {
    final stylesMap = {};
    if (style != null && style != '') {
      List<String> styles = style.split(';');
      if (styles.isNotEmpty) {
        for (var item in styles) {
          if (item != '') {
            stylesMap.addAll({
              item.split(':')[0].trimLeft().trimRight():
                  item.split(':')[1].trimLeft().trimRight()
            });
          }
        }
        return stylesMap;
      }
    }

    return stylesMap;
  }

  static String styleToString(Map<dynamic, dynamic> style) {
    String map = '';
    style.forEach((key, value) {
      map += '$key: $value;';
    });

    return map;
  }

  static Color parseColor(String color) {
    try {
      if (color != '') {
        var tmp = color.replaceAll('#', '').trim();
        return Color(int.parse('0xFF' + tmp));
      } else {
        return const Color(0xFF000000);
      }
    } catch (err) {
      if (kDebugMode) {
        print('HTML Renderer Error: $err');
      }
      return const Color(0xFF000000);
    }
  }

  static dynamic parseElementInStyle(String style, String key) {
    if (style != '') {
      List<String> styles = style.split(';');
      if (styles.isNotEmpty) {
        Map stylesMap = {};
        for (var item in styles) {
          if (item != '') {
            stylesMap.addAll({
              item.split(':')[0].trimLeft().trimRight():
                  item.split(':')[1].trimLeft().trimRight()
            });
          }
        }
        if (stylesMap.containsKey(key)) {
          return stylesMap[key];
        } else {
          return '';
        }
      }
    }

    return '';
  }

  double getFontSize() {
    switch (type) {
      case HTMLContainerType.unknown:
      case HTMLContainerType.div:
      case HTMLContainerType.p:
        return 16.0;
      case HTMLContainerType.h6:
        return 11.5;
      case HTMLContainerType.h5:
        return 13.0;
      case HTMLContainerType.h4:
        return 16.0;
      case HTMLContainerType.h3:
        return 20.0;
      case HTMLContainerType.h2:
        return 24.0;
      case HTMLContainerType.h1:
        return 32.0;
    }
  }
}
