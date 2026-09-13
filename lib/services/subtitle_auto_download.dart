import 'package:flutter/widgets.dart';

import '../media/media_source_info.dart';
import '../models/plex/plex_subtitle_search_result.dart';
import '../utils/language_codes.dart';
import 'settings_service.dart';

/// Whether the item carries nothing in [languageCode], so an online search is
/// the only way to serve the viewer's preferred subtitle language.
///
/// Matching goes through [subtitleLanguageMatches] for the same reason selection
/// does: a prefix compare would let `est` satisfy an `es` preference. Both the
/// server's display language and its code are checked, because a sidecar row
/// can carry one without the other.
bool needsSubtitleDownload(List<MediaSubtitleTrack> tracks, String languageCode) {
  if (languageCode.isEmpty) return false;
  for (final track in tracks) {
    if (subtitleLanguageMatches(track.languageCode, languageCode) ||
        subtitleLanguageMatches(track.language, languageCode)) {
      return false;
    }
  }
  return true;
}

/// The result to download, best first.
///
/// Provider score alone is a weak signal on a common title — "Target" (1985)
/// returned a confidently-scored subtitle for an entirely different film — so
/// score only breaks ties between results that already agree on the stronger
/// evidence:
///
/// 1. Plex's `perfectMatch`, which comes from matching the actual file rather
///    than its name, and is the only signal here that cannot be fooled by a
///    shared title.
/// 2. The language actually asked for, when the result declares one. A
///    provider that substitutes a neighbouring language is not a match.
/// 3. Full dialogue over forced or hearing-impaired variants — the viewer
///    asked for subtitles, not signs-and-songs or sound descriptions. Both
///    remain eligible, just behind.
///
/// [language] is the ISO code the search asked for; pass null to skip the
/// language comparison entirely.
PlexSubtitleSearchResult? pickBestSubtitleResult(List<PlexSubtitleSearchResult> results, {String? language}) {
  bool languageAgrees(PlexSubtitleSearchResult result) {
    if (language == null) return true;
    final declared = result.languageCode ?? result.language;
    // Nothing declared is not a mismatch: the request already constrained it.
    if (declared == null || declared.isEmpty) return true;
    return subtitleLanguageMatches(declared, language);
  }

  bool isFullDialogue(PlexSubtitleSearchResult result) => !result.forced && !result.hearingImpaired;

  PlexSubtitleSearchResult? best;
  for (final result in results) {
    if (result.key.isEmpty) continue;
    if (best == null) {
      best = result;
      continue;
    }
    if (result.perfectMatch != best.perfectMatch) {
      if (result.perfectMatch) best = result;
      continue;
    }
    if (languageAgrees(result) != languageAgrees(best)) {
      if (languageAgrees(result)) best = result;
      continue;
    }
    if (isFullDialogue(result) != isFullDialogue(best)) {
      if (isFullDialogue(result)) best = result;
      continue;
    }
    if ((result.score ?? 0) > (best.score ?? 0)) best = result;
  }
  return best;
}

/// The subtitle language to search for and to hold subtitles to.
///
/// With no explicit preference set, the app's own language is the best guess
/// we have about what the viewer reads — and it already falls back to the
/// system locale itself when they have never chosen one.
String resolveSubtitleSearchLanguageCode({String? savedLanguageCode, required Locale appLocale}) {
  return LanguageCodes.getIso6391Code(savedLanguageCode ?? '') ??
      LanguageCodes.getIso6391Code(appLocale.languageCode) ??
      'en';
}

/// [resolveSubtitleSearchLanguageCode] against the live settings, for callers
/// that have no `BuildContext` handy.
String resolveSubtitleLanguageFromSettings(SettingsService? settings) {
  return resolveSubtitleSearchLanguageCode(
    savedLanguageCode: settings?.read(SettingsService.subtitleSearchLanguage),
    appLocale: settings == null
        ? WidgetsBinding.instance.platformDispatcher.locale
        : Locale(settings.read(SettingsService.appLocale).languageCode),
  );
}
