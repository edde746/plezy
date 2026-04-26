import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/mixins/library_tab_state.dart';
import 'package:provider/provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';

// NOTE on coverage scope:
// `LibraryTabStateMixin` is a 14-line forwarding mixin:
//   - exposes `library` (abstract) and
//   - resolves the per-library PlexClient via a BuildContext extension.
//
// Coverage:
//   - The mixin returns the same library reference back to subclass code.
//   - `getClientForLibrary` throws when there is no MultiServerProvider with a
//     matching server — the documented "no client available" failure path.
//
// What's NOT covered (and intentionally skipped):
//   - The success path of `getClientForLibrary` requires either a real
//     [PlexClient] inside a [MultiServerManager] (which itself requires a
//     server registry, network, and prefs) or a deep fake of the manager's
//     client cache. Not worth it for a mixin whose only contribution is
//     `context.getPlexClientForLibrary(library)`.

class _Probe extends StatefulWidget {
  const _Probe({required this.library, required this.onState});

  final MediaLibrary library;
  final void Function(_ProbeState state, BuildContext context) onState;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> with LibraryTabStateMixin<_Probe> {
  @override
  MediaLibrary get library => widget.library;

  @override
  Widget build(BuildContext context) {
    // Surface state+context after the first frame so callers can poke the
    // mixin against a live BuildContext.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onState(this, context);
    });
    return const SizedBox.shrink();
  }
}

MediaLibrary _lib({String? serverId, String key = '1'}) =>
    MediaLibrary(id: key, backend: MediaBackend.plex, title: 'Movies', kind: MediaKind.movie, serverId: serverId);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LibraryTabStateMixin', () {
    testWidgets('library getter returns the host state\'s library', (tester) async {
      late _ProbeState state;
      final library = _lib(serverId: 'srv-A', key: 'lib-1');

      await tester.pumpWidget(_Probe(library: library, onState: (s, _) => state = s));
      await tester.pump();

      expect(identical(state.library, library), isTrue);
      expect(state.library.serverId, 'srv-A');
      expect(state.library.id, 'lib-1');
    });

    testWidgets('getClientForLibrary throws when no server matches and no fallback online', (tester) async {
      late _ProbeState state;
      late BuildContext ctx;

      final manager = MultiServerManager();
      final aggregation = DataAggregationService(manager);
      final provider = MultiServerProvider(manager, aggregation);
      // provider.dispose() cascades to manager.dispose() — only register
      // the outer teardown to avoid a double-close on the manager's stream.
      addTearDown(provider.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<MultiServerProvider>.value(
          value: provider,
          child: _Probe(
            library: _lib(serverId: 'srv-missing'),
            onState: (s, c) {
              state = s;
              ctx = c;
            },
          ),
        ),
      );
      await tester.pump();

      // No registered servers means no client and no fallback — the
      // extension throws a localized "no client available" Exception.
      expect(() => state.getClientForLibrary(), throwsA(isA<Exception>()));
      expect(ctx.mounted, isTrue); // sanity: exception came from the lookup, not a torn-down context
    });
  });
}
