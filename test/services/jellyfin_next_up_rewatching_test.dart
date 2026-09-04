import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/media/account_preferences.dart';
import 'package:plezy/media/media_browser_dialect.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/media_browser_account_preferences_source.dart';

import '../test_helpers/backend_client_fixtures.dart';

/// Every request the client made, so a test can assert what Next Up carried.
class _Recorder {
  final List<Uri> requests = [];

  http.Client client({bool rewatchingStored = false}) {
    return MockClient((request) async {
      requests.add(request.url);
      final path = request.url.path;
      if (request.method == 'POST') return http.Response('', 204);
      if (path.startsWith('/DisplayPreferences/')) {
        return http.Response(
          jsonEncode({
            'CustomPrefs': {if (rewatchingStored) 'enableRewatchingInNextUp': 'true'},
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }
      if (path.endsWith('/Items/series-1')) {
        return http.Response(
          jsonEncode({'Id': 'series-1', 'Name': 'Rewatched Show', 'Type': 'Series'}),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }
      if (path == '/Users/Me' || path == '/Users/user-1') {
        return http.Response(
          jsonEncode({'Configuration': <String, dynamic>{}}),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }
      return http.Response(
        jsonEncode({'Items': <dynamic>[], 'TotalRecordCount': 0}),
        200,
        headers: const {'content-type': 'application/json'},
      );
    });
  }

  Iterable<Uri> get nextUpRequests => requests.where((uri) => uri.path == '/Shows/NextUp');
}

JellyfinClient _client(_Recorder recorder, {bool rewatchingStored = false, MediaBrowserDialect? dialect}) {
  final client = JellyfinClient.forTesting(
    connection: testJellyfinConnection(userId: 'user-1', dialect: dialect ?? MediaBrowserDialect.jellyfin),
    httpClient: recorder.client(rewatchingStored: rewatchingStored),
  );
  addTearDown(client.close);
  return client;
}

void main() {
  group('Next Up rewatching', () {
    test('the parameter is absent until the account switch is read as on', () async {
      final recorder = _Recorder();
      final client = _client(recorder);

      await client.fetchContinueWatching(count: 5);
      await client.fetchItemWithOnDeck('series-1');

      expect(recorder.nextUpRequests, isNotEmpty);
      for (final uri in recorder.nextUpRequests) {
        expect(uri.queryParameters.containsKey('EnableRewatching'), isFalse, reason: uri.toString());
      }
    });

    test('every Next Up request carries it once the account has it on', () async {
      final recorder = _Recorder();
      final client = _client(recorder, rewatchingStored: true);

      // The profile bind performs this read at startup; browsing then needs no
      // fetch of its own.
      await MediaBrowserAccountPreferencesSource(client).read();
      recorder.requests.clear();

      await client.fetchContinueWatching(count: 5);
      await client.fetchItemWithOnDeck('series-1');
      await client.fetchGlobalHubs(limit: 5);

      final nextUp = recorder.nextUpRequests.toList();
      expect(nextUp, isNotEmpty);
      for (final uri in nextUp) {
        expect(uri.queryParameters['EnableRewatching'], 'true', reason: uri.toString());
      }
    });

    test('writing the switch on takes effect without a further read', () async {
      final recorder = _Recorder();
      final client = _client(recorder, rewatchingStored: true);

      await MediaBrowserAccountPreferencesSource(
        client,
      ).write(AccountPreferencesPatch.of(AccountPreferenceKey.rewatchingInNextUp, true));
      recorder.requests.clear();

      await client.fetchContinueWatching(count: 5);

      expect(recorder.nextUpRequests, isNotEmpty);
      for (final uri in recorder.nextUpRequests) {
        expect(uri.queryParameters['EnableRewatching'], 'true');
      }
    });

    test('Emby never receives the parameter, even with the switch stored', () async {
      final recorder = _Recorder();
      final client = _client(recorder, rewatchingStored: true, dialect: MediaBrowserDialect.emby);

      await MediaBrowserAccountPreferencesSource(client).read();
      recorder.requests.clear();

      await client.fetchItemWithOnDeck('series-1');

      expect(recorder.nextUpRequests, isNotEmpty);
      for (final uri in recorder.nextUpRequests) {
        expect(uri.queryParameters.containsKey('EnableRewatching'), isFalse, reason: uri.toString());
      }
    });
  });
}
