import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/user_switch_response.dart';

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
  group('UserSwitchResponse.fromJson', () {
    test('parses a realistic drifted 201 body, preserving the token', () {
      final response = UserSwitchResponse.fromJson(driftedSwitchJson());

      expect(response.authToken, 'minted-user-token');
      expect(response.uuid, 'e443d57860076fc3');
      expect(response.protected, isTrue);
      expect(response.homeAdmin, isTrue);
      expect(response.profile.defaultAudioLanguages, ['en', 'sv']);
      expect(response.profile.defaultSubtitleLanguages, ['en', 'sv']);
    });

    test('parses a token-only body with defaults everywhere else', () {
      final response = UserSwitchResponse.fromJson({'authToken': 'tok'});

      expect(response.authToken, 'tok');
      expect(response.id, 0);
      expect(response.uuid, '');
      expect(response.title, '');
      expect(response.confirmed, isFalse);
      expect(response.homeSize, 1);
      expect(response.maxHomeSize, 1);
      expect(response.profile.autoSelectAudio, isTrue);
      expect(response.profile.defaultAudioLanguages, isNull);
    });

    test('never loses the token to wrong-typed decorative fields', () {
      final response = UserSwitchResponse.fromJson({
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

      expect(response.authToken, 'tok');
      expect(response.id, 0);
      expect(response.uuid, '42');
      expect(response.title, '7');
      expect(response.confirmed, isFalse);
      expect(response.homeSize, 1);
      expect(response.profile.autoSelectAudio, isTrue);
      expect(response.profile.defaultAudioLanguages, isNull);
    });

    test('throws when authToken is missing, empty, or not a string', () {
      expect(() => UserSwitchResponse.fromJson(const {}), throwsFormatException);
      expect(() => UserSwitchResponse.fromJson({'authToken': ''}), throwsFormatException);
      expect(() => UserSwitchResponse.fromJson({'authToken': 12345}), throwsFormatException);
    });
  });
}
