import '../../utils/platform_helper.dart';

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/services.dart';

import '../../focus/dpad_navigator.dart';
import '../../mpv/mpv.dart';
import '../../models/plex_media_info.dart';
import '../../models/plex_media_version.dart';
import '../../models/plex_metadata.dart';
import '../../services/fullscreen_state_manager.dart';
import '../../utils/desktop_window_padding.dart';
import '../../utils/formatters.dart';
import '../../i18n/strings.g.dart';
import '../../focus/focusable_wrapper.dart';
import '../../services/shader_service.dart';
import 'widgets/first_frame_guard.dart';
import 'widgets/play_pause_stream_builder.dart';
import 'widgets/video_controls_header.dart';
import 'widgets/video_timeline_bar.dart';
import 'widgets/volume_control.dart';
import 'widgets/track_chapter_controls.dart';

/// Desktop-specific video controls layout with top bar and bottom controls
class DesktopVideoControls extends StatefulWidget {
  final Player player;
  final PlexMetadata metadata;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final List<PlexChapter> chapters;
  final bool chaptersLoaded;
  final int seekTimeSmall;
  final VoidCallback onSeekToPreviousChapter;
  final VoidCallback onSeekToNextChapter;
  final VoidCallback? onSeekBackward;
  final VoidCallback? onSeekForward;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<Duration> onSeekEnd;
  final IconData Function(int) getReplayIcon;
  final IconData Function(int) getForwardIcon;

  /// Called when focus activity occurs (to reset hide timer)
  final VoidCallback? onFocusActivity;

  /// Called to request focus on play/pause button (e.g., when controls shown via keyboard)
  final VoidCallback? onRequestPlayPauseFocus;

  /// Called when user navigates up from timeline (to hide controls)
  final VoidCallback? onHideControls;

  // Track chapter controls parameters
  final List<PlexMediaVersion> availableVersions;
  final int selectedMediaIndex;
  final int boxFitMode;
  final int audioSyncOffset;
  final int subtitleSyncOffset;
  final bool isFullscreen;
  final bool isAlwaysOnTop;
  final VoidCallback? onTogglePIPMode;
  final VoidCallback? onCycleBoxFitMode;
  final VoidCallback? onToggleFullscreen;
  final VoidCallback? onToggleAlwaysOnTop;
  final Function(int)? onSwitchVersion;
  final Function(AudioTrack)? onAudioTrackChanged;
  final Function(SubtitleTrack)? onSubtitleTrackChanged;
  final VoidCallback? onLoadSeekTimes;
  final VoidCallback? onCancelAutoHide;
  final VoidCallback? onStartAutoHide;
  final String serverId;
  final VoidCallback? onBack;

  /// Whether the user can control playback (false in host-only mode for non-host).
  final bool canControl;

  /// Notifier for whether first video frame has rendered (shows loading state when false).
  final ValueNotifier<bool>? hasFirstFrame;

  final ShaderService? shaderService;
  final VoidCallback? onShaderChanged;

  /// Optional callback that returns a thumbnail URL for a given timestamp.
  final String Function(Duration time)? thumbnailUrlBuilder;

  const DesktopVideoControls({
    super.key,
    required this.player,
    required this.metadata,
    this.onNext,
    this.onPrevious,
    required this.chapters,
    required this.chaptersLoaded,
    required this.seekTimeSmall,
    required this.onSeekToPreviousChapter,
    required this.onSeekToNextChapter,
    this.onSeekBackward,
    this.onSeekForward,
    required this.onSeek,
    required this.onSeekEnd,
    required this.getReplayIcon,
    required this.getForwardIcon,
    this.onFocusActivity,
    this.onRequestPlayPauseFocus,
    this.onHideControls,
    this.availableVersions = const [],
    this.selectedMediaIndex = 0,
    this.boxFitMode = 0,
    this.audioSyncOffset = 0,
    this.subtitleSyncOffset = 0,
    this.isFullscreen = false,
    this.isAlwaysOnTop = false,
    this.onTogglePIPMode,
    this.onCycleBoxFitMode,
    this.onToggleFullscreen,
    this.onToggleAlwaysOnTop,
    this.onSwitchVersion,
    this.onAudioTrackChanged,
    this.onSubtitleTrackChanged,
    this.onLoadSeekTimes,
    this.onCancelAutoHide,
    this.onStartAutoHide,
    this.serverId = '',
    this.onBack,
    this.canControl = true,
    this.hasFirstFrame,
    this.shaderService,
    this.onShaderChanged,
    this.thumbnailUrlBuilder,
  });

  @override
  State<DesktopVideoControls> createState() => DesktopVideoControlsState();
}

class DesktopVideoControlsState extends State<DesktopVideoControls> {
  // Focus nodes for playback control buttons
  late final FocusNode _prevItemFocusNode;
  late final FocusNode _prevChapterFocusNode;
  late final FocusNode _skipBackFocusNode;
  late final FocusNode _playPauseFocusNode;
  late final FocusNode _skipForwardFocusNode;
  late final FocusNode _nextChapterFocusNode;
  late final FocusNode _nextItemFocusNode;
  late final FocusNode _timelineFocusNode;

  // Focus node for volume control
  late final FocusNode _volumeFocusNode;

  // Focus nodes for track/chapter controls (max 8 buttons possible)
  late final List<FocusNode> _trackControlFocusNodes;

  // List of button focus nodes for horizontal navigation
  late final List<FocusNode> _buttonFocusNodes;

  // Progressive seek acceleration state
  LogicalKeyboardKey? _seekDirection; // Current direction being held
  int _seekRepeatCount = 0; // Consecutive key repeats for acceleration

  @override
  void initState() {
    super.initState();
    _prevItemFocusNode = FocusNode(debugLabel: 'PrevItem');
    _prevChapterFocusNode = FocusNode(debugLabel: 'PrevChapter');
    _skipBackFocusNode = FocusNode(debugLabel: 'SkipBack');
    _playPauseFocusNode = FocusNode(debugLabel: 'PlayPause');
    _skipForwardFocusNode = FocusNode(debugLabel: 'SkipForward');
    _nextChapterFocusNode = FocusNode(debugLabel: 'NextChapter');
    _nextItemFocusNode = FocusNode(debugLabel: 'NextItem');
    _timelineFocusNode = FocusNode(debugLabel: 'Timeline');
    _volumeFocusNode = FocusNode(debugLabel: 'Volume');

    // Create focus nodes for track controls (up to 8 buttons)
    _trackControlFocusNodes = List.generate(8, (i) => FocusNode(debugLabel: 'TrackControl$i'));

    _buttonFocusNodes = [
      _prevItemFocusNode,
      _prevChapterFocusNode,
      _skipBackFocusNode,
      _playPauseFocusNode,
      _skipForwardFocusNode,
      _nextChapterFocusNode,
      _nextItemFocusNode,
    ];
  }

  @override
  void dispose() {
    _prevItemFocusNode.dispose();
    _prevChapterFocusNode.dispose();
    _skipBackFocusNode.dispose();
    _playPauseFocusNode.dispose();
    _skipForwardFocusNode.dispose();
    _nextChapterFocusNode.dispose();
    _nextItemFocusNode.dispose();
    _timelineFocusNode.dispose();
    _volumeFocusNode.dispose();
    for (final node in _trackControlFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// Request focus on the play/pause button (called when controls shown via keyboard)
  void requestPlayPauseFocus() {
    _playPauseFocusNode.requestFocus();
  }

  /// Request focus on the timeline (called when controls shown via LEFT/RIGHT)
  void requestTimelineFocus() {
    _timelineFocusNode.requestFocus();
  }

  /// Get focus node for volume control
  FocusNode get volumeFocusNode => _volumeFocusNode;

  /// Get focus nodes for track controls
  List<FocusNode> get trackControlFocusNodes => _trackControlFocusNodes;

  /// Handle left navigation from first track control - go to volume
  void navigateFromTrackToVolume() {
    _volumeFocusNode.requestFocus();
    widget.onFocusActivity?.call();
  }

  void _onFocusChange(bool hasFocus) {
    if (hasFocus) {
      widget.onFocusActivity?.call();
    } else {
      // Reset progressive seek state when timeline loses focus
      _resetSeekState();
    }
  }

  /// Handle directional navigation for bottom control row.
  ///
  /// Returns [KeyEventResult.handled] if the key was processed,
  /// [KeyEventResult.ignored] otherwise.
  /// UP always navigates to timeline.
  KeyEventResult _handleDirectionalNavigation(KeyEvent event, {FocusNode? leftTarget, FocusNode? rightTarget}) {
    if (!event.isActionable) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowLeft) {
      leftTarget?.requestFocus();
      widget.onFocusActivity?.call();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowRight) {
      rightTarget?.requestFocus();
      widget.onFocusActivity?.call();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      _timelineFocusNode.requestFocus();
      widget.onFocusActivity?.call();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Handle key events for horizontal button navigation
  KeyEventResult _handleButtonKeyEvent(FocusNode node, KeyEvent event, int index) {
    final leftTarget = index > 0 ? _buttonFocusNodes[index - 1] : null;
    final rightTarget = index < _buttonFocusNodes.length - 1 ? _buttonFocusNodes[index + 1] : _volumeFocusNode;

    return _handleDirectionalNavigation(event, leftTarget: leftTarget, rightTarget: rightTarget);
  }

  /// Handle key events for volume control navigation
  KeyEventResult _handleVolumeKeyEvent(FocusNode node, KeyEvent event) {
    return _handleDirectionalNavigation(
      event,
      leftTarget: _nextItemFocusNode,
      rightTarget: _trackControlFocusNodes.isNotEmpty ? _trackControlFocusNodes[0] : null,
    );
  }

  /// Reset progressive seek state
  void _resetSeekState() {
    _seekDirection = null;
    _seekRepeatCount = 0;
  }

  /// Calculate seek multiplier based on repeat count (stepped tiers)
  double _getSeekMultiplier() {
    if (_seekRepeatCount <= 5) {
      return 1.5;
    } else if (_seekRepeatCount <= 15) {
      return 3.0;
    } else if (_seekRepeatCount <= 30) {
      return 6.0;
    } else {
      return 10.0;
    }
  }

  /// Handle key events for timeline navigation
  KeyEventResult _handleTimelineKeyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;

    // Handle key release to reset progressive seek state
    if (event is KeyUpEvent) {
      if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight) {
        _resetSeekState();
      }
      return KeyEventResult.ignored;
    }

    if (!event.isActionable) {
      return KeyEventResult.ignored;
    }

    final duration = widget.player.state.duration;
    final position = widget.player.state.position;

    // UP arrow - hide controls and reset seek state
    if (key == LogicalKeyboardKey.arrowUp) {
      _resetSeekState();
      widget.onHideControls?.call();
      return KeyEventResult.handled;
    }

    // DOWN arrow - move focus to play/pause button and reset seek state
    if (key == LogicalKeyboardKey.arrowDown) {
      _resetSeekState();
      _playPauseFocusNode.requestFocus();
      widget.onFocusActivity?.call();
      return KeyEventResult.handled;
    }

    // LEFT/RIGHT for smooth scrubbing with progressive acceleration
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight) {
      // Ignore seeking if user cannot control
      if (!widget.canControl) return KeyEventResult.handled;

      if (duration.inMilliseconds <= 0) return KeyEventResult.handled;

      // Track direction change - reset if direction changes
      if (_seekDirection != key) {
        _seekDirection = key;
        _seekRepeatCount = 0;
      }

      // Increment repeat count on KeyRepeatEvent
      if (event is KeyRepeatEvent) {
        _seekRepeatCount++;
      }

      // Base step: 0.5% of duration, minimum 500ms, maximum 15s
      final baseStepMs = (duration.inMilliseconds * 0.005).clamp(500, 15000).toInt();

      // Apply progressive multiplier only on repeat events (initial press uses 1x)
      final effectiveMultiplier = event is KeyRepeatEvent ? _getSeekMultiplier() : 1.0;
      final stepMs = (baseStepMs * effectiveMultiplier).clamp(500, 60000).toInt();
      final step = Duration(milliseconds: stepMs);

      final isForward = key == LogicalKeyboardKey.arrowRight;
      final newPosition = isForward ? position + step : position - step;

      // Clamp to valid range
      final clampedPosition = Duration(milliseconds: newPosition.inMilliseconds.clamp(0, duration.inMilliseconds));

      widget.onSeek(clampedPosition);
      widget.onFocusActivity?.call();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top bar with back button and title (always visible)
        _buildTopBar(context),
        FirstFrameGuard(
          hasFirstFrame: widget.hasFirstFrame,
          placeholder: const Expanded(child: SizedBox.shrink()),
          builder: (context) =>
              Expanded(child: Column(children: [const Spacer(), _buildBottomControlsContent(context, hasFrame: true)])),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    // Use global fullscreen state for padding
    return ListenableBuilder(
      listenable: FullscreenStateManager(),
      builder: (context, _) {
        final isFullscreen = FullscreenStateManager().isFullscreen;
        // In fullscreen on macOS, use less left padding since traffic lights auto-hide
        // In normal mode on macOS, need more padding to avoid traffic lights
        final leftPadding = AppPlatform.isMacOS
            ? (isFullscreen ? DesktopWindowPadding.macOSLeftFullscreen : DesktopWindowPadding.macOSLeft)
            : DesktopWindowPadding.macOSLeftFullscreen;

        return _buildTopBarContent(context, leftPadding);
      },
    );
  }

  Widget _buildTopBarContent(BuildContext context, double leftPadding) {
    final topBar = Padding(
      padding: EdgeInsets.only(left: leftPadding, right: 16),
      child: VideoControlsHeader(
        metadata: widget.metadata,
        style: AppPlatform.isMacOS ? VideoHeaderStyle.singleLine : VideoHeaderStyle.multiLine,
        onBack: widget.onBack,
      ),
    );

    return DesktopAppBarHelper.wrapWithGestureDetector(topBar, opaque: true);
  }

  Widget _buildBottomControlsContent(BuildContext context, {required bool hasFrame}) {
    final canInteract = widget.canControl && hasFrame;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Row 1: Timeline with time indicators
          VideoTimelineBar(
            player: widget.player,
            chapters: widget.chapters,
            chaptersLoaded: widget.chaptersLoaded,
            onSeek: widget.onSeek,
            onSeekEnd: widget.onSeekEnd,
            horizontalLayout: true,
            focusNode: _timelineFocusNode,
            onKeyEvent: _handleTimelineKeyEvent,
            onFocusChange: _onFocusChange,
            enabled: canInteract,
            thumbnailUrlBuilder: widget.thumbnailUrlBuilder,
          ),
          const SizedBox(height: 4),
          // Row 2: Playback controls and options
          Row(
            children: [
              // Previous item
              Opacity(
                opacity: widget.canControl ? 1.0 : 0.5,
                child: _buildFocusableButton(
                  focusNode: _prevItemFocusNode,
                  index: 0,
                  icon: Symbols.skip_previous_rounded,
                  color: widget.onPrevious != null && widget.canControl ? Colors.white : Colors.white54,
                  onPressed: widget.canControl ? widget.onPrevious : null,
                  semanticLabel: t.videoControls.previousButton,
                ),
              ),
              // Previous chapter
              StreamBuilder<Duration>(
                stream: widget.player.streams.position,
                initialData: widget.player.state.position,
                builder: (context, posSnapshot) {
                  final prevLabel = _getPreviousChapterLabel(posSnapshot.data ?? Duration.zero);
                  return Opacity(
                    opacity: widget.canControl ? 1.0 : 0.5,
                    child: _buildFocusableButton(
                      focusNode: _prevChapterFocusNode,
                      index: 1,
                      icon: Symbols.fast_rewind_rounded,
                      color: widget.chapters.isNotEmpty && widget.canControl ? Colors.white : Colors.white54,
                      onPressed: widget.canControl && widget.chapters.isNotEmpty ? widget.onSeekToPreviousChapter : null,
                      semanticLabel: t.videoControls.previousChapterButton,
                      tooltip: prevLabel,
                    ),
                  );
                },
              ),
              // Skip backward
              Opacity(
                opacity: widget.canControl ? 1.0 : 0.5,
                child: _buildFocusableButton(
                  focusNode: _skipBackFocusNode,
                  index: 2,
                  icon: widget.getReplayIcon(widget.seekTimeSmall),
                  onPressed: widget.canControl ? widget.onSeekBackward : null,
                  semanticLabel: t.videoControls.seekBackwardButton(seconds: widget.seekTimeSmall),
                ),
              ),
              // Play/Pause
              Opacity(
                opacity: widget.canControl ? 1.0 : 0.5,
                child: PlayPauseStreamBuilder(
                  player: widget.player,
                  builder: (context, isPlaying) {
                    return _buildFocusableButton(
                      focusNode: _playPauseFocusNode,
                      index: 3,
                      icon: isPlaying ? Symbols.pause_rounded : Symbols.play_arrow_rounded,
                      iconSize: 32,
                      onPressed: widget.canControl
                          ? () {
                              if (isPlaying) {
                                widget.player.pause();
                              } else {
                                widget.player.play();
                              }
                            }
                          : null,
                      semanticLabel: isPlaying ? t.videoControls.pauseButton : t.videoControls.playButton,
                    );
                  },
                ),
              ),
              // Skip forward
              Opacity(
                opacity: widget.canControl ? 1.0 : 0.5,
                child: _buildFocusableButton(
                  focusNode: _skipForwardFocusNode,
                  index: 4,
                  icon: widget.getForwardIcon(widget.seekTimeSmall),
                  onPressed: widget.canControl ? widget.onSeekForward : null,
                  semanticLabel: t.videoControls.seekForwardButton(seconds: widget.seekTimeSmall),
                ),
              ),
              // Next chapter
              StreamBuilder<Duration>(
                stream: widget.player.streams.position,
                initialData: widget.player.state.position,
                builder: (context, posSnapshot) {
                  final nextLabel = _getNextChapterLabel(posSnapshot.data ?? Duration.zero);
                  return Opacity(
                    opacity: widget.canControl ? 1.0 : 0.5,
                    child: _buildFocusableButton(
                      focusNode: _nextChapterFocusNode,
                      index: 5,
                      icon: Symbols.fast_forward_rounded,
                      color: widget.chapters.isNotEmpty && widget.canControl ? Colors.white : Colors.white54,
                      onPressed: widget.canControl && widget.chapters.isNotEmpty ? widget.onSeekToNextChapter : null,
                      semanticLabel: t.videoControls.nextChapterButton,
                      tooltip: nextLabel,
                    ),
                  );
                },
              ),
              // Next item
              Opacity(
                opacity: widget.canControl ? 1.0 : 0.5,
                child: _buildFocusableButton(
                  focusNode: _nextItemFocusNode,
                  index: 6,
                  icon: Symbols.skip_next_rounded,
                  color: widget.onNext != null && widget.canControl ? Colors.white : Colors.white54,
                  onPressed: widget.canControl ? widget.onNext : null,
                  semanticLabel: t.videoControls.nextButton,
                ),
              ),
              // Finish time (hidden when too narrow to fit)
              Expanded(
                child: StreamBuilder<Duration>(
                  stream: widget.player.streams.position,
                  initialData: widget.player.state.position,
                  builder: (context, posSnap) {
                    return StreamBuilder<Duration>(
                      stream: widget.player.streams.duration,
                      initialData: widget.player.state.duration,
                      builder: (context, durSnap) {
                        return StreamBuilder<double>(
                          stream: widget.player.streams.rate,
                          initialData: widget.player.state.rate,
                          builder: (context, rateSnap) {
                            final position = posSnap.data ?? Duration.zero;
                            final duration = durSnap.data ?? Duration.zero;
                            final remaining = duration - position;
                            final rate = rateSnap.data ?? 1.0;
                            if (remaining.inSeconds <= 0) return const SizedBox.shrink();

                            final text = t.videoControls.endsAt(time: formatFinishTime(remaining, rate: rate));
                            const style = TextStyle(color: Colors.white70, fontSize: 13);

                            return LayoutBuilder(
                              builder: (context, constraints) {
                                final tp = TextPainter(
                                  text: TextSpan(text: text, style: style),
                                  textDirection: TextDirection.ltr,
                                )..layout();
                                final textWidth = tp.width + 8;
                                tp.dispose();
                                if (textWidth > constraints.maxWidth) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(text, style: style),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              // Volume control
              VolumeControl(
                player: widget.player,
                focusNode: _volumeFocusNode,
                onKeyEvent: _handleVolumeKeyEvent,
                onFocusChange: _onFocusChange,
                onFocusActivity: widget.onFocusActivity,
              ),
              const SizedBox(width: 16),
              // Audio track, subtitle, and chapter controls
              TrackChapterControls(
                player: widget.player,
                chapters: widget.chapters,
                chaptersLoaded: widget.chaptersLoaded,
                availableVersions: widget.availableVersions,
                selectedMediaIndex: widget.selectedMediaIndex,
                boxFitMode: widget.boxFitMode,
                audioSyncOffset: widget.audioSyncOffset,
                subtitleSyncOffset: widget.subtitleSyncOffset,
                isRotationLocked: false, // Desktop doesn't have rotation lock
                isFullscreen: widget.isFullscreen,
                isAlwaysOnTop: widget.isAlwaysOnTop,
                serverId: widget.serverId,
                onTogglePIPMode: null, // PIP not supported on desktop
                onCycleBoxFitMode: widget.onCycleBoxFitMode,
                onToggleFullscreen: widget.onToggleFullscreen,
                onToggleAlwaysOnTop: widget.onToggleAlwaysOnTop,
                onSwitchVersion: widget.onSwitchVersion,
                onAudioTrackChanged: widget.onAudioTrackChanged,
                onSubtitleTrackChanged: widget.onSubtitleTrackChanged,
                onLoadSeekTimes: widget.onLoadSeekTimes,
                onCancelAutoHide: widget.onCancelAutoHide,
                onStartAutoHide: widget.onStartAutoHide,
                focusNodes: _trackControlFocusNodes,
                onFocusChange: _onFocusChange,
                onNavigateLeft: navigateFromTrackToVolume,
                canControl: widget.canControl,
                shaderService: widget.shaderService,
                onShaderChanged: widget.onShaderChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Returns the label of the next chapter the user would seek to, or null.
  String? _getNextChapterLabel(Duration position) {
    if (widget.chapters.isEmpty) return null;
    final currentPositionMs = position.inMilliseconds;
    for (final chapter in widget.chapters) {
      final chapterStart = chapter.startTimeOffset ?? 0;
      if (chapterStart > currentPositionMs) {
        return chapter.label;
      }
    }
    return null;
  }

  /// Returns the label of the previous chapter the user would seek to, or null.
  String? _getPreviousChapterLabel(Duration position) {
    if (widget.chapters.isEmpty) return null;
    final currentPositionMs = position.inMilliseconds;
    for (int i = widget.chapters.length - 1; i >= 0; i--) {
      final chapterStart = widget.chapters[i].startTimeOffset ?? 0;
      if (currentPositionMs > chapterStart + 3000) {
        return widget.chapters[i].label;
      }
    }
    return null;
  }

  Widget _buildFocusableButton({
    required FocusNode focusNode,
    required int index,
    required IconData icon,
    required VoidCallback? onPressed,
    required String semanticLabel,
    Color color = Colors.white,
    double iconSize = 24,
    String? tooltip,
  }) {
    return FocusableWrapper(
      focusNode: focusNode,
      onSelect: onPressed,
      onKeyEvent: (node, event) => _handleButtonKeyEvent(node, event, index),
      onFocusChange: _onFocusChange,
      borderRadius: 20,
      autoScroll: false,
      useBackgroundFocus: true,
      semanticLabel: semanticLabel,
      child: Semantics(
        label: semanticLabel,
        button: true,
        excludeSemantics: true,
        child: IconButton(
          icon: AppIcon(icon, fill: 1, color: color, size: iconSize),
          iconSize: iconSize,
          tooltip: tooltip,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
