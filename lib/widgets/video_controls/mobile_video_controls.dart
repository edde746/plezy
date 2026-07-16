import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../widgets/app_icon.dart';
import '../../media/media_item.dart';
import '../../mpv/mpv.dart';
import '../../models/livetv_capture_buffer.dart';
import '../../media/media_source_info.dart';
import '../../services/scrub_preview_source.dart';
import '../../utils/desktop_window_padding.dart';
import '../../i18n/strings.g.dart';
import 'player_chrome_controller.dart';
import 'widgets/circular_control_button.dart';
import 'widgets/content_strip.dart';
import 'widgets/first_frame_guard.dart';
import 'widgets/play_pause_stream_builder.dart';
import 'widgets/live_timeline_bar.dart';
import 'widgets/video_controls_header.dart';
import 'widgets/video_timeline_bar.dart';

/// Mobile video controls layout for Plex video player
///
/// Displays a full-screen overlay with:
/// - Top bar: Back button, title, and track/chapter controls
/// - Center: Large playback controls (seek backward, play/pause, seek forward)
/// - Bottom bar: Timeline slider with chapter markers and timestamps
///
/// When chapters or queue are available, the user can swipe up on the bottom
/// area to slide a content strip into view. The playback controls and timeline
/// fade out while the strip slides up — only the top bar stays fixed.
class MobileVideoControls extends StatefulWidget {
  final Player player;
  final MediaItem metadata;
  final List<MediaChapter> chapters;
  final bool chaptersLoaded;
  final bool showChapterMarkersOnTimeline;
  final int seekTimeSmall;
  final Widget trackChapterControls;
  final Function(Duration) onSeek;
  final Function(Duration) onSeekEnd;
  final VoidCallback? onScrubStart;
  final VoidCallback? onScrubEnd;
  final Future<void> Function(Duration position)? onSeekRequested;
  final Function(Duration)? onSeekCompleted;
  final VoidCallback onPlayPause;
  final VoidCallback? onCancelAutoHide;
  final VoidCallback? onStartAutoHide;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  /// Whether the user can control playback (false in host-only mode for non-host).
  final bool canControl;

  /// Notifier for whether first video frame has rendered (shows loading state when false).
  final ValueNotifier<bool>? hasFirstFrame;

  /// Optional callback that returns thumbnail image bytes for a given timestamp.
  final ScrubFrame? Function(Duration time)? thumbnailDataBuilder;

  /// Whether this is a live TV stream
  final bool isLive;

  /// Channel name for live TV display
  final String? liveChannelName;

  // Live TV time-shift
  final CaptureBuffer? captureBuffer;
  final bool isAtLiveEdge;
  final double streamStartEpoch;
  final ValueChanged<int>? onLiveSeek;

  /// Server ID for chapter thumbnails in the content strip
  final String? serverId;

  /// Whether to show the queue tab in the content strip
  final bool showQueueTab;

  /// Callback when a queue item is selected from the content strip
  final Function(MediaItem)? onQueueItemSelected;

  /// Shared controller for chrome visibility (used to reset strip on hide)
  final PlayerChromeController? chromeController;

  /// Called when the content strip visibility changes
  final ValueChanged<bool>? onStripVisibilityChanged;

  /// Returns true when a global touch position belongs to the parent edge-adjustment zone.
  final bool Function(Offset globalPosition)? isInEdgeAdjustmentZone;

  const MobileVideoControls({
    super.key,
    required this.player,
    required this.metadata,
    required this.chapters,
    required this.chaptersLoaded,
    this.showChapterMarkersOnTimeline = true,
    required this.seekTimeSmall,
    required this.trackChapterControls,
    required this.onSeek,
    required this.onSeekEnd,
    this.onScrubStart,
    this.onScrubEnd,
    required this.onPlayPause,
    this.onSeekRequested,
    this.onSeekCompleted,
    this.onCancelAutoHide,
    this.onStartAutoHide,
    this.onBack,
    this.onNext,
    this.onPrevious,
    this.canControl = true,
    this.hasFirstFrame,
    this.thumbnailDataBuilder,
    this.isLive = false,
    this.liveChannelName,
    this.captureBuffer,
    this.isAtLiveEdge = true,
    this.streamStartEpoch = 0,
    this.onLiveSeek,
    this.serverId,
    this.showQueueTab = false,
    this.onQueueItemSelected,
    this.chromeController,
    this.onStripVisibilityChanged,
    this.isInEdgeAdjustmentZone,
  });

  @override
  State<MobileVideoControls> createState() => _MobileVideoControlsState();
}

class _MobileVideoControlsState extends State<MobileVideoControls> with SingleTickerProviderStateMixin {
  late final AnimationController _stripAnim;
  bool _stripVisible = false;
  late bool _lastControlsVisible;
  bool _stripDragEnabled = true;

  /// Drag distance (in pixels) required to fully reveal the strip.
  static const _dragExtent = 150.0;

  bool get _hasStripContent =>
      widget.chapters.isNotEmpty || (widget.showQueueTab && widget.onQueueItemSelected != null);

  @override
  void initState() {
    super.initState();
    _stripAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _stripAnim.addListener(_onStripAnimChanged);
    _lastControlsVisible = widget.chromeController?.controlsVisible ?? true;
    widget.chromeController?.addListener(_onChromeVisibilityChanged);
  }

  @override
  void didUpdateWidget(MobileVideoControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chromeController != widget.chromeController) {
      oldWidget.chromeController?.removeListener(_onChromeVisibilityChanged);
      _lastControlsVisible = widget.chromeController?.controlsVisible ?? true;
      widget.chromeController?.addListener(_onChromeVisibilityChanged);
    }
  }

  @override
  void dispose() {
    widget.chromeController?.removeListener(_onChromeVisibilityChanged);
    _stripAnim.removeListener(_onStripAnimChanged);
    _stripAnim.dispose();
    super.dispose();
  }

  void _onStripAnimChanged() {
    final visible = _stripAnim.value > 0.5;
    if (visible != _stripVisible) {
      _stripVisible = visible;
      widget.onStripVisibilityChanged?.call(visible);
    }
  }

  void _onChromeVisibilityChanged() {
    final chromeController = widget.chromeController;
    final controlsVisible = chromeController?.controlsVisible ?? true;
    final wasControlsVisible = _lastControlsVisible;
    _lastControlsVisible = controlsVisible;

    if (chromeController?.contentStripVisible == false && _stripAnim.value > 0) {
      _stripAnim.reverse();
    }

    if (!controlsVisible && wasControlsVisible && _stripVisible) {
      // Just notify parent that strip is no longer active — don't animate,
      // let the overlay fade out with the strip still showing.
      _stripVisible = false;
      widget.onStripVisibilityChanged?.call(false);
    } else if (controlsVisible && !wasControlsVisible && _stripAnim.value > 0) {
      // Reset strip when controls reappear so page 0 is shown.
      _stripAnim.value = 0;
    }
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _stripDragEnabled = widget.isInEdgeAdjustmentZone?.call(details.globalPosition) != true;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_stripDragEnabled) return;
    // Negative primaryDelta = swipe up = reveal strip (increase value)
    _stripAnim.value -= (details.primaryDelta ?? 0) / _dragExtent;
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (!_stripDragEnabled) {
      _stripDragEnabled = true;
      return;
    }
    final velocity = details.primaryVelocity ?? 0;
    // Fast swipe up or past halfway without fast swipe down → show strip
    if (velocity < -200 || (_stripAnim.value > 0.5 && velocity < 200)) {
      _stripAnim.forward();
    } else {
      _stripAnim.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasStripContent) {
      return Column(
        children: [
          _buildTopBar(context),
          const Spacer(),
          _buildPlaybackControls(context),
          const Spacer(),
          _buildBottomBar(context),
        ],
      );
    }

    // Top bar stays fixed. Everything below it is a Stack where the controls
    // fade out and the content strip slides up from the bottom on swipe.
    return Column(
      children: [
        _buildTopBar(context),
        Expanded(
          child: GestureDetector(
            onVerticalDragStart: _onVerticalDragStart,
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
            behavior: HitTestBehavior.translucent,
            child: ListenableBuilder(
              listenable: _stripAnim,
              builder: (context, _) {
                final t = _stripAnim.value;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Normal controls — fade out as strip appears
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: t > 0.5,
                        child: Opacity(
                          opacity: (1 - t * 2).clamp(0.0, 1.0),
                          child: Stack(
                            children: [
                              Column(
                                children: [
                                  const Spacer(),
                                  _buildPlaybackControls(context),
                                  const Spacer(),
                                  _buildBottomBar(context),
                                ],
                              ),
                              const Positioned(
                                left: 0,
                                right: 0,
                                bottom: 12,
                                child: AppIcon(Symbols.keyboard_arrow_up_rounded, color: Colors.white24, size: 24),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Content strip — slides up from below the bottom edge
                    Align(
                      alignment: .bottomCenter,
                      child: FractionalTranslation(
                        translation: Offset(0, 1 - t),
                        child: IgnorePointer(
                          ignoring: t < 0.5,
                          child: Opacity(
                            opacity: (t * 2).clamp(0.0, 1.0),
                            child: Container(
                              padding: const EdgeInsets.only(top: 32),
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
                                mainAxisSize: .min,
                                children: [
                                  const AppIcon(Symbols.keyboard_arrow_down_rounded, color: Colors.white38, size: 20),
                                  const SizedBox(height: 4),
                                  ContentStrip(
                                    player: widget.player,
                                    chapters: widget.chapters,
                                    chaptersLoaded: widget.chaptersLoaded,
                                    serverId: widget.serverId,
                                    showQueueTab: widget.showQueueTab,
                                    onQueueItemSelected: widget.onQueueItemSelected,
                                    onSeekRequested: widget.onSeekRequested,
                                    onSeekCompleted: widget.onSeekCompleted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final topBar = _conditionalSafeArea(
      context: context,
      bottom: false, // Only respect top safe area when in portrait
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: VideoControlsHeader(
          metadata: widget.metadata,
          style: VideoHeaderStyle.multiLine,
          onCancelAutoHide: widget.onCancelAutoHide,
          onStartAutoHide: widget.onStartAutoHide,
          trailing: widget.trackChapterControls,
          onBack: widget.onBack,
        ),
      ),
    );

    return DesktopAppBarHelper.wrapWithGestureDetector(topBar, opaque: true);
  }

  Widget _buildPlaybackControls(BuildContext _) {
    // Hide all playback controls in host-only mode for non-host
    if (!widget.canControl) {
      return const SizedBox.shrink();
    }

    return FirstFrameGuard(
      hasFirstFrame: widget.hasFirstFrame,
      builder: (context) => _buildPlaybackControlsContent(context),
    );
  }

  Widget _buildPlaybackControlsContent(BuildContext _) {
    return PlayPauseStreamBuilder(
      player: widget.player,
      builder: (context, isPlaying) {
        return Row(
          mainAxisAlignment: .center,
          children: [
            if (!widget.isLive) ...[
              // Previous episode button (greyed out when unavailable)
              CircularControlButton(
                semanticLabel: t.videoControls.previousButton,
                icon: Symbols.skip_previous_rounded,
                iconSize: 48,
                onPressed: widget.onPrevious,
              ),
              const SizedBox(width: 24),
            ],
            CircularControlButton(
              semanticLabel: isPlaying ? t.videoControls.pauseButton : t.videoControls.playButton,
              icon: isPlaying ? Symbols.pause_rounded : Symbols.play_arrow_rounded,
              iconSize: 72,
              onPressed: () {
                if (isPlaying) {
                  widget.player.pause();
                  widget.onCancelAutoHide?.call(); // Cancel auto-hide when paused
                } else {
                  widget.player.play();
                  widget.onStartAutoHide?.call(); // Start auto-hide when playing
                }
              },
            ),
            if (!widget.isLive) ...[
              const SizedBox(width: 24),
              // Next episode button (greyed out when unavailable)
              CircularControlButton(
                semanticLabel: t.videoControls.nextButton,
                icon: Symbols.skip_next_rounded,
                iconSize: 48,
                onPressed: widget.onNext,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext _) {
    if (widget.isLive) {
      if (widget.captureBuffer != null) {
        // Live TV with time-shift: show seekable timeline
        return FirstFrameGuard(
          hasFirstFrame: widget.hasFirstFrame,
          builder: (context) => LiveTimelineBar(
            player: widget.player,
            captureBuffer: widget.captureBuffer!,
            streamStartEpoch: widget.streamStartEpoch,
            isAtLiveEdge: widget.isAtLiveEdge,
            onSeekEnd: widget.onLiveSeek,
            horizontalLayout: false,
            enabled: widget.canControl,
          ),
        );
      }
      // Fallback: static LIVE badge (no capture buffer)
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(color: Colors.red, borderRadius: BorderRadius.all(Radius.circular(4))),
              child: Text(
                t.liveTv.live,
                style: const TextStyle(color: Colors.white, fontWeight: .bold, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }
    return FirstFrameGuard(hasFirstFrame: widget.hasFirstFrame, builder: (context) => _buildBottomBarContent(context));
  }

  Widget _buildBottomBarContent(BuildContext context) {
    return _conditionalSafeArea(
      context: context,
      top: false, // Only respect bottom safe area when in portrait
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: VideoTimelineBar(
          player: widget.player,
          chapters: widget.chapters,
          chaptersLoaded: widget.chaptersLoaded,
          showChapterMarkersOnTimeline: widget.showChapterMarkersOnTimeline,
          onSeek: widget.onSeek,
          onSeekEnd: widget.onSeekEnd,
          onScrubStart: widget.onScrubStart,
          onScrubEnd: widget.onScrubEnd,
          horizontalLayout: false,
          enabled: widget.canControl,
          showFinishTime: true,
          thumbnailDataBuilder: widget.thumbnailDataBuilder,
        ),
      ),
    );
  }

  /// Conditionally wraps child with SafeArea only in portrait mode
  Widget _conditionalSafeArea({
    required BuildContext context,
    required Widget child,
    bool top = true,
    bool bottom = true,
  }) {
    final orientation = MediaQuery.orientationOf(context);
    final isPortrait = orientation == Orientation.portrait;

    // Only apply SafeArea in portrait mode
    if (isPortrait) {
      return SafeArea(top: top, bottom: bottom, child: child);
    }

    // In landscape, return child without SafeArea
    return child;
  }
}
