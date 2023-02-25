import 'package:samsara/samsara.dart';
import 'package:samsara/utils/uid.dart';
import 'package:samsara/gestures.dart';

import 'components/playground.dart';
import 'common.dart';

class CardGameScene extends Scene {
  CardGameScene({
    required super.controller,
  }) : super(name: 'cardGame', key: 'cardGame${uid4()}');

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final p = PlayGround(width: kGamepadSize.x, height: kGamepadSize.y);
    add(p);
  }

  @override
  void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
    camera.snapTo(camera.position - details.delta.toVector2());

    super.onDragUpdate(pointer, buttons, details);
  }
}
