import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/utils/play_deep_link.dart';

Profile _plexHome(String id, String uuid) => Profile.plexHome(
  id: id,
  displayName: id,
  parentConnectionId: 'conn',
  plexHomeUserUuid: uuid,
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  group('PlayDeepLink.parse', () {
    test('takes a bare shelf content id as is', () {
      final link = PlayDeepLink.parse('plezy_abc123_456');
      expect(link.contentId, 'plezy_abc123_456');
      expect(link.profile, isNull);
    });

    test('reads content id and profile from a play link', () {
      expect(PlayDeepLink.parse('plezy://play?content_id=plezy_abc123_456').contentId, 'plezy_abc123_456');
      expect(PlayDeepLink.parse('plezy://play?content_id=plezy_abc123_456').profile, isNull);

      final link = PlayDeepLink.parse('plezy://play?content_id=plezy_abc123_456&profile=0123456789abcdef');
      expect(link.contentId, 'plezy_abc123_456');
      expect(link.profile, '0123456789abcdef');
    });

    test('decodes the query and treats a blank profile as none', () {
      expect(
        PlayDeepLink.parse('plezy://play?content_id=plezy_abc_1&profile=plex-home-conn%3A1-0123456789abcdef').profile,
        'plex-home-conn:1-0123456789abcdef',
      );
      expect(PlayDeepLink.parse('plezy://play?content_id=plezy_abc_1&profile=%20').profile, isNull);
    });

    test('a play link without content id yields no content id', () {
      expect(PlayDeepLink.parse('plezy://play?profile=0123456789abcdef').contentId, isEmpty);
    });

    test('reads other links as bare content ids', () {
      expect(PlayDeepLink.parse('https://play?content_id=plezy_abc_1&profile=x').profile, isNull);
      expect(PlayDeepLink.parse('plezy://live?channel=4.1&profile=x').profile, isNull);
    });
  });

  group('resolveDeepLinkProfile', () {
    final max = _plexHome('plex-home-conn-aaaaaaaaaaaaaaaa', 'aaaaaaaaaaaaaaaa');
    final leo = _plexHome('plex-home-conn-bbbbbbbbbbbbbbbb', 'bbbbbbbbbbbbbbbb');
    final local = Profile.local(id: 'local-1', displayName: 'Guest', createdAt: DateTime(2026, 1, 1));
    final profiles = [max, leo, local];

    test('matches a Plex Home user uuid, ignoring case', () {
      expect(resolveDeepLinkProfile(profiles, 'bbbbbbbbbbbbbbbb'), leo);
      expect(resolveDeepLinkProfile(profiles, 'BBBBBBBBBBBBBBBB'), leo);
    });

    test('matches a Plezy profile id', () {
      expect(resolveDeepLinkProfile(profiles, 'plex-home-conn-aaaaaaaaaaaaaaaa'), max);
      expect(resolveDeepLinkProfile(profiles, 'local-1'), local);
    });

    test('returns null for unknown or ambiguous profiles', () {
      expect(resolveDeepLinkProfile(profiles, 'cccccccccccccccc'), isNull);
      final sameUserTwice = [max, _plexHome('plex-home-other-aaaaaaaaaaaaaaaa', 'aaaaaaaaaaaaaaaa')];
      expect(resolveDeepLinkProfile(sameUserTwice, 'aaaaaaaaaaaaaaaa'), isNull);
    });
  });
}
