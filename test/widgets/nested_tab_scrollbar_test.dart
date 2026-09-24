import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/widgets/nested_tab_scrollbar.dart';

const _rowHeight = 50.0;

/// A kept-alive tab body shaped like the library tabs: an overlap injector
/// plus a long list, attached to the NestedScrollView's shared inner
/// controller.
class _Tab extends StatefulWidget {
  const _Tab({required this.label, required this.rightInset, required this.onChildPadding});

  final String label;
  final double rightInset;
  final ValueChanged<EdgeInsets> onChildPadding;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return NestedTabScrollbar(
      rightInset: widget.rightInset,
      child: CustomScrollView(
        slivers: [
          SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
          SliverList.builder(
            itemCount: 200,
            itemBuilder: (context, index) {
              widget.onChildPadding(MediaQuery.paddingOf(context));
              return SizedBox(height: _rowHeight, child: Text('${widget.label} $index'));
            },
          ),
        ],
      ),
    );
  }
}

class _Harness {
  _Harness(this.tester, this.tabs);

  final WidgetTester tester;
  final TabController tabs;
  EdgeInsets? childPadding;

  Finder _tab(String label) => find.byWidgetPredicate((w) => w is _Tab && w.label == label, skipOffstage: false);

  ScrollPosition position(String label) => tester
      .state<ScrollableState>(find.descendant(of: _tab(label), matching: find.byType(Scrollable), skipOffstage: false))
      .position;

  Future<void> wheel(double dy) async {
    await tester.sendEventToBinding(PointerScrollEvent(position: const Offset(300, 300), scrollDelta: Offset(0, dy)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  /// Global centre of the visible scrollbar thumb for [label], or null when no
  /// thumb is drawn.
  Offset? thumbCenter(String label) {
    final bars = find.descendant(
      of: _tab(label),
      matching: find.byWidgetPredicate((w) => w is RawScrollbar),
      skipOffstage: false,
    );
    if (bars.evaluate().isEmpty) return null;
    final paint = find.descendant(of: bars.first, matching: find.byType(CustomPaint), skipOffstage: false).first;
    final painter = tester.widget<CustomPaint>(paint).foregroundPainter! as ScrollbarPainter;
    final box = tester.renderObject<RenderBox>(paint);
    final hits = <Offset>[];
    for (var y = 0.0; y < box.size.height; y++) {
      for (var x = box.size.width - 40; x < box.size.width; x++) {
        final local = Offset(x, y);
        if (painter.hitTestOnlyThumbInteractive(local, PointerDeviceKind.mouse)) hits.add(local);
      }
    }
    if (hits.isEmpty) return null;
    final left = hits.map((o) => o.dx).reduce((a, b) => a < b ? a : b);
    final right = hits.map((o) => o.dx).reduce((a, b) => a > b ? a : b);
    final top = hits.map((o) => o.dy).reduce((a, b) => a < b ? a : b);
    final bottom = hits.map((o) => o.dy).reduce((a, b) => a > b ? a : b);
    return box.localToGlobal(Offset((left + right) / 2, (top + bottom) / 2));
  }
}

Future<_Harness> _pumpTabs(WidgetTester tester, {double rightInset = 0}) async {
  final tabs = TabController(length: 2, vsync: tester);
  addTearDown(tabs.dispose);
  final harness = _Harness(tester, tabs);
  void record(EdgeInsets padding) => harness.childPadding = padding;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          // The libraries screen turns behavior scrollbars off for its body.
          builder: (context) => ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: NestedScrollView(
              floatHeaderSlivers: true,
              headerSliverBuilder: (context, _) => [
                SliverOverlapAbsorber(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  sliver: const SliverAppBar(title: Text('Library'), floating: true, snap: true),
                ),
              ],
              body: TabBarView(
                controller: tabs,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Tab(label: 'A', rightInset: rightInset, onChildPadding: record),
                  _Tab(label: 'B', rightInset: rightInset, onChildPadding: record),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return harness;
}

void main() {
  testWidgets('a second kept-alive tab gets a thumb that drags its own position', (tester) async {
    final harness = await _pumpTabs(tester);
    await harness.wheel(600);
    expect(harness.thumbCenter('A'), isNotNull);

    // Tab A stays alive, so the shared inner controller now holds two
    // positions — the state that broke the behavior-built scrollbar.
    harness.tabs.index = 1;
    await tester.pumpAndSettle();
    await harness.wheel(600);

    final thumb = harness.thumbCenter('B');
    expect(thumb, isNotNull);
    final before = harness.position('B').pixels;
    final drag = await tester.startGesture(thumb!, kind: PointerDeviceKind.mouse);
    await tester.pump();
    await drag.moveBy(const Offset(0, 150));
    await tester.pump();
    await drag.up();
    await tester.pumpAndSettle();

    // A thumb drag maps track distance onto the whole list; a content drag
    // the same distance would scroll back up instead.
    expect(harness.position('B').pixels, greaterThan(before + 1000));
  }, variant: TargetPlatformVariant.desktop());

  testWidgets('rightInset keeps the thumb clear of an overlaid edge control without insetting the content', (
    tester,
  ) async {
    const inset = 20.0;
    final harness = await _pumpTabs(tester, rightInset: inset);
    await harness.wheel(600);

    final width = tester.getSize(find.byType(TabBarView)).width;
    final thumb = harness.thumbCenter('A');
    expect(thumb, isNotNull);
    expect(thumb!.dx, lessThan(width - inset));
    expect(thumb.dx, greaterThan(width - inset - 16));
    expect(harness.childPadding?.right, 0);
  }, variant: TargetPlatformVariant.desktop());

  testWidgets('the scrollbar follows a position the scrollable replaces', (tester) async {
    addTearDown(tester.view.reset);
    final harness = await _pumpTabs(tester);
    await harness.wheel(600);
    final original = harness.position('A');

    // Moving the window to a display with another pixel ratio makes the
    // Scrollable replace its position; the logical size stays the same.
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(1600, 1200);
    await tester.pumpAndSettle();
    expect(identical(harness.position('A'), original), isFalse);

    await harness.wheel(2400);
    final before = harness.position('A').pixels;
    final thumb = harness.thumbCenter('A');
    expect(thumb, isNotNull);

    // Paging from the track moves relative to the live offset, not to the
    // offset the replaced position was frozen at.
    await tester.tapAt(Offset(thumb!.dx, 560), kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    expect(harness.position('A').pixels, greaterThan(before));
  }, variant: TargetPlatformVariant.desktop());
}
