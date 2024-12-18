import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:samsara/extensions.dart';

class GameLocalization {
  List<String> errors = [];

  GameLocalization([List<String> localeIds = const ['en', 'zh']]) {
    for (final key in localeIds) {
      _data[key] = {};
    }
  }

  String languageId = 'zh';

  final Map<String, Map<String, dynamic>> _data = {};

  Map<String, dynamic> get current => _data[languageId]!;

  String getLanguageName(String languageId) {
    assert(_data.containsKey(languageId));
    assert(current.containsKey('languageName'));
    return current['languageName'];
  }

  bool hasLanguage(String id) => _data.containsKey(id);

  Future<void> init() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    final assetKeys = manifestMap.keys;

    for (final filename in assetKeys) {
      for (final languageId in _data.keys) {
        if (filename.startsWith('assets/locale/$languageId')) {
          final Map<String, dynamic> languageData = _data[languageId]!;
          final String jsonString = await rootBundle.loadString(filename);
          final Map<String, dynamic> jsonData = json.decode(jsonString);
          for (final key in jsonData.keys) {
            if (languageData.containsKey(key)) {
              //   final arr = [languageData[key]];
              //   arr.add(jsonData[key]);
              //   languageData[key] = arr;
              errors.add('found duplicate locale string: [$key]');
            }
            // else {
            languageData[key] = jsonData[key];
            // }
          }
        }
      }
    }
  }

  /// 这里并不一定需要从JSON或者Map读取数据，
  /// 也可以支持任何拥有keys，并且可以用[]运算符取值的对象。
  void loadData(Map localeData) {
    for (final locale in localeData.values) {
      assert(locale is Map);
      final langId = locale['languageId'];
      if (langId == null) {
        errors.add('invalid locale data. could not found languageId.');
      } else {
        if (_data[langId] == null) _data[langId] = {};
        for (final key in locale.keys) {
          _data[langId]![key] = locale[key]!;
        }
      }
    }
  }

  bool hasLocaleString(String? key) => current.containsKey(key);

  /// 通过一个key获取对应的本地化字符串。
  /// 如果key本身是字符串，就直接获取
  /// 如果key是一个列表，就分别获取对应的字符串，再用 ', ' 拼接起来
  String getLocaleString(dynamic key, {List? interpolations}) {
    // if (text is List) {
    //   text = text.elementAt(Random().nextInt(text.length));
    // }
    if (key is String) {
      String text = current[key] ?? '"$key"';
      if (interpolations != null) {
        text = text.interpolate(interpolations);
      }
      return text;
    } else if (key is List) {
      List<String> result = [];
      for (final k in key) {
        result.add(getLocaleString(k));
      }
      return result.join(', ');
    }

    return '"$key"';
  }
}
