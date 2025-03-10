import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
// import 'package:hetu_script/errors.dart';

import 'engine.dart';
import 'ui/close_button2.dart';
import 'ui/responsive_view.dart';
import 'extensions.dart';

class Console extends StatefulWidget {
  const Console({
    super.key,
    required this.engine,
    this.margin,
    this.backgroundColor,
  });

  final SamsaraEngine engine;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;

  @override
  State<Console> createState() => _ConsoleState();
}

class _ConsoleState extends State<Console> {
  static int _commandHistoryIndex = 0;
  static final _commandHistory = <String>[];
  final TextEditingController _consoleOutputTextController =
      TextEditingController();
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
    _consoleOutputTextController.text = widget.engine.getLogs().join('\n');
    return ResponsiveView(
      alignment: AlignmentDirectional.center,
      margin: widget.margin,
      color: widget.backgroundColor,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(widget.engine.locale('console')),
          actions: const [CloseButton2()],
        ),
        body: Column(
          children: [
            Expanded(
              child: ScrollConfiguration(
                behavior: MaterialScrollBehavior(),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: TextField(
                    controller: _consoleOutputTextController,
                    readOnly: true,
                    maxLines: null,
                    decoration: const InputDecoration(border: InputBorder.none),
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
                      widget.engine.info('>>>$text');
                      final result =
                          widget.engine.hetu.eval(text, globallyImport: true);
                      final formatted =
                          widget.engine.hetu.lexicon.stringify(result);
                      widget.engine.info('execution result: $formatted');
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
      ),
    );
  }
}
