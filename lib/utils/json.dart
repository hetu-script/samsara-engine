import 'dart:convert';

void jsonLikeDataAssign(dynamic target, dynamic source) {
  for (final key in source.keys) {
    target[key] = source[key];
  }
}

const _jsonEncoderWithIndent = JsonEncoder.withIndent('  ');

String jsonEncodeWithIndent(Object? source) =>
    _jsonEncoderWithIndent.convert(source);
