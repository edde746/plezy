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
}
