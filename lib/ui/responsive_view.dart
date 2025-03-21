import 'package:flutter/material.dart';

class ResponsiveView extends StatelessWidget {
  const ResponsiveView({
    super.key,
    this.child,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.margin,
    this.isPortraitMode = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(5.0)),
    Color? color,
    this.barrierColor,
    this.children = const [],
  }) : color = color ?? Colors.black;

  final Widget? child;
  final AlignmentGeometry alignment;
  final double? width, height;
  final EdgeInsetsGeometry? margin;
  final bool isPortraitMode;
  final BorderRadius borderRadius;
  final Color color;
  final Color? barrierColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          if (barrierColor != null)
            Positioned.fill(
              child: ModalBarrier(
                color: barrierColor,
              ),
            ),
          // Center(
          //   child:
          // ClipRRect(
          //   borderRadius: borderRadius,
          //   child:
          Align(
            alignment: alignment,
            child: Container(
              width: width,
              height: height,
              margin: margin,
              padding: const EdgeInsets.all(5.0),
              decoration: BoxDecoration(
                color: color,
                borderRadius: borderRadius,
                border:
                    Border.all(color: Theme.of(context).colorScheme.onSurface),
              ),
              child: child,
            ),
          ),
          // ),
          // ),
          ...children,
        ],
      ),
    );
  }
}
