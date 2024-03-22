import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';

import '../engine.dart';

class SamsaraEngineClassBinding extends HTExternalClass {
  SamsaraEngineClassBinding() : super(r'SamsaraEngine');

  @override
  dynamic instanceMemberGet(dynamic instance, String id,
      {bool ignoreUndefined = false}) {
    var engine = instance as SamsaraEngine;
    switch (id) {
      case 'loadLocaleFromJSON':
        return ({positionalArgs, namedArgs}) =>
            engine.loadLocale(positionalArgs.first);
      case 'setLocale':
        return ({positionalArgs, namedArgs}) =>
            engine.setLocale(positionalArgs.first);
      case 'locale':
        return ({positionalArgs, namedArgs}) => engine.locale(
              positionalArgs[0],
              interpolations: namedArgs['interpolations'],
            );
      // case 'updateZoneColors':
      //   return ({positionalArgs, namedArgs}) =>
      //       updateZoneColors(positionalArgs.first);
      // case 'addTileMapZoneColors':
      //   return ({positionalArgs, namedArgs}) =>
      //       engine.addTileMapZoneColors(positionalArgs.first);
      // case 'onIncident':
      //   return ({positionalArgs, namedArgs}) =>
      //       onIncident(positionalArgs.first);
      case 'emit':
        return ({positionalArgs, namedArgs}) =>
            engine.emit(positionalArgs[0], args: positionalArgs[1]);
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
      case 'warn':
        return ({positionalArgs, namedArgs}) => engine.warn(positionalArgs
            .map((object) => engine.hetu.lexicon.stringify(object))
            .join(' '));
      case 'error':
        return ({positionalArgs, namedArgs}) => engine.error(positionalArgs
            .map((object) => engine.hetu.lexicon.stringify(object))
            .join(' '));
      case 'play':
        return ({positionalArgs, namedArgs}) =>
            engine.play(positionalArgs.first);
      case 'loop':
        return ({positionalArgs, namedArgs}) =>
            engine.loop(positionalArgs.first);
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }
}

const kHetuEngineBindingSource = r'''
external class SamsaraEngine {
  fun loadLocaleFromJSON(data: Map)
  fun setLocale(localeId: string)
  fun locale(key: string, {interpolations})
  // fun addTileMapZoneColors(data: List)
  // fun updateNationColors(data: Map)
  fun emit(eventId, args)
  fun log(...content: string)
  fun debug(...content: string)
  fun info(...content: string)
  fun warn(...content: string)
  fun error(...content: string)
  fun play(filename)
  fun loop(filename)
}

let ctx

function build(context) {
  ctx = context
}

let engine: SamsaraEngine
''';
