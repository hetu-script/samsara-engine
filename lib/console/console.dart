import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../engine.dart';
import '../extensions.dart';
import '../colors.dart';

class Console extends StatefulWidget {
  const Console({
    super.key,
    required this.engine,
    this.backgroundColor,
    this.closeButton,
    this.label,
    this.labelStyle,
  });

  final SamsaraEngine engine;
  final Color? backgroundColor;
  final Widget? closeButton;
  final String? label;
  final TextStyle? labelStyle;

  @override
  State<Console> createState() => _ConsoleState();
}

class _ConsoleState extends State<Console> {
  static int _commandHistoryIndex = 0;
  static final _commandHistory = <String>[];
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _keyboardListenerFocusNode = FocusNode();
  late final FocusNode _textFieldFocusNode;
  late final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textEditingController.dispose();
    _keyboardListenerFocusNode.dispose();
    _textFieldFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  void initState() {
    super.initState();

    _textFieldFocusNode = FocusNode(onKeyEvent: (_, KeyEvent event) {
      if (event is KeyUpEvent) {
        switch (event.logicalKey) {
          case LogicalKeyboardKey.escape:
            Navigator.maybePop(context, null);
          case LogicalKeyboardKey.enter:
            if (HardwareKeyboard.instance.isControlPressed) {
              submit();
              return KeyEventResult.handled;
            }
          case LogicalKeyboardKey.arrowUp: // up
            if (HardwareKeyboard.instance.isControlPressed) {
              if (_commandHistoryIndex > 0) {
                --_commandHistoryIndex;
              }
              if (_commandHistory.isNotEmpty) {
                _textEditingController.text =
                    _commandHistory[_commandHistoryIndex];
              } else {
                _textEditingController.text = '';
              }
              return KeyEventResult.handled;
            }
          case LogicalKeyboardKey.arrowDown: // down
            if (HardwareKeyboard.instance.isControlPressed) {
              if (_commandHistoryIndex < _commandHistory.length - 1) {
                ++_commandHistoryIndex;
                _textEditingController.text =
                    _commandHistory[_commandHistoryIndex];
              } else {
                _textEditingController.text = '';
              }
              return KeyEventResult.handled;
            }
        }
      }
      return KeyEventResult.ignored;
    });

    jumpToEnd();
  }

  void submit() {
    final text = _textEditingController.text.trim();
    _textEditingController.text = '';
    if (text.isNotBlank) {
      _commandHistory.add(text);
      _commandHistoryIndex = _commandHistory.length;
      try {
        widget.engine.info('>>>$text');
        final result = widget.engine.hetu.eval(text, globallyImport: true);
        final formatted = widget.engine.hetu.lexicon.stringify(result);
        widget.engine.warning('execution result: $formatted');
      } catch (error) {
        widget.engine.error(error.toString());
      }
    }
    jumpToEnd();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final rawLogs = widget.engine.getLogsRaw();
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.engine.locale('console')),
        actions: [widget.closeButton ?? CloseButton()],
      ),
      body: Column(
        children: [
          Expanded(
            child: ScrollConfiguration(
              behavior: MaterialScrollBehavior(),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView(
                    shrinkWrap: true,
                    children: rawLogs.map((log) {
                      return Text(
                        log.$2,
                        style: TextStyle(
                          color: getColorForLogLevel(log.$1),
                          fontSize: 14.0,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: fluent.InfoLabel(
              label: widget.label ??
                  'Press Ctrl+Enter to submit. Press Ctrl+Up/Down to navigate command history.',
              labelStyle: widget.labelStyle,
              child: fluent.TextBox(
                maxLines: null,
                focusNode: _textFieldFocusNode,
                controller: _textEditingController,
                autofocus: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
