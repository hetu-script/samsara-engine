import 'package:flutter/material.dart';

import 'rrect_icon.dart';

class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    this.name,
    this.margin = const EdgeInsets.all(5.0),
    this.onPressed,
    this.image,
    this.size = const Size(100.0, 100.0),
    this.radius = 10.0,
    this.borderColor,
    this.borderWidth = 2.0,
  });

  final String? name;

  final EdgeInsetsGeometry margin;

  final VoidCallback? onPressed;

  final ImageProvider<Object>? image;

  final Size size;

  final double radius;

  final Color? borderColor;

  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: MouseRegion(
        cursor: onPressed != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: Container(
          margin: margin,
          width: size.width,
          height: size.height,
          child: Stack(
            children: [
              if (image != null)
                RRectIcon(
                  image: image!,
                  size: size,
                  borderRadius: BorderRadius.all(Radius.circular(radius)),
                  borderColor:
                      borderColor ?? Theme.of(context).colorScheme.onSurface,
                  borderWidth: borderWidth,
                ),
              if (name != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(radius)),
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(128),
                    ),
                    child: Text(
                      name!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
