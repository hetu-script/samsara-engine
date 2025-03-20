import 'package:flutter/material.dart';

import 'mouse_region2.dart';

class BorderedIconButton extends StatelessWidget {
  const BorderedIconButton({
    super.key,
    this.size = const Size(24.0, 24.0),
    this.child,
    this.padding = const EdgeInsets.all(0.0),
    this.borderRadius = 0.0,
    this.borderColor = Colors.white54,
    this.borderWidth = 1.0,
    this.onTapDown,
    this.onTapUp,
    this.onMouseEnter,
    this.onMouseExit,
    this.isSelected = false,
  });

  final Size size;
  final Widget? child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color borderColor;
  final double borderWidth;
  final bool isSelected;

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
                color:
                    isSelected ? Theme.of(context).colorScheme.primary : null,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: borderColor,
                  width: borderWidth,
                ),
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
