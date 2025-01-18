import 'package:flutter/material.dart';

class CloseButton2 extends StatelessWidget {
  const CloseButton2({
    super.key,
    this.color,
    this.onPressed,
    this.tooltip,
    this.child,
  });

  final Color? color;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: child ?? const Icon(Icons.close),
      color: color,
      tooltip: tooltip,
      onPressed: () {
        if (onPressed != null) {
          onPressed!();
        } else {
          Navigator.maybePop(context, null);
        }
      },
    );
  }
}
