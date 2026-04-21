import 'package:flutter/material.dart';

import '../../../models/plex_media_info.dart';
import '../../../models/plex_media_version.dart';
import '../../../models/plex_metadata.dart';
import '../../../models/transcode_quality_preset.dart';
import '../../../mpv/mpv.dart';
import '../../../services/shader_service.dart';

/// Immutable configuration for track/chapter control widgets.
class TrackControlsState {
  final List<PlexMediaVersion> availableVersions;
  final int selectedMediaIndex;
  final TranscodeQualityPreset selectedQualityPreset;
  final bool serverSupportsTranscoding;
  final bool isTranscoding;
  final List<PlexAudioTrack> sourceAudioTracks;
  final int? selectedAudioStreamId;

  /// Total media duration in milliseconds. Used by the version/quality sheet
  /// to show estimated file sizes per preset (bitrate × duration).
  final int? sourceDurationMs;
  final int boxFitMode;
  final int audioSyncOffset;
  final int subtitleSyncOffset;
  final bool isRotationLocked;
  final bool isScreenLocked;
  final bool isFullscreen;
  final bool isAlwaysOnTop;
  final VoidCallback? onTogglePIPMode;
  final VoidCallback? onCycleBoxFitMode;
  final VoidCallback? onToggleRotationLock;
  final VoidCallback? onToggleScreenLock;
  final VoidCallback? onToggleFullscreen;
  final VoidCallback? onToggleAlwaysOnTop;
  final Function(int)? onSwitchVersion;
  final ValueChanged<TranscodeQualityPreset>? onSwitchQualityPreset;
  final ValueChanged<int>? onSwitchAudioStreamId;
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
  final Function(PlexMetadata)? onQueueItemSelected;
  final String ratingKey;
  final String? mediaTitle;
  final Future<void> Function()? onSubtitleDownloaded;

  const TrackControlsState({
    this.availableVersions = const [],
    this.selectedMediaIndex = 0,
    this.selectedQualityPreset = TranscodeQualityPreset.original,
    this.serverSupportsTranscoding = false,
    this.isTranscoding = false,
    this.sourceAudioTracks = const [],
    this.selectedAudioStreamId,
    this.sourceDurationMs,
    this.boxFitMode = 0,
    this.audioSyncOffset = 0,
    this.subtitleSyncOffset = 0,
    this.isRotationLocked = false,
    this.isScreenLocked = false,
    this.isFullscreen = false,
    this.isAlwaysOnTop = false,
    this.onTogglePIPMode,
    this.onCycleBoxFitMode,
    this.onToggleRotationLock,
    this.onToggleScreenLock,
    this.onToggleFullscreen,
    this.onToggleAlwaysOnTop,
    this.onSwitchVersion,
    this.onSwitchQualityPreset,
    this.onSwitchAudioStreamId,
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
  });
}
