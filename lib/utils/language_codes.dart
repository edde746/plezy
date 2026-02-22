import 'dart:convert';
import 'package:flutter/services.dart';

/// Helper class for converting between ISO 639-1 (2-letter) and ISO 639-2 (3-letter) language codes
class LanguageCodes {
  static Map<String, dynamic>? _codes;

  /// Load the language codes from JSON
  static Future<void> initialize() async {
    if (_codes != null) return;

    final jsonString = await rootBundle.loadString('lib/data/iso_639_codes.json');
    _codes = json.decode(jsonString) as Map<String, dynamic>;
  }

  /// Get all possible variations of a language code
  /// Handles both ISO 639-1 (2-letter) and ISO 639-2 (3-letter) codes
  /// Returns a list of codes to check against track languages
  static List<String> getVariations(String languageCode) {
    if (_codes == null) {
      throw StateError('LanguageCodes not initialized. Call initialize() first.');
    }

    final normalized = languageCode.toLowerCase().trim();
    final variations = <String>{normalized}; // Use Set to avoid duplicates

    // Check if it's a 2-letter code (ISO 639-1)
    if (_codes!.containsKey(normalized)) {
      final entry = _codes![normalized] as Map<String, dynamic>;

      // Add the 639-1 code
      if (entry.containsKey('639-1')) {
        variations.add((entry['639-1'] as String).toLowerCase());
      }

      // Add the 639-2 code
      if (entry.containsKey('639-2')) {
        variations.add((entry['639-2'] as String).toLowerCase());
      }

      // Add the 639-2/B code if it exists (bibliographic variant)
      if (entry.containsKey('639-2/B')) {
        variations.add((entry['639-2/B'] as String).toLowerCase());
      }
    } else {
      // It might be a 3-letter code, search for it
      for (var entry in _codes!.values) {
        final entryMap = entry as Map<String, dynamic>;

        // Check if this entry contains our code as 639-2 or 639-2/B
        final code6392 = entryMap['639-2'] as String?;
        final code6392B = entryMap['639-2/B'] as String?;

        if (code6392?.toLowerCase() == normalized || code6392B?.toLowerCase() == normalized) {
          // Add all variations from this entry
          if (entryMap.containsKey('639-1')) {
            variations.add((entryMap['639-1'] as String).toLowerCase());
          }
          if (code6392 != null) {
            variations.add(code6392.toLowerCase());
          }
          if (code6392B != null) {
            variations.add(code6392B.toLowerCase());
          }
          break;
        }
      }
    }

    return variations.toList();
  }

  /// Get a display name for a language/locale code.
  /// Handles plain codes ("en" → "English") and locale codes ("en-US" → "English",
  /// "en-AU" → "English (Australia)").
  /// Uses [_regionNames] for the country qualifier on non-primary variants.
  static String getDisplayName(String code) {
    if (code.isEmpty) return code;

    // Plain language code (e.g. "en", "ja")
    if (!code.contains('-')) {
      return getLanguageName(code) ?? code;
    }

    // Locale code (e.g. "en-US", "zh-TW")
    final parts = code.split('-');
    final langName = getLanguageName(parts[0]) ?? parts[0];
    final region = parts.length > 1 ? _regionNames[parts[1]] : null;
    return region != null ? '$langName ($region)' : langName;
  }

  // Region qualifiers for Plex locale codes that differ from the primary variant.
  // Only entries where Plex shows a country qualifier in its UI are listed.
  static const _regionNames = <String, String>{
    'AU': 'Australia',
    'BR': 'Brazil',
    'CA': 'Canada',
    'GB': 'UK',
    'HK': 'Hong Kong',
    'MX': 'Mexico',
    'PT': 'Portugal',
    'TW': 'Taiwan',
  };

  /// Get the English name of a language from its code
  static String? getLanguageName(String languageCode) {
    if (_codes == null) return null;

    final normalized = languageCode.toLowerCase().trim();

    // Check if it's a 2-letter code
    if (_codes!.containsKey(normalized)) {
      final entry = _codes![normalized] as Map<String, dynamic>;
      return entry['name'] as String?;
    }

    // Search for 3-letter code
    for (var entry in _codes!.values) {
      final entryMap = entry as Map<String, dynamic>;
      final code6392 = entryMap['639-2'] as String?;
      final code6392B = entryMap['639-2/B'] as String?;

      if (code6392?.toLowerCase() == normalized || code6392B?.toLowerCase() == normalized) {
        return entryMap['name'] as String?;
      }
    }

    return null;
  }
}
