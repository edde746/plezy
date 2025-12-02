import 'package:flutter/material.dart';

import '../../mpv/mpv.dart';
import '../../models/plex_media_info.dart';
import '../../models/plex_metadata.dart';
import '../../utils/desktop_window_padding.dart';
import '../../utils/duration_formatter.dart';
import '../../utils/player_utils.dart';
import '../../utils/video_control_icons.dart';
import '../../i18n/strings.g.dart';
import '../app_bar_back_button.dart';
import 'widgets/timeline_slider.dart';

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
  final VoidCallback onPlayPause;
  final VoidCallback? onCancelAutoHide;
  final VoidCallback? onStartAutoHide;

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
    this.onCancelAutoHide,
    this.onStartAutoHide,
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
        child: Row(
          children: [
            AppBarBackButton(
              style: BackButtonStyle.video,
              semanticLabel: t.videoControls.backButton,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metadata.grandparentTitle ?? metadata.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (metadata.parentIndex != null && metadata.index != null)
                    Text(
                      'S${metadata.parentIndex} · E${metadata.index} · ${metadata.title}',
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
            trackChapterControls,
          ],
        ),
      ),
    );

    return DesktopAppBarHelper.wrapWithGestureDetector(topBar, opaque: true);
  }

  Widget _buildPlaybackControls(BuildContext context) {
    return StreamBuilder<bool>(
      stream: player.streams.playing,
      initialData: player.state.playing,
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
              child: Semantics(
                label: t.videoControls.seekBackwardButton(
                  seconds: seekTimeSmall,
                ),
                button: true,
                excludeSemantics: true,
                child: IconButton(
                  icon: Icon(
                    getReplayIcon(seekTimeSmall),
                    color: Colors.white,
                    size: 48,
                  ),
                  iconSize: 48,
                  onPressed: () {
                    seekWithClamping(player, Duration(seconds: -seekTimeSmall));
                  },
                ),
              ),
            ),
            const SizedBox(width: 48),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Semantics(
                label: isPlaying
                    ? t.videoControls.pauseButton
                    : t.videoControls.playButton,
                button: true,
                excludeSemantics: true,
                child: IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 72,
                  ),
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
              ),
            ),
            const SizedBox(width: 48),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Semantics(
                label: t.videoControls.seekForwardButton(
                  seconds: seekTimeSmall,
                ),
                button: true,
                excludeSemantics: true,
                child: IconButton(
                  icon: Icon(
                    getForwardIcon(seekTimeSmall),
                    color: Colors.white,
                    size: 48,
                  ),
                  iconSize: 48,
                  onPressed: () {
                    seekWithClamping(player, Duration(seconds: seekTimeSmall));
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return _conditionalSafeArea(
      context: context,
      top: false, // Only respect bottom safe area when in portrait
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<Duration>(
          stream: player.streams.position,
          initialData: player.state.position,
          builder: (context, positionSnapshot) {
            return StreamBuilder<Duration>(
              stream: player.streams.duration,
              initialData: player.state.duration,
              builder: (context, durationSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;
                final duration = durationSnapshot.data ?? Duration.zero;

                return Column(
                  children: [
                    TimelineSlider(
                      position: position,
                      duration: duration,
                      chapters: chapters,
                      chaptersLoaded: chaptersLoaded,
                      onSeek: onSeek,
                      onSeekEnd: onSeekEnd,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formatDurationTimestamp(position),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            formatDurationTimestamp(duration),
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
