import 'package:flutter/material.dart';
import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:samsara/markdown_wiki.dart';

import '../ui/responsive_view.dart';
import '../engine.dart';
import 'markdown_page.dart';

final Map<int, Color> colorMapper = {
  0: Colors.white,
  1: Colors.blueGrey[50]!,
  2: Colors.blueGrey[100]!,
  3: Colors.blueGrey[200]!,
  4: Colors.blueGrey[300]!,
  5: Colors.blueGrey[400]!,
  6: Colors.blueGrey[500]!,
  7: Colors.blueGrey[600]!,
  8: Colors.blueGrey[700]!,
  9: Colors.blueGrey[800]!,
  10: Colors.blueGrey[900]!,
};

extension ColorUtil on Color {
  Color byLuminance() =>
      computeLuminance() > 0.4 ? Colors.black87 : Colors.white;
}

const double treeWidth = 300.0;

class MarkdownWiki extends StatefulWidget {
  const MarkdownWiki({
    super.key,
    required this.engine,
    required this.treeNodes,
    this.builder,
    this.margin,
    this.backgroundColor,
    this.closeButton,
  });

  final SamsaraEngine engine;
  final TreeNode<WikiPageData> treeNodes;
  final Widget Function(BuildContext, TreeNode<WikiPageData>)? builder;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Widget? closeButton;

  @override
  State<MarkdownWiki> createState() => _MarkdownWikiState();
}

class _MarkdownWikiState extends State<MarkdownWiki> {
  late TreeViewController<WikiPageData, TreeNode<WikiPageData>> _treeController;

  String? pageData;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      alignment: AlignmentDirectional.center,
      margin: widget.margin,
      backgroundColor: widget.backgroundColor,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(widget.engine.locale('console')),
          actions: [widget.closeButton ?? CloseButton()],
        ),
        body: Row(
          children: [
            SizedBox(
              width: treeWidth,
              child: TreeView.simple<WikiPageData>(
                tree: widget.treeNodes,
                showRootNode: true,
                expansionIndicatorBuilder: (context, node) =>
                    ChevronIndicator.rightDown(
                  tree: node,
                  color: Colors.blue[700],
                  padding: const EdgeInsets.all(8),
                ),
                indentation: const Indentation(style: IndentStyle.roundJoint),
                onItemTap: (node) {
                  _treeController.expandNode(node);
                  pageData = node.data?.content;
                  setState(() {});
                },
                onTreeReady: (controller) {
                  _treeController = controller;
                  final root = _treeController.elementAt('/');
                  _treeController.expandNode(root);
                },
                builder: widget.builder ??
                    (context, node) => Card(
                          child: ListTile(
                            title: Text(
                                widget.engine.locale(node.data?.title ?? '')),
                            subtitle: Text(widget.engine
                                .locale(node.data?.description ?? '')),
                          ),
                        ),
              ),
            ),
            Expanded(
              child: MarkdownPage(pageData ?? ''),
            ),
          ],
        ),
      ),
    );
  }
}
