import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/settings_service.dart' show ViewMode, LibraryDensity;
import '../../utils/grid_size_calculator.dart';

/// A widget that automatically switches between grid and list view
/// based on user settings, providing a consistent layout pattern
/// across all library screens.
///
/// Generic type T: The type of items being displayed
class AdaptiveMediaGrid<T> extends StatelessWidget {
  /// The list of items to display
  final List<T> items;

  /// Builder function for each item in the grid/list
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Callback when the list needs to be refreshed
  final VoidCallback? onRefresh;

  /// Optional padding around the grid/list
  final EdgeInsets padding;

  /// Child aspect ratio for grid items (width / height)
  final double childAspectRatio;

  /// Optional focus node for the first item (for programmatic focus)
  final FocusNode? firstItemFocusNode;

  /// Callback when back button is pressed (for hierarchical navigation)
  final VoidCallback? onBack;

  const AdaptiveMediaGrid({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onRefresh,
    this.padding = const EdgeInsets.fromLTRB(8, 8, 8, 8),
    this.childAspectRatio = 2 / 3.3,
    this.firstItemFocusNode,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return _buildItemsView(
          context,
          settingsProvider.viewMode,
          settingsProvider.libraryDensity,
        );
      },
    );
  }

  /// Builds either a list or grid view based on the view mode
  Widget _buildItemsView(
    BuildContext context,
    ViewMode viewMode,
    LibraryDensity density,
  ) {
    if (viewMode == ViewMode.list) {
      return ListView.builder(
        padding: padding,
        itemCount: items.length,
        itemBuilder: (context, index) =>
            itemBuilder(context, items[index], index),
      );
    } else {
      return GridView.builder(
        padding: padding,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: GridSizeCalculator.getMaxCrossAxisExtent(
            context,
            density,
          ),
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: 0,
          mainAxisSpacing: 0,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) =>
            itemBuilder(context, items[index], index),
      );
    }
  }
}
