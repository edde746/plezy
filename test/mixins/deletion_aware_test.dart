import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mixins/deletion_aware.dart';
import 'package:plezy/utils/deletion_notifier.dart';

class _Probe extends StatefulWidget {
  const _Probe({this.onState, this.serverIdOverride, this.globalKeysOverride, required this.itemIdsOverride});

  final void Function(_ProbeState)? onState;
  final String? serverIdOverride;
  final Set<String>? globalKeysOverride;
  final Set<String>? itemIdsOverride;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> with DeletionAware {
  final List<DeletionEvent> events = <DeletionEvent>[];

  String? _serverId;
  Set<String>? _globalKeys;
  Set<String>? _itemIds;

  @override
  String? get deletionServerId => _serverId;

  @override
  Set<String>? get deletionGlobalKeys => _globalKeys;

  @override
  Set<String>? get deletionIds => _itemIds;

  @override
  void onDeletionEvent(DeletionEvent event) {
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

DeletionEvent _ev({
  required String serverId,
  required String itemId,
  List<String> parentChain = const [],
  String mediaType = 'movie',
}) => DeletionEvent(itemId: itemId, serverId: serverId, parentChain: parentChain, mediaType: mediaType);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump(Duration.zero);
}

void main() {
  group('DeletionAware', () {
    testWidgets('receives events for itemIds it tracks', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s, itemIdsOverride: const {'42'}));

      DeletionNotifier().notify(_ev(serverId: 's1', itemId: '42'));
      await _settle(tester);

      expect(state.events, hasLength(1));
      expect(state.events.first.itemId, '42');
    });

    testWidgets('drops events for itemIds outside its set', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s, itemIdsOverride: const {'42'}));

      DeletionNotifier().notify(_ev(serverId: 's1', itemId: '999'));
      await _settle(tester);

      expect(state.events, isEmpty);
    });

    testWidgets('parent-chain hits are delivered (e.g. season deleted invalidates a show)', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s, itemIdsOverride: const {'show123'}));

      DeletionNotifier().notify(
        _ev(serverId: 's1', itemId: 'season789', parentChain: const ['show123'], mediaType: 'season'),
      );
      await _settle(tester);

      expect(state.events, hasLength(1));
      expect(state.events.first.itemId, 'season789');
    });

    testWidgets('serverId override scopes events', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s, serverIdOverride: 's1', itemIdsOverride: const {'42'}));

      DeletionNotifier().notify(_ev(serverId: 's2', itemId: '42'));
      await _settle(tester);
      expect(state.events, isEmpty);

      DeletionNotifier().notify(_ev(serverId: 's1', itemId: '42'));
      await _settle(tester);
      expect(state.events, hasLength(1));
    });

    testWidgets('globalKeys override takes precedence over itemIds', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(
        _Probe(onState: (s) => state = s, globalKeysOverride: const {'s1:99'}, itemIdsOverride: const {'5'}),
      );

      DeletionNotifier().notify(_ev(serverId: 's1', itemId: '5'));
      await _settle(tester);
      expect(state.events, isEmpty);

      DeletionNotifier().notify(_ev(serverId: 's1', itemId: '99'));
      await _settle(tester);
      expect(state.events, hasLength(1));
      expect(state.events.first.itemId, '99');
    });

    testWidgets('empty itemIds delivers nothing', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s, itemIdsOverride: const <String>{}));

      DeletionNotifier().notify(_ev(serverId: 's1', itemId: '1'));
      await _settle(tester);

      expect(state.events, isEmpty);
    });

    testWidgets('cancels its subscription on dispose', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s, itemIdsOverride: const {'42'}));

      DeletionNotifier().notify(_ev(serverId: 's1', itemId: '42'));
      await _settle(tester);
      expect(state.events, hasLength(1));

      await tester.pumpWidget(const SizedBox.shrink());

      DeletionNotifier().notify(_ev(serverId: 's1', itemId: '42'));
      await tester.pump(Duration.zero);

      expect(state.events, hasLength(1));
    });
  });
}
