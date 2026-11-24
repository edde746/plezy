import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/connection/connection.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_auth_service.dart';
import 'package:plezy/services/plex_client.dart';
import 'package:plezy/utils/active_client_scope.dart';

import '../test_helpers/backend_client_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MultiServerManager manager;
  late DataAggregationService aggregation;

  setUp(() {
    manager = MultiServerManager(connectivityChanges: () => const Stream.empty());
    aggregation = DataAggregationService(manager);
  });

  tearDown(() => manager.dispose());

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

    test('isServerOnline / getClientForServer return defaults for unknown ids', () {
      final p = MultiServerProvider(manager, aggregation);
      expect(p.isServerOnline(ServerId('nope')), isFalse);
      expect(p.getClientForServer(ServerId('nope')), isNull);
      p.dispose();
    });

    test('liveTvServers getter returns an unmodifiable view', () {
      final p = MultiServerProvider(manager, aggregation);
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

      manager.updateServerStatus(ServerId('srv-1'), true);
      // Give the broadcast stream microtask time to deliver.
      await Future<void>.delayed(Duration.zero);

      expect(notified, greaterThanOrEqualTo(1));

      p.dispose();
    });

    test('invokes onOnlineServersChanged with the visibility-filtered online set', () async {
      final p = MultiServerProvider(manager, aggregation);
      final calls = <Set<String>>[];
      p.addOnlineServersListener(calls.add);

      manager.updateServerStatus(ServerId('srv-1'), true);
      await Future<void>.delayed(Duration.zero);
      expect(calls, isNotEmpty);
      expect(calls.last, {'srv-1'});

      // A server that is online in the manager but outside the active profile's
      // visibility filter must not appear in the payload.
      p.setVisibleServerIds({'srv-1'});
      manager.updateServerStatus(ServerId('srv-2'), true);
      await Future<void>.delayed(Duration.zero);
      expect(calls.last, {'srv-1'}, reason: 'srv-2 is online but filtered out');
      expect(() => calls.last.clear(), throwsUnsupportedError);

      p.dispose();
    });

    test('online-server listener registration is idempotent', () async {
      final p = MultiServerProvider(manager, aggregation);
      var calls = 0;
      void listener(Set<String> _) => calls++;
      p.addOnlineServersListener(listener);
      p.addOnlineServersListener(listener);

      manager.updateServerStatus(ServerId('srv-1'), true);
      await Future<void>.delayed(Duration.zero);

      expect(calls, 1);
      expect(p.onlineServersListenerCount, 1);
      p.dispose();
    });

    group('visibility filter', () {
      test('setVisibleServerIds replaces the filter and notifies', () {
        final p = MultiServerProvider(manager, aggregation);
        var notified = 0;
        p.addListener(() => notified++);

        expect(p.hasExplicitVisibleServerFilter, isFalse);

        // Empty set is a real value (different from null) — switching from
        // null → {} should notify so consumers know the active profile has
        // no servers, not "all servers".
        p.setVisibleServerIds(<String>{});
        expect(notified, 1);
        expect(p.hasExplicitVisibleServerFilter, isTrue);

        p.setVisibleServerIds({'a', 'b'});
        expect(notified, 2);
        expect(p.hasExplicitVisibleServerFilter, isTrue);

        p.setVisibleServerIds({'b', 'a'});
        expect(notified, 2);

        p.setVisibleServerIds(null);
        expect(notified, 3);
        expect(p.hasExplicitVisibleServerFilter, isFalse);

        p.dispose();
      });

      test('expected visibility is copied and set-equal updates are ignored', () {
        final p = MultiServerProvider(manager, aggregation);
        var notified = 0;
        p.addListener(() => notified++);
        final expected = {'a', 'b'};

        p.setExpectedVisibleServerIds(expected);
        expected.add('c');
        p.setExpectedVisibleServerIds({'b', 'a'});

        expect(notified, 1);
        expect(p.expectedServerIds, containsAll({'a', 'b'}));
        expect(p.expectedServerIds, isNot(contains('c')));
        p.dispose();
      });

      test('addToVisibleServerIds initializes filter when null', () {
        final p = MultiServerProvider(manager, aggregation);
        var notified = 0;
        p.addListener(() => notified++);

        // No prior filter — first add seeds it as a one-element set.
        p.addToVisibleServerIds(ServerId('srv-1'));
        expect(notified, 1);

        // Build up incrementally.
        p.addToVisibleServerIds(ServerId('srv-2'));
        expect(notified, 2);

        // Idempotent on already-present ids.
        p.addToVisibleServerIds(ServerId('srv-1'));
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
        manager.updateServerStatus(ServerId('srv-1'), true);
        manager.updateServerStatus(ServerId('srv-2'), true);
        manager.updateServerStatus(ServerId('srv-3'), false);

        // No filter — every online id passes through.
        expect(p.onlineServerIds, containsAll({'srv-1', 'srv-2'}));

        p.setVisibleServerIds({'srv-1'});
        expect(p.onlineServerIds, ['srv-1']);
        expect(p.isServerOnline(ServerId('srv-2')), isFalse, reason: 'filtered out even when manager reports online');

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

      test('expected servers become visible when they reconnect', () async {
        final p = MultiServerProvider(manager, aggregation);
        final onlineCalls = <Set<String>>[];
        p.addOnlineServersListener(onlineCalls.add);

        p.setVisibleServerIds({'srv-1'});
        p.setExpectedVisibleServerIds({'srv-1', 'srv-2'});
        manager.updateServerStatus(ServerId('srv-1'), true);
        await Future<void>.delayed(Duration.zero);

        expect(p.onlineServerIds, ['srv-1']);

        manager.updateServerStatus(ServerId('srv-2'), true);
        await Future<void>.delayed(Duration.zero);

        expect(p.onlineServerIds, containsAllInOrder(['srv-1', 'srv-2']));
        expect(p.isServerOnline(ServerId('srv-2')), isTrue);
        expect(onlineCalls.last, {'srv-1', 'srv-2'});

        p.dispose();
      });
    });

    group('Live TV re-probe failures', () {
      http.Response? failure;
      Future<void> Function()? duringProbe;
      late PlexClient client;

      setUp(() {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        PlexApiCache.initialize(db);
        failure = null;
        duringProbe = null;
      });

      /// Switch [client] in place to profile B, as
      /// `MultiServerManager.refreshTokensForProfile` does for an online client.
      Future<void> switchClientToProfileB() async {
        final applied = await client.applyProfileUpdate(
          newToken: 'token-b',
          newProfileScopeId: buildPlexProfileScopeId(serverId: ServerId('srv-1'), profileId: 'profile-b'),
        );
        expect(applied, isTrue);
      }

      PlexClient dvrClient() => client = testPlexClient(
        serverId: ServerId('srv-1'),
        handler: (request) async {
          if (request.url.path == '/') {
            return http.Response(
              jsonEncode({
                'MediaContainer': {'machineIdentifier': 'srv-1'},
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path != '/livetv/dvrs') return http.Response('{}', 404);
          final hook = duringProbe;
          duringProbe = null;
          await hook?.call();
          return failure ??
              http.Response(
                jsonEncode({
                  'MediaContainer': {
                    'Dvr': [
                      {'key': 'dvr-1', 'uuid': 'dvr-1'},
                    ],
                  },
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
        },
      );

      Future<MultiServerProvider> providerWithFoundDvr() async {
        manager.debugRegisterClientForTesting(dvrClient());
        final p = MultiServerProvider(manager, aggregation);
        addTearDown(p.dispose);
        await p.checkLiveTvAvailability();
        expect(p.liveTvServers.map((s) => s.dvrKey), ['dvr-1']);
        return p;
      }

      test('a transient failure keeps the DVR the last check found', () async {
        final p = await providerWithFoundDvr();
        failure = http.Response('', 503);
        await p.checkLiveTvAvailability();
        expect(p.hasLiveTv, isTrue);
        expect(p.liveTvServers.map((s) => s.dvrKey), ['dvr-1']);
      });

      test('an authorization failure drops the DVR', () async {
        final p = await providerWithFoundDvr();
        failure = http.Response('', 403);
        await p.checkLiveTvAvailability();
        expect(p.hasLiveTv, isFalse);
        expect(p.liveTvServers, isEmpty);
      });

      test('a transient failure on a replaced client drops the DVR', () async {
        final p = await providerWithFoundDvr();
        failure = http.Response('', 503);
        manager.debugRegisterClientForTesting(dvrClient());
        await p.checkLiveTvAvailability();
        expect(p.hasLiveTv, isFalse);
        expect(p.liveTvServers, isEmpty);
      });

      test('a transient failure after an in-place profile switch drops the DVR', () async {
        final p = await providerWithFoundDvr();
        await switchClientToProfileB();
        failure = http.Response('', 503);
        await p.checkLiveTvAvailability();
        expect(p.hasLiveTv, isFalse);
        expect(p.liveTvServers, isEmpty);
      });

      test('a probe answered across an in-place profile switch is discarded', () async {
        final p = await providerWithFoundDvr();
        duringProbe = switchClientToProfileB;
        await p.checkLiveTvAvailability();
        expect(p.hasLiveTv, isFalse);
        expect(p.liveTvServers, isEmpty);

        // Profile B's own failed probe cannot resurrect profile A's DVR.
        failure = http.Response('', 503);
        await p.checkLiveTvAvailability();
        expect(p.liveTvServers, isEmpty);
      });
    });

    group('Live TV after an in-place profile switch', () {
      final dvrProbeTokens = <String?>[];
      late http.Response noAccessResponse;

      setUp(() {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        PlexApiCache.initialize(db);
        dvrProbeTokens.clear();
        noAccessResponse = http.Response(
          jsonEncode({
            'MediaContainer': {'size': 0},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      /// One server whose `/livetv/dvrs` answer depends on the user: only
      /// `token-dvr` has Live TV access.
      Future<http.Response> handler(http.Request request) async {
        final token = request.headers['X-Plex-Token'];
        http.Response json(Object body) =>
            http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});
        switch (request.url.path) {
          case '/':
            return json({
              'MediaContainer': {'machineIdentifier': 'srv-1'},
            });
          case '/media/providers':
            return json({
              'MediaContainer': {'MediaProvider': <Object>[]},
            });
          case '/livetv/dvrs':
            dvrProbeTokens.add(token);
            if (token != 'token-dvr') return noAccessResponse;
            return json({
              'MediaContainer': {
                'Dvr': [
                  {'key': 'dvr-1', 'uuid': 'dvr-1'},
                ],
              },
            });
        }
        return http.Response('{}', 404);
      }

      Future<MultiServerProvider> providerOnlineAs(String token) async {
        manager.debugRegisterClientForTesting(
          testPlexClient(
            serverId: ServerId('srv-1'),
            token: token,
            profileScopeId: buildPlexProfileScopeId(serverId: ServerId('srv-1'), profileId: 'profile-a'),
            handler: handler,
          ),
          online: false,
        );
        final p = MultiServerProvider(manager, aggregation);
        addTearDown(p.dispose);
        p.setVisibleServerIds({'srv-1'});
        manager.updateServerStatus(ServerId('srv-1'), true);
        await pumpEventQueue();
        return p;
      }

      /// What `ActiveProfileBinder` does for a Plex Home switch: rotate the
      /// online client's token in place, then publish the same visible set.
      Future<void> switchTo(MultiServerProvider p, String token) async {
        final account = PlexAccountConnection(
          id: 'account',
          accountToken: 'account-token',
          clientIdentifier: 'test-client',
          accountLabel: 'Account',
          servers: [
            PlexServer(
              name: 'srv-1',
              clientIdentifier: 'srv-1',
              accessToken: token,
              connections: const [],
              owned: true,
            ),
          ],
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        );
        expect(await manager.refreshTokensForProfile(account, profileId: 'profile-b'), {'srv-1'});
        p.setVisibleServerIds({'srv-1'});
        await pumpEventQueue();
      }

      test('switching to a user without Live TV access hides it', () async {
        final p = await providerOnlineAs('token-dvr');
        expect(p.hasLiveTv, isTrue);

        await switchTo(p, 'token-no-dvr');
        expect(p.hasLiveTv, isFalse);
        expect(p.liveTvServers, isEmpty);
      });

      test('switching to a user with Live TV access shows it', () async {
        final p = await providerOnlineAs('token-no-dvr');
        expect(p.hasLiveTv, isFalse);

        await switchTo(p, 'token-dvr');
        expect(p.hasLiveTv, isTrue);
        expect(p.liveTvServers.map((s) => s.dvrKey), ['dvr-1']);
      });

      test('a refused user is not re-probed on unrelated status changes', () async {
        noAccessResponse = http.Response('', 403);
        final p = await providerOnlineAs('token-dvr');
        await switchTo(p, 'token-no-dvr');
        expect(p.hasLiveTv, isFalse);
        final probes = dvrProbeTokens.length;

        manager.updateServerStatus(ServerId('srv-2'), false);
        await pumpEventQueue();
        expect(dvrProbeTokens, hasLength(probes));
      });
    });

    test('dispose runs cleanly and cancels the status subscription', () async {
      final p = MultiServerProvider(manager, aggregation);

      var notifyCount = 0;
      p.addListener(() => notifyCount++);

      // Sanity: subscription works pre-dispose.
      manager.updateServerStatus(ServerId('a'), true);
      await Future<void>.delayed(Duration.zero);
      expect(notifyCount, greaterThanOrEqualTo(1));

      // The provider owns only its subscription; the app root owns the manager.
      expect(p.dispose, returnsNormally);
      expect(() => manager.updateServerStatus(ServerId('b'), true), returnsNormally);
    });
  });
}
