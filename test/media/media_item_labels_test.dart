import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_item_labels.dart';
import 'package:plezy/media/media_kind.dart';

void main() {
  MediaItem item({
    MediaKind kind = MediaKind.movie,
    String? grandparentTitle,
    int? parentIndex,
    int? index,
    int? year,
    String? editionTitle,
  }) => MediaItem.plex(
    id: 'item',
    kind: kind,
    grandparentTitle: grandparentTitle,
    parentIndex: parentIndex,
    index: index,
    year: year,
    editionTitle: editionTitle,
  );

  test('formats episodes with show and season/episode numbers', () {
    expect(
      formatQueueItemSubtitle(item(kind: MediaKind.episode, grandparentTitle: 'Show', parentIndex: 2, index: 3)),
      'Show \u00b7 S2E3',
    );
  });

  test('falls back through show, year and edition, then media kind', () {
    expect(formatQueueItemSubtitle(item(grandparentTitle: 'Show')), 'Show');
    expect(formatQueueItemSubtitle(item(year: 2026, editionTitle: 'Director Cut')), '2026 \u00b7 Director Cut');
    expect(formatQueueItemSubtitle(item(year: 2026)), '2026');
    expect(formatQueueItemSubtitle(item()), 'movie');
  });
}
