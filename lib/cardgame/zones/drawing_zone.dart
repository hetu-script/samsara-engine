import 'dart:async';

import '../../component/game_component.dart';
import '../../gestures.dart';
import '../playing_card.dart';
import '../../paint.dart';

class DrawingZone extends GameComponent with HandlesGesture {
  String? ownedBy;

  bool isOwnedBy(String? player) {
    if (player == null) return false;
    return ownedBy == player;
  }

  final Vector2 drawedCardPosition, drawedCardSize;

  /// the duration of the drawed card reveal time.
  double revealDuration;

  final List<PlayingCard> cards;

  final Anchor tooltipAnchor;
  final EdgeInsets tooltipPadding;

  ScreenTextStyle? piledNumberStyle;

  DrawingZone({
    super.id,
    this.ownedBy,
    super.position,
    super.size,
    super.borderRadius = 5.0,
    required this.cards,
    required this.drawedCardPosition,
    required this.drawedCardSize,
    this.revealDuration = 0.5,
    this.tooltipAnchor = Anchor.topCenter,
    this.tooltipPadding = EdgeInsets.zero,
  }) {
    piledNumberStyle = ScreenTextStyle(
      rect: border,
      anchor: tooltipAnchor,
      padding: tooltipPadding,
    );
  }

  @override
  void generateBorder() {
    super.generateBorder();

    piledNumberStyle = piledNumberStyle?.copyWith(rect: border);
  }

  // @override
  // Future<void> onLoad() async {
  //   super.onLoad();
  // }

  Future<PlayingCard> drawOneCard({bool flip = true}) async {
    assert(cards.isNotEmpty);

    // final drawingAction = Completer();
    // 不知道为什么，不能将下面的操作提取到 action.dart文件中，
    // 而只能以 inline 形式复制到这里使用才可以
    // await waitAllActions();
    // bool check(GameAction action) =>
    //     action.completer != null ? !action.completer!.isCompleted : false;
    // while (gameActions.any(check)) {
    //   await gameActions.firstWhere(check).completer!.future;
    // }

    // gameActions.add(GameAction(completer: drawingAction));

    final card = cards.last;
    cards.removeLast();

    await card.moveTo(
      toPosition: drawedCardPosition,
      toSize: drawedCardSize,
      duration: 0.6,
      curve: Curves.easeIn,
    );

    if (flip) {
      card.isFlipped = false;
    }

    return Future<PlayingCard>.delayed(
      Duration(milliseconds: (revealDuration * 1000).toInt()),
      () => card,
    );
  }

  @override
  void render(Canvas canvas) {
    if (isHovering) {
      drawScreenText(canvas, '数量：${cards.length}', style: piledNumberStyle);
      // canvas.drawRRect(border, borderPaintFocused);
    }
    //  else {
    canvas.drawRRect(rborder, DefaultBorderPaint.light);
    // }

    // for (final card in cards) {
    //   card.render(canvas, position: card.position);
    // }
  }

  // @override
  // void onTap(int buttons, Vector2 position) {
  //   // drawOneCard();
  // }

  @override
  void update(double dt) {
    //   _drawingAnimation?.update(dt);
  }
}
