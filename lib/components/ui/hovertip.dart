import '../../richtext.dart';
import '../../samsara.dart';

enum HovertipDirection {
  none,
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

const kHovertipScreenIndent = 10.0;
const kHovertipContentIndent = 10.0;
const kHovertipBackgroundBorderRadius = 5.0;
const kHovertipDefautWidth = 400.0;

class Hovertip extends BorderComponent {
  static Hovertip? _globalInstance;
  static final Map<String, Hovertip> _cachedInstances = {};

  static final Map<GameComponent, Hovertip> _instances = {};

  static ScreenTextConfig defaultContentConfig = ScreenTextConfig();

  // static bool showBorder = false;
  static Paint backgroundPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.black.withAlpha(200);

  static void clearAll([List<GameComponent>? list]) {
    if (list == null) {
      for (final instance in _instances.values) {
        instance.removeFromParent();
      }
      _instances.clear();
    } else {
      for (final target in list) {
        if (_instances.containsKey(target)) {
          _instances[target]!.removeFromParent();
          _instances.remove(target);
        }
      }
    }
  }

  static void show({
    required Scene scene,
    GameComponent? target,
    String? content,
    ScreenTextConfig? config,
    HovertipDirection direction = HovertipDirection.topLeft,
    double width = kHovertipDefautWidth,
    Vector2? position,
    EdgeInsets? margin,
  }) {
    final escapedContent =
        (content?.trim() ?? '').replaceAllEscapedLineBreaks();

    Hovertip instance;
    if (_cachedInstances[escapedContent] != null) {
      instance = _cachedInstances[escapedContent]!;
    } else {
      instance = Hovertip();
      instance.setContent(escapedContent, config: config, width: width);
      _cachedInstances[escapedContent] = instance;
    }
    hide(target);
    if (target != null) {
      _instances[target] = instance;
    } else {
      _globalInstance = instance;
    }

    Vector2 calculatedPosition;

    if (target != null) {
      final targetPosition = target.absoluteTopLeftPosition;
      Vector2 targetGlobalPosition = targetPosition;
      Vector2 targetGlobalSize = target.size;
      if (!target.isHud) {
        targetGlobalPosition = scene.camera.localToGlobal(targetPosition);
        targetGlobalSize = target.size * scene.camera.zoom;
      }

      switch (direction) {
        case HovertipDirection.topLeft:
          calculatedPosition = Vector2(
              targetGlobalPosition.x + (margin?.left ?? 0),
              targetGlobalPosition.y -
                  (margin?.bottom ?? kHovertipScreenIndent) -
                  instance.height);
        case HovertipDirection.topCenter:
          calculatedPosition = Vector2(
              targetGlobalPosition.x -
                  (instance.width - targetGlobalSize.x) / 2,
              targetGlobalPosition.y -
                  (margin?.bottom ?? kHovertipScreenIndent) -
                  instance.height);
        case HovertipDirection.topRight:
          calculatedPosition = Vector2(
              targetGlobalPosition.x +
                  targetGlobalSize.x -
                  instance.width -
                  (margin?.right ?? 0),
              targetGlobalPosition.y - kHovertipScreenIndent - instance.height);
        case HovertipDirection.leftTop:
          calculatedPosition = Vector2(
              targetGlobalPosition.x -
                  (margin?.right ?? kHovertipScreenIndent) -
                  instance.width,
              targetGlobalPosition.y + (margin?.top ?? 0));
        case HovertipDirection.leftCenter:
          calculatedPosition = Vector2(
              targetGlobalPosition.x - kHovertipScreenIndent - instance.width,
              targetGlobalPosition.y -
                  (instance.height - targetGlobalSize.y) / 2);
        case HovertipDirection.leftBottom:
          calculatedPosition = Vector2(
              targetGlobalPosition.x - kHovertipScreenIndent - instance.width,
              targetGlobalPosition.y + targetGlobalSize.y - instance.height);
        case HovertipDirection.rightTop:
          calculatedPosition = Vector2(
              targetGlobalPosition.x +
                  targetGlobalSize.x +
                  kHovertipScreenIndent,
              targetGlobalPosition.y);
        case HovertipDirection.rightCenter:
          calculatedPosition = Vector2(
              targetGlobalPosition.x +
                  targetGlobalSize.x +
                  kHovertipScreenIndent,
              targetGlobalPosition.y -
                  (instance.height - targetGlobalSize.y) / 2);
        case HovertipDirection.rightBottom:
          calculatedPosition = Vector2(
              targetGlobalPosition.x +
                  targetGlobalSize.x +
                  kHovertipScreenIndent,
              targetGlobalPosition.y + targetGlobalSize.y - instance.height);
        case HovertipDirection.bottomLeft:
          calculatedPosition = Vector2(
              targetGlobalPosition.x,
              targetGlobalPosition.y +
                  targetGlobalSize.y +
                  kHovertipScreenIndent);
        case HovertipDirection.bottomCenter:
          calculatedPosition = Vector2(
              targetGlobalPosition.x -
                  (instance.width - targetGlobalSize.x) / 2,
              targetGlobalPosition.y +
                  targetGlobalSize.y +
                  kHovertipScreenIndent);
        case HovertipDirection.bottomRight:
          calculatedPosition = Vector2(
              targetGlobalPosition.x + targetGlobalSize.x - instance.width,
              targetGlobalPosition.y +
                  targetGlobalSize.y +
                  kHovertipScreenIndent);
        case HovertipDirection.none:
          final targetCenter = target.absoluteCenter;
          final targetCenterGlobal = scene.camera.localToGlobal(targetCenter);
          calculatedPosition = targetCenterGlobal;
      }
    } else {
      // target is null, position based on screen and margin
      double x = 0;
      double y = 0;

      if (margin != null) {
        if (margin.left != 0) {
          x = margin.left;
          if (margin.top == 0 && margin.bottom == 0) {
            if (direction == HovertipDirection.leftTop) {
              y = kHovertipScreenIndent;
            } else if (direction == HovertipDirection.leftCenter) {
              y = scene.size.y / 2 - instance.height / 2;
            } else if (direction == HovertipDirection.leftBottom) {
              y = scene.size.y - instance.height - kHovertipScreenIndent;
            }
          }
        } else if (margin.right != 0) {
          x = scene.size.x - instance.width - margin.right;
        }

        if ((margin.left != 0 || margin.right != 0) &&
            (margin.top == 0 && margin.bottom == 0)) {
          if (direction == HovertipDirection.leftTop ||
              direction == HovertipDirection.rightTop) {
            y = kHovertipScreenIndent;
          } else if (direction == HovertipDirection.leftCenter ||
              direction == HovertipDirection.rightCenter) {
            y = scene.size.y / 2 - instance.height / 2;
          } else if (direction == HovertipDirection.leftBottom ||
              direction == HovertipDirection.rightBottom) {
            y = scene.size.y - instance.height - kHovertipScreenIndent;
          }
        }

        if (margin.top != 0) {
          y = margin.top;
        } else if (margin.bottom != 0) {
          y = scene.size.y - instance.height - margin.bottom;
        }

        if ((margin.top != 0 || margin.bottom != 0) &&
            (margin.left == 0 && margin.right == 0)) {
          if (direction == HovertipDirection.topLeft ||
              direction == HovertipDirection.bottomLeft) {
            x = kHovertipScreenIndent;
          } else if (direction == HovertipDirection.topCenter ||
              direction == HovertipDirection.bottomCenter) {
            x = scene.size.x / 2 - instance.width / 2;
          } else if (direction == HovertipDirection.topRight ||
              direction == HovertipDirection.bottomRight) {
            x = scene.size.x - instance.width - kHovertipScreenIndent;
          }
        }
      }
      calculatedPosition = Vector2(x, y);
    }

    // 检查是否超出了游戏屏幕
    if (calculatedPosition.x < 0) {
      calculatedPosition.x = 0;
    }
    if (calculatedPosition.y < 0) {
      calculatedPosition.y = 0;
    }
    if (calculatedPosition.x + instance.width > scene.camera.viewport.size.x) {
      calculatedPosition.x = scene.camera.viewport.size.x - instance.width;
    }
    if (calculatedPosition.y + instance.height > scene.camera.viewport.size.y) {
      calculatedPosition.y = scene.camera.viewport.size.y - instance.height;
    }

    instance.position = calculatedPosition;
    scene.camera.viewport.add(instance);
  }

  static void hide([GameComponent? target]) async {
    if (target == null) {
      _globalInstance?.removeFromParent();
      _globalInstance = null;
    } else {
      if (_instances.containsKey(target)) {
        final instance = _instances[target];
        instance!.removeFromParent();
        _instances.remove(target);
      }
    }
  }

  static void hideAll() {
    _globalInstance?.removeFromParent();
    _globalInstance = null;
    for (final instance in _instances.values) {
      instance.removeFromParent();
    }
    _instances.clear();
    for (final instance in _cachedInstances.values) {
      instance.removeFromParent();
    }
    _cachedInstances.clear();
  }

  static void toogle(GameComponent target,
      {required Scene scene, bool justShow = false}) async {
    assert(_instances.containsKey(target));
    final instance = _instances[target];
    if (instance!.isMounted) {
      if (!justShow) {
        instance.removeFromParent();
      }
    } else {
      scene.camera.viewport.add(_instances[target]!);
    }
  }

  static bool hastip(GameComponent target) {
    return _instances.containsKey(target);
  }

  String _content = '';
  String get content => _content;
  DocumentRoot? _contentDocument;
  GroupElement? _contentElement;
  late ScreenTextConfig contentConfig;
  // late TextPaint _contentPaint;

  Hovertip({
    ScreenTextConfig? contentConfig,
    // super.borderRadius = 5.0,
    // super.borderWidth = 5.0,
    // super.borderPaint,
  }) : super(priority: 9999999999) {
    this.contentConfig = (contentConfig ?? const ScreenTextConfig())
        .fillFrom(defaultContentConfig);
    // _contentPaint = getTextPaint(config: contentConfig);
  }

  void setContent(String content,
      {ScreenTextConfig? config, required double width}) {
    _content = content;
    contentConfig = contentConfig.copyFrom(config);
    _contentDocument =
        buildFlameRichText(_content, style: contentConfig.textStyle);
    _calculateSize(width: width);
  }

  void _calculateSize({required double width}) {
    if (_contentDocument == null) return;

    // double preferredHeight = contentHeight + kTooltipContentIndent * 2;
    // size = Vector2(preferredWidth, preferredHeight);

    // if (_content != null) {
    //   _contentRect = Rect.fromLTWH(
    //     kTooltipContentIndent,
    //     kTooltipContentIndent,
    //     width - kTooltipContentIndent * 2,
    //     height - kTooltipContentIndent * 2,
    //   );

    //   contentConfig =
    //       contentConfig.copyWith(size: _contentRect.size.toVector2());
    // }

    double contentWidth = width - kHovertipContentIndent * 2;
    final contentAnchor = contentConfig.anchor ?? Anchor.topLeft;

    _contentElement = _contentDocument!.format(DocumentStyle(
      paragraph: BlockStyle(
          margin: EdgeInsets.zero, textAlign: contentConfig.textAlign),
      text: contentConfig.textStyle?.toInlineTextStyle(),
      width: contentWidth,
    ));
    final boundingBox = _contentElement!.boundingBox;
    size = Vector2(width, boundingBox.height + kHovertipContentIndent * 2);
    // 文本区域的左中右对齐已经由 document.format 的 textAlign 处理
    // 下面只是单独处理垂直方向的对齐
    switch (contentAnchor) {
      case Anchor.topLeft:
        _contentElement!
            .translate(kHovertipContentIndent, kHovertipContentIndent);
      case Anchor.topCenter:
        _contentElement!
            .translate(kHovertipContentIndent, kHovertipContentIndent);
      case Anchor.topRight:
        _contentElement!
            .translate(kHovertipContentIndent, kHovertipContentIndent);
      case Anchor.centerLeft:
        _contentElement!.translate(
            0,
            kHovertipContentIndent +
                (height - boundingBox.height - kHovertipContentIndent * 2) / 2);
      case Anchor.center:
        _contentElement!.translate(
            0,
            kHovertipContentIndent +
                (height - boundingBox.height - kHovertipContentIndent * 2) / 2);
      case Anchor.centerRight:
        _contentElement!.translate(
            0,
            kHovertipContentIndent +
                (height - boundingBox.height - kHovertipContentIndent * 2) / 2);
      case Anchor.bottomLeft:
        _contentElement!.translate(kHovertipContentIndent,
            height - kHovertipContentIndent - boundingBox.height);
      case Anchor.bottomCenter:
        _contentElement!.translate(kHovertipContentIndent,
            height - kHovertipContentIndent - boundingBox.height);
      case Anchor.bottomRight:
        _contentElement!.translate(kHovertipContentIndent,
            height - kHovertipContentIndent - boundingBox.height);
      default:
    }
  }

  @override
  void render(Canvas canvas) {
    // if (showBorder) {
    //   canvas.drawRect(border, borderPaint);
    // }
    canvas.drawRect(border, backgroundPaint);
    // canvas.drawRRect(roundBorder, borderPaint);
    // canvas.drawRRect(roundBorder, backgroundPaint);

    if (_contentElement != null) {
      _contentElement!.draw(canvas);
    }

    // if (_content != null) {
    //   drawScreenText(
    //     canvas,
    //     _content!,
    //     position: _contentRect.topLeft,
    //     textPaint: _contentPaint,
    //     config: contentConfig,
    //   );
    // }
  }
}
