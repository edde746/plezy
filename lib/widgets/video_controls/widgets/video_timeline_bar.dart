import 'package:flutter/material.dart';

import '../../../mpv/mpv.dart';
import '../../../models/plex_media_info.dart';
import '../../../utils/formatters.dart';
import 'timeline_slider.dart';

/// Encapsulates the StreamBuilder stack for video timeline with timestamps.
///
/// This widget listens to player position and duration streams, and displays
/// a timeline slider with formatted timestamps. Supports both horizontal
/// layout (timestamps beside slider) and vertical layout (timestamps below slider).
class VideoTimelineBar extends StatelessWidget {
  final Player player;
  final List<PlexChapter> chapters;
  final bool chaptersLoaded;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<Duration> onSeekEnd;

  /// If true, timestamps are shown in a row beside the slider (desktop layout).
  /// If false, timestamps are shown in a row below the slider (mobile layout).
  final bool horizontalLayout;

  /// Optional FocusNode for D-pad/keyboard navigation.
  final FocusNode? focusNode;

  /// Custom key event handler for focus navigation.
  final KeyEventResult Function(FocusNode, KeyEvent)? onKeyEvent;

  /// Called when focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// Whether the timeline is enabled for interaction.
  final bool enabled;

  /// Whether to show the estimated finish time next to the remaining timestamp (mobile).
  final bool showFinishTime;

  const VideoTimelineBar({
    super.key,
    required this.player,
    required this.chapters,
    required this.chaptersLoaded,
    required this.onSeek,
    required this.onSeekEnd,
    this.horizontalLayout = true,
    this.focusNode,
    this.onKeyEvent,
    this.onFocusChange,
    this.enabled = true,
    this.showFinishTime = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: player.streams.position,
      initialData: player.state.position,
      builder: (context, positionSnapshot) {
        return StreamBuilder<Duration>(
          stream: player.streams.duration,
          initialData: player.state.duration,
          builder: (context, durationSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final duration = durationSnapshot.data ?? Duration.zero;
            final remaining = position - duration; // We want this to be negative

            if (horizontalLayout) {
              return _buildHorizontalLayout(position, duration, remaining);
            } else {
              return _buildVerticalLayout(position, duration, remaining);
            }
          },
        );
      },
    );
  }

  Widget _buildHorizontalLayout(Duration position, Duration duration, Duration remaining) {
    return Row(
      children: [
        _buildTimestamp(position),
        const SizedBox(width: 12),
        Expanded(child: _buildSlider(position, duration)),
        const SizedBox(width: 12),
        _buildTimestamp(remaining),
      ],
    );
  }

  Widget _buildVerticalLayout(Duration position, Duration duration, Duration remaining) {
    return Column(
      children: [
        _buildSlider(position, duration),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_buildTimestamp(position), _buildRemainingTimestamp(remaining)],
          ),
        ),
      ],
    );
  }

  Widget _buildTimestamp(Duration time) {
    return Text(formatDurationTimestamp(time), style: const TextStyle(color: Colors.white, fontSize: 14));
  }

  Widget _buildRemainingTimestamp(Duration remaining) {
    if (!showFinishTime || remaining.inSeconds >= 0) {
      return _buildTimestamp(remaining);
    }
    final text = '${formatDurationTimestamp(remaining)} · ${formatFinishTime(remaining.abs())}';
    return Text(text, style: const TextStyle(color: Colors.white, fontSize: 14));
  }

  Widget _buildSlider(Duration position, Duration duration) {
    return TimelineSlider(
      position: position,
      duration: duration,
      chapters: chapters,
      chaptersLoaded: chaptersLoaded,
      onSeek: onSeek,
      onSeekEnd: onSeekEnd,
      focusNode: focusNode,
      onKeyEvent: onKeyEvent,
      onFocusChange: onFocusChange,
      enabled: enabled,
    );
  }
}
