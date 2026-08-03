import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/media/media_backend.dart';

/// Backend-agnostic [Connection] sealed-class tests. The
/// `connection_registry_test` already covers DB persistence; these focus on
/// the model layer's `toConfigJson` / `fromConfigJson` round-trip and the
/// derived `kind` / `backend` mappings — the bits the registry treats as a
/// black box.
void main() {
  group('ConnectionKind', () {
    test('id round-trips through fromId', () {
      for (final k in ConnectionKind.values) {
        expect(ConnectionKind.fromId(k.id), k);
      }
    });

    test('fromId throws on unknown id (no silent fallback)', () {
      expect(() => ConnectionKind.fromId('emby'), throwsA(isA<ArgumentError>()));
    });

    test('backend mapping is total', () {
      expect(ConnectionKind.plex.backend, MediaBackend.plex);
      expect(ConnectionKind.jellyfin.backend, MediaBackend.jellyfin);
    });
  });

  group('JellyfinConnection serialization', () {
    final base = JellyfinConnection(
      id: 'srv-1/user-1',
      baseUrl: 'https://jellyfin.example.com',
      baseUrls: const ['https://jellyfin.example.com', 'https://jellyfin.lan:8096'],
      serverName: 'Home',
      serverMachineId: 'srv-1',
      userId: 'user-1',
      userName: 'edde',
      accessToken: 'tok-abc',
      deviceId: 'dev-xyz',
      createdAt: DateTime.utc(2026, 1, 15),
      lastAuthenticatedAt: DateTime.utc(2026, 4, 25),
    );

    test('toConfigJson + fromConfigJson round-trip preserves every field', () {
      final json = base.toConfigJson();
      final restored = JellyfinConnection.fromConfigJson(
        id: base.id,
        json: json,
        status: base.status,
        createdAt: base.createdAt,
        lastAuthenticatedAt: base.lastAuthenticatedAt,
      );
      expect(restored.id, base.id);
      expect(restored.baseUrl, base.baseUrl);
      expect(restored.baseUrls, base.baseUrls);
      expect(restored.serverName, base.serverName);
      expect(restored.serverMachineId, base.serverMachineId);
      expect(restored.userId, base.userId);
      expect(restored.userName, base.userName);
      expect(restored.accessToken, base.accessToken);
      expect(restored.deviceId, base.deviceId);
      expect(restored.createdAt, base.createdAt);
      expect(restored.lastAuthenticatedAt, base.lastAuthenticatedAt);
    });

    test('primary image tag round-trips through config JSON', () {
      final tagged = base.copyWith(primaryImageTag: 'avatar-tag');
      final restored = JellyfinConnection.fromConfigJson(
        id: tagged.id,
        json: tagged.toConfigJson(),
        status: tagged.status,
        createdAt: tagged.createdAt,
        lastAuthenticatedAt: tagged.lastAuthenticatedAt,
      );

      expect(restored.primaryImageTag, 'avatar-tag');
    });

    test('config saved before image tags decodes with no primary image tag', () {
      final legacyJson = <String, Object?>{
        'baseUrl': base.baseUrl,
        'baseUrls': base.baseUrls,
        'serverName': base.serverName,
        'serverMachineId': base.serverMachineId,
        'userId': base.userId,
        'userName': base.userName,
        'accessToken': base.accessToken,
        'deviceId': base.deviceId,
        'isAdministrator': base.isAdministrator,
      };
      expect(legacyJson.containsKey('primaryImageTag'), isFalse);

      final restored = JellyfinConnection.fromConfigJson(
        id: base.id,
        json: legacyJson,
        status: base.status,
        createdAt: base.createdAt,
        lastAuthenticatedAt: base.lastAuthenticatedAt,
      );

      expect(restored.primaryImageTag, isNull);
    });

    test('blank persisted primary image tags decode as null', () {
      for (final tag in ['', ' \t\n ']) {
        final restored = JellyfinConnection.fromConfigJson(
          id: base.id,
          json: {...base.toConfigJson(), 'primaryImageTag': tag},
          status: base.status,
          createdAt: base.createdAt,
          lastAuthenticatedAt: base.lastAuthenticatedAt,
        );

        expect(restored.primaryImageTag, isNull, reason: 'tag: "$tag"');
      }
    });

    test('fromConfigJson with empty payload uses safe defaults (no NPE)', () {
      final restored = JellyfinConnection.fromConfigJson(
        id: 'orphan',
        json: const {},
        status: ConnectionStatus.unknown,
        createdAt: DateTime.utc(2026),
      );
      expect(restored.id, 'orphan');
      expect(restored.baseUrl, '');
      expect(restored.baseUrls, isEmpty);
      expect(restored.serverName, 'Jellyfin');
      expect(restored.accessToken, '');
    });

    test('fromConfigJson backfills baseUrls from legacy baseUrl', () {
      final restored = JellyfinConnection.fromConfigJson(
        id: 'legacy',
        json: const {
          'baseUrl': 'https://jellyfin.example.com',
          'serverName': 'Home',
          'serverMachineId': 'srv-1',
          'userId': 'user-1',
        },
        status: ConnectionStatus.unknown,
        createdAt: DateTime.utc(2026),
      );

      expect(restored.baseUrl, 'https://jellyfin.example.com');
      expect(restored.baseUrls, ['https://jellyfin.example.com']);
    });

    test('copyWith moves the active baseUrl to the front of baseUrls', () {
      final updated = base.copyWith(baseUrl: 'https://jellyfin.lan:8096');
      expect(updated.baseUrl, 'https://jellyfin.lan:8096');
      expect(updated.baseUrls, ['https://jellyfin.lan:8096', 'https://jellyfin.example.com']);
    });

    test('copyWith preserves an existing primary image tag by default', () {
      final tagged = base.copyWith(primaryImageTag: 'old');

      expect(tagged.copyWith().primaryImageTag, 'old');
    });

    test('copyWith replaces an existing primary image tag', () {
      final tagged = base.copyWith(primaryImageTag: 'old');

      expect(tagged.copyWith(primaryImageTag: 'new').primaryImageTag, 'new');
    });

    test('copyWith only clears a primary image tag through the clear sentinel', () {
      final tagged = base.copyWith(primaryImageTag: 'old');

      expect(tagged.copyWith(primaryImageTag: null).primaryImageTag, 'old');
      expect(tagged.copyWith(clearPrimaryImageTag: true).primaryImageTag, isNull);
    });

    test('reads primary image tags defensively from Jellyfin user DTOs', () {
      expect(JellyfinConnection.readPrimaryImageTag(const {'PrimaryImageTag': 'avatar-tag'}), 'avatar-tag');
      expect(JellyfinConnection.readPrimaryImageTag(const {}), isNull);
      expect(JellyfinConnection.readPrimaryImageTag(const {'PrimaryImageTag': ' \t\n '}), isNull);
      expect(JellyfinConnection.readPrimaryImageTag(const {'PrimaryImageTag': 42}), '42');
    });

    test('kind and backend match Jellyfin', () {
      expect(base.kind, ConnectionKind.jellyfin);
      expect(base.backend, MediaBackend.jellyfin);
    });
  });

  group('PlexAccountConnection serialization', () {
    final base = PlexAccountConnection(
      id: 'plex.client-uuid',
      accountToken: 'token-xyz',
      clientIdentifier: 'client-uuid',
      accountLabel: 'edde',
      servers: const [],
      activeProfile: null,
      createdAt: DateTime.utc(2026, 1, 15),
      lastAuthenticatedAt: DateTime.utc(2026, 4, 25),
    );

    test('toConfigJson + fromConfigJson round-trip preserves identity fields', () {
      final json = base.toConfigJson();
      final restored = PlexAccountConnection.fromConfigJson(
        id: base.id,
        json: json,
        status: base.status,
        createdAt: base.createdAt,
        lastAuthenticatedAt: base.lastAuthenticatedAt,
      );
      expect(restored.id, base.id);
      expect(restored.accountToken, base.accountToken);
      expect(restored.clientIdentifier, base.clientIdentifier);
      expect(restored.accountLabel, base.accountLabel);
      expect(restored.servers, isEmpty);
      expect(restored.activeProfile, isNull);
      expect(restored.createdAt, base.createdAt);
      expect(restored.lastAuthenticatedAt, base.lastAuthenticatedAt);
    });

    test('fromConfigJson with empty payload uses safe defaults (no NPE)', () {
      final restored = PlexAccountConnection.fromConfigJson(
        id: 'orphan',
        json: const {},
        status: ConnectionStatus.unknown,
        createdAt: DateTime.utc(2026),
      );
      expect(restored.id, 'orphan');
      expect(restored.accountToken, '');
      expect(restored.accountLabel, 'Plex');
      expect(restored.servers, isEmpty);
    });

    test('kind and backend match Plex', () {
      expect(base.kind, ConnectionKind.plex);
      expect(base.backend, MediaBackend.plex);
    });
  });
}
