import 'package:flutter/material.dart';

class ButtonClose extends StatelessWidget {
  const ButtonClose({
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
        }
        Navigator.maybePop(context);
      },
    );
  }
}
