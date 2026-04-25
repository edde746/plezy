import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mixins/server_bound_media_mixin.dart';
import 'package:plezy/models/plex_metadata.dart';

/// Probe widget exposing the mixin's surface so tests can read its getters
/// and call its helpers against a real BuildContext.
class _Probe extends StatefulWidget {
  const _Probe({required this.metadata, required this.offline, required this.onState});

  final PlexMetadata metadata;
  final bool offline;
  final void Function(_ProbeState state, BuildContext context) onState;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> with ServerBoundMediaMixin<_Probe> {
  @override
  PlexMetadata get serverBoundMetadata => widget.metadata;

  @override
  bool get isServerBoundOffline => widget.offline;

  @override
  Widget build(BuildContext context) {
    // Surface state+context after the first frame settles so callers can
    // exercise the mixin against a live BuildContext.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onState(this, context);
    });
    return const SizedBox.shrink();
  }
}

PlexMetadata _meta({String? serverId, String ratingKey = 'rk1'}) =>
    PlexMetadata(ratingKey: ratingKey, serverId: serverId);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ServerBoundMediaMixin', () {
    testWidgets('serverBoundServerId mirrors metadata.serverId', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(
        _Probe(
          metadata: _meta(serverId: 'srv-A'),
          offline: false,
          onState: (s, _) => state = s,
        ),
      );
      await tester.pump();
      expect(state.serverBoundServerId, 'srv-A');
    });

    testWidgets('serverBoundServerId is null when metadata has no server', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(metadata: _meta(), offline: false, onState: (s, _) => state = s));
      await tester.pump();
      expect(state.serverBoundServerId, isNull);
    });

    testWidgets('isServerBoundOffline reflects the host state override', (tester) async {
      late _ProbeState onState;
      late _ProbeState offState;
      await tester.pumpWidget(
        _Probe(
          metadata: _meta(serverId: 's1'),
          offline: false,
          onState: (s, _) => offState = s,
        ),
      );
      await tester.pump();
      expect(offState.isServerBoundOffline, isFalse);

      await tester.pumpWidget(
        _Probe(
          metadata: _meta(serverId: 's1'),
          offline: true,
          onState: (s, _) => onState = s,
        ),
      );
      await tester.pump();
      expect(onState.isServerBoundOffline, isTrue);
    });

    testWidgets('toServerBoundGlobalKey uses the metadata serverId by default', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(
        _Probe(
          metadata: _meta(serverId: 'srv-A'),
          offline: false,
          onState: (s, _) => state = s,
        ),
      );
      await tester.pump();

      // Format is "serverId:ratingKey".
      expect(state.toServerBoundGlobalKey('rk-99'), 'srv-A:rk-99');
    });

    testWidgets('toServerBoundGlobalKey accepts an explicit serverId override', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(
        _Probe(
          metadata: _meta(serverId: 'srv-A'),
          offline: false,
          onState: (s, _) => state = s,
        ),
      );
      await tester.pump();

      // Explicit serverId takes precedence over the metadata-bound one.
      expect(state.toServerBoundGlobalKey('rk-1', serverId: 'srv-B'), 'srv-B:rk-1');
    });

    testWidgets('toServerBoundGlobalKey falls back to empty serverId when metadata has none', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(metadata: _meta(), offline: false, onState: (s, _) => state = s));
      await tester.pump();

      // Empty server prefix is the documented fallback for server-less metadata.
      expect(state.toServerBoundGlobalKey('rk-1'), ':rk-1');
    });

    testWidgets('getServerBoundClient returns null in offline mode regardless of providers', (tester) async {
      late _ProbeState state;
      late BuildContext ctx;
      await tester.pumpWidget(
        _Probe(
          metadata: _meta(serverId: 'srv-A'),
          offline: true,
          onState: (s, c) {
            state = s;
            ctx = c;
          },
        ),
      );
      await tester.pump();

      // The provider extension short-circuits to null when isOffline is true,
      // so no MultiServerProvider is required to exercise this branch.
      expect(state.getServerBoundClient(ctx), isNull);
    });
  });
}
