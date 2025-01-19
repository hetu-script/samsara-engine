import 'dart:convert';

import 'package:hetu_script/values.dart';
import 'package:hetu_script/utils/json.dart';

void jsonLikeDataAssign(dynamic target, dynamic source) {
  for (final key in source.keys) {
    target[key] = source[key];
  }
}

const _jsonEncoderWithIndent = JsonEncoder.withIndent('  ');

String jsonEncodeWithIndent(Object? source) =>
    _jsonEncoderWithIndent.convert(source);

Map<String, dynamic> jsonParse(dynamic source) {
  if (source is Map) {
    return source.cast<String, dynamic>();
  } else if (source is String) {
    return (jsonDecode(source) as Map).cast<String, dynamic>();
  } else if (source is HTStruct) {
    return jsonifyStruct(source);
  } else {
    throw ArgumentError('Invalid json source type: ${source.runtimeType}');
  }
}
