import 'package:flutter/material.dart';

class InkImageButton extends StatelessWidget {
  final double? width, height;

  final Widget? child;

  final VoidCallback onPressed;

  final String? tooltip;

  final double borderRadius;

  const InkImageButton({
    super.key,
    this.width,
    this.height,
    this.tooltip,
    this.child,
    this.borderRadius = 50,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Ink(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onBackground,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            width: 2,
            color: Colors.lightBlue,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Tooltip(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
            ),
            textStyle: const TextStyle(fontSize: 20.0),
            message: tooltip ?? '',
            child: InkWell(
              // customBorder: const CircleBorder(),
              onTap: onPressed,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
