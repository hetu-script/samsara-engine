import 'dart:ui';
import 'dart:math' as math;

import 'package:flame/components.dart';

/// 彩色碎片/彩带粒子
class ConfettiParticle extends PositionComponent {
  static final _random = math.Random();

  final Vector2 velocity;
  final double rotationSpeed;
  final Color color;
  final ConfettiShape shape;
  final Paint _paint;

  double _rotation = 0;
  double _lifetime = 0;
  static const _maxLifetime = 5.0; // 5秒后消失
  static const _gravity = 300.0; // 重力加速度

  ConfettiParticle({
    required super.position,
    required this.velocity,
    required this.color,
    required this.shape,
    super.size,
    super.priority,
  })  : rotationSpeed = _random.nextDouble() * 10 - 5, // -5 到 5 rad/s
        _paint = Paint()
          ..color = color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;

  @override
  void update(double dt) {
    super.update(dt);

    _lifetime += dt;

    // 应用重力
    velocity.y += _gravity * dt;

    // 更新位置
    position += velocity * dt;

    // 更新旋转
    _rotation += rotationSpeed * dt;

    // 淡出效果
    if (_lifetime > _maxLifetime * 0.7) {
      final fadeProgress =
          (_lifetime - _maxLifetime * 0.7) / (_maxLifetime * 0.3);
      _paint.color =
          color.withAlpha(((1 - fadeProgress) * 255).clamp(0, 255).toInt());
    }

    // 超时或飞出屏幕则移除
    if (_lifetime > _maxLifetime || position.y > 1200) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.save();
    canvas.translate(width / 2, height / 2);
    canvas.rotate(_rotation);

    switch (shape) {
      case ConfettiShape.rectangle:
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: width, height: height),
          _paint,
        );
      case ConfettiShape.circle:
        canvas.drawCircle(Offset.zero, width / 2, _paint);
      case ConfettiShape.triangle:
        final path = Path()
          ..moveTo(0, -height / 2)
          ..lineTo(width / 2, height / 2)
          ..lineTo(-width / 2, height / 2)
          ..close();
        canvas.drawPath(path, _paint);
      case ConfettiShape.ribbon:
        // 彩带：长条形
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero, width: width * 0.3, height: height),
            Radius.circular(width * 0.15),
          ),
          _paint,
        );
    }

    canvas.restore();
  }
}

enum ConfettiShape {
  rectangle,
  circle,
  triangle,
  ribbon,
}

/// 庆祝效果管理器
class Celebration extends PositionComponent {
  static final _random = math.Random();
  static final _celebrationColors = [
    Color(0xFFFF6B6B), // 红
    Color(0xFF4ECDC4), // 青
    Color(0xFFFFE66D), // 黄
    Color(0xFF95E1D3), // 薄荷绿
    Color(0xFFF38181), // 粉红
    Color(0xFFAA96DA), // 紫
    Color(0xFFFCBAD3), // 粉
    Color(0xFFFF8C42), // 橙
  ];

  Celebration({
    required super.position,
    required super.size,
    super.priority,
  });

  @override
  void onMount() {
    super.onMount();
    _createConfettiBurst();
  }

  void _createConfettiBurst() {
    // 从左侧发射
    for (int i = 0; i < 50; i++) {
      _createConfetti(
        startX: 0,
        velocityXRange: (200, 400),
        velocityYRange: (-600, -300),
      );
    }

    // 从右侧发射
    for (int i = 0; i < 50; i++) {
      _createConfetti(
        startX: width,
        velocityXRange: (-400, -200),
        velocityYRange: (-600, -300),
      );
    }

    // 从顶部中间发射
    for (int i = 0; i < 50; i++) {
      _createConfetti(
        startX: width / 2 + _random.nextDouble() * 200 - 100,
        velocityXRange: (-150, 150),
        velocityYRange: (-500, -200),
      );
    }
  }

  void _createConfetti({
    required double startX,
    required (double, double) velocityXRange,
    required (double, double) velocityYRange,
  }) {
    final color =
        _celebrationColors[_random.nextInt(_celebrationColors.length)];
    final shape =
        ConfettiShape.values[_random.nextInt(ConfettiShape.values.length)];

    // 随机大小
    final size = shape == ConfettiShape.ribbon
        ? Vector2(8 + _random.nextDouble() * 8, 20 + _random.nextDouble() * 20)
        : Vector2.all(6 + _random.nextDouble() * 10);

    final confetti = ConfettiParticle(
      position: Vector2(startX, height * 0.5 + _random.nextDouble() * 100),
      velocity: Vector2(
        velocityXRange.$1 +
            _random.nextDouble() * (velocityXRange.$2 - velocityXRange.$1),
        velocityYRange.$1 +
            _random.nextDouble() * (velocityYRange.$2 - velocityYRange.$1),
      ),
      color: color,
      shape: shape,
      size: size,
    );

    add(confetti);
  }
}
