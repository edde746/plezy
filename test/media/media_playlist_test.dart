import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_playlist.dart';

/// Backend-agnostic [MediaPlaylist] tests. Mappers (`plex_mappers_test` /
/// `jellyfin_mappers_test`) cover JSON → model translation; this file pins
/// the neutral model's surface so a future mapper swap can't silently
/// regress its derived getters.
///
/// Note: [MediaPlaylist] does **not** override `==` / `hashCode`, so this
/// file deliberately avoids equality tests that would exercise default
/// identity behavior.
MediaPlaylist _playlist({
  String id = 'pl1',
  MediaBackend backend = MediaBackend.plex,
  String title = 'My Playlist',
  String playlistType = 'video',
  bool smart = false,
  String? compositeImagePath,
  String? thumbPath,
  String? serverId = 's1',
}) => MediaPlaylist(
  id: id,
  backend: backend,
  title: title,
  playlistType: playlistType,
  smart: smart,
  compositeImagePath: compositeImagePath,
  thumbPath: thumbPath,
  serverId: serverId,
);

void main() {
  group('MediaPlaylist.copyWith', () {
    test('returns an equivalent copy when no overrides are passed', () {
      final original = _playlist(
        id: 'pl-original',
        title: 'Original',
        compositeImagePath: '/library/metadata/123/composite/1700000000',
        thumbPath: '/library/metadata/123/thumb',
        serverId: 's-original',
      );
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.backend, original.backend);
      expect(copy.title, original.title);
      expect(copy.playlistType, original.playlistType);
      expect(copy.compositeImagePath, original.compositeImagePath);
      expect(copy.thumbPath, original.thumbPath);
      expect(copy.serverId, original.serverId);
    });

    test('overrides apply to the copy without mutating the source', () {
      final original = _playlist(title: 'Original', smart: false);
      final renamed = original.copyWith(title: 'Renamed', smart: true);
      expect(renamed.title, 'Renamed');
      expect(renamed.smart, isTrue);
      // Source untouched — copyWith must be non-mutating.
      expect(original.title, 'Original');
      expect(original.smart, isFalse);
    });

    test('every nullable field can be overridden', () {
      final original = _playlist();
      final fully = original.copyWith(
        id: 'new-id',
        backend: MediaBackend.jellyfin,
        title: 'New Title',
        summary: 'A new summary',
        guid: 'plex://playlist/abc',
        smart: true,
        playlistType: 'audio',
        durationMs: 1234567,
        leafCount: 42,
        viewCount: 7,
        addedAt: 1700000000,
        updatedAt: 1700001000,
        lastViewedAt: 1700002000,
        compositeImagePath: '/composite/x',
        thumbPath: '/thumb/x',
        serverId: 'new-server',
        serverName: 'New Server',
      );
      expect(fully.id, 'new-id');
      expect(fully.backend, MediaBackend.jellyfin);
      expect(fully.title, 'New Title');
      expect(fully.summary, 'A new summary');
      expect(fully.guid, 'plex://playlist/abc');
      expect(fully.smart, isTrue);
      expect(fully.playlistType, 'audio');
      expect(fully.durationMs, 1234567);
      expect(fully.leafCount, 42);
      expect(fully.viewCount, 7);
      expect(fully.addedAt, 1700000000);
      expect(fully.updatedAt, 1700001000);
      expect(fully.lastViewedAt, 1700002000);
      expect(fully.compositeImagePath, '/composite/x');
      expect(fully.thumbPath, '/thumb/x');
      expect(fully.serverId, 'new-server');
      expect(fully.serverName, 'New Server');
    });
  });

  group('MediaPlaylist.displayImagePath', () {
    test('prefers compositeImagePath over thumbPath', () {
      final pl = _playlist(compositeImagePath: '/composite/grid', thumbPath: '/thumb/single');
      expect(pl.displayImagePath, '/composite/grid');
    });

    test('falls back to thumbPath when composite is null', () {
      final pl = _playlist(compositeImagePath: null, thumbPath: '/thumb/single');
      expect(pl.displayImagePath, '/thumb/single');
    });

    test('is null when both are null', () {
      final pl = _playlist(compositeImagePath: null, thumbPath: null);
      expect(pl.displayImagePath, isNull);
    });
  });

  group('MediaPlaylist.displayTitle', () {
    test('is an alias of title', () {
      final pl = _playlist(title: 'Anything');
      expect(pl.displayTitle, 'Anything');
      expect(pl.displayTitle, pl.title);
    });
  });

  group('MediaPlaylist.isEditable', () {
    test('smart playlists are read-only (Plex semantics)', () {
      expect(_playlist(smart: true).isEditable, isFalse);
    });

    test('manual playlists are editable', () {
      expect(_playlist(smart: false).isEditable, isTrue);
    });
  });

  group('MediaPlaylist.globalKey', () {
    test('uses "<serverId>:<id>" when serverId is set', () {
      final pl = _playlist(id: 'pl-42', serverId: 'srv-9');
      expect(pl.globalKey, 'srv-9:pl-42');
    });

    test('falls back to bare id when serverId is null', () {
      final pl = _playlist(id: 'pl-42', serverId: null);
      expect(pl.globalKey, 'pl-42');
    });
  });

  group('MediaPlaylist construction', () {
    test('tolerates all-optional fields being null', () {
      final minimal = MediaPlaylist(id: 'pl', backend: MediaBackend.plex, title: 'Min', playlistType: 'video');
      expect(minimal.summary, isNull);
      expect(minimal.guid, isNull);
      expect(minimal.smart, isFalse);
      expect(minimal.durationMs, isNull);
      expect(minimal.leafCount, isNull);
      expect(minimal.viewCount, isNull);
      expect(minimal.addedAt, isNull);
      expect(minimal.updatedAt, isNull);
      expect(minimal.lastViewedAt, isNull);
      expect(minimal.compositeImagePath, isNull);
      expect(minimal.thumbPath, isNull);
      expect(minimal.serverId, isNull);
      expect(minimal.serverName, isNull);
      expect(minimal.displayImagePath, isNull);
      expect(minimal.displayTitle, 'Min');
      expect(minimal.isEditable, isTrue);
      // Without a serverId, globalKey reduces to the bare id.
      expect(minimal.globalKey, 'pl');
    });
  });
}
