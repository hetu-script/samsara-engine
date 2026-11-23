import 'package:flutter/material.dart';
import 'package:samsara/richtext.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import 'game_dialog.dart';
import '../hover_info/hover_content.dart';
import '../widgets/ui/mouse_region2.dart';

typedef SelectionButtonBuilder =
    Widget Function(
      BuildContext context,
      String key,
      String text,
      VoidCallback onPressed,
    );

class SelectionDialog extends StatefulWidget {
  /// selection data 数据格式：
  /// ```
  /// {
  ///   selections: {
  ///     // 可以只有一个单独的文本
  ///     selectKey1: 'localedText1',
  ///     // 也可以是文本加一个描述文本
  ///     selectKey2: { text: 'localedText3', description: 'localedText4' },
  ///   }
  /// }
  static Future<String?> show(
    BuildContext context, {
    required dynamic selectionsData,
    MouseCursor? cursor,
    Color? barrierColor,
    fluent.ButtonStyle? buttonStyle,
    TextStyle? textStyle,
    SelectionButtonBuilder? buttonBuilder,
  }) async {
    return await showDialog<String>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return SelectionDialog(
          data: selectionsData,
          cursor: cursor,
          barrierColor: barrierColor,
          buttonStyle: buttonStyle,
          textStyle: textStyle,
          buttonBuilder: buttonBuilder,
        );
      },
    );
  }

  const SelectionDialog({
    super.key,
    required this.data,
    this.barrierColor,
    this.cursor,
    this.buttonStyle,
    this.textStyle,
    this.buttonBuilder,
  }) : assert(data != null);

  final dynamic data;
  final MouseCursor? cursor;
  final Color? barrierColor;
  final fluent.ButtonStyle? buttonStyle;
  final TextStyle? textStyle;
  final SelectionButtonBuilder? buttonBuilder;

  @override
  State<SelectionDialog> createState() => _SelectionDialogState();
}

class _SelectionDialogState extends State<SelectionDialog> {
  void _onSelection([String? key]) {
    context.read<HoverContentState>().hide();
    if (widget.data['taskId'] == null) {
      Navigator.pop(context, key);
    } else {
      assert(widget.data['id'] != null);
      context.read<GameDialog>().finishSelection(
        widget.data['taskId'],
        widget.data['id'],
        value: key,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const errorMsg = 'invalid selection data';
    final selectionData = widget.data?['selections'] ?? {'error': errorMsg};
    final defaultTextStyle = Theme.of(context).textTheme.bodyLarge;

    return MouseRegion(
      cursor: widget.cursor ?? MouseCursor.defer,
      hitTestBehavior: HitTestBehavior.translucent,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (widget.barrierColor != null)
              ModalBarrier(
                color: widget.barrierColor,
                onDismiss: _onSelection,
              ),
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.from(
                  selectionData.keys.map((key) {
                    final value = selectionData[key];
                    final text = value == null
                        ? errorMsg
                        : value is String
                        ? value
                        : value['text'] ?? errorMsg;
                    final description = value != null && value is! String
                        ? value['description'] as String?
                        : null;
                    final child = widget.buttonBuilder != null
                        ? widget.buttonBuilder!(
                            context,
                            key.toString(),
                            text.toString(),
                            () => _onSelection(key.toString()),
                          )
                        : fluent.Button(
                            style: widget.buttonStyle,
                            onPressed: () => _onSelection(key.toString()),
                            child: Label(
                              text.toString(),
                              textStyle: TextStyle(
                                fontFamily: defaultTextStyle?.fontFamily,
                                fontSize: defaultTextStyle?.fontSize,
                              ).merge(widget.textStyle),
                              width: 300,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                            ),
                          );
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      width: 300,
                      child: MouseRegion2(
                        onEnter: description == null
                            ? null
                            : (rect) {
                                context.read<HoverContentState>().show(
                                  data: description,
                                  rect: rect,
                                  direction: HoverContentDirection.topCenter,
                                );
                              },
                        onExit: description == null
                            ? null
                            : () => context.read<HoverContentState>().hide(),
                        child: child,
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
