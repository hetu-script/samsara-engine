import 'package:flutter/material.dart';

class ResponsiveWindow extends StatelessWidget {
  const ResponsiveWindow({
    super.key,
    this.child,
    this.alignment = AlignmentDirectional.topStart,
    this.size,
    this.margin = const EdgeInsets.all(0.0),
    this.padding = const EdgeInsets.all(0.0),
    this.isPortraitMode = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(5.0)),
    Color? color,
  }) : color = color ?? Colors.black;

  final Widget? child;
  final AlignmentGeometry alignment;
  final Size? size;
  final EdgeInsetsGeometry margin, padding;
  final bool isPortraitMode;
  final BorderRadius borderRadius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        alignment: alignment,
        children: [
          ClipRRect(
            borderRadius: borderRadius,
            child: Container(
              width: size?.width,
              height: size?.height,
              margin: margin,
              padding: padding,
              decoration: BoxDecoration(
                color: color,
                borderRadius: borderRadius,
                border:
                    Border.all(color: Theme.of(context).colorScheme.onSurface),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
