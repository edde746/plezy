import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/screens/settings/async_form_state_mixin.dart';

class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with AsyncFormStateMixin<_Host> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  testWidgets('sequential runAsync calls manage busy/error state', (tester) async {
    await tester.pumpWidget(const _Host());
    final state = tester.state<_HostState>(find.byType(_Host));

    final result = await state.runAsync(() async => 42);
    expect(result, 42);
    expect(state.busy, isFalse);
    expect(state.errorText, isNull);

    final failed = await state.runAsync<int>(() async => throw Exception('boom'), errorMapper: (_) => 'mapped');
    expect(failed, isNull);
    expect(state.errorText, 'mapped');
    expect(state.busy, isFalse);
  });

  testWidgets('overlapping runAsync is refused', (tester) async {
    await tester.pumpWidget(const _Host());
    final state = tester.state<_HostState>(find.byType(_Host));

    final gate = Completer<int>();
    final first = state.runAsync(() => gate.future);
    await tester.pump();
    expect(state.busy, isTrue);

    // Debug builds assert (loud failure during development); release builds
    // refuse the call with null so the busy flag can't be corrupted.
    await expectLater(state.runAsync(() async => 1), throwsAssertionError);
    expect(state.busy, isTrue, reason: 'the in-flight run is unaffected');

    gate.complete(7);
    expect(await first, 7);
    expect(state.busy, isFalse);
  });
}
