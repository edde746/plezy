import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/focused_scroll_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TvDetectionService.debugSetAppleTVOverride(false);
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  testWidgets('scrolls to top on the iOS status-bar tap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(top: 25)),
          child: FocusedScrollScaffold(
            title: const Text('Settings'),
            slivers: [
              SliverList.builder(
                itemCount: 40,
                itemBuilder: (context, index) => SizedBox(height: 100, child: Text('Row $index')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    position.jumpTo(1500);
    await tester.pump();
    expect(position.pixels, 1500);

    // The scroll view inherits the route's PrimaryScrollController, which is
    // how the Scaffold finds it when the status-bar channel event arrives.
    tester.simulateStatusBarTap();
    await tester.pumpAndSettle();

    expect(position.pixels, 0);
  });
}
