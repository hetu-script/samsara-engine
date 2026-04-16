import 'dart:ui';

import 'package:flutter/foundation.dart';

const kHoverInfoMaxWidth = 400.0;

enum HoverContentDirection {
  topLeft,
  topCenter,
  topRight,
  leftTop,
  leftCenter,
  leftBottom,
  rightTop,
  rightCenter,
  rightBottom,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

class HoverContent {
  final dynamic data;
  final Rect rect;
  final double maxWidth;
  final HoverContentDirection direction;
  final TextAlign textAlign;

  HoverContent({
    required this.rect,
    required this.data,
    this.maxWidth = kHoverInfoMaxWidth,
    this.direction = HoverContentDirection.bottomCenter,
    this.textAlign = TextAlign.center,
  });
}

class HoverContentState extends ChangeNotifier {
  bool isDetailed = false;
  HoverContent? content;
  String? currentId;

  /// 可选的内容构建器，用于在 isDetailed 切换时重新生成内容
  dynamic Function(bool isDetailed)? _contentBuilder;

  void setCurrentId(String? id) {
    currentId = id;
  }

  void show({
    required Rect rect,
    dynamic data,
    double maxWidth = kHoverInfoMaxWidth,
    HoverContentDirection direction = HoverContentDirection.bottomCenter,
    TextAlign textAlign = TextAlign.center,
    dynamic Function(bool isDetailed)? contentBuilder,
  }) {
    assert(data != null || contentBuilder != null);

    _contentBuilder = contentBuilder;
    content = HoverContent(
      rect: rect,
      data: data ?? contentBuilder!(isDetailed),
      maxWidth: maxWidth,
      direction: direction,
      textAlign: textAlign,
    );
    notifyListeners();
  }

  void setDetailed(bool detailed) {
    if (isDetailed == detailed) return;
    isDetailed = detailed;
    if (_contentBuilder != null && content != null) {
      content = HoverContent(
        rect: content!.rect,
        data: _contentBuilder!(isDetailed),
        maxWidth: content!.maxWidth,
        direction: content!.direction,
        textAlign: content!.textAlign,
      );
    }
    notifyListeners();
  }

  void hide() async {
    if (content != null) {
      // 这里延迟一会儿
      // 因为 HoverInfo 窗口本身可能需要一小段时间才会渲染出来
      // 如果立刻清空有可能窗口本身之后重新显示导致清空不成功
      // Future.delayed(const Duration(milliseconds: 10), () {
      _contentBuilder = null;
      content = null;
      notifyListeners();
      // });
    }
  }
}

class HoverContentDeterminedRectState extends ChangeNotifier {
  Rect? rect;

  void set(Rect renderBox) {
    if (rect == renderBox) return;
    rect = renderBox;

    notifyListeners();
  }
}
