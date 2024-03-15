import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';
import 'package:samsara/cardgame/card.dart';

class PlayingCardClassBinding extends HTExternalClass {
  PlayingCardClassBinding() : super(r'PlayingCard');

  @override
  dynamic instanceMemberGet(dynamic instance, String id,
      {bool ignoreUndefined = false}) {
    final object = instance as Card;
    switch (id) {
      case 'setUsable':
        return ({positionalArgs, namedArgs}) =>
            object.setUsable(positionalArgs[0], positionalArgs[1]);
      default:
        throw HTError.undefined(id);
    }
  }
}

const kHetuPlayingCardBindingSource = r'''
external class PlayingCard {
  fun loadLocale(data: Map)
}
''';
