import 'package:flutter/material.dart';

import 'mouse_region2.dart';

class BorderedIconButton extends StatelessWidget {
  BorderedIconButton({
    this.size = const Size(24.0, 24.0),
    this.child,
    this.padding = const EdgeInsets.all(0.0),
    this.borderRadius = 5.0,
    this.onTapDown,
    this.onTapUp,
    this.onMouseEnter,
    this.onMouseExit,
  }) : super(key: GlobalKey());

  final Size size;
  final Widget? child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  final Function()? onTapDown;
  final Function()? onTapUp;
  final Function(Rect rect)? onMouseEnter;
  final Function()? onMouseExit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTapDown: (details) {
            onTapDown?.call();
          },
          onTapUp: (details) {
            onTapUp?.call();
          },
          child: MouseRegion2(
            onMouseEnter: onMouseEnter,
            onMouseExit: onMouseExit,
            child: Container(
              width: size.width,
              height: size.height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                border:
                    Border.all(color: Theme.of(context).colorScheme.onSurface),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
