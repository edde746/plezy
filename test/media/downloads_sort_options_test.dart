import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/downloads_sort_options.dart';
import 'package:plezy/media/media_item_sort.dart';

/// The downloads sort sheet's option list (#927). The contract under test:
/// which keys are offered, in which order, and that the download-only fields
/// are gated behind [includeDownloadFields].
void main() {
  group('downloadSortOptions', () {
    test('offers the shared keys without download fields', () {
      final keys = downloadSortOptions(includeDownloadFields: false).map((s) => s.key).toList();
      expect(keys, [
        mediaSortKeyTitle,
        mediaSortKeyDateAdded,
        mediaSortKeyReleaseDate,
        mediaSortKeyRating,
        mediaSortKeyLibrary,
      ]);
    });

    test('includeDownloadFields inserts download date and size before library', () {
      final keys = downloadSortOptions(includeDownloadFields: true).map((s) => s.key).toList();
      expect(keys, [
        mediaSortKeyTitle,
        mediaSortKeyDateAdded,
        mediaSortKeyReleaseDate,
        mediaSortKeyRating,
        mediaSortKeyDownloadedAt,
        mediaSortKeySize,
        mediaSortKeyLibrary,
      ]);
    });

    test('every option carries a label and a default direction', () {
      for (final sort in downloadSortOptions(includeDownloadFields: true)) {
        expect(sort.title, isNotEmpty, reason: sort.key);
        expect(sort.defaultDirection, isNotNull, reason: sort.key);
      }
    });
  });
}
