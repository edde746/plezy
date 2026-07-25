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

enum _DirectEmbeddedSubtitleCatalog { incomplete, complete }

bool _isDirectEmbeddedPlexSubtitle(MediaSubtitleTrack track) => !track.isExternal;

bool _isDirectEmbeddedMpvSubtitle(SubtitleTrack track) =>
    track.id != SubtitleTrack.auto.id && track.id != SubtitleTrack.off.id && !track.isExternal && !track.isContainer;

/// Classifies only ordinary direct-embedded rows. External/keyed source
/// subtitles and native container tracks have independent arrival semantics
/// and cannot prove that this catalog is complete.
_DirectEmbeddedSubtitleCatalog _classifyDirectEmbeddedSubtitleCatalog(
  List<MediaSubtitleTrack> plexTracks,
  List<SubtitleTrack> mpvTracks,
) {
  var plexTrackCount = 0;
  for (final track in plexTracks) {
    if (_isDirectEmbeddedPlexSubtitle(track)) plexTrackCount++;
  }

  var mpvTrackCount = 0;
  for (final track in mpvTracks) {
    if (_isDirectEmbeddedMpvSubtitle(track)) mpvTrackCount++;
  }

  return plexTrackCount > 0 && plexTrackCount == mpvTrackCount
      ? _DirectEmbeddedSubtitleCatalog.complete
      : _DirectEmbeddedSubtitleCatalog.incomplete;
}

bool _hasSubtitleFact(String? value) => value != null && value.trim().isNotEmpty;

bool _lowMetadataSubtitleFactsAreCompatible(SubtitleTrack mpvTrack, MediaSubtitleTrack plexTrack) {
  final plexLanguage = plexTrack.languageCode;
  if (_hasSubtitleFact(mpvTrack.language) &&
      _hasSubtitleFact(plexLanguage) &&
      !_languagesMatch(mpvTrack.language, plexLanguage)) {
    return false;
  }

  if (_hasSubtitleFact(mpvTrack.codec) &&
      _hasSubtitleFact(plexTrack.codec) &&
      !_subtitleCodecsMatch(mpvTrack.codec, plexTrack.codec)) {
    return false;
  }

  final plexHasTitle = _hasSubtitleFact(plexTrack.title) || _hasSubtitleFact(plexTrack.displayTitle);
  if (_hasSubtitleFact(mpvTrack.title) &&
      plexHasTitle &&
      _titleScore(mpvTrack.title, plexTrack.title, plexTrack.displayTitle) == 0) {
    return false;
  }

  return mpvTrack.isForced == plexTrack.forced;
}

int _scoreLowMetadataSubtitleFacts(SubtitleTrack mpvTrack, MediaSubtitleTrack plexTrack) {
  var score = 0;
  final plexLanguage = plexTrack.languageCode;
  if (_hasSubtitleFact(mpvTrack.language) &&
      _hasSubtitleFact(plexLanguage) &&
      _languagesMatch(mpvTrack.language, plexLanguage)) {
    score += 10;
    if (_languageCodesExactMatch(mpvTrack.language, plexLanguage)) score++;
  }
  if (_hasSubtitleFact(mpvTrack.codec) &&
      _hasSubtitleFact(plexTrack.codec) &&
      _subtitleCodecsMatch(mpvTrack.codec, plexTrack.codec)) {
    score += 5;
  }
  if (_hasSubtitleFact(mpvTrack.title) &&
      (_hasSubtitleFact(plexTrack.title) || _hasSubtitleFact(plexTrack.displayTitle)) &&
      _titleScore(mpvTrack.title, plexTrack.title, plexTrack.displayTitle) > 0) {
    score += 3;
  }
  if (mpvTrack.isForced == plexTrack.forced) score += 2;
  return score;
}

T? _findUniqueBestLowMetadataMatch<T extends Object>(
  Iterable<T> candidates, {
  required bool Function(T candidate) isCompatible,
  required int Function(T candidate) score,
}) {
  T? bestMatch;
  var bestScore = -1;
  var bestIsUnique = false;

  for (final candidate in candidates) {
    if (!isCompatible(candidate)) continue;
    final candidateScore = score(candidate);
    if (candidateScore > bestScore) {
      bestMatch = candidate;
      bestScore = candidateScore;
      bestIsUnique = true;
    } else if (candidateScore == bestScore) {
      bestIsUnique = false;
    }
  }

  return bestIsUnique ? bestMatch : null;
}

/// Find the MPV subtitle track that matches a Plex subtitle track
SubtitleTrack? findMpvTrackForPlexSubtitle(
  MediaSubtitleTrack plexTrack,
  List<SubtitleTrack> mpvTracks, {
  List<MediaSubtitleTrack>? allPlexTracks,
}) {
  if (mpvTracks.isEmpty) return null;
  final sourceId = int.tryParse(plexTrack.id.toString());
  if (sourceId != null) {
    final exactSourceTrack = mpvTracks.where((track) => track.id == 'source:$sourceId').firstOrNull;
    if (exactSourceTrack != null) return exactSourceTrack;
  }

  // Keyed subtitles have a stable identity. Do not let a sidecar that has not
  // arrived yet fall through to fuzzy language/title scoring.
  final plexKey = plexTrack.key;
  if (plexKey != null && plexKey.isNotEmpty) {
    for (final mpvTrack in mpvTracks) {
      if (mpvTrack.isExternal && mpvTrack.uri?.contains(plexKey) == true) {
        return mpvTrack;
      }
    }
    return null;
  }

  // For internal subtitles, use scoring based on properties
  SubtitleTrack? bestMatch;
  int bestScore = 0;
  bool bestMatchUsesContainerOrdinal = false;

  // Ordinal identity: container sidecars expose embedded subtitle tracks as
  // external media, but retain the source container's subtitle ordering.
  final containerPlexTracks = allPlexTracks
      ?.where((track) => track.key == null || track.key!.isEmpty)
      .toList(growable: false);
  final internalMpvTracks = allPlexTracks == null
      ? null
      : mpvTracks.where((track) => !track.isExternal || track.isContainer).toList(growable: false);
  final plexOrdinal = containerPlexTracks?.indexOf(plexTrack) ?? -1;

  for (final mpvTrack in mpvTracks) {
    // A container sidecar's subtitle tracks map to internal Plex streams.
    if (!plexTrack.isExternal && mpvTrack.isExternal && !mpvTrack.isContainer) continue;

    final ordinalMatches =
        internalMpvTracks != null && plexOrdinal >= 0 && internalMpvTracks.indexOf(mpvTrack) == plexOrdinal;

    // A container track has no stable native ID. Its source-container ordinal
    // is authoritative; a metadata-identical earlier track is not a match.
    if (mpvTrack.isContainer && plexOrdinal >= 0 && !ordinalMatches) continue;

    final score = _scoreSubtitleMatch(mpvTrack, plexTrack, ordinalMatches: ordinalMatches);

    if (score > bestScore) {
      bestScore = score;
      bestMatch = mpvTrack;
      bestMatchUsesContainerOrdinal = mpvTrack.isContainer && ordinalMatches;
    }
  }

  // Prefer metadata matches. Container sidecars may expose no language/title/
  // codec at all, so their stable subtitle order is the last-resort identity.
  if (bestScore >= 10 || bestMatchUsesContainerOrdinal) return bestMatch;

  final plexTracks = allPlexTracks;
  if (plexTracks == null ||
      !_isDirectEmbeddedPlexSubtitle(plexTrack) ||
      _classifyDirectEmbeddedSubtitleCatalog(plexTracks, mpvTracks) != _DirectEmbeddedSubtitleCatalog.complete) {
    return null;
  }

  // A complete ordinary direct catalog may safely resolve low-metadata rows
  // only from their facts. Native order is deliberately not an identity.
  return _findUniqueBestLowMetadataMatch(
    mpvTracks.where(_isDirectEmbeddedMpvSubtitle),
    isCompatible: (candidate) => _lowMetadataSubtitleFactsAreCompatible(candidate, plexTrack),
    score: (candidate) => _scoreLowMetadataSubtitleFacts(candidate, plexTrack),
  );
}

/// Find the Plex subtitle track that matches an MPV subtitle track
MediaSubtitleTrack? findPlexTrackForMpvSubtitle(
  SubtitleTrack mpvTrack,
  List<MediaSubtitleTrack> plexTracks, {
  List<SubtitleTrack>? allMpvTracks,
}) {
  if (plexTracks.isEmpty) return null;
  if (mpvTrack.id.startsWith('source:')) {
    final sourceId = int.tryParse(mpvTrack.id.substring('source:'.length));
    if (sourceId != null) {
      final exactSourceTrack = plexTracks.where((track) => track.id == sourceId).firstOrNull;
      if (exactSourceTrack != null) return exactSourceTrack;
    }
  }

  // A standalone keyed subtitle maps back only by its stable Plex key.
  // Container sidecars may continue to the source-container matcher below.
  if (mpvTrack.isExternal && mpvTrack.uri != null) {
    for (final plexTrack in plexTracks) {
      final plexKey = plexTrack.key;
      if (plexKey != null && plexKey.isNotEmpty && mpvTrack.uri!.contains(plexKey)) {
        return plexTrack;
      }
    }
    if (!mpvTrack.isContainer) return null;
  }

  // For internal subtitles, use scoring based on properties
  MediaSubtitleTrack? bestMatch;
  int bestScore = 0;
  bool bestMatchUsesContainerOrdinal = false;

  // Ordinal identity: container-sidecar tracks map back to source-container
  // streams even though the native player marks their source as external.
  final mpvIsInternal = !mpvTrack.isExternal || mpvTrack.isContainer;
  final containerPlexTracks = allMpvTracks == null
      ? null
      : plexTracks.where((track) => track.key == null || track.key!.isEmpty).toList(growable: false);
  final mpvOrdinal = allMpvTracks == null
      ? -1
      : allMpvTracks.where((track) => !track.isExternal || track.isContainer).toList().indexOf(mpvTrack);

  for (final plexTrack in plexTracks) {
    if (mpvIsInternal && plexTrack.isExternal) continue;

    final ordinalMatches =
        containerPlexTracks != null && mpvOrdinal >= 0 && containerPlexTracks.indexOf(plexTrack) == mpvOrdinal;

    if (mpvTrack.isContainer && containerPlexTracks != null && !ordinalMatches) continue;

    final score = _scoreSubtitleMatch(mpvTrack, plexTrack, ordinalMatches: ordinalMatches);

    if (score > bestScore) {
      bestScore = score;
      bestMatch = plexTrack;
      bestMatchUsesContainerOrdinal = mpvTrack.isContainer && ordinalMatches;
    }
  }

  // Prefer metadata matches, with container order as the symmetric fallback
  // needed to persist a metadata-free native track back to its Plex stream.
  if (bestScore >= 10 || bestMatchUsesContainerOrdinal) return bestMatch;

  final mpvTracks = allMpvTracks;
  if (mpvTracks == null ||
      !_isDirectEmbeddedMpvSubtitle(mpvTrack) ||
      _classifyDirectEmbeddedSubtitleCatalog(plexTracks, mpvTracks) != _DirectEmbeddedSubtitleCatalog.complete) {
    return null;
  }

  return _findUniqueBestLowMetadataMatch(
    plexTracks.where(_isDirectEmbeddedPlexSubtitle),
    isCompatible: (candidate) => _lowMetadataSubtitleFactsAreCompatible(mpvTrack, candidate),
    score: (candidate) => _scoreLowMetadataSubtitleFacts(mpvTrack, candidate),
  );
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

int _mediaTrackStreamIndex(int id, int? index) => index ?? id;

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

  const TrackSelectionResult(this.track, this.priority);
}

/// Service for selecting and applying audio and subtitle tracks based on
/// preferences, user profiles, and per-media settings.
class TrackSelectionService {
  final Player? player;
  final MediaServerUserProfile? profileSettings;
  final MediaItem metadata;
  final MediaSourceInfo? plexMediaInfo;

  TrackSelectionService({this.player, this.profileSettings, required this.metadata, this.plexMediaInfo});

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

  MediaSubtitleTrack? _sourceSubtitleTrack(String nativeId) {
    if (!nativeId.startsWith('source:')) return null;
    final sourceId = int.tryParse(nativeId.substring('source:'.length));
    return sourceId == null ? null : plexMediaInfo?.subtitleTracks.where((track) => track.id == sourceId).firstOrNull;
  }

  bool _hasCompleteDirectPlexCatalogFor(MediaSubtitleTrack? sourceTrack, List<SubtitleTrack> availableTracks) {
    final info = plexMediaInfo;
    return metadata.backend == MediaBackend.plex &&
        info != null &&
        sourceTrack != null &&
        _isDirectEmbeddedPlexSubtitle(sourceTrack) &&
        _classifyDirectEmbeddedSubtitleCatalog(info.subtitleTracks, availableTracks) ==
            _DirectEmbeddedSubtitleCatalog.complete;
  }

  SubtitleTrack? findBestSubtitleMatch(List<SubtitleTrack> availableTracks, SubtitleTrack preferred) {
    // Handle special "no subtitles" case
    if (preferred.id == 'no') {
      return SubtitleTrack.off;
    }

    if (preferred.id.startsWith('source:')) {
      final sourceTrack = _sourceSubtitleTrack(preferred.id);
      if (sourceTrack == null) return null;
      return findMpvTrackForPlexSubtitle(sourceTrack, availableTracks, allPlexTracks: plexMediaInfo?.subtitleTracks);
    }

    final preferredUri = preferred.uri;
    if (preferredUri != null) {
      final uriMatches = availableTracks.where((track) => track.uri == preferredUri).toList(growable: false);
      if (uriMatches.length == 1) return uriMatches.single;
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
  /// Priority 2: Server-selected track from media info
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

    // Priority 2: Check server-selected track from media info
    final info = plexMediaInfo;
    if (info != null && availableTracks.isNotEmpty) {
      final serverSelectedTrack = info.audioTracks.where((t) => t.selected).firstOrNull;

      if (serverSelectedTrack != null) {
        final matchedMpvTrack = findMpvTrackForPlexAudio(
          serverSelectedTrack,
          availableTracks,
          allPlexTracks: info.audioTracks,
        );

        if (matchedMpvTrack != null) {
          return TrackSelectionResult(matchedMpvTrack, TrackSelectionPriority.serverSelected);
        }
      } else if (metadata.backend == MediaBackend.jellyfin) {
        final defaultStreamIndex = info.defaultAudioStreamIndex;
        final defaultTrack = defaultStreamIndex != null
            ? info.audioTracks
                  .where((track) => _mediaTrackStreamIndex(track.id, track.index) == defaultStreamIndex)
                  .firstOrNull
            : null;

        if (defaultTrack != null) {
          final matchedMpvTrack = findMpvTrackForPlexAudio(
            defaultTrack,
            availableTracks,
            allPlexTracks: info.audioTracks,
          );

          if (matchedMpvTrack != null) {
            return TrackSelectionResult(matchedMpvTrack, TrackSelectionPriority.serverSelected);
          }
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
  ///
  /// Returns null only while the source catalog can still deliver the requested
  /// subtitle. A complete catalog with no unambiguous match proceeds through
  /// the safe default/off priorities instead of waiting indefinitely.
  TrackSelectionResult<SubtitleTrack>? selectSubtitleTrack(
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
      if (preferredSubtitleTrack.id.startsWith('source:') &&
          !_hasCompleteDirectPlexCatalogFor(_sourceSubtitleTrack(preferredSubtitleTrack.id), availableTracks)) {
        return null;
      }
    }

    // Priority 2: Trust the server's selected track. Plex computes this from
    // account/show/per-item prefs; Jellyfin exposes DefaultSubtitleStreamIndex.
    final info = plexMediaInfo;
    if (info != null) {
      final serverSelectedTrack = info.subtitleTracks.where((track) => track.selected).firstOrNull;

      if (serverSelectedTrack != null) {
        final matchedMpvTrack = findMpvTrackForPlexSubtitle(
          serverSelectedTrack,
          availableTracks,
          allPlexTracks: info.subtitleTracks,
        );

        if (matchedMpvTrack != null) {
          return TrackSelectionResult(matchedMpvTrack, TrackSelectionPriority.serverSelected);
        }
        if (metadata.backend == MediaBackend.plex &&
            !_hasCompleteDirectPlexCatalogFor(serverSelectedTrack, availableTracks)) {
          return null;
        }
      } else if (metadata.backend == MediaBackend.jellyfin) {
        final defaultStreamIndex = info.defaultSubtitleStreamIndex;
        if (defaultStreamIndex == -1) {
          return TrackSelectionResult(SubtitleTrack.off, TrackSelectionPriority.serverSelected);
        }

        final defaultTrack = defaultStreamIndex != null && availableTracks.isNotEmpty
            ? info.subtitleTracks
                  .where((track) => _mediaTrackStreamIndex(track.id, track.index) == defaultStreamIndex)
                  .firstOrNull
            : null;

        if (defaultTrack != null) {
          final matchedMpvTrack = findMpvTrackForPlexSubtitle(
            defaultTrack,
            availableTracks,
            allPlexTracks: info.subtitleTracks,
          );

          if (matchedMpvTrack != null) {
            return TrackSelectionResult(matchedMpvTrack, TrackSelectionPriority.serverSelected);
          }
        }
      } else if (metadata.backend == MediaBackend.plex && info.subtitleTracks.isNotEmpty) {
        if (availableTracks.isEmpty) return null;
        // Native tracks exist and none maps to a server-selected stream.
        return TrackSelectionResult(SubtitleTrack.off, TrackSelectionPriority.serverSelected);
      }
      if (availableTracks.isEmpty && info.subtitleTracks.isNotEmpty) return null;
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
  Future<bool> selectAndApplyTracks({
    AudioTrack? preferredAudioTrack,
    SubtitleTrack? preferredSubtitleTrack,
    SubtitleTrack? preferredSecondarySubtitleTrack,
    double? defaultPlaybackSpeed,
    Function(AudioTrack)? onAudioTrackChanged,
    Function(SubtitleTrack)? onSubtitleTrackChanged,
    bool Function()? isActive,
    void Function(Future<void> mutation)? onPlayerMutationDispatched,
  }) async {
    final player = this.player;
    if (player == null) {
      throw StateError('A player is required to apply track selections');
    }
    bool canMutatePlayer() => !player.disposed && (isActive == null || isActive());

    if (!canMutatePlayer()) return false;

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

    if (!canMutatePlayer()) return false;

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
      if (!canMutatePlayer()) return false;
      final audioMutation = player.selectAudioTrack(selectedAudioTrack);
      onPlayerMutationDispatched?.call(audioMutation);
      await audioMutation;
      if (!canMutatePlayer()) return false;

      // Save to Plex if this was user's navigation preference (Priority 1)
      if (audioResult.priority == TrackSelectionPriority.navigation && onAudioTrackChanged != null) {
        onAudioTrackChanged(selectedAudioTrack);
      }
    }

    // Select and apply subtitle track. A null result means source metadata
    // advertises subtitles that the native player has not exposed yet.
    final subtitleResult = selectSubtitleTrack(realSubtitleTracks, preferredSubtitleTrack, selectedAudioTrack);
    if (subtitleResult != null) {
      final selectedSubtitleTrack = subtitleResult.track;
      final subtitleName = selectedSubtitleTrack.id == 'no'
          ? 'OFF'
          : (selectedSubtitleTrack.title ?? selectedSubtitleTrack.language ?? 'Track ${selectedSubtitleTrack.id}');
      appLogger.d('Subtitle: $subtitleName [${subtitleResult.priority.name}]');
      if (!canMutatePlayer()) return false;
      final subtitleMutation = player.selectSubtitleTrack(selectedSubtitleTrack);
      onPlayerMutationDispatched?.call(subtitleMutation);
      await subtitleMutation;
      if (!canMutatePlayer()) return false;

      // Save to Plex if this was user's navigation preference (Priority 1)
      if (subtitleResult.priority == TrackSelectionPriority.navigation && onSubtitleTrackChanged != null) {
        onSubtitleTrackChanged(selectedSubtitleTrack);
      }
    } else {
      appLogger.d('Subtitle selection pending: native tracks have not arrived');
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
        if (!canMutatePlayer()) return false;
        final secondarySubtitleMutation = player.selectSecondarySubtitleTrack(secondaryMatch);
        onPlayerMutationDispatched?.call(secondarySubtitleMutation);
        await secondarySubtitleMutation;
        if (!canMutatePlayer()) return false;
      }
    }

    // Apply default playback speed from settings
    if (defaultPlaybackSpeed != null && defaultPlaybackSpeed != 1.0) {
      if (!canMutatePlayer()) return false;
      final rateMutation = player.setRate(defaultPlaybackSpeed);
      onPlayerMutationDispatched?.call(rateMutation);
      await rateMutation;
      if (!canMutatePlayer()) return false;
    }

    return true;
  }
}
