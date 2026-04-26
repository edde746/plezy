import 'package:flutter/material.dart';
import '../media/media_item.dart';
import '../utils/provider_extensions.dart';

/// Mixin for screens that need to update individual items after watch state changes
///
/// This provides a standard implementation for fetching updated metadata
/// and replacing items in lists, while allowing each screen to customize
/// which lists should be updated.
mixin ItemUpdatable<T extends StatefulWidget> on State<T> {
  /// Override to enable backend-aware item refresh. [updateItem] resolves
  /// the right [MediaServerClient] for the item's server. When null,
  /// [updateItem] is a no-op.
  String? get itemServerId => null;

  /// Updates a single item in the screen's list(s) after watch state changes
  ///
  /// Fetches the latest metadata with images (including clearLogo) and
  /// calls [updateItemInLists] to update the appropriate list(s).
  ///
  /// If the fetch fails, the error is silently caught and the item will
  /// be updated on the next full refresh.
  Future<void> updateItem(String itemId) async {
    try {
      final serverId = itemServerId;
      if (serverId == null) return;
      final updatedItem = await context.tryGetMediaClientForServer(serverId)?.fetchItem(itemId);
      if (updatedItem != null) {
        setState(() {
          updateItemInLists(itemId, updatedItem);
        });
      }
    } catch (e) {
      // Silently fail - the item will update on next full refresh
    }
  }

  /// Override this method to specify which list(s) should be updated
  ///
  /// This method is called within [setState], so you should directly
  /// modify your list(s) without calling setState again.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void updateItemInLists(String itemId, MediaItem updatedItem) {
  ///   final index = _items.indexWhere((item) => item.id == itemId);
  ///   if (index != -1) {
  ///     _items[index] = updatedItem;
  ///   }
  /// }
  /// ```
  void updateItemInLists(String itemId, MediaItem updatedItem);
}
