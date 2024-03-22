import 'package:flutter/material.dart';

class InkButton extends StatelessWidget {
  const InkButton({
    super.key,
    required this.size,
    this.borderRadius,
    this.image,
    this.child,
    this.onPressed,
    this.padding = const EdgeInsets.all(0.0),
    this.isSelected = false,
    this.isEnabled = true,
  });

  final Size size;

  final BorderRadius? borderRadius;

  final ImageProvider<Object>? image;

  final Widget? child;

  final void Function()? onPressed;

  final EdgeInsetsGeometry padding;

  final bool isSelected, isEnabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: MouseRegion(
        cursor:
            isEnabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        child: Material(
          type: MaterialType.transparency,
          child: Ink(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              border: isSelected
                  ? Border.all(
                      color: Colors.white.withOpacity(0.5),
                    )
                  : null,
              borderRadius: borderRadius,
              image: image != null
                  ? DecorationImage(
                      image: image!,
                      fit: BoxFit.fill,
                    )
                  : null,
            ),
            child: InkWell(
              borderRadius: borderRadius,
              onTap: isEnabled ? onPressed : null,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
