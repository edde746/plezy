import 'package:flutter/material.dart';
import '../services/plex_client.dart';
import '../models/plex_metadata.dart';

/// Mixin for screens that need to update individual items after watch state changes
///
/// This provides a standard implementation for fetching updated metadata
/// and replacing items in lists, while allowing each screen to customize
/// which lists should be updated.
mixin ItemUpdatable<T extends StatefulWidget> on State<T> {
  /// The Plex client to use for fetching updated metadata
  /// Each screen must provide access to their client
  PlexClient get client;

  /// Updates a single item in the screen's list(s) after watch state changes
  ///
  /// Fetches the latest metadata with images (including clearLogo) and
  /// calls [updateItemInLists] to update the appropriate list(s).
  ///
  /// If the fetch fails, the error is silently caught and the item will
  /// be updated on the next full refresh.
  Future<void> updateItem(String ratingKey) async {
    try {
      final updatedMetadata = await client.getMetadataWithImages(ratingKey);
      if (updatedMetadata != null) {
        setState(() {
          updateItemInLists(ratingKey, updatedMetadata);
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
  /// void updateItemInLists(String ratingKey, PlexMetadata updatedMetadata) {
  ///   final index = _items.indexWhere((item) => item.ratingKey == ratingKey);
  ///   if (index != -1) {
  ///     _items[index] = updatedMetadata;
  ///   }
  /// }
  /// ```
  void updateItemInLists(String ratingKey, PlexMetadata updatedMetadata);
}
