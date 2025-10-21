import 'package:flutter/material.dart';

class ResponsiveView extends StatelessWidget {
  const ResponsiveView({
    super.key,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(5.0),
    this.margin,
    this.borderRadius,
    this.borderColor = Colors.white54,
    this.borderWidth = 0.0,
    this.backgroundColor,
    this.barrierColor = Colors.black54,
    this.barrierDismissible = false,
    this.cursor = MouseCursor.defer,
    this.child,
    this.children = const [],
  });

  final AlignmentGeometry alignment;
  final double? width, height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color borderColor;
  final double borderWidth;
  final Color? backgroundColor;
  final Color? barrierColor;
  final bool barrierDismissible;
  final MouseCursor cursor;
  final Widget? child;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: cursor,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            if (barrierColor != null)
              ModalBarrier(
                color: barrierColor,
                onDismiss: () {
                  if (barrierDismissible) {
                    Navigator.of(context).maybePop();
                  }
                },
              ),
            Align(
              alignment: alignment,
              child: Container(
                width: width,
                height: height,
                padding: padding,
                margin: margin,
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
      ),
    );
  }
}
