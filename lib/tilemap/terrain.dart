import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';

import '../components/game_component.dart';
import 'tile_mixin.dart';
import '../animation/sprite_animation.dart';
import '../utils/json.dart';
import 'tilemap.dart';
import '../extensions.dart';

class TileMapTerrain extends GameComponent with TileInfo {
  static const defaultAnimationStepTime = 0.2;

  static final gridPaint = Paint()
    ..color = Colors.blue.withAlpha(128)
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke;

  TileMapTerrain({
    required this.map,
    required this.mapId,
    required this.terrainSpriteSheet,
    required TileShape tileShape,
    // this.renderDirection = TileRenderDirection.bottomRight,
    this.data,
    required int left,
    required int top,
    // bool isLighted = true,
    // bool isOnLightPerimeter = false,
    required Vector2 srcSize,
    required Vector2 gridSize,
    String? kind,
    String? zoneId,
    String? nationId,
    String? locationId,
    String? objectId,
    bool? isNonEnterable,
    bool? isWater,
    Sprite? sprite,
    SpriteAnimationWithTicker? animation,
    Sprite? overlaySprite,
    SpriteAnimationWithTicker? overlayAnimation,
    Vector2? offset,
  })  : assert(!gridSize.isZero()),
        assert(!srcSize.isZero()),
        _kind = kind,
        _locationId = locationId,
        _objectId = objectId,
        _nationId = nationId,
        _zoneId = zoneId,
        _isNonEnterable = isNonEnterable ?? false,
        _isWater = isWater ?? false,
        _overlayAnimation = overlayAnimation,
        _animation = animation,
        _sprite = sprite,
        _overlaySprite = overlaySprite {
    this.tileShape = tileShape;
    this.gridSize = gridSize;
    this.srcSize = srcSize;
    this.offset = offset ?? Vector2.zero();

    tilePosition = TilePosition(left, top);

    _overlayAnimationPlaytimeOffset = math.Random().nextDouble() * 5;
  }

  final TileMap map;

  /// internal data of this tile, possible json or other user-defined data form.
  final dynamic data;

  final String mapId;

  final SpriteSheet terrainSpriteSheet;

  // final TileRenderDirection renderDirection;

  String? _kind;
  String? get kind => _kind;
  set kind(String? value) {
    _kind = value;
    data?['kind'] = value;
  }

  String? _locationId;
  String? get locationId => _locationId;
  set locationId(String? value) {
    _locationId = value;
    data?['locationId'] = value;
  }

  String? _objectId;
  String? get objectId => _objectId;
  set objectId(String? value) {
    _objectId = value;
    data?['objectId'] = value;
  }

  String? _nationId;
  String? get nationId => _nationId;
  set nationId(String? value) {
    _nationId = value;
    data?['nationId'] = value;
  }

  String? _zoneId;
  String? get zoneId => _zoneId;
  set zoneId(String? value) {
    _zoneId = value;
    data?['zoneId'] = value;
  }

  bool _isNonEnterable;
  bool get isNonEnterable => _isNonEnterable;
  set isNonEnterable(bool value) {
    _isNonEnterable = value;
    data?['isNonEnterable'] = value;
  }

  bool _isWater;
  bool get isWater => _isWater;
  set isWater(bool value) {
    _isWater = value;
    data?['isWater'] = value;
  }

  bool isLighted = false;

  // 显示标签
  String? caption;
  TextStyle? captionStyle;

  /// 显示贴图
  Sprite? _sprite, _overlaySprite;
  Vector2 _overlaySpriteOffset = Vector2.zero();
  SpriteAnimationWithTicker? _animation, _overlayAnimation;

  // 随机数，用来让多个 tile 的贴图动画错开播放
  late final double _overlayAnimationPlaytimeOffset;
  double _overlayAnimationOffsetValue = 0;

  Future<void> _tryLoadSprite({bool isOverlay = false}) async {
    final spriteData = isOverlay ? (data?['overlaySprite']) : data;
    final offset =
        Vector2(spriteData?['offsetX'] ?? 0.0, spriteData?['offsetY'] ?? 0.0);

    Vector2 spriteSrcSize = srcSize;
    if (spriteData?['srcWidth'] != null && spriteData?['srcHeight'] != null) {
      spriteSrcSize =
          Vector2(spriteData!['srcWidth'], spriteData!['srcHeight']);
    }

    Sprite? sprite;
    final String? spritePath = spriteData?['sprite'];
    final int? spriteIndex = spriteData?['spriteIndex'];
    if (spritePath != null) {
      sprite = await Sprite.load(spritePath, srcSize: spriteSrcSize);
    } else if (spriteIndex != null) {
      sprite = terrainSpriteSheet.getSpriteById(spriteIndex);
    } else {
      sprite = null;
    }
    if (!isOverlay) {
      _sprite = sprite;
    } else {
      _overlaySpriteOffset = offset;
      _overlaySprite = sprite;
    }
  }

  Future<void> _tryLoadAnimationFromData({bool isOverlay = false}) async {
    final spriteData = isOverlay ? (data?['overlaySprite']) : data;
    final animationData =
        isOverlay ? data?['overlaySprite']?['animation'] : data?['animation'];

    final offset =
        Vector2(spriteData?['offsetX'] ?? 0.0, spriteData?['offsetY'] ?? 0.0);
    Vector2 spriteSrcSize = srcSize;
    if (spriteData?['srcWidth'] != null && spriteData?['srcHeight'] != null) {
      spriteSrcSize =
          Vector2(spriteData!['srcWidth'], spriteData!['srcHeight']);
    }

    SpriteAnimationWithTicker? animation;
    final String? path = animationData?['path'];
    // final int? animationFrameCount = d?['frameCount'];
    final int from = animationData?['from'] ?? 0;
    final int? to = animationData?['to'];
    final int? row = animationData?['row'];
    final double stepTime =
        animationData?['stepTime'] ?? defaultAnimationStepTime;
    final bool loop = animationData?['loop'] ?? true;
    if (path != null) {
      final sheet = SpriteSheet(
          image: await Flame.images.load(path), srcSize: spriteSrcSize);
      animation = SpriteAnimationWithTicker(
        animation: sheet.createAnimation(
          row: row ?? 0,
          stepTime: stepTime,
          loop: loop,
          from: from,
          to: to ?? sheet.columns,
        ),
      );
    } else if (row != null) {
      animation = SpriteAnimationWithTicker(
        animation: terrainSpriteSheet.createAnimation(
          from: from,
          to: to,
          row: row,
          stepTime: stepTime,
          loop: loop,
        ),
      );
    } else {
      animation = null;
    }
    if (!isOverlay) {
      _animation = animation;
    } else {
      _overlaySpriteOffset = offset;
      _overlayAnimation = animation;
    }
  }

  @override
  FutureOr<void> onLoad() {
    tryLoadSprite();
    if (data['overlaySprite'] != null) {
      tryLoadSprite(isOverlay: true);
    }
  }

  void updateData({
    bool updateSprite = false,
    bool updateOverlaySprite = false,
  }) {
    kind = data?['kind'];
    locationId = data?['locationId'];
    objectId = data?['objectId'];
    nationId = data?['nationId'];
    zoneId = data?['zoneId'];
    isNonEnterable = data?['isNonEnterable'] ?? false;

    if (updateSprite) {
      tryLoadSprite();
    }
    if (updateOverlaySprite) {
      tryLoadSprite(isOverlay: true);
    }
  }

  void tryLoadSprite({bool isOverlay = false}) async {
    await _tryLoadSprite(isOverlay: isOverlay);
    await _tryLoadAnimationFromData(isOverlay: isOverlay);
  }

  void overrideSpriteData(dynamic spriteData, {bool isOverlay = false}) {
    jsonLikeDataAssign(data, spriteData);
    tryLoadSprite(isOverlay: isOverlay);
  }

  void clearAllSprite() {
    data['sprite'] = null;
    data['spriteIndex'] = null;
    data['overlaySprite'] = null;
    _sprite = null;
    _animation = null;
    _overlaySprite = null;
    _overlayAnimation = null;
  }

  void clearSprite() {
    data['sprite'] = null;
    data['spriteIndex'] = null;
    _sprite = null;
  }

  void clearAnimation() {
    data['animation'] = null;
    _animation = null;
  }

  void clearOverlaySprite() {
    data?['overlaySprite']?['sprite'] = null;
    data?['overlaySprite']?['spriteIndex'] = null;
    _overlaySprite = null;
  }

  void clearOverlayAnimation() {
    data?['overlaySprite']?['animation'] = null;
    _overlayAnimation = null;
  }

  @override
  void render(Canvas canvas) {
    if (!isVisible) return;

    _sprite?.renderRect(canvas, renderRect);
    _animation?.ticker.currentFrame.sprite.renderRect(canvas, renderRect);
    _overlaySprite?.renderRect(
        canvas, renderRect.stretchTo(_overlaySpriteOffset));

    if (map.isEditorMode) {
      canvas.drawPath(borderPath, gridPaint);
    }

    if (map.isEditorMode || map.isTileWithinSight(this)) {
      _overlayAnimation?.ticker.currentFrame.sprite
          .renderRect(canvas, renderRect.stretchTo(_overlaySpriteOffset));
    }

    if (map.colorMode != kColorModeNone) {
      final color = map.zoneColors[map.colorMode][index];
      if (color != null) {
        var paint = map.cachedPaints[color];
        paint ??= map.cachedPaints[color] = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        canvas.drawPath(borderPath, paint);
      }
    }
  }

  // TODO:计算是否在屏幕上可见
  @override
  bool get isVisible => map.isTileVisibleOnScreen(this);

  @override
  void update(double dt) {
    if (!isVisible) return;

    super.update(dt);
    _animation?.ticker.update(dt);
    if (_overlayAnimation != null) {
      _overlayAnimation?.ticker.update(dt);
      if (_overlayAnimation!.ticker.done()) {
        _overlayAnimationOffsetValue += dt;
        if (_overlayAnimationOffsetValue >= _overlayAnimationPlaytimeOffset) {
          _overlayAnimationOffsetValue = 0;
          _overlayAnimation!.ticker.reset();
        }
      }
    }
  }
}
