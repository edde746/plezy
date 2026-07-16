import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/key_event_utils.dart';
import 'package:plezy/widgets/overlay_sheet.dart';

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

    testWidgets('system back in a later frame is not mistaken for a duplicate TV key', (tester) async {
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
