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
      case 'random':
        return engine.random;
      case 'debugMode':
        return engine.config.debugMode;
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
      case 'warning':
        return ({object, positionalArgs, namedArgs}) => engine.warning(
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
      case 'loop':
        return ({object, positionalArgs, namedArgs}) =>
            engine.bgm.play(positionalArgs.first);
      case 'pushScene':
        return ({object, positionalArgs, namedArgs}) => engine.pushScene(
            positionalArgs.first,
            constructorId: namedArgs['constructorId'],
            arguments: namedArgs['arguments'],
            triggerOnStart: namedArgs['triggerOnStart'] ?? true);
      case 'switchScene':
        return ({object, positionalArgs, namedArgs}) => engine.switchScene(
            positionalArgs.first,
            arguments: namedArgs['arguments'],
            triggerOnStart: namedArgs['triggerOnStart'] ?? true);
      case 'popScene':
        return ({object, positionalArgs, namedArgs}) =>
            engine.popScene(clearCache: namedArgs['clearCache'] ?? false);
      case 'popSceneTill':
        return ({object, positionalArgs, namedArgs}) => engine.popSceneTill(
            positionalArgs.first,
            clearCache: namedArgs['clearCache'] ?? false);
      case 'clearSceneCache':
        return ({object, positionalArgs, namedArgs}) =>
            engine.clearCachedScene(positionalArgs.first);
      case 'clearAllCachedScene':
        return ({object, positionalArgs, namedArgs}) =>
            engine.clearAllCachedScene(
              except: namedArgs['except'],
              arguments: namedArgs['arguments'],
              triggerOnStart: namedArgs['triggerOnStart'] ?? true,
            );

      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }
}

const kHetuEngineBindingSource = r'''
external class SamsaraEngine {
  get random
  get debugMode
  function loadLocaleDataFromJSON(data: Map)
  function setLanguage(languageId: string)
  function hasLocaleKey(key: string)
  function locale(key: string, {interpolations: List})
  function emit(eventId, args)
  function log(...content: string)
  function debug(...content: string)
  function info(...content: string)
  function warning(...content: string)
  function error(...content: string)
  function play(filename: string)
  function loop(filename: string)
  function pushScene(sceneId: string, {constructorId: string, arguments, triggerOnStart: bool = true})
  function switchScene(sceneId: string, {arguments, triggerOnStart: bool = true})
  function popScene({clearCache: bool = false})
  function popSceneTill(sceneId: string, {clearCache: bool = false})
  function clearCachedScene(sceneId: string)
  function clearAllCachedScene({except: string, arguments, triggerOnStart: bool = true})
}

let ctx

function build(context) {
  ctx = context
}

let engine: SamsaraEngine
''';
