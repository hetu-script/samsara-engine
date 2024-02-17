import 'event.dart';

abstract class SceneEvents {
  static const createdScene = 'created_scene';
  static const loadingScene = 'loading_scene';
  static const loadedScene = 'loaded_scene';
  static const endedScene = 'ended_scene';
}

class SceneEvent extends GameEvent {
  String get sceneId => super.scene!;

  const SceneEvent.loaded({required super.scene})
      : super(name: SceneEvents.loadedScene);
}
