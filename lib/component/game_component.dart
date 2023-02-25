import 'package:meta/meta.dart';
import 'package:flame/components.dart';
import 'package:samsara/gestures.dart';
import 'package:flame/effects.dart';

import '../scene/scene.dart';
import '../extensions.dart';

export 'package:flame/components.dart' show Anchor;

abstract class GameComponent extends PositionComponent
    with HasGameRef<Scene>
    implements SizeProvider {
  GameComponent({
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.priority,
  });

  bool _isVisible = true;

  @mustCallSuper
  set isVisible(bool value) => _isVisible = value;

  bool get isVisible {
    if (isRemoving == true || _isVisible == false) {
      return false;
    }
    return true;
  }

  bool isVisibleInCamera() {
    return gameRef.camera.isComponentOnCamera(this);
  }

  Iterable<HandlesGesture> get gestureComponents =>
      children.whereType<HandlesGesture>().cast<HandlesGesture>();
}
