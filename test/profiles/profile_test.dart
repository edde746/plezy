import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/profiles/profile.dart';

void main() {
  group('Profile', () {
    test('local profile defaults', () {
      final p = Profile.local(id: 'local-1', displayName: 'Owner', createdAt: DateTime(2026, 1, 1));
      expect(p.isLocal, isTrue);
      expect(p.isPlexHome, isFalse);
      expect(p.isPinProtected, isFalse);
      expect(p.parentConnectionId, isNull);
    });

    test('local profile with PIN is pin-protected', () {
      final p = Profile.local(
        id: 'local-1',
        displayName: 'Kids',
        pinHash: computePinHash('1234'),
        createdAt: DateTime(2026, 1, 1),
      );
      expect(p.isPinProtected, isTrue);
    });

    test('plex_home profile pin protection follows the protected flag', () {
      final p = Profile.plexHome(
        id: 'plex-home-acct1-uuid1',
        displayName: 'Sarah',
        parentConnectionId: 'acct1',
        plexProtected: true,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(p.isLocal, isFalse);
      expect(p.isPinProtected, isTrue);
    });

    test('local PIN hash is round-tripped via configJson', () {
      final p = Profile.local(
        id: 'local-1',
        displayName: 'Kids',
        pinHash: computePinHash('1234'),
        createdAt: DateTime(2026, 1, 1),
      );
      final json = p.toConfigJson();
      final restored = Profile.fromRow(
        id: p.id,
        kind: 'local',
        displayName: p.displayName,
        avatarThumbUrl: null,
        json: json,
        sortOrder: 0,
        createdAt: p.createdAt,
        lastUsedAt: null,
      );
      expect(restored.pinHash, p.pinHash);
      expect(restored.isPinProtected, isTrue);
    });

    test('plex_home configJson round-trips with all flags', () {
      final p = Profile.plexHome(
        id: 'plex-home-acct1-uuid1',
        displayName: 'Admin',
        parentConnectionId: 'acct1',
        plexAdmin: true,
        plexRestricted: false,
        plexProtected: true,
        createdAt: DateTime(2026, 1, 1),
      );
      final json = p.toConfigJson();
      final restored = Profile.fromRow(
        id: p.id,
        kind: 'plex_home',
        displayName: p.displayName,
        avatarThumbUrl: null,
        json: json,
        sortOrder: 0,
        createdAt: p.createdAt,
        lastUsedAt: null,
      );
      expect(restored.plexAdmin, isTrue);
      expect(restored.plexRestricted, isFalse);
      expect(restored.plexProtected, isTrue);
      expect(restored.parentConnectionId, 'acct1');
    });

    test('plexHomeProfileId is deterministic', () {
      expect(plexHomeProfileId(accountConnectionId: 'plex.dev1', homeUserUuid: 'uuid-1'), 'plex-home-plex.dev1-uuid-1');
    });

    test('parsePlexHomeProfileId round-trips a real 16-hex uuid', () {
      // Real plex.tv home-user uuids are 16-char plain hex, and the account
      // connection id itself usually ends in one (plex.{accountUuid}).
      const acct = 'plex.e443d57860076fc3';
      const uuid = '379704d0c6601309';
      final id = plexHomeProfileId(accountConnectionId: acct, homeUserUuid: uuid);
      final parsed = parsePlexHomeProfileId(id);
      expect(parsed, isNotNull);
      expect(parsed!.accountConnectionId, acct);
      expect(parsed.homeUserUuid, uuid);
    });

    test('parsePlexHomeProfileId round-trips a hyphenated RFC-4122 uuid', () {
      // Defensive alternate shape; accountConnectionId can carry hyphens too
      // (e.g. plex.client-id).
      const acct = 'plex.client-id-123';
      const uuid = 'a1b2c3d4-e5f6-7890-abcd-ef0123456789';
      final id = plexHomeProfileId(accountConnectionId: acct, homeUserUuid: uuid);
      final parsed = parsePlexHomeProfileId(id);
      expect(parsed, isNotNull);
      expect(parsed!.accountConnectionId, acct);
      expect(parsed.homeUserUuid, uuid);
    });

    test('parsePlexHomeProfileId splits at the last uuid-shaped segment', () {
      // A hex-ending account id must not steal the uuid slot: the $ anchor
      // forces the trailing segment to be the home-user uuid.
      const acct = 'acct-aaaaaaaaaaaaaaaa';
      const uuid = 'bbbbbbbbbbbbbbbb';
      final parsed = parsePlexHomeProfileId(plexHomeProfileId(accountConnectionId: acct, homeUserUuid: uuid));
      expect(parsed, isNotNull);
      expect(parsed!.accountConnectionId, acct);
      expect(parsed.homeUserUuid, uuid);
    });

    test('parsePlexHomeProfileId rejects non-Plex-Home ids', () {
      expect(parsePlexHomeProfileId('local-1'), isNull);
      expect(parsePlexHomeProfileId('plex-home-only'), isNull);
      expect(parsePlexHomeProfileId('plex-home-acct-not-a-uuid'), isNull);
      // 15 and 17 hex chars are not uuids.
      expect(parsePlexHomeProfileId('plex-home-acct-aaaaaaaaaaaaaaa'), isNull);
      expect(parsePlexHomeProfileId('plex-home-acct-aaaaaaaaaaaaaaaaa'), isNull);
    });
  });

  group('PIN hashing', () {
    test('computePinHash is deterministic for the same input', () {
      expect(computePinHash('1234'), computePinHash('1234'));
    });

    test('computePinHash differs for different inputs', () {
      expect(computePinHash('1234'), isNot(computePinHash('5678')));
    });

    test('verifyPin matches its hash', () {
      final h = computePinHash('4242');
      expect(verifyPin('4242', h), isTrue);
      expect(verifyPin('1111', h), isFalse);
    });
  });
}
