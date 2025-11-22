import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import '../../../models/plex_media_info.dart';
import '../../../models/plex_media_version.dart';
import '../../../services/sleep_timer_service.dart';
import '../../../utils/platform_detector.dart';
import '../../../i18n/strings.g.dart';
import '../sheets/audio_track_sheet.dart';
import '../sheets/chapter_sheet.dart';
import '../sheets/subtitle_track_sheet.dart';
import '../sheets/version_sheet.dart';
import '../sheets/video_settings_sheet.dart';
import '../video_control_button.dart';

/// Row of track and chapter control buttons for the video player
class TrackChapterControls extends StatelessWidget {
  final Player player;
  final List<PlexChapter> chapters;
  final bool chaptersLoaded;
  final List<PlexMediaVersion> availableVersions;
  final int selectedMediaIndex;
  final int boxFitMode;
  final int audioSyncOffset;
  final int subtitleSyncOffset;
  final bool isRotationLocked;
  final bool isFullscreen;
  final VoidCallback? onCycleBoxFitMode;
  final VoidCallback? onToggleRotationLock;
  final VoidCallback? onToggleFullscreen;
  final Function(int)? onSwitchVersion;
  final Function(AudioTrack)? onAudioTrackChanged;
  final Function(SubtitleTrack)? onSubtitleTrackChanged;
  final VoidCallback? onLoadSeekTimes;
  final String serverId;

  const TrackChapterControls({
    super.key,
    required this.player,
    required this.chapters,
    required this.chaptersLoaded,
    required this.availableVersions,
    required this.selectedMediaIndex,
    required this.boxFitMode,
    required this.audioSyncOffset,
    required this.subtitleSyncOffset,
    required this.isRotationLocked,
    required this.isFullscreen,
    required this.serverId,
    this.onCycleBoxFitMode,
    this.onToggleRotationLock,
    this.onToggleFullscreen,
    this.onSwitchVersion,
    this.onAudioTrackChanged,
    this.onSubtitleTrackChanged,
    this.onLoadSeekTimes,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Tracks>(
      stream: player.stream.tracks,
      initialData: player.state.tracks,
      builder: (context, snapshot) {
        final tracks = snapshot.data;
        return IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Unified settings button (speed, sleep timer, audio sync, subtitle sync)
              ListenableBuilder(
                listenable: SleepTimerService(),
                builder: (context, _) {
                  final sleepTimer = SleepTimerService();
                  final isActive =
                      sleepTimer.isActive ||
                      audioSyncOffset != 0 ||
                      subtitleSyncOffset != 0;
                  return VideoControlButton(
                    icon: Icons.tune,
                    isActive: isActive,
                    semanticLabel: t.videoControls.settingsButton,
                    onPressed: () async {
                      await VideoSettingsSheet.show(
                        context,
                        player,
                        audioSyncOffset,
                        subtitleSyncOffset,
                      );
                      // Sheet is now closed, reload immediately
                      onLoadSeekTimes?.call();
                    },
                  );
                },
              ),
              if (_hasMultipleAudioTracks(tracks))
                VideoControlButton(
                  icon: Icons.audiotrack,
                  semanticLabel: t.videoControls.audioTrackButton,
                  onPressed: () => AudioTrackSheet.show(
                    context,
                    player,
                    onTrackChanged: onAudioTrackChanged,
                  ),
                ),
              if (_hasSubtitles(tracks))
                VideoControlButton(
                  icon: Icons.subtitles,
                  semanticLabel: t.videoControls.subtitlesButton,
                  onPressed: () => SubtitleTrackSheet.show(
                    context,
                    player,
                    onTrackChanged: onSubtitleTrackChanged,
                  ),
                ),
              if (chapters.isNotEmpty)
                VideoControlButton(
                  icon: Icons.video_library,
                  semanticLabel: t.videoControls.chaptersButton,
                  onPressed: () => ChapterSheet.show(
                    context,
                    player,
                    chapters,
                    chaptersLoaded,
                    serverId: serverId,
                  ),
                ),
              if (availableVersions.length > 1 && onSwitchVersion != null)
                VideoControlButton(
                  icon: Icons.video_file,
                  semanticLabel: t.videoControls.versionsButton,
                  onPressed: () => VersionSheet.show(
                    context,
                    availableVersions,
                    selectedMediaIndex,
                    onSwitchVersion!,
                  ),
                ),
              // BoxFit mode cycle button
              if (onCycleBoxFitMode != null)
                VideoControlButton(
                  icon: _getBoxFitIcon(boxFitMode),
                  tooltip: _getBoxFitTooltip(boxFitMode),
                  semanticLabel: t.videoControls.aspectRatioButton,
                  onPressed: onCycleBoxFitMode,
                ),
              // Rotation lock toggle (mobile only)
              if (PlatformDetector.isMobile(context))
                VideoControlButton(
                  icon: isRotationLocked
                      ? Icons.screen_lock_rotation
                      : Icons.screen_rotation,
                  tooltip: isRotationLocked
                      ? t.videoControls.unlockRotation
                      : t.videoControls.lockRotation,
                  semanticLabel: t.videoControls.rotationLockButton,
                  onPressed: onToggleRotationLock,
                ),
              // Fullscreen toggle (desktop only)
              if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
                VideoControlButton(
                  icon: isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  semanticLabel: isFullscreen
                      ? t.videoControls.exitFullscreenButton
                      : t.videoControls.fullscreenButton,
                  onPressed: onToggleFullscreen,
                ),
            ],
          ),
        );
      },
    );
  }

  bool _hasMultipleAudioTracks(Tracks? tracks) {
    if (tracks == null) return false;
    final audioTracks = tracks.audio
        .where((track) => track.id != 'auto' && track.id != 'no')
        .toList();
    return audioTracks.length > 1;
  }

  bool _hasSubtitles(Tracks? tracks) {
    if (tracks == null) return false;
    final subtitles = tracks.subtitle
        .where((track) => track.id != 'auto' && track.id != 'no')
        .toList();
    return subtitles.isNotEmpty;
  }

  IconData _getBoxFitIcon(int mode) {
    switch (mode) {
      case 0:
        return Icons.fit_screen; // contain (letterbox)
      case 1:
        return Icons.aspect_ratio; // cover (fill screen)
      case 2:
        return Icons.settings_overscan; // fill (stretch)
      default:
        return Icons.fit_screen;
    }
  }

  String _getBoxFitTooltip(int mode) {
    switch (mode) {
      case 0:
        return t.videoControls.letterbox;
      case 1:
        return t.videoControls.fillScreen;
      case 2:
        return t.videoControls.stretch;
      default:
        return t.videoControls.letterbox;
    }
  }
}
