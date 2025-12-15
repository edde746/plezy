class PlexFilter {
  final String filter;
  final String filterType;
  final String key;
  final String title;
  final String type;

  PlexFilter({
    required this.filter,
    required this.filterType,
    required this.key,
    required this.title,
    required this.type,
  });

  factory PlexFilter.fromJson(Map<String, dynamic> json) {
    return PlexFilter(
      filter: json['filter'] ?? '',
      filterType: json['filterType'] ?? 'string',
      key: json['key'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? 'filter',
    );
  }

  Map<String, dynamic> toJson() {
    return {'filter': filter, 'filterType': filterType, 'key': key, 'title': title, 'type': type};
  }
}

class PlexFilterValue {
  final String key;
  final String title;
  final String? type;

  PlexFilterValue({required this.key, required this.title, this.type});

  factory PlexFilterValue.fromJson(Map<String, dynamic> json) {
    return PlexFilterValue(key: json['key'] ?? '', title: json['title'] ?? '', type: json['type']);
  }

  Map<String, dynamic> toJson() {
    return {'key': key, 'title': title, if (type != null) 'type': type};
  }
}
