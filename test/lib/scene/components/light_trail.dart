import 'dart:math' as math;

import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';
import 'package:samsara/gestures.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/utils/math.dart' as math;

const _kVibrateSize = 10.0;
// const _kMoveSpeed = 10.0;
const _kLightRadius = 25.0;

class LightTrail extends BorderComponent with HandlesGesture {
  static final random = math.Random();

  double _flickerTimer = 0.0;

  late Sprite sprite;

  /// 每秒钟光晕闪烁的频率
  late double _flickerDt;
  double get flickerDt => _flickerDt;
  set flickerRate(int value) => _flickerDt = 1.0 / value;

  double preferredRadius;

  late Vector2 preferredSize;

  double _distance2CondensePoint = 0;
  double get distance2CondensePoint => _distance2CondensePoint;

  final int radius;
  final List<math.PointOnCircle> points;
  int _index;

  LightTrail({
    super.opacity,
    int flickerRate = 0,
    this.preferredRadius = _kLightRadius,
    Vector2? condensedPosition,
    required this.radius,
    required int index,
    required this.points,
  })  : _index = index,
        super(
          position: points[index].position,
          angle: points[index].angle,
          anchor: Anchor.center,
          // lightConfig: LightConfig(
          //   radius: preferredRadius,
          //   blurBorder: kLightRadius,
          //   shape: LightShape.circle,
          // ),
        ) {
    this.flickerRate = flickerRate;

    if (condensedPosition != null) {
      final dx = (position.x - condensedPosition.x).abs();
      final dy = (position.y - condensedPosition.y).abs();
      _distance2CondensePoint = math.sqrt(dx * dx + dy * dy);
    }
  }

  @override
  void onLoad() async {
    sprite =
        Sprite(await Flame.images.load('light_trail_${radius.toInt()}.png'));
    size = preferredSize = sprite.srcSize;
  }

  @override
  void update(double dt) {
    _flickerTimer += dt;

    if (_flickerTimer >= _flickerDt) {
      _flickerTimer = 0;

      size = Vector2(preferredSize.x + random.nextDouble() * _kVibrateSize,
          preferredSize.y + random.nextDouble() * _kVibrateSize);

      lightConfig!.radius = preferredRadius + random.nextDouble() * 5;
    }

    if (!isMoving) {
      _index = _index < points.length - 1 ? _index + 1 : 0;
      final next = points[_index];
      moveTo(
        toPosition: next.position,
        toAngle: next.angle,
        duration: 1.0,
      );
    }
  }

  @override
  void render(Canvas canvas) {
    if (!isVisible) return;

    sprite.renderRect(canvas, border, overridePaint: paint);
  }
}
