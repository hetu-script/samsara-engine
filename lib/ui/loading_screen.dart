import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({
    super.key,
    required this.text,
    this.showClose = false,
  });

  final String text;
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.center,
            child: Text(
              text,
              style: const TextStyle(fontSize: 18.0),
            ),
          ),
          if (showClose)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).maybePop();
              },
              child: const Text('Close'),
            )
        ],
      ),
    );
  }
}
