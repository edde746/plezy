import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/plex/plex_switch_response.dart';

/// A realistic `/api/v2/home/users/{uuid}/switch` 201 body using the
/// July 2026 wire shape where profile language lists are CSV strings (#1488).
Map<String, dynamic> driftedSwitchJson() => {
  'id': 312174832,
  'uuid': 'e443d57860076fc3',
  'username': 'pl1624',
  'title': 'pl1624',
  'email': 'user@example.com',
  'friendlyName': '',
  'locale': null,
  'confirmed': true,
  'joinedAt': 1703877982,
  'emailOnlyAuth': false,
  'hasPassword': true,
  'protected': true,
  'thumb': 'https://plex.tv/users/e443d57860076fc3/avatar',
  'authToken': 'minted-user-token',
  'mailingListActive': false,
  'scrobbleTypes': '',
  'country': 'SE',
  'restricted': false,
  'anonymous': false,
  'home': true,
  'guest': false,
  'homeSize': 2,
  'homeAdmin': true,
  'maxHomeSize': 15,
  'profile': {
    'autoSelectAudio': true,
    'defaultAudioAccessibility': 0,
    'defaultAudioLanguage': 'en',
    'defaultAudioLanguages': 'en,sv',
    'defaultSubtitleLanguage': 'en',
    'defaultSubtitleLanguages': 'en,sv',
    'autoSelectSubtitle': 1,
    'defaultSubtitleAccessibility': 0,
    'defaultSubtitleForced': 1,
    'watchedIndicator': 1,
    'mediaReviewsVisibility': 0,
    'mediaReviewsLanguages': null,
    'mediaPostsVisibility': true,
  },
  'twoFactorEnabled': false,
  'backupCodesCreated': false,
  'attributionPartner': null,
};

void main() {
  group('parsePlexSwitchAuthToken', () {
    test('takes the token out of a realistic drifted 201 body', () {
      expect(parsePlexSwitchAuthToken(driftedSwitchJson()), 'minted-user-token');
    });

    test('takes the token out of a token-only body', () {
      expect(parsePlexSwitchAuthToken({'authToken': 'tok'}), 'tok');
    });

    test('never loses the token to wrong-typed decorative fields', () {
      final token = parsePlexSwitchAuthToken({
        'authToken': 'tok',
        'id': {},
        'uuid': 42,
        'title': 7,
        'confirmed': 'yes',
        'joinedAt': {},
        'hasPassword': 'nope',
        'protected': [],
        'thumb': 1.5,
        'homeSize': 'many',
        'maxHomeSize': null,
        'profile': 'garbage',
        'twoFactorEnabled': {},
      });

      expect(token, 'tok');
    });

    test('throws when authToken is missing, empty, or not a string', () {
      expect(() => parsePlexSwitchAuthToken(const {}), throwsFormatException);
      expect(() => parsePlexSwitchAuthToken({'authToken': ''}), throwsFormatException);
      expect(() => parsePlexSwitchAuthToken({'authToken': 12345}), throwsFormatException);
    });
  });
}
