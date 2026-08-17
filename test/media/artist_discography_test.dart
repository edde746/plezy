import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/artist_discography.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';

void main() {
  MediaItem album(String id) => MediaItem.plex(id: id, kind: MediaKind.album, title: id);

  final kinds = <String, DiscographyGroupKind>{
    'ep-1': DiscographyGroupKind.singlesAndEps,
    'live-1': DiscographyGroupKind.live,
    'comp-1': DiscographyGroupKind.compilations,
  };
  DiscographyGroupKind kindOf(MediaItem item) => kinds[item.id] ?? DiscographyGroupKind.albums;

  test('partitions albums into sections in display order', () {
    final groups = buildArtistDiscographyGroups([
      album('lp-1'),
      album('ep-1'),
      album('live-1'),
      album('comp-1'),
      album('lp-2'),
    ], kindOf);

    expect(groups.map((group) => group.kind), [
      DiscographyGroupKind.albums,
      DiscographyGroupKind.singlesAndEps,
      DiscographyGroupKind.live,
      DiscographyGroupKind.compilations,
    ]);
    expect(groups[0].items.map((item) => item.id), ['lp-1', 'lp-2']);
    expect(groups[1].items.map((item) => item.id), ['ep-1']);
    expect(groups[2].items.map((item) => item.id), ['live-1']);
    expect(groups[3].items.map((item) => item.id), ['comp-1']);
  });

  test('preserves album order within each section', () {
    final groups = buildArtistDiscographyGroups([album('lp-3'), album('ep-1'), album('lp-1'), album('lp-2')], kindOf);

    expect(groups[0].items.map((item) => item.id), ['lp-3', 'lp-1', 'lp-2']);
    expect(groups[1].items.map((item) => item.id), ['ep-1']);
  });

  test('drops empty sections and returns an empty list for no albums', () {
    final groups = buildArtistDiscographyGroups([album('lp-1'), album('live-1')], kindOf);
    expect(groups.map((group) => group.kind), [DiscographyGroupKind.albums, DiscographyGroupKind.live]);

    expect(buildArtistDiscographyGroups(const [], kindOf), isEmpty);
  });
}
