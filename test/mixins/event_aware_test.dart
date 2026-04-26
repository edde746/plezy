import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mixins/event_aware.dart';
import 'package:plezy/utils/base_notifier.dart';
import 'package:plezy/utils/global_key_utils.dart';
import 'package:plezy/utils/hierarchical_event_mixin.dart';

class _FakeEvent with HierarchicalEventMixin {
  _FakeEvent({required this.serverId, required this.itemId, this.parentChain = const []});

  @override
  final String serverId;

  @override
  final String itemId;

  @override
  final List<String> parentChain;

  @override
  String get globalKey => buildGlobalKey(serverId, itemId);
}

class _FakeNotifier extends BaseNotifier<_FakeEvent> {}

/// Helper to drain the broadcast microtasks before reading received events.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('subscribeToHierarchicalEvents', () {
    late _FakeNotifier notifier;
    late List<_FakeEvent> received;

    setUp(() {
      notifier = _FakeNotifier();
      received = <_FakeEvent>[];
    });

    tearDown(() => notifier.dispose());

    test('delivers events when no filters are set (mounted, no serverId/keys)', () async {
      final sub = subscribeToHierarchicalEvents<_FakeEvent>(
        notifier: notifier,
        mounted: () => true,
        serverId: () => null,
        globalKeys: () => null,
        itemIds: () => null,
        onEvent: received.add,
      );

      final ev = _FakeEvent(serverId: 's1', itemId: '42');
      notifier.notify(ev);
      await _settle();

      expect(received, [ev]);
      await sub.cancel();
    });

    test('drops events when not mounted', () async {
      var mounted = false;
      final sub = subscribeToHierarchicalEvents<_FakeEvent>(
        notifier: notifier,
        mounted: () => mounted,
        serverId: () => null,
        globalKeys: () => null,
        itemIds: () => null,
        onEvent: received.add,
      );

      notifier.notify(_FakeEvent(serverId: 's1', itemId: '42'));
      await _settle();
      expect(received, isEmpty);

      // Once mounted, future events flow.
      mounted = true;
      final ev = _FakeEvent(serverId: 's1', itemId: '99');
      notifier.notify(ev);
      await _settle();
      expect(received, [ev]);

      await sub.cancel();
    });

    test('filters by serverId when provided', () async {
      final sub = subscribeToHierarchicalEvents<_FakeEvent>(
        notifier: notifier,
        mounted: () => true,
        serverId: () => 's1',
        globalKeys: () => null,
        itemIds: () => null,
        onEvent: received.add,
      );

      final keep = _FakeEvent(serverId: 's1', itemId: '1');
      final drop = _FakeEvent(serverId: 's2', itemId: '1');
      notifier.notify(drop);
      notifier.notify(keep);
      await _settle();

      expect(received, [keep]);
      await sub.cancel();
    });

    test('globalKeys filter delivers events matching any global key', () async {
      final keys = {buildGlobalKey('s1', '42'), buildGlobalKey('s1', '7')};
      final sub = subscribeToHierarchicalEvents<_FakeEvent>(
        notifier: notifier,
        mounted: () => true,
        serverId: () => null,
        globalKeys: () => keys,
        itemIds: () => null,
        onEvent: received.add,
      );

      final hit = _FakeEvent(serverId: 's1', itemId: '42');
      final miss = _FakeEvent(serverId: 's1', itemId: '9999');
      notifier.notify(hit);
      notifier.notify(miss);
      await _settle();

      expect(received, [hit]);
      await sub.cancel();
    });

    test('globalKeys filter takes precedence over itemIds', () async {
      // Even though itemIds would match '5', globalKeys path returns early
      // and short-circuits the itemIds check.
      final globalKeys = {buildGlobalKey('s1', '99')};
      final itemIds = {'5'};
      final sub = subscribeToHierarchicalEvents<_FakeEvent>(
        notifier: notifier,
        mounted: () => true,
        serverId: () => null,
        globalKeys: () => globalKeys,
        itemIds: () => itemIds,
        onEvent: received.add,
      );

      // itemId 5 matches the itemIds set but not the globalKeys set.
      notifier.notify(_FakeEvent(serverId: 's1', itemId: '5'));
      await _settle();
      expect(received, isEmpty);

      // Now an event matching the globalKeys set comes through.
      final hit = _FakeEvent(serverId: 's1', itemId: '99');
      notifier.notify(hit);
      await _settle();
      expect(received, [hit]);

      await sub.cancel();
    });

    test('null itemIds delivers all events (when no other filters)', () async {
      final sub = subscribeToHierarchicalEvents<_FakeEvent>(
        notifier: notifier,
        mounted: () => true,
        serverId: () => null,
        globalKeys: () => null,
        itemIds: () => null,
        onEvent: received.add,
      );

      final a = _FakeEvent(serverId: 's1', itemId: '1');
      final b = _FakeEvent(serverId: 's2', itemId: '2');
      notifier.notify(a);
      notifier.notify(b);
      await _settle();

      expect(received, [a, b]);
      await sub.cancel();
    });

    test('empty itemIds delivers nothing', () async {
      final sub = subscribeToHierarchicalEvents<_FakeEvent>(
        notifier: notifier,
        mounted: () => true,
        serverId: () => null,
        globalKeys: () => null,
        itemIds: () => <String>{},
        onEvent: received.add,
      );

      notifier.notify(_FakeEvent(serverId: 's1', itemId: '1'));
      notifier.notify(_FakeEvent(serverId: 's2', itemId: '2'));
      await _settle();

      expect(received, isEmpty);
      await sub.cancel();
    });

    test('itemIds filter delivers direct hits', () async {
      final sub = subscribeToHierarchicalEvents<_FakeEvent>(
        notifier: notifier,
        mounted: () => true,
        serverId: () => null,
        globalKeys: () => null,
        itemIds: () => {'42'},
        onEvent: received.add,
      );

      final hit = _FakeEvent(serverId: 's1', itemId: '42');
      final miss = _FakeEvent(serverId: 's1', itemId: '99');
      notifier.notify(hit);
      notifier.notify(miss);
      await _settle();

      expect(received, [hit]);
      await sub.cancel();
    });

    test('itemIds filter delivers parent-chain hits', () async {
      // Event for an episode whose parent chain includes the show id.
      // The screen tracks the show id, so it should receive the event.
      final sub = subscribeToHierarchicalEvents<_FakeEvent>(
        notifier: notifier,
        mounted: () => true,
        serverId: () => null,
        globalKeys: () => null,
        itemIds: () => {'show123'},
        onEvent: received.add,
      );

      final episode = _FakeEvent(serverId: 's1', itemId: 'episode456', parentChain: ['season789', 'show123']);
      notifier.notify(episode);
      await _settle();

      expect(received, [episode]);
      await sub.cancel();
    });

    test('filters re-evaluate on each event (dynamic getters)', () async {
      var ids = <String>{'1'};
      final sub = subscribeToHierarchicalEvents<_FakeEvent>(
        notifier: notifier,
        mounted: () => true,
        serverId: () => null,
        globalKeys: () => null,
        itemIds: () => ids,
        onEvent: received.add,
      );

      notifier.notify(_FakeEvent(serverId: 's1', itemId: '1'));
      notifier.notify(_FakeEvent(serverId: 's1', itemId: '2'));
      await _settle();
      expect(received.map((e) => e.itemId).toList(), ['1']);

      // Change the filter set; the next event should be evaluated against it.
      ids = {'2'};
      notifier.notify(_FakeEvent(serverId: 's1', itemId: '1'));
      notifier.notify(_FakeEvent(serverId: 's1', itemId: '2'));
      await _settle();
      expect(received.map((e) => e.itemId).toList(), ['1', '2']);

      await sub.cancel();
    });

    test('cancel stops further deliveries', () async {
      final sub = subscribeToHierarchicalEvents<_FakeEvent>(
        notifier: notifier,
        mounted: () => true,
        serverId: () => null,
        globalKeys: () => null,
        itemIds: () => null,
        onEvent: received.add,
      );

      notifier.notify(_FakeEvent(serverId: 's1', itemId: '1'));
      await _settle();
      expect(received, hasLength(1));

      await sub.cancel();
      notifier.notify(_FakeEvent(serverId: 's1', itemId: '2'));
      await _settle();
      expect(received, hasLength(1));
    });

    test('returns a typed StreamSubscription', () {
      final sub = subscribeToHierarchicalEvents<_FakeEvent>(
        notifier: notifier,
        mounted: () => true,
        serverId: () => null,
        globalKeys: () => null,
        itemIds: () => null,
        onEvent: received.add,
      );

      expect(sub, isA<StreamSubscription<_FakeEvent>>());
      sub.cancel();
    });
  });
}
