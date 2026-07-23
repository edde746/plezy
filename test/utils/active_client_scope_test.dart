import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/utils/active_client_scope.dart';

void main() {
  final serverId = ServerId('jf-machine');

  group('resolveActiveClientScopeId', () {
    test('returns null before a client is bound', () {
      expect(resolveActiveClientScopeId(serverId: serverId, cacheServerId: null), isNull);
    });

    test('rejects an empty cache scope', () {
      expect(resolveActiveClientScopeId(serverId: serverId, cacheServerId: ''), isNull);
    });

    test('rejects the bare server scope', () {
      expect(resolveActiveClientScopeId(serverId: serverId, cacheServerId: 'jf-machine'), isNull);
    });

    test('rejects empty and foreign compound scopes', () {
      expect(resolveActiveClientScopeId(serverId: serverId, cacheServerId: 'jf-machine/'), isNull);
      expect(resolveActiveClientScopeId(serverId: serverId, cacheServerId: 'other-machine/user-a'), isNull);
    });

    test('keeps users on the same server in distinct active scopes', () {
      expect(resolveActiveClientScopeId(serverId: serverId, cacheServerId: 'jf-machine/user-a'), 'jf-machine/user-a');
      expect(resolveActiveClientScopeId(serverId: serverId, cacheServerId: 'jf-machine/user-b'), 'jf-machine/user-b');
    });
  });
  group('Plex profile scopes', () {
    final plexServerId = ServerId('plex-machine');

    test('are typed, deterministic, profile-specific, and publicly projected', () {
      final profileA = buildPlexProfileScopeId(serverId: plexServerId, profileId: 'profile-a');
      final profileB = buildPlexProfileScopeId(serverId: plexServerId, profileId: 'profile-b');

      expect(profileA, buildPlexProfileScopeId(serverId: plexServerId, profileId: 'profile-a'));
      expect(profileA, isNot(profileB));
      expect(profileA.publicServerId, plexServerId);
      expect(profileA.profileId, 'profile-a');
      expect(profileA.cacheServerId, ServerId(profileA));
      expect(publicPlexServerIdFromScope(profileA), plexServerId);
      expect(resolveActiveClientScopeId(serverId: plexServerId, cacheServerId: profileA), profileA);
    });

    test('encodes profile ids and cannot be interpreted as Jellyfin scope', () {
      final scope = buildPlexProfileScopeId(serverId: plexServerId, profileId: 'profile/a');

      expect(scope.profileId, 'profile/a');
      expect(isPlexProfileScopeId(scope), isTrue);
      expect(isJellyfinUserScopeId(serverId: plexServerId, cacheServerId: scope), isFalse);
      expect(publicPlexServerIdFromScope('plex-machine/user-a'), isNull);
    });

    test('rejects malformed persisted server prefixes before getters can throw', () {
      const malformed = '   /~plex-profile/profile-a';

      final scope = PlexProfileScopeId.tryParse(malformed);

      expect(scope, isNull);
      expect(publicPlexServerIdFromScope(malformed), isNull);
      expect(isPlexProfileScopeId(malformed), isFalse);
    });
  });
}
