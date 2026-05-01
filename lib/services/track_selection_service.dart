import 'dart:async';

import '../mpv/mpv.dart';

import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../media/media_server_user_profile.dart';
import '../media/media_source_info.dart';
import '../utils/future_extensions.dart';
import '../utils/app_logger.dart';
import '../utils/language_codes.dart';

// These functions match MPV tracks to Plex tracks by properties (language,
// codec, title, etc.) instead of list index, since the two may be ordered
// differently.

/// Score how well an MPV subtitle track matches a Plex subtitle track.
/// Language (+10 / +1 exact) and codec (+5) carry the most weight; title,
/// forced flag, and identical ordinal position (only when [ordinalMatches]
/// is true) add smaller nudges.
int _scoreSubtitleMatch(SubtitleTrack mpvTrack, MediaSubtitleTrack plexTrack, {required bool ordinalMatches}) {
  int score = 0;

  if (_languagesMatch(mpvTrack.language, plexTrack.languageCode)) {
    score += 10;
    if (_languageCodesExactMatch(mpvTrack.language, plexTrack.languageCode)) {
      score += 1;
    }
  }

  if (_subtitleCodecsMatch(mpvTrack.codec, plexTrack.codec)) {
    score += 5;
  }

  score += _titleScore(mpvTrack.title, plexTrack.title, plexTrack.displayTitle);

  if (mpvTrack.isForced == plexTrack.forced) {
    score += 2;
  }

  if (ordinalMatches) {
    score += 1;
  }

  return score;
}

/// Score how well an MPV audio track matches a Plex audio track.
/// Language (+10 / +1 exact) and codec (+5) dominate; channel count (+3),
/// title match (+2), and identical ordinal position ([ordinalMatches], +1)
/// act as tiebreakers.
int _scoreAudioMatch(AudioTrack mpvTrack, MediaAudioTrack plexTrack, {required bool ordinalMatches}) {
  int score = 0;

  if (_languagesMatch(mpvTrack.language, plexTrack.languageCode)) {
    score += 10;
    if (_languageCodesExactMatch(mpvTrack.language, plexTrack.languageCode)) {
      score += 1;
    }
  }

  if (_audioCodecsMatch(mpvTrack.codec, plexTrack.codec)) {
    score += 5;
  }

  if (mpvTrack.channels != null && plexTrack.channels != null && mpvTrack.channels == plexTrack.channels) {
    score += 3;
  }

  if (_titlesMatch(mpvTrack.title, plexTrack.title, plexTrack.displayTitle)) {
    score += 2;
  }

  if (ordinalMatches) {
    score += 1;
  }

  return score;
}

/// Find the MPV subtitle track that matches a Plex subtitle track
SubtitleTrack? findMpvTrackForPlexSubtitle(
  MediaSubtitleTrack plexTrack,
  List<SubtitleTrack> mpvTracks, {
  List<MediaSubtitleTrack>? allPlexTracks,
}) {
  if (mpvTracks.isEmpty) return null;

  // For external subtitles, match by URI containing the Plex key
  if (plexTrack.isExternal && plexTrack.key != null) {
    for (final mpvTrack in mpvTracks) {
      if (mpvTrack.isExternal && mpvTrack.uri != null) {
        // Check if the MPV URI contains the Plex key path
        if (mpvTrack.uri!.contains(plexTrack.key!)) {
          return mpvTrack;
        }
      }
    }
  }

  // For internal subtitles, use scoring based on properties
  SubtitleTrack? bestMatch;
  int bestScore = 0;

  // Ordinal tiebreaker: precompute position of plexTrack among internal tracks
  final internalMpvTracks = allPlexTracks != null ? mpvTracks.where((t) => !t.isExternal).toList() : null;
  final plexOrdinal = allPlexTracks != null
      ? allPlexTracks.where((t) => !t.isExternal).toList().indexOf(plexTrack)
      : -1;

  for (final mpvTrack in mpvTracks) {
    // Skip external tracks when matching internal Plex tracks
    if (!plexTrack.isExternal && mpvTrack.isExternal) continue;

    final ordinalMatches =
        internalMpvTracks != null && plexOrdinal >= 0 && internalMpvTracks.indexOf(mpvTrack) == plexOrdinal;

    final score = _scoreSubtitleMatch(mpvTrack, plexTrack, ordinalMatches: ordinalMatches);

    if (score > bestScore) {
      bestScore = score;
      bestMatch = mpvTrack;
    }
  }

  // Require at least language match for a valid match
  return bestScore >= 10 ? bestMatch : null;
}

/// Find the Plex subtitle track that matches an MPV subtitle track
MediaSubtitleTrack? findPlexTrackForMpvSubtitle(
  SubtitleTrack mpvTrack,
  List<MediaSubtitleTrack> plexTracks, {
  List<SubtitleTrack>? allMpvTracks,
}) {
  if (plexTracks.isEmpty) return null;

  // For external subtitles, match by URI containing the Plex key
  if (mpvTrack.isExternal && mpvTrack.uri != null) {
    for (final plexTrack in plexTracks) {
      if (plexTrack.isExternal && plexTrack.key != null) {
        if (mpvTrack.uri!.contains(plexTrack.key!)) {
          return plexTrack;
        }
      }
    }
  }

  // For internal subtitles, use scoring based on properties
  MediaSubtitleTrack? bestMatch;
  int bestScore = 0;

  // Ordinal tiebreaker: precompute position of mpvTrack among internal tracks
  final internalPlexTracks = allMpvTracks != null ? plexTracks.where((t) => !t.isExternal).toList() : null;
  final mpvOrdinal = allMpvTracks != null ? allMpvTracks.where((t) => !t.isExternal).toList().indexOf(mpvTrack) : -1;

  for (final plexTrack in plexTracks) {
    // Skip external Plex tracks when matching internal MPV tracks
    if (!mpvTrack.isExternal && plexTrack.isExternal) continue;

    final ordinalMatches =
        internalPlexTracks != null && mpvOrdinal >= 0 && internalPlexTracks.indexOf(plexTrack) == mpvOrdinal;

    final score = _scoreSubtitleMatch(mpvTrack, plexTrack, ordinalMatches: ordinalMatches);

    if (score > bestScore) {
      bestScore = score;
      bestMatch = plexTrack;
    }
  }

  // Require at least language match for a valid match
  return bestScore >= 10 ? bestMatch : null;
}

/// Find the MPV audio track that matches a Plex audio track
AudioTrack? findMpvTrackForPlexAudio(
  MediaAudioTrack plexTrack,
  List<AudioTrack> mpvTracks, {
  List<MediaAudioTrack>? allPlexTracks,
}) {
  if (mpvTracks.isEmpty) return null;

  AudioTrack? bestMatch;
  int bestScore = 0;
  final plexOrdinal = allPlexTracks?.indexOf(plexTrack) ?? -1;

  for (final mpvTrack in mpvTracks) {
    final ordinalMatches = plexOrdinal >= 0 && mpvTracks.indexOf(mpvTrack) == plexOrdinal;

    final score = _scoreAudioMatch(mpvTrack, plexTrack, ordinalMatches: ordinalMatches);

    if (score > bestScore) {
      bestScore = score;
      bestMatch = mpvTrack;
    }
  }

  // Require at least language match for a valid match
  return bestScore >= 10 ? bestMatch : null;
}

/// Find the Plex audio track that matches an MPV audio track
MediaAudioTrack? findPlexTrackForMpvAudio(
  AudioTrack mpvTrack,
  List<MediaAudioTrack> plexTracks, {
  List<AudioTrack>? allMpvTracks,
}) {
  if (plexTracks.isEmpty) return null;

  MediaAudioTrack? bestMatch;
  int bestScore = 0;
  final mpvOrdinal = allMpvTracks?.indexOf(mpvTrack) ?? -1;

  for (final plexTrack in plexTracks) {
    final ordinalMatches = mpvOrdinal >= 0 && plexTracks.indexOf(plexTrack) == mpvOrdinal;

    final score = _scoreAudioMatch(mpvTrack, plexTrack, ordinalMatches: ordinalMatches);

    if (score > bestScore) {
      bestScore = score;
      bestMatch = plexTrack;
    }
  }

  // Require at least language match for a valid match
  return bestScore >= 10 ? bestMatch : null;
}

/// Check if two language codes match exactly (after normalizing case and stripping region suffixes)
bool _languageCodesExactMatch(String? a, String? b) {
  if (a == null || b == null) return false;
  return a.toLowerCase().split('-').first == b.toLowerCase().split('-').first;
}

/// Check if two language codes refer to the same language
/// Handles both ISO 639-1 (2-letter) and ISO 639-2 (3-letter) codes
bool _languagesMatch(String? mpvLang, String? plexLang) {
  if (mpvLang == null || plexLang == null) return false;

  final mpvNormalized = mpvLang.toLowerCase().split('-').first;
  final plexNormalized = plexLang.toLowerCase().split('-').first;

  // Direct match
  if (mpvNormalized == plexNormalized) return true;

  final mpvVariations = LanguageCodes.getVariations(mpvNormalized);
  return mpvVariations.contains(plexNormalized);
}

/// Check if two subtitle codec strings match
/// Handles common aliases (e.g., subrip/srt, ass/ssa)
bool _subtitleCodecsMatch(String? mpvCodec, String? plexCodec) {
  if (mpvCodec == null || plexCodec == null) return false;

  final mpvNorm = mpvCodec.toLowerCase();
  final plexNorm = plexCodec.toLowerCase();

  if (mpvNorm == plexNorm) return true;

  // Common subtitle codec aliases
  const aliases = {
    'subrip': ['srt', 'subrip'],
    'srt': ['srt', 'subrip'],
    'ass': ['ass', 'ssa'],
    'ssa': ['ass', 'ssa'],
    'pgs': ['pgs', 'hdmv_pgs_subtitle'],
    'hdmv_pgs_subtitle': ['pgs', 'hdmv_pgs_subtitle'],
    'vobsub': ['vobsub', 'dvd_subtitle'],
    'dvd_subtitle': ['vobsub', 'dvd_subtitle'],
    'webvtt': ['webvtt', 'vtt'],
    'vtt': ['webvtt', 'vtt'],
  };

  final mpvAliases = aliases[mpvNorm] ?? [mpvNorm];
  return mpvAliases.contains(plexNorm);
}

/// Check if two audio codec strings match
/// Handles common aliases (e.g., ac3/a52, dts variants)
bool _audioCodecsMatch(String? mpvCodec, String? plexCodec) {
  if (mpvCodec == null || plexCodec == null) return false;

  final mpvNorm = mpvCodec.toLowerCase();
  final plexNorm = plexCodec.toLowerCase();

  if (mpvNorm == plexNorm) return true;

  // Common audio codec aliases
  const aliases = {
    'ac3': ['ac3', 'a52', 'eac3', 'dolby digital'],
    'a52': ['ac3', 'a52'],
    'eac3': ['eac3', 'e-ac-3', 'dolby digital plus', 'ac3'],
    'dts': ['dts', 'dca'],
    'dca': ['dts', 'dca'],
    'aac': ['aac', 'mp4a'],
    'mp4a': ['aac', 'mp4a'],
    'truehd': ['truehd', 'mlp'],
    'mlp': ['truehd', 'mlp'],
    'flac': ['flac'],
    'opus': ['opus'],
    'vorbis': ['vorbis', 'ogg'],
    'mp3': ['mp3', 'mp3float'],
  };

  final mpvAliases = aliases[mpvNorm] ?? [mpvNorm];
  return mpvAliases.contains(plexNorm);
}

/// Score how well titles match.
/// Returns 3 for a real text match, 1 for null/empty (non-contradicting), 0 for mismatch.
int _titleScore(String? mpvTitle, String? plexTitle, String? plexDisplayTitle) {
  if (mpvTitle == null || mpvTitle.isEmpty) return 1; // No title to contradict — mild bonus

  final mpvNorm = mpvTitle.toLowerCase().trim();

  // Check exact match with either Plex title
  if (plexTitle != null && plexTitle.toLowerCase().trim() == mpvNorm) return 3;
  if (plexDisplayTitle != null && plexDisplayTitle.toLowerCase().trim() == mpvNorm) return 3;

  // Check if one contains the other (partial match)
  if (plexTitle != null && plexTitle.toLowerCase().contains(mpvNorm)) return 3;
  if (plexDisplayTitle != null && plexDisplayTitle.toLowerCase().contains(mpvNorm)) return 3;

  return 0;
}

/// Check if titles match (fuzzy comparison) — used by audio matching
bool _titlesMatch(String? mpvTitle, String? plexTitle, String? plexDisplayTitle) {
  return _titleScore(mpvTitle, plexTitle, plexDisplayTitle) > 0;
}

/// Priority levels for track selection
enum TrackSelectionPriority {
  navigation, // Priority 1: User's manual selection from previous episode
  serverSelected, // Priority 2: server's pre-selected track
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
  final MediaServerUserProfile? profileSettings;
  final MediaItem metadata;
  final MediaSourceInfo? plexMediaInfo;

  TrackSelectionService({required this.player, this.profileSettings, required this.metadata, this.plexMediaInfo});

  /// Build list of preferred languages from a user profile
  List<String> _buildPreferredLanguages(MediaServerUserProfile profile, {required bool isAudio}) {
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
    for (final track in validTracks) {
      if (getId(track) == preferredId && getTitle(track) == preferredTitle && getLanguage(track) == preferredLanguage) {
        return track;
      }
    }

    // Try to match: title and language
    for (final track in validTracks) {
      if (getTitle(track) == preferredTitle && getLanguage(track) == preferredLanguage) {
        return track;
      }
    }

    // Try to match: language only
    for (final track in validTracks) {
      if (getLanguage(track) == preferredLanguage) {
        return track;
      }
    }

    return null;
  }

  AudioTrack? findBestAudioMatch(List<AudioTrack> availableTracks, AudioTrack preferred) {
    return findBestTrackMatch<AudioTrack>(availableTracks, preferred, (t) => t.id, (t) => t.title, (t) => t.language);
  }

  AudioTrack? findAudioTrackByProfile(List<AudioTrack> availableTracks, MediaServerUserProfile profile) {
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

  SubtitleTrack? _findSubtitleTrackByProfile(
    List<SubtitleTrack> availableTracks,
    MediaServerUserProfile profile, {
    bool forcedOnly = false,
  }) {
    final candidates = forcedOnly ? availableTracks.where((track) => track.isForced).toList() : availableTracks;
    if (candidates.isEmpty) return null;

    final preferredLanguages = _buildPreferredLanguages(profile, isAudio: false);
    if (preferredLanguages.isEmpty) return null;

    for (final preferredLanguage in preferredLanguages) {
      final match = _findTrackByPreferredLanguage<SubtitleTrack>(
        candidates,
        preferredLanguage,
        (track) => track.language,
        (track) => track.title ?? 'Track ${track.id}',
        'subtitle track',
      );
      if (match != null) return match;
    }

    return null;
  }

  SubtitleTrack? _findDefaultSubtitleTrack(List<SubtitleTrack> availableTracks) {
    for (final track in availableTracks) {
      if (track.isDefault) return track;
    }
    return null;
  }

  SubtitleTrack? _findFirstSubtitleTrack(List<SubtitleTrack> availableTracks) {
    return availableTracks.isEmpty ? null : availableTracks.first;
  }

  SubtitleTrack? _findForcedSubtitleTrack(List<SubtitleTrack> availableTracks) {
    for (final track in availableTracks) {
      if (track.isForced) return track;
    }
    return null;
  }

  bool _audioMatchesProfile(AudioTrack? selectedAudioTrack, MediaServerUserProfile profile) {
    if (selectedAudioTrack == null) return false;
    final preferredLanguages = _buildPreferredLanguages(profile, isAudio: true);
    if (preferredLanguages.isEmpty) return false;
    return preferredLanguages.any((language) => languageMatches(selectedAudioTrack.language, language));
  }

  TrackSelectionResult<SubtitleTrack>? _selectSubtitleTrackByProfile(
    List<SubtitleTrack> availableTracks,
    AudioTrack? selectedAudioTrack,
  ) {
    final profile = profileSettings;
    final mode = profile?.subtitleMode;
    if (profile == null || mode == null || mode == SubtitlePlaybackMode.defaultMode) return null;

    SubtitleTrack? selected;
    switch (mode) {
      case SubtitlePlaybackMode.none:
        selected = SubtitleTrack.off;
        break;
      case SubtitlePlaybackMode.onlyForced:
        selected =
            _findSubtitleTrackByProfile(availableTracks, profile, forcedOnly: true) ??
            _findForcedSubtitleTrack(availableTracks) ??
            SubtitleTrack.off;
        break;
      case SubtitlePlaybackMode.always:
        selected =
            _findSubtitleTrackByProfile(availableTracks, profile) ??
            _findDefaultSubtitleTrack(availableTracks) ??
            _findFirstSubtitleTrack(availableTracks) ??
            SubtitleTrack.off;
        break;
      case SubtitlePlaybackMode.smart:
        if (_audioMatchesProfile(selectedAudioTrack, profile)) {
          selected =
              _findSubtitleTrackByProfile(availableTracks, profile, forcedOnly: true) ??
              _findForcedSubtitleTrack(availableTracks) ??
              SubtitleTrack.off;
        } else {
          selected =
              _findSubtitleTrackByProfile(availableTracks, profile) ??
              _findDefaultSubtitleTrack(availableTracks) ??
              _findFirstSubtitleTrack(availableTracks) ??
              SubtitleTrack.off;
        }
        break;
      case SubtitlePlaybackMode.defaultMode:
        return null;
    }

    return TrackSelectionResult(selected, TrackSelectionPriority.profile);
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

  /// Find a track matching a preferred language from a list of tracks
  /// Returns the first track whose language matches any variation of the preferred language
  T? _findTrackByLanguageVariations<T>(
    List<T> tracks,
    String _,
    List<String> languageVariations,
    String? Function(T) getLanguage,
    String Function(T) _,
    String _,
  ) {
    for (final track in tracks) {
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
  TrackSelectionResult<AudioTrack>? selectAudioTrack(
    List<AudioTrack> availableTracks,
    AudioTrack? preferredAudioTrack,
  ) {
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
    if (plexMediaInfo != null && availableTracks.isNotEmpty) {
      final plexSelectedTrack = plexMediaInfo!.audioTracks.where((t) => t.selected).firstOrNull;

      if (plexSelectedTrack != null) {
        final matchedMpvTrack = findMpvTrackForPlexAudio(
          plexSelectedTrack,
          availableTracks,
          allPlexTracks: plexMediaInfo!.audioTracks,
        );

        if (matchedMpvTrack != null) {
          return TrackSelectionResult(matchedMpvTrack, TrackSelectionPriority.serverSelected);
        }
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
    trackToSelect = availableTracks.firstWhere((t) => t.isDefault, orElse: () => availableTracks.first);
    return TrackSelectionResult(trackToSelect, TrackSelectionPriority.defaultTrack);
  }

  /// Select the best subtitle track based on priority:
  /// Priority 1: Preferred track from navigation
  /// Priority 2: Server-selected track or explicit server off decision
  /// Priority 3: User profile subtitle mode
  /// Priority 4: Default track
  /// Priority 5: Off
  TrackSelectionResult<SubtitleTrack> selectSubtitleTrack(
    List<SubtitleTrack> availableTracks,
    SubtitleTrack? preferredSubtitleTrack,
    AudioTrack? selectedAudioTrack,
  ) {
    // Priority 1: Try preferred track from navigation
    if (preferredSubtitleTrack != null) {
      if (preferredSubtitleTrack.id == 'no') {
        return TrackSelectionResult(SubtitleTrack.off, TrackSelectionPriority.navigation);
      } else if (availableTracks.isNotEmpty) {
        final subtitleToSelect = findBestSubtitleMatch(availableTracks, preferredSubtitleTrack);
        if (subtitleToSelect != null) {
          return TrackSelectionResult(subtitleToSelect, TrackSelectionPriority.navigation);
        }
      }
    }

    // Priority 2: Trust the server's selected track. Plex computes this from
    // account/show/per-item prefs; Jellyfin exposes DefaultSubtitleStreamIndex.
    final info = plexMediaInfo;
    if (info != null) {
      final serverSelectedTrack = availableTracks.isNotEmpty
          ? info.subtitleTracks.where((track) => track.selected).firstOrNull
          : null;

      if (serverSelectedTrack != null) {
        final matchedMpvTrack = findMpvTrackForPlexSubtitle(
          serverSelectedTrack,
          availableTracks,
          allPlexTracks: info.subtitleTracks,
        );

        if (matchedMpvTrack != null) {
          return TrackSelectionResult(matchedMpvTrack, TrackSelectionPriority.serverSelected);
        }
      } else if (metadata.backend == MediaBackend.jellyfin && info.defaultSubtitleStreamIndex == -1) {
        return TrackSelectionResult(SubtitleTrack.off, TrackSelectionPriority.serverSelected);
      } else if (metadata.backend == MediaBackend.plex && info.subtitleTracks.isNotEmpty) {
        // Server has subtitle tracks but none selected — trust that decision
        return TrackSelectionResult(SubtitleTrack.off, TrackSelectionPriority.serverSelected);
      }
    }

    // Priority 3: Apply server profile subtitle mode when the backend exposes
    // one (Jellyfin). Plex keeps using the selected-stream path above.
    final profileSelectedTrack = _selectSubtitleTrackByProfile(availableTracks, selectedAudioTrack);
    if (profileSelectedTrack != null) return profileSelectedTrack;

    // Priority 4: Check for default subtitle
    final defaultTrack = _findDefaultSubtitleTrack(availableTracks);
    if (defaultTrack != null) {
      return TrackSelectionResult(defaultTrack, TrackSelectionPriority.defaultTrack);
    }

    // Priority 5: Turn off subtitles
    return TrackSelectionResult(SubtitleTrack.off, TrackSelectionPriority.off);
  }

  /// Select and apply audio and subtitle tracks based on preferences
  Future<void> selectAndApplyTracks({
    AudioTrack? preferredAudioTrack,
    SubtitleTrack? preferredSubtitleTrack,
    SubtitleTrack? preferredSecondarySubtitleTrack,
    double? defaultPlaybackSpeed,
    Function(AudioTrack)? onAudioTrackChanged,
    Function(SubtitleTrack)? onSubtitleTrackChanged,
  }) async {
    // Wait for tracks to be loaded
    if (player.state.tracks.audio.isEmpty && player.state.tracks.subtitle.isEmpty) {
      try {
        await player.streams.tracks
            .where((t) => t.audio.isNotEmpty || t.subtitle.isNotEmpty)
            .first
            .namedTimeout(const Duration(seconds: 10), operation: 'track loading');
      } catch (_) {
        // Timeout or stream closed — proceed with whatever state we have
      }
    }

    if (player.disposed) return;

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
      unawaited(player.selectAudioTrack(selectedAudioTrack));

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
    unawaited(player.selectSubtitleTrack(selectedSubtitleTrack));

    // Save to Plex if this was user's navigation preference (Priority 1)
    if (subtitleResult.priority == TrackSelectionPriority.navigation && onSubtitleTrackChanged != null) {
      onSubtitleTrackChanged(selectedSubtitleTrack);
    }

    // Apply preferred secondary subtitle track if provided (mpv-only)
    if (preferredSecondarySubtitleTrack != null &&
        preferredSecondarySubtitleTrack.id != 'no' &&
        player.supportsSecondarySubtitles &&
        realSubtitleTracks.isNotEmpty) {
      final secondaryMatch = findBestSubtitleMatch(realSubtitleTracks, preferredSecondarySubtitleTrack);
      if (secondaryMatch != null && secondaryMatch.id != 'no') {
        appLogger.d(
          'Secondary subtitle: ${secondaryMatch.title ?? secondaryMatch.language ?? "Track ${secondaryMatch.id}"}',
        );
        unawaited(player.selectSecondarySubtitleTrack(secondaryMatch));
      }
    }

    // Apply default playback speed from settings
    if (defaultPlaybackSpeed != null && defaultPlaybackSpeed != 1.0) {
      unawaited(player.setRate(defaultPlaybackSpeed));
    }
  }
}
