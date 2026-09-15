import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/profiles/active_profile_binder.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/catalog/catalog_library_matcher.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_auth_service.dart';
import 'package:plezy/utils/media_server_http_client.dart';

import '../../test_helpers/backend_client_fixtures.dart';
import '../../test_helpers/prefs.dart';
import '../../test_helpers/profile_stack.dart';

/// Real authenticated health and catalog requests, without an external server.
class _LibraryServer {
  _LibraryServer(this.id, this.httpServer);

  final String id;
  final HttpServer httpServer;
  bool hasCopy = false;
  int lookups = 0;

  String get baseUrl => 'http://127.0.0.1:${httpServer.port}';

  static Future<_LibraryServer> start(String id) async {
    final server = _LibraryServer(id, await HttpServer.bind(InternetAddress.loopbackIPv4, 0));
    server.httpServer.listen((request) async {
      final Object body;
      switch (request.uri.path) {
        case '/System/Info/Public':
          body = {'Id': id, 'ServerName': id, 'Version': '10.11.0'};
        case '/Users/Me':
          body = {
            'Id': 'user-1',
            'Policy': {'IsAdministrator': false},
          };
        case '/Items':
          server.lookups++;
          body = {
            'Items': [
              if (server.hasCopy)
                {
                  'Id': '$id-copy',
                  'Type': 'Movie',
                  'Name': 'Catalog Movie',
                  'ProviderIds': {'Tmdb': '42'},
                },
            ],
          };
        case final path when path.endsWith('/Ancestors'):
          body = <Object>[];
        default:
          request.response.statusCode = HttpStatus.notFound;
          body = <String, Object>{};
      }
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(body));
      await request.response.close();
    });
    return server;
  }

  Future<void> close() async {
    await httpServer.close(force: true);
  }
}

PlexAccountConnection _clientlessAccount(String serverId, String baseUrl) => PlexAccountConnection(
  id: 'account-$serverId',
  accountToken: 'account-token-$serverId',
  clientIdentifier: 'test-client',
  accountLabel: serverId,
  createdAt: DateTime.utc(2026),
  servers: [
    PlexServer(
      name: serverId,
      clientIdentifier: serverId,
      accessToken: 'old-server-token',
      owned: true,
      connections: [
        PlexConnection(
          protocol: 'http',
          address: '127.0.0.1',
          port: Uri.parse(baseUrl).port,
          uri: baseUrl,
          local: true,
          relay: false,
          ipv6: false,
        ),
      ],
    ),
  ],
);

void main() {
  test('clientless A registrations do not contaminate B, but expected clientless B servers stay unchecked', () async {
    resetSharedPreferencesForTest();
    final previousHttpOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousHttpOverrides);
    final stack = await ProfileStack.create();
    JellyfinApiCache.initialize(stack.db);
    final aServer = await _LibraryServer.start('a');
    final bServer = await _LibraryServer.start('b');
    final manager = MultiServerManager(connectivityChanges: () => const Stream.empty());
    final multiServer = MultiServerProvider(manager, DataAggregationService(manager));
    final auth = PlexAuthService.forTesting(
      http: MediaServerHttpClient(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/switch')) {
            return http.Response(
              jsonEncode({'authToken': 'fresh-rejected-token'}),
              201,
              headers: {'content-type': 'application/json'},
            );
          }
          expect(request.url.path.endsWith('/resources'), isTrue);
          return http.Response('{}', 401, headers: {'content-type': 'application/json'});
        }),
      ),
    );
    final binder = ActiveProfileBinder(
      activeProfile: stack.active,
      connections: stack.connections,
      profileConnections: stack.profileConnections,
      serverManager: manager,
      multiServerProvider: multiServer,
      pinPrompt: (_, {String? errorMessage}) async => null,
      plexAuth: auth,
    );
    final matchers = <CatalogLibraryMatcher>[];
    addTearDown(() async {
      for (final matcher in matchers) {
        matcher.dispose();
      }
      binder.dispose();
      multiServer.dispose();
      manager.dispose();
      auth.dispose();
      await aServer.close();
      await bServer.close();
      await stack.dispose();
    });
    final a = Profile.local(id: 'profile-a', displayName: 'A', createdAt: DateTime.utc(2026));
    final b = Profile.local(id: 'profile-b', displayName: 'B', createdAt: DateTime.utc(2026));
    await stack.profiles.upsert(a);
    await stack.profiles.upsert(b);
    final aClientless = _clientlessAccount('a-clientless', aServer.baseUrl);
    final bClientless = _clientlessAccount('b-clientless', bServer.baseUrl);
    final aConnection = testJellyfinConnection(machineId: 'a', baseUrl: aServer.baseUrl);
    final bConnection = testJellyfinConnection(machineId: 'b', baseUrl: bServer.baseUrl);
    for (final connection in <Connection>[aClientless, bClientless, aConnection, bConnection]) {
      await stack.connections.upsert(connection);
    }
    Future<void> join(Profile profile, Connection connection) => stack.profileConnections.upsert(
      ProfileConnection(
        profileId: profile.id,
        connectionId: connection.id,
        userIdentifier: 'user-1',
        tokenAcquiredAt: DateTime.utc(2026),
      ),
    );
    await join(a, aClientless);
    await join(a, aConnection);
    await join(b, bConnection);
    await stack.storage.setActiveProfileId(a.id);
    await stack.active.initialize();
    await binder.rebindActive();
    expect(stack.active.lastBindingSucceeded, isTrue);
    expect(manager.getClient(ServerId('a-clientless')), isNull);
    expect(manager.authErrorServerIds, contains('a-clientless'));

    const item = CatalogItem(
      source: CatalogSourceId.trakt,
      kind: MediaKind.movie,
      title: 'Catalog Movie',
      ids: CatalogItemIds(tmdb: 42),
    );
    var now = DateTime.utc(2026, 7, 28);
    CatalogLibraryMatcher newMatcher() {
      final matcher = CatalogLibraryMatcher.withClock(multiServer, () => now);
      matchers.add(matcher);
      return matcher;
    }

    expect((await newMatcher().match(item)).unqueriedServerIds, {'a-clientless'});

    expect(await stack.active.activate(b), isTrue);
    await binder.rebindActive();
    expect(stack.active.lastBindingSucceeded, isTrue);
    expect(manager.getClient(ServerId('a')), isNull);
    expect(manager.authErrorServerIds, contains('a-clientless'));
    final bMatcher = newMatcher();
    final bMiss = await bMatcher.match(item);
    expect(bMiss.items, isEmpty);
    expect(bMiss.succeededServerIds, {'b'});
    expect(bMiss.failedServerIds, isEmpty);
    expect(bMiss.cancelledServerIds, isEmpty);
    expect(bMiss.unqueriedServerIds, isEmpty);

    bServer.hasCopy = true;
    now = now.add(CatalogLibraryMatcher.negativeTtl);
    expect((await bMatcher.match(item)).items.single.id, 'b-copy');
    bServer.hasCopy = false;
    now = now.add(const Duration(days: 30));
    expect(
      (await bMatcher.match(item)).items.single.id,
      'b-copy',
      reason: 'unrelated A registrations do not turn a complete B hit into an expiring wave',
    );
    expect(bServer.lookups, 2);

    await join(b, bClientless);
    await binder.rebindActive();
    multiServer.setVisibleServerIds({});
    final bIncomplete = await bMatcher.match(item);
    expect(bIncomplete.succeededServerIds, {'b'});
    expect(bIncomplete.unqueriedServerIds, {'b-clientless'});
    expect(bIncomplete.items, isEmpty);

    await stack.profileConnections.remove(b.id, bClientless.id);
    await binder.rebindActive();
    expect((await bMatcher.match(item)).unqueriedServerIds, isEmpty);

    expect(await stack.active.activate(a), isTrue);
    await binder.rebindActive();
    final aAgain = newMatcher();
    final aResult = await aAgain.match(item);
    expect(aResult.succeededServerIds, {'a'});
    expect(aResult.unqueriedServerIds, {'a-clientless'});
    expect(aResult.failedServerIds, isEmpty);
    expect(aResult.cancelledServerIds, isEmpty);

    await stack.active.clearActiveProfile();
    await binder.rebindActive();
    final cleared = await aAgain.match(item);
    expect(cleared.items, isEmpty);
    expect(cleared.succeededServerIds, isEmpty);
    expect(cleared.unqueriedServerIds, isEmpty);
    expect(cleared.failedServerIds, isEmpty);
    expect(cleared.cancelledServerIds, isEmpty);
  });
}
