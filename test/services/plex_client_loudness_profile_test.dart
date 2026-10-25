import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/database/app_database.dart';
import 'package:plezy/services/plex_api_cache.dart';

import '../test_helpers/backend_client_fixtures.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(database);
  });

  tearDown(() => database.close());

  test('requests the bounded Plex levels endpoint and downsamples oversized responses', () async {
    http.Request? observedRequest;
    final rawLevels = List.generate(1025, (index) => {'v': -60.0 + index / 100});
    final client = testPlexClient(
      handler: (request) async {
        observedRequest = request;
        return http.Response(
          jsonEncode({
            'MediaContainer': {'totalSamples': 9000, 'Level': rawLevels},
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      },
    );
    addTearDown(client.close);

    final profile = await client.fetchAudioLoudnessProfile(42);

    expect(observedRequest?.url.path, '/library/streams/42/levels');
    expect(observedRequest?.url.queryParameters['subsample'], '512');
    expect(profile, isNotNull);
    expect(profile!.levelsDb.length, lessThanOrEqualTo(512));
    expect(profile.totalSamples, 9000);
    expect(profile.levelsDb.first, -60);
  });

  test('filters invalid sample values and returns null when nothing usable remains', () async {
    final client = testPlexClient(
      handler: (_) async => http.Response(
        jsonEncode({
          'MediaContainer': {
            'Level': [
              {'v': -120},
              {'v': 24},
              {'v': -121},
              {'v': 25},
              {'v': 'NaN'},
              {'v': 'not-a-number'},
              null,
            ],
          },
        }),
        200,
        headers: const {'content-type': 'application/json'},
      ),
    );
    addTearDown(client.close);

    final profile = await client.fetchAudioLoudnessProfile(43);
    expect(profile?.levelsDb, [-120, 24]);
    expect(profile?.totalSamples, 2);
  });

  test('unavailable, malformed, and invalid-id responses degrade to null', () async {
    var requestCount = 0;
    final client = testPlexClient(
      handler: (_) async {
        requestCount++;
        return http.Response('not-json', 404);
      },
    );
    addTearDown(client.close);

    expect(await client.fetchAudioLoudnessProfile(0), isNull);
    expect(await client.fetchAudioLoudnessProfile(44), isNull);
    expect(requestCount, 1);
  });
}
