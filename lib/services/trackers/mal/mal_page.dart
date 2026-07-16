/// One page of a MAL API v2 list response (`{"data": [{"node": ...}], "paging": {...}}`).
///
/// MAL pages by offset; `paging.next` is present exactly when more items
/// exist, so callers never need to track counts.
class MalPage<T> {
  final List<T> items;
  final bool hasMore;

  const MalPage({required this.items, this.hasMore = false});

  static MalPage<T> fromJson<T>(Object? json, T Function(Map<String, dynamic> node) fromNode) {
    if (json is! Map) return MalPage(items: List<T>.empty());
    final data = json['data'];
    final items = <T>[
      if (data is List)
        for (final entry in data)
          if (entry is Map && entry['node'] is Map) fromNode((entry['node'] as Map).cast<String, dynamic>()),
    ];
    return MalPage(items: items, hasMore: _hasNext(json));
  }

  /// Like [fromJson] but hands the parser the whole `data[]` entry, for
  /// endpoints whose interesting fields sit beside the node (characters'
  /// `role`).
  static MalPage<T> fromJsonEntries<T>(Object? json, T Function(Map<String, dynamic> entry) fromEntry) {
    if (json is! Map) return MalPage(items: List<T>.empty());
    final data = json['data'];
    final items = <T>[
      if (data is List)
        for (final entry in data)
          if (entry is Map) fromEntry(entry.cast<String, dynamic>()),
    ];
    return MalPage(items: items, hasMore: _hasNext(json));
  }

  static bool _hasNext(Map<dynamic, dynamic> json) {
    final paging = json['paging'];
    final next = paging is Map ? paging['next'] : null;
    return next is String && next.isNotEmpty;
  }
}
