import 'dart:async';
import 'package:plezy/media/ids.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/providers/libraries_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/storage_service.dart';

import '../test_helpers/prefs.dart';

MediaLibrary _lib(String key, {String type = 'movie', ServerId? serverId, String title = 'L'}) => MediaLibrary(
  id: key,
  backend: MediaBackend.plex,
  title: title,
  kind: MediaKind.fromString(type),
  serverId: serverId,
);

MediaLibrary _serverLib(ServerId serverId, String id, String title) =>
    MediaLibrary(id: id, backend: MediaBackend.plex, title: title, kind: MediaKind.movie, serverId: serverId);

/// Minimal [MediaServerClient] returning canned libraries; only the surface the
/// aggregation service touches is implemented. An optional [gate] lets a test
/// hold `fetchLibraries` open to exercise the mid-load race; setting [error]
/// makes `fetchLibraries` throw, simulating a (possibly transient) failure.
class _FakeClient implements MediaServerClient {
  _FakeClient({required this.serverId, this.libraries = const [], this.gate, this.errorForCall});

  @override
  final ServerId serverId;
  @override
  final String serverName = 'Server';

  final List<MediaLibrary> libraries;
  final Future<void>? gate;
  final Object? Function(int call)? errorForCall;

  /// When non-null, [fetchLibraries] throws this instead of returning. Mutable
  /// so a test can fail a fetch once and then let it recover.
  Object? error;

  int fetchLibrariesCalls = 0;

  @override
  Future<List<MediaLibrary>> fetchLibraries() async {
    fetchLibrariesCalls++;
    final pending = gate;
    if (pending != null) await pending;
    final fetchError = errorForCall?.call(fetchLibrariesCalls) ?? error;
    if (fetchError != null) throw fetchError;
    return libraries;
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(resetSharedPreferencesForTest);

  group('LibrariesProvider', () {
    test('starts with initial empty state', () {
      final p = LibrariesProvider();
      expect(p.libraries, isEmpty);
      expect(p.hasLibraries, isFalse);
      expect(p.isLoading, isFalse);
      expect(p.hasLoaded, isFalse);
      expect(p.loadState, LibrariesLoadState.initial);
      expect(p.errorMessage, isNull);
      p.dispose();
    });

    test('loadLibraries before initialize is a no-op', () async {
      final p = LibrariesProvider();
      var notified = 0;
      p.addListener(() => notified++);

      await p.loadLibraries();

      // Without a DataAggregationService the load short-circuits with no
      // state transition and no listener notification.
      expect(p.loadState, LibrariesLoadState.initial);
      expect(p.libraries, isEmpty);
      expect(notified, 0);

      p.dispose();
    });

    test('refresh before initialize is a no-op', () async {
      final p = LibrariesProvider();
      var notified = 0;
      p.addListener(() => notified++);

      await p.refresh();
      expect(p.loadState, LibrariesLoadState.initial);
      expect(notified, 0);

      p.dispose();
    });

    test('updateLibraryOrder updates list, notifies, and persists order', () async {
      final p = LibrariesProvider();
      var notified = 0;
      p.addListener(() => notified++);

      final libs = [
        _lib('1', serverId: ServerId('srv'), title: 'A'),
        _lib('2', serverId: ServerId('srv'), title: 'B'),
        _lib('3', serverId: ServerId('srv'), title: 'C'),
      ];

      await p.updateLibraryOrder(libs);
      expect(p.libraries.length, 3);
      expect(p.libraries.map((l) => l.title), ['A', 'B', 'C']);
      expect(notified, 1);

      // Persisted to storage as the list of globalKeys.
      final storage = await StorageService.getInstance();
      expect(storage.getLibraryOrder(), equals(libs.map((l) => l.globalKey).toList()));

      p.dispose();
    });

    test('libraries getter returns an unmodifiable list', () async {
      final p = LibrariesProvider();
      await p.updateLibraryOrder([_lib('1', serverId: ServerId('srv'))]);
      expect(() => p.libraries.add(_lib('mutated')), throwsUnsupportedError);
      p.dispose();
    });

    test('clear resets state to initial and notifies', () async {
      final p = LibrariesProvider();
      await p.updateLibraryOrder([_lib('1', serverId: ServerId('srv')), _lib('2', serverId: ServerId('srv'))]);
      expect(p.libraries, hasLength(2));

      var notified = 0;
      p.addListener(() => notified++);

      p.clear();
      expect(p.libraries, isEmpty);
      expect(p.hasLibraries, isFalse);
      expect(p.loadState, LibrariesLoadState.initial);
      expect(p.errorMessage, isNull);
      expect(notified, 1);

      p.dispose();
    });

    test('mutating methods after dispose are no-ops', () async {
      final p = LibrariesProvider();
      p.dispose();
      p.clear();
      await p.updateLibraryOrder([_lib('1', serverId: ServerId('srv'))]);

      expect(p.libraries, isEmpty);
      final storage = await StorageService.getInstance();
      expect(storage.getLibraryOrder(), isNull);
    });
  });

  group('LibrariesProvider.syncToOnlineServers', () {
    test('loads when a server first comes online', () async {
      final manager = MultiServerManager();
      final clientA = _FakeClient(serverId: ServerId('A'), libraries: [_serverLib(ServerId('A'), '1', 'Movies A')]);
      manager.debugRegisterClientForTesting(clientA);
      final p = LibrariesProvider()..initialize(DataAggregationService(manager));

      await p.syncToOnlineServers({'A'});

      expect(p.hasLoaded, isTrue);
      expect(p.libraries.map((l) => l.title), ['Movies A']);
      expect(clientA.fetchLibrariesCalls, 1);

      p.dispose();
      manager.dispose();
    });

    test('does not reload when the online set is unchanged', () async {
      final manager = MultiServerManager();
      final clientA = _FakeClient(serverId: ServerId('A'), libraries: [_serverLib(ServerId('A'), '1', 'Movies A')]);
      manager.debugRegisterClientForTesting(clientA);
      final p = LibrariesProvider()..initialize(DataAggregationService(manager));

      await p.syncToOnlineServers({'A'});
      await p.syncToOnlineServers({'A'}); // already covered → no-op

      expect(clientA.fetchLibrariesCalls, 1);

      p.dispose();
      manager.dispose();
    });

    test('delta-loads only a server that connects after the first load', () async {
      // A server binding in a later wave (borrowed connection, or a slow
      // server reconnecting after timing out) must surface without a profile
      // re-switch — and without refetching the servers already loaded.
      final manager = MultiServerManager();
      final clientA = _FakeClient(serverId: ServerId('A'), libraries: [_serverLib(ServerId('A'), '1', 'Movies A')]);
      manager.debugRegisterClientForTesting(clientA);
      final p = LibrariesProvider()..initialize(DataAggregationService(manager));

      await p.syncToOnlineServers({'A'});
      expect(p.libraries.map((l) => l.title), ['Movies A']);

      final clientB = _FakeClient(serverId: ServerId('B'), libraries: [_serverLib(ServerId('B'), '1', 'Shows B')]);
      manager.debugRegisterClientForTesting(clientB);
      await p.syncToOnlineServers({'A', 'B'});

      expect(p.libraries.map((l) => l.title), containsAll(<String>['Movies A', 'Shows B']));
      expect(clientA.fetchLibrariesCalls, 1, reason: 'already-loaded server is not refetched');
      expect(clientB.fetchLibrariesCalls, 1);

      p.dispose();
      manager.dispose();
    });

    test('a background reload over existing data never surfaces a loading state', () async {
      final manager = MultiServerManager();
      final clientA = _FakeClient(serverId: ServerId('A'), libraries: [_serverLib(ServerId('A'), '1', 'Movies A')]);
      manager.debugRegisterClientForTesting(clientA);
      final p = LibrariesProvider()..initialize(DataAggregationService(manager));

      await p.syncToOnlineServers({'A'});
      expect(p.hasLoaded, isTrue);

      // A server connecting later must not flip the provider back to a loading
      // state — screens render `isLoading` as a full-screen spinner, so a
      // background reload would blank content the user is already viewing.
      final sawLoading = <bool>[];
      p.addListener(() => sawLoading.add(p.isLoading));

      final clientB = _FakeClient(serverId: ServerId('B'), libraries: [_serverLib(ServerId('B'), '1', 'Shows B')]);
      manager.debugRegisterClientForTesting(clientB);
      await p.syncToOnlineServers({'A', 'B'});

      expect(sawLoading, isNot(contains(true)));
      expect(p.libraries.map((l) => l.title), containsAll(<String>['Movies A', 'Shows B']));

      p.dispose();
      manager.dispose();
    });

    test('a server whose fetch fails is retried on the next sync, not cached as loaded', () async {
      // Regression: getMediaLibrariesFromAllServers swallows a per-server fetch
      // failure and returns no libraries for it — identical to a genuinely empty
      // server. Keying loaded-state on fetch *success* keeps a transiently
      // failed server out of _loadedServerIds so it reloads instead of staying
      // missing until a profile re-switch/restart.
      final manager = MultiServerManager();
      final clientA = _FakeClient(serverId: ServerId('A'), libraries: [_serverLib(ServerId('A'), '1', 'Movies A')]);
      final clientB = _FakeClient(serverId: ServerId('B'), libraries: [_serverLib(ServerId('B'), '1', 'Shows B')])
        ..error = Exception('transient');
      manager.debugRegisterClientForTesting(clientA);
      manager.debugRegisterClientForTesting(clientB);
      final p = LibrariesProvider()..initialize(DataAggregationService(manager));

      await p.syncToOnlineServers({'A', 'B'});
      // A loaded; B's fetch failed, so it is absent and must not be recorded.
      expect(p.libraries.map((l) => l.title), ['Movies A']);

      // B recovers. The same online set must now reload it rather than treating
      // B as already covered.
      clientB.error = null;
      await p.syncToOnlineServers({'A', 'B'});

      expect(p.libraries.map((l) => l.title), containsAll(<String>['Movies A', 'Shows B']));

      p.dispose();
      manager.dispose();
    });

    test('does not reload when the online set shrinks', () async {
      final manager = MultiServerManager();
      final clientA = _FakeClient(serverId: ServerId('A'), libraries: [_serverLib(ServerId('A'), '1', 'Movies A')]);
      final clientB = _FakeClient(serverId: ServerId('B'), libraries: [_serverLib(ServerId('B'), '1', 'Shows B')]);
      manager.debugRegisterClientForTesting(clientA);
      manager.debugRegisterClientForTesting(clientB);
      final p = LibrariesProvider()..initialize(DataAggregationService(manager));

      await p.syncToOnlineServers({'A', 'B'});
      expect(clientA.fetchLibrariesCalls, 1);

      // A drops; the visible online set is now a subset of what we loaded.
      await p.syncToOnlineServers({'B'});

      expect(clientA.fetchLibrariesCalls, 1);
      expect(clientB.fetchLibrariesCalls, 1);

      p.dispose();
      manager.dispose();
    });

    test('a zero-library server is marked loaded and does not retrigger', () async {
      final manager = MultiServerManager();
      final clientC = _FakeClient(serverId: ServerId('C'), libraries: const []);
      manager.debugRegisterClientForTesting(clientC);
      final p = LibrariesProvider()..initialize(DataAggregationService(manager));

      await p.syncToOnlineServers({'C'});
      expect(p.hasLoaded, isTrue);
      expect(p.libraries, isEmpty);
      expect(clientC.fetchLibrariesCalls, 1);

      // Tracking the requested set (not deriving from loaded libraries) is what
      // stops a zero-library server from looking "never loaded" and reloading
      // on every status emission.
      await p.syncToOnlineServers({'C'});
      expect(clientC.fetchLibrariesCalls, 1);

      p.dispose();
      manager.dispose();
    });

    test('a server appearing mid-load is still picked up', () async {
      final manager = MultiServerManager();
      final gate = Completer<void>();
      final clientA = _FakeClient(
        serverId: ServerId('A'),
        libraries: [_serverLib(ServerId('A'), '1', 'Movies A')],
        gate: gate.future,
      );
      manager.debugRegisterClientForTesting(clientA);
      final p = LibrariesProvider()..initialize(DataAggregationService(manager));

      // First load starts and suspends on A's gated fetch.
      final inFlight = p.syncToOnlineServers({'A'});

      // B comes online before the first load completes.
      final clientB = _FakeClient(serverId: ServerId('B'), libraries: [_serverLib(ServerId('B'), '1', 'Shows B')]);
      manager.debugRegisterClientForTesting(clientB);
      unawaited(p.syncToOnlineServers({'A', 'B'})); // queued behind the in-flight pass

      gate.complete();
      await inFlight; // resolves after the replayed pass covering {A, B}

      expect(p.libraries.map((l) => l.title), containsAll(<String>['Movies A', 'Shows B']));
      expect(clientA.fetchLibrariesCalls, 2, reason: 'a second pass runs for the larger set');

      p.dispose();
      manager.dispose();
    });

    test('online-server deltas arriving mid-pass are unioned into one trailing pass', () async {
      final manager = MultiServerManager();
      final clientA = _FakeClient(serverId: ServerId('A'), libraries: [_serverLib(ServerId('A'), '1', 'Movies A')]);
      manager.debugRegisterClientForTesting(clientA);
      final p = LibrariesProvider()..initialize(DataAggregationService(manager));
      await p.syncToOnlineServers({'A'});

      final gate = Completer<void>();
      final clientB = _FakeClient(
        serverId: ServerId('B'),
        libraries: [_serverLib(ServerId('B'), '1', 'Shows B')],
        gate: gate.future,
      );
      manager.debugRegisterClientForTesting(clientB);
      final firstDelta = p.syncToOnlineServers({'A', 'B'});
      expect(clientB.fetchLibrariesCalls, 1);

      final clientC = _FakeClient(serverId: ServerId('C'), libraries: [_serverLib(ServerId('C'), '1', 'Movies C')]);
      manager.debugRegisterClientForTesting(clientC);
      final trailingDelta = p.syncToOnlineServers({'A', 'B', 'C'});

      gate.complete();
      await Future.wait([firstDelta, trailingDelta]);

      expect(clientA.fetchLibrariesCalls, 1);
      expect(clientB.fetchLibrariesCalls, 1, reason: 'the trailing delta drops ids committed by the active pass');
      expect(clientC.fetchLibrariesCalls, 1);
      expect(p.libraries.map((library) => library.title), containsAll(['Movies A', 'Shows B', 'Movies C']));

      p.dispose();
      manager.dispose();
    });

    test('a coalesced call gets its trailing pass after the in-flight pass fails', () async {
      final manager = MultiServerManager();
      final gate = Completer<void>();
      final clientA = _FakeClient(
        serverId: ServerId('A'),
        libraries: [_serverLib(ServerId('A'), '1', 'Movies A')],
        gate: gate.future,
        errorForCall: (call) => call == 1
            ? MediaServerHttpException(type: MediaServerHttpErrorType.cancelled, message: 'first pass cancelled')
            : null,
      );
      manager.debugRegisterClientForTesting(clientA);
      final p = LibrariesProvider()..initialize(DataAggregationService(manager));

      final first = p.loadLibraries();
      final coalesced = p.loadLibraries();
      expect(clientA.fetchLibrariesCalls, 1);

      gate.complete();
      await Future.wait([first, coalesced]);

      expect(clientA.fetchLibrariesCalls, 2);
      expect(p.hasLoaded, isTrue);
      expect(p.libraries.map((library) => library.title), ['Movies A']);

      p.dispose();
      manager.dispose();
    });

    test('dispose during an in-flight coalesced load prevents trailing work and commits', () async {
      final manager = MultiServerManager();
      final gate = Completer<void>();
      final clientA = _FakeClient(
        serverId: ServerId('A'),
        libraries: [_serverLib(ServerId('A'), '1', 'Movies A')],
        gate: gate.future,
      );
      manager.debugRegisterClientForTesting(clientA);
      final p = LibrariesProvider()..initialize(DataAggregationService(manager));
      var notifications = 0;
      p.addListener(() => notifications++);

      final first = p.loadLibraries();
      final coalesced = p.loadLibraries();
      expect(clientA.fetchLibrariesCalls, 1);
      expect(notifications, 1, reason: 'the initial loading state was published before disposal');

      p.dispose();
      gate.complete();
      await Future.wait([first, coalesced]);

      expect(clientA.fetchLibrariesCalls, 1, reason: 'the queued trailing pass was discarded');
      expect(p.libraries, isEmpty, reason: 'the completed fetch was not committed after disposal');
      expect(notifications, 1);

      await p.loadLibraries();
      await p.syncToOnlineServers({'A'});
      expect(clientA.fetchLibrariesCalls, 1, reason: 'post-dispose entry points are no-ops');

      manager.dispose();
    });

    test('clear() resets tracking so the next sync reloads', () async {
      final manager = MultiServerManager();
      final clientA = _FakeClient(serverId: ServerId('A'), libraries: [_serverLib(ServerId('A'), '1', 'Movies A')]);
      manager.debugRegisterClientForTesting(clientA);
      final p = LibrariesProvider()..initialize(DataAggregationService(manager));

      await p.syncToOnlineServers({'A'});
      expect(clientA.fetchLibrariesCalls, 1);

      p.clear();
      expect(p.hasLoaded, isFalse);

      await p.syncToOnlineServers({'A'});
      expect(clientA.fetchLibrariesCalls, 2);

      p.dispose();
      manager.dispose();
    });

    test('a first load disrupted by cancellations stays loading instead of flashing empty', () async {
      // The sign-in empty-flash regression: a rebind tore the client down
      // mid-fetch, the aborted pass used to commit loaded-empty, and the
      // sidebar flashed "no libraries found" until the follow-up load landed.
      final manager = MultiServerManager();
      final clientA = _FakeClient(serverId: ServerId('A'), libraries: [_serverLib(ServerId('A'), '1', 'Movies A')])
        ..error = MediaServerHttpException(type: MediaServerHttpErrorType.cancelled, message: 'HTTP client is closing');
      manager.debugRegisterClientForTesting(clientA);
      final p = LibrariesProvider()..initialize(DataAggregationService(manager));

      await p.loadLibraries();

      expect(p.isLoading, isTrue);
      expect(p.hasLoaded, isFalse);
      expect(p.errorMessage, isNull);

      // The guaranteed follow-up load (binding-settle prime / next status
      // emission) lands the real list.
      clientA.error = null;
      await p.loadLibraries();
      expect(p.hasLoaded, isTrue);
      expect(p.libraries.map((l) => l.title), ['Movies A']);

      p.dispose();
      manager.dispose();
    });

    test('a zero-success first load during profile binding stays loading', () async {
      // The timeout-during-bind window: every fetch failed while the binder
      // was still wiring servers, with no cancellation marker.
      final manager = MultiServerManager();
      final clientA = _FakeClient(serverId: ServerId('A'), libraries: [_serverLib(ServerId('A'), '1', 'Movies A')])
        ..error = Exception('probe timed out');
      manager.debugRegisterClientForTesting(clientA);
      var binding = true;
      final p = LibrariesProvider(isProfileBinding: () => binding)..initialize(DataAggregationService(manager));

      await p.loadLibraries();
      expect(p.isLoading, isTrue);
      expect(p.hasLoaded, isFalse);

      binding = false;
      clientA.error = null;
      await p.loadLibraries();
      expect(p.hasLoaded, isTrue);
      expect(p.libraries.map((l) => l.title), ['Movies A']);

      p.dispose();
      manager.dispose();
    });

    test('a settled zero-success first load still commits loaded-empty', () async {
      // Locks the no-eternal-spinner constraint: a genuinely dead server
      // outside any disruption window keeps today's empty state.
      final manager = MultiServerManager();
      final clientA = _FakeClient(serverId: ServerId('A'))..error = Exception('connection refused');
      manager.debugRegisterClientForTesting(clientA);
      final p = LibrariesProvider()..initialize(DataAggregationService(manager));

      await p.loadLibraries();

      expect(p.hasLoaded, isTrue);
      expect(p.libraries, isEmpty);
      expect(p.errorMessage, isNull);

      p.dispose();
      manager.dispose();
    });

    test('a totally failed silent refresh keeps the last good list', () async {
      // Regression (pre-existing wipe bug): a reload-in-place where every
      // server fails without throwing used to replace the list with [] —
      // blanking the sidebar on a transient outage.
      final manager = MultiServerManager();
      final clientA = _FakeClient(serverId: ServerId('A'), libraries: [_serverLib(ServerId('A'), '1', 'Movies A')]);
      manager.debugRegisterClientForTesting(clientA);
      final p = LibrariesProvider()..initialize(DataAggregationService(manager));

      await p.loadLibraries();
      expect(p.libraries.map((l) => l.title), ['Movies A']);

      clientA.error = Exception('offline');
      await p.loadLibraries();
      expect(p.hasLoaded, isTrue);
      expect(p.libraries.map((l) => l.title), ['Movies A']);

      // The kept list does not count as covering the failed server — the
      // next sync refetches it.
      clientA.error = null;
      final callsBefore = clientA.fetchLibrariesCalls;
      await p.syncToOnlineServers({'A'});
      expect(clientA.fetchLibrariesCalls, callsBefore + 1);

      p.dispose();
      manager.dispose();
    });

    test('online-servers listener is removed on dispose', () {
      final manager = MultiServerManager();
      final multiServer = MultiServerProvider(manager, DataAggregationService(manager));

      final before = multiServer.onlineServersListenerCount;
      final scoped = LibrariesProvider(multiServer: multiServer);
      expect(multiServer.onlineServersListenerCount, before + 1);

      scoped.dispose();
      expect(multiServer.onlineServersListenerCount, before);

      multiServer.dispose();
      manager.dispose();
    });

    test('is a no-op for an empty set or before initialize', () async {
      final manager = MultiServerManager();
      final clientA = _FakeClient(serverId: ServerId('A'), libraries: [_serverLib(ServerId('A'), '1', 'Movies A')]);
      manager.debugRegisterClientForTesting(clientA);

      // Empty set on an initialized provider.
      final p = LibrariesProvider()..initialize(DataAggregationService(manager));
      await p.syncToOnlineServers(<String>{});
      expect(p.loadState, LibrariesLoadState.initial);
      expect(clientA.fetchLibrariesCalls, 0);
      p.dispose();

      // Non-empty set on an uninitialized provider.
      final p2 = LibrariesProvider();
      var notified = 0;
      p2.addListener(() => notified++);
      await p2.syncToOnlineServers({'A'});
      expect(p2.loadState, LibrariesLoadState.initial);
      expect(notified, 0);
      p2.dispose();

      manager.dispose();
    });
  });
}
