import 'package:flutter/material.dart';

class ResponsiveView extends StatelessWidget {
  const ResponsiveView({
    super.key,
    this.child,
    this.alignment = AlignmentDirectional.center,
    this.width,
    this.height,
    this.margin,
    this.isPortraitMode = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(5.0)),
    Color? color,
    this.children = const [],
  }) : color = color ?? Colors.black;

  final Widget? child;
  final AlignmentGeometry alignment;
  final double? width, height;
  final EdgeInsetsGeometry? margin;
  final bool isPortraitMode;
  final BorderRadius borderRadius;
  final Color color;
  final List<Widget> children;

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
              width: width,
              height: height,
              margin: margin,
              decoration: BoxDecoration(
                color: color,
                borderRadius: borderRadius,
                border:
                    Border.all(color: Theme.of(context).colorScheme.onSurface),
              ),
              child: child,
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
