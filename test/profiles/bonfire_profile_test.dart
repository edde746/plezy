import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/jellyfin/bonfire_profile.dart';

BonfireProfile _profile([Map<String, dynamic>? overrides]) {
  return BonfireProfile.fromJson({
    'profileUserId': 'a90f11cb-42a1-432d-94bb-97cc2d42ef8b',
    'profileName': 'Kids',
    'avatarInitial': 'K',
    'avatarColor': '#7c4dff',
    'transparentAvatar': false,
    'requiresPin': true,
    'hasPin': true,
    'isMaster': false,
    'isAdministrator': false,
    'lockoutMinutes': 15,
    'bypassPinOnLocalNetwork': true,
    'allowedDeviceIds': ['device-1'],
    'isBonfire': false,
    'profileImage': '/plugins/profiles/image/a90f11cb?v=3',
    'masterUserId': '11111111-2222-3333-4444-555555555555',
    ...?overrides,
  });
}

void main() {
  group('BonfireProfile.fromJson', () {
    test('parses the documented /list shape', () {
      final profile = _profile();
      expect(profile.profileUserId, 'a90f11cb-42a1-432d-94bb-97cc2d42ef8b');
      expect(profile.profileName, 'Kids');
      expect(profile.requiresPin, isTrue);
      expect(profile.hasPin, isTrue);
      expect(profile.isMaster, isFalse);
      expect(profile.bypassPinOnLocalNetwork, isTrue);
      expect(profile.allowedDeviceIds, ['device-1']);
      expect(profile.masterUserId, '11111111-2222-3333-4444-555555555555');
    });

    test('tolerates stringified booleans and ints from drifted servers', () {
      final profile = _profile({
        'requiresPin': 'true',
        'hasPin': 0,
        'lockoutMinutes': '30',
        'allowedDeviceIds': null,
      });
      expect(profile.requiresPin, isTrue);
      expect(profile.hasPin, isFalse);
      expect(profile.lockoutMinutes, 30);
      expect(profile.allowedDeviceIds, isEmpty);
    });

    test('missing optional fields fall back to safe defaults', () {
      final json = BonfireProfile.fromJson({
        'profileUserId': 'u-1',
        'profileName': 'Solo',
        'masterUserId': 'm-1',
      });
      expect(json.requiresPin, isFalse);
      expect(json.profileImage, isNull);
      expect(json.allowedDeviceIds, isEmpty);
    });
  });

  group('imageUrlFor', () {
    const base = 'https://jellyfin.example.net';

    test('resolves plugin-relative stored images against the server base', () {
      final url = _profile().imageUrlFor(base);
      expect(url, '$base/plugins/profiles/image/a90f11cb?v=3&size=thumb');
    });

    test('passes pasted absolute URLs through untouched', () {
      final profile = _profile({'profileImage': 'https://cdn.example.com/kids.png'});
      expect(profile.imageUrlFor(base), 'https://cdn.example.com/kids.png');
    });

    test('omits the thumb size when thumb is false or already requested', () {
      expect(_profile().imageUrlFor(base, thumb: false), '$base/plugins/profiles/image/a90f11cb?v=3');
      final withSize = _profile({'profileImage': '/plugins/profiles/image/x?size=thumb'});
      expect(withSize.imageUrlFor(base), '$base/plugins/profiles/image/x?size=thumb');
    });

    test('null image stays null', () {
      expect(_profile({'profileImage': null}).imageUrlFor(base), isNull);
    });
  });

  group('equality', () {
    test('identical payloads are equal for stream diffing', () {
      expect(_profile(), _profile());
      expect(_profile().allowedDeviceIds, _profile().allowedDeviceIds);
    });

    test('a changed flag or list is not equal', () {
      expect(_profile(), isNot(_profile({'requiresPin': false})));
      expect(_profile(), isNot(_profile({'allowedDeviceIds': ['device-2']})));
    });
  });
}
