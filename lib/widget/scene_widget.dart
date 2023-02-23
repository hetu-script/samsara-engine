import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import '../scene/scene.dart';
import 'pointer_detector.dart';

class SceneWidget<T extends Scene> extends StatelessWidget {
  final T scene;
  final Map<String, OverlayWidgetBuilder<T>>? overlayBuilderMap;

  const SceneWidget({
    super.key,
    required this.scene,
    this.overlayBuilderMap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: PointerDetector(
        child: GameWidget(
          game: scene,
          overlayBuilderMap: overlayBuilderMap,
        ),
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
      ),
    );
  }
}
