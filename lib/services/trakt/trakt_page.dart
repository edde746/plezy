import 'package:http/http.dart' as http;

/// One page of a paginated Trakt response, parsed from the
/// `X-Pagination-*` headers.
class TraktPage<T> {
  final List<T> items;
  final int page;
  final int pageCount;
  final int itemCount;

  const TraktPage({required this.items, required this.page, required this.pageCount, required this.itemCount});

  bool get hasMore => page < pageCount;

  /// Endpoints where pagination is optional omit the headers; default to a
  /// single page so callers never loop.
  factory TraktPage.fromResponse(http.Response res, List<T> items) => TraktPage(
    items: items,
    page: int.tryParse(res.headers['x-pagination-page'] ?? '') ?? 1,
    pageCount: int.tryParse(res.headers['x-pagination-page-count'] ?? '') ?? 1,
    itemCount: int.tryParse(res.headers['x-pagination-item-count'] ?? '') ?? items.length,
  );
}
