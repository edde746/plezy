import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/focus/focusable_action_bar.dart';
import 'package:vibe_stream/mixins/grid_focus_node_mixin.dart';
import 'package:vibe_stream/screens/focusable_detail_screen_mixin.dart';
import 'package:vibe_stream/theme/mono_theme.dart';
import 'package:vibe_stream/utils/platform_detector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TvDetectionService.debugSetAppleTVOverride(false);
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  testWidgets('detail scaffold scrolls to top on iOS top safe-area tap', (tester) async {
    var topTargetTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: monoTheme(dark: true).copyWith(platform: TargetPlatform.iOS),
        home: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(top: 25)),
          child: SizedBox(width: 390, height: 844, child: _TestDetailScreen(onTopTargetTap: () => topTargetTaps++)),
        ),
      ),
    );

    await tester.tapAt(const Offset(20, 10));
    await tester.pumpAndSettle();
    expect(topTargetTaps, 0);

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2500));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(0));

    await tester.tapAt(const Offset(20, 10));
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, 0);
  });

  testWidgets('detail scaffold allows native iOS pop gesture when pushed', (tester) async {
    MaterialPageRoute<void>? detailRoute;

    await tester.pumpWidget(
      MaterialApp(
        theme: monoTheme(dark: true).copyWith(platform: TargetPlatform.iOS),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              detailRoute = MaterialPageRoute<void>(builder: (_) => const _TestDetailScreen());
              Navigator.of(context).push(detailRoute!);
            },
            child: const Text('Open detail'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open detail'));
    await tester.pumpAndSettle();

    expect(detailRoute, isNotNull);
    expect(detailRoute!.popGestureEnabled, isTrue);
  });
}

class _TestDetailScreen extends StatefulWidget {
  final VoidCallback? onTopTargetTap;

  const _TestDetailScreen({this.onTopTargetTap});

  @override
  State<_TestDetailScreen> createState() => _TestDetailScreenState();
}

class _TestDetailScreenState extends State<_TestDetailScreen>
    with GridFocusNodeMixin<_TestDetailScreen>, FocusableDetailScreenMixin<_TestDetailScreen> {
  @override
  bool get hasItems => true;

  @override
  List<FocusableAction> getAppBarActions() => const [];

  @override
  void dispose() {
    disposeFocusResources();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildDetailScaffold(
      slivers: [
        SliverToBoxAdapter(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTopTargetTap,
            child: const SizedBox(height: 80, child: Text('Top target')),
          ),
        ),
        SliverList.builder(
          itemCount: 80,
          itemBuilder: (context, index) => SizedBox(height: 80, child: Text('Row $index')),
        ),
      ],
    );
  }
}
