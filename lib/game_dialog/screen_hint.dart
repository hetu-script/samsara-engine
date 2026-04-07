import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'game_dialog.dart';

class ScreenHint extends StatefulWidget {
  const ScreenHint({
    super.key,
    required this.hintInfo,
    this.cursor,
    this.barrierColor,
    this.textStyle,
    this.borderColor,
    this.borderRadius,
  });

  final ScreenHintInfo hintInfo;
  final MouseCursor? cursor;
  final Color? barrierColor;
  final TextStyle? textStyle;
  final Color? borderColor;
  final double? borderRadius;

  @override
  State<ScreenHint> createState() => _ScreenHintState();
}

class _ScreenHintState extends State<ScreenHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.3, end: 1.0).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.hintInfo;
    final barrierColor =
        widget.barrierColor ?? Colors.black.withValues(alpha: 0.7);
    final borderColor = widget.borderColor ?? Colors.white;
    final borderRadius = widget.borderRadius ?? 4.0;
    final hintRect =
        Rect.fromLTWH(info.left, info.top, info.width, info.height);

    return Stack(
      children: [
        // Semi-transparent overlay with cutout — tap on dark area dismisses
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              context.read<GameDialog>().finishScreenHint();
            },
            child: CustomPaint(
              painter: _CutoutOverlayPainter(
                hintRect: hintRect,
                barrierColor: barrierColor,
                borderRadius: borderRadius,
              ),
            ),
          ),
        ),
        // Highlighted area — tap triggers onTap callback then dismisses
        Positioned(
          left: info.left,
          top: info.top,
          width: info.width,
          height: info.height,
          child: MouseRegion(
            cursor: info.cursor ?? widget.cursor ?? SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                info.onTap?.call();
                context.read<GameDialog>().finishScreenHint();
              },
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius),
                      border: Border.all(
                        color: borderColor.withValues(
                            alpha: _pulseAnimation.value),
                        width: 3.0,
                      ),
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
          ),
        ),
        // Optional text below the highlighted area
        if (info.text != null)
          Positioned(
            left: info.left,
            top: info.top + info.height + 16,
            width: info.width,
            child: IgnorePointer(
              child: Text(
                info.text!,
                textAlign: TextAlign.center,
                style: (widget.textStyle ?? const TextStyle()).merge(
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CutoutOverlayPainter extends CustomPainter {
  final Rect hintRect;
  final Color barrierColor;
  final double borderRadius;

  _CutoutOverlayPainter({
    required this.hintRect,
    required this.barrierColor,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;
    final paint = Paint()..color = barrierColor;

    // Draw entire screen in barrier color, then cut out the hint rect
    canvas.saveLayer(fullRect, Paint());
    canvas.drawRect(fullRect, paint);

    // Cut out the spotlight area
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawRRect(
      RRect.fromRectAndRadius(hintRect, Radius.circular(borderRadius)),
      clearPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_CutoutOverlayPainter oldDelegate) {
    return oldDelegate.hintRect != hintRect ||
        oldDelegate.barrierColor != barrierColor ||
        oldDelegate.borderRadius != borderRadius;
  }
}
