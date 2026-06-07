import '../i18n/strings.g.dart';

/// Matches a media server's generic English season title, e.g. "Season 1".
///
/// Plex and Jellyfin return this verbatim when they have no localized name for a
/// season (or when the request language resolves to English), which leaks
/// untranslated "Season N" labels into otherwise-localized UI (see #1271).
final RegExp _genericSeasonTitle = RegExp(r'^season\s+(\d+)$', caseSensitive: false);

/// Localized season label.
///
/// Replaces a generic English "Season N" (or an empty title) with the app-locale
/// `t.common.seasonNumber`, while preserving custom names ("Specials", …) and
/// titles the server already localized ("Saison 1").
///
/// Prefers [index] for the number; falls back to the digits parsed from a
/// generic title, then to [fallback] when there is nothing usable to show.
String localizedSeasonLabel({String? title, int? index, String? fallback}) {
  final raw = title?.trim() ?? '';
  final match = _genericSeasonTitle.firstMatch(raw);
  final number = index ?? (match != null ? int.tryParse(match.group(1)!) : null);
  if ((match != null || raw.isEmpty) && number != null) {
    return t.common.seasonNumber(number: number);
  }
  return raw.isNotEmpty ? raw : (fallback ?? '');
}
