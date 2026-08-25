import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/media/account_preferences.dart';
import 'package:plezy/media/media_browser_dialect.dart';
import 'package:plezy/media/media_server_user_profile.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/media_browser_account_preferences_source.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/http_fixtures.dart';

MediaBrowserAccountPreferencesSource _source(
  Future<http.Response> Function(http.Request request) handler, {
  MediaBrowserDialect dialect = MediaBrowserDialect.jellyfin,
}) {
  final client = JellyfinClient.forTesting(
    connection: testJellyfinConnection(userId: 'user-1', dialect: dialect),
    httpClient: MockClient(handler),
  );
  addTearDown(client.close);
  return MediaBrowserAccountPreferencesSource(client);
}

Future<Map<String, dynamic>> _postBodyFor(
  AccountPreferencesPatch patch, {
  Map<String, dynamic> configuration = const {},
  MediaBrowserDialect dialect = MediaBrowserDialect.jellyfin,
}) async {
  late Map<String, dynamic> posted;
  final source = _source((request) async {
    if (request.method == 'GET') return jsonResponse({'Configuration': configuration});
    if (request.method == 'POST') {
      posted = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response('', 204);
    }
    return http.Response('unexpected request', 500);
  }, dialect: dialect);

  await source.write(patch);
  return posted;
}

void main() {
  group('MediaBrowserAccountPreferencesSource', () {
    test('read maps all ten UserConfiguration fields and treats an empty language as absent', () async {
      final source = _source((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/Users/Me');
        return jsonResponse({
          'Configuration': {
            'AudioLanguagePreference': 'jpn',
            'PlayDefaultAudioTrack': false,
            'SubtitleLanguagePreference': '',
            'SubtitleMode': 'Smart',
            'RememberAudioSelections': 1,
            'RememberSubtitleSelections': 'false',
            'EnableNextEpisodeAutoPlay': '1',
            'DisplayMissingEpisodes': 0,
            'HidePlayedInLatest': true,
            'DisplayCollectionsView': '0',
          },
        });
      });

      final preferences = await source.read();

      expect(source.capabilities, same(AccountPreferencesCapabilities.mediaBrowser));
      expect(preferences.preferredAudioLanguage, 'jpn');
      expect(preferences.playDefaultAudioTrack, isFalse);
      expect(preferences.preferredSubtitleLanguage, isNull);
      expect(preferences.subtitlePlaybackMode, SubtitlePlaybackMode.smart);
      expect(preferences.rememberAudioSelections, isTrue);
      expect(preferences.rememberSubtitleSelections, isFalse);
      expect(preferences.autoPlayNextEpisode, isTrue);
      expect(preferences.displayMissingEpisodes, isFalse);
      expect(preferences.hidePlayedInLatest, isTrue);
      expect(preferences.displayCollectionsView, isFalse);
    });

    test('read leaves omitted UserConfiguration fields unset', () async {
      final source = _source((_) async => jsonResponse(<String, dynamic>{}));

      final preferences = await source.read();

      for (final key in AccountPreferencesCapabilities.mediaBrowser.supportedKeys) {
        expect(preferences[key], isNull, reason: key.name);
      }
    });

    test('non-2xx read response propagates as a MediaServerHttpException', () async {
      final source = _source((_) async => jsonResponse({'Error': 'read failed'}, status: 503));

      await expectLater(
        source.read(),
        throwsA(isA<MediaServerHttpException>().having((error) => error.statusCode, 'statusCode', 503)),
      );
    });

    test('write merges one patch into the full raw configuration', () async {
      final configuration = <String, dynamic>{
        'SubtitleLanguagePreference': 'eng',
        'DisplayMissingEpisodes': true,
        'OrderedViews': ['movies', 'shows'],
        'CastReceiverId': 'receiver-1',
        'LatestItemsExcludes': ['library-hidden'],
      };

      final posted = await _postBodyFor(
        AccountPreferencesPatch.of(AccountPreferenceKey.preferredSubtitleLanguage, 'ja'),
        configuration: configuration,
      );

      expect(posted, {
        'SubtitleLanguagePreference': 'jpn',
        'DisplayMissingEpisodes': true,
        'OrderedViews': ['movies', 'shows'],
        'CastReceiverId': 'receiver-1',
        'LatestItemsExcludes': ['library-hidden'],
      });
    });

    test('clearing a language posts an empty string under the existing key', () async {
      final posted = await _postBodyFor(
        AccountPreferencesPatch.of(AccountPreferenceKey.preferredAudioLanguage, null),
        configuration: {'AudioLanguagePreference': 'eng'},
      );

      expect(posted, containsPair('AudioLanguagePreference', ''));
      expect(posted.containsKey('AudioLanguagePreference'), isTrue);
    });

    test('widens an ISO 639-1 language patch to the server ISO 639-2 form', () async {
      final posted = await _postBodyFor(AccountPreferencesPatch.of(AccountPreferenceKey.preferredAudioLanguage, 'de'));

      expect(posted['AudioLanguagePreference'], 'deu');
    });

    test('preserves an unknown language patch value verbatim', () async {
      final posted = await _postBodyFor(
        AccountPreferencesPatch.of(AccountPreferenceKey.preferredSubtitleLanguage, 'x-custom'),
      );

      expect(posted['SubtitleLanguagePreference'], 'x-custom');
    });

    test('writes every subtitle mode with the MediaBrowser server spelling', () async {
      const expected = {
        SubtitlePlaybackMode.none: 'None',
        SubtitlePlaybackMode.defaultMode: 'Default',
        SubtitlePlaybackMode.always: 'Always',
        SubtitlePlaybackMode.onlyForced: 'OnlyForced',
        SubtitlePlaybackMode.smart: 'Smart',
      };

      for (final entry in expected.entries) {
        final posted = await _postBodyFor(AccountPreferencesPatch.of(AccountPreferenceKey.subtitleMode, entry.key));
        expect(posted['SubtitleMode'], entry.value, reason: entry.key.name);
      }
    });

    test('posts the legacy user-scoped configuration route for Jellyfin and Emby', () async {
      for (final dialect in MediaBrowserDialect.values) {
        String? writePath;
        var readCount = 0;
        final source = _source((request) async {
          if (request.method == 'GET') {
            readCount++;
            final expectedPath = dialect == MediaBrowserDialect.jellyfin ? '/Users/Me' : '/Users/user-1';
            expect(request.url.path, expectedPath);
            return jsonResponse({'Configuration': <String, dynamic>{}});
          }
          expect(request.method, 'POST');
          writePath = request.url.path;
          return http.Response('', 204);
        }, dialect: dialect);

        await source.write(AccountPreferencesPatch.of(AccountPreferenceKey.autoSelectAudio, false));

        expect(writePath, '/Users/user-1/Configuration', reason: dialect.name);
        expect(readCount, 1, reason: '${dialect.name} must not re-read after the write');
      }
    });

    test('non-2xx write response propagates as a MediaServerHttpException', () async {
      final source = _source((request) async {
        if (request.method == 'GET') {
          return jsonResponse({
            'Configuration': {'RememberAudioSelections': true},
          });
        }
        return jsonResponse({'Error': 'write failed'}, status: 500);
      });

      await expectLater(
        source.write(AccountPreferencesPatch.of(AccountPreferenceKey.rememberAudioSelections, false)),
        throwsA(isA<MediaServerHttpException>().having((error) => error.statusCode, 'statusCode', 500)),
      );
    });

    test('write refuses to post when the current-user response omits Configuration', () async {
      var postCount = 0;
      final source = _source((request) async {
        if (request.method == 'POST') postCount++;
        return jsonResponse(<String, dynamic>{});
      });

      await expectLater(
        source.write(AccountPreferencesPatch.of(AccountPreferenceKey.autoSelectAudio, false)),
        throwsA(isA<FormatException>()),
      );
      expect(postCount, 0);
    });

    test('Plex-only patches throw without posting a partial configuration', () async {
      var postCount = 0;
      final source = _source((request) async {
        if (request.method == 'POST') postCount++;
        return jsonResponse({'Configuration': <String, dynamic>{}});
      });

      await expectLater(
        source.write(AccountPreferencesPatch.of(AccountPreferenceKey.watchedIndicator, WatchedIndicatorScope.none)),
        throwsA(isA<ArgumentError>()),
      );
      expect(postCount, 0);
    });
  });
}
