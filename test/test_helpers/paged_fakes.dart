import 'package:plezy/media/library_query.dart';

/// Default page size used by production media paging paths.
const fakeMediaPageSize = 200;

List<T> sliceFakePage<T>(List<T> allItems, {int? start, int? size, int defaultPageSize = fakeMediaPageSize}) {
  final offset = (start ?? 0).clamp(0, allItems.length);
  final requestedSize = (size ?? defaultPageSize).clamp(0, allItems.length - offset);
  if (requestedSize == 0) return List<T>.empty(growable: false);
  return allItems.sublist(offset, offset + requestedSize);
}

LibraryPage<T> fakeLibraryPage<T>(List<T> allItems, {int? start, int? size, int defaultPageSize = fakeMediaPageSize}) {
  final offset = start ?? 0;
  return LibraryPage<T>(
    items: sliceFakePage(allItems, start: offset, size: size, defaultPageSize: defaultPageSize),
    totalCount: allItems.length,
    offset: offset,
  );
}
