import 'dart:async';

import 'package:flutter/painting.dart';
import 'package:flame/components.dart';
import 'package:flame/rendering.dart';
import 'package:meta/meta.dart';

import '../gestures.dart';
import '../samsara.dart';

/// Custom decorator for handling clip and zoom transformations
class ClipAndZoomDecorator extends Decorator {
  final Vector2 clipOffset;
  final double zoom;
  final Rect clipRect;

  ClipAndZoomDecorator({
    required this.clipOffset,
    required this.zoom,
    required this.clipRect,
  });

  @override
  void apply(void Function(Canvas) draw, Canvas canvas) {
    canvas.save();
    canvas.clipRect(clipRect);
    canvas.translate(-clipOffset.x, -clipOffset.y);
    canvas.scale(zoom);
    draw(canvas);
    canvas.restore();
  }
}

/// A modification of Flame's SpriteComponent that allows more functionality:
/// visibility, clip and zoom options.
class SpriteComponent2 extends BorderComponent with HandlesGesture {
  /// When set to true, the component is auto-resized to match the
  /// size of underlying sprite.
  bool _autoResize;

  String? _spriteId;

  /// The [sprite] to be rendered by this component.
  Sprite? _sprite;

  Color? color;

  BoxFit boxFit;

  bool clipMode;
  double _zoom; // 缩放倍数

  /// Updates zoom and refreshes the decorator
  set zoom(double newZoom) {
    _zoom = newZoom.clamp(1.0, 2.0);
    _updateClipDecorator();
  }

  Vector2 _clipOffset = Vector2.zero(); // 裁剪偏移
  Vector2 get clipOffset => _clipOffset.clone();
  set clipOffset(Vector2 newOffset) {
    _clipOffset = newOffset;
    _updateClipDecorator();
  }

  ClipAndZoomDecorator? _clipDecorator;

  /// Creates a component with an empty sprite which can be set later
  SpriteComponent2({
    String? spriteId,
    Sprite? sprite,
    this.color,
    this.boxFit = BoxFit.fill,
    Paint? paint,
    super.position,
    Vector2? size,
    bool? autoResize,
    super.isVisible,
    super.scale,
    super.angle,
    super.nativeAngle,
    super.anchor,
    super.children,
    super.priority,
    super.key,
    super.lightConfig,
    bool enableGesture = false,
    double zoom = 1.0,
    this.clipMode = false,
  })  : assert(
          (size == null) == (autoResize ?? size == null),
          '''If size is set, autoResize should be false or size should be null when autoResize is true.''',
        ),
        _autoResize = autoResize ?? size == null,
        _spriteId = spriteId,
        _sprite = sprite,
        _zoom = zoom.clamp(1.0, 2.0),
        super(size: size ?? sprite?.srcSize) {
    if (paint != null) {
      this.paint = paint;
    }

    this.enableGesture = enableGesture;

    /// Register a listener to differentiate between size modification done by
    /// external calls v/s the ones done by [_resizeToSprite].
    this.size.addListener(_handleAutoResizeState);

    // Setup clip decorator if in clip mode
    if (clipMode) {
      _updateClipDecorator();
    }
  }

  SpriteComponent2.fromImage(
    Image image, {
    Vector2? srcPosition,
    Vector2? srcSize,
    bool? autoResize,
    Paint? paint,
    Vector2? position,
    Vector2? size,
    Vector2? scale,
    double? angle,
    double nativeAngle = 0,
    Anchor? anchor,
    Iterable<Component>? children,
    int? priority,
    ComponentKey? key,
  }) : this(
          sprite: Sprite(
            image,
            srcPosition: srcPosition,
            srcSize: srcSize,
          ),
          autoResize: autoResize,
          paint: paint,
          position: position,
          size: size,
          scale: scale,
          angle: angle,
          nativeAngle: nativeAngle,
          anchor: anchor,
          children: children,
          priority: priority,
          key: key,
        );

  /// Returns current value of auto resize flag.
  bool get autoResize => _autoResize;

  /// Sets the given value of autoResize flag. Will update the [size]
  /// to fit srcSize of [sprite] if set to  true.
  set autoResize(bool value) {
    _autoResize = value;
    _resizeToSprite();
  }

  /// This flag helps in detecting if the size modification is done by
  /// some external call vs [_autoResize]ing code from [_resizeToSprite].
  bool _isAutoResizing = false;

  /// Returns the current sprite rendered by this component.
  Sprite? get sprite => _sprite;

  /// Sets the given sprite as the new [sprite] of this component.
  /// Will update the size if [autoResize] is set to true.
  set sprite(Sprite? value) {
    _sprite = value;
    _resizeToSprite();
  }

  Future<void> tryLoadSprite({String? spriteId, Sprite? sprite}) async {
    if (spriteId != null) {
      _spriteId = spriteId;
    } else if (sprite != null) {
      _sprite = sprite;
    }
    if (_spriteId != null) {
      _sprite = await game.loadSprite(_spriteId!);
    }
    if (autoResize) {
      _resizeToSprite();
    }
  }

  @override
  FutureOr<void> onLoad() async {
    await tryLoadSprite();
  }

  @mustCallSuper
  @override
  void render(Canvas canvas) {
    if (!isVisible) return;

    if (color != null) {
      canvas.drawColor(color!, BlendMode.srcATop);
    } else if (sprite != null) {
      if (_autoResize || clipMode) {
        // 在 autoResize 或 clipMode 下，直接渲染
        // clipMode 的变换由 decorator 处理
        sprite?.render(
          canvas,
          size: size,
          overridePaint: paint,
        );
      } else {
        final thisRatio = width / height;
        final spriteRatio = sprite!.srcSize.x / sprite!.srcSize.y;

        switch (boxFit) {
          case BoxFit.none:
            sprite?.render(
              canvas,
              size: sprite?.srcSize,
              overridePaint: paint,
            );
          case BoxFit.fill:
            sprite?.render(
              canvas,
              size: size,
              overridePaint: paint,
            );
          case BoxFit.contain:
            if (thisRatio > spriteRatio) {
              final newWidth = height * spriteRatio;
              sprite?.render(
                canvas,
                size: Vector2(newWidth, height),
                overridePaint: paint,
                position: Vector2((width - newWidth) / 2, 0),
              );
            } else {
              final newHeight = width / spriteRatio;
              sprite?.render(
                canvas,
                size: Vector2(width, newHeight),
                overridePaint: paint,
                position: Vector2(0, (height - newHeight) / 2),
              );
            }
          case BoxFit.cover:
            if (thisRatio > spriteRatio) {
              final newHeight = width / spriteRatio;
              sprite?.render(
                canvas,
                size: Vector2(width, newHeight),
                overridePaint: paint,
                position: Vector2(0, (height - newHeight) / 2),
              );
            } else {
              final newWidth = height * spriteRatio;
              sprite?.render(
                canvas,
                size: Vector2(newWidth, height),
                overridePaint: paint,
                position: Vector2((width - newWidth) / 2, 0),
              );
            }
          case BoxFit.fitWidth:
            final newHeight = width / spriteRatio;
            sprite?.render(
              canvas,
              size: Vector2(width, newHeight),
              overridePaint: paint,
              position: Vector2(0, (height - newHeight) / 2),
            );
          case BoxFit.fitHeight:
            final newWidth = height * spriteRatio;
            sprite?.render(
              canvas,
              size: Vector2(newWidth, height),
              overridePaint: paint,
              position: Vector2((width - newWidth) / 2, 0),
            );
          case BoxFit.scaleDown:
            if (thisRatio > spriteRatio) {
              final newHeight = width / spriteRatio;
              sprite?.render(
                canvas,
                size: Vector2(width, newHeight),
                overridePaint: paint,
                position: Vector2(0, (height - newHeight) / 2),
              );
            } else {
              final newWidth = height * spriteRatio;
              sprite?.render(
                canvas,
                size: Vector2(newWidth, height),
                overridePaint: paint,
                position: Vector2((width - newWidth) / 2, 0),
              );
            }
        }
      }
    }
  }

  /// Updates the size [sprite]'s srcSize if [autoResize] is true.
  void _resizeToSprite() {
    if (_autoResize && _sprite != null) {
      _isAutoResizing = true;

      final newX = _sprite?.srcSize.x ?? 0;
      final newY = _sprite?.srcSize.y ?? 0;

      // Modify only if changed.
      if (size.x != newX || size.y != newY) {
        size.setValues(newX, newY);
      }

      _isAutoResizing = false;
    }
  }

  /// Turns off [_autoResize]ing if a size modification is done by user.
  void _handleAutoResizeState() {
    if (_autoResize && (!_isAutoResizing)) {
      _autoResize = false;
    }
  }

  /// Updates the clip decorator with current settings
  void _updateClipDecorator() {
    if (clipMode) {
      if (_clipDecorator == null) {
        // Create and add the clip decorator after the transform decorator
        _clipDecorator = ClipAndZoomDecorator(
          clipOffset: _clipOffset,
          zoom: _zoom,
          clipRect: border,
        );
        decorator.addLast(_clipDecorator!);
      } else {
        // Update existing decorator
        _clipDecorator = ClipAndZoomDecorator(
          clipOffset: _clipOffset,
          zoom: _zoom,
          clipRect: border,
        );
        // Replace the decorator
        decorator.removeLast();
        decorator.addLast(_clipDecorator!);
      }
    } else if (_clipDecorator != null) {
      // Remove clip decorator if clip mode is disabled
      decorator.removeLast();
      _clipDecorator = null;
    }
  }
}
