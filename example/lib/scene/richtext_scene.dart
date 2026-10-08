import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/components.dart';
import 'package:samsara/richtext.dart';

import '../engine.dart';

/// 演示 HTML 风格富文本标签：加粗/斜体、字号、颜色、稀有度、内嵌图标、多行。
/// Flame 侧使用 RichTextComponent，Flutter 侧使用 Label，二者共享同一套标签语法。
class RichTextScene extends Scene {
  RichTextScene({required super.id});

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

    final richText = RichTextComponent(
      text: "<bold>bold</> <italic>italic</> <bold italic>bold+italic</>\n"
          "<t1>t1</> <t3>t3</> <t5>t5</> <h1>h1</> <h2>h2</> <h3>h3</>\n"
          "<red>red</> <blue>blue</> <green>green</> <color='#ffd700'>#ffd700</>\n"
          "<common>common</> <rare>rare</> <epic>epic</> <legendary>legendary</> <mythic>mythic</>\n"
          "<icon=sword></> inline <icon=spirit></> icons <icon=quest></> <icon=wiki></>\n"
          "plain multiline text\n第二行 plain text",
      size: Vector2(760.0, 480.0),
      position: Vector2(340.0, 140.0),
      config: const ScreenTextConfig(textAlign: TextAlign.center),
      backgroundColor: Colors.black38,
    );
    world.add(richText);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    drawScreenText(
      canvas,
      'RichText Demo',
      config: ScreenTextConfig(
        size: size,
        anchor: Anchor.topCenter,
        padding: const EdgeInsets.only(top: 15.0),
        textStyle: const TextStyle(fontSize: 24.0, color: Colors.white),
      ),
    );
    drawScreenText(
      canvas,
      'Flame-side RichTextComponent (above) and Flutter-side Label (below) share the same tag syntax',
      config: ScreenTextConfig(
        size: size,
        anchor: Anchor.topLeft,
        padding: const EdgeInsets.only(left: 340.0, top: 100.0),
        textStyle: const TextStyle(fontSize: 16.0, color: Colors.white70),
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
          // Flutter 侧富文本，与 Flame 侧共用标签语法
          const Positioned(
            left: 340,
            bottom: 60,
            child: Label(
              "<bold h3>Flutter Label</>\n"
              "<red>red</> <color='#ffd700'>#ffd700</> <legendary>legendary</>\n"
              "<icon=sword></> icons work here too <icon=spirit></>",
              width: 760,
              textStyle: TextStyle(fontSize: 18, color: Colors.white),
              textAlign: TextAlign.center,
              backgroundColor: Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}
