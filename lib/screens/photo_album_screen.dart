import 'package:flutter/material.dart';
import '../focus/focusable_action_bar.dart';
import '../i18n/strings.g.dart';
import '../media/library_query.dart';
import '../media/media_item.dart';
import '../mixins/grid_focus_node_mixin.dart';
import '../mixins/paginated_item_loader.dart';
import '../mixins/standard_paginated_view.dart';
import '../utils/app_logger.dart';
import '../utils/error_message_utils.dart';
import '../utils/media_server_http_client.dart';
import '../widgets/desktop_app_bar.dart';
import 'base_media_list_detail_screen.dart';
import 'focusable_detail_screen_mixin.dart';

/// Grid of what a photo album holds: photos, clips and nested albums, each of
/// which opens the way its own card does.
class PhotoAlbumScreen extends StatefulWidget {
  final MediaItem album;

  const PhotoAlbumScreen({super.key, required this.album});

  @override
  State<PhotoAlbumScreen> createState() => _PhotoAlbumScreenState();
}

class _PhotoAlbumScreenState extends BaseMediaListDetailScreen<PhotoAlbumScreen>
    with
        GridFocusNodeMixin<PhotoAlbumScreen>,
        FocusableDetailScreenMixin<PhotoAlbumScreen>,
        PaginatedItemLoader<MediaItem, PhotoAlbumScreen>,
        PaginatedItemUpdatable<PhotoAlbumScreen>,
        StandardPaginatedView<MediaItem, PhotoAlbumScreen> {
  static const int _pageSize = 200;

  @override
  MediaItem get mediaItem => widget.album;

  @override
  String get title => widget.album.displayTitle;

  @override
  String get emptyMessage => t.discover.noContentAvailable;

  @override
  bool get hasItems => totalSize > 0;

  @override
  void dispose() {
    disposePagination();
    disposeFocusResources();
    super.dispose();
  }

  @override
  Future<LibraryPage<MediaItem>> fetchPage(int start, int size, AbortController? abort) {
    return mediaClient.fetchChildrenPage(widget.album.id, start: start, size: size, abort: abort);
  }

  @override
  Future<void> loadItems() {
    return loadStandardPaginatedItems(
      pageSize: _pageSize,
      errorMessageFor: (error, stackTrace) => localizedLoadErrorMessage(error, stackTrace, context: title),
      onLoaded: (loadedCount, totalCount) {
        appLogger.d('Loaded $loadedCount of $totalCount items for photo album: $title');
        autoFocusFirstItemAfterLoad();
      },
    );
  }

  @override
  List<FocusableAction> getAppBarActions() => const [];

  @override
  Widget build(BuildContext context) {
    return buildDetailScaffold(
      slivers: [
        CustomAppBar(
          title: Text(title),
          pinned: true,
          actions: buildFocusableAppBarActions(),
          onBackPressed: popFromAppBar,
        ),
        ...buildStateSlivers(),
        if (hasItems)
          buildSparseFocusableGrid(
            totalItems: totalSize,
            itemAt: (index) => loadedItems[index],
            onRefresh: updateItem,
            onSkeletonVisible: (index) => ensureIndexLoaded(index, pageSize: _pageSize),
          ),
      ],
    );
  }
}
