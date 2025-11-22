import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import '../../models/plex_media_info.dart';
import '../../models/plex_metadata.dart';
import '../../utils/duration_formatter.dart';
import '../../i18n/strings.g.dart';
import '../app_bar_back_button.dart';
import 'painters/chapter_marker_painter.dart';

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

  Widget _buildPlaybackControls(BuildContext context) {
    return StreamBuilder<bool>(
      stream: player.stream.playing,
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
                    _getReplayIcon(seekTimeSmall),
                    color: Colors.white,
                    size: 48,
                  ),
                  iconSize: 48,
                  onPressed: () {
                    _seekWithClamping(Duration(seconds: -seekTimeSmall));
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
                    _getForwardIcon(seekTimeSmall),
                    color: Colors.white,
                    size: 48,
                  ),
                  iconSize: 48,
                  onPressed: () {
                    _seekWithClamping(Duration(seconds: seekTimeSmall));
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
          stream: player.stream.position,
          initialData: player.state.position,
          builder: (context, positionSnapshot) {
            return StreamBuilder<Duration>(
              stream: player.stream.duration,
              initialData: player.state.duration,
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

  Widget _buildTimelineWithChapters({
    required Duration position,
    required Duration duration,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Chapter markers layer
        if (chaptersLoaded &&
            chapters.isNotEmpty &&
            duration.inMilliseconds > 0)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children:
                    chapters.map((chapter) {
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
                            chapters.fold<int>(
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
        Semantics(
          label: t.videoControls.timelineSlider,
          slider: true,
          child: Slider(
            value: duration.inMilliseconds > 0
                ? position.inMilliseconds.toDouble()
                : 0.0,
            min: 0.0,
            max: duration.inMilliseconds.toDouble(),
            onChanged: (value) {
              onSeek(Duration(milliseconds: value.toInt()));
            },
            onChangeEnd: (value) {
              onSeekEnd(Duration(milliseconds: value.toInt()));
            },
            activeColor: Colors.white,
            inactiveColor: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        // Chapter marker indicators
        if (chaptersLoaded &&
            chapters.isNotEmpty &&
            duration.inMilliseconds > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: CustomPaint(
                  painter: ChapterMarkerPainter(
                    chapters: chapters,
                    duration: duration,
                  ),
                ),
              ),
            ),
          ),
      ],
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

  void _seekWithClamping(Duration offset) {
    final currentPosition = player.state.position;
    final duration = player.state.duration;
    final newPosition = currentPosition + offset;

    // Clamp between 0 and video duration
    final clampedPosition = newPosition.isNegative
        ? Duration.zero
        : (newPosition > duration ? duration : newPosition);

    player.seek(clampedPosition);
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
}
