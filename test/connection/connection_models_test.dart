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
      expect(restored.serverName, base.serverName);
      expect(restored.serverMachineId, base.serverMachineId);
      expect(restored.userId, base.userId);
      expect(restored.userName, base.userName);
      expect(restored.accessToken, base.accessToken);
      expect(restored.deviceId, base.deviceId);
      expect(restored.createdAt, base.createdAt);
      expect(restored.lastAuthenticatedAt, base.lastAuthenticatedAt);
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
      expect(restored.serverName, 'Jellyfin');
      expect(restored.accessToken, '');
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
