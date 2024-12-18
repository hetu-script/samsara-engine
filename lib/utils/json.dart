import 'dart:convert';

import 'package:hetu_script/value/struct/struct.dart';

void jsonLikeDataAssign(dynamic target, dynamic source) {
  for (final key in source.keys) {
    target[key] = source[key];
  }
}

const _jsonEncoderWithIndent = JsonEncoder.withIndent('  ');

String jsonEncodeWithIndent(Object? source) =>
    _jsonEncoderWithIndent.convert(source);

dynamic jsonCopy(dynamic data) {
  if (data is Map) {
    final result = <String, dynamic>{};
    for (final key in data.keys) {
      result[key] = jsonCopy(data[key]);
    }
    return result;
  } else if (data is Iterable) {
    final result = [];
    for (final item in data) {
      result.add(jsonCopy(item));
    }
    return result;
  } else if (data is HTStruct) {
    return data.toJSON();
  } else {
    return data;
  }
}
