import 'dart:async';

import '../components/game_component.dart';
import 'sprite_animation.dart';
// import '../task.dart';
import 'package:samsara/engine.dart';

mixin AnimationStateController on GameComponent {
  final Map<String, SpriteAnimationWithTicker> _animations = {};
  final Map<String, SpriteAnimationWithTicker> _overlayAnimations = {};

  String? currentAnimationState;
  String? currentOverlayAnimationState;

  AudioPlayerInterface? audioPlayer;

  SpriteAnimationWithTicker? get currentAnimation {
    return _animations[currentAnimationState];
  }

  SpriteAnimationWithTicker? get currentOverlayAnimation {
    return _overlayAnimations[currentOverlayAnimationState];
  }

  void addState(String state, SpriteAnimationWithTicker anim,
      {bool isOverlay = false}) {
    Map<String, SpriteAnimationWithTicker> collection =
        isOverlay ? _overlayAnimations : _animations;

    if (collection.containsKey(state)) {
      throw 'Animation state already exists: $state';
    }
    collection[state] = anim;
  }

  Future<void> loadStates() async {
    for (final anim in _animations.values) {
      await anim.load();
    }
    for (final anim in _overlayAnimations.values) {
      await anim.load();
    }
  }

  bool containsState(String stateId) {
    return _animations.containsKey(stateId);
  }

  Future<void> setState(String state,
      {bool isOverlay = false, bool jumpToEnd = false}) {
    Map<String, SpriteAnimationWithTicker> collection =
        isOverlay ? _overlayAnimations : _animations;
    if (!collection.containsKey(state)) {
      throw 'State not found: $state';
    }
    if (isOverlay) {
      currentOverlayAnimationState = state;
    } else {
      currentAnimationState = state;
    }
    final anim = collection[state]!;
    if (jumpToEnd) {
      anim.ticker.paused = true;
      anim.ticker.setToLast();
    } else {
      anim.ticker.reset();
    }
    return anim.ticker.completed;
  }

  Future<void> setCompositeState({
    required List<dynamic> startup,
    List<dynamic>? recovery,
    List<dynamic>? actions,
    List<dynamic>? overlays,
    String? complete,
    String? sound,
    void Function()? onComplete,
  }) async {
    assert(startup.isNotEmpty);
    Future future = setState(startup.first);
    if (startup.length > 1) {
      for (final state in startup.skip(1)) {
        future = future.then((_) => setState(state));
      }
    }

    if (overlays != null) {
      Future prev = future;
      for (final overlay in overlays) {
        prev = prev.then((_) => setState(overlay, isOverlay: true));
      }
    }

    if (actions != null) {
      for (final action in actions) {
        future = future.then((_) => setState(action));
      }
      if (sound != null) {
        future.then((_) {
          audioPlayer?.play(sound);
        });
      }
    } else {
      if (sound != null) {
        future.then((_) {
          audioPlayer?.play(sound);
        });
      }
    }

    if (recovery != null) {
      for (final state in recovery) {
        future = future.then((_) => setState(state));
      }
    }

    future.then((_) {
      onComplete?.call();
      if (complete != null) {
        setState(complete);
      }
    });

    return future;
  }
}
