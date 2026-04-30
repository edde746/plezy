import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mixins/watch_state_aware.dart';
import 'package:plezy/utils/watch_state_notifier.dart';

class _Probe extends StatefulWidget {
  const _Probe({this.onState, this.serverIdOverride, this.globalKeysOverride, required this.itemIdsOverride});

  final void Function(_ProbeState)? onState;
  final String? serverIdOverride;
  final Set<String>? globalKeysOverride;
  final Set<String>? itemIdsOverride;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> with WatchStateAware {
  final List<WatchStateEvent> events = <WatchStateEvent>[];

  // The mixin reads these getters every event, so storing as fields lets the
  // tests mutate them after initState if needed.
  String? _serverId;
  Set<String>? _globalKeys;
  Set<String>? _itemIds;

  @override
  String? get watchStateServerId => _serverId;

  @override
  Set<String>? get watchedGlobalKeys => _globalKeys;

  @override
  Set<String>? get watchedIds => _itemIds;

  @override
  void onWatchStateChanged(WatchStateEvent event) {
    events.add(event);
  }

  @override
  void initState() {
    _serverId = widget.serverIdOverride;
    _globalKeys = widget.globalKeysOverride;
    _itemIds = widget.itemIdsOverride;
    super.initState();
    widget.onState?.call(this);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

WatchStateEvent _ev({
  required String serverId,
  required String itemId,
  List<String> parentChain = const [],
  WatchStateChangeType type = WatchStateChangeType.watched,
}) =>
    WatchStateEvent(itemId: itemId, serverId: serverId, changeType: type, parentChain: parentChain, mediaType: 'movie');

/// Drain microtasks the broadcast stream uses to deliver events.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump(Duration.zero);
}

void main() {
  group('WatchStateAware', () {
    testWidgets('receives events for itemIds it tracks', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s, itemIdsOverride: const {'42'}));

      final hit = _ev(serverId: 's1', itemId: '42');
      WatchStateNotifier().notify(hit);
      await _settle(tester);

      expect(state.events, hasLength(1));
      expect(state.events.first.itemId, '42');
    });

    testWidgets('drops events for itemIds outside its set', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s, itemIdsOverride: const {'42'}));

      WatchStateNotifier().notify(_ev(serverId: 's1', itemId: '999'));
      await _settle(tester);

      expect(state.events, isEmpty);
    });

    testWidgets('parent-chain hits are delivered', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s, itemIdsOverride: const {'show123'}));

      // Episode whose parent chain contains the show this screen tracks.
      WatchStateNotifier().notify(
        _ev(serverId: 's1', itemId: 'episode456', parentChain: const ['season789', 'show123']),
      );
      await _settle(tester);

      expect(state.events, hasLength(1));
      expect(state.events.first.itemId, 'episode456');
    });

    testWidgets('serverId override scopes events', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s, serverIdOverride: 's1', itemIdsOverride: const {'42'}));

      WatchStateNotifier().notify(_ev(serverId: 's2', itemId: '42'));
      await _settle(tester);
      expect(state.events, isEmpty);

      WatchStateNotifier().notify(_ev(serverId: 's1', itemId: '42'));
      await _settle(tester);
      expect(state.events, hasLength(1));
    });

    testWidgets('globalKeys override takes precedence over itemIds', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(
        _Probe(onState: (s) => state = s, globalKeysOverride: const {'s1:99'}, itemIdsOverride: const {'5'}),
      );

      // itemId 5 matches the itemIds set, but globalKeys is the active filter.
      WatchStateNotifier().notify(_ev(serverId: 's1', itemId: '5'));
      await _settle(tester);
      expect(state.events, isEmpty);

      WatchStateNotifier().notify(_ev(serverId: 's1', itemId: '99'));
      await _settle(tester);
      expect(state.events, hasLength(1));
      expect(state.events.first.itemId, '99');
    });

    testWidgets('empty itemIds delivers nothing', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s, itemIdsOverride: const <String>{}));

      WatchStateNotifier().notify(_ev(serverId: 's1', itemId: '1'));
      WatchStateNotifier().notify(_ev(serverId: 's2', itemId: '2'));
      await _settle(tester);

      expect(state.events, isEmpty);
    });

    testWidgets('disposes its subscription so events stop after unmount', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s, itemIdsOverride: const {'42'}));

      WatchStateNotifier().notify(_ev(serverId: 's1', itemId: '42'));
      await _settle(tester);
      expect(state.events, hasLength(1));

      // Replace the tree to dispose the probe.
      await tester.pumpWidget(const SizedBox.shrink());

      WatchStateNotifier().notify(_ev(serverId: 's1', itemId: '42'));
      await tester.pump(Duration.zero);

      // No second delivery — subscription cancelled.
      expect(state.events, hasLength(1));
    });
  });
}
