import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:hetu_script/errors.dart';

import 'engine.dart';
import 'ui/close_button.dart';
import 'ui/responsive_window.dart';
import 'extensions.dart';

class Console extends StatefulWidget {
  const Console({
    super.key,
    required this.engine,
  });

  final SamsaraEngine engine;

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

  @override
  Widget build(BuildContext context) {
    final layout = Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.engine.locale('console')),
        actions: const [CloseButton2()],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10.0),
              child: ListView(
                controller: _scrollController,
                reverse: true,
                children: widget.engine
                    .getLog()
                    .map((line) => Text(line))
                    .toList()
                    .reversed
                    .toList(),
              ),
            ),
          ),
          KeyboardListener(
            focusNode: _keyboardListenerFocusNode,
            key: UniqueKey(),
            onKeyEvent: (KeyEvent key) {
              if (key is KeyUpEvent) {
                switch (key.logicalKey) {
                  case LogicalKeyboardKey.home: // home
                    _textEditingController.selection =
                        TextSelection.fromPosition(
                            const TextPosition(offset: 0));
                  case LogicalKeyboardKey.end: // end
                    _textEditingController.selection =
                        TextSelection.fromPosition(TextPosition(
                            offset: _textEditingController.text.length));
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
                  case LogicalKeyboardKey.enter:
                    final text = _textEditingController.text;
                    if (text.isNotBlank) {
                      _commandHistory.add(text);
                      _commandHistoryIndex = _commandHistory.length;
                      setState(() {
                        try {
                          final r = widget.engine.hetu
                              .eval(text, globallyImport: true);
                          widget.engine
                              .info(widget.engine.hetu.lexicon.stringify(r));
                        } catch (e) {
                          if (e is HTError) {
                            widget.engine.error(e.message);
                          } else {
                            widget.engine.error(e.toString());
                          }
                        }
                      });
                    }
                    _textEditingController.text = '';
                    _scrollController
                        .jumpTo(_scrollController.position.minScrollExtent);
                    _textFieldFocusNode.requestFocus();
                }
              }
            },
            child: TextField(
              focusNode: _textFieldFocusNode,
              key: UniqueKey(),
              controller: _textEditingController,
              decoration: const InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 0.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return ResponsiveWindow(
      alignment: AlignmentDirectional.center,
      child: layout,
    );
  }
}
