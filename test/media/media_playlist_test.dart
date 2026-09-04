import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_playlist.dart';

/// Backend-agnostic [MediaPlaylist] tests pin the neutral model's getters
/// separately from mapper coverage. The model uses identity equality, so these
/// tests intentionally avoid equality assertions.
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
  group('MediaPlaylist.displayImagePath', () {
    test('prefers the user-assigned thumbPath over compositeImagePath', () {
      final pl = _playlist(compositeImagePath: '/composite/grid', thumbPath: '/thumb/single');
      expect(pl.displayImagePath, '/thumb/single');
    });

    test('falls back to compositeImagePath when thumb is null', () {
      final pl = _playlist(compositeImagePath: '/composite/grid', thumbPath: null);
      expect(pl.displayImagePath, '/composite/grid');
    });

    test('is null when both are null', () {
      final pl = _playlist(compositeImagePath: null, thumbPath: null);
      expect(pl.displayImagePath, isNull);
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
      expect(minimal.globalKey, 'pl');
    });
  });
}
