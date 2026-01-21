import 'package:flutter/material.dart';
import 'package:plezy/utils/formatters.dart';

import '../../../models/plex_metadata.dart';
import '../../../i18n/strings.g.dart';
import '../../app_bar_back_button.dart';

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
  final PlexMetadata metadata;
  final VideoHeaderStyle style;

  /// Optional trailing widget (e.g., track/chapter controls)
  final Widget? trailing;

  /// Optional callback for back button. If null, defaults to Navigator.pop(true).
  final VoidCallback? onBack;

  const VideoControlsHeader({
    super.key,
    required this.metadata,
    this.style = VideoHeaderStyle.multiLine,
    this.trailing,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppBarBackButton(
          style: BackButtonStyle.video,
          semanticLabel: t.videoControls.backButton,
          onPressed: onBack ?? () => Navigator.of(context).pop(true),
        ),
        const SizedBox(width: 16),
        Expanded(child: style == VideoHeaderStyle.singleLine ? _buildSingleLineTitle() : _buildMultiLineTitle()),
        if (trailing != null) trailing!,
      ],
    );
  }

  Widget _buildSingleLineTitle() {
    // Build single-line title combining series and episode info
    final seriesName = metadata.grandparentTitle ?? metadata.title;
    final hasEpisodeInfo = metadata.parentIndex != null && metadata.index != null;

    List<String> parts = [seriesName];

    if (hasEpisodeInfo) {
      parts.add('S${metadata.parentIndex}');
      parts.add('E${metadata.index}');
    }

    if (metadata.duration != null) {
      parts.add(formatDurationTextual(metadata.duration!));
    }

    if (!hasEpisodeInfo && metadata.year != null) {
      parts.add(metadata.year.toString());
    }

    if (hasEpisodeInfo && metadata.originallyAvailableAt != null) {
      parts.add(formatFullDate(metadata.originallyAvailableAt!));
    }

    return Text(
      toBulletedString(parts),
      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMultiLineTitle() {
    final hasEpisodeInfo = metadata.parentIndex != null && metadata.index != null;

    List<String> secondLineParts = [];

    if (hasEpisodeInfo) {
      secondLineParts.add('S${metadata.parentIndex}');
      secondLineParts.add('E${metadata.index}');
      secondLineParts.add(metadata.title);
    }

    if (metadata.duration != null) {
      secondLineParts.add(formatDurationTextual(metadata.duration!));
    }

    if (!hasEpisodeInfo && metadata.year != null) {
      secondLineParts.add(metadata.year.toString());
    }

    if (hasEpisodeInfo && metadata.originallyAvailableAt != null) {
      secondLineParts.add(formatFullDate(metadata.originallyAvailableAt!));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          metadata.grandparentTitle ?? metadata.title,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (secondLineParts.isNotEmpty)
          Text(
            toBulletedString(secondLineParts),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
