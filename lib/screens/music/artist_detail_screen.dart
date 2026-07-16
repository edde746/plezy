import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/focusable_action_bar.dart';
import '../../focus/key_event_utils.dart';
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
import '../../widgets/ios_status_bar_tap_scroll_to_top.dart';
import '../../widgets/music/mini_player.dart';
import '../../widgets/music/music_detail_header.dart';
import '../../widgets/music/music_actions.dart';
import '../../widgets/optimized_media_image.dart';
import '../../widgets/overlay_sheet.dart';
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

  @override
  Object get mediaItem => widget.artist;

  @override
  String get title => widget.artist.displayTitle;

  @override
  String get emptyMessage => t.messages.noItemsAvailable;

  @override
  bool get hasItems => items.isNotEmpty;

  @override
  Future<List<MediaItem>> fetchItems() => mediaClient.fetchArtistAlbums(widget.artist.id);

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
  /// listing this screen loads, so this costs one extra server round-trip —
  /// gated on playback availability first so the stub never fetches.
  Future<void> _playAll({bool shuffle = false}) async {
    if (!ensureMusicPlaybackAvailable(context)) return;
    List<MediaItem> tracks;
    try {
      tracks = await mediaClient.fetchPlayableDescendants(widget.artist.id);
    } catch (e, stackTrace) {
      final message = localizedLoadErrorMessage(e, stackTrace, context: widget.artist.displayTitle);
      if (mounted) showErrorSnackBar(context, message);
      return;
    }
    if (!mounted) return;
    if (tracks.isEmpty) {
      showAppSnackBar(context, emptyMessage);
      return;
    }
    await playTracks(
      context,
      tracks: tracks,
      playContext: MusicPlayContext(
        id: widget.artist.id,
        title: widget.artist.displayTitle,
        kind: MusicPlayContextKind.artist,
      ),
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

  @override
  Widget build(BuildContext context) {
    return PrimaryScrollController(
      controller: scrollController,
      child: IosStatusBarTapScrollToTop(
        controller: scrollController,
        child: OverlaySheetHost(
          // Host owns sheet + system back: a back with a sheet open closes it;
          // otherwise focus the action row first, then pop.
          canPop: PlatformDetector.isHandheldIOS(context),
          onSystemBack: () {
            if (BackKeyCoordinator.consumeIfHandled()) return;
            if (handleBackNavigation() && mounted) Navigator.pop(context);
          },
          child: Scaffold(
            body: CustomScrollView(
              primary: true,
              slivers: [
                CustomAppBar(title: Text(widget.artist.displayTitle)),
                SliverToBoxAdapter(child: _buildHeader()),
                ...buildStateSlivers(),
                // Albums arrive newest-first from both backends — no client-side sort.
                if (hasItems) buildFocusableGrid(items: items, onRefresh: updateItem, shape: CardShape.square),
                // Keep the last rows reachable above the floating mini-player.
                SliverToBoxAdapter(
                  child: SizedBox(height: context.watch<MiniPlayerInsetController?>()?.overlayHeight ?? 0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
