import 'package:flutter/services.dart' show rootBundle;

import 'package:animated_tree_view/animated_tree_view.dart';

class WikiPageData {
  final String key;
  final String? title;
  final String? description;
  final String? content;

  WikiPageData({
    required this.key,
    this.title,
    this.description,
    this.content,
  });
}

typedef WikiTreeNode = TreeNode<WikiPageData>;

Future<WikiTreeNode> buildWikiTreeNodesFromData(
  List<dynamic> data, {
  dynamic root,
}) async {
  Future<WikiTreeNode> buildNode(Map<String, dynamic> data) async {
    final String key = data['id'];
    final String? path = data['path'];
    final pageData = path != null ? await rootBundle.loadString(path) : null;
    final wikiPage = WikiPageData(
      key: key,
      title: data['title'],
      description: data['description'],
      content: pageData,
    );
    final node = TreeNode<WikiPageData>(key: key, data: wikiPage);
    final children = data['children'];
    if (children is List && children.isNotEmpty) {
      for (final child in children) {
        if (child is! Map<String, dynamic>) continue;
        final childNode = await buildNode(child);
        node.add(childNode);
      }
    }
    return node;
  }

  final rootNode = await buildNode(
    root ?? {'id': '/'},
  );

  for (final item in data) {
    if (item is! Map<String, dynamic>) continue;
    final node = await buildNode(item);
    rootNode.add(node);
  }

  return rootNode;
}
