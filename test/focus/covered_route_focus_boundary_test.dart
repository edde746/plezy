import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/covered_route_focus_boundary.dart';

/// The shape from #2034/#2239: a nested navigator whose content sits under a
/// route pushed on the ROOT navigator. Nested-route `isCurrent` stays true
/// there, so a focus self-heal below must be neutralised by the boundary.
class _Harness {
  _Harness(this.tester);

  final WidgetTester tester;
  final rootNavigator = GlobalKey<NavigatorState>();
  final hidden = FocusNode(debugLabel: 'HiddenSidebarItem');
  final tile = FocusNode(debugLabel: 'ContentTile');
  final content = FocusScopeNode(debugLabel: 'ContentScope');
  final cover = FocusNode(debugLabel: 'PickerTile');
  late BuildContext nestedContext;
  bool showTile = true;
  StateSetter? _rebuildNested;

  Future<void> pump({bool boundary = true}) async {
    Widget session = Navigator(
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            nestedContext = context;
            _rebuildNested = setState;
            return Column(
              children: [
                Focus(focusNode: hidden, child: const SizedBox(height: 10, width: 10)),
                FocusScope(
                  node: content,
                  child: showTile
                      ? Focus(focusNode: tile, autofocus: true, child: const SizedBox(height: 10, width: 10))
                      : const SizedBox(height: 10, width: 10),
                ),
              ],
            );
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

  void unmountTile() => _rebuildNested!(() => showTile = false);

  void dispose() {
    hidden.dispose();
    tile.dispose();
    content.dispose();
    cover.dispose();
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
}
