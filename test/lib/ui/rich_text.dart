import 'package:flutter/material.dart';

import 'package:samsara/widget/embedded_text.dart';

class RichTextView extends StatelessWidget {
  final String text;

  const RichTextView(
    this.text, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: const [
        CloseButton(),
      ]),
      body: Center(
        child: EmbeddedText(text),
      ),
    );
  }
}
