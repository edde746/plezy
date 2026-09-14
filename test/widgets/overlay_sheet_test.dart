import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/key_event_utils.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/bottom_sheet_header.dart';
import 'package:plezy/widgets/bottom_sheet_page_scaffold.dart';
import 'package:plezy/widgets/overlay_sheet.dart';
import 'package:plezy/widgets/video_controls/sheets/sheet_split_columns.dart';

void main() {
  testWidgets('scrollable sheet does not attach to parent primary controller', (tester) async {
    final parentController = ScrollController();
    addTearDown(parentController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: PrimaryScrollController(
          controller: parentController,
          child: OverlaySheetHost(
            child: Scaffold(
              body: CustomScrollView(
                primary: true,
                slivers: [
                  SliverFillRemaining(
                    child: Center(
                      child: Builder(
                        builder: (context) => ElevatedButton(
                          onPressed: () {
                            OverlaySheetController.of(context).show<void>(
                              builder: (_) => ListView.builder(
                                itemCount: 30,
                                itemBuilder: (_, index) => ListTile(title: Text('Item $index')),
                              ),
                            );
                          },
                          child: const Text('Open'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(parentController.positions.length, 1);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(parentController.positions.length, 1);
    expect(find.text('Item 0'), findsOneWidget);
  });

  testWidgets('desktop default constraints scale with window height', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: OverlaySheetHost(
          child: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    OverlaySheetController.of(context).show<void>(
                      builder: (_) => ListView.builder(
                        itemCount: 100,
                        itemBuilder: (_, index) => ListTile(title: Text('Item $index')),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Unbounded list content fills the default constraints: 75% of window
    // height (previously a fixed 400 on desktop) capped at 700 wide.
    final sheetSize = tester.getSize(find.byType(ListView));
    expect(sheetSize.height, 800 * 0.75);
    expect(sheetSize.width, 700);
  });

  testWidgets('a tall desktop window clamps the sheet to the absolute ceiling, a tall phone does not', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    // Pin both gates the ceiling reads, not just the OS one.
    PlatformDetector.debugSetIsDesktopOSOverride(true);
    TvDetectionService.debugSetAppleTVOverride(false);
    addTearDown(() {
      PlatformDetector.debugSetIsDesktopOSOverride(null);
      TvDetectionService.debugSetAppleTVOverride(null);
    });

    // 1440p desktop: 75% would be 1080px, which reads as a wall of list.
    tester.view.physicalSize = const Size(2560, 1440);
    final controller = await _pumpIdleHost(tester);
    unawaited(
      controller.show<void>(
        builder: (_) => const BottomSheetPageScaffold(title: 'Many', child: _FixedRowList(rowCount: 200)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(BottomSheetPageScaffold)).height, 720);

    controller.close();
    await tester.pumpAndSettle();

    // Narrow viewports keep the plain 75% rule: the ceiling is windows-only.
    tester.view.physicalSize = const Size(400, 1200);
    unawaited(
      controller.show<void>(
        builder: (_) => const BottomSheetPageScaffold(title: 'Many', child: _FixedRowList(rowCount: 200)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(BottomSheetPageScaffold)).height, 1200 * 0.75);
  });

  testWidgets('a portrait tablet keeps the full 75% height — the ceiling is for resizable windows', (tester) async {
    // Wide enough for the 700px width cap, but not a window the user can drag
    // taller, so the absolute ceiling must not apply.
    PlatformDetector.debugSetIsDesktopOSOverride(false);
    TvDetectionService.debugSetAppleTVOverride(false);
    addTearDown(() {
      PlatformDetector.debugSetIsDesktopOSOverride(null);
      TvDetectionService.debugSetAppleTVOverride(null);
    });
    tester.view.physicalSize = const Size(1024, 1366);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = await _pumpIdleHost(tester);
    unawaited(
      controller.show<void>(
        builder: (_) => const BottomSheetPageScaffold(title: 'Many', child: _FixedRowList(rowCount: 200)),
      ),
    );
    await tester.pumpAndSettle();

    final size = tester.getSize(find.byType(BottomSheetPageScaffold));
    expect(size.height, 1366 * 0.75);
    expect(size.width, 700, reason: 'the width cap still applies on a wide viewport');
  });

  testWidgets('TV keeps the full 75% height — the ceiling is for resizable windows', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    PlatformDetector.debugSetIsDesktopOSOverride(true);
    addTearDown(() {
      TvDetectionService.debugSetAppleTVOverride(null);
      PlatformDetector.debugSetIsDesktopOSOverride(null);
    });
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = await _pumpIdleHost(tester);
    unawaited(
      controller.show<void>(
        builder: (_) => const BottomSheetPageScaffold(title: 'Many', child: _FixedRowList(rowCount: 200)),
      ),
    );
    await tester.pumpAndSettle();

    // A 10-foot UI wants every row it can get: 810, not the 720 window ceiling.
    expect(tester.getSize(find.byType(BottomSheetPageScaffold)).height, 1080 * 0.75);
  });

  testWidgets('the hostless modal fallback inherits the same sizing rules', (tester) async {
    PlatformDetector.debugSetIsDesktopOSOverride(true);
    TvDetectionService.debugSetAppleTVOverride(false);
    addTearDown(() {
      PlatformDetector.debugSetIsDesktopOSOverride(null);
      TvDetectionService.debugSetAppleTVOverride(null);
    });
    tester.view.physicalSize = const Size(2560, 1440);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: Builder(
            // No OverlaySheetHost anywhere above: showAdaptive must fall back
            // to showModalBottomSheet and still honour the default constraints.
            builder: (context) => ElevatedButton(
              onPressed: () => unawaited(
                OverlaySheetController.showAdaptive<void>(
                  context,
                  isScrollControlled: true,
                  builder: (_) => const BottomSheetPageScaffold(title: 'Many', child: _FixedRowList(rowCount: 200)),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final size = tester.getSize(find.byType(BottomSheetPageScaffold));
    expect(size.height, 720);
    expect(size.width, 700);
  });

  for (final anchor in [Alignment.bottomCenter, Alignment.topCenter]) {
    final isTop = anchor.y < 0;
    final label = isTop ? 'top' : 'bottom';

    testWidgets('a $label-anchored sheet keeps its anchored edge still while it grows', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = await _pumpIdleHost(tester);
      unawaited(
        controller.show<void>(
          alignment: anchor,
          builder: (_) => const BottomSheetPageScaffold(title: 'Small', child: _FixedRowList(rowCount: 2)),
        ),
      );
      await tester.pumpAndSettle();
      final animated = find.descendant(of: find.byType(OverlaySheetHost), matching: find.byType(AnimatedSize));
      final smallHeight = tester.getSize(animated).height;
      // The header is the content row adjacent to the anchored edge for a
      // top-anchored sheet, and the farthest from it for a bottom-anchored one.
      final header = find.byType(BottomSheetHeader);
      final headerTopBefore = tester.getTopLeft(header).dy;

      unawaited(
        controller.push<void>(
          builder: (_) => const BottomSheetPageScaffold(title: 'Big', child: _FixedRowList(rowCount: 6)),
        ),
      );

      // Mid-tween: this is the only point where AnimatedSize's `alignment`
      // is observable. The child is already laid out at its final size, so a
      // wrong alignment shows up as the content sliding against its anchor.
      // The first pump starts the tween; the second advances it.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      final growing = tester.getSize(animated).height;
      expect(growing, greaterThan(smallHeight));
      expect(growing, lessThan(smallHeight + 160));
      if (isTop) {
        expect(tester.getTopLeft(header).dy, headerTopBefore, reason: 'header is pinned to the top anchor');
      } else {
        // Bottom-anchored: the child is laid out at its final height and
        // bottom-pinned, so the header sits at its FINAL y from the first tween
        // frame and holds there. Under a wrong (top) alignment it would instead
        // track the animating height. Only the exact value distinguishes them.
        expect(tester.getTopLeft(header).dy, 800 - (smallHeight + 160));
        expect(tester.getBottomLeft(animated).dy, 800, reason: 'bottom edge stays pinned to the viewport');
      }

      await tester.pumpAndSettle();
      expect(tester.getSize(animated).height, smallHeight + 160);
    });
  }

  testWidgets('popping back to a shorter page eases the sheet down', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = await _pumpIdleHost(tester);
    unawaited(
      controller.show<void>(
        builder: (_) => const BottomSheetPageScaffold(title: 'Small', child: _FixedRowList(rowCount: 2)),
      ),
    );
    await tester.pumpAndSettle();
    final animated = find.descendant(of: find.byType(OverlaySheetHost), matching: find.byType(AnimatedSize));
    final smallHeight = tester.getSize(animated).height;

    unawaited(
      controller.push<void>(
        builder: (_) => const BottomSheetPageScaffold(title: 'Big', child: _FixedRowList(rowCount: 6)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(animated).height, smallHeight + 160);

    controller.pop();
    await tester.pump();
    expect(tester.getSize(animated).height, smallHeight + 160, reason: 'shrink must ease, not jump');
    await tester.pump(const Duration(milliseconds: 90));
    final shrinking = tester.getSize(animated).height;
    expect(shrinking, lessThan(smallHeight + 160));
    expect(shrinking, greaterThan(smallHeight));
    await tester.pumpAndSettle();
    expect(tester.getSize(animated).height, smallHeight);
  });

  testWidgets('a short content-sized sheet still needs a deliberate drag to dismiss', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = await _pumpIdleHost(tester);
    unawaited(
      controller.show<void>(
        showDragHandle: true,
        builder: (_) => const BottomSheetPageScaffold(title: 'Tiny', child: _FixedRowList(rowCount: 2)),
      ),
    );
    await tester.pumpAndSettle();

    // ~145px of content plus a 20px drag handle, so a bare 25%-of-height
    // threshold would be ~41px — barely more than touch slop. The absolute
    // floor is what keeps a stray flick from closing it.
    expect(tester.getSize(find.byType(BottomSheetPageScaffold)).height, lessThan(200));

    // 90px of gesture is ~70px of drag once the recogniser's slop is consumed:
    // past 25% of the sheet, but well short of the floor.
    await _slowDragDown(tester, 90);
    expect(find.byType(BottomSheetPageScaffold), findsOneWidget, reason: '70px of drag must not dismiss');

    await _slowDragDown(tester, 140);
    expect(find.byType(BottomSheetPageScaffold), findsNothing, reason: '140px clears the floor');
  });

  testWidgets('a sheet shorter than the dismiss floor stays dismissible by drag', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = await _pumpIdleHost(tester);
    unawaited(
      controller.show<void>(
        showDragHandle: true,
        builder: (_) => const BottomSheetPageScaffold(title: 'One', child: _FixedRowList(rowCount: 1)),
      ),
    );
    await tester.pumpAndSettle();

    // A one-row menu is shorter than the 96px floor. Left unclamped, the floor
    // would demand a drag longer than the sheet itself, so the only way to
    // dismiss by distance would be to pull it clean off the screen.
    final sheetHeight = tester
        .getSize(find.descendant(of: find.byType(OverlaySheetHost), matching: find.byType(AnimatedSize)))
        .height;
    expect(sheetHeight, lessThan(96 / 0.6), reason: 'the clamp must actually be the binding rule here');

    // Just past 60% of the sheet, still short of the raw 96px floor.
    await _slowDragDown(tester, sheetHeight * 0.6 + 8 + _dragSlop);
    expect(find.byType(BottomSheetPageScaffold), findsNothing, reason: 'clamped floor keeps a short sheet dismissible');
  });

  testWidgets('sheet page shrinks to short content instead of filling the height cap', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpHostedSheet(tester, const BottomSheetPageScaffold(title: 'Tiny', child: _FixedRowList(rowCount: 2)));

    final sheetHeight = tester.getSize(find.byType(BottomSheetPageScaffold)).height;
    final headerHeight = tester.getSize(find.byType(BottomSheetHeader)).height;

    // Exactly header + two 40px rows: no filler between the last row and the
    // bottom of the sheet.
    expect(sheetHeight, headerHeight + 80);
    expect(sheetHeight, lessThan(800 * 0.75));
  });

  testWidgets('sheet page clamps to the height cap once content overflows', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpHostedSheet(tester, const BottomSheetPageScaffold(title: 'Many', child: _FixedRowList(rowCount: 200)));

    expect(tester.getSize(find.byType(BottomSheetPageScaffold)).height, 800 * 0.75);
    // Still scrollable rather than overflowing.
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(find.text('row 0'), findsNothing);
    expect(
      tester.getSize(find.byType(BottomSheetPageScaffold)).height,
      800 * 0.75,
      reason: 'scrolling must not resize the sheet',
    );
  });

  testWidgets('uneven row heights do not make the clamped sheet wobble while scrolling', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // A shrink-wrapping sliver reports an *estimated* max extent extrapolated
    // from the rows laid out so far. That estimate can only move the sheet while
    // it is near the clamp, so this list is deliberately sized to just overflow
    // the 600px cap (11 rows of 40/64/88 = 616px) rather than to swamp it.
    await _pumpHostedSheet(
      tester,
      const BottomSheetPageScaffold(title: 'Uneven', child: _FixedRowList(rowCount: 11, varyHeights: true)),
    );

    for (var step = 0; step < 4; step++) {
      expect(tester.getSize(find.byType(BottomSheetPageScaffold)).height, 800 * 0.75, reason: 'step $step');
      await tester.drag(find.byType(ListView), const Offset(0, -40));
      await tester.pumpAndSettle();
    }
    expect(tester.getSize(find.byType(BottomSheetPageScaffold)).height, 800 * 0.75);
  });

  testWidgets('split columns size to the taller column and stretch the rule to match', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpHostedSheet(
      tester,
      const SheetSplitColumns(start: _FixedRowList(rowCount: 2), end: _FixedRowList(rowCount: 3)),
    );

    // Taller column wins; the hairline rule must not drag the row to the cap.
    expect(tester.getSize(find.byType(SheetSplitColumns)).height, 120);
    final rule = tester.getSize(
      find.descendant(of: find.byType(SheetSplitColumns), matching: find.byType(VerticalDivider)),
    );
    expect(rule, const Size(1, 120));
  });

  testWidgets('replacing an open sheet adopts the new height instead of easing down from the old one', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = await _pumpIdleHost(tester);

    unawaited(
      controller.show<void>(
        builder: (_) => const BottomSheetPageScaffold(title: 'Many', child: _FixedRowList(rowCount: 200)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(AnimatedSize)).height, 800 * 0.75);

    // Replacing without closing keeps the sheet mounted, so only the per-sheet
    // animation key stops the new page from easing down from 600px.
    unawaited(
      controller.show<void>(
        builder: (_) => const BottomSheetPageScaffold(title: 'Tiny', child: _FixedRowList(rowCount: 2)),
      ),
    );
    await tester.pump();

    final headerHeight = tester.getSize(find.byType(BottomSheetHeader)).height;
    expect(tester.getSize(find.byType(AnimatedSize)).height, headerHeight + 80);
  });

  testWidgets('pointer-opened sheet claims focus and handles Back before the screen', (tester) async {
    final screenFocusNode = FocusNode(debugLabel: 'Screen');
    addTearDown(screenFocusNode.dispose);
    var screenBacks = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Focus(
          focusNode: screenFocusNode,
          autofocus: true,
          onKeyEvent: (_, event) {
            if (event.logicalKey == LogicalKeyboardKey.gameButtonB) {
              if (event is KeyUpEvent) screenBacks++;
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: OverlaySheetHost(
            child: Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => OverlaySheetController.of(context).show<void>(
                      builder: (_) => const SizedBox(height: 120, child: Center(child: Text('SHEET'))),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'OverlaySheetScope');
    await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonB);
    await tester.pumpAndSettle();

    expect(find.text('SHEET'), findsNothing);
    expect(screenBacks, 0);
  });

  testWidgets('pushAdaptive opens a root page on an idle host and returns its result', (tester) async {
    final result = ValueNotifier<String>('pending');
    addTearDown(result.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: OverlaySheetHost(
          child: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final value = await OverlaySheetController.pushAdaptive<String>(
                        context,
                        builder: (sheetContext) => SizedBox(
                          height: 120,
                          child: Column(
                            children: [
                              const Text('Adaptive root page'),
                              ElevatedButton(
                                onPressed: () => OverlaySheetController.of(sheetContext).close('root result'),
                                child: const Text('Close adaptive root'),
                              ),
                            ],
                          ),
                        ),
                      );
                      result.value = value ?? 'null';
                    },
                    child: const Text('Push adaptive root'),
                  ),
                  ValueListenableBuilder<String>(
                    valueListenable: result,
                    builder: (_, value, _) => Text('Root result: $value'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Push adaptive root'));
    await tester.pumpAndSettle();

    expect(find.text('Adaptive root page'), findsOneWidget);
    expect(find.text('Root result: pending'), findsOneWidget);

    await tester.tap(find.text('Close adaptive root'));
    await tester.pumpAndSettle();

    expect(find.text('Adaptive root page'), findsNothing);
    expect(find.text('Root result: root result'), findsOneWidget);
  });

  testWidgets('pushAdaptive pushes a nested page on an open host and pop restores the root', (tester) async {
    final nestedResult = ValueNotifier<String>('pending');
    addTearDown(nestedResult.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: OverlaySheetHost(
          child: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    OverlaySheetController.of(context).show<void>(
                      builder: (rootContext) => SizedBox(
                        height: 160,
                        child: Column(
                          children: [
                            const Text('Existing root page'),
                            ElevatedButton(
                              onPressed: () async {
                                final value = await OverlaySheetController.pushAdaptive<String>(
                                  rootContext,
                                  builder: (nestedContext) => SizedBox(
                                    height: 120,
                                    child: Column(
                                      children: [
                                        const Text('Adaptive nested page'),
                                        ElevatedButton(
                                          onPressed: () =>
                                              OverlaySheetController.of(nestedContext).pop('nested result'),
                                          child: const Text('Pop adaptive nested'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                                nestedResult.value = value ?? 'null';
                              },
                              child: const Text('Push adaptive nested'),
                            ),
                            ValueListenableBuilder<String>(
                              valueListenable: nestedResult,
                              builder: (_, value, _) => Text('Nested result: $value'),
                            ),
                            ElevatedButton(
                              onPressed: () => OverlaySheetController.of(rootContext).close(),
                              child: const Text('Close existing root'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: const Text('Open existing root'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open existing root'));
    await tester.pumpAndSettle();
    expect(find.text('Existing root page'), findsOneWidget);

    await tester.tap(find.text('Push adaptive nested'));
    await tester.pumpAndSettle();

    expect(find.text('Adaptive nested page'), findsOneWidget);
    expect(find.text('Existing root page'), findsNothing);

    await tester.tap(find.text('Pop adaptive nested'));
    await tester.pumpAndSettle();

    expect(find.text('Adaptive nested page'), findsNothing);
    expect(find.text('Existing root page'), findsOneWidget);
    expect(find.text('Nested result: nested result'), findsOneWidget);

    await tester.tap(find.text('Close existing root'));
    await tester.pumpAndSettle();
    expect(find.text('Existing root page'), findsNothing);
  });

  group('opt-in canPop / onSystemBack', () {
    // Pushes an OverlaySheetHost route on top of a home route so we can observe
    // whether a simulated system back pops the route. The host's child has an
    // "Open" button that shows a sheet containing "SHEET".
    Future<void> pushHost(WidgetTester tester, {required bool? canPop, VoidCallback? onSystemBack}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => OverlaySheetHost(
                        canPop: canPop,
                        onSystemBack: onSystemBack,
                        child: Scaffold(
                          body: Builder(
                            builder: (sheetContext) => Center(
                              child: ElevatedButton(
                                onPressed: () => OverlaySheetController.of(sheetContext).show<void>(
                                  builder: (_) => const SizedBox(height: 120, child: Center(child: Text('SHEET'))),
                                ),
                                child: const Text('Open'),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Push'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Push'));
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget, reason: 'host route is shown');
    }

    testWidgets('canPop null installs no PopScope (system back pops the route)', (tester) async {
      await pushHost(tester, canPop: null);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsNothing, reason: 'route popped back to home');
      expect(find.text('Push'), findsOneWidget);
    });

    testWidgets('canPop true pops the route natively on system back', (tester) async {
      await pushHost(tester, canPop: true);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsNothing, reason: 'route popped');
    });

    testWidgets('canPop false blocks the pop and runs onSystemBack', (tester) async {
      var backs = 0;
      await pushHost(tester, canPop: false, onSystemBack: () => backs++);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget, reason: 'route not popped');
      expect(backs, 1);
    });

    testWidgets('system back closes an open sheet instead of popping or running onSystemBack', (tester) async {
      var backs = 0;
      await pushHost(tester, canPop: false, onSystemBack: () => backs++);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('SHEET'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('SHEET'), findsNothing, reason: 'sheet closed');
      expect(find.text('Open'), findsOneWidget, reason: 'screen not popped');
      expect(backs, 0, reason: 'onSystemBack not called while a sheet was open');
    });

    testWidgets('system back does not duplicate a handled TV key Back on an open sheet', (tester) async {
      // The dedup is TV-only, so the override has to be on for this to be the
      // TV contract rather than an accidental cross-platform assertion.
      TvDetectionService.debugSetAppleTVOverride(true);
      addTearDown(() => TvDetectionService.debugSetAppleTVOverride(null));
      var backs = 0;
      await pushHost(tester, canPop: false, onSystemBack: () => backs++);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      BackKeyCoordinator.markHandled();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('SHEET'), findsOneWidget);
      expect(backs, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonB);
      await tester.pumpAndSettle();
      expect(find.text('SHEET'), findsNothing);
    });

    testWidgets('touch system back closes the sheet despite an unrelated handled mark', (tester) async {
      // Regression: the handled marker is global, and touch platforms never
      // deliver Back to the sheet's key handler, so there is nothing here to
      // dedup against. Consuming a mark left by any other handler stranded the
      // sheet open with no way to dismiss it.
      var backs = 0;
      await pushHost(tester, canPop: false, onSystemBack: () => backs++);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      BackKeyCoordinator.markHandled();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('SHEET'), findsNothing, reason: 'stale mark must not swallow the close');
      expect(find.text('Open'), findsOneWidget, reason: 'screen not popped');
      expect(backs, 0);
    });

    testWidgets('system back in a later frame is not mistaken for a duplicate TV key', (tester) async {
      // TV-only: the dedup this exercises is skipped on touch platforms, so
      // without the override the pop would never consult the marker and the
      // post-frame expiry would go untested.
      TvDetectionService.debugSetAppleTVOverride(true);
      addTearDown(() => TvDetectionService.debugSetAppleTVOverride(null));
      var backs = 0;
      await pushHost(tester, canPop: false, onSystemBack: () => backs++);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      BackKeyCoordinator.markHandled();
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('SHEET'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
      expect(backs, 0);
    });
  });
}

/// Shrink-wrapping list for the sizing tests: 40px rows by default, or a
/// 40/64/88 cycle when [varyHeights] is set so the sliver's estimated extent
/// keeps changing as rows are laid out.
class _FixedRowList extends StatelessWidget {
  final int rowCount;
  final bool varyHeights;

  const _FixedRowList({required this.rowCount, this.varyHeights = false});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: rowCount,
      itemBuilder: (_, index) => SizedBox(height: varyHeights ? 40 + (index % 3) * 24 : 40, child: Text('row $index')),
    );
  }
}

Future<void> _pumpHostedSheet(WidgetTester tester, Widget content) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: OverlaySheetHost(
        child: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => OverlaySheetController.of(context).show<void>(builder: (_) => content),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

/// Distance the vertical drag recogniser swallows before it starts reporting
/// updates, in 10px steps: two steps to clear `kTouchSlop`.
const _dragSlop = 20.0;

/// Drags the sheet down by [distance] in steps, so only the distance threshold
/// can decide. A single-move `tester.drag` would never emit `onUpdate` past the
/// recogniser's slop, which is why this steps by hand; the fling-velocity
/// escape hatch cannot fire either way, because `TestGesture.moveBy` stamps
/// every pointer event with `Duration.zero`.
Future<void> _slowDragDown(WidgetTester tester, double distance) async {
  final gesture = await tester.startGesture(tester.getCenter(find.byType(BottomSheetHeader)));
  for (var moved = 0.0; moved < distance; moved += 10) {
    await gesture.moveBy(const Offset(0, 10));
    await tester.pump(const Duration(milliseconds: 40));
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

Future<OverlaySheetController> _pumpIdleHost(WidgetTester tester) async {
  late OverlaySheetController controller;
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: OverlaySheetHost(
        child: Builder(
          builder: (context) {
            controller = OverlaySheetController.of(context);
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    ),
  );
  return controller;
}
