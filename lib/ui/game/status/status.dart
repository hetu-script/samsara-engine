import 'dart:async';

import 'package:flame/sprite.dart';

import '../../../component/game_component.dart';
import '../progress_indicator.dart';

class StatusEffect extends GameComponent {
  @override
  String get id => super.id!;

  final String title, description;

  final String spriteId;
  Sprite? sprite;

  int count;

  StatusEffect({
    required super.id,
    required this.title,
    required this.description,
    required this.spriteId,
    this.count = 0,
    super.position,
    super.size,
  });

  @override
  void render(Canvas canvas) {
    sprite?.renderRect(canvas, border);
  }

  static final Map<String, StatusEffect Function(int count)> _constructors = {};

  static registerEffect(
      String id, StatusEffect Function(int count) constructor) {
    _constructors[id] = constructor;
  }

  factory StatusEffect.create(String id, int count) {
    assert(_constructors.containsKey(id));
    assert(count > 0);
    final ctor = _constructors[id]!;
    final effect = ctor.call(count);
    assert(effect.id == id);
    return effect;
  }
}

class StatusBar extends GameComponent {
  static const healthBarHeight = 10.0;

  late final DynamicColorProgressIndicator health;

  double life, maxLife;

  final Map<String, StatusEffect> effects = {};

  StatusBar({
    super.position,
    super.size,
    this.life = 100,
    this.maxLife = 100,
  }) : super(anchor: Anchor.center);

  @override
  set height(double value) {
    super.height = value;

    health.y = height - healthBarHeight;
  }

  void addEffect(String id, int count) {
    if (effects.containsKey(id)) {
      final effect = effects[id]!;
      effect.count += count;
    } else {
      effects[id] = StatusEffect.create(id, count);
    }
  }

  @override
  FutureOr<void> onLoad() {
    health = DynamicColorProgressIndicator(
      position: Vector2(0, height - healthBarHeight),
      size: Vector2(width, healthBarHeight),
      value: life,
      max: maxLife,
      colors: [Colors.red, Colors.green],
      showNumber: true,
    );
    add(health);
  }

  @override
  void render(Canvas canvas) {
    // canvas.drawRect(border, DefaultBorderPaint.light);
  }
}
