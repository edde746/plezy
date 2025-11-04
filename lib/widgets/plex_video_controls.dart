import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:macos_window_utils/macos_window_utils.dart';
import '../models/plex_metadata.dart';
import '../models/plex_media_info.dart';
import '../models/plex_media_version.dart';
import '../providers/plex_client_provider.dart';
import '../services/fullscreen_state_manager.dart';
import '../services/keyboard_shortcuts_service.dart';
import '../services/settings_service.dart';
import '../utils/desktop_window_padding.dart';
import '../utils/platform_detector.dart';
import '../utils/provider_extensions.dart';
import '../screens/video_player_screen.dart';
import 'app_bar_back_button.dart';

/// Custom video controls builder for Plex with chapter, audio, and subtitle support
Widget plexVideoControlsBuilder(
  Player player,
  PlexMetadata metadata, {
  VoidCallback? onNext,
  VoidCallback? onPrevious,
  List<PlexMediaVersion>? availableVersions,
  int? selectedMediaIndex,
}) {
  return PlexVideoControls(
    player: player,
    metadata: metadata,
    onNext: onNext,
    onPrevious: onPrevious,
    availableVersions: availableVersions ?? [],
    selectedMediaIndex: selectedMediaIndex ?? 0,
  );
}

class PlexVideoControls extends StatefulWidget {
  final Player player;
  final PlexMetadata metadata;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final List<PlexMediaVersion> availableVersions;
  final int selectedMediaIndex;

  const PlexVideoControls({
    super.key,
    required this.player,
    required this.metadata,
    this.onNext,
    this.onPrevious,
    this.availableVersions = const [],
    this.selectedMediaIndex = 0,
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
  int _seekTimeLarge = 30; // Default, loaded from settings
  // Double-tap feedback state
  bool _showDoubleTapFeedback = false;
  double _doubleTapFeedbackOpacity = 0.0;
  bool _lastDoubleTapWasForward = true;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _loadChapters();
    _loadSeekTimes();
    _startHideTimer();
    _initKeyboardService();
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

  Future<void> _loadSeekTimes() async {
    final settingsService = await SettingsService.getInstance();
    if (mounted) {
      setState(() {
        _seekTimeSmall = settingsService.getSeekTimeSmall();
        _seekTimeLarge = settingsService.getSeekTimeLarge();
      });
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

  Widget _buildTrackAndChapterControls() {
    return StreamBuilder<Tracks>(
      stream: widget.player.stream.tracks,
      initialData: widget.player.state.tracks,
      builder: (context, snapshot) {
        final tracks = snapshot.data;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.speed, color: Colors.white),
              onPressed: _showPlaybackSpeedBottomSheet,
            ),
            if (_hasMultipleAudioTracks(tracks))
              IconButton(
                icon: const Icon(Icons.audiotrack, color: Colors.white),
                onPressed: _showAudioBottomSheet,
              ),
            if (_hasSubtitles(tracks))
              IconButton(
                icon: const Icon(Icons.subtitles, color: Colors.white),
                onPressed: _showSubtitleBottomSheet,
              ),
            if (_chapters.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.video_library, color: Colors.white),
                onPressed: _showChapterBottomSheet,
              ),
            if (widget.availableVersions.length > 1)
              IconButton(
                icon: const Icon(Icons.video_file, color: Colors.white),
                onPressed: _showVersionBottomSheet,
              ),
          ],
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
                    final topExclude = height * 0.15; // Exclude top 15% (top bar)
                    final bottomExclude = height * 0.15; // Exclude bottom 15% (seek slider)
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
          ],
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
    final topBar = Padding(
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
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
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
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  _getReplayIcon(_seekTimeSmall),
                  color: Colors.white,
                  size: 48,
                ),
                iconSize: 48,
                onPressed: () {
                  _seekWithClamping(Duration(seconds: -_seekTimeSmall));
                },
              ),
            ),
            const SizedBox(width: 48),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 72,
                ),
                iconSize: 72,
                onPressed: () {
                  if (isPlaying) {
                    widget.player.pause();
                    _hideTimer?.cancel(); // Cancel auto-hide when paused
                  } else {
                    widget.player.play();
                    _startHideTimer(); // Start auto-hide when playing
                  }
                },
              ),
            ),
            const SizedBox(width: 48),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  _getForwardIcon(_seekTimeSmall),
                  color: Colors.white,
                  size: 48,
                ),
                iconSize: 48,
                onPressed: () {
                  _seekWithClamping(Duration(seconds: _seekTimeSmall));
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMobileBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<Duration>(
        stream: widget.player.stream.position,
        builder: (context, positionSnapshot) {
          return StreamBuilder<Duration>(
            stream: widget.player.stream.duration,
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
    // On macOS, use single-line layout to align with traffic lights
    // On other platforms, use two-line layout with series and episode info
    final isMacOS = Platform.isMacOS;

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
            child: isMacOS
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
            builder: (context, positionSnapshot) {
              return StreamBuilder<Duration>(
                stream: widget.player.stream.duration,
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
                  _chapters.isEmpty ? _getReplayIcon(_seekTimeSmall) : Icons.fast_rewind,
                  color: Colors.white,
                ),
                onPressed: _seekToPreviousChapter,
              ),
              // Play/Pause
              StreamBuilder<bool>(
                stream: widget.player.stream.playing,
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
                  _chapters.isEmpty ? _getForwardIcon(_seekTimeSmall) : Icons.fast_forward,
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
              // Fullscreen
              IconButton(
                icon: Icon(
                  _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                ),
                onPressed: _toggleFullscreen,
              ),
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
            widget.player.seek(Duration(milliseconds: value.toInt()));
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
              onPressed: () {
                if (isMuted) {
                  widget.player.setVolume(100.0);
                } else {
                  widget.player.setVolume(0.0);
                }
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

  BoxConstraints _getBottomSheetConstraints() {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return BoxConstraints(
      maxWidth: isDesktop ? 700 : double.infinity,
      maxHeight: isDesktop ? 400 : size.height * 0.75,
      minHeight: isDesktop ? 300 : size.height * 0.5,
    );
  }

  void _showAudioBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      constraints: _getBottomSheetConstraints(),
      builder: (context) => StreamBuilder<Tracks>(
        stream: widget.player.stream.tracks,
        initialData: widget.player.state.tracks,
        builder: (context, snapshot) {
          final tracks = snapshot.data;
          final audioTracks = (tracks?.audio ?? [])
              .where((track) => track.id != 'auto' && track.id != 'no')
              .toList();

          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.audiotrack, color: Colors.white),
                        const SizedBox(width: 12),
                        const Text(
                          'Audio Tracks',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  if (audioTracks.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'No audio tracks available',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: StreamBuilder<Track>(
                        stream: widget.player.stream.track,
                        initialData: widget.player.state.track,
                        builder: (context, selectedSnapshot) {
                          // Use snapshot data or fall back to current state
                          final currentTrack =
                              selectedSnapshot.data ??
                              widget.player.state.track;
                          final selectedTrack = currentTrack.audio;
                          final selectedId = selectedTrack?.id;

                          return ListView.builder(
                            itemCount: audioTracks.length,
                            itemBuilder: (context, index) {
                              final audioTrack = audioTracks[index];
                              final isSelected = audioTrack.id == selectedId;

                              final parts = <String>[];
                              if (audioTrack.title != null &&
                                  audioTrack.title!.isNotEmpty) {
                                parts.add(audioTrack.title!);
                              }
                              if (audioTrack.language != null &&
                                  audioTrack.language!.isNotEmpty) {
                                parts.add(audioTrack.language!.toUpperCase());
                              }
                              if (audioTrack.codec != null &&
                                  audioTrack.codec!.isNotEmpty) {
                                parts.add(audioTrack.codec!.toUpperCase());
                              }
                              if (audioTrack.channelscount != null) {
                                parts.add('${audioTrack.channelscount}ch');
                              }

                              final label = parts.isEmpty
                                  ? 'Audio Track ${index + 1}'
                                  : parts.join(' · ');

                              return ListTile(
                                title: Text(
                                  label,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.white,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.blue,
                                      )
                                    : null,
                                onTap: () {
                                  widget.player.setAudioTrack(audioTrack);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSubtitleBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      constraints: _getBottomSheetConstraints(),
      builder: (context) => StreamBuilder<Tracks>(
        stream: widget.player.stream.tracks,
        initialData: widget.player.state.tracks,
        builder: (context, snapshot) {
          final tracks = snapshot.data;
          final subtitles = (tracks?.subtitle ?? [])
              .where((track) => track.id != 'auto' && track.id != 'no')
              .toList();

          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.subtitles, color: Colors.white),
                        const SizedBox(width: 12),
                        const Text(
                          'Subtitles',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  if (subtitles.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'No subtitles available',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: StreamBuilder<Track>(
                        stream: widget.player.stream.track,
                        initialData: widget.player.state.track,
                        builder: (context, selectedSnapshot) {
                          // Use snapshot data or fall back to current state
                          final currentTrack =
                              selectedSnapshot.data ??
                              widget.player.state.track;
                          final selectedTrack = currentTrack.subtitle;
                          final selectedId = selectedTrack?.id;
                          final isOffSelected = selectedId == 'no';

                          return ListView.builder(
                            itemCount:
                                subtitles.length + 1, // +1 for "Off" option
                            itemBuilder: (context, index) {
                              // First item is "Off"
                              if (index == 0) {
                                return ListTile(
                                  title: Text(
                                    'Off',
                                    style: TextStyle(
                                      color: isOffSelected
                                          ? Colors.blue
                                          : Colors.white,
                                    ),
                                  ),
                                  trailing: isOffSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.blue,
                                        )
                                      : null,
                                  onTap: () {
                                    widget.player.setSubtitleTrack(
                                      SubtitleTrack.no(),
                                    );
                                    Navigator.pop(context);
                                  },
                                );
                              }

                              // Subsequent items are subtitle tracks
                              final subtitle = subtitles[index - 1];
                              final isSelected = subtitle.id == selectedId;

                              // Build label with available info
                              final parts = <String>[];
                              if (subtitle.title != null &&
                                  subtitle.title!.isNotEmpty) {
                                parts.add(subtitle.title!);
                              }
                              if (subtitle.language != null &&
                                  subtitle.language!.isNotEmpty) {
                                parts.add(subtitle.language!.toUpperCase());
                              }
                              if (subtitle.codec != null &&
                                  subtitle.codec!.isNotEmpty) {
                                // Format codec names nicely
                                String codecName = subtitle.codec!
                                    .toUpperCase();
                                if (codecName == 'SUBRIP') {
                                  codecName = 'SRT';
                                } else if (codecName == 'DVD_SUBTITLE') {
                                  codecName = 'DVD';
                                } else if (codecName == 'ASS' ||
                                    codecName == 'SSA') {
                                  codecName = codecName; // Keep as-is
                                } else if (codecName == 'WEBVTT') {
                                  codecName = 'VTT';
                                }
                                parts.add(codecName);
                              }

                              final label = parts.isEmpty
                                  ? 'Track $index'
                                  : parts.join(' · ');

                              return ListTile(
                                title: Text(
                                  label,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.white,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.blue,
                                      )
                                    : null,
                                onTap: () {
                                  widget.player.setSubtitleTrack(subtitle);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showChapterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      constraints: _getBottomSheetConstraints(),
      builder: (context) => StreamBuilder<Duration>(
        stream: widget.player.stream.position,
        initialData: widget.player.state.position,
        builder: (context, positionSnapshot) {
          final currentPosition = positionSnapshot.data ?? Duration.zero;
          final currentPositionMs = currentPosition.inMilliseconds;

          // Find the current chapter based on position
          int? currentChapterIndex;
          for (int i = 0; i < _chapters.length; i++) {
            final chapter = _chapters[i];
            final startMs = chapter.startTimeOffset ?? 0;
            final endMs =
                chapter.endTimeOffset ??
                (i < _chapters.length - 1
                    ? _chapters[i + 1].startTimeOffset ?? 0
                    : double.maxFinite.toInt());

            if (currentPositionMs >= startMs && currentPositionMs < endMs) {
              currentChapterIndex = i;
              break;
            }
          }

          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.video_library, color: Colors.white),
                        const SizedBox(width: 12),
                        const Text(
                          'Chapters',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  if (!_chaptersLoaded)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_chapters.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'No chapters available',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _chapters.length,
                        itemBuilder: (context, index) {
                          final chapter = _chapters[index];
                          final isCurrentChapter = currentChapterIndex == index;

                          return ListTile(
                            leading: chapter.thumb != null
                                ? Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Consumer<PlexClientProvider>(
                                          builder:
                                              (context, clientProvider, child) {
                                                final client =
                                                    clientProvider.client;
                                                if (client == null) {
                                                  return const Icon(
                                                    Icons.image,
                                                    color: Colors.white54,
                                                    size: 34,
                                                  );
                                                }
                                                return Image.network(
                                                  client.getThumbnailUrl(
                                                    chapter.thumb,
                                                  ),
                                                  width: 60,
                                                  height: 34,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => const Icon(
                                                        Icons.image,
                                                        color: Colors.white54,
                                                        size: 34,
                                                      ),
                                                );
                                              },
                                        ),
                                      ),
                                      if (isCurrentChapter)
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: Colors.blue,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  )
                                : null,
                            title: Text(
                              chapter.label,
                              style: TextStyle(
                                color: isCurrentChapter
                                    ? Colors.blue
                                    : Colors.white,
                                fontWeight: isCurrentChapter
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              _formatDuration(chapter.startTime),
                              style: TextStyle(
                                color: isCurrentChapter
                                    ? Colors.blue.withValues(alpha: 0.7)
                                    : Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            trailing: isCurrentChapter
                                ? const Icon(
                                    Icons.play_circle_filled,
                                    color: Colors.blue,
                                  )
                                : null,
                            onTap: () {
                              widget.player.seek(chapter.startTime);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPlaybackSpeedBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      constraints: _getBottomSheetConstraints(),
      builder: (context) => StreamBuilder<double>(
        stream: widget.player.stream.rate,
        initialData: widget.player.state.rate,
        builder: (context, snapshot) {
          final currentRate = snapshot.data ?? 1.0;

          // Define available playback speeds
          final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0];

          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.speed, color: Colors.white),
                        const SizedBox(width: 12),
                        const Text(
                          'Playback Speed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: speeds.length,
                      itemBuilder: (context, index) {
                        final speed = speeds[index];
                        final isSelected = (currentRate - speed).abs() < 0.01;

                        // Format speed label
                        final label = speed == 1.0
                            ? 'Normal'
                            : '${speed.toStringAsFixed(2)}x';

                        return ListTile(
                          title: Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? Colors.blue : Colors.white,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: Colors.blue)
                              : null,
                          onTap: () {
                            widget.player.setRate(speed);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showVersionBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      constraints: _getBottomSheetConstraints(),
      builder: (context) {
        final versions = widget.availableVersions;
        final currentIndex = widget.selectedMediaIndex;

        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.video_file, color: Colors.white),
                      const SizedBox(width: 12),
                      const Text(
                        'Video Version',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: versions.length,
                    itemBuilder: (context, index) {
                      final version = versions[index];
                      final isSelected = index == currentIndex;

                      return ListTile(
                        title: Text(
                          version.displayLabel,
                          style: TextStyle(
                            color: isSelected ? Colors.blue : Colors.white,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: Colors.blue)
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          _switchMediaVersion(index);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
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

      // Save the preference
      final settingsService = await SettingsService.getInstance();
      final seriesKey = widget.metadata.grandparentRatingKey ??
          widget.metadata.ratingKey;
      await settingsService.setMediaVersionPreference(seriesKey, newMediaIndex);

      // Navigate to new player screen with the selected version
      // Use PageRouteBuilder with zero-duration transitions to prevent orientation reset
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder<bool>(
            pageBuilder: (context, animation, secondaryAnimation) => VideoPlayerScreen(
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
          SnackBar(content: Text('Error switching version: $e')),
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

/// Custom painter for drawing chapter markers on the timeline
class ChapterMarkerPainter extends CustomPainter {
  final List<PlexChapter> chapters;
  final Duration duration;

  ChapterMarkerPainter({required this.chapters, required this.duration});

  @override
  void paint(Canvas canvas, Size size) {
    if (duration.inMilliseconds == 0) return;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (final chapter in chapters) {
      final startMs = chapter.startTimeOffset ?? 0;
      if (startMs == 0) continue; // Skip first chapter marker at 0:00

      final position = (startMs / duration.inMilliseconds) * size.width;

      // Draw short vertical line for chapter marker (centered on slider track)
      canvas.drawLine(
        Offset(position, size.height * 0.45),
        Offset(position, size.height * 0.55),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ChapterMarkerPainter oldDelegate) {
    return oldDelegate.chapters != chapters || oldDelegate.duration != duration;
  }
}
