import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/dpad_reorder_mixin.dart';

class _ReorderHost extends StatefulWidget {
  const _ReorderHost();

  @override
  State<_ReorderHost> createState() => _ReorderHostState();
}

class _ReorderHostState extends State<_ReorderHost> with DpadReorderListMixin<String, _ReorderHost> {
  List<String> items = ['a', 'b', 'c', 'd'];
  final List<(int, int)> activations = [];
  int confirms = 0;

  @override
  List<String> get reorderItems => items;

  @override
  set reorderItems(List<String> value) => items = value;

  @override
  int get lastReorderColumn => 1;

  @override
  ScrollController? get reorderScrollController => null;

  @override
  void onReorderMoveConfirmed() => confirms++;

  @override
  void onReorderColumnActivated(int column, int index) {
    activations.add((column, index));
    setState(() => items.removeAt(index));
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

const _down = KeyDownEvent(
  physicalKey: PhysicalKeyboardKey.select,
  logicalKey: LogicalKeyboardKey.select,
  timeStamp: Duration.zero,
);
const _repeat = KeyRepeatEvent(
  physicalKey: PhysicalKeyboardKey.select,
  logicalKey: LogicalKeyboardKey.select,
  timeStamp: Duration.zero,
);
const _up = KeyUpEvent(
  physicalKey: PhysicalKeyboardKey.select,
  logicalKey: LogicalKeyboardKey.select,
  timeStamp: Duration.zero,
);

void main() {
  final node = FocusNode();
  tearDownAll(node.dispose);

  Future<_ReorderHostState> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(const _ReorderHost());
    return tester.state<_ReorderHostState>(find.byType(_ReorderHost));
  }

  testWidgets('holding SELECT on an action column activates it once', (tester) async {
    final state = await pumpHost(tester);
    state.focusedColumn = 1;

    expect(state.handleReorderKeyEvent(node, _down), KeyEventResult.handled);
    for (var i = 0; i < 10; i++) {
      expect(state.handleReorderKeyEvent(node, _repeat), KeyEventResult.handled);
    }
    expect(state.handleReorderKeyEvent(node, _up), KeyEventResult.handled);

    expect(state.activations, [(1, 0)]);
    expect(state.items, ['b', 'c', 'd']);
  });

  testWidgets('holding SELECT on a row enters move mode without confirming it', (tester) async {
    final state = await pumpHost(tester);

    state.handleReorderKeyEvent(node, _down);
    for (var i = 0; i < 3; i++) {
      state.handleReorderKeyEvent(node, _repeat);
    }
    state.handleReorderKeyEvent(node, _up);

    expect(state.movingIndex, 0);
    expect(state.confirms, 0);

    state.handleReorderKeyEvent(node, _down);
    expect(state.movingIndex, isNull);
    expect(state.confirms, 1);
  });
}
