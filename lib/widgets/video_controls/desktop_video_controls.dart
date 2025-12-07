import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import '../../mpv/mpv.dart';
import '../../models/plex_media_info.dart';
import '../../models/plex_metadata.dart';
import '../../services/fullscreen_state_manager.dart';
import '../../utils/desktop_window_padding.dart';
import '../../i18n/strings.g.dart';
import 'widgets/video_controls_header.dart';
import 'widgets/video_timeline_bar.dart';

/// Desktop-specific video controls layout with top bar and bottom controls
class DesktopVideoControls extends StatelessWidget {
  final Player player;
  final PlexMetadata metadata;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final List<PlexChapter> chapters;
  final bool chaptersLoaded;
  final int seekTimeSmall;
  final VoidCallback onSeekToPreviousChapter;
  final VoidCallback onSeekToNextChapter;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<Duration> onSeekEnd;
  final Widget volumeControl;
  final Widget trackChapterControls;
  final IconData Function(int) getReplayIcon;
  final IconData Function(int) getForwardIcon;

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
    required this.onSeek,
    required this.onSeekEnd,
    required this.volumeControl,
    required this.trackChapterControls,
    required this.getReplayIcon,
    required this.getForwardIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top bar with back button and title
        _buildTopBar(context),
        const Spacer(),
        // Bottom controls
        _buildBottomControls(context),
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
        final leftPadding = Platform.isMacOS
            ? (isFullscreen
                  ? DesktopWindowPadding.macOSLeftFullscreen
                  : DesktopWindowPadding.macOSLeft)
            : DesktopWindowPadding.macOSLeftFullscreen;

        return _buildTopBarContent(context, leftPadding);
      },
    );
  }

  Widget _buildTopBarContent(BuildContext context, double leftPadding) {
    final topBar = Padding(
      padding: EdgeInsets.only(left: leftPadding, right: 16),
      child: VideoControlsHeader(
        metadata: metadata,
        style: Platform.isMacOS
            ? VideoHeaderStyle.singleLine
            : VideoHeaderStyle.multiLine,
      ),
    );

    return DesktopAppBarHelper.wrapWithGestureDetector(topBar, opaque: true);
  }

  Widget _buildBottomControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Row 1: Timeline with time indicators
          VideoTimelineBar(
            player: player,
            chapters: chapters,
            chaptersLoaded: chaptersLoaded,
            onSeek: onSeek,
            onSeekEnd: onSeekEnd,
            horizontalLayout: true,
          ),
          const SizedBox(height: 4),
          // Row 2: Playback controls and options
          Row(
            children: [
              // Previous item
              Semantics(
                label: t.videoControls.previousButton,
                button: true,
                excludeSemantics: true,
                child: IconButton(
                  icon: Icon(
                    Icons.skip_previous,
                    color: onPrevious != null ? Colors.white : Colors.white54,
                  ),
                  onPressed: onPrevious,
                ),
              ),
              // Previous chapter (or skip backward if no chapters)
              Semantics(
                label: chapters.isEmpty
                    ? t.videoControls.seekBackwardButton(seconds: seekTimeSmall)
                    : t.videoControls.previousChapterButton,
                button: true,
                excludeSemantics: true,
                child: IconButton(
                  icon: Icon(
                    chapters.isEmpty
                        ? getReplayIcon(seekTimeSmall)
                        : Icons.fast_rewind,
                    color: Colors.white,
                  ),
                  onPressed: onSeekToPreviousChapter,
                ),
              ),
              // Play/Pause
              StreamBuilder<bool>(
                stream: player.streams.playing,
                initialData: player.state.playing,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data ?? false;
                  return Semantics(
                    label: isPlaying
                        ? t.videoControls.pauseButton
                        : t.videoControls.playButton,
                    button: true,
                    excludeSemantics: true,
                    child: IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                      iconSize: 32,
                      onPressed: () {
                        if (isPlaying) {
                          player.pause();
                        } else {
                          player.play();
                        }
                      },
                    ),
                  );
                },
              ),
              // Next chapter (or skip forward if no chapters)
              Semantics(
                label: chapters.isEmpty
                    ? t.videoControls.seekForwardButton(seconds: seekTimeSmall)
                    : t.videoControls.nextChapterButton,
                button: true,
                excludeSemantics: true,
                child: IconButton(
                  icon: Icon(
                    chapters.isEmpty
                        ? getForwardIcon(seekTimeSmall)
                        : Icons.fast_forward,
                    color: Colors.white,
                  ),
                  onPressed: onSeekToNextChapter,
                ),
              ),
              // Next item
              Semantics(
                label: t.videoControls.nextButton,
                button: true,
                excludeSemantics: true,
                child: IconButton(
                  icon: Icon(
                    Icons.skip_next,
                    color: onNext != null ? Colors.white : Colors.white54,
                  ),
                  onPressed: onNext,
                ),
              ),
              const Spacer(),
              // Volume control
              volumeControl,
              const SizedBox(width: 16),
              // Audio track, subtitle, and chapter controls
              trackChapterControls,
            ],
          ),
        ],
      ),
    );
  }
}
