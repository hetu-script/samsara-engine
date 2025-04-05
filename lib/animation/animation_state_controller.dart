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
    // return _animations.containsKey('${stateId}_$skinId');
    return _animations.containsKey(stateId);
  }

  Future<void> setState(String state, {bool isOverlay = false}) {
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
    anim.ticker.reset();
    return anim.ticker.completed;
  }

  Future<void> setCompositeState({
    required String startup,
    List<dynamic>? transitions,
    List<dynamic>? overlays,
    String? recovery,
    String? complete,
    String? sound,
    void Function()? onComplete,
  }) async {
    Future future = setState(startup);

    if (overlays != null) {
      Future prev = future;
      for (final overlay in overlays) {
        prev = prev.then((_) => setState(overlay, isOverlay: true));
      }
    }

    if (transitions != null) {
      for (final transition in transitions) {
        future = future.then((_) => setState(transition));
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
      future = future.then((_) => setState(recovery));
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
