import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../models/plex_metadata.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/plex_optimized_image.dart';
import '../utils/plex_image_helper.dart';
import '../i18n/strings.g.dart';
import 'base_media_list_detail_screen.dart';
import 'focusable_detail_screen_mixin.dart';
import '../mixins/grid_focus_node_mixin.dart';
import '../focus/focusable_action_bar.dart';

/// Screen to browse all media featuring a specific actor
class ActorMediaScreen extends StatefulWidget {
  final String actorName;
  final String personId;
  final String? actorThumb;
  final String? characterName;
  final String serverId;
  final String? serverName;

  const ActorMediaScreen({
    super.key,
    required this.actorName,
    required this.personId,
    this.actorThumb,
    this.characterName,
    required this.serverId,
    this.serverName,
  });

  @override
  State<ActorMediaScreen> createState() => _ActorMediaScreenState();
}

class _ActorMediaScreenState extends BaseMediaListDetailScreen<ActorMediaScreen>
    with
        StandardItemLoader<ActorMediaScreen>,
        GridFocusNodeMixin<ActorMediaScreen>,
        FocusableDetailScreenMixin<ActorMediaScreen> {
  @override
  PlexMetadata get mediaItem => PlexMetadata(ratingKey: '', serverId: widget.serverId, serverName: widget.serverName);

  @override
  String get title => widget.actorName;

  @override
  String get emptyMessage => t.discover.noContentAvailable;

  @override
  bool get hasItems => items.isNotEmpty;

  @override
  void dispose() {
    disposeFocusResources();
    super.dispose();
  }

  @override
  Future<List<PlexMetadata>> fetchItems() async {
    return await client.fetchAllPersonMedia(widget.personId);
  }

  @override
  Future<void> loadItems() async {
    await super.loadItems();
    autoFocusFirstItemAfterLoad();
  }

  @override
  List<FocusableAction> getAppBarActions() {
    return [];
  }

  Widget _buildActorHeader() {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: PlexOptimizedImage(
                client: client,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.actorName,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.characterName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.characterName!,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${items.length} ${items.length == 1 ? 'title' : 'titles'}',
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
        if (items.isNotEmpty) buildFocusableGrid(items: items, onRefresh: updateItem),
      ],
    );
  }
}
