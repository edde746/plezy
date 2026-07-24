import 'package:collection/collection.dart';

import '../media/media_item.dart';
import '../media/media_server_user_profile.dart';
import '../media/media_source_info.dart';
import '../mpv/mpv.dart';
import 'playback_initialization_types.dart';
import 'track_selection_service.dart';

/// A source-catalog subtitle choice.
///
/// Keeping "off" distinct from a numeric stream id prevents backend wire
/// conventions (notably Plex's `0`) from colliding with real Jellyfin ids.
final class PlaybackSourceSubtitleChoice {
  final bool isOff;
  final int? sourceStreamId;

  const PlaybackSourceSubtitleChoice.off() : this._(isOff: true);

  const PlaybackSourceSubtitleChoice.source(int sourceStreamId) : this._(isOff: false, sourceStreamId: sourceStreamId);

  const PlaybackSourceSubtitleChoice._({required this.isOff, this.sourceStreamId});

  @override
  bool operator ==(Object other) =>
      other is PlaybackSourceSubtitleChoice && other.isOff == isOff && other.sourceStreamId == sourceStreamId;

  @override
  int get hashCode => Object.hash(isOff, sourceStreamId);
}

/// Effective subtitle choice for one player open.
///
/// The source IDs remain stable across player reloads, while [primaryTrack]
/// and [secondaryTrack] carry the matching metadata used to select the newly
/// discovered native tracks after open.
class PlaybackSubtitleSelection {
  final SubtitleTrack primaryTrack;
  final int? primarySourceStreamId;
  final PlaybackSubtitleSidecar? primarySidecar;
  final SubtitleTrack? secondaryTrack;
  final int? secondarySourceStreamId;
  final PlaybackSubtitleSidecar? secondarySidecar;

  const PlaybackSubtitleSelection({
    required this.primaryTrack,
    this.primarySourceStreamId,
    this.primarySidecar,
    this.secondaryTrack,
    this.secondarySourceStreamId,
    this.secondarySidecar,
  });

  const PlaybackSubtitleSelection.off()
    : primaryTrack = SubtitleTrack.off,
      primarySourceStreamId = null,
      primarySidecar = null,
      secondaryTrack = null,
      secondarySourceStreamId = null,
      secondarySidecar = null;

  bool get isOff => primaryTrack.id == SubtitleTrack.off.id;

  List<SubtitleTrack> get sidecarsAtOpen {
    final tracks = <SubtitleTrack>[];
    final primary = primarySidecar?.track;
    if (primary != null) tracks.add(primary);
    final secondary = secondarySidecar?.track;
    if (secondary != null && secondary.uri != primary?.uri) tracks.add(secondary);
    return tracks;
  }
}

/// Resolves the server subtitle catalog before opening the native player, so
/// only the active sidecar is part of the open operation.
class PlaybackSubtitleResolver {
  const PlaybackSubtitleResolver._();

  static SubtitleTrack? _sourceBackedPreference(
    SubtitleTrack? preferred,
    MediaSourceInfo? mediaInfo,
    List<_SubtitleCandidate> candidates,
  ) {
    if (preferred == null || preferred.id == SubtitleTrack.off.id) return preferred;

    final sourceMatch = findPlexTrackForMpvSubtitle(
      preferred,
      mediaInfo?.subtitleTracks ?? const <MediaSubtitleTrack>[],
    );
    if (sourceMatch == null) return preferred;

    for (final candidate in candidates) {
      if (candidate.sourceStreamId == sourceMatch.id) return candidate.track;
    }
    return preferred;
  }

  static PlaybackSubtitleSelection resolve({
    required MediaItem metadata,
    required MediaSourceInfo? mediaInfo,
    required List<PlaybackSubtitleSidecar> sidecars,
    MediaServerUserProfile? profileSettings,
    AudioTrack? preferredAudioTrack,
    SubtitleTrack? preferredSubtitleTrack,
    SubtitleTrack? preferredSecondarySubtitleTrack,
  }) {
    final candidates = <_SubtitleCandidate>[];
    final matchedSidecars = <PlaybackSubtitleSidecar>{};

    for (final sourceTrack in mediaInfo?.subtitleTracks ?? const <MediaSubtitleTrack>[]) {
      final sidecar = sidecars.where((candidate) => candidate.sourceStreamId == sourceTrack.id).firstOrNull;
      if (sidecar != null) matchedSidecars.add(sidecar);
      candidates.add(
        _SubtitleCandidate(
          track: subtitleTrackForSource(sourceTrack, sidecar: sidecar),
          sourceStreamId: sourceTrack.id,
          sidecar: sidecar,
        ),
      );
    }

    // Legacy/offline sidecars may not have cached source metadata. They still
    // participate in normal default/profile selection and remain playable.
    for (final sidecar in sidecars) {
      if (matchedSidecars.contains(sidecar)) continue;
      candidates.add(
        _SubtitleCandidate(track: sidecar.track, sourceStreamId: sidecar.sourceStreamId, sidecar: sidecar),
      );
    }

    final availableTracks = candidates.map((candidate) => candidate.track).toList(growable: false);
    final service = TrackSelectionService(
      profileSettings: profileSettings,
      metadata: metadata,
      plexMediaInfo: mediaInfo,
    );
    final selectedAudio = service.selectAudioTrack(_audioTracksForSource(mediaInfo), preferredAudioTrack)?.track;
    final primaryPreference = _sourceBackedPreference(preferredSubtitleTrack, mediaInfo, candidates);
    final primaryResult = service.selectSubtitleTrack(availableTracks, primaryPreference, selectedAudio);
    final primary = primaryResult.track;
    if (primary.id == SubtitleTrack.off.id) return const PlaybackSubtitleSelection.off();

    final primaryCandidate = candidates.where((candidate) => candidate.track.id == primary.id).firstOrNull;
    if (primaryCandidate == null) return const PlaybackSubtitleSelection.off();

    _SubtitleCandidate? secondaryCandidate;
    final secondaryPreference = _sourceBackedPreference(preferredSecondarySubtitleTrack, mediaInfo, candidates);
    if (secondaryPreference != null && secondaryPreference.id != SubtitleTrack.off.id) {
      final secondary = service.findBestSubtitleMatch(availableTracks, secondaryPreference);
      secondaryCandidate = candidates
          .where((candidate) => candidate.track.id == secondary?.id && candidate.track.id != primary.id)
          .firstOrNull;
    }

    return PlaybackSubtitleSelection(
      primaryTrack: primaryCandidate.track,
      primarySourceStreamId: primaryCandidate.sourceStreamId,
      primarySidecar: primaryCandidate.sidecar,
      secondaryTrack: secondaryCandidate?.track,
      secondarySourceStreamId: secondaryCandidate?.sourceStreamId,
      secondarySidecar: secondaryCandidate?.sidecar,
    );
  }

  /// Stable source descriptor used for an explicit user selection. Supplying
  /// this as the next open's preferred track makes it the highest-priority
  /// choice without retaining a stale sidecar URL.
  static SubtitleTrack? preferredTrackForSource(MediaSourceInfo? mediaInfo, int sourceStreamId) {
    final sourceTrack = mediaInfo?.subtitleTracks.where((track) => track.id == sourceStreamId).firstOrNull;
    return sourceTrack == null ? null : subtitleTrackForSource(sourceTrack);
  }

  static SubtitleTrack subtitleTrackForSource(MediaSubtitleTrack sourceTrack, {PlaybackSubtitleSidecar? sidecar}) {
    final playable = sidecar?.track;
    return SubtitleTrack(
      id: 'source:${sourceTrack.id}',
      title: playable?.title ?? sourceTrack.displayTitle ?? sourceTrack.title ?? sourceTrack.language,
      language: playable?.language ?? sourceTrack.languageCode ?? sourceTrack.language,
      codec: playable?.codec ?? sourceTrack.codec,
      isDefault: sourceTrack.selected,
      isForced: sourceTrack.forced,
      isExternal: playable != null,
      uri: playable?.uri,
    );
  }

  /// Resolve a server source row to a track already loaded by direct play.
  /// Resolved sidecars only match by their stable URL key (or the current
  /// source identity); fuzzy language/codec matching must not select a
  /// different sidecar that happens to have similar metadata. A server's
  /// `external delivery` flag is not sufficient to classify a direct-play
  /// row as a sidecar: Jellyfin applies it to embedded tracks that mpv still
  /// discovers in the original file.
  static SubtitleTrack? nativeTrackForDirectPlaySource({
    required MediaSubtitleTrack sourceTrack,
    required List<SubtitleTrack> nativeTracks,
    required List<MediaSubtitleTrack> allSourceTracks,
    required bool isResolvedSidecar,
    int? currentSourceStreamId,
    SubtitleTrack? selectedNativeTrack,
  }) {
    if (isResolvedSidecar) {
      final key = sourceTrack.key;
      if (key != null && key.isNotEmpty) {
        for (final candidate in nativeTracks) {
          if (candidate.isExternal && candidate.uri?.contains(key) == true) return candidate;
        }
      }
      if (currentSourceStreamId == sourceTrack.id &&
          selectedNativeTrack != null &&
          selectedNativeTrack.id != SubtitleTrack.off.id &&
          selectedNativeTrack.isExternal) {
        return selectedNativeTrack;
      }
      return null;
    }
    return findMpvTrackForPlexSubtitle(sourceTrack, nativeTracks, allPlexTracks: allSourceTracks);
  }

  static PlaybackSourceSubtitleChoice nextSourceChoice(
    List<MediaSubtitleTrack> tracks,
    PlaybackSourceSubtitleChoice currentChoice,
  ) {
    return advanceSourceChoice(tracks, currentChoice, 1);
  }

  static PlaybackSourceSubtitleChoice advanceSourceChoice(
    List<MediaSubtitleTrack> tracks,
    PlaybackSourceSubtitleChoice currentChoice,
    int advances,
  ) {
    final choices = <PlaybackSourceSubtitleChoice>[
      const PlaybackSourceSubtitleChoice.off(),
      ...tracks.map((track) => PlaybackSourceSubtitleChoice.source(track.id)),
    ];
    final currentIndex = choices.indexOf(currentChoice);
    final normalizedCurrentIndex = currentIndex < 0 ? 0 : currentIndex;
    return choices[(normalizedCurrentIndex + advances) % choices.length];
  }

  static List<AudioTrack> _audioTracksForSource(MediaSourceInfo? mediaInfo) {
    return [
      for (final track in mediaInfo?.audioTracks ?? const <MediaAudioTrack>[])
        AudioTrack(
          id: 'source:${track.id}',
          title: track.displayTitle ?? track.title ?? track.language,
          language: track.languageCode ?? track.language,
          codec: track.codec,
          channels: track.channels,
          isDefault: track.selected,
        ),
    ];
  }
}

class _SubtitleCandidate {
  final SubtitleTrack track;
  final int? sourceStreamId;
  final PlaybackSubtitleSidecar? sidecar;

  const _SubtitleCandidate({required this.track, required this.sourceStreamId, required this.sidecar});
}
