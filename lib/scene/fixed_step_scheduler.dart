class FixedStepScheduler {
  FixedStepScheduler({
    this.fixedRate = 1 / 60,
    this.maxStepsPerFrame = 5,
  })  : assert(fixedRate > 0),
        assert(maxStepsPerFrame > 0);

  final double fixedRate;
  final int maxStepsPerFrame;

  double _accumulator = 0;

  double get interpolation => _accumulator / fixedRate;

  int advance(double dt, void Function(double fixedRate) onStep) {
    assert(dt >= 0 && dt.isFinite);

    _accumulator += dt;
    var steps = 0;
    while (_accumulator >= fixedRate && steps < maxStepsPerFrame) {
      onStep(fixedRate);
      _accumulator -= fixedRate;
      steps++;
    }
    if (_accumulator >= fixedRate) {
      _accumulator %= fixedRate;
    }
    return steps;
  }
}
