import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({
    super.key,
    required this.text,
    this.alignment = Alignment.bottomRight,
  });

  final String text;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Container(
        padding: const EdgeInsets.all(25.0),
        alignment: alignment,
        child: Text(
          text,
          style: const TextStyle(fontSize: 18.0),
        ),
      ),
    );
  }
}
