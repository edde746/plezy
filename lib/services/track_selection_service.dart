import 'package:media_kit/media_kit.dart';

import '../models/plex_metadata.dart';
import '../models/plex_user_profile.dart';
import '../utils/app_logger.dart';
import '../utils/language_codes.dart';

/// Service for selecting and applying audio and subtitle tracks based on
/// preferences, user profiles, and per-media settings.
class TrackSelectionService {
  final Player player;
  final PlexUserProfile? profileSettings;
  final PlexMetadata metadata;

  TrackSelectionService({
    required this.player,
    this.profileSettings,
    required this.metadata,
  });

  /// Generic track matching for audio and subtitle tracks
  /// Returns the best matching track based on hierarchical criteria:
  /// 1. Exact match (id + title + language)
  /// 2. Partial match (title + language)
  /// 3. Language-only match
  T? findBestTrackMatch<T>(
    List<T> availableTracks,
    T preferred,
    String Function(T) getId,
    String? Function(T) getTitle,
    String? Function(T) getLanguage,
  ) {
    if (availableTracks.isEmpty) return null;

    // Filter out auto and no tracks
    final validTracks = availableTracks
        .where((t) => getId(t) != 'auto' && getId(t) != 'no')
        .toList();
    if (validTracks.isEmpty) return null;

    final preferredId = getId(preferred);
    final preferredTitle = getTitle(preferred);
    final preferredLanguage = getLanguage(preferred);

    // Try to match: id, title, and language
    for (var track in validTracks) {
      if (getId(track) == preferredId &&
          getTitle(track) == preferredTitle &&
          getLanguage(track) == preferredLanguage) {
        return track;
      }
    }

    // Try to match: title and language
    for (var track in validTracks) {
      if (getTitle(track) == preferredTitle &&
          getLanguage(track) == preferredLanguage) {
        return track;
      }
    }

    // Try to match: language only
    for (var track in validTracks) {
      if (getLanguage(track) == preferredLanguage) {
        return track;
      }
    }

    return null;
  }

  AudioTrack? findBestAudioMatch(
    List<AudioTrack> availableTracks,
    AudioTrack preferred,
  ) {
    return findBestTrackMatch<AudioTrack>(
      availableTracks,
      preferred,
      (t) => t.id,
      (t) => t.title,
      (t) => t.language,
    );
  }

  AudioTrack? findAudioTrackByProfile(
    List<AudioTrack> availableTracks,
    PlexUserProfile profile,
  ) {
    appLogger.d('Audio track selection using user profile');
    appLogger.d(
      'Profile settings - autoSelectAudio: ${profile.autoSelectAudio}, defaultAudioLanguage: ${profile.defaultAudioLanguage}, defaultAudioLanguages: ${profile.defaultAudioLanguages}',
    );

    if (availableTracks.isEmpty || !profile.autoSelectAudio) {
      appLogger.d(
        'Cannot use profile: ${availableTracks.isEmpty ? "No tracks available" : "autoSelectAudio is false"}',
      );
      return null;
    }

    // Build list of preferred languages
    final preferredLanguages = <String>[];
    if (profile.defaultAudioLanguage != null &&
        profile.defaultAudioLanguage!.isNotEmpty) {
      preferredLanguages.add(profile.defaultAudioLanguage!);
    }
    if (profile.defaultAudioLanguages != null) {
      preferredLanguages.addAll(profile.defaultAudioLanguages!);
    }

    if (preferredLanguages.isEmpty) {
      appLogger.d('Cannot use profile: No defaultAudioLanguage(s) specified');
      return null;
    }

    appLogger.d('Preferred languages: ${preferredLanguages.join(", ")}');

    // Try to find track matching any preferred language
    for (final preferredLanguage in preferredLanguages) {
      // Get all possible language code variations (e.g., "en" → ["en", "eng"])
      final languageVariations = LanguageCodes.getVariations(preferredLanguage);
      appLogger.d(
        'Checking language variations for "$preferredLanguage": ${languageVariations.join(", ")}',
      );

      for (var track in availableTracks) {
        final trackLang = track.language?.toLowerCase();
        if (trackLang != null && languageVariations.contains(trackLang)) {
          appLogger.d(
            'Found audio track matching profile language "$preferredLanguage" (matched: "$trackLang"): ${track.title ?? "Track ${track.id}"}',
          );
          return track;
        }
      }
    }

    appLogger.d(
      'No audio track found matching profile languages or their variations',
    );
    return null;
  }

  SubtitleTrack? findBestSubtitleMatch(
    List<SubtitleTrack> availableTracks,
    SubtitleTrack preferred,
  ) {
    // Handle special "no subtitles" case
    if (preferred.id == 'no') {
      return SubtitleTrack.no();
    }

    return findBestTrackMatch<SubtitleTrack>(
      availableTracks,
      preferred,
      (t) => t.id,
      (t) => t.title,
      (t) => t.language,
    );
  }

  SubtitleTrack? findSubtitleTrackByProfile(
    List<SubtitleTrack> availableTracks,
    PlexUserProfile profile, {
    AudioTrack? selectedAudioTrack,
  }) {
    appLogger.d('Subtitle track selection using user profile');
    appLogger.d(
      'Profile settings - autoSelectSubtitle: ${profile.autoSelectSubtitle}, defaultSubtitleLanguage: ${profile.defaultSubtitleLanguage}, defaultSubtitleLanguages: ${profile.defaultSubtitleLanguages}, defaultSubtitleForced: ${profile.defaultSubtitleForced}, defaultSubtitleAccessibility: ${profile.defaultSubtitleAccessibility}',
    );

    if (availableTracks.isEmpty) {
      appLogger.d('Cannot use profile: No subtitle tracks available');
      return null;
    }

    // Mode 0: Manually selected - return OFF
    if (profile.autoSelectSubtitle == 0) {
      appLogger.d(
        'Profile specifies manual mode (autoSelectSubtitle=0) - Subtitles OFF',
      );
      return SubtitleTrack.no();
    }

    // Mode 1: Shown with foreign audio
    if (profile.autoSelectSubtitle == 1) {
      appLogger.d(
        'Profile specifies foreign audio mode (autoSelectSubtitle=1)',
      );

      // Check if audio language matches user's preferred subtitle language
      if (selectedAudioTrack != null &&
          profile.defaultSubtitleLanguage != null) {
        final audioLang = selectedAudioTrack.language?.toLowerCase();
        final prefLang = profile.defaultSubtitleLanguage!.toLowerCase();
        final languageVariations = LanguageCodes.getVariations(prefLang);

        appLogger.d(
          'Checking if audio is foreign - audio: $audioLang, preferred subtitle lang: $prefLang',
        );

        // If audio matches preferred language, no subtitles needed
        if (audioLang != null && languageVariations.contains(audioLang)) {
          appLogger.d('Audio matches preferred language - Subtitles OFF');
          return SubtitleTrack.no();
        }
        appLogger.d('Foreign audio detected - enabling subtitles');
      }
      // Foreign audio detected or cannot determine, enable subtitles
    }

    // Mode 2: Always enabled (or continuing from mode 1 with foreign audio)
    appLogger.d('Selecting subtitle track based on preferences');

    // Build list of preferred languages
    final preferredLanguages = <String>[];
    if (profile.defaultSubtitleLanguage != null &&
        profile.defaultSubtitleLanguage!.isNotEmpty) {
      preferredLanguages.add(profile.defaultSubtitleLanguage!);
    }
    if (profile.defaultSubtitleLanguages != null) {
      preferredLanguages.addAll(profile.defaultSubtitleLanguages!);
    }

    if (preferredLanguages.isEmpty) {
      appLogger.d(
        'Cannot use profile: No defaultSubtitleLanguage(s) specified',
      );
      return null;
    }

    appLogger.d('Preferred languages: ${preferredLanguages.join(", ")}');

    // Apply filtering based on preferences
    var candidateTracks = availableTracks;

    // Filter by SDH (defaultSubtitleAccessibility: 0-3)
    candidateTracks = filterSubtitlesBySDH(
      candidateTracks,
      profile.defaultSubtitleAccessibility,
    );

    // Filter by forced subtitle preference (defaultSubtitleForced: 0-3)
    candidateTracks = filterSubtitlesByForced(
      candidateTracks,
      profile.defaultSubtitleForced,
    );

    // If no candidates after filtering, relax filters
    if (candidateTracks.isEmpty) {
      appLogger.d('No tracks match strict filters, relaxing filters');
      candidateTracks = availableTracks;
    }

    // Try to find track matching any preferred language
    for (final preferredLanguage in preferredLanguages) {
      final languageVariations = LanguageCodes.getVariations(preferredLanguage);
      appLogger.d(
        'Checking language variations for "$preferredLanguage": ${languageVariations.join(", ")}',
      );

      for (var track in candidateTracks) {
        final trackLang = track.language?.toLowerCase();
        if (trackLang != null && languageVariations.contains(trackLang)) {
          appLogger.d(
            'Found subtitle matching profile language "$preferredLanguage" (matched: "$trackLang"): ${track.title ?? "Track ${track.id}"}',
          );
          return track;
        }
      }
    }

    appLogger.d(
      'No subtitle track found matching profile languages or their variations',
    );
    return null;
  }

  /// Filters subtitle tracks based on SDH (Subtitles for Deaf or Hard-of-Hearing) preference
  ///
  /// Values:
  /// - 0: Prefer non-SDH subtitles
  /// - 1: Prefer SDH subtitles
  /// - 2: Only show SDH subtitles
  /// - 3: Only show non-SDH subtitles
  List<SubtitleTrack> filterSubtitlesBySDH(
    List<SubtitleTrack> tracks,
    int preference,
  ) {
    if (preference == 0 || preference == 1) {
      // Prefer but don't require
      final preferSDH = preference == 1;
      final preferred = tracks.where((t) => isSDH(t) == preferSDH).toList();
      if (preferred.isNotEmpty) {
        appLogger.d(
          'Applying SDH preference: ${preferSDH ? "prefer SDH" : "prefer non-SDH"} (${preferred.length} tracks)',
        );
        return preferred;
      }
      appLogger.d('No tracks match SDH preference, using all tracks');
      return tracks;
    } else if (preference == 2) {
      // Only SDH
      final filtered = tracks.where((t) => isSDH(t)).toList();
      appLogger.d('Filtering to SDH only (${filtered.length} tracks)');
      return filtered;
    } else if (preference == 3) {
      // Only non-SDH
      final filtered = tracks.where((t) => !isSDH(t)).toList();
      appLogger.d('Filtering to non-SDH only (${filtered.length} tracks)');
      return filtered;
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
  List<SubtitleTrack> filterSubtitlesByForced(
    List<SubtitleTrack> tracks,
    int preference,
  ) {
    if (preference == 0 || preference == 1) {
      // Prefer but don't require
      final preferForced = preference == 1;
      final preferred = tracks
          .where((t) => isForced(t) == preferForced)
          .toList();
      if (preferred.isNotEmpty) {
        appLogger.d(
          'Applying forced preference: ${preferForced ? "prefer forced" : "prefer non-forced"} (${preferred.length} tracks)',
        );
        return preferred;
      }
      appLogger.d('No tracks match forced preference, using all tracks');
      return tracks;
    } else if (preference == 2) {
      // Only forced
      final filtered = tracks.where((t) => isForced(t)).toList();
      appLogger.d('Filtering to forced only (${filtered.length} tracks)');
      return filtered;
    } else if (preference == 3) {
      // Only non-forced
      final filtered = tracks.where((t) => !isForced(t)).toList();
      appLogger.d('Filtering to non-forced only (${filtered.length} tracks)');
      return filtered;
    }
    return tracks;
  }

  /// Checks if a subtitle track is SDH (Subtitles for Deaf or Hard-of-Hearing)
  ///
  /// Since media_kit may not expose this directly, we infer from the title
  bool isSDH(SubtitleTrack track) {
    final title = track.title?.toLowerCase() ?? '';

    // Look for common SDH indicators
    return title.contains('sdh') ||
        title.contains('cc') ||
        title.contains('hearing impaired') ||
        title.contains('deaf');
  }

  /// Checks if a subtitle track is forced
  bool isForced(SubtitleTrack track) {
    final title = track.title?.toLowerCase() ?? '';
    return title.contains('forced');
  }

  /// Checks if a track language matches a preferred language
  ///
  /// Handles both 2-letter (ISO 639-1) and 3-letter (ISO 639-2) codes
  /// Also handles bibliographic variants and region codes (e.g., "en-US")
  bool languageMatches(String? trackLanguage, String? preferredLanguage) {
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

  /// Log available tracks for debugging
  void logAvailableTracks(
    List<AudioTrack> audioTracks,
    List<SubtitleTrack> subtitleTracks,
  ) {
    appLogger.d('Available audio tracks: ${audioTracks.length}');
    for (var track in audioTracks) {
      appLogger.d(
        '  - ${track.title ?? "Track ${track.id}"} (${track.language ?? "unknown"}) ${track.isDefault == true ? "[DEFAULT]" : ""}',
      );
    }
    appLogger.d('Available subtitle tracks: ${subtitleTracks.length}');
    for (var track in subtitleTracks) {
      appLogger.d(
        '  - ${track.title ?? "Track ${track.id}"} (${track.language ?? "unknown"}) ${track.isDefault == true ? "[DEFAULT]" : ""}',
      );
    }
  }

  /// Select the best audio track based on priority:
  /// Priority 1: Preferred track from navigation
  /// Priority 2: Per-media language preference
  /// Priority 3: User profile preferences
  /// Priority 4: Default or first track
  AudioTrack? selectAudioTrack(
    List<AudioTrack> availableTracks,
    AudioTrack? preferredAudioTrack,
  ) {
    if (availableTracks.isEmpty) return null;

    AudioTrack? trackToSelect;

    // Priority 1: Try to match preferred track from navigation
    if (preferredAudioTrack != null) {
      appLogger.d('Priority 1: Checking preferred track from navigation');
      appLogger.d(
        '  Preferred: ${preferredAudioTrack.title ?? "Track ${preferredAudioTrack.id}"} (${preferredAudioTrack.language ?? "unknown"})',
      );
      trackToSelect = findBestAudioMatch(availableTracks, preferredAudioTrack);
      if (trackToSelect != null) {
        appLogger.d('  Matched preferred track');
        return trackToSelect;
      }
      appLogger.d('  No match found for preferred track');
    } else {
      appLogger.d('Priority 1: No preferred track from navigation');
    }

    // Priority 2: If no preferred track matched, try per-media language preference
    if (metadata.audioLanguage != null) {
      appLogger.d('Priority 2: Checking per-media audio language preference');
      appLogger.d('  Per-media audio language: ${metadata.audioLanguage}');

      final matchedTrack = availableTracks.firstWhere(
        (track) => languageMatches(track.language, metadata.audioLanguage),
        orElse: () => availableTracks.first,
      );

      if (languageMatches(matchedTrack.language, metadata.audioLanguage)) {
        appLogger.d('  Matched per-media audio language preference');
        return matchedTrack;
      }
      appLogger.d('  No match found for per-media audio language');
    } else {
      appLogger.d('Priority 2: No per-media audio language preference');
    }

    // Priority 3: If no preferred track matched, try user profile preferences
    if (profileSettings != null) {
      appLogger.d('Priority 3: Checking user profile preferences');
      trackToSelect = findAudioTrackByProfile(
        availableTracks,
        profileSettings!,
      );
      if (trackToSelect != null) {
        return trackToSelect;
      }
    } else {
      appLogger.d('Priority 3: No user profile available');
    }

    // Priority 4: If no match, use default or first track
    appLogger.d('Priority 4: Using default or first available track');
    trackToSelect = availableTracks.firstWhere(
      (t) => t.isDefault == true,
      orElse: () => availableTracks.first,
    );
    final isDefault = trackToSelect.isDefault == true;
    appLogger.d(
      '  Selected ${isDefault ? "default" : "first"} track: ${trackToSelect.title ?? "Track ${trackToSelect.id}"} (${trackToSelect.language ?? "unknown"})',
    );

    return trackToSelect;
  }

  /// Select the best subtitle track based on priority:
  /// Priority 1: Preferred track from navigation
  /// Priority 2: Per-media language preference
  /// Priority 3: User profile preferences
  /// Priority 4: Default track
  /// Priority 5: Off
  SubtitleTrack selectSubtitleTrack(
    List<SubtitleTrack> availableTracks,
    SubtitleTrack? preferredSubtitleTrack,
    AudioTrack? selectedAudioTrack,
  ) {
    SubtitleTrack? subtitleToSelect;

    // Priority 1: Try preferred track from navigation (always wins)
    if (preferredSubtitleTrack != null) {
      appLogger.d('Priority 1: Checking preferred track from navigation');
      if (preferredSubtitleTrack.id == 'no') {
        appLogger.d('  Preferred: OFF');
        return SubtitleTrack.no();
      } else if (availableTracks.isNotEmpty) {
        appLogger.d(
          '  Preferred: ${preferredSubtitleTrack.title ?? "Track ${preferredSubtitleTrack.id}"} (${preferredSubtitleTrack.language ?? "unknown"})',
        );
        subtitleToSelect = findBestSubtitleMatch(
          availableTracks,
          preferredSubtitleTrack,
        );
        if (subtitleToSelect != null) {
          appLogger.d('  Matched preferred track');
          return subtitleToSelect;
        }
        appLogger.d('  No match found for preferred track');
      }
    } else {
      appLogger.d('Priority 1: No preferred track from navigation');
    }

    // Priority 2: If no preferred match, try per-media language preference
    if (metadata.subtitleLanguage != null) {
      appLogger.d(
        'Priority 2: Checking per-media subtitle language preference',
      );
      appLogger.d(
        '  Per-media subtitle language: ${metadata.subtitleLanguage}',
      );

      // Check if subtitle should be disabled
      if (metadata.subtitleLanguage == 'none' ||
          metadata.subtitleLanguage!.isEmpty) {
        appLogger.d('  Per-media preference: Subtitles OFF');
        return SubtitleTrack.no();
      } else if (availableTracks.isNotEmpty) {
        final matchedTrack = availableTracks.firstWhere(
          (track) => languageMatches(track.language, metadata.subtitleLanguage),
          orElse: () => availableTracks.first,
        );
        if (languageMatches(matchedTrack.language, metadata.subtitleLanguage)) {
          appLogger.d('  Matched per-media subtitle language preference');
          return matchedTrack;
        }
        appLogger.d('  No match found for per-media subtitle language');
      }
    } else {
      appLogger.d('Priority 2: No per-media subtitle language preference');
    }

    // Priority 3: If no preferred match, apply user profile preferences
    if (profileSettings != null && availableTracks.isNotEmpty) {
      appLogger.d('Priority 3: Checking user profile preferences');
      subtitleToSelect = findSubtitleTrackByProfile(
        availableTracks,
        profileSettings!,
        selectedAudioTrack: selectedAudioTrack,
      );
      if (subtitleToSelect != null) {
        return subtitleToSelect;
      }
    } else if (availableTracks.isNotEmpty) {
      appLogger.d('Priority 3: No user profile available');
    }

    // Priority 4: If no profile match, check for default subtitle
    if (availableTracks.isNotEmpty) {
      appLogger.d('Priority 4: Checking for default subtitle track');
      final defaultTrack = availableTracks.firstWhere(
        (t) => t.isDefault == true,
        orElse: () => availableTracks.first,
      );
      if (defaultTrack.isDefault == true) {
        appLogger.d(
          '  Found default track: ${defaultTrack.title ?? "Track ${defaultTrack.id}"} (${defaultTrack.language ?? "unknown"})',
        );
        return defaultTrack;
      }
      appLogger.d('  No default subtitle track found');
    }

    // Priority 5: If still no subtitle selected, turn off
    appLogger.d('Priority 5: No subtitle selected - Subtitles OFF');
    return SubtitleTrack.no();
  }

  /// Select and apply audio and subtitle tracks based on preferences
  Future<void> selectAndApplyTracks({
    AudioTrack? preferredAudioTrack,
    SubtitleTrack? preferredSubtitleTrack,
    double? preferredPlaybackRate,
    Function(AudioTrack)? onAudioTrackChanged,
    Function(SubtitleTrack)? onSubtitleTrackChanged,
  }) async {
    // Wait for tracks to be loaded
    int attempts = 0;
    while (player.state.tracks.audio.isEmpty &&
        player.state.tracks.subtitle.isEmpty &&
        attempts < 100) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    appLogger.d('Starting track selection process');

    // Get real tracks (excluding auto and no)
    final realAudioTracks = player.state.tracks.audio
        .where((t) => t.id != 'auto' && t.id != 'no')
        .toList();
    final realSubtitleTracks = player.state.tracks.subtitle
        .where((t) => t.id != 'auto' && t.id != 'no')
        .toList();

    // Log available tracks
    logAvailableTracks(realAudioTracks, realSubtitleTracks);

    // Select and apply audio track
    appLogger.d('Audio track selection');
    final selectedAudioTrack = selectAudioTrack(
      realAudioTracks,
      preferredAudioTrack,
    );
    if (selectedAudioTrack != null) {
      appLogger.i(
        'Final audio selection: ${selectedAudioTrack.title ?? "Track ${selectedAudioTrack.id}"} (${selectedAudioTrack.language ?? "unknown"})',
      );
      player.setAudioTrack(selectedAudioTrack);
    } else {
      appLogger.d('No audio tracks available');
    }

    // Select and apply subtitle track
    appLogger.d('Subtitle track selection');
    final selectedSubtitleTrack = selectSubtitleTrack(
      realSubtitleTracks,
      preferredSubtitleTrack,
      selectedAudioTrack,
    );
    final finalSubtitle = selectedSubtitleTrack.id == 'no'
        ? 'OFF'
        : '${selectedSubtitleTrack.title ?? "Track ${selectedSubtitleTrack.id}"} (${selectedSubtitleTrack.language ?? "unknown"})';
    appLogger.i('Final subtitle selection: $finalSubtitle');
    player.setSubtitleTrack(selectedSubtitleTrack);

    // Set playback rate if preferred rate was provided
    if (preferredPlaybackRate != null) {
      appLogger.d('Setting preferred playback rate: ${preferredPlaybackRate}x');
      player.setRate(preferredPlaybackRate);
    }

    appLogger.d('Track selection complete');
  }
}
