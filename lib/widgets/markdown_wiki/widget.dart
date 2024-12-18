import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';

import 'resource/resource_manager.dart';

class TreeNode {
  const TreeNode({
    required this.title,
    String? key,
    this.expanded = false,
    this.children = const <TreeNode>[],
  }) : key = key ?? title;

  final String title, key;
  final bool expanded;

  final List<TreeNode> children;
}

class MarkdownWiki extends StatefulWidget {
  final ResourceManager resourceManager;

  const MarkdownWiki({
    super.key,
    required this.resourceManager,
  });

  @override
  State<MarkdownWiki> createState() => _MarkdownWikiState();
}

class _MarkdownWikiState extends State<MarkdownWiki> {
  late TreeController<TreeNode> _treeController;

  void expandToNode(String key) {
    setState(() {
      final result = _treeController.search((node) => node.key == key);
      for (final node in result.matches.keys) {
        _treeController.expand(node);
      }
    });
  }

  @override
  void initState() {
    final List<TreeNode> roots = [
      TreeNode(
        title: 'Lukas',
        key: 'lukas',
        expanded: true,
        children: [
          TreeNode(
            title: 'Otis',
            key: 'otis',
          ),
          TreeNode(
            title: 'Zorro',
            key: 'zorro',
          ),
        ],
      ),
    ];

    _treeController = TreeController<TreeNode>(
      roots: roots,
      childrenProvider: (TreeNode node) => node.children,
    );

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Row(
        children: [
          SizedBox(
            width: 300.0,
            height: MediaQuery.of(context).size.height,
            child: AnimatedTreeView<TreeNode>(
              treeController: _treeController,
              nodeBuilder: (BuildContext context, TreeEntry<TreeNode> entry) {
                return InkWell(
                  onTap: () => _treeController.toggleExpansion(entry.node),
                  child: TreeIndentation(
                    entry: entry,
                    child: Text(entry.node.title),
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              expandToNode('otis');
            },
            child: const Text('expand'),
          ),
        ],
      ),
    );
  }
}
