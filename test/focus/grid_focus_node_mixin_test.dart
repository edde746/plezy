import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mixins/grid_focus_node_mixin.dart';

void main() {
  testWidgets('focused distant nodes retain ownership until a later eviction', (tester) async {
    final key = GlobalKey<_GridFocusHarnessState>();

    await tester.pumpWidget(MaterialApp(home: _GridFocusHarness(key: key)));
    final state = key.currentState!;
    final retained = state.getGridItemFocusNode(0);
    state.getGridItemFocusNode(10);
    final center = state.getGridItemFocusNode(20);
    state.refresh();
    await tester.pump();

    retained.requestFocus();
    await tester.pump();
    expect(retained.hasFocus, isTrue);

    state.evictDistantFocusNodes(20, keepCount: 1);

    expect(state.gridItemFocusNodes[0], same(retained));
    expect(state.gridItemFocusNodes.containsKey(10), isFalse);
    expect(state.getGridItemFocusNode(0), same(retained));
    state.refresh();
    await tester.pump();

    center.requestFocus();
    await tester.pump();
    expect(retained.hasFocus, isFalse);

    state.evictDistantFocusNodes(20, keepCount: 1);

    expect(state.gridItemFocusNodes.containsKey(0), isFalse);
    expect(state.gridItemFocusNodes[20], same(center));
    state.refresh();
    await tester.pump();
  });
}

class _GridFocusHarness extends StatefulWidget {
  const _GridFocusHarness({super.key});

  @override
  State<_GridFocusHarness> createState() => _GridFocusHarnessState();
}

class _GridFocusHarnessState extends State<_GridFocusHarness> with GridFocusNodeMixin<_GridFocusHarness> {
  void refresh() => setState(() {});
  @override
  void dispose() {
    disposeGridFocusNodes();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final node in gridItemFocusNodes.values)
        Focus(focusNode: node, child: const SizedBox(width: 10, height: 10)),
    ],
  );
}
