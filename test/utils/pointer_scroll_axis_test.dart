import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/pointer_scroll_axis.dart';

/// The production binding's axis lock, over the standard test binding, so the
/// widget cases below exercise the same path a real wheel/trackball event takes.
class _AxisLockTestBinding extends AutomatedTestWidgetsFlutterBinding with PointerScrollAxisLock {}

void main() {
  _AxisLockTestBinding();

  PointerScrollEvent scrollEvent(Offset delta) => PointerScrollEvent(
    viewId: 7,
    timeStamp: const Duration(milliseconds: 1234),
    kind: PointerDeviceKind.mouse,
    device: 3,
    position: const Offset(40, 60),
    scrollDelta: delta,
    embedderId: 9,
  );

  group('lockScrollSignalToDominantAxis', () {
    test('keeps a single-axis signal identical', () {
      final vertical = scrollEvent(const Offset(0, 53));
      final horizontal = scrollEvent(const Offset(-53, 0));
      final still = scrollEvent(Offset.zero);

      expect(lockScrollSignalToDominantAxis(vertical), same(vertical));
      expect(lockScrollSignalToDominantAxis(horizontal), same(horizontal));
      expect(lockScrollSignalToDominantAxis(still), same(still));
    });

    test('drops the minor axis of a diagonal signal', () {
      expect(lockScrollSignalToDominantAxis(scrollEvent(const Offset(1.5, 15))).scrollDelta, const Offset(0, 15));
      expect(lockScrollSignalToDominantAxis(scrollEvent(const Offset(-0.1, -15))).scrollDelta, const Offset(0, -15));
      expect(lockScrollSignalToDominantAxis(scrollEvent(const Offset(20, -3))).scrollDelta, const Offset(20, 0));
    });

    test('breaks an exact tie toward the vertical axis', () {
      expect(lockScrollSignalToDominantAxis(scrollEvent(const Offset(-9, 9))).scrollDelta, const Offset(0, 9));
    });

    test('preserves every other field of the signal', () {
      final locked = lockScrollSignalToDominantAxis(scrollEvent(const Offset(2, 30)));

      expect(locked.viewId, 7);
      expect(locked.timeStamp, const Duration(milliseconds: 1234));
      expect(locked.kind, PointerDeviceKind.mouse);
      expect(locked.device, 3);
      expect(locked.position, const Offset(40, 60));
      expect(locked.embedderId, 9);
    });
  });

  group('a diagonal wheel over a nested row', () {
    // The shape that froze in #2081: a vertical page whose viewport is covered
    // by horizontal rows (hub sections, cast strips, season tabs).
    late ScrollController pageController;
    late List<ScrollController> rowControllers;

    Widget buildPage() {
      pageController = ScrollController();
      rowControllers = List.generate(8, (_) => ScrollController());
      return MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            controller: pageController,
            itemCount: rowControllers.length,
            itemBuilder: (context, row) => SizedBox(
              height: 200,
              child: ListView.builder(
                controller: rowControllers[row],
                scrollDirection: Axis.horizontal,
                itemCount: 20,
                itemBuilder: (context, index) => SizedBox(width: 120, child: Text('$row-$index')),
              ),
            ),
          ),
        ),
      );
    }

    tearDown(() {
      pageController.dispose();
      for (final controller in rowControllers) {
        controller.dispose();
      }
    });

    Future<void> scrollOverRow(WidgetTester tester, Offset delta) async {
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(pointer.hover(tester.getCenter(find.text('1-0'))));
      await tester.sendEventToBinding(pointer.scroll(delta));
      await tester.pump();
    }

    testWidgets('scrolls the page, not the row', (tester) async {
      await tester.pumpWidget(buildPage());

      await scrollOverRow(tester, const Offset(1.5, 120));

      expect(pageController.offset, 120);
      expect(rowControllers[1].offset, 0);
    });

    testWidgets('still scrolls the row when the wheel is horizontal', (tester) async {
      await tester.pumpWidget(buildPage());

      await scrollOverRow(tester, const Offset(120, 1.5));

      expect(rowControllers[1].offset, 120);
      expect(pageController.offset, 0);
    });
  });
}
