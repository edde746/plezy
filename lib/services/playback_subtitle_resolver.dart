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
  final List<PlaybackSubtitleSidecar> preloadedSidecars;

  const PlaybackSubtitleSelection({
    required this.primaryTrack,
    this.primarySourceStreamId,
    this.primarySidecar,
    this.secondaryTrack,
    this.secondarySourceStreamId,
    this.secondarySidecar,
    this.preloadedSidecars = const [],
  });

  const PlaybackSubtitleSelection.off({this.preloadedSidecars = const []})
    : primaryTrack = SubtitleTrack.off,
      primarySourceStreamId = null,
      primarySidecar = null,
      secondaryTrack = null,
      secondarySourceStreamId = null,
      secondarySidecar = null;

  bool get isOff => primaryTrack.id == SubtitleTrack.off.id;

  List<SubtitleTrack> get sidecarsAtOpen {
    final tracks = <SubtitleTrack>[];
    final added = <SubtitleTrack>{};
    void add(SubtitleTrack? track) {
      if (track != null && added.add(track)) tracks.add(track);
    }

    for (final sidecar in preloadedSidecars) {
      add(sidecar.track);
    }
    add(primarySidecar?.track);
    add(secondarySidecar?.track);
    return tracks;
  }
}

/// Resolves the server subtitle catalog before opening the native player,
/// combining the active choice with any sidecars marked for preloading.
class PlaybackSubtitleResolver {
  const PlaybackSubtitleResolver._();

  /// Removes a per-source ID while retaining the semantic identity needed to
  /// carry a subtitle choice across items or media sources.
  static SubtitleTrack? preferenceWithoutSourceIdentity(SubtitleTrack? preferred) {
    if (preferred == null || preferred.id == SubtitleTrack.off.id || !preferred.id.startsWith('source:')) {
      return preferred;
    }
    return SubtitleTrack(
      id: 'navigation',
      title: preferred.title,
      language: preferred.language,
      codec: preferred.codec,
      isDefault: preferred.isDefault,
      isForced: preferred.isForced,
      isExternal: preferred.isExternal,
      isContainer: preferred.isContainer,
    );
  }

  static SubtitleTrack? _sourceBackedPreference(
    SubtitleTrack? preferred,
    MediaSourceInfo? mediaInfo,
    List<_SubtitleCandidate> candidates, {
    required bool preserveSourceIdentity,
  }) {
    if (preferred == null || preferred.id == SubtitleTrack.off.id) return preferred;

    var semanticPreference = preferred;
    if (preferred.id.startsWith('source:')) {
      if (preserveSourceIdentity) {
        final sourceStreamId = int.tryParse(preferred.id.substring('source:'.length));
        final exactCandidate = candidates.where((candidate) => candidate.sourceStreamId == sourceStreamId).firstOrNull;
        if (exactCandidate != null) return exactCandidate.track;
      } else {
        semanticPreference = preferenceWithoutSourceIdentity(preferred)!;
      }
    }

    final sourceMatch = findPlexTrackForMpvSubtitle(
      semanticPreference,
      mediaInfo?.subtitleTracks ?? const <MediaSubtitleTrack>[],
    );
    if (sourceMatch == null) return semanticPreference;

    for (final candidate in candidates) {
      if (candidate.sourceStreamId == sourceMatch.id) return candidate.track;
    }
    return semanticPreference;
  }

  static PlaybackSubtitleSelection resolve({
    required MediaItem metadata,
    required MediaSourceInfo? mediaInfo,
    required List<PlaybackSubtitleSidecar> sidecars,
    MediaServerUserProfile? profileSettings,
    AudioTrack? preferredAudioTrack,
    SubtitleTrack? preferredSubtitleTrack,
    SubtitleTrack? preferredSecondarySubtitleTrack,
    bool preserveSourceIdentity = true,
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

    final preloadedSidecars = sidecars.where((sidecar) => sidecar.preload).toList(growable: false);
    final availableTracks = candidates.map((candidate) => candidate.track).toList(growable: false);
    final service = TrackSelectionService(
      profileSettings: profileSettings,
      metadata: metadata,
      plexMediaInfo: mediaInfo,
    );
    final selectedAudio = service.selectAudioTrack(_audioTracksForSource(mediaInfo), preferredAudioTrack)?.track;
    final primaryPreference = _sourceBackedPreference(
      preferredSubtitleTrack,
      mediaInfo,
      candidates,
      preserveSourceIdentity: preserveSourceIdentity,
    );
    final primaryResult = service.selectSubtitleTrack(availableTracks, primaryPreference, selectedAudio);
    final primary = primaryResult?.track;
    if (primary == null || primary.id == SubtitleTrack.off.id) {
      return PlaybackSubtitleSelection.off(preloadedSidecars: preloadedSidecars);
    }

    final primaryCandidate = candidates.where((candidate) => candidate.track.id == primary.id).firstOrNull;
    if (primaryCandidate == null) {
      return PlaybackSubtitleSelection.off(preloadedSidecars: preloadedSidecars);
    }

    _SubtitleCandidate? secondaryCandidate;
    final secondaryPreference = _sourceBackedPreference(
      preferredSecondarySubtitleTrack,
      mediaInfo,
      candidates,
      preserveSourceIdentity: preserveSourceIdentity,
    );
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
      preloadedSidecars: preloadedSidecars,
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
      isContainer: playable?.isContainer ?? false,
      uri: playable?.uri,
    );
  }

  /// Resolve a server source row to a track already loaded by the player.
  /// Standalone sidecars match only by their stable URL key (or current source
  /// identity), while a container sidecar uses normal Plex/native metadata
  /// matching across the subtitle tracks extracted from that container.
  static SubtitleTrack? nativeTrackForSource({
    required MediaSubtitleTrack sourceTrack,
    required List<SubtitleTrack> nativeTracks,
    required List<MediaSubtitleTrack> allSourceTracks,
    required bool isResolvedSidecar,
    required bool isContainerSidecar,
    int? currentSourceStreamId,
    SubtitleTrack? selectedNativeTrack,
  }) {
    if (isResolvedSidecar) {
      if (isContainerSidecar) {
        final containerTracks = nativeTracks.where((track) => track.isContainer).toList(growable: false);
        return findMpvTrackForPlexSubtitle(sourceTrack, containerTracks, allPlexTracks: allSourceTracks);
      }
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
