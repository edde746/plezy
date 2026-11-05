import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/covered_route_focus_boundary.dart';

/// The shape from #2034/#2239: a nested navigator whose content sits under a
/// route pushed on the ROOT navigator. Nested-route `isCurrent` stays true
/// there, so a focus self-heal below must be neutralised by the boundary.
/// With [innerBoundary] the nested home route carries its own boundary too,
/// as MainScreen does, for detail routes pushed beside it (#2915).
class _Harness {
  _Harness(this.tester);

  final WidgetTester tester;
  final rootNavigator = GlobalKey<NavigatorState>();
  final hidden = FocusNode(debugLabel: 'HiddenSidebarItem');
  final tile = FocusNode(debugLabel: 'ContentTile');
  final secondTile = FocusNode(debugLabel: 'SecondContentTile');
  final content = FocusScopeNode(debugLabel: 'ContentScope');
  final cover = FocusNode(debugLabel: 'PickerTile');
  final sheetItem = FocusNode(debugLabel: 'SheetItem');
  final detail = FocusNode(debugLabel: 'DetailPageItem');
  late BuildContext nestedContext;
  bool showTile = true;
  bool showSheet = false;
  StateSetter? _rebuildNested;

  Future<void> pump({bool boundary = true, bool innerBoundary = false}) async {
    Widget session = Navigator(
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            nestedContext = context;
            _rebuildNested = setState;
            final Widget screen = Column(
              children: [
                Focus(focusNode: hidden, child: const SizedBox(height: 10, width: 10)),
                FocusScope(
                  node: content,
                  child: Column(
                    children: [
                      showTile
                          ? Focus(focusNode: tile, autofocus: true, child: const SizedBox(height: 10, width: 10))
                          : const SizedBox(height: 10, width: 10),
                      Focus(focusNode: secondTile, child: const SizedBox(height: 10, width: 10)),
                    ],
                  ),
                ),
                if (showSheet)
                  FocusScope(
                    debugLabel: 'SheetScope',
                    child: Focus(focusNode: sheetItem, child: const SizedBox(height: 10, width: 10)),
                  ),
              ],
            );
            return innerBoundary ? CoveredRouteFocusBoundary(child: screen) : screen;
          },
        ),
      ),
    );
    if (boundary) session = CoveredRouteFocusBoundary(child: session);
    await tester.pumpWidget(MaterialApp(navigatorKey: rootNavigator, home: session));
    await tester.pump();
    expect(tile.hasPrimaryFocus, isTrue, reason: 'precondition: content tile autofocused');
  }

  Future<void> pushCover() async {
    rootNavigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => Focus(focusNode: cover, autofocus: true, child: const SizedBox.expand()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(cover.hasPrimaryFocus, isTrue, reason: 'precondition: covering route took focus');
  }

  Future<void> popCover() async {
    rootNavigator.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  /// A detail page pushed on the nested navigator, over the home route.
  Future<void> pushDetail() async {
    Navigator.of(nestedContext).push(
      MaterialPageRoute<void>(
        builder: (_) => Focus(focusNode: detail, autofocus: true, child: const SizedBox.expand()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(detail.hasPrimaryFocus, isTrue, reason: 'precondition: detail page took focus');
  }

  Future<void> popDetail() async {
    Navigator.of(nestedContext).pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  void unmountTile() => _rebuildNested!(() => showTile = false);

  void openSheet() => _rebuildNested!(() => showSheet = true);

  void closeSheet() => _rebuildNested!(() => showSheet = false);

  void dispose() {
    hidden.dispose();
    tile.dispose();
    secondTile.dispose();
    content.dispose();
    cover.dispose();
    sheetItem.dispose();
    detail.dispose();
  }
}

void main() {
  testWidgets('without the boundary a nested self-heal steals focus from the root cover', (tester) async {
    final h = _Harness(tester);
    addTearDown(h.dispose);
    await h.pump(boundary: false);
    await h.pushCover();

    expect(ModalRoute.of(h.nestedContext)!.isCurrent, isTrue, reason: 'nested currency lies under a root cover');
    h.hidden.requestFocus();
    await tester.pump();

    expect(h.hidden.hasPrimaryFocus, isTrue);
    expect(h.cover.hasPrimaryFocus, isFalse);
  });

  testWidgets('requestFocus below a covered route is a no-op', (tester) async {
    final h = _Harness(tester);
    addTearDown(h.dispose);
    await h.pump();
    await h.pushCover();

    h.hidden.requestFocus();
    await tester.pump();

    expect(h.hidden.hasPrimaryFocus, isFalse);
    expect(h.cover.hasPrimaryFocus, isTrue);
  });

  testWidgets('focus returns to the leaf that had it once the cover pops', (tester) async {
    final h = _Harness(tester);
    addTearDown(h.dispose);
    await h.pump();
    await h.pushCover();
    h.hidden.requestFocus();
    await tester.pump();

    await h.popCover();

    expect(h.tile.hasPrimaryFocus, isTrue);
  });

  testWidgets('an initial focus request made under the cover lands once it pops (#2817)', (tester) async {
    // A subtree remounted under the cover has no recorded path; its first
    // focus claim is the only target it has, so it is held, not dropped.
    final h = _Harness(tester);
    addTearDown(h.dispose);
    await h.pump();
    await h.pushCover();

    CoveredRouteFocusBoundary.requestInitialFocus(h.nestedContext, h.secondTile);
    await tester.pump();
    expect(h.cover.hasPrimaryFocus, isTrue, reason: 'a held request must not steal the cover');

    await h.popCover();

    expect(h.secondTile.hasPrimaryFocus, isTrue);
  });

  testWidgets('initial focus requests held under the cover replay in request order', (tester) async {
    // Discover's rail claim then MainScreen's content-scope claim: uncovered,
    // the scope request lands on the descendant just focused. Replaying only
    // the last request would land on the scope's older history instead.
    final h = _Harness(tester);
    addTearDown(h.dispose);
    await h.pump();
    await h.pushCover();

    CoveredRouteFocusBoundary.requestInitialFocus(h.nestedContext, h.secondTile);
    CoveredRouteFocusBoundary.requestInitialFocus(h.nestedContext, h.content);
    await h.popCover();

    expect(h.secondTile.hasPrimaryFocus, isTrue);
  });

  testWidgets('a leaf unmounted while covered leaves focus on its scope, not the root scope', (tester) async {
    final h = _Harness(tester);
    addTearDown(h.dispose);
    await h.pump();
    await h.pushCover();

    h.unmountTile();
    await tester.pump();
    expect(h.cover.hasPrimaryFocus, isTrue, reason: 'unmounting below the cover must not disturb it');

    await h.popCover();

    expect(primaryFocus, isNot(same(FocusManager.instance.rootScope)));
    expect(h.content.hasFocus, isTrue);
  });

  testWidgets('focus returns to the opener when the focused sheet unmounts as the cover is pushed (#2699)', (
    tester,
  ) async {
    final h = _Harness(tester);
    addTearDown(h.dispose);
    await h.pump();
    h.openSheet();
    await tester.pump();
    h.sheetItem.requestFocus();
    await tester.pump();
    expect(h.sheetItem.hasPrimaryFocus, isTrue, reason: 'precondition: sheet item focused');

    // A sheet completes its result in the setState that unmounts it, so a
    // cover pushed from that result lands in the same frame, with focus still
    // on the item being torn down.
    h.closeSheet();
    await h.pushCover();
    await h.popCover();

    expect(h.tile.hasPrimaryFocus, isTrue);
  });

  testWidgets('a route pushed on the nested navigator is not treated as a cover', (tester) async {
    final h = _Harness(tester);
    addTearDown(h.dispose);
    await h.pump();
    final above = FocusNode(debugLabel: 'NestedAbove');
    addTearDown(above.dispose);

    Navigator.of(h.nestedContext).push(
      MaterialPageRoute<void>(
        builder: (_) => Focus(focusNode: above, autofocus: true, child: const SizedBox.expand()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(above.hasPrimaryFocus, isTrue);
    // Flutter's own restoration still owns the nested pop.
    Navigator.of(h.nestedContext).pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(h.tile.hasPrimaryFocus, isTrue);
  });

  testWidgets('a self-heal under a screen covered by a sibling route is a no-op (#2915)', (tester) async {
    // MainScreen's offline flip refocused its sidebar while a series page sat
    // on top of it; the remote then drove the hidden sidebar and Back never
    // reached the page.
    final h = _Harness(tester);
    addTearDown(h.dispose);
    await h.pump(innerBoundary: true);
    await h.pushDetail();

    h.hidden.requestFocus();
    await tester.pump();

    expect(h.hidden.hasPrimaryFocus, isFalse);
    expect(h.detail.hasPrimaryFocus, isTrue);
  });

  testWidgets('focus returns to the leaf that had it once the sibling route pops', (tester) async {
    final h = _Harness(tester);
    addTearDown(h.dispose);
    await h.pump(innerBoundary: true);
    h.secondTile.requestFocus();
    await tester.pump();
    await h.pushDetail();
    h.hidden.requestFocus();
    await tester.pump();

    await h.popDetail();

    expect(h.secondTile.hasPrimaryFocus, isTrue);
  });

  testWidgets('an initial focus request passes an uncovered inner boundary to the covered outer one', (tester) async {
    // The #2817 remount under the root picker, with MainScreen's own boundary
    // between the request and the session boundary that is actually covered.
    final h = _Harness(tester);
    addTearDown(h.dispose);
    await h.pump(innerBoundary: true);
    await h.pushCover();

    CoveredRouteFocusBoundary.requestInitialFocus(h.secondTile.context!, h.secondTile);
    await tester.pump();
    expect(h.cover.hasPrimaryFocus, isTrue, reason: 'a held request must not steal the cover');

    await h.popCover();

    expect(h.secondTile.hasPrimaryFocus, isTrue);
  });

  testWidgets('an initial focus request held under a sibling route waits out a root cover too', (tester) async {
    final h = _Harness(tester);
    addTearDown(h.dispose);
    await h.pump(innerBoundary: true);
    await h.pushDetail();
    await h.pushCover();

    // Requested from inside the screen, as TvBrowseRail does: the innermost
    // covered boundary holds it first.
    CoveredRouteFocusBoundary.requestInitialFocus(h.secondTile.context!, h.secondTile);
    // The sibling route leaves first, while the root cover is still up: the
    // replay must not land behind the cover.
    await h.popDetail();
    expect(h.cover.hasPrimaryFocus, isTrue, reason: 'the replay must not steal the root cover');

    await h.popCover();

    expect(h.secondTile.hasPrimaryFocus, isTrue);
  });
}
