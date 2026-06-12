import 'json_utils.dart';

final RegExp plexLibrarySectionPathPattern = RegExp(r'/(?:library|hubs)/sections/(\d+)');

/// Matches a section id carried in a query string rather than the path, e.g.
/// `/hubs/home/recentlyAdded?type=2&sectionID=2`. The `[?&]` anchor keeps it from
/// false-matching a path segment; the alternation also accepts `librarySectionID=`.
final RegExp plexLibrarySectionQueryPattern = RegExp(r'[?&](?:librarySectionID|sectionID)=(\d+)');

int? plexLibrarySectionIdFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  final direct = flexibleInt(json['librarySectionID']) ?? flexibleInt(json['targetLibrarySectionID']);
  if (direct != null) return direct;

  for (final key in const ['librarySectionKey', 'key', 'hubKey']) {
    final parsed = plexLibrarySectionIdFromString(json[key]?.toString());
    if (parsed != null) return parsed;
  }
  return null;
}

int? plexLibrarySectionIdFromString(String? value) {
  if (value == null || value == 'shared') return null;
  final direct = int.tryParse(value);
  if (direct != null) return direct;
  final pathMatch = plexLibrarySectionPathPattern.firstMatch(value);
  if (pathMatch != null) return int.tryParse(pathMatch.group(1)!);
  final queryMatch = plexLibrarySectionQueryPattern.firstMatch(value);
  return queryMatch == null ? null : int.tryParse(queryMatch.group(1)!);
}

String? plexLibrarySectionTitleFromJson(Map<String, dynamic>? json) {
  return json?['librarySectionTitle']?.toString();
}
