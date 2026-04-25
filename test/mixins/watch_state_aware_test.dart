import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mixins/watch_state_aware.dart';
import 'package:plezy/utils/watch_state_notifier.dart';

class _Probe extends StatefulWidget {
  const _Probe({this.onState, this.serverIdOverride, this.globalKeysOverride, required this.ratingKeysOverride});

  final void Function(_ProbeState)? onState;
  final String? serverIdOverride;
  final Set<String>? globalKeysOverride;
  final Set<String>? ratingKeysOverride;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> with WatchStateAware {
  final List<WatchStateEvent> events = <WatchStateEvent>[];

  // The mixin reads these getters every event, so storing as fields lets the
  // tests mutate them after initState if needed.
  String? _serverId;
  Set<String>? _globalKeys;
  Set<String>? _ratingKeys;

  @override
  String? get watchStateServerId => _serverId;

  @override
  Set<String>? get watchedGlobalKeys => _globalKeys;

  @override
  Set<String>? get watchedRatingKeys => _ratingKeys;

  @override
  void onWatchStateChanged(WatchStateEvent event) {
    events.add(event);
  }

  @override
  void initState() {
    _serverId = widget.serverIdOverride;
    _globalKeys = widget.globalKeysOverride;
    _ratingKeys = widget.ratingKeysOverride;
    super.initState();
    widget.onState?.call(this);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

WatchStateEvent _ev({
  required String serverId,
  required String ratingKey,
  List<String> parentChain = const [],
  WatchStateChangeType type = WatchStateChangeType.watched,
}) => WatchStateEvent(
  ratingKey: ratingKey,
  serverId: serverId,
  changeType: type,
  parentChain: parentChain,
  mediaType: 'movie',
);

/// Drain microtasks the broadcast stream uses to deliver events.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump(Duration.zero);
}

void main() {
  group('WatchStateAware', () {
    testWidgets('receives events for ratingKeys it tracks', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s, ratingKeysOverride: const {'42'}));

      final hit = _ev(serverId: 's1', ratingKey: '42');
      WatchStateNotifier().notify(hit);
      await _settle(tester);

      expect(state.events, hasLength(1));
      expect(state.events.first.ratingKey, '42');
    });

    testWidgets('drops events for ratingKeys outside its set', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s, ratingKeysOverride: const {'42'}));

      WatchStateNotifier().notify(_ev(serverId: 's1', ratingKey: '999'));
      await _settle(tester);

      expect(state.events, isEmpty);
    });

    testWidgets('parent-chain hits are delivered', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s, ratingKeysOverride: const {'show123'}));

      // Episode whose parent chain contains the show this screen tracks.
      WatchStateNotifier().notify(
        _ev(serverId: 's1', ratingKey: 'episode456', parentChain: const ['season789', 'show123']),
      );
      await _settle(tester);

      expect(state.events, hasLength(1));
      expect(state.events.first.ratingKey, 'episode456');
    });

    testWidgets('serverId override scopes events', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(
        _Probe(onState: (s) => state = s, serverIdOverride: 's1', ratingKeysOverride: const {'42'}),
      );

      WatchStateNotifier().notify(_ev(serverId: 's2', ratingKey: '42'));
      await _settle(tester);
      expect(state.events, isEmpty);

      WatchStateNotifier().notify(_ev(serverId: 's1', ratingKey: '42'));
      await _settle(tester);
      expect(state.events, hasLength(1));
    });

    testWidgets('globalKeys override takes precedence over ratingKeys', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(
        _Probe(onState: (s) => state = s, globalKeysOverride: const {'s1:99'}, ratingKeysOverride: const {'5'}),
      );

      // ratingKey 5 matches the ratingKeys set, but globalKeys is the active filter.
      WatchStateNotifier().notify(_ev(serverId: 's1', ratingKey: '5'));
      await _settle(tester);
      expect(state.events, isEmpty);

      WatchStateNotifier().notify(_ev(serverId: 's1', ratingKey: '99'));
      await _settle(tester);
      expect(state.events, hasLength(1));
      expect(state.events.first.ratingKey, '99');
    });

    testWidgets('empty ratingKeys delivers nothing', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s, ratingKeysOverride: const <String>{}));

      WatchStateNotifier().notify(_ev(serverId: 's1', ratingKey: '1'));
      WatchStateNotifier().notify(_ev(serverId: 's2', ratingKey: '2'));
      await _settle(tester);

      expect(state.events, isEmpty);
    });

    testWidgets('disposes its subscription so events stop after unmount', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s, ratingKeysOverride: const {'42'}));

      WatchStateNotifier().notify(_ev(serverId: 's1', ratingKey: '42'));
      await _settle(tester);
      expect(state.events, hasLength(1));

      // Replace the tree to dispose the probe.
      await tester.pumpWidget(const SizedBox.shrink());

      WatchStateNotifier().notify(_ev(serverId: 's1', ratingKey: '42'));
      await tester.pump(Duration.zero);

      // No second delivery — subscription cancelled.
      expect(state.events, hasLength(1));
    });
  });
}
