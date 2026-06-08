import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vibe_stream/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../focus/focus_theme.dart';
import '../focus/focusable_wrapper.dart';
import '../mixins/context_menu_tap_mixin.dart';
import '../models/download_models.dart';
import '../providers/download_provider.dart';
import '../providers/watch_state_overlay_provider.dart';
import 'package:provider/provider.dart';

import '../services/settings_service.dart';
import 'settings_builder.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../widgets/collapsible_text.dart';
import '../widgets/download_status_icon.dart';
import '../widgets/optimized_media_image.dart';
import '../utils/platform_detector.dart';
import '../utils/formatters.dart';
import '../utils/media_quality_labels.dart';
import '../widgets/media_context_menu.dart';
import '../widgets/placeholder_container.dart';
import '../theme/mono_tokens.dart';
import '../media/media_server_client.dart';

/// Episode card widget with D-pad long-press support
class EpisodeCard extends StatefulWidget {
  final MediaItem episode;
  final MediaServerClient? client;
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

class _EpisodeCardState extends State<EpisodeCard> with ContextMenuTapMixin<EpisodeCard> {
  MediaItem _effectiveEpisode(BuildContext context) {
    try {
      final patch = context.select<WatchStateOverlayProvider, WatchStateOverlayPatch?>(
        (provider) => provider.patchForGlobalKey(widget.episode.globalKey),
      );
      return WatchStateOverlayProvider.applyPatch(widget.episode, patch);
    } on ProviderNotFoundException {
      return widget.episode;
    }
  }

  Widget _buildEpisodeMetaRow(BuildContext context, MediaItem episode, List<String> qualityLabels) {
    final mutedStyle = Theme.of(context).textTheme.bodySmall?.copyWith(color: tokens(context).textMuted, fontSize: 12);
    final children = <Widget>[];

    void addSeparator() {
      if (children.isEmpty) return;
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('•', style: mutedStyle),
        ),
      );
    }

    if (episode.durationMs != null) {
      children.add(Text(formatDurationTimestamp(Duration(milliseconds: episode.durationMs!)), style: mutedStyle));
    }

    if (episode.originallyAvailableAt != null) {
      addSeparator();
      children.add(Text(formatFullDate(episode.originallyAvailableAt!), style: mutedStyle));
    }

    if (episode.userRating != null && episode.userRating! > 0) {
      addSeparator();
      children.add(
        Row(
          mainAxisSize: .min,
          children: [
            const Padding(
              padding: .only(top: 2),
              child: Icon(Symbols.star_rounded, size: 12, fill: 1, color: Colors.amber),
            ),
            const SizedBox(width: 2),
            Text(
              (episode.userRating! / 2) == (episode.userRating! / 2).truncateToDouble()
                  ? '${(episode.userRating! / 2).toInt()}'
                  : formatRating(episode.userRating! / 2),
              style: mutedStyle,
            ),
          ],
        ),
      );
    }

    for (final label in qualityLabels) {
      addSeparator();
      children.add(Text(label, style: mutedStyle));
    }

    return Wrap(crossAxisAlignment: .center, runSpacing: 4, children: children);
  }

  @override
  Widget build(BuildContext context) {
    return SettingValueBuilder<bool>(
      pref: SettingsService.hideSpoilers,
      builder: (context, hideSpoilers, _) => _buildContent(context, hideSpoilers: hideSpoilers),
    );
  }

  Widget _buildContent(BuildContext context, {required bool hideSpoilers}) {
    final episode = _effectiveEpisode(context);
    final shouldBlur = hideSpoilers && episode.shouldHideSpoiler;
    final qualityLabels = buildMediaQualityLabels(episode);

    // Hide progress when offline (not tracked)
    final hasProgress =
        !widget.isOffline && episode.viewOffsetMs != null && episode.durationMs != null && episode.viewOffsetMs! > 0;
    final progress = hasProgress ? episode.viewOffsetMs! / episode.durationMs! : 0.0;

    final hasActiveProgress = hasProgress && episode.viewOffsetMs! < episode.durationMs!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: FocusableWrapper(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        enableLongPress: true,
        onNavigateUp: widget.onNavigateUp,
        onSelect: widget.onTap,
        onLongPress: showContextMenuFromTap,
        disableScale: true,
        child: MediaContextMenu(
          key: contextMenuKey,
          item: episode,
          onRefresh: widget.onRefresh,
          onListRefresh: widget.onListRefresh,
          onTap: widget.onTap,
          child: InkWell(
            key: Key(episode.id),
            mouseCursor: SystemMouseCursors.click,
            borderRadius: BorderRadius.circular(FocusTheme.defaultBorderRadius),
            onTap: widget.onTap,
            canRequestFocus: false,
            onTapDown: storeTapPosition,
            onLongPress: showContextMenuFromTap,
            onSecondaryTapDown: storeTapPosition,
            onSecondaryTap: showContextMenuFromTap,
            hoverColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.05),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(FocusTheme.defaultBorderRadius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                crossAxisAlignment: .start,
                children: [
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
                                      child: _buildEpisodeThumbnail(episode),
                                    ),
                                  )
                                : _buildEpisodeThumbnail(episode),
                          ),
                        ),

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
                                child: const AppIcon(
                                  Symbols.play_arrow_rounded,
                                  fill: 1,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),

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

                        if (episode.isWatched && !hasActiveProgress)
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

                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Selector<DownloadProvider, _DownloadSlice>(
                          selector: (_, p) =>
                              _DownloadSlice.from(p.getProgress(episode.globalKey), p.isQueueing(episode.globalKey)),
                          builder: (context, slice, _) {
                            Widget? downloadStatusIcon;

                            // Only show download status in online mode
                            if (!widget.isOffline && episode.serverId != null) {
                              final status = slice.status;
                              final mutedBase = tokens(context).textMuted;

                              if (slice.isQueueing) {
                                downloadStatusIcon = DownloadQueueingSpinner(size: 12, color: mutedBase);
                              } else if (status != null) {
                                final iconSize = status == DownloadStatus.downloading ? 14.0 : 12.0;
                                downloadStatusIcon = DownloadStatusIcon(
                                  status: status,
                                  size: iconSize,
                                  variant: DownloadStatusIconVariant.muted,
                                  mutedBase: mutedBase,
                                  progress: slice.progressPercent,
                                );
                              }
                              // Note: No icon shown if not downloaded (null)
                            }

                            return Row(
                              children: [
                                if (episode.index != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primaryContainer,
                                      borderRadius: const BorderRadius.all(Radius.circular(3)),
                                    ),
                                    child: Text(
                                      'E${episode.index}',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                        fontSize: 11,
                                        fontWeight: .w600,
                                      ),
                                    ),
                                  ),
                                if (downloadStatusIcon != null) ...[const SizedBox(width: 6), downloadStatusIcon],
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    episode.title!,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: .bold),
                                    maxLines: 2,
                                    overflow: .ellipsis,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        if (!shouldBlur && episode.summary != null && episode.summary!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          if (PlatformDetector.isTV())
                            Text(
                              episode.summary!,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(color: tokens(context).textMuted, height: 1.3),
                              maxLines: 3,
                              overflow: .ellipsis,
                            )
                          else
                            CollapsibleText(
                              text: episode.summary!,
                              maxLines: 3,
                              small: true,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(color: tokens(context).textMuted, height: 1.3),
                            ),
                        ],

                        const SizedBox(height: 8),
                        _buildEpisodeMetaRow(context, episode, qualityLabels),
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

  Widget _buildEpisodeThumbnail(MediaItem episode) {
    if (widget.isOffline && widget.localPosterPath != null) {
      return OptimizedMediaImage.thumb(
        client: null,
        imagePath: null,
        localFilePath: widget.localPosterPath,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) =>
            const PlaceholderContainer(child: AppIcon(Symbols.movie_rounded, fill: 1, size: 32)),
      );
    }
    if (episode.thumbPath != null) {
      return OptimizedMediaImage.thumb(
        client: widget.client,
        imagePath: episode.thumbPath,
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

/// Captures only primitives so Selector equality avoids rebuilds on unrelated
/// download ticks (e.g. other episodes, unused `DownloadProgress` fields).
class _DownloadSlice {
  final DownloadStatus? status;
  final double? progressPercent;
  final bool isQueueing;

  const _DownloadSlice({required this.status, required this.progressPercent, required this.isQueueing});

  factory _DownloadSlice.from(DownloadProgress? p, bool isQueueing) =>
      _DownloadSlice(status: p?.status, progressPercent: p?.progressPercent, isQueueing: isQueueing);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _DownloadSlice &&
        other.status == status &&
        other.progressPercent == progressPercent &&
        other.isQueueing == isQueueing;
  }

  @override
  int get hashCode => Object.hash(status, progressPercent, isQueueing);
}
