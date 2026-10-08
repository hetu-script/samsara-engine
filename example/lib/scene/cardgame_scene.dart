import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/components.dart';
import 'package:samsara/cardgame.dart';

import '../engine.dart';

/// 演示卡牌系统：PiledZone 牌堆 + DrawingZone 手牌区。
/// 点击牌堆抽一张牌到手牌区；双击手牌翻转；手牌可拖动。
class CardGameScene extends Scene {
  CardGameScene({required super.id});

  static final _kCardSize = Vector2(90.0, 126.0);
  static final _kDeckPos = Vector2(180.0, 360.0);
  static final _kHandPos = Vector2(380.0, 560.0);
  static const _kMaxHand = 10;

  late final PiledZone _deck;
  late final DrawingZone _handZone;
  final List<GameCard> _handCards = [];

  Vector2 _handSlot(int index) =>
      Vector2(_kHandPos.x + 50.0 + index * 102.0, _kHandPos.y + 85.0);

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final backButton = SpriteButton(
      anchor: Anchor.center,
      text: 'Back',
      spriteId: 'button.png',
      useSpriteSrcSize: true,
      position: Vector2(70.0, 40.0),
    );
    backButton.onTap = (button, position) {
      engine.popScene();
    };
    world.add(backButton);

    // 构造牌堆：一叠背面朝上的牌
    final deckCards = <GameCard>[];
    for (var i = 0; i < 10; ++i) {
      final card = CustomGameCard(
        id: 'demo_card_$i',
        size: _kCardSize.clone(),
        anchor: Anchor.center,
        preferredSize: _kCardSize,
        isFlipped: true,
        spriteId: 'border4.png',
        illustrationSpriteId: i.isEven ? 'pepe.png' : 'glow.png',
        backSpriteId: 'attack_normal.png',
        title: 'Card $i',
        titleRelativeRect: const Rect.fromLTWH(0.1, 0.02, 0.8, 0.1),
        illustrationRelativeRect: const Rect.fromLTWH(0.08, 0.14, 0.84, 0.46),
        description: '<red>攻击 +$i</>\n<grey>demo card</>',
        descriptionRelativeRect: const Rect.fromLTWH(0.08, 0.64, 0.84, 0.3),
      );
      // 构造完成后重新生成一次边框区域，让描述文本按卡牌实际尺寸排版
      card.generateBorder();
      deckCards.add(card);
      world.add(card);
    }
    _deck = PiledZone(
      position: _kDeckPos.clone(),
      size: _kCardSize.clone(),
      piledCardSize: _kCardSize.clone(),
      pileStartPosition: _kDeckPos.clone(),
      pileOffset: Vector2(2.0, -2.0),
      cards: deckCards,
    );
    for (final card in deckCards) {
      _wireDeckCard(card);
    }
    world.add(_deck);

    // 手牌区
    _handZone = DrawingZone(
      position: _kHandPos.clone(),
      size: Vector2(1010.0, 170.0),
      cards: _handCards,
      drawedCardPosition: _handSlot(0),
      drawedCardSize: _kCardSize.clone(),
    );
    world.add(_handZone);
  }

  void _wireDeckCard(GameCard card) {
    card.onTap = (button, position) {
      // 只有牌堆顶层的牌响应点击
      if (_deck.cards.isNotEmpty && identical(_deck.cards.last, card)) {
        _drawCardToHand();
      }
    };
  }

  void _wireHandCard(GameCard card) {
    card.onDoubleTap = (button, position) {
      card.isFlipped = !card.isFlipped;
    };
    card.onDragStart = (button, position) {
      card.priority = 1000;
      return null;
    };
    card.onDragUpdate = (button, position, delta) {
      card.position += delta;
    };
    card.onDragEnd = (position) {
      card.priority = card.preferredPriority;
    };
  }

  Future<void> _drawCardToHand() async {
    if (_deck.cards.isEmpty || _handCards.length >= _kMaxHand) {
      addHintText('deck empty', position: _kDeckPos + Vector2(45.0, 70.0));
      return;
    }

    final card = _deck.removeCardByIndex(_deck.cards.length - 1);
    if (card == null) return;

    _wireHandCard(card);
    _handCards.add(card);
    final slot = _handSlot(_handCards.length - 1);
    await card.moveTo(
      toPosition: slot,
      duration: 0.5,
      curve: Curves.decelerate,
    );
    // 到达手牌区后翻开
    card.isFlipped = false;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    drawScreenText(
      canvas,
      'CardGame Demo',
      config: ScreenTextConfig(
        size: size,
        anchor: Anchor.topCenter,
        padding: const EdgeInsets.only(top: 15.0),
        textStyle: const TextStyle(fontSize: 24.0, color: Colors.white),
      ),
    );
    drawScreenText(
      canvas,
      'Click the deck to draw a card · double-click a hand card to flip · drag cards',
      config: ScreenTextConfig(
        size: size,
        anchor: Anchor.topLeft,
        padding: const EdgeInsets.only(left: 80.0, top: 100.0),
        textStyle: const TextStyle(fontSize: 16.0, color: Colors.white70),
      ),
    );
    drawScreenText(
      canvas,
      'Deck (${_deck.cards.length})',
      config: ScreenTextConfig(
        size: size,
        anchor: Anchor.topLeft,
        padding: const EdgeInsets.only(left: 180.0, top: 520.0),
        textStyle: const TextStyle(fontSize: 18.0, color: Colors.white),
      ),
    );
    drawScreenText(
      canvas,
      'Hand (${_handCards.length})',
      config: ScreenTextConfig(
        size: size,
        anchor: Anchor.topLeft,
        padding: const EdgeInsets.only(left: 380.0, top: 760.0),
        textStyle: const TextStyle(fontSize: 18.0, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context, {
    Widget Function(BuildContext)? loadingBuilder,
    Map<String, Widget Function(BuildContext, Scene)>? overlayBuilderMap,
    List<String>? initialActiveOverlays,
  }) {
    return Scaffold(
      body: Stack(
        children: [
          SceneWidget(scene: this),
        ],
      ),
    );
  }
}
