import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plezy/utils/formatters.dart';

import '../../../media/media_item.dart';
import '../../../media/live_tv_timeline.dart';
import '../../../mpv/mpv.dart';
import '../../../i18n/strings.g.dart';
import '../../../watch_together/widgets/watch_together_overlay.dart';
import '../../../watch_together/providers/watch_together_provider.dart';
import '../../app_bar_back_button.dart';
import '../../system_clock.dart';

/// Header layout style for video controls
enum VideoHeaderStyle {
  /// Multi-line: Series name on first line, episode info on second line
  multiLine,

  /// Single-line: All info combined with separators (for macOS)
  singleLine,
}

/// Shared header widget for video controls with back button and title.
///
/// Displays the video title with optional series/episode information.
/// Supports both single-line (macOS) and multi-line (other platforms) layouts.
class VideoControlsHeader extends StatelessWidget {
  final MediaItem metadata;
  final VideoHeaderStyle style;

  /// Live TV resolves the header from the same snapshot as the timeline,
  /// including an explicitly requested seek preview.
  final Player? player;
  final LiveTvTimeline Function(Duration position)? liveTimelineForPosition;

  /// Optional trailing widget (e.g., track/chapter controls)
  final Widget? trailing;

  /// Optional callback for back button. If null, defaults to Navigator.pop(true).
  final VoidCallback? onBack;
  final VoidCallback? onCancelAutoHide;
  final VoidCallback? onStartAutoHide;

  /// Whether to show the system clock. Off for a portrait phone, where the
  /// header is too narrow to fit the clock beside the title and trailing
  /// controls.
  final bool showClock;

  const VideoControlsHeader({
    super.key,
    required this.metadata,
    this.style = VideoHeaderStyle.multiLine,
    this.player,
    this.liveTimelineForPosition,
    this.trailing,
    this.onBack,
    this.onCancelAutoHide,
    this.onStartAutoHide,
    this.showClock = true,
  }) : assert(liveTimelineForPosition == null || player != null);

  @override
  Widget build(BuildContext context) {
    final itemTitle = metadata.title ?? t.common.unknown;
    return Row(
      children: [
        AppBarBackButton(style: BackButtonStyle.video, onPressed: onBack ?? () => Navigator.of(context).pop(true)),
        const SizedBox(width: 16),
        Expanded(child: _buildTitle(itemTitle)),
        Selector<WatchTogetherProvider, bool>(
          selector: (_, p) => p.isInSession,
          builder: (context, inSession, child) {
            if (!inSession) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: WatchTogetherSessionIndicator(
                onCancelAutoHide: onCancelAutoHide,
                onStartAutoHide: onStartAutoHide,
              ),
            );
          },
        ),
        if (showClock)
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: SystemClock(
              style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: .w500),
            ),
          ),
        ?trailing,
      ],
    );
  }

  Widget _buildTitle(String itemTitle) {
    final timelineForPosition = liveTimelineForPosition;
    final livePlayer = player;
    if (timelineForPosition != null && livePlayer != null) {
      return StreamBuilder<Duration>(
        key: ObjectKey(livePlayer),
        stream: livePlayer.streams.position,
        initialData: livePlayer.state.position,
        builder: (context, snapshot) {
          final program = timelineForPosition(Duration(seconds: snapshot.requireData.inSeconds)).program;
          final parts = <String>[];
          if (program != null) {
            parts.add(program.displayTitle);
            final start = program.beginsAt;
            final end = program.endsAt;
            if (start != null && end != null && end > start) {
              parts.add(formatDurationTextual((end - start) * 1000));
            }
          }
          return _buildMultiLineTitle(itemTitle, parts);
        },
      );
    }
    if (style == VideoHeaderStyle.singleLine) return _buildSingleLineTitle(itemTitle);

    final parts = <String>[];
    if (metadata.parentIndex != null && metadata.index != null) {
      parts.add('S${metadata.parentIndex}');
      parts.add('E${metadata.index}');
      parts.add(itemTitle);
    }
    if (metadata.durationMs != null) parts.add(formatDurationTextual(metadata.durationMs!));
    return _buildMultiLineTitle(metadata.grandparentTitle ?? itemTitle, parts);
  }

  Widget _buildSingleLineTitle(String itemTitle) {
    final seriesName = metadata.grandparentTitle ?? itemTitle;
    final hasEpisodeInfo = metadata.parentIndex != null && metadata.index != null;

    final List<String> parts = [seriesName];

    if (hasEpisodeInfo) {
      parts.add('S${metadata.parentIndex}E${metadata.index}');
      parts.add(itemTitle);
    }

    return Text(
      toBulletedString(parts),
      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: .w500),
      maxLines: 1,
      overflow: .ellipsis,
    );
  }

  Widget _buildMultiLineTitle(String itemTitle, List<String> secondLineParts) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          itemTitle,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: .bold),
          maxLines: 1,
          overflow: .ellipsis,
        ),
        if (secondLineParts.isNotEmpty)
          Text(
            toBulletedString(secondLineParts),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            maxLines: 1,
            overflow: .ellipsis,
          ),
      ],
    );
  }
}
