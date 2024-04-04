import 'dart:ui';

import 'package:flame/camera.dart';

class World2 extends World {
  void renderFromCamera2(Canvas canvas) {
    render(canvas);
    for (var c in children) {
      c.renderTree(canvas);
    }

    // Any debug rendering should be rendered on top of everything
    if (debugMode) {
      renderDebugMode(canvas);
    }
  }
}
