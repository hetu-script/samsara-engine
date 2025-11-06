import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class MarkdownPage extends StatelessWidget {
  final String data;

  const MarkdownPage(
    this.data, {
    this.scrollController,
    super.key,
  });

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return Markdown(
      data: data,
      controller: scrollController,
      selectable: true,
      // styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      //   p: Theme.of(context).textTheme.bodyMedium,
      //   h1: Theme.of(context).textTheme.headlineLarge,
      //   h2: Theme.of(context).textTheme.headlineMedium,
      //   h3: Theme.of(context).textTheme.headlineSmall,
      //   h4: Theme.of(context).textTheme.titleLarge,
      //   h5: Theme.of(context).textTheme.titleMedium,
      //   h6: Theme.of(context).textTheme.titleSmall,
      //   code: Theme.of(context).textTheme.bodyMedium?.copyWith(
      //       fontFamily: 'monospace', backgroundColor: Colors.grey.shade200),
      //   blockquote: Theme.of(context).textTheme.bodyMedium?.copyWith(
      //       color: Colors.grey.shade600, fontStyle: FontStyle.italic),
      //   blockquoteDecoration: BoxDecoration(
      //     color: Colors.grey.shade100,
      //     borderRadius: BorderRadius.circular(4),
      //     border: Border(
      //       left: BorderSide(
      //         color: Colors.grey.shade400,
      //         width: 4,
      //       ),
      //     ),
      //   ),
      // ),
      // imageBuilder: (uri, title, alt) {
      //   return Image.network(uri.toString());
      // },
      // onTapLink: (text, href, title) {
      //   if (href == null) return;
      //   launchUrl(Uri.parse(href));
      // },
    );
  }
}
