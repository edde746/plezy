import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../focus/focusable_button.dart';
import '../../focus/focusable_wrapper.dart';
import '../../models/plex_metadata.dart';
import '../../providers/settings_provider.dart';
import '../../services/settings_service.dart' show EpisodePosterMode;
import '../../utils/content_utils.dart';
import '../../utils/formatters.dart';
import '../../utils/provider_extensions.dart';
import '../../widgets/media_progress_bar.dart';
import '../../widgets/plex_optimized_image.dart';
import '../../theme/mono_tokens.dart';
import '../../i18n/strings.g.dart';

/// Individual item in the folder tree
/// Can be either a folder (expandable) or a file (tappable)
class FolderTreeItem extends StatelessWidget {
  final PlexMetadata item;
  final int depth;
  final bool isExpanded;
  final bool isFolder;
  final VoidCallback? onTap;
  final VoidCallback? onExpand;
  final VoidCallback? onPlayAll;
  final VoidCallback? onShuffle;
  final bool isLoading;
  final FocusNode? focusNode;
  final VoidCallback? onNavigateUp;
  final String? serverId;

  const FolderTreeItem({
    super.key,
    required this.item,
    required this.depth,
    this.isExpanded = false,
    this.isFolder = false,
    this.onTap,
    this.onExpand,
    this.onPlayAll,
    this.onShuffle,
    this.isLoading = false,
    this.focusNode,
    this.onNavigateUp,
    this.serverId,
  });

  IconData _getIcon() {
    if (isFolder) {
      return Symbols.folder_rounded;
    }

    return switch (item.mediaType) {
      PlexMediaType.movie => Symbols.movie_rounded,
      PlexMediaType.show => Symbols.tv_rounded,
      PlexMediaType.season => Symbols.video_library_rounded,
      PlexMediaType.episode => Symbols.play_circle_rounded,
      PlexMediaType.collection => Symbols.collections_rounded,
      _ => Symbols.insert_drive_file_rounded,
    };
  }

  void _handleTap() {
    if (isFolder) {
      onExpand?.call();
    } else {
      onTap?.call();
    }
  }

  String? _buildSubtitle() {
    if (item.isEpisode) {
      final parts = <String>[];
      if (item.parentIndex != null && item.index != null) {
        parts.add('S${item.parentIndex} E${item.index}');
      }
      if (item.title != null && item.title!.isNotEmpty) {
        parts.add(item.title!);
      }
      return parts.isNotEmpty ? parts.join(' · ') : null;
    }
    if (item.isSeason) {
      return item.displaySubtitle;
    }
    return item.displaySubtitle;
  }

  String _buildMetadataLine() {
    final parts = <String>[];

    if (item.contentRating != null && item.contentRating!.isNotEmpty) {
      parts.add(item.contentRating!);
    }
    if (item.year != null) {
      parts.add(item.year.toString());
    }
    if (item.duration != null && item.duration! > 0) {
      parts.add(formatDurationTextual(item.duration!));
    }
    if (item.rating != null) {
      parts.add('★ ${item.rating!.toStringAsFixed(1)}');
    }

    return parts.join(' · ');
  }

  Widget _buildFolderRow(BuildContext context) {
    final indentation = depth * 24.0;
    final expandIcon = isExpanded ? Symbols.keyboard_arrow_down_rounded : Symbols.keyboard_arrow_right_rounded;

    return Container(
      padding: EdgeInsets.only(left: 16.0 + indentation, right: 8.0, top: 8.0, bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: isLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : AppIcon(expandIcon, fill: 1, size: 20),
          ),
          const SizedBox(width: 8),
          AppIcon(_getIcon(), fill: 1, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.displayTitle,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaRow(BuildContext context) {
    final indentation = depth * 24.0;
    final episodePosterMode = context.select<SettingsProvider, EpisodePosterMode>((s) => s.episodePosterMode);
    final hideSpoilers = context.select<SettingsProvider, bool>((s) => s.hideSpoilers);
    final showUnwatchedCount = context.select<SettingsProvider, bool>((s) => s.showUnwatchedCount);

    final isWide = item.usesWideAspectRatio(episodePosterMode);
    final thumbWidth = isWide ? 130.0 : 53.0;
    final thumbHeight = isWide ? 73.0 : 80.0;

    final subtitle = _buildSubtitle();
    final metadataLine = _buildMetadataLine();

    return Container(
      padding: EdgeInsets.only(left: 16.0 + indentation, right: 16.0, top: 6.0, bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail with progress overlay
          SizedBox(
            width: thumbWidth,
            height: thumbHeight,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: _buildThumbnail(context, episodePosterMode, hideSpoilers, thumbWidth, thumbHeight),
                ),
                // Watch progress overlay
                _buildWatchOverlay(context, showUnwatchedCount),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Metadata column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.displayTitle,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: tokens(context).textMuted.withValues(alpha: 0.85),
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (metadataLine.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    metadataLine,
                    style: TextStyle(
                      fontSize: 10,
                      color: tokens(context).textMuted.withValues(alpha: 0.7),
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(
    BuildContext context,
    EpisodePosterMode episodePosterMode,
    bool hideSpoilers,
    double width,
    double height,
  ) {
    final posterUrl = item.posterThumb(mode: episodePosterMode);
    final client = serverId != null ? context.getClientForServer(serverId!) : null;
    final shouldBlur =
        hideSpoilers && item.shouldHideSpoiler && episodePosterMode == EpisodePosterMode.episodeThumbnail;

    Widget image;
    if (item.usesWideAspectRatio(episodePosterMode)) {
      image = PlexOptimizedImage.thumb(
        client: client,
        imagePath: posterUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    } else {
      image = PlexOptimizedImage.poster(
        client: client,
        imagePath: posterUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    }

    if (shouldBlur) {
      return ClipRect(
        child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: image),
      );
    }
    return image;
  }

  Widget _buildWatchOverlay(BuildContext context, bool showUnwatchedCount) {
    final hasActiveProgress =
        item.viewOffset != null && item.duration != null && item.viewOffset! > 0 && item.viewOffset! < item.duration!;

    return Stack(
      children: [
        // Watched checkmark
        if (item.isWatched && !hasActiveProgress)
          Positioned(
            top: 3,
            right: 3,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: tokens(context).text,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
              ),
              child: AppIcon(Symbols.check_rounded, fill: 1, color: tokens(context).bg, size: 12),
            ),
          ),
        // Unwatched count for shows/seasons
        if (showUnwatchedCount &&
            !item.isWatched &&
            (item.mediaType == PlexMediaType.show || item.mediaType == PlexMediaType.season) &&
            (item.leafCount != null && item.leafCount! > 0 && item.viewedLeafCount != null))
          Positioned(
            top: 3,
            right: 3,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: tokens(context).text,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
              ),
              alignment: Alignment.center,
              child: Text(
                '${item.leafCount! - item.viewedLeafCount!}',
                style: TextStyle(color: tokens(context).bg, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        // Progress bar
        if (hasActiveProgress)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(6), bottomRight: Radius.circular(6)),
              child: MediaProgressBar(viewOffset: item.viewOffset!, duration: item.duration!),
            ),
          ),
        // Season progress
        if (item.isSeason && item.isPartiallyWatched)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(6), bottomRight: Radius.circular(6)),
              child: LinearProgressIndicator(
                value: item.viewedLeafCount! / item.leafCount!,
                backgroundColor: tokens(context).outline,
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                minHeight: 3,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rowContent = isFolder ? _buildFolderRow(context) : _buildMediaRow(context);

    return Row(
      children: [
        // Main item row
        Expanded(
          child: FocusableWrapper(
            focusNode: focusNode,
            onSelect: _handleTap,
            onNavigateUp: onNavigateUp,
            useBackgroundFocus: true,
            disableScale: true,
            descendantsAreFocusable: false,
            child: GestureDetector(onTap: _handleTap, behavior: HitTestBehavior.opaque, child: rowContent),
          ),
        ),

        // Play/Shuffle buttons for folders
        if (isFolder) ...[
          FocusableButton(
            useBackgroundFocus: true,
            onPressed: onPlayAll,
            child: IconButton(
              onPressed: onPlayAll,
              icon: AppIcon(
                Symbols.play_arrow_rounded,
                fill: 1,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              tooltip: t.common.play,
              iconSize: 18,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
          FocusableButton(
            useBackgroundFocus: true,
            onPressed: onShuffle,
            child: IconButton(
              onPressed: onShuffle,
              icon: AppIcon(
                Symbols.shuffle_rounded,
                fill: 1,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              tooltip: t.common.shuffle,
              iconSize: 18,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ],
    );
  }
}
