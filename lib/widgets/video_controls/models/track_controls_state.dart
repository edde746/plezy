import 'package:flutter/material.dart';

import '../../../media/media_item.dart';
import '../../../media/media_version.dart';
import '../../../media/media_source_info.dart';
import '../../../media/packed_stereo_layout.dart';
import '../../../models/transcode_quality_preset.dart';
import '../../../mpv/mpv.dart';
import '../../../services/playback_initialization_types.dart';
import '../../../services/playback_subtitle_resolver.dart';
import '../../../services/shader_service.dart';
import '../helpers/track_filter_helper.dart';

enum SubtitleDownloadApplyOutcome { applied, timedOut, busy, superseded, unavailable, failed }

/// Immutable configuration for track/chapter control widgets.
class TrackControlsState {
  final List<MediaVersion> availableVersions;
  final int selectedMediaIndex;
  final TranscodeQualityPreset selectedQualityPreset;
  final bool serverSupportsTranscoding;
  final bool isTranscoding;
  final List<MediaAudioTrack> sourceAudioTracks;
  final int? selectedAudioStreamId;
  final List<MediaSubtitleTrack> sourceSubtitleTracks;
  final PlaybackSourceSubtitleChoice? selectedSubtitleChoice;
  final int? selectedSecondarySubtitleStreamId;
  final List<PlaybackSubtitleSidecar> sourceSubtitleSidecars;
  final int? sourcePartId;

  /// Total media duration in milliseconds. Used by the version/quality sheet
  /// to show estimated file sizes per preset (bitrate × duration).
  final int? sourceDurationMs;
  final int boxFitMode;
  final PackedStereoLayout packedStereoLayout;
  final double videoZoomScale;
  final int audioSyncOffset;
  final int subtitleSyncOffset;
  final bool isRotationLocked;
  final bool isFullscreen;
  final bool isAlwaysOnTop;
  final VoidCallback? onTogglePIPMode;
  final VoidCallback? onCycleBoxFitMode;
  final ValueChanged<double>? onVideoZoomChanged;
  final VoidCallback? onResetVideoZoom;
  final VoidCallback? onToggleRotationLock;
  final VoidCallback? onToggleScreenLock;
  final VoidCallback? onToggleFullscreen;
  final VoidCallback? onToggleAlwaysOnTop;
  final Function(int)? onSwitchVersion;
  final ValueChanged<TranscodeQualityPreset>? onSwitchQualityPreset;
  final Future<void> Function(int)? onSwitchAudioStreamId;
  final Future<void> Function(PlaybackSourceSubtitleChoice)? onSwitchSubtitle;
  final Function(AudioTrack)? onAudioTrackChanged;
  final Function(SubtitleTrack)? onSubtitleTrackChanged;
  final Function(SubtitleTrack)? onSecondarySubtitleTrackChanged;
  final Future<void> Function()? onClipRequested;
  final VoidCallback? onCancelAutoHide;
  final VoidCallback? onStartAutoHide;
  final String? serverId;
  final ShaderService? shaderService;
  final VoidCallback? onShaderChanged;
  final bool isAmbientLightingEnabled;
  final VoidCallback? onToggleAmbientLighting;
  final bool canControl;
  final bool isLive;
  final bool subtitlesVisible;
  final bool showQueueButton;
  final Function(MediaItem)? onQueueItemSelected;
  final String ratingKey;
  final String? mediaTitle;

  /// Item currently playing, used to key scope-persisted player settings
  /// ([ScopedPlayerPrefs]). Null only for embedders without item identity.
  final MediaItem? metadata;
  final Future<SubtitleDownloadApplyOutcome> Function({required String serverId, required String ratingKey})?
  onSubtitleDownloaded;

  /// Whether OpenSubtitles search is reachable for this server. The Plex
  /// server proxies the OpenSubtitles plugin; Jellyfin doesn't expose an
  /// equivalent. The track sheet hides the "Search subtitles" tile when
  /// this is false.
  final bool subtitleSearchSupported;

  const TrackControlsState({
    this.availableVersions = const [],
    this.selectedMediaIndex = 0,
    this.selectedQualityPreset = TranscodeQualityPreset.original,
    this.serverSupportsTranscoding = false,
    this.isTranscoding = false,
    this.sourceAudioTracks = const [],
    this.selectedAudioStreamId,
    this.sourceSubtitleTracks = const [],
    this.selectedSubtitleChoice,
    this.selectedSecondarySubtitleStreamId,
    this.sourceSubtitleSidecars = const <PlaybackSubtitleSidecar>[],
    this.sourcePartId,
    this.sourceDurationMs,
    this.boxFitMode = 0,
    this.packedStereoLayout = PackedStereoLayout.unknown,
    this.videoZoomScale = 1.0,
    this.audioSyncOffset = 0,
    this.subtitleSyncOffset = 0,
    this.isRotationLocked = false,
    this.isFullscreen = false,
    this.isAlwaysOnTop = false,
    this.onTogglePIPMode,
    this.onCycleBoxFitMode,
    this.onVideoZoomChanged,
    this.onResetVideoZoom,
    this.onToggleRotationLock,
    this.onToggleScreenLock,
    this.onToggleFullscreen,
    this.onToggleAlwaysOnTop,
    this.onSwitchVersion,
    this.onSwitchQualityPreset,
    this.onSwitchAudioStreamId,
    this.onSwitchSubtitle,
    this.onAudioTrackChanged,
    this.onSubtitleTrackChanged,
    this.onSecondarySubtitleTrackChanged,
    this.onClipRequested,
    this.onCancelAutoHide,
    this.onStartAutoHide,
    this.serverId,
    this.metadata,
    this.shaderService,
    this.onShaderChanged,
    this.isAmbientLightingEnabled = false,
    this.onToggleAmbientLighting,
    this.canControl = true,
    this.isLive = false,
    this.subtitlesVisible = true,
    this.showQueueButton = false,
    this.onQueueItemSelected,
    this.ratingKey = '',
    this.mediaTitle,
    this.onSubtitleDownloaded,
    this.subtitleSearchSupported = true,
  });

  /// Transcoded subtitle choices must be negotiated with the server and
  /// therefore replace the native rendition track list. A live session's
  /// server-side tracks work the same way — the stream is rebuilt with the
  /// chosen track burned in (Plex live DVB subtitles, issue #1983) — while a
  /// live stream that exposes none keeps the native list (in-band CEA
  /// captions, issue #1590).
  bool get canUseSourceSubtitles =>
      (isTranscoding || isLive) && sourceSubtitleTracks.isNotEmpty && onSwitchSubtitle != null;

  /// Direct play keeps embedded/native switching instant while still exposing
  /// unloaded server sidecars that require one source reopen when selected.
  List<MediaSubtitleTrack> get directPlaySourceSidecars => !isTranscoding && onSwitchSubtitle != null
      ? sourceSubtitleTracks
            .where(
              (track) => sourceSubtitleSidecars.any(
                (sidecar) => sidecar.sourceStreamId != null && sidecar.sourceStreamId == track.id,
              ),
            )
            .toList(growable: false)
      : const <MediaSubtitleTrack>[];

  /// External subtitle search needs both a searchable media item and a server
  /// that can proxy the OpenSubtitles request.
  bool get canSearchSubtitles =>
      ratingKey.isNotEmpty && serverId != null && serverId!.isNotEmpty && subtitleSearchSupported;

  /// Whether the track sheet should expose subtitle controls at all. This is
  /// the single source of truth shared by the toolbar icon and the sheet layout.
  bool hasSubtitleControls(Tracks? tracks) {
    final playerSubtitles = tracks?.subtitle ?? const <SubtitleTrack>[];
    return canUseSourceSubtitles ||
        directPlaySourceSidecars.isNotEmpty ||
        TrackFilterHelper.hasTracks<SubtitleTrack>(playerSubtitles) ||
        canSearchSubtitles;
  }
}
