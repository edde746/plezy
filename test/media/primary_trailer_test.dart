import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/primary_trailer.dart';

import '../test_helpers/media_items.dart';

void main() {
  final featurette = testMediaItem(id: 'featurette', raw: const {'ExtraType': 'Featurette'});
  final trailer = testMediaItem(id: 'trailer', raw: const {'ExtraType': 'Trailer'});

  test('picks the first extra classified as a trailer', () {
    expect(primaryTrailer(testMediaItem(id: 'movie'), [featurette, trailer])?.id, 'trailer');
  });

  test("prefers Plex's own primary extra over the first trailer", () {
    final pick = testMediaItem(id: '52601', raw: const {'ExtraType': 'Featurette'});
    final movie = (testMediaItem(id: 'movie') as PlexMediaItem).copyWith(trailerKey: '/library/metadata/52601');

    expect(primaryTrailer(movie, [trailer, pick])?.id, '52601');
  });

  test('reads MediaBrowser extra types and returns null without a trailer', () {
    final jellyfinTrailer = testMediaItem(
      id: 'jf-trailer',
      backend: MediaBackend.jellyfin,
      raw: const {'Type': 'Trailer'},
    );

    expect(primaryTrailer(testMediaItem(id: 'movie'), [featurette, jellyfinTrailer])?.id, 'jf-trailer');
    expect(primaryTrailer(testMediaItem(id: 'movie'), [featurette]), isNull);
  });
}
