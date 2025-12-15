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
        child: VideoControlsHeader(
          metadata: metadata,
          style: VideoHeaderStyle.multiLine,
          trailing: trackChapterControls,
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
            _buildCircularButton(
              semanticLabel: t.videoControls.seekBackwardButton(seconds: seekTimeSmall),
              icon: getReplayIcon(seekTimeSmall),
              iconSize: 48,
              onPressed: () {
                seekWithClamping(player, Duration(seconds: -seekTimeSmall));
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
                seekWithClamping(player, Duration(seconds: seekTimeSmall));
              },
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
        child: VideoTimelineBar(
          player: player,
          chapters: chapters,
          chaptersLoaded: chaptersLoaded,
          onSeek: onSeek,
          onSeekEnd: onSeekEnd,
          horizontalLayout: false,
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
