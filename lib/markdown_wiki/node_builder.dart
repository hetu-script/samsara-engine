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

Future<TreeNode<WikiPageData>> buildWikiTreeNodesFromData(
    List<dynamic> data) async {
  final root = TreeNode<WikiPageData>.root();

  Future<TreeNode<WikiPageData>> buildNode(Map<String, dynamic> data) async {
    final String key = data['id'];
    final String path = data['path'];
    final pageData = await rootBundle.loadString(path);
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

  for (final item in data) {
    if (item is! Map<String, dynamic>) continue;
    final node = await buildNode(item);
    root.add(node);
  }

  return root;
}
