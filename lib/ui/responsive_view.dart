import 'package:flutter/material.dart';

class ResponsiveView extends StatelessWidget {
  const ResponsiveView({
    super.key,
    this.child,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.margin,
    this.borderRadius,
    this.borderColor = Colors.white54,
    this.borderWidth = 0.0,
    this.backgroundColor,
    this.barrierColor,
    this.children = const [],
  });

  final Widget? child;
  final AlignmentGeometry alignment;
  final double? width, height;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color borderColor;
  final double borderWidth;
  final Color? backgroundColor;
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
                dismissible: false,
              ),
            ),
          Align(
            alignment: alignment,
            child: Container(
              width: width,
              height: height,
              margin: margin,
              padding: const EdgeInsets.all(5.0),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: borderRadius != null
                    ? BorderRadius.circular(borderRadius!)
                    : null,
                border: borderWidth > 0
                    ? Border.all(
                        width: borderWidth,
                        color: Theme.of(context).colorScheme.onSurface,
                      )
                    : null,
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
