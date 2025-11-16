import '../models/plex_media_info.dart';
import '../models/plex_metadata.dart';
import '../models/plex_user_profile.dart';
import '../utils/language_codes.dart';

/// Service for selecting audio and subtitle tracks based on user preferences
class TrackSelectionService {
  /// Selects the best audio track based on user preferences
  ///
  /// Priority order:
  /// 1. Per-media preferred audio language (from metadata.audioLanguage)
  /// 2. Profile-wide language preferences (if auto-select is enabled)
  /// 3. Plex's selected track (if auto-select is disabled)
  /// 4. First track
  ///
  /// Returns the selected audio track, or null if no suitable track is found
  static PlexAudioTrack? selectAudioTrack(
    List<PlexAudioTrack> tracks,
    PlexUserProfile profile, {
    PlexMetadata? metadata,
  }) {
    if (tracks.isEmpty) return null;

    // Priority 1: Check for per-media audio language preference
    if (metadata?.audioLanguage != null) {
      final perMediaTrack = tracks.firstWhere(
        (track) =>
            _matchesLanguage(track.languageCode, metadata!.audioLanguage),
        orElse: () => tracks.first,
      );
      // Only use it if we actually found a matching track
      if (_matchesLanguage(
        perMediaTrack.languageCode,
        metadata!.audioLanguage,
      )) {
        return perMediaTrack;
      }
    }

    // Priority 2: If auto-select is disabled, use Plex's selected track
    if (!profile.autoSelectAudio) {
      return tracks.firstWhere(
        (track) => track.selected,
        orElse: () => tracks.first,
      );
    }

    // Priority 3: Use profile-wide language preferences
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
  /// Priority order:
  /// 1. Per-media preferred subtitle language (from metadata.subtitleLanguage)
  /// 2. Profile-wide subtitle preferences (based on auto-select mode)
  /// 3. Disabled (null)
  ///
  /// Returns the selected subtitle track, or null if subtitles should be disabled
  static PlexSubtitleTrack? selectSubtitleTrack(
    List<PlexSubtitleTrack> tracks,
    PlexUserProfile profile,
    PlexAudioTrack? selectedAudioTrack, {
    PlexMetadata? metadata,
  }) {
    if (tracks.isEmpty) return null;

    // Priority 1: Check for per-media subtitle language preference
    if (metadata?.subtitleLanguage != null &&
        metadata!.subtitleLanguage!.isNotEmpty) {
      // Check if subtitle should be disabled (empty string or "none")
      if (metadata.subtitleLanguage == 'none' ||
          metadata.subtitleLanguage == '') {
        return null;
      }

      final perMediaTrack = tracks.firstWhere(
        (track) =>
            _matchesLanguage(track.languageCode, metadata.subtitleLanguage),
        orElse: () => tracks.first,
      );
      // Only use it if we actually found a matching track
      if (_matchesLanguage(
        perMediaTrack.languageCode,
        metadata.subtitleLanguage,
      )) {
        return perMediaTrack;
      }
    }

    // Priority 2: Use profile-wide subtitle preferences
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
  /// Also handles bibliographic variants and region codes (e.g., "en-US")
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

    // Extract base language codes (handle region codes like "en-US")
    final trackBase = track.split('-').first;
    final preferredBase = preferred.split('-').first;

    if (trackBase == preferredBase) return true;

    // Get all variations of the preferred language (e.g., "en" → ["en", "eng"])
    final variations = LanguageCodes.getVariations(preferredBase);

    // Check if track's base code matches any variation
    return variations.contains(trackBase);
  }
}
