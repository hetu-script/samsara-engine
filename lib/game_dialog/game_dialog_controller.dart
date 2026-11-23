import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import 'game_dialog.dart';
import 'game_dialog_content.dart';
import 'screen_hint.dart';
import 'selection_dialog.dart';

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

class GameDialogController extends StatefulWidget {
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
    this.selectionButtonStyle,
    this.selectionTextStyle,
    this.selectionButtonBuilder,
    this.screenHintBarrierColor,
    this.screenHintTextStyle,
    this.screenHintBorderColor,
    this.screenHintBorderRadius,
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
  final fluent.ButtonStyle? selectionButtonStyle;
  final TextStyle? selectionTextStyle;
  final SelectionButtonBuilder? selectionButtonBuilder;
  final Color? screenHintBarrierColor;
  final TextStyle? screenHintTextStyle;
  final Color? screenHintBorderColor;
  final double? screenHintBorderRadius;

  @override
  State<GameDialogController> createState() => _GameDialogControllerState();
}

class _GameDialogControllerState extends State<GameDialogController>
    with TickerProviderStateMixin {
  late final AnimationController sceneFadeController,
      illustrationFadeController;

  late final Animation<double> sceneFadeAnimation, illustrationFadeAnimation;

  String? _sceneAnimationTaskId;

  @override
  void initState() {
    super.initState();
    sceneFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    illustrationFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    sceneFadeAnimation =
        Tween(begin: 0.0, end: 1.0).animate(sceneFadeController);
    sceneFadeAnimation.addStatusListener(_handleSceneAnimationStatus);
    illustrationFadeAnimation =
        Tween(begin: 0.0, end: 1.0).animate(illustrationFadeController);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSceneAnimation());
  }

  @override
  void didUpdateWidget(covariant GameDialogController oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSceneAnimation());
  }

  void _handleSceneAnimationStatus(AnimationStatus status) {
    if (!mounted ||
        (status != AnimationStatus.completed &&
            status != AnimationStatus.dismissed)) {
      return;
    }
    final taskId = _sceneAnimationTaskId;
    if (taskId == null) return;
    _sceneAnimationTaskId = null;
    context.read<GameDialog>().finishTask(taskId);
  }

  void _stopSceneAnimation({bool finishTask = false}) {
    final taskId = _sceneAnimationTaskId;
    _sceneAnimationTaskId = null;
    sceneFadeController.stop();
    if (finishTask && taskId != null) {
      context.read<GameDialog>().finishTask(taskId);
    }
  }

  void _syncSceneAnimation() {
    if (!mounted) return;
    final dialog = context.read<GameDialog>();
    final sceneInfo = dialog.currentSceneInfo;
    final prevScene = dialog.prevScene;
    final onlyBackground = dialog.illustrations.isEmpty &&
        dialog.currentContent == null &&
        dialog.selectionsData == null;

    final fadeIn = sceneInfo != null && sceneInfo.isFadeIn && onlyBackground;
    final fadeOut = sceneInfo == null &&
        prevScene != null &&
        prevScene.isFadeOut &&
        onlyBackground;
    final nextTaskId = fadeIn
        ? sceneInfo.taskId
        : fadeOut
            ? prevScene.taskId
            : null;
    if (nextTaskId == null) {
      _stopSceneAnimation(finishTask: true);
      return;
    }
    if (nextTaskId == _sceneAnimationTaskId) return;
    _stopSceneAnimation(finishTask: true);
    _sceneAnimationTaskId = nextTaskId;
    if (fadeIn) {
      sceneFadeController.forward(from: 0.0);
    } else {
      sceneFadeController.reverse(from: 1.0);
    }
  }

  @override
  void dispose() {
    _sceneAnimationTaskId = null;
    sceneFadeController.dispose();
    illustrationFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final dialog = context.watch<GameDialog>();
    final prevScene = dialog.prevScene;
    final sceneInfo = dialog.currentSceneInfo;
    final illustrationsInfo = dialog.illustrations;
    final dialogContentData = dialog.currentContent;
    final selectionsData = dialog.selectionsData;
    final screenHintInfo = dialog.screenHintInfo;

    Widget? background;
    final onlyBackground = illustrationsInfo.isEmpty &&
        dialogContentData == null &&
        selectionsData == null;
    if (sceneInfo != null) {
      final current = SizedBox(
        width: screenSize.width,
        height: screenSize.height,
        child: Image(
          image: AssetImage(sceneInfo.path),
          fit: BoxFit.cover,
        ),
      );

      if (sceneInfo.isFadeIn && onlyBackground) {
        background = Stack(
          children: [
            if (prevScene != null)
              SizedBox(
                width: screenSize.width,
                height: screenSize.height,
                child: Image(
                  image: AssetImage(prevScene.path),
                  fit: BoxFit.cover,
                ),
              ),
            FadeTransition(opacity: sceneFadeAnimation, child: current),
          ],
        );
      } else {
        background = current;
      }
    } else if (prevScene != null && prevScene.isFadeOut && onlyBackground) {
      background = FadeTransition(
        opacity: sceneFadeAnimation,
        child: SizedBox(
          width: screenSize.width,
          height: screenSize.height,
          child: Image(
            image: AssetImage(prevScene.path),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final illustrations = [
      for (final info in illustrationsInfo)
        Positioned.fill(
          child: GameDialogIllustration(
            key: ValueKey(info.path),
            image: AssetImage(info.path),
            offsetX: info.offsetX + widget.illustrationOffset.dx,
            offsetY: info.offsetY + widget.illustrationOffset.dy,
          ),
        ),
    ];

    final isEmpty = background == null &&
        illustrations.isEmpty &&
        dialogContentData == null &&
        selectionsData == null &&
        screenHintInfo == null;

    return isEmpty
        ? const SizedBox.shrink()
        : Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                if (widget.barrierColor != null)
                  ModalBarrier(
                    color: widget.barrierColor,
                    onDismiss: () {},
                  ),
                if (background != null) background,
                ...illustrations,
                if (dialogContentData != null)
                  GameDialogContent(
                    data: dialogContentData,
                    cursor: widget.cursor,
                    textStyle: widget.dialogTextStyle,
                    nameTextStyle: widget.dialogNameTextStyle,
                    decoration: widget.dialogDecoration,
                    frameBuilder: widget.dialogFrameBuilder,
                    width: widget.dialogWidth,
                    height: widget.dialogHeight,
                    bottom: widget.dialogBottom,
                    avatarSize: widget.dialogAvatarSize,
                    avatarMargin: widget.dialogAvatarMargin,
                    contentPadding: widget.dialogContentPadding,
                    textPadding: widget.dialogTextPadding,
                    onAvatarPressed: widget.onAvatarPressed,
                  ),
                if (selectionsData != null)
                  SelectionDialog(
                    data: selectionsData,
                    cursor: widget.cursor,
                    buttonStyle: widget.selectionButtonStyle,
                    textStyle: widget.selectionTextStyle,
                    buttonBuilder: widget.selectionButtonBuilder,
                  ),
                if (screenHintInfo != null)
                  ScreenHint(
                    hintInfo: screenHintInfo,
                    cursor: widget.screenHintCursor,
                    barrierColor: widget.screenHintBarrierColor,
                    textStyle: widget.screenHintTextStyle,
                    borderColor: widget.screenHintBorderColor,
                    borderRadius: widget.screenHintBorderRadius,
                  ),
              ],
            ),
          );
  }
}
