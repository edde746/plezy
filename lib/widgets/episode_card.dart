import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../focus/focus_theme.dart';
import '../focus/focusable_wrapper.dart';
import '../models/download_models.dart';
import '../providers/download_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/content_utils.dart';
import '../widgets/collapsible_text.dart';
import '../widgets/plex_optimized_image.dart';
import '../models/plex_metadata.dart';
import '../utils/platform_detector.dart';
import '../utils/formatters.dart';
import '../widgets/media_context_menu.dart';
import '../widgets/placeholder_container.dart';
import '../theme/mono_tokens.dart';
import '../../services/plex_client.dart';

/// Episode card widget with D-pad long-press support
class EpisodeCard extends StatefulWidget {
  final PlexMetadata episode;
  final PlexClient? client;
  final VoidCallback onTap;
  final Future<void> Function(String)? onRefresh;
  final Future<void> Function()? onListRefresh;
  final bool autofocus;
  final bool isOffline;
  final String? localPosterPath;
  final FocusNode? focusNode;
  final VoidCallback? onNavigateUp;

  const EpisodeCard({
    super.key,
    required this.episode,
    this.client,
    required this.onTap,
    this.onRefresh,
    this.onListRefresh,
    this.autofocus = false,
    this.isOffline = false,
    this.localPosterPath,
    this.focusNode,
    this.onNavigateUp,
  });

  @override
  State<EpisodeCard> createState() => _EpisodeCardState();
}

class _EpisodeCardState extends State<EpisodeCard> {
  final _contextMenuKey = GlobalKey<MediaContextMenuState>();
  Offset? _tapPosition;

  void _storeTapPosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  void _showContextMenu() {
    _contextMenuKey.currentState?.showContextMenu(context, position: _tapPosition);
  }

  Widget _buildEpisodeMetaRow(BuildContext context) {
    final mutedStyle = Theme.of(context).textTheme.bodySmall?.copyWith(color: tokens(context).textMuted, fontSize: 12);
    final dot = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text('•', style: mutedStyle),
    );
    return Row(
      children: [
        if (widget.episode.duration != null)
          Text(formatDurationTimestamp(Duration(milliseconds: widget.episode.duration!)), style: mutedStyle),
        if (widget.episode.originallyAvailableAt != null) ...[
          dot,
          Text(formatFullDate(widget.episode.originallyAvailableAt!), style: mutedStyle),
        ],
        if (widget.episode.userRating != null && widget.episode.userRating! > 0) ...[
          dot,
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Symbols.star_rounded, size: 12, fill: 1, color: Colors.amber),
          ),
          const SizedBox(width: 2),
          Text(
            (widget.episode.userRating! / 2) == (widget.episode.userRating! / 2).truncateToDouble()
                ? '${(widget.episode.userRating! / 2).toInt()}'
                : (widget.episode.userRating! / 2).toStringAsFixed(1),
            style: mutedStyle,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hideSpoilers = context.watch<SettingsProvider>().hideSpoilers;
    final shouldBlur = hideSpoilers && widget.episode.shouldHideSpoiler;

    // Hide progress when offline (not tracked)
    final hasProgress =
        !widget.isOffline &&
        widget.episode.viewOffset != null &&
        widget.episode.duration != null &&
        widget.episode.viewOffset! > 0;
    final progress = hasProgress ? widget.episode.viewOffset! / widget.episode.duration! : 0.0;

    final hasActiveProgress = hasProgress && widget.episode.viewOffset! < widget.episode.duration!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: FocusableWrapper(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        enableLongPress: true,
        onNavigateUp: widget.onNavigateUp,
        onSelect: widget.onTap,
        onLongPress: _showContextMenu,
        disableScale: true,
        child: MediaContextMenu(
          key: _contextMenuKey,
          item: widget.episode,
          onRefresh: widget.onRefresh,
          onListRefresh: widget.onListRefresh,
          onTap: widget.onTap,
          child: InkWell(
            key: Key(widget.episode.ratingKey),
            borderRadius: BorderRadius.circular(FocusTheme.defaultBorderRadius),
            onTap: widget.onTap,
            onTapDown: _storeTapPosition,
            onLongPress: _showContextMenu,
            onSecondaryTapDown: _storeTapPosition,
            onSecondaryTap: _showContextMenu,
            hoverColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.05),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(FocusTheme.defaultBorderRadius),
              ),
              padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Episode thumbnail (16:9 aspect ratio, fixed width)
                SizedBox(
                  width: 160,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(6)),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: shouldBlur
                              ? ClipRect(
                                  child: ImageFiltered(
                                    imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                    child: _buildEpisodeThumbnail(),
                                  ),
                                )
                              : _buildEpisodeThumbnail(),
                        ),
                      ),

                      // Play overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(Radius.circular(6)),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.2)],
                            ),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const AppIcon(Symbols.play_arrow_rounded, fill: 1, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ),

                      // Progress bar at bottom
                      if (hasActiveProgress)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(6),
                              bottomRight: Radius.circular(6),
                            ),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: tokens(context).outline,
                              minHeight: 3,
                            ),
                          ),
                        ),

                      if (widget.episode.isWatched && !hasActiveProgress)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: tokens(context).text,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
                            ),
                            child: AppIcon(Symbols.check_rounded, fill: 1, color: tokens(context).bg, size: 12),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Episode info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Episode number and title with download status
                      Consumer<DownloadProvider>(
                        builder: (context, downloadProvider, _) {
                          // Build download status icon based on state
                          Widget? downloadStatusIcon;

                          // Only show download status in online mode
                          if (!widget.isOffline && widget.episode.serverId != null) {
                            final globalKey = widget.episode.globalKey;
                            final progress = downloadProvider.getProgress(globalKey);
                            final isQueueing = downloadProvider.isQueueing(globalKey);

                            // Helper to get status-specific muted color
                            Color getMutedColor(Color baseColor) {
                              return Color.lerp(
                                tokens(context).textMuted,
                                baseColor,
                                0.3, // 30% of the status color, 70% muted
                              )!;
                            }

                            if (isQueueing) {
                              // Queueing state - building queue
                              downloadStatusIcon = SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 1.5, color: tokens(context).textMuted),
                              );
                            } else if (progress?.status == DownloadStatus.queued) {
                              // Queued state - waiting to download
                              downloadStatusIcon = AppIcon(
                                Symbols.schedule_rounded,
                                fill: 1,
                                size: 12,
                                color: getMutedColor(Colors.orange),
                              );
                            } else if (progress?.status == DownloadStatus.downloading) {
                              // Downloading state - active download with radial progress
                              downloadStatusIcon = SizedBox(
                                width: 14,
                                height: 14,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Background circle
                                    CircularProgressIndicator(
                                      value: 1.0,
                                      strokeWidth: 1.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        getMutedColor(Theme.of(context).colorScheme.primary).withValues(alpha: 0.3),
                                      ),
                                    ),
                                    // Progress circle
                                    CircularProgressIndicator(
                                      value: progress?.progressPercent,
                                      strokeWidth: 1.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        getMutedColor(Theme.of(context).colorScheme.primary),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else if (progress?.status == DownloadStatus.paused) {
                              // Paused state - download paused
                              downloadStatusIcon = AppIcon(
                                Symbols.pause_circle_outline_rounded,
                                fill: 1,
                                size: 12,
                                color: getMutedColor(Colors.amber),
                              );
                            } else if (progress?.status == DownloadStatus.failed) {
                              // Failed state - download failed
                              downloadStatusIcon = AppIcon(
                                Symbols.error_outline_rounded,
                                fill: 1,
                                size: 12,
                                color: getMutedColor(Colors.red),
                              );
                            } else if (progress?.status == DownloadStatus.cancelled) {
                              // Cancelled state - download cancelled
                              downloadStatusIcon = AppIcon(
                                Symbols.cancel_rounded,
                                fill: 1,
                                size: 12,
                                color: getMutedColor(Colors.grey),
                              );
                            } else if (progress?.status == DownloadStatus.completed) {
                              // Completed state - download complete
                              downloadStatusIcon = AppIcon(
                                Symbols.file_download_done_rounded,
                                fill: 1,
                                size: 12,
                                color: getMutedColor(Colors.green),
                              );
                            }
                            // Note: No icon shown if not downloaded (null)
                          }

                          return Row(
                            children: [
                              // Episode number badge
                              if (widget.episode.index != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: const BorderRadius.all(Radius.circular(3)),
                                  ),
                                  child: Text(
                                    'E${widget.episode.index}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              // Download status icon (if present)
                              if (downloadStatusIcon != null) ...[const SizedBox(width: 6), downloadStatusIcon],
                              const SizedBox(width: 8),
                              // Episode title
                              Expanded(
                                child: Text(
                                  widget.episode.title,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      // Summary (hidden when spoiler protection is active)
                      if (!shouldBlur && widget.episode.summary != null && widget.episode.summary!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        if (PlatformDetector.isTV())
                          Text(
                            widget.episode.summary!,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: tokens(context).textMuted, height: 1.3),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          CollapsibleText(
                            text: widget.episode.summary!,
                            maxLines: 3,
                            small: true,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: tokens(context).textMuted, height: 1.3),
                          ),
                      ],

                      // Metadata row (duration, watched status)
                      const SizedBox(height: 8),
                      _buildEpisodeMetaRow(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildEpisodeThumbnail() {
    if (widget.isOffline && widget.localPosterPath != null) {
      return Image.file(
        File(widget.localPosterPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const PlaceholderContainer(child: AppIcon(Symbols.movie_rounded, fill: 1, size: 32)),
      );
    }
    if (widget.episode.thumb != null) {
      return PlexOptimizedImage.thumb(
        client: widget.client,
        imagePath: widget.episode.thumb,
        filterQuality: FilterQuality.medium,
        fit: BoxFit.cover,
        placeholder: (context, url) => const PlaceholderContainer(),
        errorWidget: (context, url, error) =>
            const PlaceholderContainer(child: AppIcon(Symbols.movie_rounded, fill: 1, size: 32)),
      );
    }
    return const PlaceholderContainer(child: AppIcon(Symbols.movie_rounded, fill: 1, size: 32));
  }
}
