import 'package:flutter/material.dart';

class ResponsiveWindow extends StatelessWidget {
  const ResponsiveWindow({
    super.key,
    required this.child,
    this.alignment = AlignmentDirectional.topStart,
    this.size,
    this.margin = const EdgeInsets.all(50.0),
    this.isPortraitMode = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(5.0)),
  });

  final Widget child;
  final AlignmentGeometry alignment;
  final Size? size;
  final EdgeInsetsGeometry margin;
  final bool isPortraitMode;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    if (isPortraitMode) {
      return child;
    } else {
      return Material(
        type: MaterialType.transparency,
        child: Stack(
          alignment: alignment,
          children: [
            Container(
              width: size?.width,
              height: size?.height,
              margin: margin,
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                border: Border.all(
                    color: Theme.of(context).colorScheme.onBackground),
              ),
              child: ClipRRect(
                borderRadius: borderRadius,
                child: child,
              ),
            ),
          ],
        ),
      );
    }
  }
}
