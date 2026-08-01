import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focusable_action_bar.dart';
import 'package:plezy/focus/key_event_utils.dart';
import 'package:plezy/mixins/grid_focus_node_mixin.dart';
import 'package:plezy/screens/focusable_detail_screen_mixin.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/overlay_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TvDetectionService.debugSetAppleTVOverride(false);
    BackKeyCoordinator.clear();
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
    BackKeyCoordinator.clear();
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

  testWidgets('collection surface hosts adaptive sheets and system Back closes the sheet before the route', (
    tester,
  ) async {
    await _pushDetailSurface(tester, surfaceName: 'collection', hasActions: true);

    await tester.tap(find.text('Open collection sheet'));
    await tester.pumpAndSettle();

    final sheet = find.text('collection sheet');
    expect(sheet, findsOneWidget);
    expect(find.ancestor(of: sheet, matching: find.byType(OverlaySheetHost)), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(sheet, findsNothing);
    expect(find.byType(_TestDetailScreen), findsOneWidget);
  });

  testWidgets('actor surface D-pad Back closes its hosted sheet, then actor can pop with no actions', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    await _pushDetailSurface(tester, surfaceName: 'actor', hasActions: false);

    await tester.tap(find.text('Open actor sheet'));
    await tester.pumpAndSettle();

    final sheet = find.text('actor sheet');
    expect(sheet, findsOneWidget);
    expect(find.ancestor(of: sheet, matching: find.byType(OverlaySheetHost)), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.gameButtonB);

    // Android TV can dispatch route Back for the same remote press. Dispatch
    // that duplicate before pumping so the coordinator deterministically
    // associates it with this key-down instead of a later, independent Back.
    await tester.binding.handlePopRoute();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.gameButtonB);
    await tester.pumpAndSettle();

    expect(sheet, findsNothing);
    expect(find.byType(_TestDetailScreen), findsOneWidget);

    // After the key press has settled, a new system Back is independent. With
    // no actor actions to focus, it must pop the route immediately.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(_TestDetailScreen), findsNothing);
    expect(find.text('Open actor detail'), findsOneWidget);
  });

  testWidgets('collection surface system Back focuses its action bar before popping the route', (tester) async {
    await _pushDetailSurface(tester, surfaceName: 'collection', hasActions: true);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(_TestDetailScreen), findsOneWidget);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'ActionBar[0]');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(_TestDetailScreen), findsNothing);
    expect(find.text('Open collection detail'), findsOneWidget);
  });
}

Future<void> _pushDetailSurface(WidgetTester tester, {required String surfaceName, required bool hasActions}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: monoTheme(dark: true).copyWith(platform: TargetPlatform.android),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => _TestDetailScreen(surfaceName: surfaceName, hasActions: hasActions),
              ),
            ),
            child: Text('Open $surfaceName detail'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open $surfaceName detail'));
  await tester.pumpAndSettle();
  expect(find.byType(_TestDetailScreen), findsOneWidget);
}

class _TestDetailScreen extends StatefulWidget {
  final VoidCallback? onTopTargetTap;
  final String surfaceName;
  final bool hasActions;

  const _TestDetailScreen({this.onTopTargetTap, this.surfaceName = 'detail', this.hasActions = false});

  @override
  State<_TestDetailScreen> createState() => _TestDetailScreenState();
}

class _TestDetailScreenState extends State<_TestDetailScreen>
    with GridFocusNodeMixin<_TestDetailScreen>, FocusableDetailScreenMixin<_TestDetailScreen> {
  @override
  bool get hasItems => true;

  @override
  List<FocusableAction> getAppBarActions() => widget.hasActions
      ? [FocusableAction(icon: Icons.more_horiz, tooltip: 'Collection actions', onPressed: () {})]
      : const [];

  @override
  void dispose() {
    disposeFocusResources();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildDetailScaffold(
      slivers: [
        SliverAppBar(title: Text('${widget.surfaceName} detail'), actions: buildFocusableAppBarActions()),
        SliverToBoxAdapter(
          child: Column(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTopTargetTap,
                child: const SizedBox(height: 80, child: Text('Top target')),
              ),
              Builder(
                builder: (sheetContext) => TextButton(
                  onPressed: () async {
                    await OverlaySheetController.showAdaptive<void>(
                      sheetContext,
                      builder: (_) => SizedBox(height: 120, child: Center(child: Text('${widget.surfaceName} sheet'))),
                    );
                  },
                  child: Text('Open ${widget.surfaceName} sheet'),
                ),
              ),
            ],
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
