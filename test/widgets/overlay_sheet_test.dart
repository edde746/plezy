import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  });
}
