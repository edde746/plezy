import 'package:flutter/material.dart';
import '../media/ids.dart';
import '../media/media_item.dart';
import '../utils/provider_extensions.dart';

/// Mixin for screens that need to update individual items after watch state changes
///
/// This provides a standard implementation for fetching updated metadata
/// and replacing items in lists, while allowing each screen to customize
/// which lists should be updated.
mixin ItemUpdatable<T extends StatefulWidget> on State<T> {
  /// Updates a single item in the screen's list(s) after watch state changes
  ///
  /// Fetches the latest metadata with images (including clearLogo) and
  /// calls [updateItemInLists] to update the appropriate list(s).
  ///
  /// If the fetch fails, the error is silently caught and the item will
  /// be updated on the next full refresh.
  Future<void> updateItem(MediaItem source) async {
    if (!mounted) return;

    final serverId = source.serverId;
    if (serverId == null) return;

    try {
      final updatedItem = await context.tryGetMediaClientForServer(ServerId(serverId))?.fetchItem(source.id);
      if (updatedItem != null) {
        if (!mounted) return;
        setState(() {
          updateItemInLists(source.globalKey, updatedItem);
        });
      }
    } catch (e) {
      // Silently fail - the item will update on next full refresh
    }
  }

  /// Override this method to specify which list(s) should be updated.
  ///
  /// This method is called within [setState], so implementations should
  /// directly modify their lists without calling [setState] again.
  ///
  /// [sourceGlobalKey] is the server-qualified identity of the item that
  /// initiated the refresh.
  void updateItemInLists(String sourceGlobalKey, MediaItem updatedItem);
}
