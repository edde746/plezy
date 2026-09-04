import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/media/account_preferences.dart';
import 'package:plezy/media/media_server_user_profile.dart';
import 'package:plezy/models/plex/plex_account_preferences.dart';
import 'package:plezy/services/plex_account_preferences_source.dart';
import 'package:plezy/services/plex_auth_service.dart';
import 'package:plezy/utils/media_server_http_client.dart';

void main() {
  group('Plex account preferences', () {
    test('read maps all eight profile keys and accepts the profile envelope', () async {
      var serviceCount = 0;
      final source = PlexAccountPreferencesSource(
        authToken: 'account-token',
        serviceFactory: () async {
          final responseBody = serviceCount++ == 0 ? _profilePayload() : {'profile': _profilePayload()};
          return _serviceWith(
            MockClient((request) async {
              expect(request.method, 'GET');
              expect(request.url.host, 'clients.plex.tv');
              expect(request.url.path, '/api/v2/user/profile');
              return http.Response(jsonEncode(responseBody), 200, headers: {'content-type': 'application/json'});
            }),
          );
        },
      );

      final bare = await source.read();
      final wrapped = await source.read();

      expect(_snapshot(bare), [
        'de',
        true,
        'sv',
        SubtitlePlaybackMode.smart,
        WatchedIndicatorScope.shows,
        MediaReviewsVisibility.criticsOnly,
        SubtitleAccessibilityPreference.onlySdh,
        ForcedSubtitlePreference.preferForced,
      ]);
      expect(_snapshot(wrapped), _snapshot(bare));
    });

    test('read tolerates drifted scalars without discarding the profile', () async {
      final source = PlexAccountPreferencesSource(
        authToken: 'account-token',
        serviceFactory: () async => _serviceWith(
          MockClient(
            (_) async => http.Response(
              jsonEncode({
                'autoSelectAudio': '1',
                'autoSelectSubtitle': 1,
                'watchedIndicator': 99,
                'mediaReviewsVisibility': '1',
              }),
              200,
              headers: {'content-type': 'application/json'},
            ),
          ),
        ),
      );

      final preferences = await source.read();

      expect(preferences.playDefaultAudioTrack, isTrue);
      expect(preferences.subtitlePlaybackMode, SubtitlePlaybackMode.smart);
      expect(preferences.watchedIndicator, isNull);
      expect(preferences.mediaReviewsVisibility, MediaReviewsVisibility.usersOnly);
    });

    test('language fields take the first entry of array or CSV drift (#1488)', () {
      final array = PlexAccountPreferences.fromProfileJson({
        'defaultAudioLanguage': ['en', 'sv'],
        'defaultSubtitleLanguage': ['sv', 'en'],
      });
      final csv = PlexAccountPreferences.fromProfileJson({
        'defaultAudioLanguage': 'en,sv',
        'defaultSubtitleLanguage': 'sv,en',
      });
      final absent = PlexAccountPreferences.fromProfileJson({'defaultAudioLanguage': null});

      for (final preferences in [array, csv]) {
        expect(preferences.defaultAudioLanguage, 'en');
        expect(preferences.defaultSubtitleLanguage, 'sv');
      }
      expect(absent.defaultAudioLanguage, isNull);
      expect(absent.defaultSubtitleLanguage, isNull);
    });

    test('write sends query parameters with an empty body and re-reads an empty response', () async {
      var requestCount = 0;
      final source = PlexAccountPreferencesSource(
        authToken: 'account-token',
        serviceFactory: () async => _serviceWith(
          MockClient((request) async {
            requestCount++;
            if (request.method == 'PUT') {
              expect(request.url.host, 'clients.plex.tv');
              expect(request.url.path, '/api/v2/user/profile');
              expect(request.url.queryParameters, {
                'defaultAudioLanguage': '',
                'autoSelectAudio': '1',
                'defaultSubtitleLanguage': 'de',
                'autoSelectSubtitle': '1',
                'watchedIndicator': '2',
                'mediaReviewsVisibility': '3',
                'defaultSubtitleAccessibility': '2',
                'defaultSubtitleForced': '1',
              });
              expect(request.body, isEmpty);
              expect(request.headers['content-type'], isNull);
              return http.Response('', 204);
            }

            expect(request.method, 'GET');
            expect(request.url.path, '/api/v2/user/profile');
            return http.Response(jsonEncode(_profilePayload()), 200, headers: {'content-type': 'application/json'});
          }),
        ),
      );
      final patch = AccountPreferencesPatch({
        AccountPreferenceKey.preferredAudioLanguage: null,
        AccountPreferenceKey.autoSelectAudio: true,
        AccountPreferenceKey.preferredSubtitleLanguage: 'deu',
        AccountPreferenceKey.subtitleMode: SubtitlePlaybackMode.smart,
        AccountPreferenceKey.watchedIndicator: WatchedIndicatorScope.movies,
        AccountPreferenceKey.mediaReviewsVisibility: MediaReviewsVisibility.nobody,
        AccountPreferenceKey.subtitleAccessibility: SubtitleAccessibilityPreference.onlySdh,
        AccountPreferenceKey.forcedSubtitles: ForcedSubtitlePreference.preferForced,
      });

      final preferences = await source.write(patch);

      expect(requestCount, 2);
      expect(preferences.preferredAudioLanguage, 'de');
    });

    test('disabling automatic audio also sends manual subtitle selection', () async {
      final source = PlexAccountPreferencesSource(
        authToken: 'account-token',
        serviceFactory: () async => _serviceWith(
          MockClient((request) async {
            expect(request.method, 'PUT');
            expect(request.url.queryParameters, {'autoSelectAudio': '0', 'autoSelectSubtitle': '0'});
            expect(request.body, isEmpty);
            return http.Response(
              jsonEncode({'autoSelectAudio': false, 'autoSelectSubtitle': 0}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
      );

      final preferences = await source.write(AccountPreferencesPatch.of(AccountPreferenceKey.autoSelectAudio, false));

      expect(preferences.playDefaultAudioTrack, isFalse);
      expect(preferences.subtitlePlaybackMode, SubtitlePlaybackMode.none);
    });

    test('only-forced subtitle mode cannot be represented by Plex', () {
      final patch = AccountPreferencesPatch.of(AccountPreferenceKey.subtitleMode, SubtitlePlaybackMode.onlyForced);

      expect(
        () => PlexAccountPreferences.queryParametersFor(patch),
        throwsA(isA<ArgumentError>().having((error) => error.toString(), 'message', contains('subtitleMode'))),
      );
    });
  });
}

PlexAuthService _serviceWith(http.Client client) =>
    PlexAuthService.forTesting(http: MediaServerHttpClient(client: client));

Map<String, dynamic> _profilePayload() => {
  'autoSelectAudio': true,
  'defaultAudioLanguage': 'de',
  'defaultSubtitleLanguage': 'sv',
  'autoSelectSubtitle': 1,
  'defaultSubtitleAccessibility': 2,
  'defaultSubtitleForced': 1,
  'watchedIndicator': 3,
  'mediaReviewsVisibility': 2,
};

List<Object?> _snapshot(AccountPreferences preferences) => [
  preferences.preferredAudioLanguage,
  preferences.playDefaultAudioTrack,
  preferences.preferredSubtitleLanguage,
  preferences.subtitlePlaybackMode,
  preferences.watchedIndicator,
  preferences.mediaReviewsVisibility,
  preferences.subtitleAccessibility,
  preferences.forcedSubtitles,
];
