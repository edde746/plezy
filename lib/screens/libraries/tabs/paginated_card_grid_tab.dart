import 'package:flutter/material.dart';
import '../../../focus/input_mode_tracker.dart';
import '../../../media/media_item.dart';
import '../../../mixins/grid_focus_node_mixin.dart';
import '../../../mixins/library_tab_focus_mixin.dart';
import '../../../mixins/paginated_item_loader.dart';
import '../../../mixins/standard_paginated_view.dart';
import '../../../services/settings_service.dart';
import '../../../utils/error_message_utils.dart';
import '../../../utils/layout_constants.dart';
import '../../../utils/platform_detector.dart';
import '../../../widgets/card_inflation_budget.dart';
import '../../../widgets/focusable_media_card.dart';
import '../../../widgets/media_card_sliver_layout.dart';
import '../../../widgets/settings_builder.dart';
import '../../../widgets/skeleton_media_card.dart';
import '../../../widgets/sliver_child_memo.dart';
import '../../main_screen.dart';
import 'base_library_tab.dart';

/// Library tabs whose whole body is one paginated grid of media cards.
///
/// Owns the grid: sparse page loading, the card widget memo, the inflation
/// budget and skeleton-upgrade handshake, and first-item/sidebar focus wiring.
/// Subclasses supply only what differs per tab — [pageSize], [fetchPage],
/// [usesSquareCards], [idOf], and the empty/error chrome from
/// [BaseLibraryTabState].
abstract class PaginatedCardGridTabState<T extends Object, W extends BaseLibraryTab<T>>
    extends BaseLibraryTabState<T, W>
    with
        GridFocusNodeMixin<W>,
        LibraryTabFocusMixin<W>,
        PaginatedItemLoader<T, W>,
        StandardPaginatedView<T, W>,
        SkeletonUpgradeScheduler<W> {
  static const double _focusDecorationPadding = 3.0;

  /// Reuses card widgets across delegate swaps so tab-level setStates
  /// (pagination, refreshes) don't rebuild every realized card inside layout.
  final SliverChildMemo<T> _cardMemo = SliverChildMemo<T>();

  /// Items fetched per page.
  int get pageSize;

  /// Whether cards render with the square container silhouette.
  bool get usesSquareCards;

  /// Card key for [item]. The tabs' item types share no common supertype.
  String idOf(T item);

  @override
  int get itemCount => totalSize;

  @override
  Future<void> loadItems() {
    cleanupGridFocusNodes(0);
    _cardMemo.clear();
    // This pipeline bypasses [beginLibraryLoad]; capture the epoch here so
    // [markItemsLoaded]'s record marks load-start data, not a mid-fetch push.
    snapshotLibraryContentEpoch();
    return loadStandardPaginatedItems(
      pageSize: pageSize,
      errorMessageFor: (error, stackTrace) => localizedLoadErrorMessage(error, stackTrace, context: errorContext),
      onLoaded: (_, _) => markItemsLoaded(),
    );
  }

  /// Server push while this grid is visible (#1646): refetch the loaded span
  /// in place so the old cards stay rendered — no spinner, no scroll reset,
  /// no focus churn. Item-owned nodes retain active and covered restoration
  /// focus across the merge. The clearing [loadItems] path is reserved for surfaces
  /// with nothing visible to preserve (error or empty states, where it is
  /// also the only way a first item can appear live).
  @override
  Future<void> performLiveLibraryRefresh() async {
    if (isLoading) return;
    if (!hasLoadedData || loadedItems.isEmpty || totalSize == 0) return loadItems();
    snapshotLibraryContentEpoch();
    final result = await repopulateLoadedRange(idOf: idOf);
    if (result == null || !mounted) return;
    recordLibraryContentEpoch();
    setState(() => items = loadedItems.values.toList());
    reconcileGridFocusNodes({for (final entry in loadedItems.entries) idOf(entry.value): entry.key});
  }

  /// Index currently holding the item with [id], or null when it is no longer
  /// loaded.
  int? _loadedIndexOfId(String id) {
    for (final entry in loadedItems.entries) {
      if (idOf(entry.value) == id) return entry.key;
    }
    return null;
  }

  @override
  Widget buildContent(List<T> items) {
    return SettingsBuilder(
      prefs: const [SettingsService.viewMode, SettingsService.libraryDensity, SettingsService.tvFullCardLayout],
      builder: (context) {
        final settings = SettingsService.instance;
        final viewMode = settings.read(SettingsService.viewMode);
        final density = settings.read(SettingsService.libraryDensity);
        final fullCardLayout = PlatformDetector.isTV() && settings.read(SettingsService.tvFullCardLayout);
        return CustomScrollView(
          clipBehavior: Clip.none,
          slivers: [
            SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
            _buildItemsSliver(viewMode, density, fullCardLayout: fullCardLayout),
          ],
        );
      },
    );
  }

  EdgeInsets get _effectivePadding {
    final base = GridLayoutConstants.gridPadding;
    return base.copyWith(top: base.top + _focusDecorationPadding);
  }

  Widget _buildItemsSliver(ViewMode viewMode, int density, {required bool fullCardLayout}) {
    final shape = usesSquareCards ? CardShape.square : null;
    final useFullCardLayout = fullCardLayout && shape != CardShape.square;
    return MediaCardSliverLayout(
      viewMode: viewMode,
      itemCount: totalSize,
      density: density,
      findChildIndexCallback: (key) => _loadedIndexOfId((key as ValueKey<String>).value),
      padding: _effectivePadding,
      fullBleedImage: useFullCardLayout,
      shape: shape,
      listEpoch: (ViewMode.list, totalSize, density, shape),
      gridEpochBuilder: (geometry) =>
          (ViewMode.grid, geometry.columnCount, totalSize, useFullCardLayout, density, shape),
      itemBuilder: (context, position) {
        final index = position.index;
        final item = loadedItems[index];
        if (item == null) {
          ensureIndexLoaded(index, pageSize: pageSize);
          return const SkeletonMediaCard();
        }
        if (!position.isGrid) {
          return _cardMemo.widgetFor(index, item, epoch: position.layoutEpoch!, build: () => _buildCard(position));
        }

        return realizeBudgeted(
          _cardMemo,
          context,
          index,
          item,
          epoch: position.layoutEpoch!,
          keyboardMode: InputModeTracker.isKeyboardMode(context, listen: false),
          build: () => _buildCard(position, fullBleedImage: useFullCardLayout),
        );
      },
    );
  }

  Widget _buildCard(MediaCardSliverPosition position, {bool fullBleedImage = false}) {
    final index = position.index;
    final item = loadedItems[index];
    if (item == null) {
      ensureIndexLoaded(index, pageSize: pageSize);
      return const SkeletonMediaCard();
    }

    // Explicit navigation instead of default directional traversal. This grid
    // lives inside the libraries screen's NestedScrollView (floating chips
    // header); framework traversal scrolls the found node into view via
    // Scrollable.ensureVisible, whose outer-scrollable pass routes through the
    // nested-scroll coordinator and resets the inner position to zero on UP —
    // snapping the list back to the top and dropping focus onto the header.
    final columnCount = position.columnCount;
    final navigateUp = position.isFirstRow ? widget.onBack : () => _focusGridItem(index - columnCount);
    final navigateDown = index + columnCount < totalSize ? () => _focusGridItem(index + columnCount) : null;
    final navigateLeft = position.isFirstColumn ? _navigateToSidebar : () => _focusGridItem(index - 1);
    final navigateRight = !position.isLastColumn && index + 1 < totalSize ? () => _focusGridItem(index + 1) : null;

    return FocusableMediaCard(
      key: Key(idOf(item)),
      item: item,
      focusNode: _cardFocusNode(index),
      disableScale: position.disableScale,
      fullBleedImage: fullBleedImage,
      cardShapeOverride: usesSquareCards ? CardShape.square : null,
      onListRefresh: loadItems,
      onNavigateUp: navigateUp,
      onNavigateDown: navigateDown,
      onNavigateLeft: navigateLeft,
      onNavigateRight: navigateRight,
      onBack: widget.onBack,
      onFocusChange: (hasFocus) => trackGridItemFocus(index, hasFocus),
    );
  }

  FocusNode _cardFocusNode(int index) => focusNodeForIndex(
    index,
    firstItemFocusNode,
    prefix: 'paginated_grid_item',
    itemIdentity: loadedItems[index] == null ? null : idOf(loadedItems[index]!),
  );

  /// Move focus to the grid item at [targetIndex]. When the target card is
  /// not yet mounted (being built this frame, or still an unloaded skeleton),
  /// the pending request lands once its card attaches the node.
  void _focusGridItem(int targetIndex) {
    if (targetIndex < 0 || targetIndex >= totalSize) return;
    final node = _cardFocusNode(targetIndex);
    if (node.context != null) {
      node.requestFocus();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) node.requestFocus();
      });
    }
  }

  void _navigateToSidebar() {
    MainScreenFocusScope.focusSidebarOf(context);
  }

  @override
  void dispose() {
    disposePagination();
    disposeGridFocusNodes();
    super.dispose();
  }
}
