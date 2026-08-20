import 'dart:ui';
import '../../media/ids.dart';

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../focus/focusable_button.dart';
import '../../providers/watch_state_store.dart';
import '../../focus/focusable_wrapper.dart';
import '../../media/media_item.dart';
import '../../media/media_item_types.dart';
import '../../media/media_kind.dart';
import '../../mixins/context_menu_tap_mixin.dart';
import '../../services/settings_service.dart';
import '../../widgets/settings_builder.dart';
import '../../utils/formatters.dart';
import '../../utils/provider_extensions.dart';
import '../../widgets/app_menu.dart';
import '../../widgets/media_context_menu.dart';
import '../../widgets/optimized_media_image.dart';
import '../../widgets/watched_indicator.dart';
import '../../theme/mono_tokens.dart';
import '../../i18n/strings.g.dart';
import '../../widgets/loading_indicator_box.dart';

/// Individual item in the folder tree. [isExpandable] controls hierarchy
/// behavior independently from [isFolder], which identifies plain directory
/// rows and their folder-specific visuals/actions.
class FolderTreeItem extends StatefulWidget {
  final MediaItem item;
  final int depth;
  final bool isExpanded;
  final bool isFolder;
  final bool isExpandable;
  final VoidCallback? onTap;
  final VoidCallback? onExpand;
  final VoidCallback? onPlayAll;
  final VoidCallback? onShuffle;
  final bool isLoading;
  final FocusNode? focusNode;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onNavigateLeft;
  final void Function(MediaItem source)? onRefresh;
  final VoidCallback? onListRefresh;
  final String? serverId;

  const FolderTreeItem({
    super.key,
    required this.item,
    required this.depth,
    this.isExpanded = false,
    this.isFolder = false,
    this.isExpandable = false,
    this.onTap,
    this.onExpand,
    this.onPlayAll,
    this.onShuffle,
    this.isLoading = false,
    this.focusNode,
    this.onNavigateUp,
    this.onNavigateLeft,
    this.onRefresh,
    this.onListRefresh,
    this.serverId,
  });

  @override
  State<FolderTreeItem> createState() => _FolderTreeItemState();
}

class _FolderTreeItemState extends State<FolderTreeItem> with ContextMenuTapMixin {
  /// Whether the row is a real media item that gets the standard media
  /// presentation and context menu, even when it is also expandable.
  bool get _isMediaRow => !widget.isFolder;

  /// Plain folders only offer the Play/Shuffle actions of their trailing buttons.
  bool get _hasFolderMenu => !_isMediaRow && (widget.onPlayAll != null || widget.onShuffle != null);

  bool get _hasMenu => _isMediaRow || _hasFolderMenu;

  IconData _getIcon() {
    if (widget.isFolder) {
      return Symbols.folder_rounded;
    }

    return switch (widget.item.kind) {
      MediaKind.movie => Symbols.movie_rounded,
      MediaKind.show => Symbols.tv_rounded,
      MediaKind.season => Symbols.video_library_rounded,
      MediaKind.episode => Symbols.play_circle_rounded,
      MediaKind.collection => Symbols.collections_rounded,
      _ => Symbols.insert_drive_file_rounded,
    };
  }

  String _rowTitle() {
    final title = widget.item.title?.trim();
    if (title != null && title.isNotEmpty) return title;
    return widget.item.displayTitle;
  }

  MediaItem _effectiveItem(BuildContext context) => context.withFreshWatchState(widget.item);

  String? _dedupeSubtitle(String? subtitle) {
    final value = subtitle?.trim();
    if (value == null || value.isEmpty || value == _rowTitle()) return null;
    return value;
  }

  void _handleTap() {
    if (widget.isExpandable) {
      widget.onExpand?.call();
    } else {
      widget.onTap?.call();
    }
  }

  void _showRowMenu() {
    if (_isMediaRow) {
      showContextMenuFromTap();
    } else {
      _showFolderMenu();
    }
  }

  /// Center of the row, used to anchor the folder menu for keyboard/d-pad
  /// activation (mirrors [MediaContextMenuState.showContextMenu]).
  Offset _rowCenter() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return Offset.zero;
    final size = renderBox.size;
    final topLeft = renderBox.localToGlobal(Offset.zero);
    return Offset(topLeft.dx + size.width / 2, topLeft.dy + size.height / 2);
  }

  /// Ad-hoc Play/Shuffle menu for plain folder rows. These map to pseudo
  /// [MediaItem]s (Plex directories, Jellyfin folders), so [MediaContextMenu]
  /// would offer actions that don't apply to them.
  Future<void> _showFolderMenu() async {
    final entries = <AppMenuEntry<String>>[
      if (widget.onPlayAll != null)
        AppMenuItem<String>(value: 'play', icon: Symbols.play_arrow_rounded, label: t.common.play),
      if (widget.onShuffle != null)
        AppMenuItem<String>(value: 'shuffle', icon: Symbols.shuffle_rounded, label: t.common.shuffle),
    ];
    if (entries.isEmpty) return;

    final previousFocus = FocusManager.instance.primaryFocus;
    final position = lastTapPosition;
    final fromKeyboard = position == null;
    final selected = await showAdaptiveAppMenu<String>(
      context,
      title: _rowTitle(),
      entries: entries,
      position: position ?? _rowCenter(),
      focusFirstItem: fromKeyboard,
    );

    if (!mounted) return;

    if (selected == null) {
      // Dismissed — restore focus to the row. Play/Shuffle hand off to the
      // player instead (mirrors MediaContextMenu's didNavigate handling).
      if (previousFocus != null && previousFocus.canRequestFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (previousFocus.canRequestFocus) {
            previousFocus.requestFocus();
          }
        });
      }
      return;
    }

    switch (selected) {
      case 'play':
        widget.onPlayAll?.call();
      case 'shuffle':
        widget.onShuffle?.call();
    }
  }

  String? _buildSubtitle() {
    final item = widget.item;
    if (item.isEpisode) {
      final parts = <String>[];
      if (item.parentIndex != null && item.index != null) {
        parts.add('S${item.parentIndex} E${item.index}');
      }
      return parts.isNotEmpty ? parts.join(' · ') : _dedupeSubtitle(item.displaySubtitle);
    }
    if (item.isSeason) {
      return _dedupeSubtitle(item.displaySubtitle);
    }
    return _dedupeSubtitle(item.displaySubtitle);
  }

  String _buildMetadataLine() {
    final item = widget.item;
    final parts = <String>[];

    if (item.contentRating != null && item.contentRating!.isNotEmpty) {
      parts.add(item.contentRating!);
    }
    if (item.year != null) {
      parts.add(item.year.toString());
    }
    if (item.durationMs != null && item.durationMs! > 0) {
      parts.add(formatDurationTextual(item.durationMs!));
    }
    if (item.rating != null) {
      parts.add('★ ${item.rating!.toStringAsFixed(1)}');
    }

    return parts.join(' · ');
  }

  Widget _buildFolderRow(BuildContext context) {
    final indentation = widget.depth * 24.0;
    final expandIcon = widget.isExpanded ? Symbols.keyboard_arrow_down_rounded : Symbols.keyboard_arrow_right_rounded;

    return Container(
      padding: .only(left: 16.0 + indentation, right: 8.0, top: 8.0, bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: widget.isLoading ? const LoadingIndicatorBox(size: 16) : AppIcon(expandIcon, fill: 1, size: 20),
          ),
          const SizedBox(width: 8),
          AppIcon(_getIcon(), fill: 1, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _rowTitle(),
              style: const TextStyle(fontSize: 14, fontWeight: .w500),
              maxLines: 1,
              overflow: .ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaRow(BuildContext context) {
    final indentation = widget.depth * 24.0;
    final svc = SettingsService.instance;
    final episodePosterMode = svc.read(SettingsService.episodePosterMode);
    final hideSpoilers = svc.read(SettingsService.hideSpoilers);
    final showUnwatchedCount = svc.read(SettingsService.showUnwatchedCount);
    final expandIcon = widget.isExpanded ? Symbols.keyboard_arrow_down_rounded : Symbols.keyboard_arrow_right_rounded;

    final isWide = widget.item.usesWideAspectRatio(episodePosterMode);
    final thumbWidth = isWide ? 130.0 : 53.0;
    final thumbHeight = isWide ? 73.0 : 80.0;

    final subtitle = _buildSubtitle();
    final metadataLine = _buildMetadataLine();

    return Container(
      padding: .only(left: 16.0 + indentation, right: 16.0, top: 6.0, bottom: 6.0),
      child: Row(
        crossAxisAlignment: .center,
        children: [
          if (widget.isExpandable) ...[
            SizedBox(
              width: 24,
              child: widget.isLoading ? const LoadingIndicatorBox(size: 16) : AppIcon(expandIcon, fill: 1, size: 20),
            ),
            const SizedBox(width: 8),
          ],
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
              crossAxisAlignment: .start,
              mainAxisSize: .min,
              children: [
                Text(
                  _rowTitle(),
                  style: const TextStyle(fontSize: 13, fontWeight: .w500, height: 1.2),
                  maxLines: 1,
                  overflow: .ellipsis,
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
                    overflow: .ellipsis,
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
                    overflow: .ellipsis,
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
    final item = widget.item;
    final posterUrl = item.posterThumb(mode: episodePosterMode);
    // Backend-neutral so Jellyfin items render via Jellyfin's transcoder.
    final client = context.tryGetMediaClientWithFallback(serverIdOrNull(widget.serverId));
    final shouldBlur =
        hideSpoilers && item.shouldHideSpoiler && episodePosterMode == EpisodePosterMode.episodeThumbnail;

    Widget image;
    if (item.usesWideAspectRatio(episodePosterMode)) {
      image = OptimizedMediaImage.thumb(
        client: client,
        imagePath: posterUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    } else {
      image = OptimizedMediaImage.poster(
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
    return WatchedIndicator(
      // Session-fresh view of the item so the overlay reflects live patches.
      item: _effectiveItem(context),
      size: WatchedIndicatorSize.compact,
      showUnwatchedCount: showUnwatchedCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final playAll = widget.onPlayAll;
    final shuffle = widget.onShuffle;
    final hasMenu = _hasMenu;
    final rowContent = widget.isFolder
        ? _buildFolderRow(context)
        : SettingsBuilder(
            prefs: const [
              SettingsService.episodePosterMode,
              SettingsService.hideSpoilers,
              SettingsService.showUnwatchedCount,
            ],
            builder: _buildMediaRow,
          );

    Widget gesture = GestureDetector(
      onTap: _handleTap,
      onTapDown: hasMenu ? storeTapPosition : null,
      onLongPress: hasMenu ? _showRowMenu : null,
      onSecondaryTapDown: hasMenu ? storeTapPosition : null,
      onSecondaryTap: hasMenu ? _showRowMenu : null,
      behavior: HitTestBehavior.opaque,
      child: rowContent,
    );

    if (_isMediaRow) {
      gesture = MediaContextMenu(
        key: contextMenuKey,
        item: widget.item,
        onRefresh: widget.onRefresh,
        onListRefresh: widget.onListRefresh,
        child: gesture,
      );
    }

    return Row(
      children: [
        // Main item row
        Expanded(
          child: FocusableWrapper(
            focusNode: widget.focusNode,
            onSelect: _handleTap,
            enableLongPress: hasMenu,
            onLongPress: hasMenu ? _showRowMenu : null,
            onNavigateUp: widget.onNavigateUp,
            onNavigateLeft: widget.onNavigateLeft,
            useBackgroundFocus: true,
            disableScale: true,
            descendantsAreFocusable: false,
            child: gesture,
          ),
        ),

        // Play/Shuffle buttons for folders when the backend supports them.
        if (widget.isFolder && playAll != null) ...[
          FocusableButton(
            useBackgroundFocus: true,
            onPressed: playAll,
            child: IconButton(
              onPressed: playAll,
              icon: AppIcon(
                Symbols.play_arrow_rounded,
                fill: 1,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              tooltip: t.common.play,
              iconSize: 18,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: .zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
        if (widget.isFolder && shuffle != null) ...[
          FocusableButton(
            useBackgroundFocus: true,
            onPressed: shuffle,
            child: IconButton(
              onPressed: shuffle,
              icon: AppIcon(
                Symbols.shuffle_rounded,
                fill: 1,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              tooltip: t.common.shuffle,
              iconSize: 18,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: .zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ],
    );
  }
}
