import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flame/components.dart';

import '../extensions.dart';

const kDefaultAnimationStepTime = 0.5;

extension AnimationWithTicker on SpriteSheet {
  List<Sprite> generateSpriteList({required int from, required int to}) {
    if (!(from >= 0 && from <= to && to < columns * rows)) {
      throw 'Invalid range: from $from to $to';
    }
    final spriteList = <Sprite>[];
    for (var i = from; i <= to; i++) {
      final sprite = getSpriteById(i);
      spriteList.add(sprite);
    }
    return spriteList;
  }

  /// Create a SpriteAnimationWithTicker
  /// If [from] is null, it will start from the first sprite of the sheet.
  /// If [to] is null, it will end at the last sprite of the row.
  SpriteAnimationWithTicker createAnimationWithTicker({
    int? from,
    int? to,
    int? row,
    required double stepTime,
    bool loop = true,
    Rect? renderRect,
  }) {
    from ??= row != null ? row * columns : 0;
    to ??= rows * columns - 1;

    final spriteList = generateSpriteList(from: from, to: to);

    return SpriteAnimationWithTicker(
      animation: SpriteAnimation.spriteList(
        spriteList,
        stepTime: stepTime,
        loop: loop,
      ),
      renderRect: renderRect,
    );
  }
}

class SpriteAnimationWithTicker {
  late SpriteAnimation animation;

  late SpriteAnimationTicker ticker;

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  final String? animationId;
  Vector2? srcSize;
  double scale;

  SpriteSheet? _spriteSheet;
  int? from, to, row;
  final double stepTime;
  final bool loop;
  Rect? renderRect;

  SpriteAnimationWithTicker({
    SpriteAnimation? animation,
    this.animationId,
    SpriteSheet? spriteSheet,
    Vector2? srcSize,
    this.scale = 1.0,
    this.from,
    this.to,
    this.row,
    this.stepTime = kDefaultAnimationStepTime,
    this.loop = true,
    this.renderRect,
  }) : _spriteSheet = spriteSheet {
    if (animation != null) {
      this.animation = animation;
      ticker = animation.createTicker();
      this.srcSize = ticker.getSprite().srcSize;
      _isLoaded = true;
    } else if (animationId != null) {
      assert(srcSize != null);
      this.srcSize = srcSize;
    } else {
      assert(spriteSheet != null);
    }
  }

  SpriteAnimationWithTicker clone() => SpriteAnimationWithTicker(
        animation: animation.clone(),
        animationId: animationId,
        spriteSheet: _spriteSheet,
        srcSize: srcSize,
        scale: scale,
        from: from,
        to: to,
        row: row,
        stepTime: stepTime,
        loop: loop,
        renderRect: renderRect,
      );

  Future<void> load() async {
    if (_isLoaded) return;

    if (animationId != null && _spriteSheet == null) {
      _spriteSheet = SpriteSheet(
        image: await Flame.images.load('animation/$animationId'),
        srcSize: srcSize!,
      );
    }

    if (_spriteSheet != null) {
      from ??= row != null ? (row! * _spriteSheet!.columns) : 0;
      to ??= _spriteSheet!.rows * _spriteSheet!.columns - 1;
      srcSize = _spriteSheet!.srcSize;
      animation = _spriteSheet!.createAnimation(
        from: from ?? 0,
        to: to,
        row: row ?? 0,
        stepTime: stepTime,
        loop: loop,
      );
      ticker = animation.createTicker();
      _isLoaded = true;
    }
  }

  Sprite get currentSprite => ticker.getSprite();

  void update(double dt) {
    if (_isLoaded) {
      ticker.update(dt);
    }
  }

  void render(Canvas canvas, {Vector2? position}) {
    if (!_isLoaded) return;

    if (renderRect != null) {
      currentSprite.renderRect(canvas, renderRect!);
    } else {
      currentSprite.render(canvas, position: position, size: srcSize! * scale);
    }
  }
}
