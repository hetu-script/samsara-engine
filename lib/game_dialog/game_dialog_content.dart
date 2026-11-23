import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';
import 'package:samsara/richtext.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import 'game_dialog.dart';
import 'avatar.dart';

typedef GameDialogFrameBuilder =
    Widget Function(BuildContext context, Widget child);

class GameDialogContent extends StatefulWidget {
  /// 调用这个方法不会触发 GameDialogState 的改变
  ///
  /// dialog data 数据格式
  /// ```javascript
  /// {
  ///   name: string,
  ///   icon: icon,
  ///   image: string,
  ///   lines: []string,
  /// }
  /// ```
  static Future<void> show(
    BuildContext context,
    dynamic data, {
    MouseCursor? cursor,
    Color barrierColor = Colors.transparent,
    TextStyle? textStyle,
    TextStyle? nameTextStyle,
    BoxDecoration? decoration,
    GameDialogFrameBuilder? frameBuilder,
    double? width,
    double? height,
    double? bottom,
    Size? avatarSize,
    EdgeInsetsGeometry? avatarMargin,
    EdgeInsetsGeometry? contentPadding,
    EdgeInsetsGeometry? textPadding,
    void Function(dynamic)? onAvatarPressed,
  }) {
    final resolved = data is String
        ? {'lines': data.split('\n')}
        : (data is List ? {'lines': data} : data);
    assert(resolved is Map || resolved is HTStruct);
    assert(resolved['id'] == null);
    return showDialog<dynamic>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return GameDialogContent(
          data: resolved,
          cursor: cursor,
          barrierColor: barrierColor,
          textStyle: textStyle,
          nameTextStyle: nameTextStyle,
          decoration: decoration,
          frameBuilder: frameBuilder,
          width: width,
          height: height,
          bottom: bottom,
          avatarSize: avatarSize,
          avatarMargin: avatarMargin,
          contentPadding: contentPadding,
          textPadding: textPadding,
          onAvatarPressed: onAvatarPressed,
        );
      },
    );
  }

  const GameDialogContent({
    super.key,
    required this.data,
    this.textStyle,
    this.nameTextStyle,
    this.barrierColor,
    this.cursor,
    this.decoration,
    this.frameBuilder,
    this.width,
    this.height,
    this.bottom,
    this.avatarSize,
    this.avatarMargin,
    this.contentPadding,
    this.textPadding,
    this.onAvatarPressed,
  }) : assert(data != null);

  final dynamic data;
  final MouseCursor? cursor;
  final Color? barrierColor;
  final TextStyle? textStyle;
  final TextStyle? nameTextStyle;
  final BoxDecoration? decoration;
  final GameDialogFrameBuilder? frameBuilder;
  final double? width;
  final double? height;
  final double? bottom;
  final Size? avatarSize;
  final EdgeInsetsGeometry? avatarMargin;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? textPadding;
  final void Function(dynamic)? onAvatarPressed;

  @override
  State<GameDialogContent> createState() => _GameDialogContentState();
}

class _GameDialogContentState extends State<GameDialogContent> {
  Timer? _timer;
  String? _currentAvatar;
  String _currentLine = '';
  List<String> _nodes = [];
  String? _name;
  int _currentSayIndex = 0;
  int _progress = 0;
  bool _lineFinished = false;

  final _textShowController = StreamController<TextSpan>.broadcast();

  late TextStyle _style;

  @override
  void initState() {
    super.initState();
    _resolveTextStyle();
    _scheduleStartLine();
  }

  @override
  void didUpdateWidget(covariant GameDialogContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resolveTextStyle();
    if (oldWidget.data != widget.data) {
      _currentSayIndex = 0;
      _scheduleStartLine();
    }
  }

  void _resolveTextStyle() {
    _style = const TextStyle(
      fontSize: 20,
      letterSpacing: 2,
      fontWeight: FontWeight.normal,
      decoration: TextDecoration.none,
    ).merge(widget.textStyle);
  }

  void _scheduleStartLine() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startLine();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textShowController.close();
    super.dispose();
  }

  void _onTap() {
    if (_lineFinished) {
      _nextSay();
    } else {
      _finishLine();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.cursor ?? MouseCursor.defer,
      hitTestBehavior: HitTestBehavior.translucent,
      child: GestureDetector(
        onTap: _onTap,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            alignment: AlignmentDirectional.bottomCenter,
            children: [
              if (widget.barrierColor != null)
                ModalBarrier(
                  color: widget.barrierColor,
                  onDismiss: _onTap,
                ),
              Positioned(
                bottom: widget.bottom ?? 20.0,
                child: StreamBuilder<TextSpan>(
                  stream: _textShowController.stream,
                  builder: (context, snapshot) {
                    final content = SizedBox.expand(
                      child: Row(
                        children: [
                          Avatar(
                            margin:
                                widget.avatarMargin ??
                                const EdgeInsets.only(left: 20.0),
                            image: _currentAvatar != null
                                ? AssetImage('assets/images/$_currentAvatar')
                                : null,
                            size:
                                widget.avatarSize ?? const Size(140.0, 140.0),
                            onPressed: (_) {
                              widget.onAvatarPressed?.call(
                                widget.data?['characterId'],
                              );
                            },
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                                  widget.contentPadding ??
                                  const EdgeInsets.only(left: 20.0, top: 10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10.0,
                                    ),
                                    child: Label(
                                      _name ?? '',
                                      textStyle:
                                          widget.nameTextStyle ??
                                          const TextStyle(fontSize: 20),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        widget.textPadding ??
                                        const EdgeInsets.only(left: 5.0),
                                    child: RichText(
                                      text:
                                          snapshot.data ?? const TextSpan(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (widget.frameBuilder != null) {
                      return widget.frameBuilder!(context, content);
                    }
                    return Container(
                      width: widget.width ?? 880.0,
                      height: widget.height ?? 190.0,
                      decoration: widget.decoration,
                      child: Stack(
                        children: [
                          const Positioned.fill(
                            child: fluent.Acrylic(
                              luminosityAlpha: 0.4,
                              blurAmount: 5.0,
                            ),
                          ),
                          content,
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startLine() {
    _timer?.cancel();
    final lines = widget.data?['lines'] as List? ?? const [];
    if (_currentSayIndex >= lines.length) {
      _finishDialog();
      return;
    }
    setState(() {
      _lineFinished = false;
      _progress = 0;
      _currentAvatar = widget.data['icon'];
      _name = widget.data['name'];
      _currentLine = lines[_currentSayIndex].toString();
      _nodes = getRichTextStream(_currentLine);
    });
    if (!_textShowController.isClosed) {
      _textShowController.add(const TextSpan());
    }
    if (_nodes.isEmpty) {
      _finishLine();
      return;
    }

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || _textShowController.isClosed) {
        timer.cancel();
        return;
      }
      _progress++;
      if (_progress >= _nodes.length) {
        _finishLine();
      } else {
        _textShowController.add(
          TextSpan(
            children: buildFlutterRichText(
              _nodes.sublist(0, _progress).join(),
              style: _style,
            ),
          ),
        );
      }
    });
  }

  void _nextSay() {
    _currentSayIndex++;
    _startLine();
  }

  void _finishLine() {
    _timer?.cancel();
    _lineFinished = true;
    if (!_textShowController.isClosed) {
      _textShowController.add(
        TextSpan(
          children: buildFlutterRichText(_currentLine, style: _style),
        ),
      );
    }
  }

  void _finishDialog() {
    _timer?.cancel();
    _currentSayIndex = 0;
    final id = widget.data?['id'];
    if (id != null) {
      context.read<GameDialog>().finishDialog(id);
    } else {
      Navigator.of(context).pop();
    }
  }
}
