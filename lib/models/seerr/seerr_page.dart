/// One page of a paginated Seerr response. Discover/search endpoints use the
/// TMDB shape `{page, totalPages, results}`; Seerr's own listings (e.g.
/// `GET /request`) use `{pageInfo: {page, pages}, results}` — both parse.
class SeerrPage<T> {
  final List<T> items;
  final bool hasMore;
  final int? totalResults;

  const SeerrPage({required this.items, required this.hasMore, this.totalResults});

  /// [skip] drops results the mapper can't represent (person entries in
  /// mixed trending/search results) — return null from [fromItem] for those.
  factory SeerrPage.fromJson(Map<String, dynamic> json, T? Function(Map<String, dynamic>) fromItem) {
    final info = json['pageInfo'] is Map<String, dynamic> ? json['pageInfo'] as Map<String, dynamic> : json;
    final page = (info['page'] as num?)?.toInt() ?? 1;
    final totalPages = ((info['pages'] ?? info['totalPages']) as num?)?.toInt() ?? page;
    final totalResults = ((json['totalResults'] ?? info['totalResults']) as num?)?.toInt();
    final results = json['results'];
    return SeerrPage(
      items: [
        if (results is List)
          for (final item in results)
            if (item is Map<String, dynamic>)
              if (fromItem(item) case final T parsed) parsed,
      ],
      hasMore: page < totalPages,
      totalResults: totalResults,
    );
  }
}
