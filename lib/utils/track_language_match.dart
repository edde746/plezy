/// Language names whose ISO 639-2/B code shares no prefix with the English
/// name, so prefix matching alone cannot connect them.
const Map<String, String> _iso639bAliases = {
  'albanian': 'alb',
  'armenian': 'arm',
  'basque': 'baq',
  'burmese': 'bur',
  'chinese': 'chi',
  'czech': 'cze',
  'dutch': 'dut',
  'french': 'fre',
  'georgian': 'geo',
  'german': 'ger',
  'greek': 'gre',
  'icelandic': 'ice',
  'japanese': 'jpn',
  'macedonian': 'mac',
  'malay': 'may',
  'maori': 'mao',
  'persian': 'per',
  'romanian': 'rum',
  'slovak': 'slo',
  'tibetan': 'tib',
  'welsh': 'wel',
};

/// Whether [query] identifies a media track carrying [language] / [title].
///
/// mpv reports ISO 639 codes (`eng`), while a person naturally says the full
/// name (`english`), so a plain substring test in
/// either direction misses: `'eng'.contains('english')` is false. Matching is
/// therefore prefix-based in both directions, with an alias table for the
/// ISO 639-2/B codes that share no prefix with their English name (`jpn`,
/// `ger`, `rum`, …), falling back to the human-readable track title.
bool trackLanguageMatches({required String query, String? language, String? title}) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return false;

  final trackLanguage = (language ?? '').trim().toLowerCase();
  if (trackLanguage.isNotEmpty) {
    // 'english' vs 'eng'/'en', and 'en' vs 'eng'. Two characters is the
    // shortest meaningful code, so shorter queries never match by prefix.
    if (normalizedQuery.startsWith(trackLanguage)) return true;
    if (normalizedQuery.length >= 2 && trackLanguage.startsWith(normalizedQuery)) return true;

    final alias = _iso639bAliases[normalizedQuery];
    if (alias != null && trackLanguage.startsWith(alias)) return true;
  }

  // Titles are free text ('English SDH', 'Commentary'); only trust them for a
  // query long enough not to collide with an unrelated word.
  return normalizedQuery.length >= 3 && (title ?? '').toLowerCase().contains(normalizedQuery);
}
