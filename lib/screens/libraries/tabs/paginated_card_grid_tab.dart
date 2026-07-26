import 'package:flutter/material.dart';
import '../../../focus/input_mode_tracker.dart';
import '../../../media/media_item.dart';
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
    with LibraryTabFocusMixin<W>, PaginatedItemLoader<T, W>, StandardPaginatedView<T, W>, SkeletonUpgradeScheduler<W> {
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
  Future<List<T>> loadData() async => <T>[];

  @override
  Future<void> loadItems() {
    return loadStandardPaginatedItems(
      pageSize: pageSize,
      errorMessageFor: (error, stackTrace) => localizedLoadErrorMessage(error, stackTrace, context: errorContext),
      onLoaded: (_, _) => markItemsLoaded(),
    );
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
          return _cardMemo.widgetFor(
            index,
            item,
            epoch: position.layoutEpoch!,
            build: () => _buildCard(index, isFirstRow: position.isFirstRow, isFirstColumn: true, disableScale: true),
          );
        }

        final cached = _cardMemo.tryGet(index, item, epoch: position.layoutEpoch!);
        if (cached != null) return cached;
        if (CardInflationBudget.isScrollingContext(context) &&
            !InputModeTracker.isKeyboardMode(context) &&
            !CardInflationBudget.tryTake()) {
          scheduleSkeletonUpgrade();
          return const SkeletonMediaCard();
        }
        return _cardMemo.widgetFor(
          index,
          item,
          epoch: position.layoutEpoch!,
          build: () => _buildCard(
            index,
            isFirstRow: position.isFirstRow,
            isFirstColumn: position.isFirstColumn,
            fullBleedImage: useFullCardLayout,
          ),
        );
      },
    );
  }

  Widget _buildCard(
    int index, {
    required bool isFirstRow,
    required bool isFirstColumn,
    bool disableScale = false,
    bool fullBleedImage = false,
  }) {
    final item = loadedItems[index];
    if (item == null) {
      ensureIndexLoaded(index, pageSize: pageSize);
      return const SkeletonMediaCard();
    }

    return FocusableMediaCard(
      key: Key(idOf(item)),
      item: item,
      focusNode: index == 0 ? firstItemFocusNode : null,
      disableScale: disableScale,
      fullBleedImage: fullBleedImage,
      cardShapeOverride: usesSquareCards ? CardShape.square : null,
      onListRefresh: loadItems,
      onNavigateUp: isFirstRow ? widget.onBack : null,
      onBack: widget.onBack,
      onNavigateLeft: isFirstColumn ? _navigateToSidebar : null,
    );
  }

  void _navigateToSidebar() {
    MainScreenFocusScope.focusSidebarOf(context);
  }

  @override
  void dispose() {
    disposePagination();
    super.dispose();
  }
}
