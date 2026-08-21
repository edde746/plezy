import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/coalesced_load_coordinator.dart';

void main() {
  test('full requests share one drain and schedule one trailing pass', () async {
    final gates = [Completer<void>(), Completer<void>()];
    var fullCalls = 0;
    final coordinator = CoalescedLoadCoordinator<String>(
      onFull: () async {
        final gate = gates[fullCalls++];
        await gate.future;
      },
      onDelta: (_) async {},
    );

    final first = coordinator.requestFull();
    final second = coordinator.requestFull();
    final third = coordinator.requestFull();

    expect(identical(first, second), isTrue);
    expect(identical(first, third), isTrue);
    expect(fullCalls, 1);

    gates.first.complete();
    await Future<void>.delayed(Duration.zero);
    expect(fullCalls, 2);

    gates.last.complete();
    await first;
    expect(fullCalls, 2);
  });

  test('delta requests union behind the active pass', () async {
    final gate = Completer<void>();
    final passes = <Set<String>>[];
    final coordinator = CoalescedLoadCoordinator<String>(
      onFull: () async {},
      onDelta: (values) async {
        passes.add(values);
        if (passes.length == 1) await gate.future;
      },
    );

    final drain = coordinator.requestDelta({'a'});
    unawaited(coordinator.requestDelta({'b'}));
    unawaited(coordinator.requestDelta({'b', 'c'}));
    expect(passes, [
      {'a'},
    ]);

    gate.complete();
    await drain;
    expect(passes, [
      {'a'},
      {'b', 'c'},
    ]);
  });

  test('queued full takes priority and supersedes queued deltas', () async {
    final gate = Completer<void>();
    final passes = <Object>[];
    final coordinator = CoalescedLoadCoordinator<String>(
      onFull: () async => passes.add('full'),
      onDelta: (values) async {
        passes.add(values);
        if (passes.length == 1) await gate.future;
      },
    );

    final drain = coordinator.requestDelta({'a'});
    unawaited(coordinator.requestDelta({'b'}));
    unawaited(coordinator.requestFull());
    gate.complete();
    await drain;

    expect(passes, [
      {'a'},
      'full',
    ]);
  });

  test('dispose cancels trailing and future requests', () async {
    final gate = Completer<void>();
    var fullCalls = 0;
    final coordinator = CoalescedLoadCoordinator<String>(
      onFull: () async {
        fullCalls++;
        await gate.future;
      },
      onDelta: (_) async {},
    );

    final drain = coordinator.requestFull();
    unawaited(coordinator.requestFull());
    coordinator.dispose();
    gate.complete();
    await drain;
    await coordinator.requestFull();
    await coordinator.requestDelta({'a'});

    expect(fullCalls, 1);
  });

  test('clearPending discards trailing work but remains reusable', () async {
    final gate = Completer<void>();
    var fullCalls = 0;
    final coordinator = CoalescedLoadCoordinator<String>(
      onFull: () async {
        fullCalls++;
        if (fullCalls == 1) await gate.future;
      },
      onDelta: (_) async {},
    );

    final drain = coordinator.requestFull();
    unawaited(coordinator.requestFull());
    coordinator.clearPending();
    gate.complete();
    await drain;
    expect(fullCalls, 1);

    await coordinator.requestFull();
    expect(fullCalls, 2);
  });
}
