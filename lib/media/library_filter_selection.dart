import 'dart:convert';

import '../utils/app_logger.dart';
import 'library_query.dart';

/// Helpers for the per-library filter selection: an ordered list of
/// [LibraryFilter] clauses that AND together.
///
/// The list is the persisted unit (see `StorageService.saveLibraryFilters`)
/// and the unit the filter editor mutates, so encode/decode and the small set
/// of list edits live together.
extension LibraryFilterSelection on List<LibraryFilter> {
  /// Every clause targeting [field], in selection order.
  List<LibraryFilter> clausesFor(String field) => where((clause) => clause.field == field).toList();

  /// The single clause targeting [field], or null when the field is unset.
  /// Fields the editor allows more than one clause on (ranges) use
  /// [clausesFor] instead.
  LibraryFilter? clauseFor(String field) {
    for (final clause in this) {
      if (clause.field == field) return clause;
    }
    return null;
  }

  bool hasField(String field) => any((clause) => clause.field == field);

  /// Replace every clause on [clauses]' field with [clauses], keeping the
  /// field's original position so the editor's summary rows do not reorder
  /// as the user edits them. An empty [clauses] clears the field.
  List<LibraryFilter> withField(String field, List<LibraryFilter> clauses) {
    final result = <LibraryFilter>[];
    var inserted = false;
    for (final existing in this) {
      if (existing.field != field) {
        result.add(existing);
        continue;
      }
      if (!inserted) {
        result.addAll(clauses);
        inserted = true;
      }
    }
    if (!inserted) result.addAll(clauses);
    return result;
  }
}

/// Serialize a selection for persistence.
String encodeLibraryFilterSelection(List<LibraryFilter> filters) =>
    json.encode(filters.map((clause) => clause.toStorageJson()).toList());

/// Parse a persisted selection.
///
/// Accepts the pre-clause format — a flat `{"genre": "42", "unwatched": "1"}`
/// map, one value per field, always an equality — so filters saved by an
/// older build survive the upgrade instead of silently vanishing.
List<LibraryFilter> decodeLibraryFilterSelection(String jsonString) {
  if (jsonString.isEmpty) return const [];
  Object? decoded;
  try {
    decoded = json.decode(jsonString);
  } catch (e) {
    appLogger.w('Discarding unreadable library filter selection: $e');
    return const [];
  }
  if (decoded is List) {
    return decoded.map(LibraryFilter.fromStorageJson).whereType<LibraryFilter>().toList();
  }
  if (decoded is Map) {
    final migrated = <LibraryFilter>[];
    for (final entry in decoded.entries) {
      final field = entry.key;
      final value = entry.value;
      if (field is! String || field.isEmpty || value == null) continue;
      final values = value.toString().split(',').where((v) => v.isNotEmpty).toList();
      if (values.isEmpty) continue;
      migrated.add(LibraryFilter(field: field, values: values));
    }
    return migrated;
  }
  return const [];
}
