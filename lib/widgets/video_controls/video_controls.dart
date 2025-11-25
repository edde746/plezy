import 'dart:async' show StreamSubscription, Timer;
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChrome, DeviceOrientation;
import 'package:macos_window_utils/macos_window_utils.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import '../../client/plex_client.dart';
import '../../models/plex_media_info.dart';
import '../../models/plex_media_version.dart';
import '../../models/plex_metadata.dart';
import '../../screens/video_player_screen.dart';
import '../../services/keyboard_shortcuts_service.dart';
import '../../services/settings_service.dart';
import '../../utils/platform_detector.dart';
import '../../utils/player_utils.dart';
import '../../utils/provider_extensions.dart';
import '../../utils/video_control_icons.dart';
import '../../i18n/strings.g.dart';
import 'widgets/volume_control.dart';
import 'widgets/track_chapter_controls.dart';
import 'mobile_video_controls.dart';
import 'desktop_video_controls.dart';

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

  /// Get the correct PlexClient for this metadata's server
  PlexClient _getClientForMetadata() {
    return context.getClientForServer(widget.metadata.serverId!);
  }

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
  // Playback state subscription for auto-hide timer
  StreamSubscription<bool>? _playingSubscription;

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
    _listenToPlayingState();
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

  /// Listen to playback state changes to manage auto-hide timer on iOS/mobile
  void _listenToPlayingState() {
    _playingSubscription = widget.player.stream.playing.listen((isPlaying) {
      if (isPlaying && _showControls) {
        _startHideTimer();
      } else if (!isPlaying) {
        _hideTimer?.cancel();
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
    _playingSubscription?.cancel();
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

  /// Restart the hide timer on user interaction (if video is playing)
  void _restartHideTimerIfPlaying() {
    if (widget.player.state.playing) {
      _startHideTimer();
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
    final client = _getClientForMetadata();

    final chapters = await client.getChapters(widget.metadata.ratingKey);
    if (mounted) {
      setState(() {
        _chapters = chapters;
        _chaptersLoaded = true;
      });
    }
  }

  Future<void> _loadMarkers() async {
    final client = _getClientForMetadata();

    final markers = await client.getMarkers(widget.metadata.ratingKey);

    if (mounted) {
      setState(() {
        _markers = markers;
        _markersLoaded = true;
      });
    }
  }

  Widget _buildTrackChapterControlsWidget() {
    return TrackChapterControls(
      player: widget.player,
      chapters: _chapters,
      chaptersLoaded: _chaptersLoaded,
      availableVersions: widget.availableVersions,
      selectedMediaIndex: widget.selectedMediaIndex,
      boxFitMode: widget.boxFitMode,
      audioSyncOffset: _audioSyncOffset,
      subtitleSyncOffset: _subtitleSyncOffset,
      isRotationLocked: _isRotationLocked,
      isFullscreen: _isFullscreen,
      onCycleBoxFitMode: widget.onCycleBoxFitMode,
      onToggleRotationLock: _toggleRotationLock,
      onToggleFullscreen: _toggleFullscreen,
      onSwitchVersion: _switchMediaVersion,
      onAudioTrackChanged: widget.onAudioTrackChanged,
      onSubtitleTrackChanged: widget.onSubtitleTrackChanged,
      onLoadSeekTimes: () async {
        if (mounted) {
          await _loadSeekTimes();
        }
      },
      serverId: widget.metadata.serverId ?? '',
    );
  }

  void _seekToPreviousChapter() {
    if (_chapters.isEmpty) {
      // No chapters - seek backward by configured amount
      seekWithClamping(widget.player, Duration(seconds: -_seekTimeSmall));
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
      seekWithClamping(widget.player, Duration(seconds: _seekTimeSmall));
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

  /// Handle double-tap skip forward or backward
  void _handleDoubleTapSkip({required bool isForward}) {
    // Perform the seek
    seekWithClamping(
      widget.player,
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
              ? getForwardIcon(_seekTimeSmall)
              : getReplayIcon(_seekTimeSmall),
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
                          ? Listener(
                              behavior: HitTestBehavior.translucent,
                              onPointerDown: (_) =>
                                  _restartHideTimerIfPlaying(),
                              child: MobileVideoControls(
                                player: widget.player,
                                metadata: widget.metadata,
                                chapters: _chapters,
                                chaptersLoaded: _chaptersLoaded,
                                seekTimeSmall: _seekTimeSmall,
                                trackChapterControls:
                                    _buildTrackChapterControlsWidget(),
                                onSeek: _throttledSeek,
                                onSeekEnd: _finalizeSeek,
                                onPlayPause:
                                    () {}, // Not used, handled internally
                                onCancelAutoHide: () => _hideTimer?.cancel(),
                                onStartAutoHide: _startHideTimer,
                              ),
                            )
                          : Listener(
                              behavior: HitTestBehavior.translucent,
                              onPointerDown: (_) =>
                                  _restartHideTimerIfPlaying(),
                              child: DesktopVideoControls(
                                player: widget.player,
                                metadata: widget.metadata,
                                onNext: widget.onNext,
                                onPrevious: widget.onPrevious,
                                chapters: _chapters,
                                chaptersLoaded: _chaptersLoaded,
                                seekTimeSmall: _seekTimeSmall,
                                volumeControl: VolumeControl(
                                  player: widget.player,
                                ),
                                trackChapterControls:
                                    _buildTrackChapterControlsWidget(),
                                onSeekToPreviousChapter: _seekToPreviousChapter,
                                onSeekToNextChapter: _seekToNextChapter,
                                onSeek: _throttledSeek,
                                onSeekEnd: _finalizeSeek,
                                getReplayIcon: getReplayIcon,
                                getForwardIcon: getForwardIcon,
                              ),
                            ),
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
}
