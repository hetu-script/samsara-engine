import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import 'game_dialog.dart';
import 'game_dialog_content.dart';
import 'screen_hint.dart';
import 'selection_dialog.dart';

typedef GameDialogSkipButtonBuilder = Widget Function(
    BuildContext context, VoidCallback onPressed);

class GameDialogIllustration extends StatelessWidget {
  const GameDialogIllustration({
    super.key,
    required this.image,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
  });

  final ImageProvider image;
  final double offsetX;
  final double offsetY;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox.expand(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Transform.translate(
              offset: Offset(offsetX, offsetY),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth,
                  maxHeight: constraints.maxHeight,
                ),
                child: Image(image: image, fit: BoxFit.contain),
              ),
            ),
          ),
        );
      },
    );
  }
}

class GameDialogController extends StatelessWidget {
  const GameDialogController({
    super.key,
    this.cursor,
    this.screenHintCursor,
    this.barrierColor,
    this.illustrationOffset = Offset.zero,
    this.dialogTextStyle,
    this.dialogNameTextStyle,
    this.dialogDecoration,
    this.dialogFrameBuilder,
    this.dialogWidth,
    this.dialogHeight,
    this.dialogBottom,
    this.dialogAvatarSize,
    this.dialogAvatarMargin,
    this.dialogContentPadding,
    this.dialogTextPadding,
    this.onAvatarPressed,
    this.selectionOffset = Offset.zero,
    this.selectionButtonStyle,
    this.selectionTextStyle,
    this.selectionButtonBuilder,
    this.screenHintBarrierColor,
    this.screenHintTextStyle,
    this.screenHintBorderColor,
    this.screenHintBorderRadius,
    this.onSkip,
    this.skipButtonBuilder,
  });

  final MouseCursor? cursor;
  final MouseCursor? screenHintCursor;
  final Color? barrierColor;
  final Offset illustrationOffset;
  final TextStyle? dialogTextStyle;
  final TextStyle? dialogNameTextStyle;
  final BoxDecoration? dialogDecoration;
  final GameDialogFrameBuilder? dialogFrameBuilder;
  final double? dialogWidth;
  final double? dialogHeight;
  final double? dialogBottom;
  final Size? dialogAvatarSize;
  final EdgeInsetsGeometry? dialogAvatarMargin;
  final EdgeInsetsGeometry? dialogContentPadding;
  final EdgeInsetsGeometry? dialogTextPadding;
  final void Function(dynamic)? onAvatarPressed;
  final Offset selectionOffset;
  final fluent.ButtonStyle? selectionButtonStyle;
  final TextStyle? selectionTextStyle;
  final SelectionButtonBuilder? selectionButtonBuilder;
  final Color? screenHintBarrierColor;
  final TextStyle? screenHintTextStyle;
  final Color? screenHintBorderColor;
  final double? screenHintBorderRadius;
  final VoidCallback? onSkip;
  final GameDialogSkipButtonBuilder? skipButtonBuilder;

  @override
  Widget build(BuildContext context) {
    final dialog = context.watch<GameDialog>();
    final paused = dialog.presentationPaused;
    final sceneInfo = dialog.currentSceneInfo;
    final prevScene = dialog.prevScene;
    final illustrationsInfo = dialog.illustrations;
    final prevIllustration = dialog.prevIllustration;
    final dialogContentData = paused ? null : dialog.currentContent;
    final selectionsData = paused ? null : dialog.selectionsData;
    final screenHintInfo = dialog.screenHintInfo;
    final shadeActive =
        dialog.sceneShade != null || dialog.sceneShadeOpacity > 0;

    final hasBackground =
        sceneInfo != null || (prevScene != null && prevScene.isFadeOut);
    final hasIllustration = illustrationsInfo.isNotEmpty ||
        (prevIllustration != null && prevIllustration.isFadeOut);
    final showSkip = onSkip != null &&
        dialogContentData != null &&
        selectionsData == null &&
        !paused &&
        !shadeActive;

    final illustrations = [
      for (final info in illustrationsInfo)
        Positioned.fill(
          child: _buildIllustration(info, dialog, paused),
        ),
      if (prevIllustration != null && prevIllustration.isFadeOut)
        Positioned.fill(
          child: _buildIllustration(prevIllustration, dialog, paused),
        ),
    ];

    final isEmpty = !hasBackground &&
        !hasIllustration &&
        dialogContentData == null &&
        selectionsData == null &&
        screenHintInfo == null &&
        !shadeActive;

    return isEmpty
        ? const SizedBox.shrink()
        : Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                if (barrierColor != null)
                  ModalBarrier(
                    color: barrierColor,
                    onDismiss: () {},
                  ),
                if (hasBackground)
                  Positioned.fill(
                    child: _GameDialogBackgroundView(
                      dialog: dialog,
                      paused: paused,
                    ),
                  ),
                ...illustrations,
                if (dialogContentData != null)
                  GameDialogContent(
                    data: dialogContentData,
                    cursor: cursor,
                    textStyle: dialogTextStyle,
                    nameTextStyle: dialogNameTextStyle,
                    decoration: dialogDecoration,
                    frameBuilder: dialogFrameBuilder,
                    width: dialogWidth,
                    height: dialogHeight,
                    bottom: dialogBottom,
                    avatarSize: dialogAvatarSize,
                    avatarMargin: dialogAvatarMargin,
                    contentPadding: dialogContentPadding,
                    textPadding: dialogTextPadding,
                    onAvatarPressed: onAvatarPressed,
                  ),
                if (selectionsData != null)
                  SelectionDialog(
                    data: selectionsData,
                    cursor: cursor,
                    offset: selectionOffset,
                    buttonStyle: selectionButtonStyle,
                    textStyle: selectionTextStyle,
                    buttonBuilder: selectionButtonBuilder,
                  ),
                if (showSkip)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: SafeArea(
                      child: skipButtonBuilder?.call(context, onSkip!) ??
                          IconButton(
                            onPressed: onSkip,
                            icon: const Icon(Icons.fast_forward),
                          ),
                    ),
                  ),
                if (screenHintInfo != null)
                  ScreenHint(
                    hintInfo: screenHintInfo,
                    cursor: screenHintCursor,
                    barrierColor: screenHintBarrierColor,
                    textStyle: screenHintTextStyle,
                    borderColor: screenHintBorderColor,
                    borderRadius: screenHintBorderRadius,
                  ),
                if (shadeActive)
                  Positioned.fill(
                    child: _GameDialogShadeView(
                      dialog: dialog,
                      paused: paused,
                    ),
                  ),
              ],
            ),
          );
  }

  Widget _buildIllustration(
    IllustrationInfo info,
    GameDialog dialog,
    bool paused,
  ) {
    final child = GameDialogIllustration(
      image: AssetImage(info.path),
      offsetX: info.offsetX + illustrationOffset.dx,
      offsetY: info.offsetY + illustrationOffset.dy,
    );
    if (!info.isFadeIn && !info.isFadeOut) return child;
    return _IllustrationTransitionView(
      key: ValueKey(info),
      info: info,
      paused: paused,
      onCompleted: dialog.completeIllustrationTransition,
      child: child,
    );
  }
}

class _GameDialogBackgroundView extends StatefulWidget {
  const _GameDialogBackgroundView({required this.dialog, required this.paused});

  final GameDialog dialog;
  final bool paused;

  @override
  State<_GameDialogBackgroundView> createState() =>
      _GameDialogBackgroundViewState();
}

class _GameDialogBackgroundViewState extends State<_GameDialogBackgroundView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  SceneInfo? _current;
  SceneInfo? _previous;
  SceneInfo? _active;
  bool _reversing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener(_handleStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didUpdateWidget(covariant _GameDialogBackgroundView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (!mounted) return;
    final current = widget.dialog.currentSceneInfo;
    final previous = widget.dialog.prevScene;
    if (current != _current || previous != _previous) {
      _current = current;
      _previous = previous;
      _controller.stop();
      _active = null;
      SceneInfo? transition;
      if (current != null && (current.isFadeIn || current.motion != null)) {
        transition = current;
        _reversing = false;
      } else if (current == null && previous?.isFadeOut == true) {
        transition = previous;
        _reversing = true;
      }
      _active = transition;
      if (transition == null) {
        _controller.value = 1;
      } else {
        _controller.duration = _reversing
            ? transition.fadeDuration
            : transition.motion?.duration ?? transition.fadeDuration;
        _controller.value = _reversing ? 1 : 0;
        if (!widget.paused) _run();
      }
      return;
    }
    if (widget.paused) {
      _controller.stop();
    } else if (_active != null && !_controller.isAnimating) {
      final completed = _reversing
          ? _controller.status == AnimationStatus.dismissed
          : _controller.status == AnimationStatus.completed;
      if (!completed) _run();
    }
  }

  void _run() {
    if (_reversing) {
      _controller.reverse(from: _controller.value);
    } else {
      _controller.forward(from: _controller.value);
    }
  }

  void _handleStatus(AnimationStatus status) {
    final active = _active;
    if (active == null || !mounted) return;
    if ((!_reversing && status == AnimationStatus.completed) ||
        (_reversing && status == AnimationStatus.dismissed)) {
      _active = null;
      widget.dialog.completeSceneTransition(active);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final current = _current;
        final previous = _previous;
        final progress = _active == null ? 1.0 : _controller.value;
        final currentOpacity = _currentOpacity(current, previous, progress);
        final children = <Widget>[];
        if (previous != null &&
            ((current != null && currentOpacity < 1) ||
                (current == null && previous.isFadeOut))) {
          final opacity = current == null ? 1 - progress : 1 - currentOpacity;
          children.add(_scene(previous, true, 1, opacity.clamp(0, 1)));
        }
        if (current != null) {
          children.add(_scene(current, false, progress, currentOpacity));
        }
        return Stack(children: children);
      },
    );
  }

  double _currentOpacity(
    SceneInfo? current,
    SceneInfo? previous,
    double progress,
  ) {
    if (current == null || _active != current) return 1;
    if (current.isFadeIn) return progress;
    final fadeDuration = current.motion?.fadeDuration;
    if (fadeDuration == null || previous == null) return 1;
    final duration = current.motion!.duration;
    final elapsed = duration * progress;
    return (elapsed.inMicroseconds / fadeDuration.inMicroseconds).clamp(0, 1);
  }

  Widget _scene(
    SceneInfo info,
    bool endState,
    double progress,
    double opacity,
  ) {
    final motion = info.motion;
    var effectiveProgress = endState ? 1.0 : progress;
    if (motion != null && !endState) {
      effectiveProgress = motion.curve.transform(progress.clamp(0, 1));
    }
    return Opacity(
      opacity: opacity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final coverScale = math.max(
            constraints.maxWidth / 1920,
            constraints.maxHeight / 1080,
          );
          Widget image = SizedBox.expand(
            child: Image(
              image: AssetImage(info.path),
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          );
          if (motion != null) {
            final scale = lerpDouble(
              motion.beginScale,
              motion.endScale,
              effectiveProgress,
            )!;
            final offset = Offset.lerp(
              motion.beginOffset,
              motion.endOffset,
              effectiveProgress,
            )!;
            image = ClipRect(
              child: Transform.translate(
                offset: offset * coverScale,
                child: Transform.scale(scale: scale, child: image),
              ),
            );
          }
          return image;
        },
      ),
    );
  }
}

class _GameDialogShadeView extends StatefulWidget {
  const _GameDialogShadeView({required this.dialog, required this.paused});

  final GameDialog dialog;
  final bool paused;

  @override
  State<_GameDialogShadeView> createState() => _GameDialogShadeViewState();
}

class _GameDialogShadeViewState extends State<_GameDialogShadeView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  SceneShadeInfo? _active;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener(_handleStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didUpdateWidget(covariant _GameDialogShadeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (!mounted) return;
    final next = widget.dialog.sceneShade;
    if (next != _active) {
      _controller.stop();
      _active = next;
      if (next != null) {
        _controller.duration = next.duration;
        _controller.value = 0;
        if (!widget.paused) _controller.forward();
      }
      return;
    }
    if (widget.paused) {
      _controller.stop();
    } else if (_active != null &&
        !_controller.isAnimating &&
        _controller.status != AnimationStatus.completed) {
      _controller.forward(from: _controller.value);
    }
  }

  void _handleStatus(AnimationStatus status) {
    final active = _active;
    if (active != null && status == AnimationStatus.completed && mounted) {
      _active = null;
      widget.dialog.completeSceneShade(active);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final info = widget.dialog.sceneShade;
        final opacity = info == null
            ? widget.dialog.sceneShadeOpacity
            : lerpDouble(
                info.fromOpacity,
                info.targetOpacity,
                _controller.value,
              )!;
        return AbsorbPointer(
          absorbing: opacity > 0 || info != null,
          child: ColoredBox(
            color: Colors.black.withValues(alpha: opacity),
          ),
        );
      },
    );
  }
}

class _IllustrationTransitionView extends StatefulWidget {
  const _IllustrationTransitionView({
    super.key,
    required this.info,
    required this.paused,
    required this.onCompleted,
    required this.child,
  });

  final IllustrationInfo info;
  final bool paused;
  final void Function(IllustrationInfo info) onCompleted;
  final Widget child;

  @override
  State<_IllustrationTransitionView> createState() =>
      _IllustrationTransitionViewState();
}

class _IllustrationTransitionViewState
    extends State<_IllustrationTransitionView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.info.fadeDuration,
      value: widget.info.isFadeOut ? 1 : 0,
    )..addStatusListener(_handleStatus);
    if (!widget.paused) _run();
  }

  @override
  void didUpdateWidget(covariant _IllustrationTransitionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paused) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _run();
    }
  }

  void _run() {
    if (widget.info.isFadeOut) {
      _controller.reverse(from: _controller.value);
    } else {
      _controller.forward(from: _controller.value);
    }
  }

  void _handleStatus(AnimationStatus status) {
    if ((widget.info.isFadeOut && status == AnimationStatus.dismissed) ||
        (!widget.info.isFadeOut && status == AnimationStatus.completed)) {
      widget.onCompleted(widget.info);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _controller, child: widget.child);
  }
}
