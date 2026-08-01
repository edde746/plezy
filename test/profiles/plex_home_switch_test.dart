import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/profiles/plex_home_switch.dart';
import 'package:plezy/services/plex_auth_service.dart';
import 'package:plezy/utils/media_server_http_client.dart';

/// Regression for #1488: Plex started returning profile language lists as CSV
/// strings ("en,sv") instead of arrays; the parse crash on the 201 /switch
/// response made the flow report failure and drop the freshly minted token,
/// leaving the app permanently offline.
void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  PlexAuthService authReturning(MockClient mock) {
    final client = MediaServerHttpClient(client: mock);
    addTearDown(client.close);
    return PlexAuthService.forTesting(http: client);
  }

  group('switchPlexHomeUserWithPin', () {
    test('succeeds and keeps the token when the 201 body has drifted field shapes', () async {
      final auth = authReturning(
        MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v2/home/users/uuid-1/switch');
          return http.Response(jsonEncode(_driftedSwitchBody()), 201, headers: {'content-type': 'application/json'});
        }),
      );

      final result = await switchPlexHomeUserWithPin(
        auth: auth,
        accountToken: 'account-token',
        homeUserUuid: 'uuid-1',
        requiresPin: false,
        promptForPin: ({String? errorMessage}) async => fail('should not prompt'),
      );

      expect(result.status, PlexHomeSwitchStatus.success);
      expect(result.userToken, 'minted-user-token');
    });

    test('re-prompts on Plex error 1041 and succeeds with the corrected PIN', () async {
      var attempts = 0;
      final auth = authReturning(
        MockClient((request) async {
          attempts++;
          if (attempts == 1) {
            return http.Response(
              jsonEncode({
                'errors': [
                  {'code': 1041, 'message': 'Invalid PIN', 'status': 403},
                ],
              }),
              403,
              headers: {'content-type': 'application/json'},
            );
          }
          expect(request.url.queryParameters['pin'], '1234');
          return http.Response(jsonEncode(_driftedSwitchBody()), 201, headers: {'content-type': 'application/json'});
        }),
      );

      final promptErrors = <String?>[];
      final result = await switchPlexHomeUserWithPin(
        auth: auth,
        accountToken: 'account-token',
        homeUserUuid: 'uuid-1',
        requiresPin: false,
        promptForPin: ({String? errorMessage}) async {
          promptErrors.add(errorMessage);
          return '1234';
        },
      );

      expect(result.status, PlexHomeSwitchStatus.success);
      expect(result.userToken, 'minted-user-token');
      expect(attempts, 2);
      expect(promptErrors, hasLength(1));
      expect(promptErrors.single, isNotNull);
    });

    test('reports cancelled when the user dismisses the PIN prompt', () async {
      final auth = authReturning(
        MockClient((request) async {
          return http.Response(
            jsonEncode({
              'errors': [
                {'code': 1041, 'message': 'Invalid PIN', 'status': 403},
              ],
            }),
            403,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final result = await switchPlexHomeUserWithPin(
        auth: auth,
        accountToken: 'account-token',
        homeUserUuid: 'uuid-1',
        requiresPin: false,
        promptForPin: ({String? errorMessage}) async => null,
      );

      expect(result.status, PlexHomeSwitchStatus.cancelled);
      expect(result.userToken, isNull);
    });

    test('reports failed when the response has no token', () async {
      final auth = authReturning(
        MockClient((request) async {
          return http.Response(
            jsonEncode({'id': 1, 'uuid': 'uuid-1'}),
            201,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final result = await switchPlexHomeUserWithPin(
        auth: auth,
        accountToken: 'account-token',
        homeUserUuid: 'uuid-1',
        requiresPin: false,
        promptForPin: ({String? errorMessage}) async => fail('should not prompt'),
      );

      expect(result.status, PlexHomeSwitchStatus.failed);
      expect(result.userToken, isNull);
    });
  });
}

Map<String, dynamic> _driftedSwitchBody() => {
  'id': 312174832,
  'uuid': 'uuid-1',
  'title': 'hi_phi',
  'authToken': 'minted-user-token',
  'protected': true,
  'home': true,
  'profile': {
    'defaultAudioLanguage': 'en',
    'defaultAudioLanguages': 'en,sv',
    'defaultSubtitleLanguage': 'en',
    'defaultSubtitleLanguages': 'en,sv',
    'mediaReviewsLanguages': null,
    'mediaPostsVisibility': true,
  },
};
