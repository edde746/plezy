import 'package:flutter/widgets.dart';

import '../media/media_item.dart';
import 'item_updatable.dart';
import 'paginated_item_loader.dart';

/// Standard view-state wiring for screens whose body is a single paginated
/// list.
///
/// [PaginatedItemLoader] owns the sparse `loadedItems` map; the hosts
/// (`BaseMediaListDetailScreen`, `BaseLibraryTabState`) additionally expose
/// `items` / `isLoading` / `errorMessage` to drive the loading, empty and
/// error chrome. This mixin owns the transitions between the two, so a
/// screen's `loadItems` supplies only the page size, the error text, and an
/// optional post-load hook.
mixin StandardPaginatedView<T, W extends StatefulWidget> on PaginatedItemLoader<T, W> {
  set items(List<T> value);
  set isLoading(bool value);
  set errorMessage(String? value);

  /// Initial-load transaction: clears the view state, fetches the first page,
  /// then publishes either the loaded items or [errorMessageFor]'s text.
  ///
  /// Stale results — a newer load started, or the screen was disposed — are
  /// dropped without touching state. [errorMessageFor] runs even when
  /// unmounted, so screens can log from it; [onLoaded] runs only after a
  /// successful publish.
  Future<void> loadStandardPaginatedItems({
    required int pageSize,
    required String Function(Object error, StackTrace stackTrace) errorMessageFor,
    void Function(int loadedCount, int totalCount)? onLoaded,
  }) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      items = [];
      resetPaginationState();
    });

    try {
      final initialPage = await loadInitialPageWithStatus(pageSize);
      if (!initialPage.applied || !mounted) return;

      setState(() {
        items = loadedItems.values.toList();
        isLoading = false;
      });
      onLoaded?.call(loadedItems.length, totalSize);
    } catch (error, stackTrace) {
      final message = errorMessageFor(error, stackTrace);
      if (!mounted) return;
      setState(() {
        errorMessage = message;
        isLoading = false;
      });
    }
  }
}

/// [ItemUpdatable.updateItemInLists] for screens whose visible list is the
/// sparse `loadedItems` map rather than a flat `items` list — searching the
/// map is what keeps an item refreshed at a scrolled-in position, past the
/// first page.
mixin PaginatedItemUpdatable<W extends StatefulWidget> on PaginatedItemLoader<MediaItem, W>, ItemUpdatable<W> {
  @override
  void updateItemInLists(String sourceGlobalKey, MediaItem updatedItem) {
    for (final entry in loadedItems.entries) {
      if (entry.value.globalKey == sourceGlobalKey) {
        loadedItems[entry.key] = updatedItem;
        return;
      }
    }
  }
}
