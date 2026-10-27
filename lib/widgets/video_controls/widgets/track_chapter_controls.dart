import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/services.dart';

import '../../../focus/dpad_navigator.dart';
import '../../../mpv/mpv.dart';
import '../../../models/motion_clarity.dart';
import '../../../models/player_setting_scope.dart';
import '../../../services/motion_clarity_service.dart';
import '../../../services/scoped_player_prefs.dart';
import '../../../services/settings_service.dart';
import '../../../media/media_source_info.dart';
import '../../../services/sleep_timer_service.dart';
import '../../../utils/platform_detector.dart';
import '../../../utils/quality_preset_labels.dart';
import '../../../i18n/strings.g.dart';
import '../../../widgets/overlay_sheet.dart';
import '../models/track_controls_state.dart';
import '../sheets/chapter_sheet.dart';
import '../sheets/queue_sheet.dart';
import '../sheets/track_sheet.dart';
import '../sheets/video_settings_sheet.dart';
import '../../../utils/track_label_builder.dart';
import '../video_control_button.dart';

/// Row of track and chapter control buttons for the video player
class TrackChapterControls extends StatelessWidget {
  static final Expando<bool> _motionToggleInFlight = Expando<bool>('motion-clarity-toggle');
  final Player player;
  final List<MediaChapter> chapters;
  final bool chaptersLoaded;
  final TrackControlsState trackControlsState;
  final Future<void> Function(Duration position)? onSeekRequested;
  final Function(Duration position)? onSeekCompleted;

  /// List of FocusNodes for the buttons (passed from parent for navigation)
  final List<FocusNode>? focusNodes;

  /// Called when focus changes on any button
  final ValueChanged<bool>? onFocusChange;

  final VoidCallback? onNavigateLeft;

  /// Called to navigate up from any button (e.g., to focus timeline on TV)
  final VoidCallback? onNavigateUp;

  /// Called to navigate down from any button (e.g., to show content strip on TV)
  final VoidCallback? onNavigateDown;

  /// Whether to hide the chapters and queue buttons (mobile uses content strip instead)
  final bool hideChaptersAndQueue;

  const TrackChapterControls({
    super.key,
    required this.player,
    required this.chapters,
    required this.chaptersLoaded,
    required this.trackControlsState,
    this.onSeekRequested,
    this.onSeekCompleted,
    this.focusNodes,
    this.onFocusChange,
    this.onNavigateLeft,
    this.onNavigateUp,
    this.onNavigateDown,
    this.hideChaptersAndQueue = false,
  });

  KeyEventResult _handleButtonKeyEvent(FocusNode _, KeyEvent event, int index, int totalButtons) {
    if (!event.isActionable) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

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

    if (key == LogicalKeyboardKey.arrowRight) {
      if (index < totalButtons - 1 && focusNodes != null && focusNodes!.length > index + 1) {
        focusNodes![index + 1].requestFocus();
        return KeyEventResult.handled;
      }
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      onNavigateUp?.call();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      onNavigateDown?.call();
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
    // The row being built. Arrow-key navigation reads its length lazily, so
    // by event time it reflects every button that build() actually added.
    required List<Widget> buttons,
    String? tooltip,
    String? semanticValue,
    bool? checked,
    bool isActive = false,
    VoidCallback? onLongPress,
  }) {
    return VideoControlButton(
      icon: icon,
      tooltip: tooltip,
      semanticLabel: semanticLabel,
      semanticValue: semanticValue,
      checked: checked,
      isActive: isActive,
      focusNode: focusNodes != null && focusNodes!.length > buttonIndex ? focusNodes![buttonIndex] : null,
      onKeyEvent: focusNodes != null
          ? (node, event) => _handleButtonKeyEvent(node, event, buttonIndex, buttons.length)
          : null,
      onFocusChange: onFocusChange,
      onPressed: onPressed,
      onLongPress: onLongPress,
    );
  }


  void _openMotionClaritySheet(BuildContext context) {
    final state = trackControlsState;
    state.onCancelAutoHide?.call();
    OverlaySheetController.of(context)
        .show(
          builder: (_) => VideoSettingsSheet(
            player: player,
            trackControlsState: state,
            openMotionClarity: true,
          ),
        )
        .whenComplete(() => state.onStartAutoHide?.call());
  }

  Future<void> _toggleMotionClarity(BuildContext context) async {
    final state = trackControlsState;
    final service = MotionClarityService.forPlayer(player);
    final metadata = state.metadata;
    if (_motionToggleInFlight[player] == true) return;
    _motionToggleInFlight[player] = true;

    try {
      final status = await service.inspect();
      if (!context.mounted) return;
      if (!status.isSupported) {
        _openMotionClaritySheet(context);
        return;
      }

      final currentPreset = service.currentPreset;
      if (currentPreset.interpolationEnabled && status.isComparisonBypass) {
        final result = await service.setComparisonBypass(false);
        if (context.mounted && result.isComparisonBypass) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.videoSettings.motionClarityCompareFailed)),
          );
        }
        return;
      }

      final scope = SettingsService.instance.read(SettingsService.motionClarityScope);
      final sessionOnly = scope == PlayerSettingScope.off;
      final manualKernel = sessionOnly
          ? service.currentKernel
          : ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.motionClarityKernel, metadata);
      final manualThreshold = sessionOnly
          ? service.currentThresholdPercent
          : ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.motionClarityThreshold, metadata);
      final engine = sessionOnly
          ? service.currentEngine
          : ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.motionClarityEngine, metadata);
      final outputRate = sessionOnly
          ? service.currentOutputRate
          : ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.motionClarityOutputRate, metadata);
      final quality = sessionOnly
          ? service.currentMciQuality
          : ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.motionClarityMciQuality, metadata);
      final lastPreset = sessionOnly
          ? service.lastEnabledPreset
          : ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.motionClarityLastPreset, metadata);
      final targetPreset = currentPreset.interpolationEnabled
          ? MotionClarityPreset.original
          : lastPreset.interpolationEnabled
              ? lastPreset
              : MotionClarityPreset.balanced;
      final keepManualControls =
          targetPreset == MotionClarityPreset.custom || targetPreset == MotionClarityPreset.original;
      final kernel = keepManualControls ? manualKernel : targetPreset.defaultKernel;
      final threshold = keepManualControls ? manualThreshold : targetPreset.defaultThresholdPercent;

      final result = await service.configure(
        preset: targetPreset,
        kernel: kernel,
        thresholdPercent: threshold,
        beforeSourceOpen: false,
        engine: engine,
        outputRate: outputRate,
        mciQuality: quality,
      );
      if (!context.mounted) return;
      if (!result.isSupported || (targetPreset.interpolationEnabled && !result.isConfigured)) {
        _openMotionClaritySheet(context);
        return;
      }

      try {
        if (currentPreset.interpolationEnabled) {
          await ScopedPlayerPrefs.write(ScopedPlayerPrefs.motionClarityLastPreset, metadata, currentPreset);
        } else if (targetPreset.interpolationEnabled) {
          await ScopedPlayerPrefs.write(ScopedPlayerPrefs.motionClarityLastPreset, metadata, targetPreset);
        }
        await ScopedPlayerPrefs.write(ScopedPlayerPrefs.motionClarityPreset, metadata, targetPreset);
      } catch (_) {
        final restoreKernel =
            currentPreset == MotionClarityPreset.custom ? manualKernel : currentPreset.defaultKernel;
        final restoreThreshold = currentPreset == MotionClarityPreset.custom
            ? manualThreshold
            : currentPreset.defaultThresholdPercent;
        await service.configure(
          preset: currentPreset,
          kernel: restoreKernel,
          thresholdPercent: restoreThreshold,
          beforeSourceOpen: false,
          engine: engine,
          outputRate: outputRate,
          mciQuality: quality,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.videoSettings.motionClaritySaveFailed)),
          );
        }
        return;
      }

      if (result.requiresSourceReload && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.videoSettings.motionClarityRestartRequired)),
        );
      } else if (targetPreset.interpolationEnabled &&
          (targetPreset == MotionClarityPreset.oled || engine == MotionClarityEngine.motionCompensated) &&
          result.effectiveEngine != MotionClarityEngine.motionCompensated) {
        _openMotionClaritySheet(context);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.videoSettings.motionClaritySaveFailed)),
        );
      }
    } finally {
      _motionToggleInFlight[player] = false;
      if (context.mounted) state.onMotionClarityChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Tracks>(
      stream: player.streams.tracks,
      initialData: player.state.tracks,
      builder: (context, snapshot) {
        final tracks = snapshot.data;
        final state = trackControlsState;
        final isMobile = PlatformDetector.isMobile(context);
        final isDesktop = PlatformDetector.isDesktopOS();

        final buttons = <Widget>[];
        int buttonIndex = 0;

        buttons.add(
          ListenableBuilder(
            listenable: SleepTimerService(),
            builder: (context, _) {
              final sleepTimer = SleepTimerService();
              final shaderService = state.shaderService;
              final isShaderActive =
                  shaderService != null && shaderService.isSupported && shaderService.currentPreset.isEnabled;
              final isZoomActive = (state.videoZoomScale - 1.0).abs() > 0.0001;
              final isMotionActive =
                  player.playerType == 'mpv' &&
                  ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.motionClarityPreset, state.metadata) !=
                      MotionClarityPreset.original;
              final isActive =
                  sleepTimer.isActive ||
                  state.audioSyncOffset != 0 ||
                  state.subtitleSyncOffset != 0 ||
                  isShaderActive ||
                  isZoomActive ||
                  isMotionActive;
              return _buildTrackButton(
                buttonIndex: 0,
                icon: Symbols.tune_rounded,
                isActive: isActive,
                checked: isActive,
                tooltip: t.videoControls.settingsButton,
                semanticValue: _versionQualitySemanticValue(),
                semanticLabel: t.videoControls.settingsButton,
                buttons: buttons,
                onPressed: () {
                  state.onCancelAutoHide?.call();
                  OverlaySheetController.of(context)
                      .show(
                        builder: (_) => VideoSettingsSheet(player: player, trackControlsState: state),
                      )
                      .whenComplete(() => state.onStartAutoHide?.call());
                },
              );
            },
          ),
        );
        buttonIndex++;

        if (player.playerType == 'mpv' && !isMobile) {
          final currentIndex = buttonIndex;
          final motionService = MotionClarityService.forPlayer(player);
          final isMotionActive = motionService.isMotionProcessingActive;
          buttons.add(
            _buildTrackButton(
              buttonIndex: currentIndex,
              icon: Symbols.blur_on_rounded,
              isActive: isMotionActive,
              checked: isMotionActive,
              tooltip: isMotionActive
                  ? t.videoSettings.motionClarityQuickToggleOn
                  : t.videoSettings.motionClarityQuickToggleOff,
              semanticLabel: t.videoSettings.motionClarityQuickToggle,
              buttons: buttons,
              onPressed: () => unawaited(_toggleMotionClarity(context)),
              onLongPress: () => _openMotionClaritySheet(context),
            ),
          );
          buttonIndex++;
        }

        {
          final currentIndex = buttonIndex;
          buttons.add(
            StreamBuilder<TrackSelection>(
              stream: player.streams.track,
              initialData: player.state.track,
              builder: (context, selectionSnapshot) {
                final selection = selectionSnapshot.data ?? player.state.track;
                final hasSubtitleControls = state.hasSubtitleControls(tracks);
                final selectedSub = selection.subtitle;
                final hasActiveSubtitle = selectedSub != null && selectedSub.id != SubtitleTrack.off.id;
                final isHidden = hasSubtitleControls && hasActiveSubtitle && !state.subtitlesVisible;
                final icon = hasSubtitleControls
                    ? (isHidden ? Symbols.subtitles_off_rounded : Symbols.subtitles_rounded)
                    : Symbols.audiotrack_rounded;
                return _buildTrackButton(
                  buttonIndex: currentIndex,
                  icon: icon,
                  tooltip: t.videoControls.tracksButton,
                  semanticLabel: t.videoControls.tracksButton,
                  semanticValue: _selectionSemanticValue(tracks, selection),
                  buttons: buttons,
                  onPressed: () {
                    state.onCancelAutoHide?.call();
                    OverlaySheetController.of(context)
                        .show(
                          builder: (_) => TrackSheet(player: player, trackControlsState: state),
                        )
                        .whenComplete(() => state.onStartAutoHide?.call());
                  },
                );
              },
            ),
          );
          buttonIndex++;
        }

        if (chapters.isNotEmpty && !hideChaptersAndQueue) {
          final currentIndex = buttonIndex;
          buttons.add(
            _buildTrackButton(
              buttonIndex: currentIndex,
              icon: Symbols.bookmarks_rounded,
              tooltip: t.videoControls.chaptersButton,
              semanticLabel: t.videoControls.chaptersButton,
              buttons: buttons,
              onPressed: () {
                state.onCancelAutoHide?.call();
                OverlaySheetController.of(context)
                    .show(
                      builder: (_) => ChapterSheet(
                        player: player,
                        chapters: chapters,
                        chaptersLoaded: chaptersLoaded,
                        canControl: state.canControl,
                        serverId: state.serverId,
                        onSeekRequested: onSeekRequested,
                        onSeekCompleted: onSeekCompleted,
                      ),
                    )
                    .whenComplete(() => state.onStartAutoHide?.call());
              },
            ),
          );
          buttonIndex++;
        }

        if (state.showQueueButton && state.onQueueItemSelected != null && !hideChaptersAndQueue) {
          final currentIndex = buttonIndex;
          buttons.add(
            _buildTrackButton(
              buttonIndex: currentIndex,
              icon: Symbols.queue_rounded,
              tooltip: t.videoControls.queue,
              semanticLabel: t.videoControls.queue,
              buttons: buttons,
              onPressed: () {
                state.onCancelAutoHide?.call();
                OverlaySheetController.of(context)
                    .show(builder: (_) => QueueSheet(onItemSelected: state.onQueueItemSelected!))
                    .whenComplete(() => state.onStartAutoHide?.call());
              },
            ),
          );
          buttonIndex++;
        }

        if (state.onTogglePIPMode != null) {
          final currentIndex = buttonIndex;
          buttons.add(
            _buildTrackButton(
              buttonIndex: currentIndex,
              icon: Symbols.picture_in_picture_alt_rounded,
              tooltip: state.pipActionLabel ?? t.videoControls.openMiniPlayer,
              semanticLabel: state.pipActionLabel ?? t.videoControls.openMiniPlayer,
              buttons: buttons,
              onPressed: state.onTogglePIPMode,
            ),
          );
          buttonIndex++;
        }

        // BoxFit mode button
        if (state.onCycleBoxFitMode != null) {
          final currentIndex = buttonIndex;
          buttons.add(
            _buildTrackButton(
              buttonIndex: currentIndex,
              icon: _getBoxFitIcon(state.boxFitMode),
              tooltip: _getBoxFitTooltip(state.boxFitMode),
              semanticLabel: t.videoControls.aspectRatioButton,
              semanticValue: _getBoxFitTooltip(state.boxFitMode),
              buttons: buttons,
              onPressed: state.onCycleBoxFitMode,
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
              icon: state.isRotationLocked ? Symbols.screen_lock_rotation_rounded : Symbols.screen_rotation_rounded,
              tooltip: state.isRotationLocked ? t.videoControls.unlockRotation : t.videoControls.lockRotation,
              semanticLabel: t.videoControls.rotationLockButton,
              checked: state.isRotationLocked,
              buttons: buttons,
              onPressed: state.onToggleRotationLock,
            ),
          );
          buttonIndex++;
        }

        // Screen lock button (mobile only, not on TV)
        if (isMobile && !PlatformDetector.isTV()) {
          final currentIndex = buttonIndex;
          buttons.add(
            _buildTrackButton(
              buttonIndex: currentIndex,
              icon: Symbols.lock_rounded,
              tooltip: t.videoControls.lockScreen,
              semanticLabel: t.videoControls.screenLockButton,
              buttons: buttons,
              onPressed: state.onToggleScreenLock,
            ),
          );
          buttonIndex++;
        }

        // Always on top button (desktop only, not TV)
        if (isDesktop && state.onToggleAlwaysOnTop != null) {
          final currentIndex = buttonIndex;
          buttons.add(
            _buildTrackButton(
              buttonIndex: currentIndex,
              icon: Symbols.layers_rounded,
              tooltip: t.videoControls.alwaysOnTopButton,
              semanticLabel: t.videoControls.alwaysOnTopButton,
              isActive: state.isAlwaysOnTop,
              checked: state.isAlwaysOnTop,
              buttons: buttons,
              onPressed: state.onToggleAlwaysOnTop,
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
              icon: state.isFullscreen ? Symbols.fullscreen_exit_rounded : Symbols.fullscreen_rounded,
              tooltip: state.isFullscreen ? t.videoControls.exitFullscreenButton : t.videoControls.fullscreenButton,
              semanticLabel: state.isFullscreen
                  ? t.videoControls.exitFullscreenButton
                  : t.videoControls.fullscreenButton,
              checked: state.isFullscreen,
              buttons: buttons,
              onPressed: state.onToggleFullscreen,
            ),
          );
        }

        return IntrinsicHeight(
          child: Row(mainAxisSize: .min, crossAxisAlignment: .stretch, children: buttons),
        );
      },
    );
  }

  String? _versionQualitySemanticValue() {
    final state = trackControlsState;
    final values = <String>[];
    if (state.availableVersions.length > 1) {
      final index = state.selectedMediaIndex;
      if (index >= 0 && index < state.availableVersions.length) {
        values.add(state.availableVersions[index].displayLabel);
      }
    }
    if (state.serverSupportsTranscoding) {
      values.add(qualityPresetLabel(state.selectedQualityPreset));
    }
    return values.isEmpty ? null : values.join(' / ');
  }

  String? _selectionSemanticValue(Tracks? tracks, TrackSelection selection) {
    final values = <String>[];
    final audio = selection.audio;
    if (audio != null && audio.id != AudioTrack.off.id) {
      final index = tracks?.audio.indexWhere((track) => track.id == audio.id) ?? -1;
      final visibleIndex = index < 0 ? 0 : index;
      final label = TrackLabelBuilder.audioLabel(
        title: audio.title,
        language: audio.language,
        codec: audio.codec,
        codecProfile: audio.codecProfile,
        channels: audio.channelsCount,
        index: visibleIndex,
      );
      values.add(label.joined);
    }

    final subtitle = selection.subtitle;
    if (subtitle != null && subtitle.id != SubtitleTrack.off.id) {
      final index = tracks?.subtitle.indexWhere((track) => track.id == subtitle.id) ?? -1;
      values.add(
        TrackLabelBuilder.subtitleLabel(
          title: subtitle.title,
          language: subtitle.language,
          codec: subtitle.codec,
          forced: subtitle.isForced,
          index: index < 0 ? 0 : index,
        ).joined,
      );
    }

    return values.isEmpty ? null : values.join(', ');
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
