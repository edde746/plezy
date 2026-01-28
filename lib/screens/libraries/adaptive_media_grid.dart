import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/settings_service.dart' show ViewMode, LibraryDensity;
import '../../utils/grid_size_calculator.dart';
import '../../utils/layout_constants.dart';
import '../main_screen.dart';

/// Context passed to the item builder with navigation information.
class GridItemContext {
  /// Whether this item is in the first row of the grid.
  final bool isFirstRow;

  /// Whether this item is in the first column of the grid.
  final bool isFirstColumn;

  /// Callback to navigate to the sidebar (for first-column items).
  final VoidCallback? navigateToSidebar;

  const GridItemContext({required this.isFirstRow, required this.isFirstColumn, this.navigateToSidebar});
}

/// A widget that automatically switches between grid and list view
/// based on user settings, providing a consistent layout pattern
/// across all library screens.
///
/// Generic type T: The type of items being displayed
class AdaptiveMediaGrid<T> extends StatelessWidget {
  /// The list of items to display
  final List<T> items;

  /// Builder function for each item in the grid/list.
  /// Receives the item, index, and optional grid context with navigation info.
  final Widget Function(BuildContext context, T item, int index, [GridItemContext? gridContext]) itemBuilder;

  /// Callback when the list needs to be refreshed
  final VoidCallback? onRefresh;

  /// Optional padding around the grid/list
  final EdgeInsets? padding;

  /// Child aspect ratio for grid items (width / height)
  final double? childAspectRatio;

  /// Optional focus node for the first item (for programmatic focus)
  final FocusNode? firstItemFocusNode;

  /// Callback when back button is pressed (for hierarchical navigation)
  final VoidCallback? onBack;

  /// Whether to enable sidebar navigation for first-column items.
  final bool enableSidebarNavigation;

  const AdaptiveMediaGrid({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onRefresh,
    this.padding,
    this.childAspectRatio,
    this.firstItemFocusNode,
    this.onBack,
    this.enableSidebarNavigation = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return _buildItemsView(context, settingsProvider.viewMode, settingsProvider.libraryDensity);
      },
    );
  }

  // Extra top padding for focus decoration (scale + border extends beyond item bounds)
  static const double _focusDecorationPadding = 8.0;

  /// Navigate focus to the sidebar
  void _navigateToSidebar(BuildContext context) {
    MainScreenFocusScope.of(context)?.focusSidebar();
  }

  /// Calculate column count based on actual available width.
  /// Uses the same formula as Flutter's SliverGridDelegateWithMaxCrossAxisExtent.
  int _calculateColumnCount(double availableWidth, double maxCrossAxisExtent) {
    final crossAxisSpacing = GridLayoutConstants.crossAxisSpacing;
    return ((availableWidth + crossAxisSpacing) / (maxCrossAxisExtent + crossAxisSpacing)).ceil().clamp(1, 100);
  }

  /// Builds either a list or grid view based on the view mode
  Widget _buildItemsView(BuildContext context, ViewMode viewMode, LibraryDensity density) {
    final basePadding = padding ?? GridLayoutConstants.gridPadding;
    // Add extra top padding for focus decoration of first row items
    final effectivePadding = basePadding.copyWith(top: basePadding.top + _focusDecorationPadding);
    final effectiveAspectRatio = childAspectRatio ?? GridLayoutConstants.posterAspectRatio;

    if (viewMode == ViewMode.list) {
      // In list view, all items are in a single column (first column)
      return ListView.builder(
        padding: effectivePadding,
        // Allow focus decoration to render outside scroll bounds
        clipBehavior: Clip.none,
        itemCount: items.length,
        itemBuilder: (ctx, index) {
          final gridContext = enableSidebarNavigation
              ? GridItemContext(
                  isFirstRow: index == 0,
                  isFirstColumn: true, // List view = single column
                  navigateToSidebar: () => _navigateToSidebar(context),
                )
              : null;
          return itemBuilder(ctx, items[index], index, gridContext);
        },
      );
    } else {
      final maxCrossAxisExtent = GridSizeCalculator.getMaxCrossAxisExtent(context, density);
      final horizontalPadding = effectivePadding.left + effectivePadding.right;

      // Use LayoutBuilder to get the actual available width (accounting for sidebar, etc.)
      return LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth - horizontalPadding;
          final columnCount = _calculateColumnCount(availableWidth, maxCrossAxisExtent);

          return GridView.builder(
            padding: effectivePadding,
            // Allow focus decoration to render outside scroll bounds
            clipBehavior: Clip.none,
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: maxCrossAxisExtent,
              childAspectRatio: effectiveAspectRatio,
              crossAxisSpacing: GridLayoutConstants.crossAxisSpacing,
              mainAxisSpacing: GridLayoutConstants.mainAxisSpacing,
            ),
            itemCount: items.length,
            itemBuilder: (ctx, index) {
              final gridContext = enableSidebarNavigation
                  ? GridItemContext(
                      isFirstRow: GridSizeCalculator.isFirstRow(index, columnCount),
                      isFirstColumn: GridSizeCalculator.isFirstColumn(index, columnCount),
                      navigateToSidebar: () => _navigateToSidebar(context),
                    )
                  : null;
              return itemBuilder(ctx, items[index], index, gridContext);
            },
          );
        },
      );
    }
  }
}
