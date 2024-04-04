import '../components/game_component.dart';

import 'sprite_animation.dart';

mixin AnimationStateController on GameComponent {
  final Map<String, SpriteAnimationWithTicker> _animations = {};
  String currentState = '';

  SpriteAnimationWithTicker get currentAnimation {
    if (!_animations.containsKey(currentState)) {
      throw 'Could not find animation state: [$currentState]';
    }
    return _animations[currentState]!;
  }

  void addState(String state, SpriteAnimationWithTicker anim) {
    _animations[state] = anim;
  }

  void addStates(Map<String, SpriteAnimationWithTicker> anims) {
    _animations.addAll(anims);
  }

  Future<void> loadStates() async {
    for (final anim in _animations.values) {
      await anim.load();
    }
  }

  bool containsState(String stateId) {
    // return _animations.containsKey('${stateId}_$skinId');
    return _animations.containsKey(stateId);
  }

  Future<void> setState(
    String state, {
    bool pauseOnLastFrame = false,
    String? resetOnComplete,
    void Function()? onComplete,
  }) {
    // engine.info('${isHero ? 'hero' : 'enemy'} new state: $state');
    // state = '${state}_$skinId';
    if (currentState != state) {
      currentState = state;
    }
    final anim = currentAnimation;
    if (pauseOnLastFrame) {
      anim.ticker.paused = true;
      anim.ticker.setToLast();
    } else {
      anim.ticker.reset();
      anim.ticker.onComplete = () {
        onComplete?.call();
        if (resetOnComplete != null) {
          setState(resetOnComplete);
        }
      };
    }
    return anim.ticker.completed;
  }
}
