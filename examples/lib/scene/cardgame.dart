import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/utils/uid.dart';

import 'components/playground.dart';

class CardGameScene extends Scene {
  CardGameScene({
    required super.controller,
  }) : super(name: 'cardGame', key: 'cardGame${uid(4)}');

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final p = PlayGround(width: 1280.0, height: 720.0);

    add(p);
  }

  @override
  void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
    camera.snapTo(camera.position - details.delta.toVector2());

    super.onDragUpdate(pointer, buttons, details);
  }
}
