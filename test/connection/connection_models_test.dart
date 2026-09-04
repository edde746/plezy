import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_browser_dialect.dart';

/// Backend-agnostic [Connection] model tests pin config round-trips and derived
/// kind/backend mappings; registry persistence is covered separately.
void main() {
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
          createdAt: base.createdAt,
          lastAuthenticatedAt: base.lastAuthenticatedAt,
        );

        expect(restored.primaryImageTag, isNull, reason: 'tag: "$tag"');
      }
    });

    test('fromConfigJson with empty payload uses safe defaults (no NPE)', () {
      final restored = JellyfinConnection.fromConfigJson(id: 'orphan', json: const {}, createdAt: DateTime.utc(2026));
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
      expect(base.dialect, MediaBrowserDialect.jellyfin);
      expect(base.kind, MediaBackend.jellyfin);
      expect(base.backend, MediaBackend.jellyfin);
    });

    test('an Emby dialect drives kind, backend and the persisted discriminator', () {
      final emby = base.copyWith(dialect: MediaBrowserDialect.emby);

      expect(emby.kind, MediaBackend.emby);
      expect(emby.kind.id, 'emby');
      expect(emby.backend, MediaBackend.emby);
      // The dialect lives in the `connections.kind` column, never in the
      // encrypted config payload, so exactly one discriminator is on disk.
      expect(emby.toConfigJson().containsKey('dialect'), isFalse);
    });

    test('fromConfigJson restores the dialect handed in by the registry', () {
      final restored = JellyfinConnection.fromConfigJson(
        id: 'srv-1/user-1',
        json: base.toConfigJson(),
        createdAt: base.createdAt,
        dialect: MediaBrowserDialect.emby,
      );

      expect(restored.dialect, MediaBrowserDialect.emby);
      expect(restored.kind, MediaBackend.emby);
      expect(restored.accessToken, 'tok-abc');
    });

    test('fromConfigJson defaults to Jellyfin for rows written before Emby support', () {
      final restored = JellyfinConnection.fromConfigJson(
        id: 'legacy',
        json: const {'baseUrl': 'https://jellyfin.example.com'},
        createdAt: DateTime.utc(2026),
      );

      expect(restored.dialect, MediaBrowserDialect.jellyfin);
      expect(restored.kind, MediaBackend.jellyfin);
    });

    test('empty-payload serverName falls back to the dialect product name', () {
      final emby = JellyfinConnection.fromConfigJson(
        id: 'orphan',
        json: const {},
        createdAt: DateTime.utc(2026),
        dialect: MediaBrowserDialect.emby,
      );

      expect(emby.serverName, 'Emby');
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
        createdAt: DateTime.utc(2026),
      );
      expect(restored.id, 'orphan');
      expect(restored.accountToken, '');
      expect(restored.accountLabel, 'Plex');
      expect(restored.servers, isEmpty);
    });

    test('kind and backend match Plex', () {
      expect(base.kind, MediaBackend.plex);
      expect(base.backend, MediaBackend.plex);
    });
  });
}
