import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';
import 'package:samsara/cardgame/playing_card.dart';

extension PlayingCardBinding on PlayingCard {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'setUsable':
        return ({positionalArgs, namedArgs}) =>
            setUsable(positionalArgs[0], positionalArgs[1]);
      default:
        throw HTError.undefined(varName);
    }
  }
}

class PlayingCardClassBinding extends HTExternalClass {
  PlayingCardClassBinding() : super(r'PlayingCard');

  @override
  dynamic instanceMemberGet(dynamic instance, String id) {
    var i = instance as PlayingCard;
    return i.htFetch(id);
  }
}

const kHetuPlayingCardBindingSource = r'''
external class PlayingCard {
  fun loadLocale(data: Map)
}
''';
