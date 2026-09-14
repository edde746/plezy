import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/focusable_action_bar.dart';
import '../../media/artist_discography.dart';
import '../../i18n/strings.g.dart';
import '../../media/ids.dart';
import '../../media/media_item.dart';
import '../../mixins/grid_focus_node_mixin.dart';
import '../../services/music/music_playback_service.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/formatters.dart';
import '../../utils/error_message_utils.dart';
import '../../utils/media_image_helper.dart';
import '../../utils/music_navigation.dart';
import '../../utils/platform_detector.dart';
import '../../utils/provider_extensions.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/collapsible_text.dart';
import '../../widgets/desktop_app_bar.dart';
import '../../widgets/music/mini_player.dart';
import '../../widgets/music/music_detail_header.dart';
import '../../widgets/music/music_actions.dart';
import '../../widgets/optimized_media_image.dart';
import '../base_media_list_detail_screen.dart';
import '../focusable_detail_screen_mixin.dart';

/// Detail screen for a music artist: circular artist image, genres and
/// collapsible bio, Play/Shuffle/Instant Mix action row, and the artist's
/// albums as a square-card grid (album tap → album detail).
class ArtistDetailScreen extends StatefulWidget {
  final MediaItem artist;

  const ArtistDetailScreen({super.key, required this.artist});

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends BaseMediaListDetailScreen<ArtistDetailScreen>
    with
        GridFocusNodeMixin<ArtistDetailScreen>,
        FocusableDetailScreenMixin<ArtistDetailScreen>,
        StandardItemLoader<ArtistDetailScreen> {
  final FocusNode _bioFocusNode = FocusNode(debugLabel: 'artist_bio');

  /// Discography sections in display order. A single flat `albums` group
  /// (Plex with no singles/live/compilations, or any Jellyfin/Emby artist)
  /// renders the flat grid. The sections mirror the concatenation order of
  /// [items], so [updateItem]'s in-place swap stays visible.
  List<ArtistDiscographyGroup> _discographyGroups = const [];

  @override
  Object get mediaItem => widget.artist;

  @override
  String get title => widget.artist.displayTitle;

  @override
  String get emptyMessage => t.messages.noItemsAvailable;

  @override
  bool get hasItems => items.isNotEmpty;

  @override
  Future<List<MediaItem>> fetchItems() async {
    final groups = await mediaClient.fetchArtistDiscography(widget.artist);
    _discographyGroups = groups;
    // Flat concatenation keeps BaseMediaListDetailScreen/StandardItemLoader/
    // updateItem working against one list; the grouped slivers slice it.
    return [for (final group in groups) ...group.items];
  }

  @override
  Future<void> loadItems() async {
    await super.loadItems();
    autoFocusFirstItemAfterLoad();
  }

  @override
  void dispose() {
    _bioFocusNode.dispose();
    disposeFocusResources();
    super.dispose();
  }

  /// Plays the artist's full track list. The tracks aren't part of the album
  /// listing this screen loads, so this costs one extra server round-trip.
  Future<void> _playAll({bool shuffle = false}) async {
    await playFetchedTracks(
      context,
      fetch: () => mediaClient.fetchPlayableDescendants(widget.artist.id),
      playContext: MusicPlayContext(title: widget.artist.displayTitle, kind: MusicPlayContextKind.artist),
      onError: (e, stackTrace) =>
          showErrorSnackBar(context, localizedLoadErrorMessage(e, stackTrace, context: widget.artist.displayTitle)),
      onEmpty: () => showAppSnackBar(context, emptyMessage),
      shuffle: shuffle,
    );
  }

  @override
  List<FocusableAction> getAppBarActions() {
    final client = context.tryGetMediaClientWithFallback(serverIdOrNull(widget.artist.serverId));
    return buildMusicActions(
      onPlay: () => unawaited(_playAll()),
      onShuffle: () => unawaited(_playAll(shuffle: true)),
      onInstantMix: (client?.capabilities.instantMix ?? false)
          ? () => unawaited(playInstantMix(context, widget.artist))
          : null,
    );
  }

  Widget _buildHeader() {
    final tk = tokens(context);
    final textTheme = Theme.of(context).textTheme;
    final client = context.tryGetMediaClientWithFallback(serverIdOrNull(widget.artist.serverId));
    final genres = widget.artist.genres ?? const [];
    final summary = widget.artist.summary;

    Widget portrait(double size) => ClipOval(
      child: OptimizedMediaImage(
        client: client,
        imagePath: widget.artist.thumbPath,
        imageType: ImageType.square,
        width: size,
        height: size,
        fallbackIcon: Symbols.artist_rounded,
      ),
    );

    Widget info({required bool centered}) => Column(
      mainAxisSize: .min,
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          widget.artist.displayTitle,
          style: textTheme.titleLarge,
          textAlign: centered ? TextAlign.center : TextAlign.start,
        ),
        if (genres.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            toBulletedString(genres),
            style: textTheme.bodyMedium?.copyWith(color: tk.textMuted),
            textAlign: centered ? TextAlign.center : TextAlign.start,
          ),
        ],
        if (summary != null && summary.isNotEmpty) ...[
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: CollapsibleText(
              text: summary,
              maxLines: 3,
              style: textTheme.bodyMedium?.copyWith(color: tk.textMuted),
              focusNode: _bioFocusNode,
              skipTraversal: false,
            ),
          ),
        ],
      ],
    );

    final actionRow = FocusableActionBar(
      key: actionBarKey,
      spacing: 4,
      actions: getAppBarActions(),
      onNavigateDown: navigateToGrid,
      onBack: () => Navigator.pop(context),
    );

    return MusicDetailHeader(
      artworkBuilder: portrait,
      infoBuilder: info,
      actionBar: actionRow,
      compactArtworkSize: 140,
      compactArtworkSpacing: 12,
      compactBottomSpacing: 8,
    );
  }

  /// Discography slivers. One group (or a backend without grouping) renders
  /// exactly today's flat grid; multiple groups render a titled section per
  /// group. Every section's grid shares the screen-global focus index space
  /// so D-pad navigation and [navigateToGrid] restore work across sections.
  List<Widget> _buildDiscographySlivers(BuildContext context) {
    if (_discographyGroups.length <= 1) {
      return [buildFocusableGrid(items: items, onRefresh: updateItem, shape: CardShape.square)];
    }

    final sectionTitleStyle = Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: .bold, fontSize: PlatformDetector.isTV() ? 28 : null);

    final slivers = <Widget>[];
    var offset = 0;
    for (final group in _discographyGroups) {
      final groupItems = items.sublist(offset, offset + group.items.length);
      final sectionOffset = offset;
      offset += group.items.length;
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(_discographyGroupTitle(group.kind), style: sectionTitleStyle),
          ),
        ),
      );
      slivers.add(
        buildFocusableGrid(
          items: groupItems,
          onRefresh: updateItem,
          shape: CardShape.square,
          indexOffset: sectionOffset,
        ),
      );
    }
    return slivers;
  }

  String _discographyGroupTitle(DiscographyGroupKind kind) => switch (kind) {
    DiscographyGroupKind.albums => t.libraries.groupings.albums,
    DiscographyGroupKind.singlesAndEps => t.music.discography.singlesAndEps,
    DiscographyGroupKind.live => t.music.discography.live,
    DiscographyGroupKind.compilations => t.music.discography.compilations,
  };

  @override
  Widget build(BuildContext context) {
    return buildDetailScaffold(
      slivers: [
        CustomAppBar(title: Text(widget.artist.displayTitle)),
        SliverToBoxAdapter(child: _buildHeader()),
        ...buildStateSlivers(),
        // Albums arrive newest-first from both backends — no client-side sort.
        if (hasItems) ..._buildDiscographySlivers(context),
        // Keep the last rows reachable above the floating mini-player.
        SliverToBoxAdapter(child: SizedBox(height: context.watch<MiniPlayerInsetController?>()?.overlayHeight ?? 0)),
      ],
    );
  }
}
