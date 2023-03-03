import 'package:flutter/material.dart';

// import '../../shared/rrect_icon.dart';
// import '../../../shared/close_button.dart';

const _kInfoPanelWidth = 300.0;

class EntityInfo extends StatelessWidget {
  EntityInfo({
    super.key,
    this.left,
    this.actions = const [],
    this.backgroundColor = Colors.black,
    this.borderColor = Colors.white,
    BorderRadiusGeometry? borderRadius,
  }) : borderRadius = borderRadius ?? BorderRadius.circular(5.0);

  final double? left;
  final List<Widget> actions;
  final Color backgroundColor, borderColor;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    double? actualLeft;
    if (left != null) {
      actualLeft = left;
      final contextSize = MediaQuery.of(context).size;
      if (contextSize.width - left! < _kInfoPanelWidth) {
        final l = contextSize.width - _kInfoPanelWidth;
        actualLeft = l > 0 ? l : 0;
      }
    }

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
        },
        child: Stack(
          alignment: AlignmentDirectional.topEnd,
          children: [
            Positioned(
              left: actualLeft,
              top: 80.0,
              child: Container(
                // margin: const EdgeInsets.only(right: 240.0, top: 120.0),
                padding: const EdgeInsets.all(10.0),
                width: _kInfoPanelWidth,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: borderRadius,
                  border: Border.all(color: borderColor),
                ),
                child: ClipRRect(
                  borderRadius: borderRadius,
                  // child: Column(
                  //   mainAxisSize: MainAxisSize.min,
                  //   crossAxisAlignment: CrossAxisAlignment.start,
                  //   children: [
                  //     Row(
                  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //       children: [
                  //         Text(
                  //           entityData['name'],
                  //           style: TextStyle(color: titleColor),
                  //         ),
                  //       ],
                  //     ),
                  //     if (entityData['description'] != null &&
                  //         entityData['description'].isNotEmpty)
                  //       Text(
                  //         entityData['description'],
                  //         style: const TextStyle(color: Colors.grey),
                  //       ),
                  //     if (actions.isNotEmpty) const Divider(),
                  //     if (actions.isNotEmpty)
                  //       Row(
                  //         mainAxisAlignment: MainAxisAlignment.center,
                  //         children: actions,
                  //       ),
                  //   ],
                  // ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
