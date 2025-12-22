import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../mpv/mpv.dart';
import '../../models/plex_media_info.dart';
import '../../models/plex_metadata.dart';
import '../../utils/desktop_window_padding.dart';
import '../../utils/player_utils.dart';
import 'icons.dart';
import '../../i18n/strings.g.dart';
import 'widgets/video_controls_header.dart';
import 'widgets/video_timeline_bar.dart';

/// Mobile video controls layout for Plex video player
///
/// Displays a full-screen overlay with:
/// - Top bar: Back button, title, and track/chapter controls
/// - Center: Large playback controls (seek backward, play/pause, seek forward)
/// - Bottom bar: Timeline slider with chapter markers and timestamps
class MobileVideoControls extends StatelessWidget {
  final Player player;
  final PlexMetadata metadata;
  final List<PlexChapter> chapters;
  final bool chaptersLoaded;
  final int seekTimeSmall;
  final Widget trackChapterControls;
  final Function(Duration) onSeek;
  final Function(Duration) onSeekEnd;
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

  const MobileVideoControls({
    super.key,
    required this.player,
    required this.metadata,
    required this.chapters,
    required this.chaptersLoaded,
    required this.seekTimeSmall,
    required this.trackChapterControls,
    required this.onSeek,
    required this.onSeekEnd,
    required this.onPlayPause,
    this.onSeekCompleted,
    this.onCancelAutoHide,
    this.onStartAutoHide,
    this.onBack,
    this.onNext,
    this.onPrevious,
    this.canControl = true,
    this.hasFirstFrame,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top bar with back button and track/chapter controls
        _buildTopBar(context),
        const Spacer(),
        // Centered large playback controls
        _buildPlaybackControls(context),
        const Spacer(),
        // Progress bar at bottom
        _buildBottomBar(context),
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
          metadata: metadata,
          style: VideoHeaderStyle.multiLine,
          trailing: trackChapterControls,
          onBack: onBack,
        ),
      ),
    );

    return DesktopAppBarHelper.wrapWithGestureDetector(topBar, opaque: true);
  }

  Widget _buildPlaybackControls(BuildContext context) {
    // Hide all playback controls in host-only mode for non-host
    if (!canControl) {
      return const SizedBox.shrink();
    }

    // Check if we're still loading first frame
    final hasFirstFrameNotifier = hasFirstFrame;
    if (hasFirstFrameNotifier != null) {
      return ValueListenableBuilder<bool>(
        valueListenable: hasFirstFrameNotifier,
        builder: (context, hasFrame, child) {
          if (!hasFrame) {
            // Empty space, spinner shown by video_player_screen
            return const SizedBox.shrink();
          }
          return _buildPlaybackControlsContent(context);
        },
      );
    }
    return _buildPlaybackControlsContent(context);
  }

  Widget _buildPlaybackControlsContent(BuildContext context) {
    return StreamBuilder<bool>(
      stream: player.streams.playing,
      initialData: player.state.playing,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Previous episode button (hidden when unavailable)
            if (onPrevious != null) ...[
              _buildCircularButton(
                semanticLabel: t.videoControls.previousButton,
                icon: Symbols.skip_previous_rounded,
                iconSize: 48,
                onPressed: onPrevious!,
              ),
              const SizedBox(width: 16),
            ],
            _buildCircularButton(
              semanticLabel: t.videoControls.seekBackwardButton(seconds: seekTimeSmall),
              icon: getReplayIcon(seekTimeSmall),
              iconSize: 48,
              onPressed: () {
                final newPosition = seekWithClamping(player, Duration(seconds: -seekTimeSmall));
                onSeekCompleted?.call(newPosition);
              },
            ),
            const SizedBox(width: 48),
            _buildCircularButton(
              semanticLabel: isPlaying ? t.videoControls.pauseButton : t.videoControls.playButton,
              icon: isPlaying ? Symbols.pause_rounded : Symbols.play_arrow_rounded,
              iconSize: 72,
              onPressed: () {
                if (isPlaying) {
                  player.pause();
                  onCancelAutoHide?.call(); // Cancel auto-hide when paused
                } else {
                  player.play();
                  onStartAutoHide?.call(); // Start auto-hide when playing
                }
              },
            ),
            const SizedBox(width: 48),
            _buildCircularButton(
              semanticLabel: t.videoControls.seekForwardButton(seconds: seekTimeSmall),
              icon: getForwardIcon(seekTimeSmall),
              iconSize: 48,
              onPressed: () {
                final newPosition = seekWithClamping(player, Duration(seconds: seekTimeSmall));
                onSeekCompleted?.call(newPosition);
              },
            ),
            // Next episode button (hidden when unavailable)
            if (onNext != null) ...[
              const SizedBox(width: 16),
              _buildCircularButton(
                semanticLabel: t.videoControls.nextButton,
                icon: Symbols.skip_next_rounded,
                iconSize: 48,
                onPressed: onNext!,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    // Check if we're still loading first frame
    final hasFirstFrameNotifier = hasFirstFrame;
    if (hasFirstFrameNotifier != null) {
      return ValueListenableBuilder<bool>(
        valueListenable: hasFirstFrameNotifier,
        builder: (context, hasFrame, child) {
          if (!hasFrame) {
            // Hide timeline while loading
            return const SizedBox.shrink();
          }
          return _buildBottomBarContent(context);
        },
      );
    }
    return _buildBottomBarContent(context);
  }

  Widget _buildBottomBarContent(BuildContext context) {
    return _conditionalSafeArea(
      context: context,
      top: false, // Only respect bottom safe area when in portrait
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: VideoTimelineBar(
          player: player,
          chapters: chapters,
          chaptersLoaded: chaptersLoaded,
          onSeek: onSeek,
          onSeekEnd: onSeekEnd,
          horizontalLayout: false,
          enabled: canControl,
        ),
      ),
    );
  }

  Widget _buildCircularButton({
    required String semanticLabel,
    required IconData icon,
    required double iconSize,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
      child: Semantics(
        label: semanticLabel,
        button: true,
        excludeSemantics: true,
        child: IconButton(
          icon: AppIcon(icon, fill: 1, color: Colors.white, size: iconSize),
          iconSize: iconSize,
          onPressed: onPressed,
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
    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;

    // Only apply SafeArea in portrait mode
    if (isPortrait) {
      return SafeArea(top: top, bottom: bottom, child: child);
    }

    // In landscape, return child without SafeArea
    return child;
  }
}
