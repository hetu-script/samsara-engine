import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import 'scene.dart';
import '../widgets/pointer_detector.dart';

class SceneWidget<T extends Scene> extends StatelessWidget {
  final T scene;
  final GameLoadingWidgetBuilder? loadingBuilder;
  final Map<String, OverlayWidgetBuilder<T>>? overlayBuilderMap;
  final List<String>? initialActiveOverlays;
  // final MouseCursor cursor;

  const SceneWidget({
    super.key,
    required this.scene,
    this.loadingBuilder,
    this.overlayBuilderMap,
    this.initialActiveOverlays,
    // this.cursor = MouseCursor.defer,
  });

  @override
  Widget build(BuildContext context) {
    return PointerDetector(
      onTapDown: scene.onTapDown,
      onTapUp: scene.onTapUp,
      onDragStart: scene.onDragStart,
      onDragUpdate: scene.onDragUpdate,
      onDragEnd: scene.onDragEnd,
      onScaleStart: scene.onScaleStart,
      onScaleUpdate: scene.onScaleUpdate,
      onScaleEnd: scene.onScaleEnd,
      onLongPress: scene.onLongPress,
      onMouseHover: scene.onMouseHover,
      onMouseScroll: scene.onMouseScroll,
      child: GameWidget(
        game: scene,
        // mouseCursor: cursor,
        loadingBuilder: loadingBuilder,
        overlayBuilderMap: overlayBuilderMap,
        initialActiveOverlays: initialActiveOverlays,
      ),
    );
  }
}
