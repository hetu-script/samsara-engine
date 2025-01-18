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

  SamsaraEngine? engine;

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
      throw 'State already exists: $state';
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

  SpriteAnimationWithTicker _setState(
      {required String state, bool isOverlay = false}) {
    Map<String, SpriteAnimationWithTicker> collection =
        isOverlay ? _overlayAnimations : _animations;
    if (!collection.containsKey(state)) {
      throw 'State not found: $state';
    }
    if (isOverlay) {
      currentOverlayAnimationState = state;
    } else {
      currentOverlayAnimationState = null;
      currentAnimationState = state;
    }
    return collection[state]!;
  }

  /// 如果进入动画，则返回一个双元素元组
  /// 第一个是前摇动画的 Future，第二个是整个动画的 Future
  Future<void> setAnimationState(
    String state, {
    String? sound,
    String? recoveryState,
    String? overlayState,
    String? completeState,
    bool jumpToLastFrame = false,
    void Function()? onComplete,
    bool isOverlay = false,
  }) async {
    if (isOverlay) {
      if (currentOverlayAnimationState == state) {
        return;
      }
    } else {
      if (currentAnimationState == state) {
        return;
      }
    }

    // final Completer completer = Completer();

    final anim = _setState(state: state, isOverlay: isOverlay);
    anim.ticker.reset();
    if (jumpToLastFrame) {
      anim.ticker.paused = true;
      anim.ticker.setToLast();
      onComplete?.call();
      // completer.complete();
      return;
    } else {
      Future startUpResult = anim.ticker.completed;
      if (sound != null) {
        startUpResult.then((_) {
          engine?.play(sound);
        });
      }

      Future? overlayResult;

      if (overlayState != null) {
        overlayResult = startUpResult
            .then((_) => setAnimationState(overlayState, isOverlay: true));
      }

      Future finalResult = (overlayResult ?? startUpResult);

      if (recoveryState != null) {
        finalResult = finalResult.then((_) => setAnimationState(recoveryState));
      }

      finalResult.then((_) {
        if (completeState != null) {
          setAnimationState(completeState);
        }
        onComplete?.call();
      });

      return finalResult;
    }
  }
}
