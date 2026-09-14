import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focusable_wrapper.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/mixins/grid_focus_node_mixin.dart';
import 'package:plezy/mixins/library_tab_focus_mixin.dart';
import 'package:plezy/utils/focus_utils.dart';

void main() {
  testWidgets('covered item keeps captured restoration across first and nonfirst positions', (tester) async {
    final key = GlobalKey<_GridFocusHarnessState>();
    await tester.pumpWidget(MaterialApp(home: _GridFocusHarness(key: key)));
    final state = key.currentState!;
    state.firstItemFocusNode.requestFocus();
    await tester.pump();
    final captured = FocusManager.instance.primaryFocus!;
    final cover = FocusNode();
    addTearDown(cover.dispose);
    unawaitedDialog(state.context, cover);
    await tester.pumpAndSettle();
    expect(cover.hasPrimaryFocus, isTrue);

    for (final order in [
      <String>['X', 'B', 'A'],
      <String>['B', 'A', 'X'],
      <String>['A', 'X', 'B'],
    ]) {
      state.replace(order);
      await tester.pump();
      expect(cover.hasPrimaryFocus, isTrue, reason: 'a content commit must not focus behind a route');
    }
    Navigator.of(cover.context!).pop();
    await tester.pumpAndSettle();
    FocusUtils.restoreFocusAfterBuild(state, captured);
    await tester.pump();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(state.selected, 'A');

    state.replace(['B', 'A', 'X']);
    await tester.pump();
    state.focusFirstItem();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(state.selected, 'B', reason: 'tab entry resolves the new first item, not the original first node');
  });

  testWidgets('retired captured destinations cannot activate replacement content', (tester) async {
    final key = GlobalKey<_GridFocusHarnessState>();
    await tester.pumpWidget(MaterialApp(home: _GridFocusHarness(key: key)));
    final state = key.currentState!;
    state.firstItemFocusNode.requestFocus();
    await tester.pump();
    final captured = FocusManager.instance.primaryFocus!;
    final cover = FocusNode();
    addTearDown(cover.dispose);
    unawaitedDialog(state.context, cover);
    await tester.pumpAndSettle();
    state.replace(['X', 'B']);
    await tester.pump();
    expect(cover.hasPrimaryFocus, isTrue);
    expect(captured.canRequestFocus, isFalse);
    Navigator.of(cover.context!).pop();
    await tester.pumpAndSettle();
    state.focusFirstItem();
    await tester.pump();
    FocusUtils.restoreFocusAfterBuild(state, captured);
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(state.selected, 'X');
  });

  testWidgets('viewport eviction keeps a mounted remembered item under a cover', (tester) async {
    final key = GlobalKey<_GridFocusHarnessState>();
    await tester.pumpWidget(MaterialApp(home: _GridFocusHarness(key: key)));
    final state = key.currentState!;
    state.firstItemFocusNode.requestFocus();
    await tester.pump();
    final captured = FocusManager.instance.primaryFocus!;
    state.evictDistantFocusNodes(20, keepCount: 1);
    await tester.pump();
    expect(captured.hasPrimaryFocus, isTrue, reason: 'eviction must not disturb a live focused leaf');
    final cover = FocusNode();
    addTearDown(cover.dispose);
    unawaitedDialog(state.context, cover);
    await tester.pumpAndSettle();
    state.evictDistantFocusNodes(20, keepCount: 1);
    await tester.pump();
    expect(cover.hasPrimaryFocus, isTrue);
    Navigator.of(cover.context!).pop();
    await tester.pumpAndSettle();
    captured.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(state.selected, 'A');
  });

  testWidgets('lazy grid reclaims historical attachments and remains traversable after returning', (tester) async {
    final key = GlobalKey<_LazyGridHarnessState>();
    await tester.pumpWidget(
      InputModeTracker(
        child: MaterialApp(home: _LazyGridHarness(key: key)),
      ),
    );
    final state = key.currentState!;
    final historical = state.getGridItemFocusNode(0);

    for (var index = 12; index <= 336; index += 12) {
      state.scrollTo(index);
      await tester.pump();
      state.evictDistantFocusNodes(index);
      await tester.pump();
    }

    expect(state.realizedItems, containsAll(List.generate(336, (index) => index)));
    expect(historical.context, isNotNull, reason: 'Flutter retains the last attachment context');
    expect(historical.context!.mounted, isFalse);
    expect(historical.canRequestFocus, isFalse, reason: 'the detached historical resource was retired');
    expect(state.gridItemFocusNodes.length, lessThanOrEqualTo(200));

    for (var index = 324; index >= 0; index -= 12) {
      state.scrollTo(index);
      await tester.pump();
      state.evictDistantFocusNodes(index);
      await tester.pump();
    }
    final returned = state.getGridItemFocusNode(0);
    expect(returned, isNot(same(historical)));
    expect(returned.rect, tester.getRect(find.byKey(const ValueKey('lazy_0'))));
    expect(state.gridItemFocusNodes.length, lessThanOrEqualTo(200));

    await tester.tap(find.text('Item 0'));
    expect(state.selected, 0);
    returned.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(state.selected, 1, reason: 'keyboard traversal uses the returned item identities');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(state.selected, 5, reason: 'd-pad navigation still reaches the next row');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonA);
    expect(state.selected, 6, reason: 'gamepad selection activates the newly focused item');
  });

  testWidgets('detached remembered destination survives until its content version expires', (tester) async {
    final key = GlobalKey<_LazyGridHarnessState>();
    await tester.pumpWidget(MaterialApp(home: _LazyGridHarness(key: key)));
    final state = key.currentState!;
    final remembered = state.getGridItemFocusNode(0);
    remembered.requestFocus();
    await tester.pump();
    state.toolbar.requestFocus();
    await tester.pump();
    state.scrollTo(300);
    await tester.pump();
    expect(remembered.parent, isNull);
    expect(remembered.context!.mounted, isFalse);
    state.evictDistantFocusNodes(300, keepCount: 4);
    await tester.pump();
    expect(state.getGridItemFocusNode(0), same(remembered));
    expect(state.toolbar.hasPrimaryFocus, isTrue, reason: 'retaining history does not restore focus');

    state.scrollTo(0);
    await tester.pump();
    remembered.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(state.selected, 0);
    state.toolbar.requestFocus();
    await tester.pump();
    state.scrollTo(300);
    await tester.pump();
    state.gridContentVersion++;
    state.evictDistantFocusNodes(300, keepCount: 4);
    await tester.pump();
    expect(remembered.canRequestFocus, isFalse, reason: 'an obsolete remembered version no longer pins the node');
  });

  testWidgets('preattachment destination survives eviction and releases its pin after attaching', (tester) async {
    final key = GlobalKey<_LazyGridHarnessState>();
    await tester.pumpWidget(MaterialApp(home: _LazyGridHarness(key: key)));
    final state = key.currentState!;
    final pending = state.getGridItemFocusNode(500);
    pending.requestFocus();
    state.evictDistantFocusNodes(0, keepCount: 4);
    await tester.pump();
    expect(state.getGridItemFocusNode(500), same(pending));
    state.scrollTo(500);
    await tester.pump();
    await tester.pump();
    expect(pending.hasPrimaryFocus, isTrue, reason: 'Flutter completes the retained preattachment request');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(state.selected, 500);

    state.toolbar.requestFocus();
    await tester.pump();
    state.scrollTo(0);
    await tester.pump();
    state.getGridItemFocusNode(0).requestFocus();
    await tester.pump();
    state.evictDistantFocusNodes(0, keepCount: 4);
    await tester.pump();
    expect(pending.canRequestFocus, isFalse, reason: 'the completed request must not pin detached history forever');
  });

  testWidgets('attachment tokens distinguish detached mounted contexts from unparented live borrowers', (tester) async {
    final key = GlobalKey<_GridFocusHarnessState>();
    await tester.pumpWidget(MaterialApp(home: _GridFocusHarness(key: key)));
    final state = key.currentState!;
    final detached = state.getGridItemFocusNode(300);
    final oldAttachment = detached.attach(state.context);
    oldAttachment.reparent();
    oldAttachment.detach();
    expect(detached.context!.mounted, isTrue);
    expect(oldAttachment.isAttached, isFalse);

    final borrower = state.getGridItemFocusNode(301);
    final liveAttachment = borrower.attach(
      state.context,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
          state.selected = 'borrower';
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );
    expect(borrower.parent, isNull);
    state.evictDistantFocusNodes(0, keepCount: 1);
    await tester.pump();
    expect(detached.canRequestFocus, isFalse);
    expect(liveAttachment.isAttached, isTrue);
    expect(state.getGridItemFocusNode(301), same(borrower));
    liveAttachment.reparent();
    borrower.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(state.selected, 'borrower');
    liveAttachment.detach();
  });

  testWidgets('offstage and globally reparented grid hosts keep their live nodes', (tester) async {
    final key = GlobalKey<_GridFocusHarnessState>();
    var moved = false;
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (_, setState) {
            rebuild = setState;
            return Row(
              children: [
                Expanded(
                  child: Offstage(offstage: true, child: moved ? const SizedBox() : _GridFocusHarness(key: key)),
                ),
                Expanded(child: moved ? _GridFocusHarness(key: key) : const SizedBox()),
              ],
            );
          },
        ),
      ),
    );
    final state = key.currentState!;
    final captured = state.firstItemFocusNode;
    state.evictDistantFocusNodes(500, keepCount: 1);
    await tester.pump();
    expect(state.firstItemFocusNode, same(captured));
    rebuild(() => moved = true);
    await tester.pump();
    state.evictDistantFocusNodes(500, keepCount: 1);
    await tester.pump();
    expect(state.firstItemFocusNode, same(captured));
    captured.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(state.selected, 'A');
    expect(captured.rect, tester.getRect(find.text('A')));
  });
}

void unawaitedDialog(BuildContext context, FocusNode node) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      content: Focus(focusNode: node, autofocus: true, child: const Text('Cover')),
    ),
  );
}

class _GridFocusHarness extends StatefulWidget {
  const _GridFocusHarness({super.key});

  @override
  State<_GridFocusHarness> createState() => _GridFocusHarnessState();
}

class _GridFocusHarnessState extends State<_GridFocusHarness>
    with GridFocusNodeMixin<_GridFocusHarness>, LibraryTabFocusMixin<_GridFocusHarness> {
  List<String> items = ['A', 'B'];
  String? selected;

  @override
  String get focusNodeDebugLabel => 'first';

  @override
  int get itemCount => items.length;

  void replace(List<String> value) {
    setState(() {
      items = value;
      reconcileGridFocusNodes({for (var i = 0; i < items.length; i++) items[i]: i});
    });
  }

  @override
  void dispose() {
    disposeGridFocusNodes();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: FocusScope(
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            Focus(
              key: ValueKey(items[i]),
              focusNode: focusNodeForIndex(i, firstItemFocusNode, prefix: 'item', itemIdentity: items[i]),
              onFocusChange: (value) => trackGridItemFocus(i, value),
              onKeyEvent: (_, event) {
                if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                  selected = items[i];
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Text(items[i]),
            ),
        ],
      ),
    ),
  );
}

class _LazyGridHarness extends StatefulWidget {
  const _LazyGridHarness({super.key});

  @override
  State<_LazyGridHarness> createState() => _LazyGridHarnessState();
}

class _LazyGridHarnessState extends State<_LazyGridHarness> with GridFocusNodeMixin<_LazyGridHarness> {
  final controller = ScrollController();
  final toolbar = FocusNode(debugLabel: 'toolbar');
  final realizedItems = <int>{};
  int? selected;

  void scrollTo(int index) => controller.jumpTo((index ~/ 4) * 60.0);

  @override
  void dispose() {
    controller.dispose();
    toolbar.dispose();
    disposeGridFocusNodes();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Focus(focusNode: toolbar, child: const Text('Toolbar')),
        SizedBox(
          width: 400,
          height: 180,
          child: GridView.builder(
            scrollCacheExtent: ScrollCacheExtent.pixels(0),
            controller: controller,
            addAutomaticKeepAlives: false,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisExtent: 60),
            itemCount: 650,
            itemBuilder: (_, index) {
              realizedItems.add(index);
              return FocusableWrapper(
                key: ValueKey('lazy_$index'),
                focusNode: getGridItemFocusNode(index),
                autoScroll: false,
                disableScale: true,
                onFocusChange: (focused) => trackGridItemFocus(index, focused),
                onSelect: () => selected = index,
                onNavigateDown: () => getGridItemFocusNode(index + 4).requestFocus(),
                onNavigateRight: () => getGridItemFocusNode(index + 1).requestFocus(),
                child: GestureDetector(
                  onTap: () => selected = index,
                  child: Center(child: Text('Item $index')),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
