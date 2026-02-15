import '../../../utils/platform_helper.dart';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/services.dart';

import '../../../focus/dpad_navigator.dart';
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
import '../../../services/shader_service.dart';
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
  final bool isAlwaysOnTop;
  final VoidCallback? onTogglePIPMode;
  final VoidCallback? onCycleBoxFitMode;
  final VoidCallback? onToggleRotationLock;
  final VoidCallback? onToggleFullscreen;
  final VoidCallback? onToggleAlwaysOnTop;
  final Function(int)? onSwitchVersion;
  final Function(AudioTrack)? onAudioTrackChanged;
  final Function(SubtitleTrack)? onSubtitleTrackChanged;
  final VoidCallback? onLoadSeekTimes;
  final VoidCallback? onCancelAutoHide;
  final VoidCallback? onStartAutoHide;
  final String serverId;
  final ShaderService? shaderService;
  final VoidCallback? onShaderChanged;

  /// List of FocusNodes for the buttons (passed from parent for navigation)
  final List<FocusNode>? focusNodes;

  /// Called when focus changes on any button
  final ValueChanged<bool>? onFocusChange;

  /// Called to navigate left from the first button
  final VoidCallback? onNavigateLeft;

  /// Whether the user can control playback (false in host-only mode for non-host).
  final bool canControl;

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
    this.isAlwaysOnTop = false,
    this.onTogglePIPMode,
    this.onCycleBoxFitMode,
    this.onToggleRotationLock,
    this.onToggleFullscreen,
    this.onToggleAlwaysOnTop,
    this.onSwitchVersion,
    this.onAudioTrackChanged,
    this.onSubtitleTrackChanged,
    this.onLoadSeekTimes,
    this.onCancelAutoHide,
    this.onStartAutoHide,
    this.focusNodes,
    this.onFocusChange,
    this.onNavigateLeft,
    this.canControl = true,
    this.shaderService,
    this.onShaderChanged,
  });

  /// Handle key event for button navigation
  KeyEventResult _handleButtonKeyEvent(FocusNode node, KeyEvent event, int index, int totalButtons) {
    if (!event.isActionable) {
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
      if (index < totalButtons - 1 && focusNodes != null && focusNodes!.length > index + 1) {
        focusNodes![index + 1].requestFocus();
        return KeyEventResult.handled;
      }
      // At end, consume to prevent bubbling
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Build a track control button with consistent focus handling
  Widget _buildTrackButton({
    required int buttonIndex,
    required IconData icon,
    required String semanticLabel,
    required VoidCallback? onPressed,
    required Tracks? tracks,
    required bool isMobile,
    required bool isDesktop,
    String? tooltip,
    bool isActive = false,
  }) {
    return VideoControlButton(
      icon: icon,
      tooltip: tooltip,
      semanticLabel: semanticLabel,
      isActive: isActive,
      focusNode: focusNodes != null && focusNodes!.length > buttonIndex ? focusNodes![buttonIndex] : null,
      onKeyEvent: focusNodes != null
          ? (node, event) =>
                _handleButtonKeyEvent(node, event, buttonIndex, _getButtonCount(tracks, isMobile, isDesktop))
          : null,
      onFocusChange: onFocusChange,
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Tracks>(
      stream: player.streams.tracks,
      initialData: player.state.tracks,
      builder: (context, snapshot) {
        final tracks = snapshot.data;
        final isMobile = PlatformDetector.isMobile(context);
        final isDesktop = AppPlatform.isWindows || AppPlatform.isLinux || AppPlatform.isMacOS;

        // Build list of buttons dynamically to track indices
        final buttons = <Widget>[];
        int buttonIndex = 0;

        // Settings button (always shown)
        buttons.add(
          ListenableBuilder(
            listenable: SleepTimerService(),
            builder: (context, _) {
              final sleepTimer = SleepTimerService();
              final isShaderActive =
                  shaderService != null && shaderService!.isSupported && shaderService!.currentPreset.isEnabled;
              final isActive = sleepTimer.isActive || audioSyncOffset != 0 || subtitleSyncOffset != 0 || isShaderActive;
              return _buildTrackButton(
                buttonIndex: 0,
                icon: Symbols.tune_rounded,
                isActive: isActive,
                tooltip: t.videoControls.settingsButton,
                semanticLabel: t.videoControls.settingsButton,
                tracks: tracks,
                isMobile: isMobile,
                isDesktop: isDesktop,
                onPressed: () async {
                  await VideoSettingsSheet.show(
                    context,
                    player,
                    audioSyncOffset,
                    subtitleSyncOffset,
                    onOpen: onCancelAutoHide,
                    onClose: onStartAutoHide,
                    canControl: canControl,
                    shaderService: shaderService,
                    onShaderChanged: onShaderChanged,
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
            _buildTrackButton(
              buttonIndex: currentIndex,
              icon: Symbols.audiotrack_rounded,
              tooltip: t.videoControls.audioTrackButton,
              semanticLabel: t.videoControls.audioTrackButton,
              tracks: tracks,
              isMobile: isMobile,
              isDesktop: isDesktop,
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
            _buildTrackButton(
              buttonIndex: currentIndex,
              icon: Symbols.subtitles_rounded,
              tooltip: t.videoControls.subtitlesButton,
              semanticLabel: t.videoControls.subtitlesButton,
              tracks: tracks,
              isMobile: isMobile,
              isDesktop: isDesktop,
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
            _buildTrackButton(
              buttonIndex: currentIndex,
              icon: Symbols.video_library_rounded,
              tooltip: t.videoControls.chaptersButton,
              semanticLabel: t.videoControls.chaptersButton,
              tracks: tracks,
              isMobile: isMobile,
              isDesktop: isDesktop,
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
            _buildTrackButton(
              buttonIndex: currentIndex,
              icon: Symbols.video_file_rounded,
              tooltip: t.videoControls.versionsButton,
              semanticLabel: t.videoControls.versionsButton,
              tracks: tracks,
              isMobile: isMobile,
              isDesktop: isDesktop,
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

        // Picture-in-Picture mode
        if (onTogglePIPMode != null) {
          final currentIndex = buttonIndex;
          buttons.add(
            _buildTrackButton(
              buttonIndex: currentIndex,
              icon: Symbols.picture_in_picture_alt,
              tooltip: t.videoControls.pipButton,
              semanticLabel: t.videoControls.pipButton,
              tracks: tracks,
              isMobile: isMobile,
              isDesktop: isDesktop,
              onPressed: onTogglePIPMode,
            ),
          );
          buttonIndex++;
        }

        // BoxFit mode button
        if (onCycleBoxFitMode != null) {
          final currentIndex = buttonIndex;
          buttons.add(
            _buildTrackButton(
              buttonIndex: currentIndex,
              icon: _getBoxFitIcon(boxFitMode),
              tooltip: _getBoxFitTooltip(boxFitMode),
              semanticLabel: t.videoControls.aspectRatioButton,
              tracks: tracks,
              isMobile: isMobile,
              isDesktop: isDesktop,
              onPressed: onCycleBoxFitMode,
            ),
          );
          buttonIndex++;
        }

        // Rotation lock button (mobile only, not on TV since screens don't rotate)
        if (isMobile && !PlatformDetector.isTV()) {
          final currentIndex = buttonIndex;
          buttons.add(
            _buildTrackButton(
              buttonIndex: currentIndex,
              icon: isRotationLocked ? Symbols.screen_lock_rotation_rounded : Symbols.screen_rotation_rounded,
              tooltip: isRotationLocked ? t.videoControls.unlockRotation : t.videoControls.lockRotation,
              semanticLabel: t.videoControls.rotationLockButton,
              tracks: tracks,
              isMobile: isMobile,
              isDesktop: isDesktop,
              onPressed: onToggleRotationLock,
            ),
          );
          buttonIndex++;
        }

        // Always on top button (desktop only, not TV)
        if (isDesktop && onToggleAlwaysOnTop != null) {
          final currentIndex = buttonIndex;
          buttons.add(
            _buildTrackButton(
              buttonIndex: currentIndex,
              icon: Symbols.layers_rounded,
              tooltip: t.videoControls.alwaysOnTopButton,
              semanticLabel: t.videoControls.alwaysOnTopButton,
              isActive: isAlwaysOnTop,
              tracks: tracks,
              isMobile: isMobile,
              isDesktop: isDesktop,
              onPressed: onToggleAlwaysOnTop,
            ),
          );
          buttonIndex++;
        }

        // Fullscreen button (desktop only)
        if (isDesktop) {
          final currentIndex = buttonIndex;
          buttons.add(
            _buildTrackButton(
              buttonIndex: currentIndex,
              icon: isFullscreen ? Symbols.fullscreen_exit_rounded : Symbols.fullscreen_rounded,
              tooltip: isFullscreen ? t.videoControls.exitFullscreenButton : t.videoControls.fullscreenButton,
              semanticLabel: isFullscreen ? t.videoControls.exitFullscreenButton : t.videoControls.fullscreenButton,
              tracks: tracks,
              isMobile: isMobile,
              isDesktop: isDesktop,
              onPressed: onToggleFullscreen,
            ),
          );
        }

        return IntrinsicHeight(
          child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: buttons),
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
    if (onTogglePIPMode != null) count++;
    if (onCycleBoxFitMode != null) count++;
    if (isMobile && !PlatformDetector.isTV()) count++; // Rotation lock (not on TV)
    if (isDesktop && onToggleAlwaysOnTop != null) count++; // Always on top
    if (isDesktop) count++; // Fullscreen
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
        return Symbols.fit_screen_rounded; // contain (letterbox)
      case 1:
        return Symbols.aspect_ratio_rounded; // cover (fill screen)
      case 2:
        return Symbols.settings_overscan_rounded; // fill (stretch)
      default:
        return Symbols.fit_screen_rounded;
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
