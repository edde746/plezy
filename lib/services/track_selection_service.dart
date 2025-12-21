import '../mpv/mpv.dart';

import '../models/plex_media_info.dart';
import '../models/plex_metadata.dart';
import '../models/plex_user_profile.dart';
import '../utils/app_logger.dart';
import '../utils/language_codes.dart';

/// Priority levels for track selection
enum TrackSelectionPriority {
  navigation, // Priority 1: User's manual selection from previous episode
  plexSelected, // Priority 2: Plex's selected track
  perMedia, // Priority 3: Per-media language preference
  profile, // Priority 4: User profile preferences
  defaultTrack, // Priority 5: Default or first track
  off, // Priority 6: Subtitles off (subtitle only)
}

/// Result of track selection including the selected track and which priority was used
class TrackSelectionResult<T> {
  final T track;
  final TrackSelectionPriority priority;

  TrackSelectionResult(this.track, this.priority);
}

/// Service for selecting and applying audio and subtitle tracks based on
/// preferences, user profiles, and per-media settings.
class TrackSelectionService {
  final Player player;
  final PlexUserProfile? profileSettings;
  final PlexMetadata metadata;
  final PlexMediaInfo? plexMediaInfo;

  TrackSelectionService({
    required this.player,
    this.profileSettings,
    required this.metadata,
    this.plexMediaInfo,
  });

  /// Build list of preferred languages from a user profile
  List<String> _buildPreferredLanguages(PlexUserProfile profile, {required bool isAudio}) {
    final primary = isAudio ? profile.defaultAudioLanguage : profile.defaultSubtitleLanguage;
    final list = isAudio ? profile.defaultAudioLanguages : profile.defaultSubtitleLanguages;

    final result = <String>[];
    if (primary != null && primary.isNotEmpty) {
      result.add(primary);
    }
    if (list != null) {
      result.addAll(list);
    }
    return result;
  }

  /// Find a track by preferred language with variation lookup and logging
  T? _findTrackByPreferredLanguage<T>(
    List<T> tracks,
    String preferredLanguage,
    String? Function(T) getLanguage,
    String Function(T) getDescription,
    String trackType,
  ) {
    final languageVariations = LanguageCodes.getVariations(preferredLanguage);
    return _findTrackByLanguageVariations<T>(
      tracks,
      preferredLanguage,
      languageVariations,
      getLanguage,
      getDescription,
      trackType,
    );
  }

  /// Apply a filter to tracks, falling back to original if filter produces empty result
  List<T> _applyFilterWithFallback<T>(List<T> tracks, List<T> Function(List<T>) filter, String filterDescription) {
    final filtered = filter(tracks);
    return filtered.isNotEmpty ? filtered : tracks;
  }

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
    final validTracks = availableTracks.where((t) => getId(t) != 'auto' && getId(t) != 'no').toList();
    if (validTracks.isEmpty) return null;

    final preferredId = getId(preferred);
    final preferredTitle = getTitle(preferred);
    final preferredLanguage = getLanguage(preferred);

    // Try to match: id, title, and language
    for (var track in validTracks) {
      if (getId(track) == preferredId && getTitle(track) == preferredTitle && getLanguage(track) == preferredLanguage) {
        return track;
      }
    }

    // Try to match: title and language
    for (var track in validTracks) {
      if (getTitle(track) == preferredTitle && getLanguage(track) == preferredLanguage) {
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

  AudioTrack? findBestAudioMatch(List<AudioTrack> availableTracks, AudioTrack preferred) {
    return findBestTrackMatch<AudioTrack>(availableTracks, preferred, (t) => t.id, (t) => t.title, (t) => t.language);
  }

  AudioTrack? findAudioTrackByProfile(List<AudioTrack> availableTracks, PlexUserProfile profile) {
    if (availableTracks.isEmpty || !profile.autoSelectAudio) return null;

    final preferredLanguages = _buildPreferredLanguages(profile, isAudio: true);
    if (preferredLanguages.isEmpty) return null;

    for (final preferredLanguage in preferredLanguages) {
      final match = _findTrackByPreferredLanguage<AudioTrack>(
        availableTracks,
        preferredLanguage,
        (t) => t.language,
        (t) => t.title ?? 'Track ${t.id}',
        'audio track',
      );
      if (match != null) return match;
    }

    return null;
  }

  SubtitleTrack? findBestSubtitleMatch(List<SubtitleTrack> availableTracks, SubtitleTrack preferred) {
    // Handle special "no subtitles" case
    if (preferred.id == 'no') {
      return SubtitleTrack.off;
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
    if (availableTracks.isEmpty) return null;

    // Mode 0: Manually selected - return OFF
    if (profile.autoSelectSubtitle == 0) return SubtitleTrack.off;

    // Mode 1: Shown with foreign audio
    if (profile.autoSelectSubtitle == 1) {
      if (selectedAudioTrack != null && profile.defaultSubtitleLanguage != null) {
        final audioLang = selectedAudioTrack.language?.toLowerCase();
        final prefLang = profile.defaultSubtitleLanguage!.toLowerCase();
        final languageVariations = LanguageCodes.getVariations(prefLang);

        // If audio matches preferred language, no subtitles needed
        if (audioLang != null && languageVariations.contains(audioLang)) {
          return SubtitleTrack.off;
        }
      }
    }

    // Mode 2: Always enabled (or continuing from mode 1 with foreign audio)
    final preferredLanguages = _buildPreferredLanguages(profile, isAudio: false);
    if (preferredLanguages.isEmpty) return null;

    // Apply filtering with fallback to original tracks if filter produces empty result
    var candidateTracks = availableTracks;
    candidateTracks = filterSubtitlesBySDH(candidateTracks, profile.defaultSubtitleAccessibility);
    candidateTracks = filterSubtitlesByForced(candidateTracks, profile.defaultSubtitleForced);
    candidateTracks = _applyFilterWithFallback(availableTracks, (_) => candidateTracks, 'strict filters');

    for (final preferredLanguage in preferredLanguages) {
      final match = _findTrackByPreferredLanguage<SubtitleTrack>(
        candidateTracks,
        preferredLanguage,
        (t) => t.language,
        (t) => t.title ?? 'Track ${t.id}',
        'subtitle',
      );
      if (match != null) return match;
    }

    return null;
  }

  /// Filters subtitle tracks based on SDH (Subtitles for Deaf or Hard-of-Hearing) preference
  ///
  /// Values:
  /// - 0: Prefer non-SDH subtitles
  /// - 1: Prefer SDH subtitles
  /// - 2: Only show SDH subtitles
  /// - 3: Only show non-SDH subtitles
  List<SubtitleTrack> filterSubtitlesBySDH(List<SubtitleTrack> tracks, int preference) {
    if (preference == 0 || preference == 1) {
      final preferSDH = preference == 1;
      final preferred = tracks.where((t) => isSDH(t) == preferSDH).toList();
      return preferred.isNotEmpty ? preferred : tracks;
    } else if (preference == 2) {
      return tracks.where((t) => isSDH(t)).toList();
    } else if (preference == 3) {
      return tracks.where((t) => !isSDH(t)).toList();
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
  List<SubtitleTrack> filterSubtitlesByForced(List<SubtitleTrack> tracks, int preference) {
    if (preference == 0 || preference == 1) {
      final preferForced = preference == 1;
      final preferred = tracks.where((t) => isForced(t) == preferForced).toList();
      return preferred.isNotEmpty ? preferred : tracks;
    } else if (preference == 2) {
      return tracks.where((t) => isForced(t)).toList();
    } else if (preference == 3) {
      return tracks.where((t) => !isForced(t)).toList();
    }
    return tracks;
  }

  /// Checks if a subtitle track is SDH (Subtitles for Deaf or Hard-of-Hearing)
  ///
  /// Since mpv may not expose this directly, we infer from the title
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

  /// Find a track matching a preferred language from a list of tracks
  /// Returns the first track whose language matches any variation of the preferred language
  T? _findTrackByLanguageVariations<T>(
    List<T> tracks,
    String preferredLanguage,
    List<String> languageVariations,
    String? Function(T) getLanguage,
    String Function(T) getTrackDescription,
    String trackType,
  ) {
    for (var track in tracks) {
      final trackLang = getLanguage(track)?.toLowerCase();
      if (trackLang != null && languageVariations.any((lang) => trackLang.startsWith(lang))) {
        return track;
      }
    }
    return null;
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

  /// Select the best audio track based on priority:
  /// Priority 1: Preferred track from navigation
  /// Priority 2: Plex-selected track from media info
  /// Priority 3: Per-media language preference
  /// Priority 4: User profile preferences
  /// Priority 5: Default or first track
  TrackSelectionResult<AudioTrack>? selectAudioTrack(List<AudioTrack> availableTracks, AudioTrack? preferredAudioTrack) {
    if (availableTracks.isEmpty) return null;

    AudioTrack? trackToSelect;

    // Priority 1: Try to match preferred track from navigation
    if (preferredAudioTrack != null) {
      trackToSelect = findBestAudioMatch(availableTracks, preferredAudioTrack);
      if (trackToSelect != null) {
        return TrackSelectionResult(trackToSelect, TrackSelectionPriority.navigation);
      }
    }

    // Priority 2: Check Plex-selected track from media info
    if (plexMediaInfo != null) {
      final plexAudioTracks = plexMediaInfo!.audioTracks;
      final plexSelectedIndex = plexAudioTracks.indexWhere((t) => t.selected);
      if (plexSelectedIndex >= 0 && plexSelectedIndex < availableTracks.length) {
        return TrackSelectionResult(availableTracks[plexSelectedIndex], TrackSelectionPriority.plexSelected);
      }
    }

    // Priority 3: Try per-media language preference
    if (metadata.audioLanguage != null) {
      final matchedTrack = availableTracks.firstWhere(
        (track) => languageMatches(track.language, metadata.audioLanguage),
        orElse: () => availableTracks.first,
      );
      if (languageMatches(matchedTrack.language, metadata.audioLanguage)) {
        return TrackSelectionResult(matchedTrack, TrackSelectionPriority.perMedia);
      }
    }

    // Priority 4: Try user profile preferences
    if (profileSettings != null) {
      trackToSelect = findAudioTrackByProfile(availableTracks, profileSettings!);
      if (trackToSelect != null) {
        return TrackSelectionResult(trackToSelect, TrackSelectionPriority.profile);
      }
    }

    // Priority 5: Use default or first track
    trackToSelect = availableTracks.firstWhere((t) => t.isDefault == true, orElse: () => availableTracks.first);
    return TrackSelectionResult(trackToSelect, TrackSelectionPriority.defaultTrack);
  }

  /// Select the best subtitle track based on priority:
  /// Priority 1: Preferred track from navigation
  /// Priority 2: Plex-selected track from media info
  /// Priority 3: Per-media language preference
  /// Priority 4: User profile preferences
  /// Priority 5: Default track
  /// Priority 6: Off
  TrackSelectionResult<SubtitleTrack> selectSubtitleTrack(
    List<SubtitleTrack> availableTracks,
    SubtitleTrack? preferredSubtitleTrack,
    AudioTrack? selectedAudioTrack,
  ) {
    SubtitleTrack? subtitleToSelect;

    // Priority 1: Try preferred track from navigation
    if (preferredSubtitleTrack != null) {
      if (preferredSubtitleTrack.id == 'no') {
        return TrackSelectionResult(SubtitleTrack.off, TrackSelectionPriority.navigation);
      } else if (availableTracks.isNotEmpty) {
        subtitleToSelect = findBestSubtitleMatch(availableTracks, preferredSubtitleTrack);
        if (subtitleToSelect != null) {
          return TrackSelectionResult(subtitleToSelect, TrackSelectionPriority.navigation);
        }
      }
    }

    // Priority 2: Check Plex-selected track from media info
    if (plexMediaInfo != null && availableTracks.isNotEmpty) {
      final plexSubtitleTracks = plexMediaInfo!.subtitleTracks;
      final plexSelectedIndex = plexSubtitleTracks.indexWhere((t) => t.selected);
      if (plexSelectedIndex >= 0 && plexSelectedIndex < availableTracks.length) {
        return TrackSelectionResult(availableTracks[plexSelectedIndex], TrackSelectionPriority.plexSelected);
      }
    }

    // Priority 3: Try per-media language preference
    if (metadata.subtitleLanguage != null) {
      if (metadata.subtitleLanguage == 'none' || metadata.subtitleLanguage!.isEmpty) {
        return TrackSelectionResult(SubtitleTrack.off, TrackSelectionPriority.perMedia);
      } else if (availableTracks.isNotEmpty) {
        final matchedTrack = availableTracks.firstWhere(
          (track) => languageMatches(track.language, metadata.subtitleLanguage),
          orElse: () => availableTracks.first,
        );
        if (languageMatches(matchedTrack.language, metadata.subtitleLanguage)) {
          return TrackSelectionResult(matchedTrack, TrackSelectionPriority.perMedia);
        }
      }
    }

    // Priority 4: Apply user profile preferences
    if (profileSettings != null && availableTracks.isNotEmpty) {
      subtitleToSelect = findSubtitleTrackByProfile(
        availableTracks,
        profileSettings!,
        selectedAudioTrack: selectedAudioTrack,
      );
      if (subtitleToSelect != null) {
        return TrackSelectionResult(subtitleToSelect, TrackSelectionPriority.profile);
      }
    }

    // Priority 5: Check for default subtitle
    if (availableTracks.isNotEmpty) {
      final defaultTrack = availableTracks.firstWhere((t) => t.isDefault == true, orElse: () => availableTracks.first);
      if (defaultTrack.isDefault == true) {
        return TrackSelectionResult(defaultTrack, TrackSelectionPriority.defaultTrack);
      }
    }

    // Priority 6: Turn off subtitles
    return TrackSelectionResult(SubtitleTrack.off, TrackSelectionPriority.off);
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
    while (player.state.tracks.audio.isEmpty && player.state.tracks.subtitle.isEmpty && attempts < 100) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    // Get real tracks (excluding auto and no)
    final realAudioTracks = player.state.tracks.audio.where((t) => t.id != 'auto' && t.id != 'no').toList();
    final realSubtitleTracks = player.state.tracks.subtitle.where((t) => t.id != 'auto' && t.id != 'no').toList();

    // Select and apply audio track
    final audioResult = selectAudioTrack(realAudioTracks, preferredAudioTrack);
    AudioTrack? selectedAudioTrack;
    if (audioResult != null) {
      selectedAudioTrack = audioResult.track;
      appLogger.d(
        'Audio: ${selectedAudioTrack.title ?? selectedAudioTrack.language ?? "Track ${selectedAudioTrack.id}"} [${audioResult.priority.name}]',
      );
      player.selectAudioTrack(selectedAudioTrack);

      // Save to Plex if this was user's navigation preference (Priority 1)
      if (audioResult.priority == TrackSelectionPriority.navigation && onAudioTrackChanged != null) {
        onAudioTrackChanged(selectedAudioTrack);
      }
    }

    // Select and apply subtitle track
    final subtitleResult = selectSubtitleTrack(realSubtitleTracks, preferredSubtitleTrack, selectedAudioTrack);
    final selectedSubtitleTrack = subtitleResult.track;
    final subtitleName = selectedSubtitleTrack.id == 'no'
        ? 'OFF'
        : (selectedSubtitleTrack.title ?? selectedSubtitleTrack.language ?? 'Track ${selectedSubtitleTrack.id}');
    appLogger.d('Subtitle: $subtitleName [${subtitleResult.priority.name}]');
    player.selectSubtitleTrack(selectedSubtitleTrack);

    // Save to Plex if this was user's navigation preference (Priority 1)
    if (subtitleResult.priority == TrackSelectionPriority.navigation && onSubtitleTrackChanged != null) {
      onSubtitleTrackChanged(selectedSubtitleTrack);
    }

    // Set playback rate if preferred rate was provided
    if (preferredPlaybackRate != null) {
      player.setRate(preferredPlaybackRate);
    }
  }
}
