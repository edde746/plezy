import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../mpv/mpv.dart';
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
import '../helpers/track_filter_helper.dart';
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
  final VoidCallback? onCancelAutoHide;
  final VoidCallback? onStartAutoHide;
  final String serverId;

  /// List of FocusNodes for the buttons (passed from parent for navigation)
  final List<FocusNode>? focusNodes;

  /// Called when focus changes on any button
  final ValueChanged<bool>? onFocusChange;

  /// Called to navigate left from the first button
  final VoidCallback? onNavigateLeft;

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
    this.onCancelAutoHide,
    this.onStartAutoHide,
    this.focusNodes,
    this.onFocusChange,
    this.onNavigateLeft,
  });

  /// Handle key event for button navigation
  KeyEventResult _handleButtonKeyEvent(
    FocusNode node,
    KeyEvent event,
    int index,
    int totalButtons,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    // LEFT arrow - move to previous button or exit to volume
    if (key == LogicalKeyboardKey.arrowLeft) {
      if (index > 0 && focusNodes != null && focusNodes!.length > index - 1) {
        focusNodes![index - 1].requestFocus();
        return KeyEventResult.handled;
      } else if (index == 0) {
        onNavigateLeft?.call();
        return KeyEventResult.handled;
      }
      return KeyEventResult.handled;
    }

    // RIGHT arrow - move to next button
    if (key == LogicalKeyboardKey.arrowRight) {
      if (index < totalButtons - 1 &&
          focusNodes != null &&
          focusNodes!.length > index + 1) {
        focusNodes![index + 1].requestFocus();
        return KeyEventResult.handled;
      }
      // At end, consume to prevent bubbling
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Tracks>(
      stream: player.streams.tracks,
      initialData: player.state.tracks,
      builder: (context, snapshot) {
        final tracks = snapshot.data;
        final isMobile = PlatformDetector.isMobile(context);
        final isDesktop =
            Platform.isWindows || Platform.isLinux || Platform.isMacOS;

        // Build list of buttons dynamically to track indices
        final buttons = <Widget>[];
        int buttonIndex = 0;

        // Settings button (always shown)
        buttons.add(
          ListenableBuilder(
            listenable: SleepTimerService(),
            builder: (context, _) {
              final sleepTimer = SleepTimerService();
              final isActive =
                  sleepTimer.isActive ||
                  audioSyncOffset != 0 ||
                  subtitleSyncOffset != 0;
              final currentIndex = 0;
              return VideoControlButton(
                icon: Icons.tune,
                isActive: isActive,
                semanticLabel: t.videoControls.settingsButton,
                focusNode: focusNodes != null && focusNodes!.isNotEmpty
                    ? focusNodes![currentIndex]
                    : null,
                onKeyEvent: focusNodes != null
                    ? (node, event) => _handleButtonKeyEvent(
                        node,
                        event,
                        currentIndex,
                        _getButtonCount(tracks, isMobile, isDesktop),
                      )
                    : null,
                onFocusChange: onFocusChange,
                onPressed: () async {
                  await VideoSettingsSheet.show(
                    context,
                    player,
                    audioSyncOffset,
                    subtitleSyncOffset,
                    onOpen: onCancelAutoHide,
                    onClose: onStartAutoHide,
                  );
                  onLoadSeekTimes?.call();
                },
              );
            },
          ),
        );
        buttonIndex++;

        // Audio track button
        if (_hasMultipleAudioTracks(tracks)) {
          final currentIndex = buttonIndex;
          buttons.add(
            VideoControlButton(
              icon: Icons.audiotrack,
              semanticLabel: t.videoControls.audioTrackButton,
              focusNode: focusNodes != null && focusNodes!.length > currentIndex
                  ? focusNodes![currentIndex]
                  : null,
              onKeyEvent: focusNodes != null
                  ? (node, event) => _handleButtonKeyEvent(
                      node,
                      event,
                      currentIndex,
                      _getButtonCount(tracks, isMobile, isDesktop),
                    )
                  : null,
              onFocusChange: onFocusChange,
              onPressed: () => AudioTrackSheet.show(
                context,
                player,
                onTrackChanged: onAudioTrackChanged,
                onOpen: onCancelAutoHide,
                onClose: onStartAutoHide,
              ),
            ),
          );
          buttonIndex++;
        }

        // Subtitles button
        if (_hasSubtitles(tracks)) {
          final currentIndex = buttonIndex;
          buttons.add(
            VideoControlButton(
              icon: Icons.subtitles,
              semanticLabel: t.videoControls.subtitlesButton,
              focusNode: focusNodes != null && focusNodes!.length > currentIndex
                  ? focusNodes![currentIndex]
                  : null,
              onKeyEvent: focusNodes != null
                  ? (node, event) => _handleButtonKeyEvent(
                      node,
                      event,
                      currentIndex,
                      _getButtonCount(tracks, isMobile, isDesktop),
                    )
                  : null,
              onFocusChange: onFocusChange,
              onPressed: () => SubtitleTrackSheet.show(
                context,
                player,
                onTrackChanged: onSubtitleTrackChanged,
                onOpen: onCancelAutoHide,
                onClose: onStartAutoHide,
              ),
            ),
          );
          buttonIndex++;
        }

        // Chapters button
        if (chapters.isNotEmpty) {
          final currentIndex = buttonIndex;
          buttons.add(
            VideoControlButton(
              icon: Icons.video_library,
              semanticLabel: t.videoControls.chaptersButton,
              focusNode: focusNodes != null && focusNodes!.length > currentIndex
                  ? focusNodes![currentIndex]
                  : null,
              onKeyEvent: focusNodes != null
                  ? (node, event) => _handleButtonKeyEvent(
                      node,
                      event,
                      currentIndex,
                      _getButtonCount(tracks, isMobile, isDesktop),
                    )
                  : null,
              onFocusChange: onFocusChange,
              onPressed: () => ChapterSheet.show(
                context,
                player,
                chapters,
                chaptersLoaded,
                serverId: serverId,
                onOpen: onCancelAutoHide,
                onClose: onStartAutoHide,
              ),
            ),
          );
          buttonIndex++;
        }

        // Versions button
        if (availableVersions.length > 1 && onSwitchVersion != null) {
          final currentIndex = buttonIndex;
          buttons.add(
            VideoControlButton(
              icon: Icons.video_file,
              semanticLabel: t.videoControls.versionsButton,
              focusNode: focusNodes != null && focusNodes!.length > currentIndex
                  ? focusNodes![currentIndex]
                  : null,
              onKeyEvent: focusNodes != null
                  ? (node, event) => _handleButtonKeyEvent(
                      node,
                      event,
                      currentIndex,
                      _getButtonCount(tracks, isMobile, isDesktop),
                    )
                  : null,
              onFocusChange: onFocusChange,
              onPressed: () => VersionSheet.show(
                context,
                availableVersions,
                selectedMediaIndex,
                onSwitchVersion!,
                onOpen: onCancelAutoHide,
                onClose: onStartAutoHide,
              ),
            ),
          );
          buttonIndex++;
        }

        // BoxFit mode button
        if (onCycleBoxFitMode != null) {
          final currentIndex = buttonIndex;
          buttons.add(
            VideoControlButton(
              icon: _getBoxFitIcon(boxFitMode),
              tooltip: _getBoxFitTooltip(boxFitMode),
              semanticLabel: t.videoControls.aspectRatioButton,
              focusNode: focusNodes != null && focusNodes!.length > currentIndex
                  ? focusNodes![currentIndex]
                  : null,
              onKeyEvent: focusNodes != null
                  ? (node, event) => _handleButtonKeyEvent(
                      node,
                      event,
                      currentIndex,
                      _getButtonCount(tracks, isMobile, isDesktop),
                    )
                  : null,
              onFocusChange: onFocusChange,
              onPressed: onCycleBoxFitMode,
            ),
          );
          buttonIndex++;
        }

        // Rotation lock button (mobile only)
        if (isMobile) {
          final currentIndex = buttonIndex;
          buttons.add(
            VideoControlButton(
              icon: isRotationLocked
                  ? Icons.screen_lock_rotation
                  : Icons.screen_rotation,
              tooltip: isRotationLocked
                  ? t.videoControls.unlockRotation
                  : t.videoControls.lockRotation,
              semanticLabel: t.videoControls.rotationLockButton,
              focusNode: focusNodes != null && focusNodes!.length > currentIndex
                  ? focusNodes![currentIndex]
                  : null,
              onKeyEvent: focusNodes != null
                  ? (node, event) => _handleButtonKeyEvent(
                      node,
                      event,
                      currentIndex,
                      _getButtonCount(tracks, isMobile, isDesktop),
                    )
                  : null,
              onFocusChange: onFocusChange,
              onPressed: onToggleRotationLock,
            ),
          );
          buttonIndex++;
        }

        // Fullscreen button (desktop only)
        if (isDesktop) {
          final currentIndex = buttonIndex;
          buttons.add(
            VideoControlButton(
              icon: isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
              semanticLabel: isFullscreen
                  ? t.videoControls.exitFullscreenButton
                  : t.videoControls.fullscreenButton,
              focusNode: focusNodes != null && focusNodes!.length > currentIndex
                  ? focusNodes![currentIndex]
                  : null,
              onKeyEvent: focusNodes != null
                  ? (node, event) => _handleButtonKeyEvent(
                      node,
                      event,
                      currentIndex,
                      _getButtonCount(tracks, isMobile, isDesktop),
                    )
                  : null,
              onFocusChange: onFocusChange,
              onPressed: onToggleFullscreen,
            ),
          );
        }

        return IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: buttons,
          ),
        );
      },
    );
  }

  /// Calculate total button count for navigation
  int _getButtonCount(Tracks? tracks, bool isMobile, bool isDesktop) {
    int count = 1; // Settings button always shown
    if (_hasMultipleAudioTracks(tracks)) count++;
    if (_hasSubtitles(tracks)) count++;
    if (chapters.isNotEmpty) count++;
    if (availableVersions.length > 1 && onSwitchVersion != null) count++;
    if (onCycleBoxFitMode != null) count++;
    if (isMobile) count++;
    if (isDesktop) count++;
    return count;
  }

  bool _hasMultipleAudioTracks(Tracks? tracks) {
    if (tracks == null) return false;
    return TrackFilterHelper.hasMultipleTracks<AudioTrack>(tracks.audio);
  }

  bool _hasSubtitles(Tracks? tracks) {
    if (tracks == null) return false;
    return TrackFilterHelper.hasTracks<SubtitleTrack>(tracks.subtitle);
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
