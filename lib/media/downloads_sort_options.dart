import '../i18n/strings.g.dart';
import 'media_item_sort.dart';
import 'media_sort.dart';

/// The sort options the downloads screen offers, as [MediaSort] structs so
/// the existing sort sheet can render them unchanged. Unlike server-provided
/// sorts these keys are local — they feed [mediaItemSortComparator], not a
/// backend query.
///
/// [includeDownloadFields] adds the download-only fields (download date,
/// file size) that only make sense once per-item download metadata is
/// available to the comparator's `extras` lookup.
List<MediaSort> downloadSortOptions({required bool includeDownloadFields}) {
  return [
    MediaSort(key: mediaSortKeyTitle, title: t.libraries.sortLabels.title, defaultDirection: 'asc'),
    MediaSort(key: mediaSortKeyDateAdded, title: t.libraries.sortLabels.dateAdded, defaultDirection: 'desc'),
    MediaSort(key: mediaSortKeyReleaseDate, title: t.libraries.sortLabels.releaseDate, defaultDirection: 'desc'),
    MediaSort(key: mediaSortKeyRating, title: t.libraries.sortLabels.rating, defaultDirection: 'desc'),
    if (includeDownloadFields) ...[
      MediaSort(key: mediaSortKeyDownloadedAt, title: t.libraries.sortLabels.dateDownloaded, defaultDirection: 'desc'),
      MediaSort(key: mediaSortKeySize, title: t.libraries.sortLabels.size, defaultDirection: 'desc'),
    ],
    MediaSort(key: mediaSortKeyLibrary, title: t.libraries.sortLabels.library, defaultDirection: 'asc'),
  ];
}
