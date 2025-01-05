import 'game_component.dart';
import '../task.dart';

class TaskComponent extends GameComponent with TaskController {
  TaskComponent({
    super.key,
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.priority,
    super.nativeAngle,
    super.opacity,
    super.children,
    super.lightConfig,
    super.paint,
    super.isVisible,
  });
}
