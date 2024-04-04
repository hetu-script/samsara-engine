import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// List of default markers
const List<RichTextMarker> defaultMarkers = [
  RichTextMarker(
    startPattern: r'\*',
    endPattern: r'\*',
    style: TextStyle(fontWeight: FontWeight.bold),
  ),
  RichTextMarker(
    startPattern: r'/',
    endPattern: r'/',
    style: TextStyle(fontStyle: FontStyle.italic),
  ),
  RichTextMarker(
    startPattern: r'<red ',
    endPattern: r'>',
    style: TextStyle(color: Colors.red),
  ),
  RichTextMarker(
    startPattern: r'<green ',
    endPattern: r'>',
    style: TextStyle(color: Colors.green),
  ),
  RichTextMarker(
    startPattern: r'<blue ',
    endPattern: r'>',
    style: TextStyle(color: Colors.lightBlue),
  ),
  RichTextMarker(
    startPattern: r'<yellow ',
    endPattern: r'>',
    style: TextStyle(color: Colors.yellow),
  ),
];

class RichTextMarker {
  /// Marker to identify in text, ex: *MY TEXT*, marker is "*"
  final String startPattern, endPattern;

  /// Text Style
  final TextStyle style;

  /// Type of Marker
  bool get isTappable => function != null;

  /// List of functions case type is "function" or "sameFunction"
  final void Function(String content)? function;

  /// On error occurred when called any functions above
  final void Function(Object error)? onError;

  const RichTextMarker({
    required this.startPattern,
    required this.endPattern,
    required this.style,
    this.onError,
    this.function,
  });
}

String getPlainText(
  String source, {
  bool useDefaultMarkers = true,
  List<RichTextMarker> additionalMarkers = const [],
}) {
  final List<RichTextMarker> markers = [];
  if (useDefaultMarkers) {
    markers.addAll(defaultMarkers);
  }
  markers.addAll(additionalMarkers);

  for (final marker in markers) {
    source =
        source.replaceAllMapped(RegExp(marker.startPattern), (match) => '');
    source = source.replaceAllMapped(RegExp(marker.endPattern), (match) => '');
  }

  return source;
}

List<TextSpan> buildRichText(
  String source, {
  TextStyle? style,
  bool useDefaultMarkers = true,
  List<RichTextMarker> additionalMarkers = const [],
}) {
  final List<RichTextMarker> markers = [];
  if (useDefaultMarkers) {
    markers.addAll(defaultMarkers);
  }
  markers.addAll(additionalMarkers);

  String process(List<TextSpan> output,
      {RichTextMarker? currentMarker, String? processingText}) {
    processingText ??= source;
    while (processingText!.isNotEmpty) {
      bool noMatch = true;
      for (var marker in markers) {
        final String pattern = '${marker.startPattern}(.*)${marker.endPattern}';
        final List<RegExpMatch> matches =
            RegExp(pattern).allMatches(processingText!).toList();

        if (matches.isNotEmpty) {
          noMatch = false;
          final match = matches.first;
          final before = processingText.substring(0, match.start);
          processingText = processingText.substring(match.end);

          if (before.isNotEmpty) {
            if (currentMarker != null) {
              output.add(TextSpan(
                text: before,
                style: currentMarker.style,
                recognizer: marker.isTappable
                    ? (TapGestureRecognizer()
                      ..onTap = () => marker.function?.call(before))
                    : null,
              ));
            } else {
              output.add(TextSpan(text: before));
            }
          }

          final matchString = match.group(0)!;
          String content = matchString.replaceAllMapped(
              RegExp(marker.startPattern), (match) => '');
          content = content.replaceAllMapped(
              RegExp(marker.endPattern), (match) => '');

          final processed =
              process(output, currentMarker: marker, processingText: content);

          if (processed.isNotEmpty) {
            output.add(TextSpan(
              text: content,
              style: marker.style.merge(currentMarker?.style),
              recognizer: marker.isTappable
                  ? (TapGestureRecognizer()
                    ..onTap = () => marker.function?.call(content))
                  : null,
            ));
          }

          break;
        }
      }
      if (noMatch) {
        break;
      }
    }

    return processingText!;
  }

  final List<TextSpan> textSpans = [];
  final rest = process(textSpans);
  if (rest.isNotEmpty) {
    textSpans.add(TextSpan(text: rest));
  }

  return textSpans;
}
