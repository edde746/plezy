import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/navigation/navigation_tabs.dart';
import 'package:plezy/utils/iphone_duo.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/mobile_navigation_rail.dart';
import 'package:plezy/widgets/vertical_bar_shell.dart';

// Geometry measured on the iPhone Duo simulator (iOS 27.1).
const _closedSize = Size(466, 678);
const _closedPadding = EdgeInsets.only(right: 84, bottom: 34);
const _closedStatusRegion = Rect.fromLTWH(382, 0, 84, 170);
const _closedCamera = Rect.fromLTWH(399.67, 29.33, 37, 37);

void main() {
  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
    TvDetectionService.debugReset();
    addTearDown(TvDetectionService.debugReset);
    addTearDown(() => IphoneDuo.instance.state.value = IphoneDuoState.empty);
  });

  group('verticalBarRailInsets', () {
    test('clears the status region at the top of the bar', () {
      final insets = verticalBarRailInsets(
        barStrip: const Rect.fromLTWH(382, 0, 84, 678),
        padding: _closedPadding,
        occlusions: const [_closedCamera, _closedStatusRegion],
      );
      expect(insets, const EdgeInsets.only(top: 170, bottom: 34));
    });

    test('clears a status region rotated to the bottom of the bar', () {
      final insets = verticalBarRailInsets(
        barStrip: const Rect.fromLTWH(594, 0, 84, 466),
        padding: const EdgeInsets.only(right: 84, bottom: 34),
        occlusions: const [Rect.fromLTWH(594, 384, 84, 82)],
      );
      expect(insets, const EdgeInsets.only(bottom: 82));
    });

    test('ignores occlusions outside the bar', () {
      final insets = verticalBarRailInsets(
        barStrip: const Rect.fromLTWH(867, 0, 84, 669),
        padding: const EdgeInsets.only(right: 84, bottom: 20),
        occlusions: const [Rect.fromLTWH(400, 0, 60, 60)],
      );
      expect(insets, const EdgeInsets.only(bottom: 20));
    });
  });

  group('IphoneDuo.verticalBarEdgeOf', () {
    Future<VerticalBarEdge?> edgeFor(WidgetTester tester, EdgeInsets padding, VerticalBarEdge? reported) async {
      IphoneDuo.instance.state.value = IphoneDuoState(verticalBarEdge: reported);
      VerticalBarEdge? edge;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: _closedSize, padding: padding),
          child: IphoneDuoScope(
            child: Builder(
              builder: (context) {
                edge = IphoneDuo.verticalBarEdgeOf(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      return edge;
    }

    testWidgets('needs both the system edge and an inset on that edge', (tester) async {
      expect(await edgeFor(tester, _closedPadding, VerticalBarEdge.right), VerticalBarEdge.right);
      // Split View window away from the bar: the trait reports an edge, the
      // window has no inset there.
      expect(await edgeFor(tester, EdgeInsets.zero, VerticalBarEdge.left), isNull);
      // Every other iPhone.
      expect(await edgeFor(tester, const EdgeInsets.only(top: 62, bottom: 34), null), isNull);
    });
  });

  testWidgets('outer display: tabs sit in the bar, below the status items', (tester) async {
    tester.view.physicalSize = _closedSize;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(right: 84, bottom: 34);
    addTearDown(tester.view.reset);
    IphoneDuo.instance.state.value = const IphoneDuoState(
      verticalBarEdge: VerticalBarEdge.right,
      occlusions: [_closedCamera, _closedStatusRegion],
    );

    final tabs = allNavigationTabs.where((tab) => tab.id != NavigationTabId.settings).toList();
    late double contentRightPadding;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => IphoneDuoScope(child: child!),
        home: Scaffold(
          body: VerticalBarShell(
            edge: VerticalBarEdge.right,
            railBuilder: (context, barWidth) => MobileNavigationRail(
              tabs: tabs,
              selectedTab: NavigationTabId.discover,
              showLabels: true,
              onDestinationSelected: (_) {},
              minWidth: barWidth,
              groupAlignment: 1,
              backgroundColor: Colors.transparent,
            ),
            child: Builder(
              builder: (context) {
                contentRightPadding = MediaQuery.paddingOf(context).right;
                return const ColoredBox(key: ValueKey('content'), color: Colors.blue);
              },
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    final content = tester.getRect(find.byKey(const ValueKey('content')));
    expect(content, const Rect.fromLTWH(0, 0, 382, 678));
    expect(contentRightPadding, 0, reason: 'the rail owns the bar inset');

    final rail = tester.getRect(find.byType(NavigationRail));
    expect(rail.left, 382);
    expect(rail.width, 84);

    final singleLineHeight = tester.getSize(find.text(tabs.first.getLabel())).height;
    for (final tab in tabs) {
      final label = tester.getRect(find.text(tab.getLabel()));
      expect(label.height, singleLineHeight, reason: '${tab.getLabel()} stays on one line');
      expect(label.top, greaterThanOrEqualTo(_closedStatusRegion.bottom), reason: tab.getLabel());
      expect(label.bottom, lessThanOrEqualTo(_closedSize.height - 34), reason: tab.getLabel());
      expect(label.left, greaterThanOrEqualTo(382), reason: tab.getLabel());
    }
  });

  testWidgets('grids get an even column count across a vertical fold', (tester) async {
    IphoneDuo.instance.state.value = const IphoneDuoState(folds: [Rect.fromLTWH(455.5, 0, 40, 669)]);
    late int odd;
    late int even;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(951, 669)),
        child: IphoneDuoScope(
          child: Builder(
            builder: (context) {
              odd = IphoneDuo.foldAwareColumnCount(context, 5);
              even = IphoneDuo.foldAwareColumnCount(context, 4);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(odd, 6);
    expect(even, 4);

    IphoneDuo.instance.state.value = IphoneDuoState.empty;
    await tester.pump();
    expect(odd, 5);
  });
}
