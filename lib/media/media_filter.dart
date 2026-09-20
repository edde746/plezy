import 'package:json_annotation/json_annotation.dart';

import 'library_query.dart';

part 'media_filter.g.dart';

/// Which editor a filter category needs. Derived from the backend-declared
/// field type plus whether the backend can list the field's values.
enum FilterEditorKind {
  /// Tri-state Any/Yes/No, edited inline on the category row.
  toggle,

  /// Multi-select list of server-listed values.
  valueList,

  /// Inclusive numeric lower/upper bound.
  number,

  /// Relative date window (added in the last N days, …).
  date,

  /// Free-text with a match mode.
  text,
}

/// Field types a backend can declare. Plex publishes these in
/// `/library/sections/{id}/all?includeMeta=1` (`Meta.FieldType`); the legacy
/// `/filters` listing only distinguishes `string`, `integer` and `boolean`.
abstract final class MediaFilterType {
  static const boolean = 'boolean';
  static const integer = 'integer';
  static const date = 'date';
  static const string = 'string';
  static const tag = 'tag';
}

/// Field names Plezy gives its own meaning to, independent of backend.
abstract final class MediaFilterField {
  static const unwatched = 'unwatched';
  static const favorite = 'favorite';
  static const genre = 'genre';
  static const year = 'year';
  static const contentRating = 'contentRating';
  static const tag = 'tag';

  /// Plex-only: substring match over the item's full file path. Undocumented
  /// but supported on movie and episode queries; it errors on show queries,
  /// so the Plex client only offers it for those two kinds.
  static const file = 'file';
}

/// One filter category offered for a library, with the comparisons the
/// backend can actually evaluate for it.
@JsonSerializable()
class MediaFilter {
  /// Wire field name. Plex may qualify it by type (`show.genre`) when the
  /// field belongs to a type other than the one being browsed.
  @JsonKey(defaultValue: '')
  final String filter;

  /// Backend-declared field type — see [MediaFilterType].
  @JsonKey(defaultValue: 'string')
  final String filterType;

  /// Endpoint listing this field's selectable values, or empty when the field
  /// has no enumerable values (free text, numbers, dates).
  @JsonKey(defaultValue: '')
  final String key;

  @JsonKey(defaultValue: '')
  final String title;

  @JsonKey(defaultValue: 'filter')
  final String type;

  /// Comparisons this backend supports for this field. Excluded from JSON:
  /// the legacy Plex `/filters` rows carry no operator vocabulary, so those
  /// fall back to [defaultOperatorsFor].
  @JsonKey(includeFromJson: false, includeToJson: false)
  final List<LibraryFilterOperator> operators;

  MediaFilter({
    required this.filter,
    required this.filterType,
    required this.key,
    required this.title,
    required this.type,
    List<LibraryFilterOperator>? operators,
  }) : operators = operators ?? defaultOperatorsFor(filterType);

  factory MediaFilter.fromJson(Map<String, dynamic> json) => _$MediaFilterFromJson(json);

  Map<String, dynamic> toJson() => _$MediaFilterToJson(this);

  /// Whether the backend can enumerate this field's values.
  bool get hasValueList => key.isNotEmpty;

  bool get isBoolean => filterType == MediaFilterType.boolean;

  /// Whether the user can express "not this" for this field.
  bool get supportsExclusion => operators.any((op) => op.isNegated);

  FilterEditorKind get editorKind {
    if (isBoolean) return FilterEditorKind.toggle;
    if (hasValueList) return FilterEditorKind.valueList;
    return switch (filterType) {
      MediaFilterType.integer => FilterEditorKind.number,
      MediaFilterType.date => FilterEditorKind.date,
      _ => FilterEditorKind.text,
    };
  }

  /// Comparisons assumed when the backend declares a field type but no
  /// operator list. Deliberately conservative: only the comparisons every
  /// supported Plex version evaluates for that type.
  static List<LibraryFilterOperator> defaultOperatorsFor(String filterType) {
    return switch (filterType) {
      MediaFilterType.boolean => const [LibraryFilterOperator.is_, LibraryFilterOperator.isNot],
      MediaFilterType.integer || MediaFilterType.date => const [
        LibraryFilterOperator.is_,
        LibraryFilterOperator.isNot,
        LibraryFilterOperator.atLeast,
        LibraryFilterOperator.atMost,
      ],
      _ => const [LibraryFilterOperator.is_, LibraryFilterOperator.isNot],
    };
  }
}

@JsonSerializable(includeIfNull: false)
class MediaFilterValue {
  @JsonKey(defaultValue: '')
  final String key;
  @JsonKey(defaultValue: '')
  final String title;
  final String? type;

  MediaFilterValue({required this.key, required this.title, this.type});

  factory MediaFilterValue.fromJson(Map<String, dynamic> json) => _$MediaFilterValueFromJson(json);

  Map<String, dynamic> toJson() => _$MediaFilterValueToJson(this);
}

/// Canonical filter identity carried by Plex query/path keys or plain backend ids.
String libraryFilterValueId(String key, String filterName) {
  if (key.contains('?')) {
    final queryString = key.substring(key.indexOf('?') + 1);
    return Uri.splitQueryString(queryString)[filterName] ?? key;
  }
  if (key.startsWith('/')) return key.split('/').last;
  return key;
}
