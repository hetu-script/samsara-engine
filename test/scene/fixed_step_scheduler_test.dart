import 'package:flutter_test/flutter_test.dart';
import 'package:samsara/scene/fixed_step_scheduler.dart';
import 'package:samsara/scene/scene.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FixedStepScheduler', () {
    test('advances exactly one step at the fixed rate boundary', () {
      final scheduler = FixedStepScheduler();
      final steps = <double>[];

      final count = scheduler.advance(1 / 60, steps.add);

      expect(count, 1);
      expect(steps, [1 / 60]);
      expect(scheduler.interpolation, closeTo(0, 1e-12));
    });

    test('runs 60 fixed steps per second at 120Hz', () {
      final scheduler = FixedStepScheduler();
      var steps = 0;

      for (var frame = 0; frame < 240; frame++) {
        steps += scheduler.advance(1 / 120, (_) {});
      }

      expect(steps, 120);
      expect(scheduler.interpolation, greaterThanOrEqualTo(0));
      expect(scheduler.interpolation, lessThan(1));
    });

    test('catches up to 60 fixed steps per second at 30Hz', () {
      final scheduler = FixedStepScheduler();
      var steps = 0;

      for (var frame = 0; frame < 60; frame++) {
        steps += scheduler.advance(1 / 30, (_) {});
      }

      expect(steps, 120);
    });

    test('preserves the fractional step', () {
      final scheduler = FixedStepScheduler();

      final count = scheduler.advance((1 / 60) * 2.5, (_) {});

      expect(count, 2);
      expect(scheduler.interpolation, closeTo(0.5, 1e-12));
    });

    test('drops whole overdue steps after the catch-up limit', () {
      final scheduler = FixedStepScheduler();
      var steps = 0;

      final count = scheduler.advance(1, (_) => steps++);

      expect(count, 5);
      expect(steps, 5);
      expect(scheduler.interpolation, greaterThanOrEqualTo(0));
      expect(scheduler.interpolation, lessThan(1));
      expect(scheduler.advance(0, (_) {}), 0);
    });

    test('accepts a zero-length frame', () {
      final scheduler = FixedStepScheduler();

      expect(scheduler.advance(0, (_) {}), 0);
      expect(scheduler.interpolation, 0);
    });
  });

  test('Scene calls updateFrame even without a fixed logic step', () {
    final scene = _TimingScene();

    scene.update(1 / 120);
    scene.update(1 / 120);
    scene.update(0);

    expect(scene.fixedUpdates, 1);
    expect(scene.frameUpdates, 3);
    expect(scene.lastFrameDt, 0);
  });
}

class _TimingScene extends Scene {
  _TimingScene() : super(id: 'timing_test');

  int fixedUpdates = 0;
  int frameUpdates = 0;
  double? lastFrameDt;

  @override
  void fixedUpdate(double dt) {
    super.fixedUpdate(dt);
    fixedUpdates++;
  }

  @override
  void updateFrame(double dt) {
    super.updateFrame(dt);
    frameUpdates++;
    lastFrameDt = dt;
  }
}
