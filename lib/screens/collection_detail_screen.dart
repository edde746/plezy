import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../focus/focusable_action_bar.dart';
import '../media/library_query.dart';
import '../media/media_item.dart';
import '../mixins/paginated_item_loader.dart';
import '../mixins/standard_paginated_view.dart';
import '../providers/download_provider.dart';
import '../theme/mono_tokens.dart';
import '../utils/app_logger.dart';
import '../utils/content_utils.dart';
import '../utils/dialogs.dart';
import '../utils/error_message_utils.dart';
import '../utils/download_utils.dart';
import '../utils/desktop_window_padding.dart';
import '../utils/layout_constants.dart';
import '../utils/media_image_helper.dart';
import '../utils/media_server_http_client.dart';
import '../utils/platform_detector.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/app_bar_back_button.dart';
import '../widgets/collapsible_text.dart';
import '../widgets/cycling_media_backdrop.dart';
import '../widgets/optimized_media_image.dart';
import '../widgets/rasterized_gradient.dart';
import '../i18n/strings.g.dart';
import 'base_media_list_detail_screen.dart';
import 'focusable_detail_screen_mixin.dart';
import '../mixins/grid_focus_node_mixin.dart';
import '../services/playlist_items_loader.dart';

/// Screen to display the contents of a collection.
///
/// Header follows the album/artist detail pages: the collection poster beside
/// its title, item count, year span and summary, with the Play / Shuffle /
/// Download / Delete row underneath. The collection's backdrop art washes the
/// header region and fades into the scaffold background before the grid.
class CollectionDetailScreen extends StatefulWidget {
  final MediaItem collection;

  const CollectionDetailScreen({super.key, required this.collection});

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends BaseMediaListDetailScreen<CollectionDetailScreen>
    with
        GridFocusNodeMixin<CollectionDetailScreen>,
        FocusableDetailScreenMixin<CollectionDetailScreen>,
        PaginatedItemLoader<MediaItem, CollectionDetailScreen>,
        PaginatedItemUpdatable<CollectionDetailScreen>,
        StandardPaginatedView<MediaItem, CollectionDetailScreen> {
  static const int _pageSize = 200;

  /// Scroll offset where the pinned title starts fading in, and the distance
  /// over which it completes. Roughly where the poster leaves the viewport.
  static const double _titleFadeStart = 120;
  static const double _titleFadeDistance = 80;

  final FocusNode _summaryFocusNode = FocusNode(debugLabel: 'collection_summary');

  @override
  MediaItem get mediaItem => widget.collection;

  @override
  String get title => widget.collection.title!;

  @override
  String get emptyMessage => t.collections.empty;

  @override
  bool get hasItems => totalSize > 0;

  bool get _isMusic {
    final loaded = loadedItems.values;
    return loaded.isNotEmpty && loaded.every((item) => item.kind.isMusic);
  }

  @override
  void dispose() {
    disposePagination();
    disposeFocusResources();
    _summaryFocusNode.dispose();
    super.dispose();
  }

  @override
  Future<LibraryPage<MediaItem>> fetchPage(int start, int size, AbortController? abort) {
    return mediaClient.fetchCollectionPage(
      widget.collection.id,
      start: start,
      size: size,
      abort: abort,
      libraryId: widget.collection.libraryId,
      libraryTitle: widget.collection.libraryTitle,
    );
  }

  @override
  Future<void> loadItems() {
    return loadStandardPaginatedItems(
      pageSize: _pageSize,
      errorMessageFor: (error, stackTrace) =>
          localizedLoadErrorMessage(error, stackTrace, context: t.collections.collection),
      onLoaded: (loadedCount, totalCount) {
        appLogger.d('Loaded $loadedCount of $totalCount items for collection: ${widget.collection.title}');
        autoFocusFirstItemAfterLoad();
      },
    );
  }

  @override
  List<FocusableAction> getAppBarActions() {
    final ruleKey = syncRuleKey;
    // Select the specific bool we care about so unrelated DownloadProvider
    // ticks (e.g. active download progress) don't rebuild the action row.
    final hasRule = context.select<DownloadProvider, bool>((p) => p.hasSyncRule(ruleKey));

    return [
      if (hasItems) ...[
        FocusableAction(icon: Symbols.play_arrow_rounded, tooltip: t.common.play, onPressed: playItems),
        FocusableAction(icon: Symbols.shuffle_rounded, tooltip: t.common.shuffle, onPressed: shufflePlayItems),
      ],
      // Emptiness is handled inside [_downloadCollection], so the download
      // entry stays visible for empty collections.
      ...buildSyncRuleActions(
        context,
        ruleKey: ruleKey,
        displayTitle: widget.collection.displayTitle,
        hasRule: hasRule,
        showDownload: true,
        onDownload: _downloadCollection,
      ),
      FocusableAction(
        icon: Symbols.delete_rounded,
        tooltip: t.common.delete,
        onPressed: _deleteCollection,
        iconColor: Colors.red,
      ),
    ];
  }

  Future<void> _downloadCollection() async {
    if (!hasItems) {
      showErrorSnackBar(context, t.collections.empty);
      return;
    }

    await fetchAndQueueListDownload(
      context,
      client: mediaClient,
      downloadProvider: context.read<DownloadProvider>(),
      fetchItems: () => fetchAllCollectionItemsPaged(
        mediaClient,
        widget.collection.id,
        libraryId: widget.collection.libraryId,
        libraryTitle: widget.collection.libraryTitle,
      ),
      rootMetadata: widget.collection,
      targetType: ContentTypes.collection,
    );
  }

  Future<void> _deleteCollection() async {
    final confirmed = await showDeleteConfirmation(
      context,
      title: t.collections.deleteCollection,
      message: t.collections.deleteConfirm(title: widget.collection.displayTitle),
    );

    if (!confirmed) return;
    if (!mounted) return;

    try {
      // Backend-neutral [deleteCollection] reads `libraryId` from the
      // [MediaItem] for Plex's section-id; Jellyfin ignores it.
      final success = await mediaClient.deleteCollection(widget.collection);

      if (!mounted) return;

      if (success) {
        showSuccessSnackBar(context, t.collections.deleted);
        Navigator.pop(context, true);
      } else {
        showErrorSnackBar(context, t.collections.deleteFailed);
      }
    } catch (e) {
      appLogger.e('Failed to delete collection', error: e);
      if (mounted) {
        showErrorSnackBar(context, t.collections.deleteFailedWithError(error: e.toString()));
      }
    }
  }

  /// "10 items · 2007–2013 · PG-13". The year span is only shown once every
  /// item is loaded, so a partially fetched collection never reports a range
  /// narrower than the truth.
  String _metaLine() {
    final count = totalSize > 0 ? totalSize : (widget.collection.childCount ?? 0);
    final parts = <String>[count == 1 ? t.playlists.oneItem : t.playlists.itemCount(count: count)];
    if (totalSize > 0 && loadedItems.length == totalSize) {
      final years = loadedItems.values.map((i) => i.year).nonNulls.toList();
      if (years.isNotEmpty) {
        final lo = years.reduce(math.min);
        final hi = years.reduce(math.max);
        parts.add(lo == hi ? '$lo' : '$lo–$hi');
      }
    }
    final rating = widget.collection.contentRating;
    if (rating != null && rating.isNotEmpty) parts.add(rating);
    return parts.join('  ·  ');
  }

  Widget _buildArtwork(double height) {
    final square = _isMusic;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: OptimizedMediaImage(
        client: mediaClient,
        imagePath: widget.collection.thumbPath,
        imageType: square ? ImageType.square : ImageType.poster,
        width: square ? height : height * 2 / 3,
        height: height,
        fallbackIcon: Symbols.collections_bookmark_rounded,
      ),
    );
  }

  Widget _buildInfo(BuildContext context, {required bool centered, required bool isTv}) {
    final theme = Theme.of(context);
    final tk = tokens(context);
    final summary = widget.collection.summary;
    final align = centered ? TextAlign.center : TextAlign.start;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          widget.collection.displayTitle,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: isTv ? 34 : null),
          textAlign: align,
        ),
        const SizedBox(height: 4),
        Text(
          _metaLine(),
          style: theme.textTheme.bodyMedium?.copyWith(color: tk.textMuted, fontSize: isTv ? 18 : null),
          textAlign: align,
        ),
        if (summary != null && summary.isNotEmpty) ...[
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: CollapsibleText(
              text: summary,
              maxLines: 3,
              style: theme.textTheme.bodyMedium?.copyWith(color: tk.textMuted, fontSize: isTv ? 18 : null),
              focusNode: _summaryFocusNode,
              skipTraversal: false,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeader(BuildContext context, {required bool compact, required bool isTv, required double inset}) {
    final topInset = MediaQuery.paddingOf(context).top + kToolbarHeight;
    final actionBar = FocusableActionBar(
      key: actionBarKey,
      spacing: 4,
      actions: getAppBarActions(),
      onNavigateDown: navigateToGrid,
      onBack: () => Navigator.pop(context),
    );

    if (compact) {
      return Padding(
        padding: EdgeInsets.fromLTRB(inset, topInset + 8, inset, 12),
        child: Column(
          children: [
            _buildArtwork(240),
            const SizedBox(height: 16),
            _buildInfo(context, centered: true, isTv: isTv),
            const SizedBox(height: 16),
            actionBar,
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(inset, topInset + 8, inset, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildArtwork(isTv ? 300 : 240),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfo(context, centered: false, isTv: isTv),
                const SizedBox(height: 16),
                actionBar,
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Backdrop art washing the header, scrimmed to the scaffold background
  /// well before the grid starts. Translated with the scroll view so it keeps
  /// a fixed relationship to the header. Collections without `art` fall back
  /// to a blurred poster so the wash still reads as colour, not as a second
  /// copy of the poster.
  Widget _buildBackdropLayer(BuildContext context, {required Size size, required double height}) {
    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;
    final containerAspect = size.width / height;
    final artPaths = widget.collection.heroArtCandidates(containerAspectRatio: containerAspect);
    final usePoster = artPaths.isEmpty;
    final paths = usePoster ? [?widget.collection.thumbPath] : artPaths;
    if (paths.isEmpty) return const SizedBox.shrink();

    Widget art = CyclingMediaBackdrop(
      mediaKey: widget.collection.globalKey,
      imagePaths: usePoster ? paths : widget.collection.heroRotationPaths(containerAspectRatio: containerAspect),
      fallbackImagePaths: paths,
      client: mediaClient,
      width: size.width,
      height: height,
      fallbackColor: theme.colorScheme.surfaceContainerHighest,
    );
    if (usePoster) {
      art = ClipRect(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40, tileMode: TileMode.clamp),
          child: Transform.scale(scale: 1.15, child: art),
        ),
      );
    }

    // Same eased ramp as the movie/show hero, starting from a 35% global dim
    // so the header text sits on a calmer surface than a full-bleed hero.
    const topAlpha = 0.35;
    const easedAlphas = [0.0, 0.034, 0.125, 0.253, 0.40, 0.547, 0.675, 0.785, 0.798, 0.8];
    const xs = [0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 0.9375, 1.0];
    const solidStop = 0.9;
    final scrim = RasterizedGradient(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          for (final a in easedAlphas) bg.withValues(alpha: topAlpha + a * (1 - topAlpha)),
          bg,
        ],
        stops: [for (final x in xs) solidStop * x, 1.0],
      ),
    );

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: height,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: scrollController,
          builder: (context, child) {
            final offset = scrollController.hasClients ? scrollController.offset : 0.0;
            return Transform.translate(offset: Offset(0, -offset), child: child);
          },
          child: RepaintBoundary(
            child: Stack(fit: StackFit.expand, children: [art, scrim]),
          ),
        ),
      ),
    );
  }

  /// Transparent title bar that fades in once the header scrolls away, plus
  /// the always-visible circular back button (as on the movie/show detail).
  List<Widget> _buildChrome(BuildContext context) {
    final theme = Theme.of(context);
    final statusBar = MediaQuery.paddingOf(context).top;
    return [
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: statusBar + kToolbarHeight,
        child: AnimatedBuilder(
          animation: scrollController,
          builder: (context, child) {
            final offset = scrollController.hasClients ? scrollController.offset : 0.0;
            final progress = ((offset - _titleFadeStart) / _titleFadeDistance).clamp(0.0, 1.0);
            return IgnorePointer(
              ignoring: progress < 0.5,
              child: ColoredBox(
                color: theme.scaffoldBackgroundColor.withValues(alpha: progress),
                child: Opacity(opacity: progress, child: child),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.only(top: statusBar),
            child: Center(
              child: Text(
                widget.collection.displayTitle,
                style: theme.textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
      Positioned(
        top: 0,
        left: 0,
        child: DesktopAppBarHelper.buildAdjustedLeading(
          AppBarBackButton(style: BackButtonStyle.circular, onPressed: () => Navigator.pop(context)),
          context: context,
        )!,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTv = PlatformDetector.isTV();
    final compact = size.width < ScreenBreakpoints.mobile;
    final inset = isTv ? TvLayoutConstants.horizontalInset : 16.0;
    final artHeight = compact ? size.height * 0.62 : (isTv ? size.height * 0.7 : 460.0);

    return buildDetailScaffold(
      behind: [_buildBackdropLayer(context, size: size, height: artHeight)],
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(context, compact: compact, isTv: isTv, inset: inset),
        ),
        ...buildStateSlivers(),
        if (hasItems)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: isTv ? inset - 8 : 8),
            sliver: buildSparseFocusableGrid(
              totalItems: totalSize,
              itemAt: (index) => loadedItems[index],
              onRefresh: updateItem,
              onSkeletonVisible: (index) => ensureIndexLoaded(index, pageSize: _pageSize),
              collectionId: widget.collection.id,
              onListRefresh: loadItems,
              shape: _isMusic ? CardShape.square : null,
            ),
          ),
      ],
      above: _buildChrome(context),
    );
  }
}
