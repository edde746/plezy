import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MultiServerManager manager;
  late DataAggregationService aggregation;

  setUp(() {
    manager = MultiServerManager();
    aggregation = DataAggregationService(manager);
  });

  // The provider's dispose() also disposes the manager — only call manager.dispose
  // here in tests where the provider is *not* constructed.

  group('MultiServerProvider', () {
    test('starts with empty server lists and no live TV', () {
      final p = MultiServerProvider(manager, aggregation);
      expect(p.serverIds, isEmpty);
      expect(p.onlineServerIds, isEmpty);
      expect(p.onlineServerCount, 0);
      expect(p.totalServerCount, 0);
      expect(p.hasConnectedServers, isFalse);
      expect(p.hasLiveTv, isFalse);
      expect(p.liveTvServers, isEmpty);
      p.dispose();
    });

    test('exposes the injected manager and aggregation service', () {
      final p = MultiServerProvider(manager, aggregation);
      expect(identical(p.serverManager, manager), isTrue);
      expect(identical(p.aggregationService, aggregation), isTrue);
      p.dispose();
    });

    test('isServerOnline / getClientForServer return defaults for unknown ids', () {
      final p = MultiServerProvider(manager, aggregation);
      expect(p.isServerOnline('nope'), isFalse);
      expect(p.getClientForServer('nope'), isNull);
      p.dispose();
    });

    test('liveTvServers getter returns an unmodifiable view', () {
      final p = MultiServerProvider(manager, aggregation);
      // Empty by default; mutating through the unmodifiable view must throw.
      expect(() => p.liveTvServers.clear(), throwsUnsupportedError);
      p.dispose();
    });

    test('clearAllConnections notifies listeners', () async {
      final p = MultiServerProvider(manager, aggregation);

      var notified = 0;
      p.addListener(() => notified++);

      // disconnectAll() also pushes a status event onto the broadcast stream,
      // which will eventually fire the manager-status listener and notify
      // again. We only assert that the synchronous notifyListeners path runs.
      p.clearAllConnections();
      expect(notified, greaterThanOrEqualTo(1));

      p.dispose();
    });

    test('listens to manager status stream and notifies on change', () async {
      final p = MultiServerProvider(manager, aggregation);

      var notified = 0;
      p.addListener(() => notified++);

      // Push a status change through the manager's public API.
      manager.updateServerStatus('srv-1', true);
      // Give the broadcast stream microtask time to deliver.
      await Future<void>.delayed(Duration.zero);

      expect(notified, greaterThanOrEqualTo(1));

      p.dispose();
    });

    test('checkServerHealth with no clients completes without error', () async {
      final p = MultiServerProvider(manager, aggregation);
      // Empty clients map → no work, but the call must complete.
      await p.checkServerHealth();
      p.dispose();
    });

    group('visibility filter', () {
      test('setVisibleServerIds replaces the filter and notifies', () {
        final p = MultiServerProvider(manager, aggregation);
        var notified = 0;
        p.addListener(() => notified++);

        // Empty set is a real value (different from null) — switching from
        // null → {} should notify so consumers know the active profile has
        // no servers, not "all servers".
        p.setVisibleServerIds(<String>{});
        expect(notified, 1);

        p.setVisibleServerIds({'a', 'b'});
        expect(notified, 2);

        // Idempotent: same membership is a no-op.
        p.setVisibleServerIds({'b', 'a'});
        expect(notified, 2);

        // Clearing back to null after a real filter is a state change.
        p.setVisibleServerIds(null);
        expect(notified, 3);

        p.dispose();
      });

      test('addToVisibleServerIds initializes filter when null', () {
        final p = MultiServerProvider(manager, aggregation);
        var notified = 0;
        p.addListener(() => notified++);

        // No prior filter — first add seeds it as a one-element set.
        p.addToVisibleServerIds('srv-1');
        expect(notified, 1);

        // Build up incrementally.
        p.addToVisibleServerIds('srv-2');
        expect(notified, 2);

        // Idempotent on already-present ids.
        p.addToVisibleServerIds('srv-1');
        expect(notified, 2);

        p.dispose();
      });

      test('onlineServerIds respect the visibility filter', () {
        final p = MultiServerProvider(manager, aggregation);
        // updateServerStatus only populates _serverStatus, not _plexServers, so
        // we exercise the filter via onlineServerIds (which is keyed off
        // status). The serverIds list requires actual server registration
        // which goes through addPlexAccount/addJellyfinConnection — beyond
        // what this unit test needs to cover.
        manager.updateServerStatus('srv-1', true);
        manager.updateServerStatus('srv-2', true);
        manager.updateServerStatus('srv-3', false);

        // No filter — every online id passes through.
        expect(p.onlineServerIds, containsAll({'srv-1', 'srv-2'}));

        p.setVisibleServerIds({'srv-1'});
        expect(p.onlineServerIds, ['srv-1']);
        expect(p.isServerOnline('srv-2'), isFalse, reason: 'filtered out even when manager reports online');

        // Empty filter blocks everything — covers the "no connections" path
        // for a freshly-created profile that hasn't borrowed anything yet.
        p.setVisibleServerIds(<String>{});
        expect(p.onlineServerIds, isEmpty);

        p.dispose();
      });

      test('setVisibleServerIds immediately hides Live TV servers outside the filter', () {
        final p = MultiServerProvider(manager, aggregation);
        p.debugSetLiveTvServersForTesting([
          LiveTvServerInfo(serverId: 'srv-1', dvrKey: 'dvr-1'),
          LiveTvServerInfo(serverId: 'srv-2', dvrKey: 'dvr-2'),
        ]);

        p.setVisibleServerIds({'srv-1'});

        expect(p.hasLiveTv, isTrue);
        expect(p.liveTvServers.map((s) => s.serverId), ['srv-1']);
        expect(p.liveTvServers.single.dvrKey, 'dvr-1');

        p.dispose();
      });

      test('setVisibleServerIds empty immediately clears stale Live TV state', () {
        final p = MultiServerProvider(manager, aggregation);
        p.debugSetLiveTvServersForTesting([LiveTvServerInfo(serverId: 'srv-1', dvrKey: 'dvr-1')]);

        p.setVisibleServerIds(<String>{});

        expect(p.hasLiveTv, isFalse);
        expect(p.liveTvServers, isEmpty);

        p.dispose();
      });
    });

    test('dispose runs cleanly and cancels the status subscription', () async {
      final p = MultiServerProvider(manager, aggregation);

      var notifyCount = 0;
      p.addListener(() => notifyCount++);

      // Sanity: subscription works pre-dispose.
      manager.updateServerStatus('a', true);
      await Future<void>.delayed(Duration.zero);
      expect(notifyCount, greaterThanOrEqualTo(1));

      // After dispose, no further notifications can be observed because the
      // provider has been disposed AND its subscription is cancelled. We
      // can't even push to the manager (disposed), so we just verify that
      // disposing once doesn't throw.
      expect(p.dispose, returnsNormally);
    });
  });
}
