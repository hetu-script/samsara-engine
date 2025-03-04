import 'package:flutter/foundation.dart';
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
      case 'debugMode':
        return kDebugMode || engine.config.debugMode;
      case 'loadLocaleDataFromJSON':
        return ({object, positionalArgs, namedArgs}) =>
            engine.loadLocaleDataFromJSON(positionalArgs.first);
      case 'setLanguage':
        return ({object, positionalArgs, namedArgs}) =>
            engine.setLanguage(positionalArgs.first);
      case 'hasLocaleKey':
        return ({object, positionalArgs, namedArgs}) =>
            engine.hasLocaleKey(positionalArgs.first);
      case 'locale':
        return ({object, positionalArgs, namedArgs}) => engine.locale(
              positionalArgs.first,
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
        return ({object, positionalArgs, namedArgs}) =>
            engine.emit(positionalArgs[0], positionalArgs[1]);
      case 'log':
        return ({object, positionalArgs, namedArgs}) => engine.log(
            positionalArgs
                .map((object) => engine.hetu.lexicon.stringify(object))
                .join(' '));
      case 'debug':
        return ({object, positionalArgs, namedArgs}) => engine.debug(
            positionalArgs
                .map((object) => engine.hetu.lexicon.stringify(object))
                .join(' '));
      case 'info':
        return ({object, positionalArgs, namedArgs}) => engine.info(
            positionalArgs
                .map((object) => engine.hetu.lexicon.stringify(object))
                .join(' '));
      case 'warn':
        return ({object, positionalArgs, namedArgs}) => engine.warn(
            positionalArgs
                .map((object) => engine.hetu.lexicon.stringify(object))
                .join(' '));
      case 'error':
        return ({object, positionalArgs, namedArgs}) => engine.error(
            positionalArgs
                .map((object) => engine.hetu.lexicon.stringify(object))
                .join(' '));
      case 'play':
        return ({object, positionalArgs, namedArgs}) =>
            engine.play(positionalArgs.first);
      case 'playBGM':
        return ({object, positionalArgs, namedArgs}) =>
            engine.bgm.play(positionalArgs.first);
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }
}

const kHetuEngineBindingSource = r'''
external class SamsaraEngine {
  get debugMode
  fun loadLocaleDataFromJSON(data: Map)
  fun setLanguage(languageId: string)
  fun hasLocaleKey(key)
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
