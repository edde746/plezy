import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/plex_metadata.dart';
import '../../providers/settings_provider.dart';
import '../../services/settings_service.dart' show ViewMode;
import '../../utils/grid_size_calculator.dart';
import '../../widgets/focusable_media_card.dart';

/// A widget that automatically switches between grid and list view
/// based on user settings, providing a consistent layout pattern
/// across all library screens
class AdaptiveMediaGrid extends StatelessWidget {
  /// The list of media items to display
  final List<PlexMetadata> items;

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
        if (settingsProvider.viewMode == ViewMode.list) {
          return ListView.builder(
            padding: padding,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return FocusableMediaCard(
                key: Key(item.ratingKey),
                item: item,
                focusNode: index == 0 ? firstItemFocusNode : null,
                onListRefresh: onRefresh,
                onBack: onBack,
              );
            },
          );
        } else {
          return GridView.builder(
            padding: padding,
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: GridSizeCalculator.getMaxCrossAxisExtent(
                context,
                settingsProvider.libraryDensity,
              ),
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: 0,
              mainAxisSpacing: 0,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return FocusableMediaCard(
                key: Key(item.ratingKey),
                item: item,
                focusNode: index == 0 ? firstItemFocusNode : null,
                onListRefresh: onRefresh,
                onBack: onBack,
              );
            },
          );
        }
      },
    );
  }
}
