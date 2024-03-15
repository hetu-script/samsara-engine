import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

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
              errors.add('Found duplicate locale string: [$key]');
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
        errors.add('Invalid locale data. Could not found languageId.');
      } else {
        if (_data[langId] == null) _data[langId] = {};
        for (final key in locale.keys) {
          _data[langId]![key] = locale[key]!;
        }
      }
    }
  }

  /// 对于需要替换部分字符串的本地化串，使用这个接口
  String getLocaleString(String key, {List? interpolations}) {
    // if (text is List) {
    //   text = text.elementAt(Random().nextInt(text.length));
    // }

    String text = current[key] ?? '"$key"';
    if (interpolations != null) {
      for (var i = 0; i < interpolations.length; ++i) {
        text = text.replaceAll('{$i}', '${interpolations[i]}');
      }
    }
    return text;
  }
}
