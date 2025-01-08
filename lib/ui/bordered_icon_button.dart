import 'package:flutter/material.dart';

import 'mouse_region2.dart';

class BorderedIconButton extends StatelessWidget {
  BorderedIconButton({
    this.size = const Size(24.0, 24.0),
    this.iconSize = 24.0,
    required this.icon,
    this.padding = const EdgeInsets.all(0.0),
    this.borderRadius = 5.0,
    required this.onTap,
    this.onMouseEnter,
    this.onMouseExit,
  }) : super(key: GlobalKey());

  final Size size;

  final double iconSize;

  final Widget icon;

  final EdgeInsetsGeometry padding;

  final double borderRadius;

  final Function()? onTap;
  final Function(Rect rect)? onMouseEnter;
  final Function()? onMouseExit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: MouseRegion2(
            onMouseEnter: onMouseEnter,
            onMouseExit: onMouseExit,
            child: Container(
              width: size.width,
              height: size.height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                border:
                    Border.all(color: Theme.of(context).colorScheme.onSurface),
                // shape: BoxShape.rectangle,
                // boxShadow: [
                //   BoxShadow(
                //     color: Colors.grey.withOpacity(0.5),
                //     spreadRadius: 3,
                //     blurRadius: 6,
                //     offset: const Offset(0, 2), // changes position of shadow
                //   ),
                // ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: icon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
