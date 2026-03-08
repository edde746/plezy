import 'package:flutter/material.dart';

import '../../../models/plex_media_version.dart';
import '../../../models/plex_metadata.dart';
import '../../../mpv/mpv.dart';
import '../../../services/shader_service.dart';

/// Immutable configuration for track/chapter control widgets.
class TrackControlsState {
  final List<PlexMediaVersion> availableVersions;
  final int selectedMediaIndex;
  final int boxFitMode;
  final int audioSyncOffset;
  final int subtitleSyncOffset;
  final bool isRotationLocked;
  final bool isFullscreen;
  final bool isAlwaysOnTop;
  final VoidCallback? onTogglePIPMode;
  final VoidCallback? onCycleBoxFitMode;
  final VoidCallback? onToggleRotationLock;
  final VoidCallback? onToggleFullscreen;
  final VoidCallback? onToggleAlwaysOnTop;
  final Function(int)? onSwitchVersion;
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

  const TrackControlsState({
    this.availableVersions = const [],
    this.selectedMediaIndex = 0,
    this.boxFitMode = 0,
    this.audioSyncOffset = 0,
    this.subtitleSyncOffset = 0,
    this.isRotationLocked = false,
    this.isFullscreen = false,
    this.isAlwaysOnTop = false,
    this.onTogglePIPMode,
    this.onCycleBoxFitMode,
    this.onToggleRotationLock,
    this.onToggleFullscreen,
    this.onToggleAlwaysOnTop,
    this.onSwitchVersion,
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
  });
}
