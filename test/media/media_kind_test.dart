import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_item_types.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_part.dart';
import 'package:plezy/media/media_version.dart';

import '../test_helpers/media_items.dart';

void main() {
  group('photo kinds', () {
    test('a MediaBrowser PhotoAlbum and a Plex-style photo parse to their own kinds', () {
      expect(MediaKind.fromString('PhotoAlbum'), MediaKind.photoAlbum);
      expect(MediaKind.fromString('Photo'), MediaKind.photo);
    });

    test('only photos and albums count as photo content', () {
      expect(MediaKind.photo.isPhotoContent, isTrue);
      expect(MediaKind.photoAlbum.isPhotoContent, isTrue);
      expect(MediaKind.clip.isPhotoContent, isFalse);
      expect(MediaKind.album.isPhotoContent, isFalse);
    });

    test('photo albums are neither playable nor file-backed and have no leaf counts', () {
      expect(MediaKind.photoAlbum.isPlayable, isFalse);
      expect(MediaKind.photoAlbum.hasFileInfo, isFalse);
      expect(MediaKind.photoAlbum.usesLeafWatchCounts, isFalse);
    });

    test('a photo album has a lowercase id that parses back', () {
      expect(MediaKind.photoAlbum.id, 'photoalbum');
      expect(MediaKind.fromString(MediaKind.photoAlbum.id), MediaKind.photoAlbum);
    });

    test('a photo album survives the MediaItem JSON round trip', () {
      final album = testMediaItem(id: 'album-1', kind: MediaKind.photoAlbum, title: 'Album');

      expect(MediaItem.fromJson(album.toJson()).kind, MediaKind.photoAlbum);
    });
  });

  group('photoImagePath', () {
    const versions = [
      MediaVersion(
        id: '1',
        parts: [MediaPart(id: 'p1', streamPath: '/library/parts/1/2/photo.jpg')],
      ),
    ];

    test('a Plex photo uses its file', () {
      final photo = testMediaItem(kind: MediaKind.photo, thumbPath: '/thumb').copyWith(mediaVersions: versions);

      expect(photo.photoImagePath, '/library/parts/1/2/photo.jpg');
    });

    test('a Plex photo without Media falls back to its thumb', () {
      final photo = testMediaItem(kind: MediaKind.photo, thumbPath: '/thumb');

      expect(photo.photoImagePath, '/thumb');
    });

    test('a MediaBrowser photo ignores the video stream route in its parts', () {
      final photo = testMediaItem(
        backend: MediaBackend.jellyfin,
        kind: MediaKind.photo,
        thumbPath: '/Items/1/Images/Primary',
      ).copyWith(mediaVersions: versions);

      expect(photo.photoImagePath, '/Items/1/Images/Primary');
    });
  });
}
