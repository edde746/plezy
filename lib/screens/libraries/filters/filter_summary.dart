import '../../../i18n/strings.g.dart';
import '../../../media/library_query.dart';
import '../../../media/media_filter.dart';

/// Display names for filter values, keyed by server + library + field + value.
///
/// Plex value ids are opaque (`genre=239`), so the title has to be remembered
/// from the moment the user picked it; otherwise a restored selection would
/// summarise as a number. Process-wide and bounded — it is a label cache, not
/// state.
abstract final class FilterValueNames {
  static const int _maxEntries = 1000;
  static final Map<String, String> _names = {};

  static String _cacheKey(String serverId, String libraryKey, String field, String value) =>
      '$serverId:$libraryKey:$field:$value';

  static void remember({
    required String serverId,
    required String libraryKey,
    required String field,
    required String value,
    required String title,
  }) {
    if (_names.length > _maxEntries) _names.clear();
    _names[_cacheKey(serverId, libraryKey, field, value)] = title;
  }

  /// Remembered title for a value, or null when it has never been seen.
  static String? maybeLookup({
    required String serverId,
    required String libraryKey,
    required String field,
    required String value,
  }) => _names[_cacheKey(serverId, libraryKey, field, value)];
}

/// One-line summary of everything selected for [filter], or null when the
/// field is unset. Shown on the category row and in the desktop popup.
String? filterFieldSummary({
  required MediaFilter filter,
  required List<LibraryFilter> clauses,
  required String serverId,
  required String libraryKey,
}) {
  final own = clauses.where((clause) => clause.field == filter.filter).toList();
  if (own.isEmpty) return null;

  if (filter.isBoolean) {
    final negated = own.first.op.isNegated;
    return negated ? t.libraries.advancedFilters.no : t.libraries.advancedFilters.yes;
  }

  if (filter.editorKind == FilterEditorKind.number || filter.editorKind == FilterEditorKind.date) {
    return _boundsSummary(filter, own);
  }

  return own.map((clause) => _clauseSummary(filter, clause, serverId: serverId, libraryKey: libraryKey)).join(' · ');
}

String _clauseSummary(
  MediaFilter filter,
  LibraryFilter clause, {
  required String serverId,
  required String libraryKey,
}) {
  final String labels;
  if (filter.hasValueList) {
    // Plex value ids are opaque, so a restored selection can carry values the
    // name cache has never seen. Summarising those as a count is truthful;
    // echoing `Not 190` at the viewer is not. Opening the field remembers the
    // titles, after which this reads normally.
    final resolved = clause.values
        .map(
          (value) => FilterValueNames.maybeLookup(
            serverId: serverId,
            libraryKey: libraryKey,
            field: filter.filter,
            value: value,
          ),
        )
        .toList();
    if (resolved.any((name) => name == null)) {
      final count = clause.values.length.toString();
      return clause.op.isNegated
          ? t.libraries.advancedFilters.valueCountExcluded(count: count)
          : t.libraries.advancedFilters.valueCount(count: count);
    }
    labels = resolved.join(', ');
  } else {
    labels = clause.values.join(', ');
  }
  final body = switch (clause.op) {
    LibraryFilterOperator.beginsWith => '$labels…',
    LibraryFilterOperator.endsWith => '…$labels',
    _ => labels,
  };
  return clause.op.isNegated ? t.libraries.advancedFilters.not(value: body) : body;
}

String? _boundsSummary(MediaFilter filter, List<LibraryFilter> clauses) {
  String? lower;
  String? upper;
  final exact = <String>[];
  for (final clause in clauses) {
    final value = clause.values.join(', ');
    switch (clause.op) {
      case LibraryFilterOperator.atLeast:
        lower = value;
      case LibraryFilterOperator.atMost:
        upper = value;
      default:
        exact.add(clause.op.isNegated ? t.libraries.advancedFilters.not(value: value) : value);
    }
  }
  final parts = <String>[
    ...exact,
    if (lower != null && upper != null)
      t.libraries.advancedFilters.range(from: _boundLabel(filter, lower), to: _boundLabel(filter, upper))
    else if (lower != null)
      _lowerBoundLabel(filter, lower)
    else if (upper != null)
      _upperBoundLabel(filter, upper),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

String _lowerBoundLabel(MediaFilter filter, String value) {
  if (filter.editorKind == FilterEditorKind.date) return relativeDateLabel(value);
  return t.libraries.advancedFilters.atLeast(value: value);
}

String _upperBoundLabel(MediaFilter filter, String value) {
  if (filter.editorKind == FilterEditorKind.date) return relativeDateLabel(value, older: true);
  return t.libraries.advancedFilters.atMost(value: value);
}

String _boundLabel(MediaFilter filter, String value) =>
    filter.editorKind == FilterEditorKind.date ? relativeDateLabel(value) : value;

/// Relative date windows the date editor offers, as Plex's own relative
/// syntax (`-30d`). Verified against PMS 1.43: `addedAt>>=-30d` resolves
/// server-side, so nothing has to be converted to an absolute timestamp.
const List<String> relativeDateWindows = ['-7d', '-30d', '-90d', '-1y'];

String relativeDateLabel(String value, {bool older = false}) {
  final days = switch (value) {
    '-7d' => 7,
    '-30d' => 30,
    '-90d' => 90,
    _ => null,
  };
  if (days != null) {
    return older
        ? t.libraries.advancedFilters.dateOlderThanDays(count: days.toString())
        : t.libraries.advancedFilters.dateLastDays(count: days.toString());
  }
  if (value == '-1y') {
    return older ? t.libraries.advancedFilters.dateOlderThanYear : t.libraries.advancedFilters.dateLastYear;
  }
  return value;
}
