import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/services/credential_vault.dart';

import '../test_helpers/prefs.dart';

void main() {
  setUp(resetSharedPreferencesForTest);

  group('SeerrConnection', () {
    test('round-trips via toConfigJson + fromConfigJson', () {
      final original = SeerrConnection(
        id: 'seerr-host-7',
        baseUrl: 'https://requests.example.com',
        instanceLabel: 'My Seerr',
        jellyfinUsername: 'edde',
        jellyfinPassword: 'pw',
        sessionCookie: 'abc.def',
        sessionCookieCapturedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        seerrUserId: 7,
        seerrUserType: 4,
        permissions: 8,
        avatarUrl: 'https://example.com/a.png',
        status: ConnectionStatus.online,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        lastAuthenticatedAt: DateTime.fromMillisecondsSinceEpoch(123),
      );
      final restored = SeerrConnection.fromConfigJson(
        id: original.id,
        json: original.toConfigJson(),
        status: ConnectionStatus.online,
        createdAt: original.createdAt,
        lastAuthenticatedAt: original.lastAuthenticatedAt,
      );
      expect(restored.baseUrl, original.baseUrl);
      expect(restored.instanceLabel, original.instanceLabel);
      expect(restored.jellyfinUsername, original.jellyfinUsername);
      expect(restored.jellyfinPassword, original.jellyfinPassword);
      expect(restored.sessionCookie, original.sessionCookie);
      expect(restored.sessionCookieCapturedAt, original.sessionCookieCapturedAt);
      expect(restored.seerrUserId, original.seerrUserId);
      expect(restored.permissions, original.permissions);
      expect(restored.avatarUrl, original.avatarUrl);
    });

    test('CredentialVault encrypts sessionCookie and jellyfinPassword for seerr kind', () async {
      final config = <String, Object?>{
        'baseUrl': 'https://requests.example.com',
        'instanceLabel': 'Seerr',
        'jellyfinUsername': 'edde',
        'jellyfinPassword': 'plain-password',
        'sessionCookie': 'plain-cookie',
        'sessionCookieCapturedAt': 0,
        'seerrUserId': 1,
        'seerrUserType': 4,
        'permissions': 0,
        'avatarUrl': null,
      };
      final protected = await CredentialVault.protectConnectionConfig('seerr', config);
      expect(CredentialVault.isProtected(protected['jellyfinPassword'] as String), isTrue);
      expect(CredentialVault.isProtected(protected['sessionCookie'] as String), isTrue);
      expect(protected['baseUrl'], 'https://requests.example.com');

      final revealed = await CredentialVault.revealConnectionConfig('seerr', Map<String, dynamic>.from(protected));
      expect(revealed.config['jellyfinPassword'], 'plain-password');
      expect(revealed.config['sessionCookie'], 'plain-cookie');
      expect(revealed.migrated, isFalse);
    });

    test('reading legacy plaintext flags migrated=true', () async {
      final legacy = <String, dynamic>{
        'baseUrl': 'https://requests.example.com',
        'instanceLabel': 'Seerr',
        'jellyfinUsername': 'edde',
        'jellyfinPassword': 'plain',
        'sessionCookie': 'plain',
        'sessionCookieCapturedAt': 0,
        'seerrUserId': 1,
        'seerrUserType': 4,
        'permissions': 0,
        'avatarUrl': null,
      };
      final revealed = await CredentialVault.revealConnectionConfig('seerr', legacy);
      expect(revealed.migrated, isTrue);
      expect(revealed.config['jellyfinPassword'], 'plain');
      expect(revealed.config['sessionCookie'], 'plain');
    });

    test('toConfigJson is JSON-encodable', () {
      final conn = SeerrConnection(
        id: 'x',
        baseUrl: 'https://x',
        instanceLabel: 'x',
        jellyfinUsername: 'x',
        jellyfinPassword: 'x',
        sessionCookie: 'x',
        seerrUserId: 1,
        seerrUserType: 4,
        permissions: 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
      expect(() => jsonEncode(conn.toConfigJson()), returnsNormally);
    });

    test('ConnectionKind.seerr.isMediaBackend is false', () {
      expect(ConnectionKind.seerr.isMediaBackend, isFalse);
      expect(ConnectionKind.plex.isMediaBackend, isTrue);
      expect(ConnectionKind.jellyfin.isMediaBackend, isTrue);
    });

    test('SeerrConnection.backend throws StateError', () {
      final conn = SeerrConnection(
        id: 'x',
        baseUrl: 'https://x',
        instanceLabel: 'x',
        jellyfinUsername: 'x',
        jellyfinPassword: 'x',
        sessionCookie: 'x',
        seerrUserId: 1,
        seerrUserType: 4,
        permissions: 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
      expect(() => conn.backend, throwsStateError);
      expect(conn.isMediaBackend, isFalse);
    });
  });
}
