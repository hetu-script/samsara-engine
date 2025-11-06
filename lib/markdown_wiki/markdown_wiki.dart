import 'package:flutter/material.dart';
import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:samsara/markdown_wiki.dart';

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
    this.closeButton,
    this.homePage = '/',
    this.onTreeReady,
    this.cursor,
    this.path,
    this.onPageChanged,
  });

  final SamsaraEngine engine;
  final TreeNode<WikiPageData> treeNodes;
  final Widget Function(BuildContext, TreeNode<WikiPageData>)? builder;
  final Widget? closeButton;
  final String homePage;
  final void Function(TreeViewController<WikiPageData, TreeNode<WikiPageData>>)?
      onTreeReady;
  final WidgetStateMouseCursor? cursor;
  final String? path;
  final void Function(String path)? onPageChanged;

  @override
  State<MarkdownWiki> createState() => _MarkdownWikiState();
}

class _MarkdownWikiState extends State<MarkdownWiki> {
  late TreeViewController<WikiPageData, TreeNode<WikiPageData>> _treeController;
  final ScrollController _scrollController = ScrollController();

  String? _rootTitle;
  String? _title;
  String? _pageData;

  TreeNode<WikiPageData>? _selectedNode;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();

    _scrollController.dispose();
  }

  void _onSelectedNode(TreeNode<WikiPageData> node) {
    _selectedNode = node;
    _title = node.data?.title;
    _pageData = node.data?.content;
    _scrollController.jumpTo(_scrollController.position.minScrollExtent);
    widget.onPageChanged?.call(node.path);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
            '${_rootTitle != null ? widget.engine.locale(_rootTitle) : ''}${_title != null ? ' - ${widget.engine.locale(_title)}' : ''}'),
        actions: [widget.closeButton ?? CloseButton()],
      ),
      body: Row(
        children: [
          SizedBox(
            width: treeWidth,
            child: Material(
              type: MaterialType.transparency,
              child: TreeView.simple<WikiPageData>(
                tree: widget.treeNodes,
                showRootNode: false,
                expansionIndicatorBuilder: (context, node) =>
                    ChevronIndicator.rightDown(
                  tree: node,
                  color: Colors.blue[700],
                  padding: const EdgeInsets.all(8),
                ),
                indentation: const Indentation(style: IndentStyle.roundJoint),
                onTreeReady: (controller) async {
                  _treeController = controller;
                  final home = _treeController.elementAt(widget.homePage);
                  _rootTitle = home.data?.title;
                  final path = widget.path ?? widget.homePage;
                  final node = _treeController.elementAt(path);
                  widget.onTreeReady?.call(_treeController);
                  _onSelectedNode(node);
                  var parent = node.parent;
                  while (parent != null) {
                    _treeController
                        .expandNode(parent as TreeNode<WikiPageData>);
                    parent = parent.parent;
                  }
                  _treeController.expandNode(node);
                },
                builder: widget.builder ??
                    (context, node) {
                      return Material(
                        type: MaterialType.transparency,
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: ListTile(
                            mouseCursor:
                                widget.cursor?.resolve({WidgetState.hovered}),
                            dense: true,
                            title: Text(widget.engine
                                .locale(node.data?.title ?? 'Untitled page')),
                            onTap: () {
                              _onSelectedNode(node);
                              _treeController.toggleExpansion(node);
                            },
                            selected: _selectedNode == node,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.black, width: 1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            selectedColor: Colors.white,
                            selectedTileColor: Colors.lightBlue,
                          ),
                        ),
                      );
                    },
              ),
            ),
          ),
          Expanded(
            child: MarkdownPage(
              scrollController: _scrollController,
              _pageData ?? '',
            ),
          ),
        ],
      ),
    );
  }
}
