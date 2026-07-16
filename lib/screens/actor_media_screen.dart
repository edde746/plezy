import 'package:flutter/material.dart';
import '../media/ids.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../media/library_query.dart';
import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../mixins/paginated_item_loader.dart';
import '../utils/app_logger.dart';
import '../utils/media_server_http_client.dart';
import '../utils/provider_extensions.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/optimized_media_image.dart';
import '../utils/media_image_helper.dart';
import '../i18n/strings.g.dart';
import 'base_media_list_detail_screen.dart';
import 'focusable_detail_screen_mixin.dart';
import '../mixins/grid_focus_node_mixin.dart';
import '../focus/focusable_action_bar.dart';

/// Screen to browse all media featuring a specific actor.
class ActorMediaScreen extends StatefulWidget {
  final String actorName;
  final String personId;
  final String? actorThumb;
  final String? characterName;
  final String serverId;
  final String? serverName;
  final MediaBackend backend;

  const ActorMediaScreen({
    super.key,
    required this.actorName,
    required this.personId,
    this.actorThumb,
    this.characterName,
    required this.serverId,
    this.serverName,
    required this.backend,
  });

  @override
  State<ActorMediaScreen> createState() => _ActorMediaScreenState();
}

class _ActorMediaScreenState extends BaseMediaListDetailScreen<ActorMediaScreen>
    with
        GridFocusNodeMixin<ActorMediaScreen>,
        FocusableDetailScreenMixin<ActorMediaScreen>,
        PaginatedItemLoader<MediaItem, ActorMediaScreen> {
  static const int _pageSize = 200;

  @override
  MediaItem get mediaItem => MediaItem(
    id: '',
    backend: widget.backend,
    kind: MediaKind.unknown,
    serverId: widget.serverId,
    serverName: widget.serverName,
  );

  @override
  String get title => widget.actorName;

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

  MediaServerClient get _mediaClient => context.getMediaClientForServer(ServerId(widget.serverId));

  @override
  Future<LibraryPage<MediaItem>> fetchPage(int start, int size, AbortController? abort) {
    return _mediaClient.fetchPersonMediaPage(widget.personId, start: start, size: size, abort: abort);
  }

  @override
  void updateItemInLists(String sourceGlobalKey, MediaItem updatedItem) {
    for (final entry in loadedItems.entries) {
      if (entry.value.globalKey == sourceGlobalKey) {
        loadedItems[entry.key] = updatedItem;
        return;
      }
    }
  }

  @override
  Future<void> loadItems() async {
    await loadInitialPaginatedItems(
      pageSize: _pageSize,
      resetViewState: () {
        isLoading = true;
        errorMessage = null;
        items = [];
      },
      applyLoadedItems: (loaded) {
        items = loaded;
        isLoading = false;
      },
      applyError: (error, _) {
        errorMessage = t.messages.errorLoading(error: error.toString());
        isLoading = false;
      },
      onLoaded: (loadedCount, totalCount) {
        appLogger.d('Loaded $loadedCount of $totalCount items for actor: ${widget.actorName}');
        autoFocusFirstItemAfterLoad();
      },
      onError: (error, stackTrace) {
        appLogger.e('Failed to load actor media', error: error, stackTrace: stackTrace);
      },
    );
  }

  @override
  List<FocusableAction> getAppBarActions() {
    return [];
  }

  Widget _buildActorHeader() {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: OptimizedMediaImage(
                client: _mediaClient,
                imagePath: widget.actorThumb,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                imageType: ImageType.avatar,
                fallbackIcon: Symbols.person_rounded,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    widget.actorName,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: .bold),
                    maxLines: 2,
                    overflow: .ellipsis,
                  ),
                  if (widget.characterName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.characterName!,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: .ellipsis,
                    ),
                  ],
                  if (totalSize > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$totalSize ${totalSize == 1 ? 'title' : 'titles'}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildDetailScaffold(
      slivers: [
        CustomAppBar(title: Text(widget.actorName), pinned: true, actions: buildFocusableAppBarActions()),
        _buildActorHeader(),
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
