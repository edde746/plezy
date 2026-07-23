import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/services/api_cache.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/utils/media_server_http_client.dart';

class _CacheClient with MediaServerCacheMixin implements MediaServerClient {
  _CacheClient(this.cache);

  @override
  final ApiCache cache;

  @override
  ServerId get serverId => ServerId('cache-server');

  @override
  MediaBackend get backend => MediaBackend.plex;

  bool offline = false;

  @override
  bool get isOfflineMode => offline;

  @override
  void setOfflineMode(bool value) => offline = value;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase database;
  late PlexApiCache cache;
  late _CacheClient client;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(database);
    cache = PlexApiCache.instance;
    client = _CacheClient(cache);
  });

  tearDown(() async {
    await database.close();
  });

  test('cache-first rejects decoded 401 and 500 before parsing or caching', () async {
    for (final status in [401, 500]) {
      var networkCalls = 0;
      var parserCalls = 0;
      final key = '/metadata/status-$status';

      await expectLater(
        client.fetchWithCacheFirst<String>(
          cacheScope: client.serverId,
          cacheKey: key,
          networkCall: () async {
            networkCalls++;
            return MediaServerResponse(
              statusCode: status,
              data: {
                'MediaContainer': {
                  'Metadata': [
                    {'ratingKey': 'must-not-parse'},
                  ],
                },
              },
              headers: const {},
            );
          },
          parseCache: (_) => 'cached',
          parseResponse: (_) {
            parserCalls++;
            return 'parsed';
          },
        ),
        throwsA(isA<MediaServerHttpException>().having((error) => error.statusCode, 'statusCode', status)),
      );

      expect(networkCalls, 1);
      expect(parserCalls, 0);
      expect(await cache.get(client.serverId, key), isNull);
    }
  });

  test('cache-first validates status even when response caching is disabled', () async {
    var parserCalls = 0;

    await expectLater(
      client.fetchWithCacheFirst<String>(
        cacheScope: client.serverId,
        cacheKey: '/metadata/no-cache',
        cacheResponse: false,
        networkCall: () async =>
            MediaServerResponse(statusCode: 500, data: const {'mustNotParse': true}, headers: const {}),
        parseCache: (_) => 'cached',
        parseResponse: (_) {
          parserCalls++;
          return 'parsed';
        },
      ),
      throwsA(isA<MediaServerHttpException>().having((error) => error.statusCode, 'statusCode', 500)),
    );

    expect(parserCalls, 0);
    expect(await cache.get(client.serverId, '/metadata/no-cache'), isNull);
  });

  test('successful miss is parsed and cached exactly once', () async {
    var networkCalls = 0;
    var parserCalls = 0;
    const body = {
      'MediaContainer': {
        'Metadata': [
          {'ratingKey': '42'},
        ],
      },
    };

    final value = await client.fetchWithCacheFirst<String>(
      cacheScope: client.serverId,
      cacheKey: '/metadata/success',
      networkCall: () async {
        networkCalls++;
        return MediaServerResponse(statusCode: 200, data: body, headers: const {});
      },
      parseCache: (_) => 'cached',
      parseResponse: (response) {
        parserCalls++;
        return (response.data as Map<String, dynamic>)['MediaContainer'].toString();
      },
    );

    expect(value, contains('ratingKey'));
    expect(networkCalls, 1);
    expect(parserCalls, 1);
    expect(await cache.get(client.serverId, '/metadata/success'), body);
  });

  test('prepopulated cache wins without network or response parsing', () async {
    const body = {'cached': true};
    await cache.put(client.serverId, '/metadata/cached', body);
    var responseParserCalls = 0;

    final value = await client.fetchWithCacheFirst<String>(
      cacheScope: client.serverId,
      cacheKey: '/metadata/cached',
      networkCall: () => fail('Network must not be called for a cache hit'),
      parseCache: (cached) => (cached as Map<String, dynamic>)['cached'].toString(),
      parseResponse: (_) {
        responseParserCalls++;
        return 'network';
      },
    );

    expect(value, 'true');
    expect(responseParserCalls, 0);
  });

  test('offline cache miss returns null without network or parsers', () async {
    client.setOfflineMode(true);
    var cacheParserCalls = 0;
    var responseParserCalls = 0;

    final value = await client.fetchWithCacheFirst<String>(
      cacheScope: client.serverId,
      cacheKey: '/metadata/offline-miss',
      networkCall: () => fail('Network must not be called while offline'),
      parseCache: (_) {
        cacheParserCalls++;
        return 'cached';
      },
      parseResponse: (_) {
        responseParserCalls++;
        return 'network';
      },
    );

    expect(value, isNull);
    expect(cacheParserCalls, 0);
    expect(responseParserCalls, 0);
  });
}
