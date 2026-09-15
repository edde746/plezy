import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/widgets/media_context_menu.dart';

void main() {
  group('hasKnownNoPlayableMedia', () {
    test('Plex movie with an explicitly empty version list is metadata-only', () {
      expect(
        hasKnownNoPlayableMedia(
          kind: MediaKind.movie,
          backend: MediaBackend.plex,
          mediaVersions: const <MediaVersion>[],
          leafCount: null,
        ),
        isTrue,
      );
    });

    test('Jellyfin movie with a null version list fails open (listings omit MediaSources)', () {
      expect(
        hasKnownNoPlayableMedia(
          kind: MediaKind.movie,
          backend: MediaBackend.jellyfin,
          mediaVersions: null,
          leafCount: null,
        ),
        isFalse,
      );
    });

    test('show with an explicit leafCount of 0 is metadata-only on any backend', () {
      expect(
        hasKnownNoPlayableMedia(
          kind: MediaKind.show,
          backend: MediaBackend.jellyfin,
          mediaVersions: null,
          leafCount: 0,
        ),
        isTrue,
      );
    });

    test('show with a null leafCount fails open', () {
      expect(
        hasKnownNoPlayableMedia(kind: MediaKind.show, backend: MediaBackend.plex, mediaVersions: null, leafCount: null),
        isFalse,
      );
    });
  });
}
