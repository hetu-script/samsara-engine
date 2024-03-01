import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';

import '../engine.dart';

class SamsaraEngineClassBinding extends HTExternalClass {
  SamsaraEngineClassBinding() : super(r'SamsaraEngine');

  @override
  dynamic instanceMemberGet(dynamic instance, String id) {
    var engine = instance as SamsaraEngine;
    switch (id) {
      case 'loadLocale':
        return ({positionalArgs, namedArgs}) =>
            engine.loadLocale(positionalArgs.first);
      case 'setLocale':
        return ({positionalArgs, namedArgs}) =>
            engine.setLocale(positionalArgs.first);
      case 'locale':
        return ({positionalArgs, namedArgs}) => engine.locale.getLocaleString(
              positionalArgs[0],
              interpolations: positionalArgs[1],
            );
      // case 'updateZoneColors':
      //   return ({positionalArgs, namedArgs}) =>
      //       updateZoneColors(positionalArgs.first);
      case 'loadColors':
        return ({positionalArgs, namedArgs}) =>
            engine.loadColors(positionalArgs.first);
      // case 'onIncident':
      //   return ({positionalArgs, namedArgs}) =>
      //       onIncident(positionalArgs.first);
      case 'log':
        return ({positionalArgs, namedArgs}) => engine.log(positionalArgs
            .map((object) => engine.hetu.lexicon.stringify(object))
            .join(' '));
      case 'debug':
        return ({positionalArgs, namedArgs}) => engine.debug(positionalArgs
            .map((object) => engine.hetu.lexicon.stringify(object))
            .join(' '));
      case 'info':
        return ({positionalArgs, namedArgs}) => engine.info(positionalArgs
            .map((object) => engine.hetu.lexicon.stringify(object))
            .join(' '));
      case 'warning':
        return ({positionalArgs, namedArgs}) => engine.warn(positionalArgs
            .map((object) => engine.hetu.lexicon.stringify(object))
            .join(' '));
      case 'error':
        return ({positionalArgs, namedArgs}) => engine.error(positionalArgs
            .map((object) => engine.hetu.lexicon.stringify(object))
            .join(' '));
      default:
        throw HTError.undefined(id);
    }
  }
}

const kHetuEngineBindingSource = r'''
external class SamsaraEngine {
  fun loadLocale(data: Map)
  fun setLocale(localeId: string)
  fun locale(key: string, [interpolations: List])
  fun loadColors(data: List)
  // fun updateNationColors(data: Map)
  fun log(...content: string)
  fun debug(...content: string)
  fun info(...content: string)
  fun warning(...content: string)
  fun error(...content: string)
}

var buildContext

fun build(ctx) {
  buildContext = ctx
}

var engine: SamsaraEngine
''';
