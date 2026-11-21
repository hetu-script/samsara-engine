import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samsara/gestures.dart';

void main() {
  testWidgets('pointer movement starts dragging after a long press', (
    tester,
  ) async {
    var longPressCount = 0;
    var dragStartCount = 0;
    var dragUpdateCount = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: PointerDetector(
              longPressTickTimeConsider: 20,
              onLongPress: (_, __, ___) => longPressCount++,
              onDragStart: (_, __, ___) => dragStartCount++,
              onDragUpdate: (_, __, ___) => dragUpdateCount++,
              child: const ColoredBox(color: Color(0xFF000000)),
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ColoredBox)),
    );
    await tester.pump(const Duration(milliseconds: 30));
    expect(longPressCount, 1);
    expect(dragStartCount, 0);

    await gesture.moveBy(const Offset(30, 20));
    await tester.pump(const Duration(milliseconds: 20));
    expect(dragStartCount, 1);
    expect(dragUpdateCount, 0);

    await gesture.moveBy(const Offset(15, 10));
    await tester.pump(const Duration(milliseconds: 20));

    expect(dragStartCount, 1);
    expect(dragUpdateCount, 1);
    await gesture.up();
    await tester.pump();
  });
}
