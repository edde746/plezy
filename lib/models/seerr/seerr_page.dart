/// Generic paginated wrapper for Seerr list endpoints (`/search`,
/// `/discover/...`, `/request`, `/user/{id}/requests`).
class SeerrPage<T> {
  final int page;
  final int pages;
  final int totalResults;
  final List<T> results;

  const SeerrPage({required this.page, required this.pages, required this.totalResults, required this.results});

  factory SeerrPage.fromJson(
    Map<String, dynamic> json,
    T? Function(Map<String, dynamic> item) decode, {
    String resultsKey = 'results',
  }) {
    final pageInfo = json['pageInfo'];
    final pageInfoMap = pageInfo is Map<String, dynamic> ? pageInfo : const <String, dynamic>{};
    final raw = json[resultsKey];
    final results = <T>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          final decoded = decode(item);
          if (decoded != null) results.add(decoded);
        }
      }
    }
    // Seerr surfaces pagination in a few different shapes:
    //   - /search and /discover return top-level {page, totalPages, totalResults}
    //   - some endpoints use top-level {page, pages, totalResults}
    //   - /request and the user-scoped lists nest it as {pageInfo: {page, pages, results, pageSize}}
    // Read whichever field is present.
    final pages = ((pageInfoMap['pages'] ?? json['pages'] ?? json['totalPages']) as num?)?.toInt() ?? 1;
    return SeerrPage(
      page: ((pageInfoMap['page'] ?? json['page']) as num?)?.toInt() ?? 1,
      pages: pages,
      totalResults: ((pageInfoMap['results'] ?? json['totalResults']) as num?)?.toInt() ?? results.length,
      results: results,
    );
  }

  bool get hasMore => page < pages;
}
