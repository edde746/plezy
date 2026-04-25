import 'package:json_annotation/json_annotation.dart';

part 'plex_sort.g.dart';

@JsonSerializable()
class PlexSort {
  final String key;
  final String? descKey;
  final String title;
  final String? defaultDirection;

  PlexSort({required this.key, this.descKey, required this.title, this.defaultDirection});

  factory PlexSort.fromJson(Map<String, dynamic> json) => _$PlexSortFromJson(json);

  Map<String, dynamic> toJson() => _$PlexSortToJson(this);

  /// Gets the full sort key with direction
  /// If [descending] is true, returns the descKey or key:desc
  /// Otherwise returns the key for ascending sort
  String getSortKey({bool descending = false}) {
    if (!descending) {
      return key;
    }

    // Use descKey if available, otherwise append :desc to key
    return descKey ?? '$key:desc';
  }

  /// Returns true if this sort's default direction is descending
  bool get isDefaultDescending {
    return defaultDirection?.toLowerCase() == 'desc';
  }

  @override
  String toString() {
    return 'PlexSort(key: $key, title: $title, defaultDirection: $defaultDirection)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlexSort && other.key == key;
  }

  @override
  int get hashCode => key.hashCode;
}
