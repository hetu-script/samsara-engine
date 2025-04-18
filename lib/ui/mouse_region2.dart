import 'package:flutter/material.dart';

import '../pointer_detector.dart';

class MouseRegion2 extends StatelessWidget {
  MouseRegion2({
    this.cursor = MouseCursor.defer,
    this.onTapDown,
    this.onTapUp,
    this.onMouseEnter,
    this.onMouseExit,
    this.hitTestBehavior,
    required this.child,
  }) : super(key: GlobalKey());

  final MouseCursor cursor;
  final void Function()? onTapDown;
  final void Function()? onTapUp;
  final void Function(Rect rect)? onMouseEnter;
  final void Function()? onMouseExit;
  final HitTestBehavior? hitTestBehavior;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: cursor,
      hitTestBehavior: hitTestBehavior,
      onEnter: (event) {
        if (onMouseEnter == null) return;

        final renderBox = context.findRenderObject() as RenderBox;
        final Size size = renderBox.size;
        final Offset offset = renderBox.localToGlobal(Offset.zero);
        final Rect rect =
            Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
        onMouseEnter!.call(rect);
      },
      onExit: (event) {
        onMouseExit?.call();
      },
      child: PointerDetector(
        onTapDown: (pointer, button, details) {
          onTapDown?.call();
        },
        onTapUp: (pointer, button, details) {
          onTapUp?.call();
        },
        child: child,
      ),
    );
  }
}
