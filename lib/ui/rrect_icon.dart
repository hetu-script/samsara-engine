import 'package:flutter/material.dart';

class RRectIcon extends StatelessWidget {
  const RRectIcon({
    super.key,
    required this.image,
    this.size = const Size(48.0, 48.0),
    required this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
  });

  final ImageProvider<Object> image;
  final Size size;
  final BorderRadiusGeometry borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: backgroundColor,
          image: DecorationImage(
            fit: BoxFit.fill,
            image: image,
          ),
          borderRadius: borderRadius,
          border: (borderWidth != null && borderWidth! > 0)
              ? Border.all(
                  color: borderColor ?? Theme.of(context).colorScheme.onSurface,
                  width: borderWidth!,
                )
              : null,
        ),
      ),
    );
  }
}
