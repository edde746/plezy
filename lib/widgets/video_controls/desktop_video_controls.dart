import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/services.dart';

import '../../focus/dpad_navigator.dart';
import '../../mpv/mpv.dart';
import '../../models/plex_media_info.dart';
import '../../models/plex_metadata.dart';
import '../../services/fullscreen_state_manager.dart';
import '../../utils/desktop_window_padding.dart';
import '../../utils/formatters.dart';
import '../../i18n/strings.g.dart';
import '../../focus/focusable_wrapper.dart';
import 'models/track_controls_state.dart';
import 'widgets/content_strip.dart';
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

  final TrackControlsState trackControlsState;
  final VoidCallback? onBack;

  /// Notifier for whether first video frame has rendered (shows loading state when false).
  final ValueNotifier<bool>? hasFirstFrame;

  /// Optional callback that returns thumbnail image bytes for a given timestamp.
  final Uint8List? Function(Duration time)? thumbnailDataBuilder;

  /// Channel name for live TV display
  final String? liveChannelName;

  /// Whether to use dpad navigation for content strip (TV or keyboard nav mode)
  final bool useDpadNavigation;

  /// Server ID for content strip images
  final String? serverId;

  /// Whether to show the queue tab in the content strip
  final bool showQueueTab;

  /// Called when a queue item is selected in the content strip
  final Function(PlexMetadata)? onQueueItemSelected;

  /// Called to cancel auto-hide timer (e.g., when content strip is shown)
  final VoidCallback? onCancelAutoHide;

  /// Called to start auto-hide timer
  final VoidCallback? onStartAutoHide;

  /// Called when content strip visibility changes
  final ValueChanged<bool>? onContentStripVisibilityChanged;

  /// Called when a seek operation completes successfully.
  final Function(Duration position)? onSeekCompleted;

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
    this.trackControlsState = const TrackControlsState(),
    this.onBack,
    this.hasFirstFrame,
    this.thumbnailDataBuilder,
    this.liveChannelName,
    this.useDpadNavigation = false,
    this.serverId,
    this.showQueueTab = false,
    this.onQueueItemSelected,
    this.onCancelAutoHide,
    this.onStartAutoHide,
    this.onContentStripVisibilityChanged,
    this.onSeekCompleted,
  });

  @override
  State<DesktopVideoControls> createState() => DesktopVideoControlsState();
}

class DesktopVideoControlsState extends State<DesktopVideoControls> {
  TrackControlsState get _trackControlsState => widget.trackControlsState;
  bool get _canControl => _trackControlsState.canControl;
  bool get _isLive => _trackControlsState.isLive;

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

  // Content strip state
  bool _contentStripVisible = false;
  final GlobalKey<ContentStripState> _contentStripKey = GlobalKey<ContentStripState>();

  // Track which button was last focused (for returning from content strip)
  FocusNode? _lastFocusedButtonNode;

  /// Whether the content strip has any content to show
  bool get _hasStripContent {
    return widget.chapters.isNotEmpty || (widget.showQueueTab && widget.onQueueItemSelected != null);
  }

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

  /// Hide content strip (called by parent when controls hide)
  void hideContentStrip() {
    if (_contentStripVisible) {
      setState(() {
        _contentStripVisible = false;
      });
      widget.onContentStripVisibilityChanged?.call(false);
    }
  }

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

  /// Track the last focused button node for returning from content strip
  void _onButtonRowFocusChange(bool hasFocus) {
    if (hasFocus) {
      widget.onFocusActivity?.call();
      // Find which button or track control has focus
      for (final node in _buttonFocusNodes) {
        if (node.hasFocus) {
          _lastFocusedButtonNode = node;
          return;
        }
      }
      for (final node in _trackControlFocusNodes) {
        if (node.hasFocus) {
          _lastFocusedButtonNode = node;
          return;
        }
      }
      if (_volumeFocusNode.hasFocus) {
        _lastFocusedButtonNode = _volumeFocusNode;
      }
    }
  }

  void _showContentStrip() {
    if (!widget.useDpadNavigation || !_hasStripContent) return;
    if (_contentStripVisible) {
      // Already visible - focus into it
      _contentStripKey.currentState?.requestInitialFocus();
      return;
    }

    setState(() {
      _contentStripVisible = true;
    });
    widget.onContentStripVisibilityChanged?.call(true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _contentStripKey.currentState?.requestInitialFocus();
    });
  }

  void _onContentStripNavigateUp() {
    // Hide content strip and show normal controls again
    setState(() {
      _contentStripVisible = false;
    });
    widget.onContentStripVisibilityChanged?.call(false);

    // Return focus to the last focused button (or play/pause as fallback)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _lastFocusedButtonNode;
      if (target != null && target.context != null) {
        target.requestFocus();
      } else {
        _playPauseFocusNode.requestFocus();
      }
      widget.onFocusActivity?.call();
    });
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

    if (key == LogicalKeyboardKey.arrowDown) {
      if (widget.useDpadNavigation && _hasStripContent) {
        _showContentStrip();
        return KeyEventResult.handled;
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Handle key events for horizontal button navigation
  KeyEventResult _handleButtonKeyEvent(FocusNode _, KeyEvent event, int index) {
    final leftTarget = index > 0 ? _buttonFocusNodes[index - 1] : null;
    final rightTarget = index < _buttonFocusNodes.length - 1 ? _buttonFocusNodes[index + 1] : _volumeFocusNode;

    return _handleDirectionalNavigation(event, leftTarget: leftTarget, rightTarget: rightTarget);
  }

  /// Handle key events for volume control navigation
  KeyEventResult _handleVolumeKeyEvent(FocusNode _, KeyEvent event) {
    return _handleDirectionalNavigation(
      event,
      leftTarget: _nextItemFocusNode,
      rightTarget: _trackControlFocusNodes.isNotEmpty ? _trackControlFocusNodes.first : null,
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
  KeyEventResult _handleTimelineKeyEvent(FocusNode _, KeyEvent event) {
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
      if (!_canControl) return KeyEventResult.handled;

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
          builder: (context) => Expanded(
            child: Column(
              children: [
                const Spacer(),
                // When content strip is visible, hide the normal controls (like mobile)
                if (!_contentStripVisible)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildBottomControlsContent(context, hasFrame: true),
                      // Down arrow hint when strip content is available
                      if (widget.useDpadNavigation && _hasStripContent)
                        const Positioned(
                          left: 0,
                          right: 0,
                          bottom: 12,
                          child: Icon(Symbols.keyboard_arrow_down_rounded, color: Colors.white24, size: 24),
                        ),
                    ],
                  ),
                // Content strip (TV/dpad only) — replaces normal controls
                if (_contentStripVisible && widget.useDpadNavigation)
                  Container(
                    padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8, top: 32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        stops: const [0.0, 0.42, 1.0],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Symbols.keyboard_arrow_up_rounded, color: Colors.white38, size: 20),
                        const SizedBox(height: 4),
                        ContentStrip(
                          key: _contentStripKey,
                          player: widget.player,
                          chapters: widget.chapters,
                          chaptersLoaded: widget.chaptersLoaded,
                          serverId: widget.serverId,
                          showQueueTab: widget.showQueueTab,
                          onQueueItemSelected: widget.onQueueItemSelected,
                          onSeekCompleted: widget.onSeekCompleted,
                          useFocusNavigation: true,
                          onNavigateUp: _onContentStripNavigateUp,
                          onFocusActivity: widget.onFocusActivity,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext _) {
    // Use global fullscreen state for padding
    return ListenableBuilder(
      listenable: FullscreenStateManager(),
      builder: (context, _) {
        final isFullscreen = FullscreenStateManager().isFullscreen;
        // In fullscreen on macOS, use less left padding since traffic lights auto-hide
        // In normal mode on macOS, need more padding to avoid traffic lights
        double leftPadding;
        if (Platform.isMacOS) {
          leftPadding = isFullscreen ? DesktopWindowPadding.macOSLeftFullscreen : DesktopWindowPadding.macOSLeft;
        } else {
          leftPadding = DesktopWindowPadding.macOSLeftFullscreen;
        }

        return _buildTopBarContent(context, leftPadding);
      },
    );
  }

  Widget _buildTopBarContent(BuildContext _, double leftPadding) {
    final topBar = Padding(
      padding: EdgeInsets.only(left: leftPadding, right: 16),
      child: Row(
        children: [
          Expanded(
            child: VideoControlsHeader(
              metadata: widget.metadata,
              style: Platform.isMacOS ? VideoHeaderStyle.singleLine : VideoHeaderStyle.multiLine,
              onBack: widget.onBack,
            ),
          ),
          if (_isLive) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(color: Colors.red, borderRadius: BorderRadius.all(Radius.circular(4))),
              child: Text(
                t.liveTv.live,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );

    return DesktopAppBarHelper.wrapWithGestureDetector(topBar, opaque: true);
  }

  Widget _buildBottomControlsContent(BuildContext _, {required bool hasFrame}) {
    final canInteract = _canControl && hasFrame;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Row 1: Timeline with time indicators (hidden for live TV)
          if (!_isLive) ...[
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
              thumbnailDataBuilder: widget.thumbnailDataBuilder,
            ),
            const SizedBox(height: 4),
          ],
          // Row 2: Playback controls and options
          Focus(
            onFocusChange: _onButtonRowFocusChange,
            skipTraversal: true,
            child: Row(
              children: [
                if (!_isLive) ...[
                  // Previous item
                  Opacity(
                    opacity: _canControl ? 1.0 : 0.5,
                    child: _buildFocusableButton(
                      focusNode: _prevItemFocusNode,
                      index: 0,
                      icon: Symbols.skip_previous_rounded,
                      color: widget.onPrevious != null && _canControl ? Colors.white : Colors.white54,
                      onPressed: _canControl ? widget.onPrevious : null,
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
                        opacity: _canControl ? 1.0 : 0.5,
                        child: _buildFocusableButton(
                          focusNode: _prevChapterFocusNode,
                          index: 1,
                          icon: Symbols.fast_rewind_rounded,
                          color: widget.chapters.isNotEmpty && _canControl ? Colors.white : Colors.white54,
                          onPressed: _canControl && widget.chapters.isNotEmpty ? widget.onSeekToPreviousChapter : null,
                          semanticLabel: t.videoControls.previousChapterButton,
                          tooltip: prevLabel,
                        ),
                      );
                    },
                  ),
                  // Skip backward
                  Opacity(
                    opacity: _canControl ? 1.0 : 0.5,
                    child: _buildFocusableButton(
                      focusNode: _skipBackFocusNode,
                      index: 2,
                      icon: widget.getReplayIcon(widget.seekTimeSmall),
                      onPressed: _canControl ? widget.onSeekBackward : null,
                      semanticLabel: t.videoControls.seekBackwardButton(seconds: widget.seekTimeSmall),
                    ),
                  ),
                ],
                // Play/Pause
                Opacity(
                  opacity: _canControl ? 1.0 : 0.5,
                  child: PlayPauseStreamBuilder(
                    player: widget.player,
                    builder: (context, isPlaying) {
                      return _buildFocusableButton(
                        focusNode: _playPauseFocusNode,
                        index: 3,
                        icon: isPlaying ? Symbols.pause_rounded : Symbols.play_arrow_rounded,
                        iconSize: 32,
                        onPressed: _canControl
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
                if (!_isLive) ...[
                  // Skip forward
                  Opacity(
                    opacity: _canControl ? 1.0 : 0.5,
                    child: _buildFocusableButton(
                      focusNode: _skipForwardFocusNode,
                      index: 4,
                      icon: widget.getForwardIcon(widget.seekTimeSmall),
                      onPressed: _canControl ? widget.onSeekForward : null,
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
                        opacity: _canControl ? 1.0 : 0.5,
                        child: _buildFocusableButton(
                          focusNode: _nextChapterFocusNode,
                          index: 5,
                          icon: Symbols.fast_forward_rounded,
                          color: widget.chapters.isNotEmpty && _canControl ? Colors.white : Colors.white54,
                          onPressed: _canControl && widget.chapters.isNotEmpty ? widget.onSeekToNextChapter : null,
                          semanticLabel: t.videoControls.nextChapterButton,
                          tooltip: nextLabel,
                        ),
                      );
                    },
                  ),
                  // Next item
                  Opacity(
                    opacity: _canControl ? 1.0 : 0.5,
                    child: _buildFocusableButton(
                      focusNode: _nextItemFocusNode,
                      index: 6,
                      icon: Symbols.skip_next_rounded,
                      color: widget.onNext != null && _canControl ? Colors.white : Colors.white54,
                      onPressed: _canControl ? widget.onNext : null,
                      semanticLabel: t.videoControls.nextButton,
                    ),
                  ),
                ],
                // Finish time (hidden for live TV and when too narrow to fit)
                if (_isLive)
                  const Spacer()
                else
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

                                final text = t.videoControls.endsAt(
                                  time: formatFinishTime(
                                    remaining,
                                    rate: rate,
                                    is24Hour: MediaQuery.alwaysUse24HourFormatOf(context),
                                  ),
                                );
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
                  trackControlsState: _trackControlsState,
                  onSeekCompleted: widget.onSeekCompleted,
                  focusNodes: _trackControlFocusNodes,
                  onFocusChange: _onFocusChange,
                  onNavigateLeft: navigateFromTrackToVolume,
                  onNavigateUp: () {
                    _timelineFocusNode.requestFocus();
                    widget.onFocusActivity?.call();
                  },
                  onNavigateDown: () {
                    if (widget.useDpadNavigation && _hasStripContent) {
                      _showContentStrip();
                    }
                  },
                  hideChaptersAndQueue: widget.useDpadNavigation && _hasStripContent,
                ),
              ],
            ),
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
