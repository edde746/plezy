import 'package:flutter/material.dart';

import '../../../media/media_item.dart';
import '../../../media/media_version.dart';
import '../../../media/media_source_info.dart';
import '../../../models/transcode_quality_preset.dart';
import '../../../mpv/mpv.dart';
import '../../../services/shader_service.dart';
import '../helpers/track_filter_helper.dart';

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
  final int? selectedSubtitleStreamId;
  final int? sourcePartId;

  /// Total media duration in milliseconds. Used by the version/quality sheet
  /// to show estimated file sizes per preset (bitrate × duration).
  final int? sourceDurationMs;
  final int boxFitMode;
  final double videoZoomScale;
  final int audioSyncOffset;
  final int subtitleSyncOffset;
  final bool isRotationLocked;
  final bool isScreenLocked;
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
  final ValueChanged<int>? onSwitchAudioStreamId;
  final ValueChanged<int>? onSwitchSubtitleStreamId;
  final Function(AudioTrack)? onAudioTrackChanged;
  final Function(SubtitleTrack)? onSubtitleTrackChanged;
  final Function(SubtitleTrack)? onSecondarySubtitleTrackChanged;
  final VoidCallback? onLoadSeekTimes;
  final VoidCallback? onCancelAutoHide;
  final VoidCallback? onStartAutoHide;
  final void Function(String propertyName, int offset)? onSyncOffsetChanged;
  final String serverId;
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
  final Future<void> Function()? onSubtitleDownloaded;

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
    this.selectedSubtitleStreamId,
    this.sourcePartId,
    this.sourceDurationMs,
    this.boxFitMode = 0,
    this.videoZoomScale = 1.0,
    this.audioSyncOffset = 0,
    this.subtitleSyncOffset = 0,
    this.isRotationLocked = false,
    this.isScreenLocked = false,
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
    this.onSwitchSubtitleStreamId,
    this.onAudioTrackChanged,
    this.onSubtitleTrackChanged,
    this.onSecondarySubtitleTrackChanged,
    this.onLoadSeekTimes,
    this.onCancelAutoHide,
    this.onStartAutoHide,
    this.onSyncOffsetChanged,
    this.serverId = '',
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

  /// Source subtitles can only be selected when playback can be re-opened with
  /// a Plex source subtitle stream id.
  bool get canUseSourceSubtitles =>
      isTranscoding && sourceSubtitleTracks.isNotEmpty && onSwitchSubtitleStreamId != null;

  /// External subtitle search needs both a searchable media item and a server
  /// that can proxy the OpenSubtitles request.
  bool get canSearchSubtitles => ratingKey.isNotEmpty && serverId.isNotEmpty && subtitleSearchSupported;

  /// Whether the track sheet should expose subtitle controls at all. This is
  /// the single source of truth shared by the toolbar icon and the sheet layout.
  bool hasSubtitleControls(Tracks? tracks) {
    final playerSubtitles = tracks?.subtitle ?? const <SubtitleTrack>[];
    return canUseSourceSubtitles || TrackFilterHelper.hasTracks<SubtitleTrack>(playerSubtitles) || canSearchSubtitles;
  }
}
