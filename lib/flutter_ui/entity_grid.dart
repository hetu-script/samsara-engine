import 'package:flutter/material.dart';

import 'rrect_icon.dart';

enum GridStyle {
  icon,
  card,
}

class EntityGrid extends StatelessWidget {
  EntityGrid({
    super.key,
    this.style = GridStyle.icon,
    this.size = const Size(48.0, 48.0),
    this.hasBorder = true,
    this.child,
    this.icon,
    this.backgroundImage,
    this.onPressed,
    this.tooltip,
    this.backgroundColor = Colors.black,
    this.borderColor = Colors.white,
    this.title,
    this.showTitle = false,
  }) : borderRadius = BorderRadius.circular(5.0);

  final String? tooltip;
  final GridStyle style;
  final Size size;
  final bool hasBorder;
  final Widget? child;
  final ImageProvider<Object>? icon, backgroundImage;
  final void Function()? onPressed;
  final Color backgroundColor, borderColor;
  final BorderRadiusGeometry borderRadius;
  final String? title;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case GridStyle.icon:
        return GestureDetector(
          onTapUp: (TapUpDetails details) {
            onPressed?.call();
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child:
                // Tooltip(
                //   message: tooltip,
                //   child:

                Container(
              width: size.width,
              height: size.height,
              decoration: hasBorder
                  ? BoxDecoration(
                      color: backgroundColor,
                      border: Border.all(
                        color: borderColor,
                      ),
                      image: backgroundImage != null
                          ? DecorationImage(
                              fit: BoxFit.contain,
                              image: backgroundImage!,
                              opacity: 0.2,
                            )
                          : null,
                      borderRadius: borderRadius,
                    )
                  : null,
              child: Stack(
                children: [
                  if (icon != null)
                    RRectIcon(
                      image: icon!,
                      size: size,
                      borderRadius: borderRadius,
                      borderColor: Colors.transparent,
                      borderWidth: 0.0,
                    ),
                  if (child != null) child!,
                  if (title != null && showTitle)
                    Align(
                      alignment: AlignmentDirectional.bottomCenter,
                      child: Text(title!),
                    ),
                ],
              ),
              // ),
            ),
          ),
        );
      case GridStyle.card:
        final iconSize = size.height - 10.0;
        return Container(
          padding: const EdgeInsets.all(10.0),
          decoration: hasBorder
              ? BoxDecoration(
                  color: backgroundColor,
                  border: Border.all(
                    color: borderColor,
                  ),
                  image: backgroundImage != null
                      ? DecorationImage(
                          fit: BoxFit.contain,
                          image: backgroundImage!,
                          opacity: 0.2,
                        )
                      : null,
                  borderRadius: borderRadius,
                )
              : null,
          child: Row(
            children: [
              GestureDetector(
                onTapUp: (TapUpDetails details) {
                  onPressed?.call();
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                      width: size.height,
                      height: size.height,
                      padding: const EdgeInsets.all(5.0),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        border: Border.all(
                          color: borderColor,
                        ),
                        image: backgroundImage != null
                            ? DecorationImage(
                                fit: BoxFit.contain,
                                image: backgroundImage!,
                                opacity: 0.2,
                              )
                            : null,
                        borderRadius: borderRadius,
                      ),
                      child: Stack(
                        children: [
                          if (icon != null)
                            RRectIcon(
                              image: icon!,
                              size: Size(iconSize, iconSize),
                              borderRadius: borderRadius,
                              borderColor: Colors.transparent,
                              borderWidth: 0.0,
                            ),
                        ],
                      )),
                ),
              ),
              if (child != null) child!,
            ],
          ),
        );
    }
  }
}
