import '../models/plex_media_info.dart';
import '../models/plex_user_profile.dart';

/// Service for selecting audio and subtitle tracks based on user preferences
class TrackSelectionService {
  /// Selects the best audio track based on user preferences
  ///
  /// Returns the selected audio track, or null if no suitable track is found
  static PlexAudioTrack? selectAudioTrack(
    List<PlexAudioTrack> tracks,
    PlexUserProfile profile,
  ) {
    if (tracks.isEmpty) return null;

    // If auto-select is disabled, use Plex's selected track
    if (!profile.autoSelectAudio) {
      return tracks.firstWhere(
        (track) => track.selected,
        orElse: () => tracks.first,
      );
    }

    // Build list of preferred language codes
    final preferredLanguages = <String>[];
    if (profile.defaultAudioLanguage != null) {
      preferredLanguages.add(profile.defaultAudioLanguage!);
    }
    if (profile.defaultAudioLanguages != null) {
      preferredLanguages.addAll(profile.defaultAudioLanguages!);
    }

    // If no preferred languages, return first track
    if (preferredLanguages.isEmpty) {
      return tracks.first;
    }

    // Try to find a track matching preferred languages
    for (final language in preferredLanguages) {
      final matchingTrack = tracks.firstWhere(
        (track) => _matchesLanguage(track.languageCode, language),
        orElse: () => tracks.first,
      );
      if (matchingTrack != tracks.first ||
          _matchesLanguage(matchingTrack.languageCode, language)) {
        return matchingTrack;
      }
    }

    // Fallback to first track
    return tracks.first;
  }

  /// Selects the best subtitle track based on user preferences
  ///
  /// Returns the selected subtitle track, or null if subtitles should be disabled
  static PlexSubtitleTrack? selectSubtitleTrack(
    List<PlexSubtitleTrack> tracks,
    PlexUserProfile profile,
    PlexAudioTrack? selectedAudioTrack,
  ) {
    if (tracks.isEmpty) return null;

    // Mode 0: Manually selected - return null to disable subtitles
    if (profile.autoSelectSubtitle == 0) {
      return null;
    }

    // Mode 1: Shown with foreign audio
    if (profile.autoSelectSubtitle == 1) {
      // Check if audio language matches user's preferred subtitle language
      if (selectedAudioTrack != null &&
          profile.defaultSubtitleLanguage != null) {
        final audioLang = selectedAudioTrack.languageCode;
        final prefLang = profile.defaultSubtitleLanguage;

        // If audio matches preferred language, no subtitles needed
        if (_matchesLanguage(audioLang, prefLang)) {
          return null;
        }
      }

      // Foreign audio detected, enable subtitles
      return _findBestSubtitle(tracks, profile);
    }

    // Mode 2: Always enabled
    if (profile.autoSelectSubtitle == 2) {
      return _findBestSubtitle(tracks, profile);
    }

    return null;
  }

  /// Finds the best subtitle track matching user preferences
  static PlexSubtitleTrack? _findBestSubtitle(
    List<PlexSubtitleTrack> tracks,
    PlexUserProfile profile,
  ) {
    // Build list of preferred language codes
    final preferredLanguages = <String>[];
    if (profile.defaultSubtitleLanguage != null) {
      preferredLanguages.add(profile.defaultSubtitleLanguage!);
    }
    if (profile.defaultSubtitleLanguages != null) {
      preferredLanguages.addAll(profile.defaultSubtitleLanguages!);
    }

    // Filter tracks based on preferences
    var candidateTracks = tracks;

    // Apply SDH (hearing impaired) filtering
    candidateTracks = _filterBySDH(
      candidateTracks,
      profile.defaultSubtitleAccessibility,
    );

    // Apply forced subtitle filtering
    candidateTracks = _filterByForced(
      candidateTracks,
      profile.defaultSubtitleForced,
    );

    // If no candidates after filtering, relax filters
    if (candidateTracks.isEmpty) {
      candidateTracks = tracks;
    }

    // If no preferred languages, return first candidate
    if (preferredLanguages.isEmpty) {
      return candidateTracks.firstOrNull;
    }

    // Try to find a track matching preferred languages
    for (final language in preferredLanguages) {
      final matchingTrack = candidateTracks.firstWhere(
        (track) => _matchesLanguage(track.languageCode, language),
        orElse: () => candidateTracks.first,
      );
      if (matchingTrack != candidateTracks.first ||
          _matchesLanguage(matchingTrack.languageCode, language)) {
        return matchingTrack;
      }
    }

    // Fallback to first candidate
    return candidateTracks.firstOrNull;
  }

  /// Filters subtitle tracks based on SDH (hearing impaired) preference
  ///
  /// Values:
  /// - 0: Prefer non-SDH subtitles
  /// - 1: Prefer SDH subtitles
  /// - 2: Only show SDH subtitles
  /// - 3: Only show non-SDH subtitles
  static List<PlexSubtitleTrack> _filterBySDH(
    List<PlexSubtitleTrack> tracks,
    int preference,
  ) {
    if (preference == 0 || preference == 1) {
      // Prefer but don't require
      final preferSDH = preference == 1;
      final preferred = tracks.where((t) => _isSDH(t) == preferSDH).toList();
      return preferred.isNotEmpty ? preferred : tracks;
    } else if (preference == 2) {
      // Only SDH
      return tracks.where(_isSDH).toList();
    } else if (preference == 3) {
      // Only non-SDH
      return tracks.where((t) => !_isSDH(t)).toList();
    }
    return tracks;
  }

  /// Filters subtitle tracks based on forced subtitle preference
  ///
  /// Values:
  /// - 0: Prefer non-forced subtitles
  /// - 1: Prefer forced subtitles
  /// - 2: Only show forced subtitles
  /// - 3: Only show non-forced subtitles
  static List<PlexSubtitleTrack> _filterByForced(
    List<PlexSubtitleTrack> tracks,
    int preference,
  ) {
    if (preference == 0 || preference == 1) {
      // Prefer but don't require
      final preferForced = preference == 1;
      final preferred = tracks.where((t) => t.forced == preferForced).toList();
      return preferred.isNotEmpty ? preferred : tracks;
    } else if (preference == 2) {
      // Only forced
      return tracks.where((t) => t.forced).toList();
    } else if (preference == 3) {
      // Only non-forced
      return tracks.where((t) => !t.forced).toList();
    }
    return tracks;
  }

  /// Checks if a subtitle track is SDH (Subtitles for Deaf or Hard-of-Hearing)
  ///
  /// Since Plex API may not expose this directly, we infer from the title/displayTitle
  static bool _isSDH(PlexSubtitleTrack track) {
    final title = track.title?.toLowerCase() ?? '';
    final displayTitle = track.displayTitle?.toLowerCase() ?? '';

    // Look for common SDH indicators
    return title.contains('sdh') ||
        displayTitle.contains('sdh') ||
        title.contains('cc') ||
        displayTitle.contains('cc') ||
        title.contains('hearing impaired') ||
        displayTitle.contains('hearing impaired');
  }

  /// Checks if a language code matches a preferred language
  ///
  /// Handles both 2-letter (ISO 639-1) and 3-letter (ISO 639-2) codes
  static bool _matchesLanguage(
    String? trackLanguage,
    String? preferredLanguage,
  ) {
    if (trackLanguage == null || preferredLanguage == null) {
      return false;
    }

    final track = trackLanguage.toLowerCase();
    final preferred = preferredLanguage.toLowerCase();

    // Direct match
    if (track == preferred) return true;

    // Handle common 2-letter to 3-letter mappings
    final languageMap = {
      'en': 'eng',
      'es': 'spa',
      'fr': 'fra',
      'de': 'deu',
      'it': 'ita',
      'pt': 'por',
      'ja': 'jpn',
      'ko': 'kor',
      'zh': 'zho',
      'ru': 'rus',
      'ar': 'ara',
      'hi': 'hin',
      'nl': 'nld',
      'pl': 'pol',
      'tr': 'tur',
      'sv': 'swe',
      'no': 'nor',
      'da': 'dan',
      'fi': 'fin',
      'cs': 'ces',
      'hu': 'hun',
      'ro': 'ron',
      'th': 'tha',
      'vi': 'vie',
      'id': 'ind',
      'uk': 'ukr',
      'el': 'ell',
      'he': 'heb',
    };

    // Try mapping preferred to 3-letter and compare
    if (languageMap[preferred] == track) return true;

    // Try mapping track to 3-letter and compare with preferred 3-letter
    if (languageMap[track] == preferred) return true;

    // Try reverse mapping (3-letter to 2-letter)
    final reverseMap = languageMap.map((k, v) => MapEntry(v, k));
    if (reverseMap[preferred] == track) return true;
    if (reverseMap[track] == preferred) return true;

    return false;
  }
}
