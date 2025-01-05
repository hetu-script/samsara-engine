import 'package:flutter/material.dart';

class CustomPreferredSizeWidget extends StatelessWidget
    implements PreferredSizeWidget {
  const CustomPreferredSizeWidget({
    super.key,
    this.color,
    this.child,
    this.bottom,
    this.preferredSize = const Size.fromHeight(kToolbarHeight),
  });

  final Color? color;
  final Widget? child;
  final Widget? bottom;

  @override
  final Size preferredSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Column(children: [
        if (child != null) child!,
        if (bottom != null) bottom!,
      ]),
    );
  }
}
