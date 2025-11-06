import 'package:flutter/material.dart';
import 'package:samsara/widgets/ui/rrect_icon.dart';
import 'package:samsara/widgets/ui/mouse_region2.dart';

// import '../../ui.dart';
// import '../../global.dart';
// import '../../data/game.dart';
// import 'character/profile.dart';

enum AvatarNameAlignment {
  inside,
  top,
  bottom,
}

const kNameHeight = 20.0;

class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    this.name,
    this.nameAlignment = AvatarNameAlignment.inside,
    this.cursor,
    this.margin,
    this.image,
    this.borderImage,
    this.imageId,
    this.placeholderId,
    this.showBorderImage = false,
    this.color = Colors.transparent,
    this.size = const Size(100.0, 100.0),
    this.radius = const Radius.circular(10.0),
    this.borderColor = Colors.white54,
    this.borderWidth = 2.0,
    this.onPressed,
    this.onEnter,
    this.onExit,
    this.data,
  });

  final WidgetStateMouseCursor? cursor;
  final AvatarNameAlignment nameAlignment;
  final String? name;
  final EdgeInsetsGeometry? margin;
  final String? imageId;
  final String? placeholderId;
  final ImageProvider<Object>? image, borderImage;
  final bool showBorderImage;
  final Color color;
  final Size size;
  final Radius radius;
  final Color borderColor;
  final double borderWidth;
  final void Function(dynamic data)? onPressed;
  final void Function(Rect)? onEnter;
  final void Function()? onExit;
  final dynamic data;

  @override
  Widget build(BuildContext context) {
    Widget? icon, border;

    String? displayName = name;
    ImageProvider<Object>? iconImg = image;
    ImageProvider<Object>? borderImg = borderImage;

    // dynamic character;

    // if (characterId != null) {
    //   character = GameData.getCharacter(characterId!);
    // } else if (characterData != null) {
    //   character = characterData;
    // }

    // if (displayName == null && character != null) {
    //   if (character != GameData.hero) {
    //     final haveMet = engine.hetu
    //         .invoke('haveMet', positionalArgs: [GameData.hero, character]);
    //     if (haveMet != null) {
    //       displayName = character['name'];
    //     } else {
    //       displayName = '???';
    //     }
    //   } else {
    //     displayName = engine.locale('you');
    //   }
    // }

    if (iconImg == null) {
      if (imageId != null) {
        iconImg = AssetImage('assets/images/$imageId');
      } else if (placeholderId != null) {
        iconImg = AssetImage('assets/images/$placeholderId');
      }
    }

    if (iconImg != null) {
      icon = RRectIcon(
        backgroundColor: color,
        image: iconImg,
        size:
            (displayName != null && nameAlignment != AvatarNameAlignment.inside)
                ? Size(size.width - kNameHeight, size.height - kNameHeight)
                : size,
        borderRadius: BorderRadius.all(radius),
        borderColor: borderColor,
        borderWidth: borderWidth,
      );
    }

    if (showBorderImage) {
      borderImg ??= const AssetImage('assets/images/illustration/border.png');
      border = RRectIcon(
        backgroundColor: Colors.transparent,
        image: borderImg,
        size:
            (displayName != null && nameAlignment != AvatarNameAlignment.inside)
                ? Size(size.width - kNameHeight, size.height - kNameHeight)
                : size,
        borderRadius: BorderRadius.all(radius),
        borderColor: borderColor,
        borderWidth: borderWidth,
      );
    }

    final widgets = <Widget>[];

    final outsideNameWidget = Text(
      displayName.toString(),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 20,
      ),
    );

    if (nameAlignment == AvatarNameAlignment.inside) {
      if (icon != null) {
        widgets.add(icon);
      }
      if (displayName != null) {
        widgets.add(Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: size.width,
            decoration: BoxDecoration(
              color: Colors.white70,
              borderRadius:
                  BorderRadius.only(bottomLeft: radius, bottomRight: radius),
            ),
            child: Text(
              displayName,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ));
      }
      if (showBorderImage) {
        widgets.add(border!);
      }
    } else {
      if (displayName != null && nameAlignment == AvatarNameAlignment.top) {
        widgets.add(Container(
          alignment: Alignment.topCenter,
          child: outsideNameWidget,
        ));
      }
      widgets.add(
        Positioned.fill(
          top: nameAlignment == AvatarNameAlignment.top ? kNameHeight : 0.0,
          child: Container(
            alignment: nameAlignment == AvatarNameAlignment.top
                ? Alignment.bottomCenter
                : nameAlignment == AvatarNameAlignment.bottom
                    ? Alignment.topCenter
                    : Alignment.center,
            child: icon,
          ),
        ),
      );

      if (showBorderImage) {
        widgets.add(
          Positioned.fill(
            top: nameAlignment == AvatarNameAlignment.top ? kNameHeight : 0.0,
            child: Container(
              alignment: nameAlignment == AvatarNameAlignment.top
                  ? Alignment.bottomCenter
                  : nameAlignment == AvatarNameAlignment.bottom
                      ? Alignment.topCenter
                      : Alignment.center,
              child: border,
            ),
          ),
        );
      }
      if (displayName != null && nameAlignment == AvatarNameAlignment.bottom) {
        widgets.add(Container(
          alignment: Alignment.bottomCenter,
          child: outsideNameWidget,
        ));
      }
    }

    return GestureDetector(
      onTap: () => onPressed?.call(data),
      child: MouseRegion2(
        onEnter: onEnter,
        onExit: onExit,
        cursor: cursor?.resolve({WidgetState.hovered}) ?? MouseCursor.defer,
        child: Container(
          margin: margin,
          width: size.width,
          height: nameAlignment != AvatarNameAlignment.inside
              ? size.height + kNameHeight
              : size.height,
          child: Stack(
            children: widgets,
          ),
        ),
      ),
    );
  }
}
