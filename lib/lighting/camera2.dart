import 'package:flame/components.dart';
import '../components/game_component.dart';
import '../extensions.dart';
import 'light_config.dart';
import 'world2.dart';

class Camera2 extends CameraComponent {
  bool enableLighting;

  late Color backgroundLightingColor;

  // Rect _bounds = Rect.zero;

  Camera2({
    this.enableLighting = false,
    Color? backgroundLightingColor,
  }) : backgroundLightingColor =
            backgroundLightingColor ?? Colors.black.withOpacity(0.8);

  /// Renders the [world] as seen through this camera.
  ///
  /// If the world is not mounted yet, only the viewport and viewfinder elements
  /// will be rendered.
  @override
  void renderTree(Canvas canvas) {
    canvas.save();
    canvas.translate(
      viewport.position.x - viewport.anchor.x * viewport.size.x,
      viewport.position.y - viewport.anchor.y * viewport.size.y,
    );
    // Render the world through the viewport
    if ((world?.isMounted ?? false) &&
        CameraComponent.currentCameras.length <
            CameraComponent.maxCamerasDepth) {
      canvas.save();
      viewport.clip(canvas);
      viewport.transformCanvas(canvas);
      backdrop.renderTree(canvas);
      canvas.save();
      try {
        CameraComponent.currentCameras.add(this);
        canvas.transform2D(viewfinder.transform);
        (world as World2).renderFromCamera2(canvas);
        if (enableLighting) {
          canvas.saveLayer(null, Paint());
          canvas.drawColor(backgroundLightingColor, BlendMode.dstATop);
          for (final c in world!.children.whereType<GameComponent>()) {
            if (!c.isVisible) continue;
            if (c.lightConfig != null) {
              final config = c.lightConfig!;
              canvas.save();
              Vector2 lightCenter;
              if (c.lightConfig!.lightCenter != null) {
                lightCenter = c.lightConfig!.lightCenter!;
              } else if (c.lightConfig!.lightCenterOffset != null) {
                lightCenter = c.center + c.lightConfig!.lightCenterOffset!;
              } else {
                lightCenter = c.center;
              }
              switch (config.shape) {
                case LightShape.circle:
                  canvas.drawCircle(
                      lightCenter.toOffset(), config.radius, config.lightPaint);
                // if (c.lightingConfig!.hasHue) {
                //   canvas.drawCircle(lightCenter.toOffset(), c.lightingConfig!.radius,
                //       c.lightingConfig!.huePaint);
                // }
                case LightShape.rect:
                  // canvas.drawRect(
                  //     Rect.fromLTWH(
                  //         c.x - c.width / 2 - config.radius,
                  //         c.y - c.height / 2 - config.radius,
                  //         c.width + config.radius * 2,
                  //         c.height + config.radius * 2),
                  //     config.lightingPaint);
                  canvas.drawRRect(
                      RRect.fromLTRBR(
                        c.x - c.width / 2 - config.radius,
                        c.y - c.height / 2 - config.radius,
                        c.x -
                            c.width / 2 -
                            config.radius +
                            c.width +
                            config.radius * 2,
                        c.y -
                            c.height / 2 -
                            config.radius +
                            c.height +
                            config.radius * 2,
                        Radius.circular(config.radius),
                      ),
                      config.lightPaint);
              }
              canvas.restore();
            }
          }
          canvas.restore();
        }
        // Render the viewfinder elements, which will be in front of the world,
        // but with the same transforms applied to them.
        viewfinder.renderTree(canvas);
      } finally {
        CameraComponent.currentCameras.removeLast();
      }
      canvas.restore();
      // Render the viewport elements, which will be in front of the world.
      viewport.renderTree(canvas);
      canvas.restore();
    }
    canvas.restore();
  }
}
