import 'package:flutter/material.dart';
import 'package:samsara/richtext/richtext_builder.dart';
import 'package:provider/provider.dart';

import 'hover_content.dart';

const kHoverInfoIndent = 10.0;

class _HoverInfoLayoutDelegate extends SingleChildLayoutDelegate {
  final HoverContent content;
  final Size screenSize;

  _HoverInfoLayoutDelegate({required this.content, required this.screenSize});

  @override
  Size getSize(BoxConstraints constraints) => screenSize;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(maxWidth: content.maxWidth);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final width = childSize.width;
    final height = childSize.height;

    double preferredX, preferredY;

    switch (content.direction) {
      case HoverContentDirection.topLeft:
        preferredX = content.rect.left;
        preferredY = content.rect.top - height - kHoverInfoIndent;
      case HoverContentDirection.topCenter:
        preferredX = content.rect.left + (content.rect.width - width) / 2;
        preferredY = content.rect.top - height - kHoverInfoIndent;
      case HoverContentDirection.topRight:
        preferredX = content.rect.right - width;
        preferredY = content.rect.top - height - kHoverInfoIndent;
      case HoverContentDirection.leftTop:
        preferredX = content.rect.left - width - kHoverInfoIndent;
        preferredY = content.rect.top;
      case HoverContentDirection.leftCenter:
        preferredX = content.rect.left - width - kHoverInfoIndent;
        preferredY = content.rect.top + (content.rect.height - height) / 2;
      case HoverContentDirection.leftBottom:
        preferredX = content.rect.left - width - kHoverInfoIndent;
        preferredY = content.rect.bottom - height - kHoverInfoIndent;
      case HoverContentDirection.rightTop:
        preferredX = content.rect.right + kHoverInfoIndent;
        preferredY = content.rect.top;
      case HoverContentDirection.rightCenter:
        preferredX = content.rect.right + kHoverInfoIndent;
        preferredY = content.rect.top + (content.rect.height - height) / 2;
      case HoverContentDirection.rightBottom:
        preferredX = content.rect.right + kHoverInfoIndent;
        preferredY = content.rect.bottom - height - kHoverInfoIndent;
      case HoverContentDirection.bottomLeft:
        preferredX = content.rect.left;
        preferredY = content.rect.bottom + kHoverInfoIndent;
      case HoverContentDirection.bottomCenter:
        preferredX = content.rect.left + (content.rect.width - width) / 2;
        preferredY = content.rect.bottom + kHoverInfoIndent;
      case HoverContentDirection.bottomRight:
        preferredX = content.rect.right - width - kHoverInfoIndent;
        preferredY = content.rect.bottom + kHoverInfoIndent;
    }

    double maxX = screenSize.width - childSize.width - kHoverInfoIndent;
    final double left =
        preferredX > maxX ? maxX : (preferredX < 0 ? 0 : preferredX);

    double maxY = screenSize.height - childSize.height - kHoverInfoIndent;
    final double top =
        preferredY > maxY ? maxY : (preferredY < 0 ? 0 : preferredY);

    return Offset(left, top);
  }

  @override
  bool shouldRelayout(covariant _HoverInfoLayoutDelegate oldDelegate) {
    return content.rect != oldDelegate.content.rect ||
        content.direction != oldDelegate.content.direction ||
        content.maxWidth != oldDelegate.content.maxWidth ||
        screenSize != oldDelegate.screenSize;
  }
}

class HoverInfo extends StatelessWidget {
  const HoverInfo(
    this.content, {
    super.key,
    this.backgroundColor = Colors.black87,
  });

  final HoverContent content;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final hoverContent = context.read<HoverContentState>().content;
    if (hoverContent == null) {
      return const SizedBox.shrink();
    }

    final screenSize = MediaQuery.sizeOf(context);

    context.watch<HoverContentState>().isDetailed;

    Widget? child;
    dynamic data = content.data;

    if (data is String) {
      final defaultStyle = Theme.of(context).textTheme.bodySmall;
      child = RichText(
        textAlign: content.textAlign,
        text: TextSpan(
          children: buildFlutterRichText(
            data,
            style: TextStyle(
              fontFamily: defaultStyle?.fontFamily,
              fontSize: defaultStyle?.fontSize,
            ),
          ),
        ),
      );
    } else if (data is Widget) {
      child = data;
    }

    return CustomSingleChildLayout(
      delegate: _HoverInfoLayoutDelegate(
        content: content,
        screenSize: screenSize,
      ),
      child: IgnorePointer(
        child: Container(
          color: backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          constraints: BoxConstraints(maxWidth: content.maxWidth),
          child: child,
        ),
      ),
    );
  }
}
