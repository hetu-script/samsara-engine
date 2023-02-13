class GameLocalization {
  static const missingText = 'missing_text_';

  String get missing => missingText;

  Map<String, String> data = {};

  /// 这里并不一定需要从JSON或者Map读取数据，
  /// 也可以支持任何拥有keys，并且可以用[]运算符取值的对象。
  void loadData(dynamic localeData) {
    if (localeData['languageId'] == null ||
        localeData['languageName'] == null) {
      throw 'Invalid locale data. Must contain languageId & languageName values.';
    }

    for (final key in localeData.keys) {
      data[key] = localeData[key];
    }
  }

  /// 无需本地化的字符串可以直接用 [] 操作符快速获取
  String operator [](String key) {
    final text = data[key];
    if (text == null) {
      return '$missingText($key)';
    } else {
      return text;
    }
  }

  /// 对于需要替换部分字符串的本地化串，使用这个接口
  String getLocaleString(String key, {List<String> interpolations = const []}) {
    var text = this[key];

    for (var i = 0; i < interpolations.length; ++i) {
      text = text.replaceAll('{$i}', interpolations[i]);
    }
    return text;
  }
}
