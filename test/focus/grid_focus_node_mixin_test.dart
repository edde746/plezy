import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mixins/grid_focus_node_mixin.dart';
import 'package:plezy/mixins/library_tab_focus_mixin.dart';

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
    captured.requestFocus();
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
