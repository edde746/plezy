import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/scroll_utils.dart';

void main() {
  group('scrollContextToCenter', () {
    test('null context is a no-op (does not throw)', () {
      // Calling with null must not register a post-frame callback or throw.
      expect(() => scrollContextToCenter(null), returnsNormally);
    });

    testWidgets('non-null context with no scrollable ancestor does not throw', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              capturedContext = ctx;
              return const SizedBox();
            },
          ),
        ),
      );
      // No Scrollable ancestor; ensureVisible has nothing to do but also
      // shouldn't crash. Pumping a frame triggers the post-frame callback.
      expect(() {
        scrollContextToCenter(capturedContext);
      }, returnsNormally);
      // A pump runs the post-frame callback; it should be a no-op gracefully.
      await tester.pump();
    });

    testWidgets('removed target before the callback is a no-op', (tester) async {
      final controller = ScrollController();
      final targetKey = GlobalKey();
      late StateSetter setHostState;
      var showTarget = true;

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 200,
            child: StatefulBuilder(
              builder: (context, setState) {
                setHostState = setState;
                return SingleChildScrollView(
                  controller: controller,
                  child: Column(
                    children: [
                      const SizedBox(height: 500),
                      if (showTarget) SizedBox(key: targetKey, height: 100),
                      const SizedBox(height: 600),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      final targetContext = targetKey.currentContext!;
      scrollContextToCenter(targetContext);
      setHostState(() => showTarget = false);
      await tester.pump();

      expect(targetContext.mounted, isFalse);
      expect(tester.takeException(), isNull);
      expect(controller.offset, 0);
      controller.dispose();
    });

    testWidgets('replacement render object under the same context is a no-op', (tester) async {
      final controller = ScrollController();
      late BuildContext targetContext;
      late StateSetter setTargetState;
      var replaceTarget = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              height: 200,
              child: SingleChildScrollView(
                controller: controller,
                child: Column(
                  children: [
                    const SizedBox(height: 500),
                    StatefulBuilder(
                      builder: (context, setState) {
                        targetContext = context;
                        setTargetState = setState;
                        if (replaceTarget) {
                          return const ColoredBox(
                            key: ValueKey('replacement'),
                            color: Colors.red,
                            child: SizedBox(width: 100, height: 100),
                          );
                        }
                        return const SizedBox(key: ValueKey('original'), width: 100, height: 100);
                      },
                    ),
                    const SizedBox(height: 600),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final selectedRenderObject = targetContext.findRenderObject();
      scrollContextToCenter(targetContext);
      setTargetState(() => replaceTarget = true);
      await tester.pump();

      expect(targetContext.mounted, isTrue);
      expect(targetContext.findRenderObject(), isNot(same(selectedRenderObject)));
      expect(tester.takeException(), isNull);
      expect(controller.offset, 0);
      controller.dispose();
    });

    testWidgets('reparented target does not scroll its old or new scrollable', (tester) async {
      final firstController = ScrollController();
      final secondController = ScrollController();
      final targetKey = GlobalKey();
      late StateSetter setHostState;
      var useSecondScrollable = false;

      Widget buildScrollable(ScrollController controller, bool containsTarget) {
        return SizedBox(
          height: 200,
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              children: [
                const SizedBox(height: 500),
                if (containsTarget) SizedBox(key: targetKey, height: 100),
                const SizedBox(height: 600),
              ],
            ),
          ),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              setHostState = setState;
              return Column(
                children: [
                  buildScrollable(firstController, !useSecondScrollable),
                  buildScrollable(secondController, useSecondScrollable),
                ],
              );
            },
          ),
        ),
      );

      final targetContext = targetKey.currentContext!;
      scrollContextToCenter(targetContext);
      setHostState(() => useSecondScrollable = true);
      await tester.pump();

      expect(targetContext.mounted, isTrue);
      expect(targetKey.currentContext, same(targetContext));
      expect(tester.takeException(), isNull);
      expect(firstController.offset, 0);
      expect(secondController.offset, 0);
      firstController.dispose();
      secondController.dispose();
    });

    testWidgets('reparented target within the same PageView does not scroll', (tester) async {
      final pageController = PageController(viewportFraction: 0.5);
      final targetKey = GlobalKey();
      late StateSetter setHostState;
      var useSecondPage = false;

      Widget buildPage(bool containsTarget) {
        return Center(
          child: containsTarget
              ? SizedBox(key: targetKey, width: 100, height: 100)
              : const SizedBox(width: 100, height: 100),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 300,
              height: 200,
              child: StatefulBuilder(
                builder: (context, setState) {
                  setHostState = setState;
                  return PageView(
                    controller: pageController,
                    padEnds: false,
                    children: [buildPage(!useSecondPage), buildPage(useSecondPage)],
                  );
                },
              ),
            ),
          ),
        ),
      );

      final targetContext = targetKey.currentContext!;
      final targetRenderObject = targetContext.findRenderObject();
      final selectedScrollable = Scrollable.of(targetContext);
      scrollContextToCenter(targetContext);
      setHostState(() => useSecondPage = true);
      await tester.pump();

      expect(targetContext.mounted, isTrue);
      expect(targetKey.currentContext, same(targetContext));
      expect(targetContext.findRenderObject(), same(targetRenderObject));
      expect(Scrollable.of(targetContext), same(selectedScrollable));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(pageController.offset, 0);
      pageController.dispose();
    });

    testWidgets('live target remains centered', (tester) async {
      final controller = ScrollController();
      final pageController = PageController();
      final targetKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              height: 200,
              child: PageView(
                controller: pageController,
                children: [
                  SingleChildScrollView(
                    controller: controller,
                    child: Column(
                      children: [
                        const SizedBox(height: 500),
                        SizedBox(key: targetKey, height: 100),
                        const SizedBox(height: 600),
                      ],
                    ),
                  ),
                  const SizedBox(),
                ],
              ),
            ),
          ),
        ),
      );

      scrollContextToCenter(targetKey.currentContext);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(controller.offset, closeTo(450, 0.5));
      expect(pageController.page, 0);
      controller.dispose();
      pageController.dispose();
    });
  });

  group('scrollToCurrentItem', () {
    testWidgets('no-op when controller has no clients', (tester) async {
      // Controller never attached -> hasClients is false -> early return.
      final controller = ScrollController();
      final firstItemKey = GlobalKey();

      // Need a binding for addPostFrameCallback to run; build any widget tree.
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      expect(() {
        scrollToCurrentItem(controller, firstItemKey, 5);
      }, returnsNormally);

      // Pump a frame to drain post-frame callbacks.
      await tester.pump();
      controller.dispose();
    });

    testWidgets('no-op when GlobalKey has no current context', (tester) async {
      final controller = ScrollController();
      final firstItemKey = GlobalKey();

      // Attach the controller to a real list so hasClients is true,
      // but never mount the firstItemKey -> findRenderObject() returns null.
      await tester.pumpWidget(
        MaterialApp(
          home: ListView(controller: controller, children: const [SizedBox(height: 50)]),
        ),
      );

      expect(() {
        scrollToCurrentItem(controller, firstItemKey, 3);
      }, returnsNormally);

      await tester.pump();
      // Offset must be unchanged because the function bailed out.
      expect(controller.offset, 0.0);
    });

    testWidgets('scrolls to currentIndex * itemHeight, clamped to maxExtent', (tester) async {
      final controller = ScrollController();
      final firstItemKey = GlobalKey();
      const itemHeight = 50.0;
      const itemCount = 100;
      // Default test viewport is 800x600 — fill it directly.
      const viewportHeight = 600.0;

      await tester.pumpWidget(
        MaterialApp(
          home: ListView.builder(
            controller: controller,
            itemCount: itemCount,
            itemBuilder: (_, i) => SizedBox(key: i == 0 ? firstItemKey : null, height: itemHeight, child: Text('$i')),
          ),
        ),
      );

      // Sanity-check viewport assumption.
      expect(controller.position.viewportDimension, viewportHeight);

      // Tap the function and pump to flush post-frame.
      scrollToCurrentItem(controller, firstItemKey, 10);
      await tester.pump();

      // 10 * 50 = 500, well within max extent (50 * 100 - 600 = 4400).
      expect(controller.offset, 500.0);
      controller.dispose();
    });

    testWidgets('clamps target to max scroll extent for huge index', (tester) async {
      final controller = ScrollController();
      final firstItemKey = GlobalKey();
      const itemHeight = 50.0;
      const itemCount = 20;

      await tester.pumpWidget(
        MaterialApp(
          home: ListView.builder(
            controller: controller,
            itemCount: itemCount,
            itemBuilder: (_, i) => SizedBox(key: i == 0 ? firstItemKey : null, height: itemHeight, child: Text('$i')),
          ),
        ),
      );

      scrollToCurrentItem(controller, firstItemKey, 10000);
      await tester.pump();

      // Max extent equals position.maxScrollExtent — read it from the
      // controller so the test stays robust against viewport changes.
      expect(controller.offset, controller.position.maxScrollExtent);
      controller.dispose();
    });
  });

  group('scrollListToIndex', () {
    testWidgets('no-op when controller has no clients', (tester) async {
      final controller = ScrollController();

      // Need a binding before invoking, even if controller is unattached.
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      expect(() {
        scrollListToIndex(controller, 5, itemExtent: 100);
      }, returnsNormally);
      controller.dispose();
    });

    testWidgets('no-op when itemExtent <= 0', (tester) async {
      final controller = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              controller: controller,
              children: List.generate(10, (i) => SizedBox(width: 80, height: 80, child: Text('$i'))),
            ),
          ),
        ),
      );

      // itemExtent of 0 must short-circuit.
      scrollListToIndex(controller, 5, itemExtent: 0);
      await tester.pump();
      expect(controller.offset, 0.0);

      // Negative itemExtent also short-circuits.
      scrollListToIndex(controller, 5, itemExtent: -10);
      await tester.pump();
      expect(controller.offset, 0.0);

      controller.dispose();
    });

    testWidgets('jumpTo (animate=false) centers the indexed item', (tester) async {
      final controller = ScrollController();
      const itemExtent = 100.0;
      const leadingPadding = 12.0;

      await tester.pumpWidget(
        MaterialApp(
          home: ListView(
            scrollDirection: Axis.horizontal,
            controller: controller,
            children: List.generate(20, (i) => SizedBox(width: itemExtent, height: 100, child: Text('$i'))),
          ),
        ),
      );

      // Viewport reflects whatever the test surface assigns; read it.
      final viewport = controller.position.viewportDimension;

      const index = 10;
      scrollListToIndex(controller, index, itemExtent: itemExtent, animate: false);
      await tester.pump();

      // Expected: leading + index*extent + extent/2 - viewport/2
      final expected = (leadingPadding + index * itemExtent + itemExtent / 2 - viewport / 2).clamp(
        0.0,
        controller.position.maxScrollExtent,
      );
      expect(controller.offset, expected);
      controller.dispose();
    });

    testWidgets('clamps to 0 when target would be negative', (tester) async {
      final controller = ScrollController();
      const itemExtent = 100.0;

      await tester.pumpWidget(
        MaterialApp(
          home: ListView(
            scrollDirection: Axis.horizontal,
            controller: controller,
            children: List.generate(20, (i) => SizedBox(width: itemExtent, height: 100, child: Text('$i'))),
          ),
        ),
      );

      // Centering the first item would require negative offset; should clamp.
      scrollListToIndex(controller, 0, itemExtent: itemExtent, animate: false);
      await tester.pump();
      expect(controller.offset, 0.0);
      controller.dispose();
    });

    testWidgets('clamps to maxScrollExtent for index past the end', (tester) async {
      final controller = ScrollController();
      const itemExtent = 100.0;

      await tester.pumpWidget(
        MaterialApp(
          home: ListView(
            scrollDirection: Axis.horizontal,
            controller: controller,
            children: List.generate(20, (i) => SizedBox(width: itemExtent, height: 100, child: Text('$i'))),
          ),
        ),
      );

      scrollListToIndex(controller, 9999, itemExtent: itemExtent, animate: false);
      await tester.pump();
      expect(controller.offset, controller.position.maxScrollExtent);
      controller.dispose();
    });

    testWidgets('animate=true reaches the same final offset as jumpTo', (tester) async {
      final controller = ScrollController();
      const itemExtent = 100.0;
      const leadingPadding = 12.0;

      await tester.pumpWidget(
        MaterialApp(
          home: ListView(
            scrollDirection: Axis.horizontal,
            controller: controller,
            children: List.generate(20, (i) => SizedBox(width: itemExtent, height: 100, child: Text('$i'))),
          ),
        ),
      );

      const index = 10;
      final viewport = controller.position.viewportDimension;
      final expected = (leadingPadding + index * itemExtent + itemExtent / 2 - viewport / 2).clamp(
        0.0,
        controller.position.maxScrollExtent,
      );

      scrollListToIndex(controller, index, itemExtent: itemExtent);
      // Walk through the 150ms animation.
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      expect(controller.offset, closeTo(expected, 0.5));
      controller.dispose();
    });
  });

  group('scrollKeyedChildToHorizontalCenter', () {
    testWidgets('centers a keyed child using measured layout bounds', (tester) async {
      final controller = ScrollController();
      final itemKey = GlobalKey();
      const viewportWidth = 300.0;
      const widths = [90.0, 120.0, 70.0, 180.0, 110.0, 160.0, 100.0];
      const targetIndex = 4;

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: viewportWidth,
            height: 80,
            child: SingleChildScrollView(
              controller: controller,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < widths.length; i++)
                    SizedBox(key: i == targetIndex ? itemKey : null, width: widths[i], height: 80, child: Text('$i')),
                ],
              ),
            ),
          ),
        ),
      );

      scrollKeyedChildToHorizontalCenter(controller, itemKey, animate: false);
      await tester.pump();

      final leadingWidth = widths.take(targetIndex).fold<double>(0, (sum, width) => sum + width);
      final targetCenter = leadingWidth + (widths[targetIndex] / 2);
      final expected = (targetCenter - (viewportWidth / 2)).clamp(0.0, controller.position.maxScrollExtent);
      expect(controller.offset, closeTo(expected, 0.001));
      controller.dispose();
    });

    testWidgets('does not center a child owned by another controller', (tester) async {
      final selectedController = ScrollController();
      final targetController = ScrollController();
      final targetKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 300,
                  height: 80,
                  child: SingleChildScrollView(
                    controller: selectedController,
                    scrollDirection: Axis.horizontal,
                    child: const SizedBox(width: 1100, height: 80),
                  ),
                ),
                SizedBox(
                  width: 300,
                  height: 80,
                  child: SingleChildScrollView(
                    controller: targetController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const SizedBox(width: 500),
                        SizedBox(key: targetKey, width: 100, height: 80),
                        const SizedBox(width: 500),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      scrollKeyedChildToHorizontalCenter(selectedController, targetKey, animate: false, maxAttempts: 0);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(selectedController.offset, 0);
      expect(targetController.offset, 0);
      selectedController.dispose();
      targetController.dispose();
    });
  });
}
