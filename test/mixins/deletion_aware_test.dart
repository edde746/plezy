import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mixins/deletion_aware.dart';
import 'package:plezy/utils/deletion_notifier.dart';

class _Probe extends StatefulWidget {
  const _Probe({this.onState, this.serverIdOverride, this.globalKeysOverride, required this.ratingKeysOverride});

  final void Function(_ProbeState)? onState;
  final String? serverIdOverride;
  final Set<String>? globalKeysOverride;
  final Set<String>? ratingKeysOverride;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> with DeletionAware {
  final List<DeletionEvent> events = <DeletionEvent>[];

  String? _serverId;
  Set<String>? _globalKeys;
  Set<String>? _ratingKeys;

  @override
  String? get deletionServerId => _serverId;

  @override
  Set<String>? get deletionGlobalKeys => _globalKeys;

  @override
  Set<String>? get deletionRatingKeys => _ratingKeys;

  @override
  void onDeletionEvent(DeletionEvent event) {
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

DeletionEvent _ev({
  required String serverId,
  required String ratingKey,
  List<String> parentChain = const [],
  String mediaType = 'movie',
}) => DeletionEvent(ratingKey: ratingKey, serverId: serverId, parentChain: parentChain, mediaType: mediaType);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump(Duration.zero);
}

void main() {
  group('DeletionAware', () {
    testWidgets('receives events for ratingKeys it tracks', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s, ratingKeysOverride: const {'42'}));

      DeletionNotifier().notify(_ev(serverId: 's1', ratingKey: '42'));
      await _settle(tester);

      expect(state.events, hasLength(1));
      expect(state.events.first.ratingKey, '42');
    });

    testWidgets('drops events for ratingKeys outside its set', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s, ratingKeysOverride: const {'42'}));

      DeletionNotifier().notify(_ev(serverId: 's1', ratingKey: '999'));
      await _settle(tester);

      expect(state.events, isEmpty);
    });

    testWidgets('parent-chain hits are delivered (e.g. season deleted invalidates a show)', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s, ratingKeysOverride: const {'show123'}));

      DeletionNotifier().notify(
        _ev(serverId: 's1', ratingKey: 'season789', parentChain: const ['show123'], mediaType: 'season'),
      );
      await _settle(tester);

      expect(state.events, hasLength(1));
      expect(state.events.first.ratingKey, 'season789');
    });

    testWidgets('serverId override scopes events', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(
        _Probe(onState: (s) => state = s, serverIdOverride: 's1', ratingKeysOverride: const {'42'}),
      );

      DeletionNotifier().notify(_ev(serverId: 's2', ratingKey: '42'));
      await _settle(tester);
      expect(state.events, isEmpty);

      DeletionNotifier().notify(_ev(serverId: 's1', ratingKey: '42'));
      await _settle(tester);
      expect(state.events, hasLength(1));
    });

    testWidgets('globalKeys override takes precedence over ratingKeys', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(
        _Probe(onState: (s) => state = s, globalKeysOverride: const {'s1:99'}, ratingKeysOverride: const {'5'}),
      );

      DeletionNotifier().notify(_ev(serverId: 's1', ratingKey: '5'));
      await _settle(tester);
      expect(state.events, isEmpty);

      DeletionNotifier().notify(_ev(serverId: 's1', ratingKey: '99'));
      await _settle(tester);
      expect(state.events, hasLength(1));
      expect(state.events.first.ratingKey, '99');
    });

    testWidgets('empty ratingKeys delivers nothing', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s, ratingKeysOverride: const <String>{}));

      DeletionNotifier().notify(_ev(serverId: 's1', ratingKey: '1'));
      await _settle(tester);

      expect(state.events, isEmpty);
    });

    testWidgets('cancels its subscription on dispose', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s, ratingKeysOverride: const {'42'}));

      DeletionNotifier().notify(_ev(serverId: 's1', ratingKey: '42'));
      await _settle(tester);
      expect(state.events, hasLength(1));

      await tester.pumpWidget(const SizedBox.shrink());

      DeletionNotifier().notify(_ev(serverId: 's1', ratingKey: '42'));
      await tester.pump(Duration.zero);

      expect(state.events, hasLength(1));
    });
  });
}
