import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'engine.dart';
import 'extensions.dart';
import 'colors.dart';

class Console extends StatefulWidget {
  const Console({
    super.key,
    required this.engine,
    this.margin,
    this.backgroundColor,
    this.closeButton,
    this.cursor = MouseCursor.defer,
  });

  final SamsaraEngine engine;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Widget? closeButton;
  final MouseCursor cursor;

  @override
  State<Console> createState() => _ConsoleState();
}

class _ConsoleState extends State<Console> {
  static int _commandHistoryIndex = 0;
  static final _commandHistory = <String>[];
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _keyboardListenerFocusNode = FocusNode();
  final FocusNode _textFieldFocusNode = FocusNode();
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

    jumpToEnd();
  }

  @override
  Widget build(BuildContext context) {
    final rawLogs = widget.engine.getLogsRaw();
    return Scaffold(
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
          KeyboardListener(
            focusNode: _keyboardListenerFocusNode,
            onKeyEvent: (KeyEvent key) {
              if (key is KeyUpEvent) {
                switch (key.logicalKey) {
                  case LogicalKeyboardKey.escape:
                    Navigator.maybePop(context, null);
                  case LogicalKeyboardKey.arrowUp: // up
                    if (_commandHistoryIndex > 0) {
                      --_commandHistoryIndex;
                    }
                    if (_commandHistory.isNotEmpty) {
                      _textEditingController.text =
                          _commandHistory[_commandHistoryIndex];
                    } else {
                      _textEditingController.text = '';
                    }
                  case LogicalKeyboardKey.arrowDown: // down
                    if (_commandHistoryIndex < _commandHistory.length - 1) {
                      ++_commandHistoryIndex;
                      _textEditingController.text =
                          _commandHistory[_commandHistoryIndex];
                    } else {
                      _textEditingController.text = '';
                    }
                }
              }
            },
            child: TextField(
              focusNode: _textFieldFocusNode,
              controller: _textEditingController,
              decoration: const InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 0.0),
                ),
              ),
              autofocus: true,
              onSubmitted: (value) {
                final text = _textEditingController.text;
                _textEditingController.text = '';
                _textFieldFocusNode.requestFocus();
                if (text.isNotBlank) {
                  _commandHistory.add(text);
                  _commandHistoryIndex = _commandHistory.length;
                  try {
                    widget.engine.debug('>>>$text');
                    final result =
                        widget.engine.hetu.eval(text, globallyImport: true);
                    final formatted =
                        widget.engine.hetu.lexicon.stringify(result);
                    widget.engine.log('execution result: $formatted');
                  } catch (error) {
                    widget.engine.error(error.toString());
                  }
                }
                jumpToEnd();
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }
}
