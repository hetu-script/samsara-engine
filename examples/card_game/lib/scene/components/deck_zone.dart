import 'package:samsara/cardgame/cardgame.dart';
import 'package:flame/components.dart';

import '../common.dart';

class DeckZone extends PiledZone {
  DeckZone({
    super.id,
    required super.x,
    required super.y,
    super.cards,
    super.focusOffset,
    super.titleAnchor = Anchor.topRight,
  }) : super(
          width: kDeckZoneWidth,
          height: kDeckZoneHeight,
          piledCardSize: kCardSize,
        );
}
