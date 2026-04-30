import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/models/plex/plex_config.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('favorite source follows requested lineup provider', () async {
    final client = PlexClient.forTesting(
      config: PlexConfig(
        baseUrl: 'https://plex.example.com',
        token: 'tok',
        clientIdentifier: 'client',
        product: 'Plezy',
        version: '1',
        machineIdentifier: 'machine-1',
      ),
      serverId: 'machine-1',
      httpClient: MockClient((_) async => http.Response('{}', 200)),
      epgProviders: const [
        (identifier: 'provider-a', gridEndpoint: '/provider-a/grid'),
        (identifier: 'provider-b', gridEndpoint: '/provider-b/grid'),
      ],
    );
    addTearDown(client.close);

    expect(await client.liveTv.buildFavoriteChannelSource(lineup: 'provider-b'), 'server://machine-1/provider-b');
  });

  test('favorite store is account device scoped instead of token scoped', () {
    PlexClient makeClient(String token) {
      return PlexClient.forTesting(
        config: PlexConfig(
          baseUrl: 'https://plex.example.com',
          token: token,
          clientIdentifier: 'account-device',
          product: 'Plezy',
          version: '1',
          machineIdentifier: 'machine-1',
        ),
        serverId: 'machine-1',
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );
    }

    final a = makeClient('server-token-a');
    final b = makeClient('server-token-b');
    addTearDown(a.close);
    addTearDown(b.close);

    expect(a.liveTv.favoriteStoreKey, b.liveTv.favoriteStoreKey);
  });
}
