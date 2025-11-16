import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_window_utils/macos_window_utils.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import '../../models/plex_media_info.dart';
import '../../models/plex_media_version.dart';
import '../../models/plex_metadata.dart';
import '../../screens/video_player_screen.dart';
import '../../services/fullscreen_state_manager.dart';
import '../../services/keyboard_shortcuts_service.dart';
import '../../services/settings_service.dart';
import '../../services/sleep_timer_service.dart';
import '../../utils/desktop_window_padding.dart';
import '../../utils/platform_detector.dart';
import '../../utils/provider_extensions.dart';
import '../../i18n/strings.g.dart';
import '../app_bar_back_button.dart';
import 'painters/chapter_marker_painter.dart';
import 'sheets/audio_track_sheet.dart';
import 'sheets/chapter_sheet.dart';
import 'sheets/subtitle_track_sheet.dart';
import 'sheets/version_sheet.dart';
import 'sheets/video_settings_sheet.dart';
import 'video_control_button.dart';

/// Custom video controls builder for Plex with chapter, audio, and subtitle support
Widget plexVideoControlsBuilder(
  Player player,
  PlexMetadata metadata, {
  VoidCallback? onNext,
  VoidCallback? onPrevious,
  List<PlexMediaVersion>? availableVersions,
  int? selectedMediaIndex,
  int boxFitMode = 0,
  VoidCallback? onCycleBoxFitMode,
  Function(AudioTrack)? onAudioTrackChanged,
  Function(SubtitleTrack)? onSubtitleTrackChanged,
}) {
  return PlexVideoControls(
    player: player,
    metadata: metadata,
    onNext: onNext,
    onPrevious: onPrevious,
    availableVersions: availableVersions ?? [],
    selectedMediaIndex: selectedMediaIndex ?? 0,
    boxFitMode: boxFitMode,
    onCycleBoxFitMode: onCycleBoxFitMode,
    onAudioTrackChanged: onAudioTrackChanged,
    onSubtitleTrackChanged: onSubtitleTrackChanged,
  );
}

class PlexVideoControls extends StatefulWidget {
  final Player player;
  final PlexMetadata metadata;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final List<PlexMediaVersion> availableVersions;
  final int selectedMediaIndex;
  final int boxFitMode;
  final VoidCallback? onCycleBoxFitMode;
  final Function(AudioTrack)? onAudioTrackChanged;
  final Function(SubtitleTrack)? onSubtitleTrackChanged;

  const PlexVideoControls({
    super.key,
    required this.player,
    required this.metadata,
    this.onNext,
    this.onPrevious,
    this.availableVersions = const [],
    this.selectedMediaIndex = 0,
    this.boxFitMode = 0,
    this.onCycleBoxFitMode,
    this.onAudioTrackChanged,
    this.onSubtitleTrackChanged,
  });

  @override
  State<PlexVideoControls> createState() => _PlexVideoControlsState();
}

class _PlexVideoControlsState extends State<PlexVideoControls>
    with WindowListener, WidgetsBindingObserver {
  bool _showControls = true;
  List<PlexChapter> _chapters = [];
  bool _chaptersLoaded = false;
  Timer? _hideTimer;
  bool _isFullscreen = false;
  late final FocusNode _focusNode;
  KeyboardShortcutsService? _keyboardService;
  int _seekTimeSmall = 10; // Default, loaded from settings
  int _audioSyncOffset = 0; // Default, loaded from settings
  int _subtitleSyncOffset = 0; // Default, loaded from settings
  bool _isRotationLocked = true; // Default locked (landscape only)
  // Double-tap feedback state
  bool _showDoubleTapFeedback = false;
  double _doubleTapFeedbackOpacity = 0.0;
  bool _lastDoubleTapWasForward = true;
  Timer? _feedbackTimer;
  // Seek throttle state
  Timer? _seekThrottleTimer;
  Duration? _pendingSeekPosition;
  // Current marker state
  PlexMarker? _currentMarker;
  List<PlexMarker> _markers = [];
  bool _markersLoaded = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _loadChapters();
    _loadMarkers();
    _loadSeekTimes();
    _startHideTimer();
    _initKeyboardService();
    _listenToPosition();
    // Add lifecycle observer to reload settings when app resumes
    WidgetsBinding.instance.addObserver(this);
    // Add window listener for tracking fullscreen state (for button icon)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.addListener(this);
    }
  }

  Future<void> _initKeyboardService() async {
    _keyboardService = await KeyboardShortcutsService.getInstance();
  }

  void _listenToPosition() {
    widget.player.stream.position.listen((position) {
      if (_markers.isEmpty || !_markersLoaded) {
        return;
      }

      PlexMarker? foundMarker;
      for (final marker in _markers) {
        if (marker.containsPosition(position)) {
          foundMarker = marker;
          break;
        }
      }

      if (foundMarker != _currentMarker) {
        if (mounted) {
          setState(() {
            _currentMarker = foundMarker;
          });
        }
      }
    });
  }

  void _skipMarker() {
    if (_currentMarker != null) {
      widget.player.seek(_currentMarker!.endTime);
    }
  }

  Future<void> _loadSeekTimes() async {
    final settingsService = await SettingsService.getInstance();
    if (mounted) {
      setState(() {
        _seekTimeSmall = settingsService.getSeekTimeSmall();
        _audioSyncOffset = settingsService.getAudioSyncOffset();
        _subtitleSyncOffset = settingsService.getSubtitleSyncOffset();
        _isRotationLocked = settingsService.getRotationLocked();
      });

      // Apply rotation lock setting
      if (_isRotationLocked) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      }
    }
  }

  void _toggleSubtitles() {
    // Toggle subtitle visibility - this would need to be implemented based on your subtitle system
    // For now, this is a placeholder
  }

  void _nextAudioTrack() {
    // Switch to next audio track - this would need to be implemented based on your track system
    // For now, this is a placeholder
  }

  void _nextSubtitleTrack() {
    // Switch to next subtitle track - this would need to be implemented based on your subtitle system
    // For now, this is a placeholder
  }

  void _nextChapter() {
    // Go to next chapter - this would use your existing chapter navigation
    if (widget.onNext != null) {
      widget.onNext!();
    }
  }

  void _previousChapter() {
    // Go to previous chapter - this would use your existing chapter navigation
    if (widget.onPrevious != null) {
      widget.onPrevious!();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _feedbackTimer?.cancel();
    _seekThrottleTimer?.cancel();
    _focusNode.dispose();
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    // Remove window listener
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload seek times when app resumes (e.g., returning from settings)
      _loadSeekTimes();
    }
  }

  @override
  void onWindowEnterFullScreen() {
    if (mounted) {
      setState(() {
        _isFullscreen = true;
      });
    }
  }

  @override
  void onWindowLeaveFullScreen() {
    if (mounted) {
      setState(() {
        _isFullscreen = false;
      });
    }
  }

  @override
  void onWindowMaximize() {
    // On macOS, maximize is the same as fullscreen (green button)
    if (mounted && Platform.isMacOS) {
      setState(() {
        _isFullscreen = true;
      });
    }
  }

  @override
  void onWindowUnmaximize() {
    // On macOS, unmaximize means exiting fullscreen
    if (mounted && Platform.isMacOS) {
      setState(() {
        _isFullscreen = false;
      });
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    // Only auto-hide if playing
    if (widget.player.state.playing) {
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && widget.player.state.playing) {
          setState(() {
            _showControls = false;
          });
          // Hide traffic lights on macOS when controls auto-hide
          if (Platform.isMacOS) {
            _updateTrafficLightVisibility();
          }
        }
      });
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    }

    // On macOS, hide/show traffic lights with controls
    if (Platform.isMacOS) {
      _updateTrafficLightVisibility();
    }
  }

  void _toggleRotationLock() async {
    setState(() {
      _isRotationLocked = !_isRotationLocked;
    });

    // Save to settings
    final settingsService = await SettingsService.getInstance();
    await settingsService.setRotationLocked(_isRotationLocked);

    if (_isRotationLocked) {
      // Locked: Allow landscape orientations only
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Unlocked: Allow all orientations including portrait
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
  }

  void _updateTrafficLightVisibility() async {
    if (Platform.isMacOS) {
      if (_showControls) {
        await WindowManipulator.showCloseButton();
        await WindowManipulator.showMiniaturizeButton();
        await WindowManipulator.showZoomButton();
      } else {
        await WindowManipulator.hideCloseButton();
        await WindowManipulator.hideMiniaturizeButton();
        await WindowManipulator.hideZoomButton();
      }
    }
  }

  Future<void> _loadChapters() async {
    final clientProvider = context.plexClient;
    final client = clientProvider.client;
    if (client == null) return;

    final chapters = await client.getChapters(widget.metadata.ratingKey);
    if (mounted) {
      setState(() {
        _chapters = chapters;
        _chaptersLoaded = true;
      });
    }
  }

  Future<void> _loadMarkers() async {
    final clientProvider = context.plexClient;
    final client = clientProvider.client;
    if (client == null) return;

    final markers = await client.getMarkers(widget.metadata.ratingKey);

    if (mounted) {
      setState(() {
        _markers = markers;
        _markersLoaded = true;
      });
    }
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

  /// Conditionally wraps child with SafeArea only in portrait mode
  Widget _conditionalSafeArea({
    required Widget child,
    bool top = true,
    bool bottom = true,
  }) {
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;

    // Only apply SafeArea in portrait mode
    if (isPortrait) {
      return SafeArea(top: top, bottom: bottom, child: child);
    }

    // In landscape, return child without SafeArea
    return child;
  }

  Widget _buildTrackAndChapterControls() {
    return StreamBuilder<Tracks>(
      stream: widget.player.stream.tracks,
      initialData: widget.player.state.tracks,
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
                      _audioSyncOffset != 0 ||
                      _subtitleSyncOffset != 0;
                  return VideoControlButton(
                    icon: Icons.tune,
                    isActive: isActive,
                    onPressed: () async {
                      await VideoSettingsSheet.show(
                        context,
                        widget.player,
                        _audioSyncOffset,
                        _subtitleSyncOffset,
                      );
                      // Sheet is now closed, reload immediately
                      if (mounted) {
                        await _loadSeekTimes();
                      }
                    },
                  );
                },
              ),
              if (_hasMultipleAudioTracks(tracks))
                VideoControlButton(
                  icon: Icons.audiotrack,
                  onPressed: () => AudioTrackSheet.show(
                    context,
                    widget.player,
                    onTrackChanged: widget.onAudioTrackChanged,
                  ),
                ),
              if (_hasSubtitles(tracks))
                VideoControlButton(
                  icon: Icons.subtitles,
                  onPressed: () => SubtitleTrackSheet.show(
                    context,
                    widget.player,
                    onTrackChanged: widget.onSubtitleTrackChanged,
                  ),
                ),
              if (_chapters.isNotEmpty)
                VideoControlButton(
                  icon: Icons.video_library,
                  onPressed: () => ChapterSheet.show(
                    context,
                    widget.player,
                    _chapters,
                    _chaptersLoaded,
                  ),
                ),
              if (widget.availableVersions.length > 1)
                VideoControlButton(
                  icon: Icons.video_file,
                  onPressed: () => VersionSheet.show(
                    context,
                    widget.availableVersions,
                    widget.selectedMediaIndex,
                    _switchMediaVersion,
                  ),
                ),
              // BoxFit mode cycle button
              if (widget.onCycleBoxFitMode != null)
                VideoControlButton(
                  icon: _getBoxFitIcon(widget.boxFitMode),
                  tooltip: _getBoxFitTooltip(widget.boxFitMode),
                  onPressed: widget.onCycleBoxFitMode,
                ),
              // Rotation lock toggle (mobile only)
              if (PlatformDetector.isMobile(context))
                VideoControlButton(
                  icon: _isRotationLocked
                      ? Icons.screen_lock_rotation
                      : Icons.screen_rotation,
                  tooltip: _isRotationLocked
                      ? t.videoControls.unlockRotation
                      : t.videoControls.lockRotation,
                  onPressed: _toggleRotationLock,
                ),
              // Fullscreen toggle (desktop only)
              if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
                VideoControlButton(
                  icon: _isFullscreen
                      ? Icons.fullscreen_exit
                      : Icons.fullscreen,
                  onPressed: _toggleFullscreen,
                ),
            ],
          ),
        );
      },
    );
  }

  void _seekToPreviousChapter() {
    if (_chapters.isEmpty) {
      // No chapters - seek backward by configured amount
      _seekWithClamping(Duration(seconds: -_seekTimeSmall));
      return;
    }

    final currentPosition = widget.player.state.position.inMilliseconds;

    // Find current chapter
    for (int i = _chapters.length - 1; i >= 0; i--) {
      final chapterStart = _chapters[i].startTimeOffset ?? 0;
      if (currentPosition > chapterStart + 3000) {
        // If more than 3 seconds into chapter, go to start of current chapter
        widget.player.seek(Duration(milliseconds: chapterStart));
        return;
      }
    }

    // If at start of first chapter, go to beginning
    widget.player.seek(Duration.zero);
  }

  void _seekToNextChapter() {
    if (_chapters.isEmpty) {
      // No chapters - seek forward by configured amount
      _seekWithClamping(Duration(seconds: _seekTimeSmall));
      return;
    }

    final currentPosition = widget.player.state.position.inMilliseconds;

    // Find next chapter
    for (int i = 0; i < _chapters.length; i++) {
      final chapterStart = _chapters[i].startTimeOffset ?? 0;
      if (chapterStart > currentPosition) {
        widget.player.seek(Duration(milliseconds: chapterStart));
        return;
      }
    }
  }

  /// Seeks by the given offset (can be positive or negative) while clamping
  /// the result between 0 and the video duration
  void _seekWithClamping(Duration offset) {
    final currentPosition = widget.player.state.position;
    final duration = widget.player.state.duration;
    final newPosition = currentPosition + offset;

    // Clamp between 0 and video duration
    final clampedPosition = newPosition.isNegative
        ? Duration.zero
        : (newPosition > duration ? duration : newPosition);

    widget.player.seek(clampedPosition);
  }

  /// Throttled seek for timeline slider - only sends seek events at most every 100ms
  void _throttledSeek(Duration position) {
    // Store the pending position
    _pendingSeekPosition = position;

    // If timer is already active, just update the pending position
    if (_seekThrottleTimer?.isActive ?? false) {
      return;
    }

    // Execute the seek immediately for the first call
    widget.player.seek(position);

    // Start a timer to throttle subsequent seeks
    _seekThrottleTimer = Timer(const Duration(milliseconds: 200), () {
      // If there's a pending position that's different, execute it
      if (_pendingSeekPosition != null && _pendingSeekPosition != position) {
        widget.player.seek(_pendingSeekPosition!);
      }
      _pendingSeekPosition = null;
    });
  }

  /// Finalizes the seek when user stops scrubbing the timeline
  void _finalizeSeek(Duration position) {
    // Cancel any pending throttled seek
    _seekThrottleTimer?.cancel();
    _seekThrottleTimer = null;

    // Execute the final position immediately to ensure accuracy
    widget.player.seek(position);
    _pendingSeekPosition = null;
  }

  /// Get the replay icon based on the duration
  /// Returns numbered icons (replay_5, replay_10, replay_30) when available,
  /// otherwise returns generic replay icon
  IconData _getReplayIcon(int seconds) {
    switch (seconds) {
      case 5:
        return Icons.replay_5;
      case 10:
        return Icons.replay_10;
      case 30:
        return Icons.replay_30;
      default:
        return Icons.replay; // Generic icon for custom durations
    }
  }

  /// Get the forward icon based on the duration
  /// Returns numbered icons (forward_5, forward_10, forward_30) when available,
  /// otherwise returns generic forward icon
  IconData _getForwardIcon(int seconds) {
    switch (seconds) {
      case 5:
        return Icons.forward_5;
      case 10:
        return Icons.forward_10;
      case 30:
        return Icons.forward_30;
      default:
        return Icons.forward; // Generic icon for custom durations
    }
  }

  /// Handle double-tap skip forward or backward
  void _handleDoubleTapSkip({required bool isForward}) {
    // Perform the seek
    _seekWithClamping(
      Duration(seconds: isForward ? _seekTimeSmall : -_seekTimeSmall),
    );

    // Show visual feedback
    _showSkipFeedback(isForward: isForward);
  }

  /// Show animated visual feedback for skip gesture
  void _showSkipFeedback({required bool isForward}) {
    _feedbackTimer?.cancel();

    setState(() {
      _lastDoubleTapWasForward = isForward;
      _showDoubleTapFeedback = true;
      _doubleTapFeedbackOpacity = 1.0;
    });

    // Fade out after delay
    _feedbackTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _doubleTapFeedbackOpacity = 0.0;
        });

        Timer(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _showDoubleTapFeedback = false;
            });
          }
        });
      }
    });
  }

  /// Build the visual feedback widget for double-tap skip
  Widget _buildDoubleTapFeedback() {
    return Align(
      alignment: _lastDoubleTapWasForward
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 60),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _lastDoubleTapWasForward
              ? _getForwardIcon(_seekTimeSmall)
              : _getReplayIcon(_seekTimeSmall),
          color: Colors.white,
          size: 48,
        ),
      ),
    );
  }

  Future<void> _toggleFullscreen() async {
    if (!PlatformDetector.isMobile(context)) {
      // Query actual window state to determine what action to take
      // This ensures we always toggle correctly regardless of local state
      final isCurrentlyFullscreen = await windowManager.isFullScreen();

      if (Platform.isMacOS) {
        // Use native macOS fullscreen - titlebar is handled automatically
        // Window listener will update _isFullscreen for UI
        if (isCurrentlyFullscreen) {
          await WindowManipulator.exitFullscreen();
        } else {
          await WindowManipulator.enterFullscreen();
        }
      } else {
        // For Windows/Linux, use window_manager
        // Window listener will update _isFullscreen for UI
        if (isCurrentlyFullscreen) {
          await windowManager.setFullScreen(false);
        } else {
          await windowManager.setFullScreen(true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = PlatformDetector.isMobile(context);

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (_keyboardService == null) return KeyEventResult.ignored;

        return _keyboardService!.handleVideoPlayerKeyEvent(
          event,
          widget.player,
          _toggleFullscreen,
          _toggleSubtitles,
          _nextAudioTrack,
          _nextSubtitleTrack,
          _nextChapter,
          _previousChapter,
        );
      },
      child: MouseRegion(
        cursor: _showControls
            ? SystemMouseCursors.basic
            : SystemMouseCursors.none,
        onHover: (_) {
          // Show controls when mouse moves
          if (!_showControls) {
            setState(() {
              _showControls = true;
            });
            _startHideTimer();
            // On macOS, show traffic lights when controls appear
            if (Platform.isMacOS) {
              _updateTrafficLightVisibility();
            }
          }
        },
        child: Stack(
          children: [
            // Invisible tap detector that always covers the full area
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleControls,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),
            // Custom controls overlay - use AnimatedOpacity to keep widget tree alive
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_showControls,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTap: _toggleControls,
                    behavior: HitTestBehavior.deferToChild,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                          stops: const [0.0, 0.2, 0.8, 1.0],
                        ),
                      ),
                      child: isMobile
                          ? _buildMobileLayout()
                          : _buildDesktopLayout(),
                    ),
                  ),
                ),
              ),
            ),
            // Middle area double-tap detector for fullscreen (desktop only)
            // Only covers the clear video area (20% to 80% vertically)
            if (!isMobile)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final height = constraints.maxHeight;
                    final topExclude = height * 0.20; // Top 20%
                    final bottomExclude = height * 0.20; // Bottom 20%

                    return Stack(
                      children: [
                        Positioned(
                          top: topExclude,
                          left: 0,
                          right: 0,
                          bottom: bottomExclude,
                          child: GestureDetector(
                            onTap: _toggleControls,
                            onDoubleTap: _toggleFullscreen,
                            behavior: HitTestBehavior.translucent,
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            // Mobile double-tap zones for skip forward/backward
            if (isMobile)
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final height = constraints.maxHeight;
                    final width = constraints.maxWidth;
                    final topExclude =
                        height * 0.15; // Exclude top 15% (top bar)
                    final bottomExclude =
                        height * 0.15; // Exclude bottom 15% (seek slider)
                    final leftZoneWidth = width * 0.35; // Left 35%

                    return Stack(
                      children: [
                        // Left zone - skip backward
                        Positioned(
                          left: 0,
                          top: topExclude,
                          bottom: bottomExclude,
                          width: leftZoneWidth,
                          child: GestureDetector(
                            onTap: _toggleControls,
                            onDoubleTap: () =>
                                _handleDoubleTapSkip(isForward: false),
                            behavior: HitTestBehavior.translucent,
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                        // Right zone - skip forward
                        Positioned(
                          right: 0,
                          top: topExclude,
                          bottom: bottomExclude,
                          width: leftZoneWidth,
                          child: GestureDetector(
                            onTap: _toggleControls,
                            onDoubleTap: () =>
                                _handleDoubleTapSkip(isForward: true),
                            behavior: HitTestBehavior.translucent,
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            // Visual feedback overlay for double-tap
            if (isMobile && _showDoubleTapFeedback)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _doubleTapFeedbackOpacity,
                    duration: const Duration(milliseconds: 300),
                    child: _buildDoubleTapFeedback(),
                  ),
                ),
              ),
            // Skip intro/credits button
            if (_currentMarker != null)
              Positioned(
                right: 24,
                bottom: isMobile ? 80 : 115,
                child: AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: _buildSkipMarkerButton(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipMarkerButton() {
    final isCredits = _currentMarker!.isCredits;
    final hasNextEpisode = widget.onNext != null;

    // Show "Next Episode" for credits when next episode is available
    final bool showNextEpisode = isCredits && hasNextEpisode;
    final String buttonText = showNextEpisode
        ? 'Next Episode'
        : (isCredits ? 'Skip Credits' : 'Skip Intro');
    final IconData buttonIcon = showNextEpisode
        ? Icons.skip_next
        : Icons.fast_forward;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: showNextEpisode ? widget.onNext : _skipMarker,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                buttonText,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(buttonIcon, color: Colors.black, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Top bar with back button and track/chapter controls
        _buildMobileTopBar(),
        const Spacer(),
        // Centered large playback controls
        _buildMobilePlaybackControls(),
        const Spacer(),
        // Progress bar at bottom
        _buildMobileBottomBar(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        // Top bar with back button and title
        _buildDesktopTopBar(),
        const Spacer(),
        // Bottom controls
        _buildDesktopBottomControls(),
      ],
    );
  }

  // Mobile layout components
  Widget _buildMobileTopBar() {
    final topBar = _conditionalSafeArea(
      bottom: false, // Only respect top safe area when in portrait
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AppBarBackButton(
              style: BackButtonStyle.video,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.metadata.grandparentTitle ?? widget.metadata.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.metadata.parentIndex != null &&
                      widget.metadata.index != null)
                    Text(
                      'S${widget.metadata.parentIndex} · E${widget.metadata.index} · ${widget.metadata.title}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // Track and chapter controls in top right
            _buildTrackAndChapterControls(),
          ],
        ),
      ),
    );

    // On macOS, wrap with GestureDetector to prevent window dragging
    if (Platform.isMacOS) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanDown: (_) {}, // Consume pan gestures to prevent window dragging
        child: topBar,
      );
    }

    return topBar;
  }

  Widget _buildMobilePlaybackControls() {
    return StreamBuilder<bool>(
      stream: widget.player.stream.playing,
      initialData: widget.player.state.playing,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFocusableIconButton(
              icon: _getReplayIcon(_seekTimeSmall),
              size: 48,
              onPressed: () {
                _seekWithClamping(Duration(seconds: -_seekTimeSmall));
              },
            ),
            const SizedBox(width: 48),
            _buildFocusableIconButton(
              icon: isPlaying ? Icons.pause : Icons.play_arrow,
              size: 72,
              onPressed: () {
                if (isPlaying) {
                  widget.player.pause();
                  _hideTimer?.cancel();
                } else {
                  widget.player.play();
                  _startHideTimer();
                }
              },
            ),
            const SizedBox(width: 48),
            _buildFocusableIconButton(
              icon: _getForwardIcon(_seekTimeSmall),
              size: 48,
              onPressed: () {
                _seekWithClamping(Duration(seconds: _seekTimeSmall));
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFocusableIconButton({
    required IconData icon,
    required double size,
    required VoidCallback onPressed,
  }) {
    final isTV = PlatformDetector.isTVSync();

    return Focus(
      onKeyEvent: (node, event) {
        if (isTV && event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            onPressed();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: isFocused && isTV
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
            ),
            child: IconButton(
              icon: Icon(icon, color: Colors.white, size: size),
              iconSize: size,
              onPressed: onPressed,
              autofocus: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileBottomBar() {
    return _conditionalSafeArea(
      top: false, // Only respect bottom safe area when in portrait
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<Duration>(
          stream: widget.player.stream.position,
          initialData: widget.player.state.position,
          builder: (context, positionSnapshot) {
            return StreamBuilder<Duration>(
              stream: widget.player.stream.duration,
              initialData: widget.player.state.duration,
              builder: (context, durationSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;
                final duration = durationSnapshot.data ?? Duration.zero;

                return Column(
                  children: [
                    _buildTimelineWithChapters(
                      position: position,
                      duration: duration,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Desktop layout components
  Widget _buildDesktopTopBar() {
    // Use global fullscreen state for padding
    return ListenableBuilder(
      listenable: FullscreenStateManager(),
      builder: (context, _) {
        final isFullscreen = FullscreenStateManager().isFullscreen;
        // In fullscreen on macOS, use less left padding since traffic lights auto-hide
        // In normal mode on macOS, need more padding to avoid traffic lights
        final leftPadding = Platform.isMacOS
            ? (isFullscreen
                  ? DesktopWindowPadding.macOSLeftFullscreen
                  : DesktopWindowPadding.macOSLeft)
            : DesktopWindowPadding.macOSLeftFullscreen;

        return _buildDesktopTopBarContent(leftPadding);
      },
    );
  }

  Widget _buildDesktopTopBarContent(double leftPadding) {
    final topBar = Padding(
      padding: EdgeInsets.only(left: leftPadding, right: 16),
      child: Row(
        children: [
          AppBarBackButton(
            style: BackButtonStyle.video,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Platform.isMacOS
                ? _buildMacOSSingleLineTitle()
                : _buildMultiLineTitle(),
          ),
        ],
      ),
    );

    // On macOS, wrap with GestureDetector to prevent window dragging
    if (Platform.isMacOS) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanDown: (_) {}, // Consume pan gestures to prevent window dragging
        child: topBar,
      );
    }

    return topBar;
  }

  Widget _buildMacOSSingleLineTitle() {
    // Build single-line title combining series and episode info
    final seriesName =
        widget.metadata.grandparentTitle ?? widget.metadata.title;
    final hasEpisodeInfo =
        widget.metadata.parentIndex != null && widget.metadata.index != null;

    final titleText = hasEpisodeInfo
        ? '$seriesName · S${widget.metadata.parentIndex} E${widget.metadata.index} · ${widget.metadata.title}'
        : seriesName;

    return Text(
      titleText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMultiLineTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.metadata.grandparentTitle ?? widget.metadata.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (widget.metadata.parentIndex != null &&
            widget.metadata.index != null)
          Text(
            'S${widget.metadata.parentIndex} · E${widget.metadata.index} · ${widget.metadata.title}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildDesktopBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Row 1: Timeline with time indicators
          StreamBuilder<Duration>(
            stream: widget.player.stream.position,
            initialData: widget.player.state.position,
            builder: (context, positionSnapshot) {
              return StreamBuilder<Duration>(
                stream: widget.player.stream.duration,
                initialData: widget.player.state.duration,
                builder: (context, durationSnapshot) {
                  final position = positionSnapshot.data ?? Duration.zero;
                  final duration = durationSnapshot.data ?? Duration.zero;

                  return Row(
                    children: [
                      Text(
                        _formatDuration(position),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTimelineWithChapters(
                          position: position,
                          duration: duration,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 4),
          // Row 2: Playback controls and options
          Row(
            children: [
              // Previous item
              IconButton(
                icon: Icon(
                  Icons.skip_previous,
                  color: widget.onPrevious != null
                      ? Colors.white
                      : Colors.white54,
                ),
                onPressed: widget.onPrevious,
              ),
              // Previous chapter (or skip backward if no chapters)
              IconButton(
                icon: Icon(
                  _chapters.isEmpty
                      ? _getReplayIcon(_seekTimeSmall)
                      : Icons.fast_rewind,
                  color: Colors.white,
                ),
                onPressed: _seekToPreviousChapter,
              ),
              // Play/Pause
              StreamBuilder<bool>(
                stream: widget.player.stream.playing,
                initialData: widget.player.state.playing,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data ?? false;
                  return IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                    iconSize: 32,
                    onPressed: () {
                      if (isPlaying) {
                        widget.player.pause();
                        _hideTimer?.cancel(); // Cancel auto-hide when paused
                      } else {
                        widget.player.play();
                        _startHideTimer(); // Start auto-hide when playing
                      }
                    },
                  );
                },
              ),
              // Next chapter (or skip forward if no chapters)
              IconButton(
                icon: Icon(
                  _chapters.isEmpty
                      ? _getForwardIcon(_seekTimeSmall)
                      : Icons.fast_forward,
                  color: Colors.white,
                ),
                onPressed: _seekToNextChapter,
              ),
              // Next item
              IconButton(
                icon: Icon(
                  Icons.skip_next,
                  color: widget.onNext != null ? Colors.white : Colors.white54,
                ),
                onPressed: widget.onNext,
              ),
              const Spacer(),
              // Volume control
              _buildVolumeControl(),
              const SizedBox(width: 16),
              // Audio track, subtitle, and chapter controls
              _buildTrackAndChapterControls(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineWithChapters({
    required Duration position,
    required Duration duration,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Chapter markers layer
        if (_chaptersLoaded &&
            _chapters.isNotEmpty &&
            duration.inMilliseconds > 0)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children:
                    _chapters.map((chapter) {
                      final chapterPosition =
                          (chapter.startTimeOffset ?? 0) /
                          duration.inMilliseconds;
                      return Expanded(
                        flex: (chapterPosition * 1000).toInt(),
                        child: const SizedBox(),
                      );
                    }).toList()..add(
                      Expanded(
                        flex:
                            1000 -
                            _chapters.fold<int>(
                              0,
                              (sum, chapter) =>
                                  sum +
                                  ((chapter.startTimeOffset ?? 0) /
                                          duration.inMilliseconds *
                                          1000)
                                      .toInt(),
                            ),
                        child: const SizedBox(),
                      ),
                    ),
              ),
            ),
          ),
        // Slider
        Slider(
          value: duration.inMilliseconds > 0
              ? position.inMilliseconds.toDouble()
              : 0.0,
          min: 0.0,
          max: duration.inMilliseconds.toDouble(),
          onChanged: (value) {
            _throttledSeek(Duration(milliseconds: value.toInt()));
          },
          onChangeEnd: (value) {
            _finalizeSeek(Duration(milliseconds: value.toInt()));
          },
          activeColor: Colors.white,
          inactiveColor: Colors.white.withValues(alpha: 0.3),
        ),
        // Chapter marker indicators
        if (_chaptersLoaded &&
            _chapters.isNotEmpty &&
            duration.inMilliseconds > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: CustomPaint(
                  painter: ChapterMarkerPainter(
                    chapters: _chapters,
                    duration: duration,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVolumeControl() {
    return StreamBuilder<double>(
      stream: widget.player.stream.volume,
      initialData: widget.player.state.volume,
      builder: (context, snapshot) {
        final volume = snapshot.data ?? 100.0;
        final isMuted = volume == 0;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isMuted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
              ),
              onPressed: () async {
                final newVolume = isMuted ? 100.0 : 0.0;
                widget.player.setVolume(newVolume);
                final settings = await SettingsService.getInstance();
                await settings.setVolume(newVolume);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 12,
                  ),
                ),
                child: Slider(
                  value: volume,
                  min: 0.0,
                  max: 100.0,
                  onChanged: (value) {
                    widget.player.setVolume(value);
                  },
                  onChangeEnd: (value) async {
                    final settings = await SettingsService.getInstance();
                    await settings.setVolume(value);
                  },
                  activeColor: Colors.white,
                  inactiveColor: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Switch to a different media version
  Future<void> _switchMediaVersion(int newMediaIndex) async {
    if (newMediaIndex == widget.selectedMediaIndex) {
      return; // Already using this version
    }

    try {
      // Save current playback position
      final currentPosition = widget.player.state.position;

      // Get state reference before async operations
      final videoPlayerState = context
          .findAncestorStateOfType<VideoPlayerScreenState>();

      // Save the preference
      final settingsService = await SettingsService.getInstance();
      final seriesKey =
          widget.metadata.grandparentRatingKey ?? widget.metadata.ratingKey;
      await settingsService.setMediaVersionPreference(seriesKey, newMediaIndex);

      // Set flag on parent VideoPlayerScreen to skip orientation restoration
      videoPlayerState?.setReplacingWithVideo();

      // Navigate to new player screen with the selected version
      // Use PageRouteBuilder with zero-duration transitions to prevent orientation reset
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder<bool>(
            pageBuilder: (context, animation, secondaryAnimation) =>
                VideoPlayerScreen(
                  metadata: widget.metadata.copyWith(
                    viewOffset: currentPosition.inMilliseconds,
                  ),
                  selectedMediaIndex: newMediaIndex,
                ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.messages.errorLoading(error: e.toString()))),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
