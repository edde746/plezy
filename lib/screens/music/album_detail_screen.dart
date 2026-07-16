import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/focus_theme.dart';
import '../../focus/focusable_action_bar.dart';
import '../../focus/input_mode_tracker.dart';
import '../../focus/key_event_utils.dart';
import '../../i18n/strings.g.dart';
import '../../media/ids.dart';
import '../../media/media_item.dart';
import '../../mixins/grid_focus_node_mixin.dart';
import '../../models/download_models.dart';
import '../../providers/download_provider.dart';
import '../../services/music/music_playback_service.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/app_logger.dart';
import '../../utils/dialogs.dart';
import '../../utils/formatters.dart';
import '../../utils/media_image_helper.dart';
import '../../utils/music_navigation.dart';
import '../../utils/platform_detector.dart';
import '../../utils/provider_extensions.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/desktop_app_bar.dart';
import '../../widgets/download_status_icon.dart';
import '../../widgets/ios_status_bar_tap_scroll_to_top.dart';
import '../../widgets/media_context_menu.dart';
import '../../widgets/music/mini_player.dart';
import '../../widgets/music/music_detail_header.dart';
import '../../widgets/music/music_actions.dart';
import '../../widgets/music/track_row.dart';
import '../../widgets/optimized_media_image.dart';
import '../../widgets/overlay_sheet.dart';
import '../base_media_list_detail_screen.dart';
import '../focusable_detail_screen_mixin.dart';

/// Detail screen for a music album: square cover header, Play/Shuffle/
/// Instant Mix action row, and the track list rendered as grouped
/// [TrackRow] cards with per-disc headers on multi-disc albums.
class AlbumDetailScreen extends StatefulWidget {
  final MediaItem album;

  const AlbumDetailScreen({super.key, required this.album});

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

/// A row of the track list: either a disc header ([discNumber] non-null) or
/// the track at [trackIndex]. [isFirst]/[isLast] mark the track's position
/// within its disc group for the grouped-card corner radii.
class _TrackListEntry {
  final int? discNumber;
  final int? trackIndex;
  final bool isFirst;
  final bool isLast;

  const _TrackListEntry.header(int this.discNumber) : trackIndex = null, isFirst = false, isLast = false;

  const _TrackListEntry.track(int this.trackIndex, {required this.isFirst, required this.isLast}) : discNumber = null;
}

class _AlbumDetailScreenState extends BaseMediaListDetailScreen<AlbumDetailScreen>
    with
        GridFocusNodeMixin<AlbumDetailScreen>,
        FocusableDetailScreenMixin<AlbumDetailScreen>,
        StandardItemLoader<AlbumDetailScreen> {
  final GlobalKey<MediaContextMenuState> _contextMenuKey = GlobalKey<MediaContextMenuState>();

  @override
  Object get mediaItem => widget.album;

  @override
  String get title => widget.album.displayTitle;

  @override
  String get emptyMessage => t.messages.noItemsAvailable;

  @override
  bool get hasItems => items.isNotEmpty;

  @override
  Future<List<MediaItem>> fetchItems() => mediaClient.fetchAlbumTracks(widget.album.id);

  @override
  Future<void> loadItems() async {
    await super.loadItems();
    autoFocusFirstItemAfterLoad();
  }

  @override
  void dispose() {
    disposeFocusResources();
    super.dispose();
  }

  MusicPlayContext get _playContext =>
      MusicPlayContext(id: widget.album.id, title: widget.album.displayTitle, kind: MusicPlayContextKind.album);

  /// Plays the already-fetched track list — no extra server round-trip.
  Future<void> _playAll({bool shuffle = false}) async {
    if (items.isEmpty) {
      showAppSnackBar(context, emptyMessage);
      return;
    }
    await playTracks(context, tracks: items, playContext: _playContext, shuffle: shuffle);
  }

  Future<void> _openArtist() async {
    final parentId = widget.album.parentId;
    if (parentId == null) return;
    MediaItem? artist;
    try {
      artist = await mediaClient.fetchItem(parentId);
    } catch (e) {
      appLogger.w('Failed to fetch artist $parentId for album ${widget.album.id}', error: e);
    }
    if (artist == null || !mounted) return;
    await navigateToArtist(context, artist);
  }

  void _showOverflowMenuAt(BuildContext buttonContext) {
    final box = buttonContext.findRenderObject() as RenderBox?;
    Offset? position;
    if (box != null) position = box.localToGlobal(box.size.center(Offset.zero));
    _contextMenuKey.currentState?.showContextMenu(buttonContext, position: position);
  }

  /// Album ⋮ — opens the item's standard context menu (Instant Mix, Go to
  /// artist, Mark played/unplayed…), same pattern as the media detail row.
  FocusableAction _overflowAction() {
    return FocusableAction(
      debugLabel: 'album_more',
      onPressed: () => _contextMenuKey.currentState?.showContextMenu(context),
      builder: (context, state) => MediaContextMenu(
        key: _contextMenuKey,
        item: widget.album,
        child: Builder(
          builder: (buttonContext) => Container(
            decoration: FocusTheme.focusBackgroundDecoration(isFocused: state.showFocus, borderRadius: 20),
            child: IconButton(
              icon: const AppIcon(Symbols.more_vert_rounded, fill: 1),
              onPressed: () => _showOverflowMenuAt(buttonContext),
            ),
          ),
        ),
      ),
    );
  }

  /// Queue the album (expands to its tracks) or, when fully downloaded,
  /// offer deletion. Queued/downloading states are inert — the button just
  /// reflects progress.
  Future<void> _handleDownloadPressed() async {
    final downloadProvider = context.read<DownloadProvider>();
    final globalKey = widget.album.globalKey;
    final progress = downloadProvider.getProgress(globalKey);

    if (downloadProvider.isQueueing(globalKey) ||
        progress?.status == DownloadStatus.queued ||
        progress?.status == DownloadStatus.downloading) {
      return;
    }

    if (downloadProvider.isDownloaded(globalKey)) {
      final confirmed = await showDeleteConfirmation(
        context,
        title: t.downloads.deleteDownload,
        message: t.downloads.deleteConfirm(title: widget.album.displayTitle),
      );
      if (!confirmed || !mounted) return;
      await downloadProvider.deleteDownload(globalKey);
      if (mounted) showSuccessSnackBar(context, t.downloads.downloadDeleted);
      return;
    }

    // Not downloaded (or partial/failed): queue the album — already-active
    // tracks are skipped inside the provider, so this also fills gaps.
    try {
      final count = await downloadProvider.queueDownload(widget.album, mediaClient);
      if (!mounted) return;
      showSuccessSnackBar(context, count > 1 ? t.downloads.tracksQueued(count: count) : t.downloads.downloadQueued);
    } on CellularDownloadBlockedException {
      if (mounted) showErrorSnackBar(context, t.settings.cellularDownloadBlocked);
    } catch (e) {
      appLogger.e('Failed to queue album download', error: e);
      if (mounted) showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
    }
  }

  /// Album download button — mirrors the media-detail download action's
  /// states in compact form. Hidden on Apple TV (no user-accessible storage)
  /// and when no [DownloadProvider] is in scope.
  FocusableAction? _downloadAction() {
    if (PlatformDetector.isAppleTV()) return null;
    if (widget.album.serverId == null || context.read<DownloadProvider?>() == null) return null;

    return FocusableAction(
      debugLabel: 'album_download',
      onPressed: () => unawaited(_handleDownloadPressed()),
      builder: (context, state) => Consumer<DownloadProvider>(
        builder: (context, downloadProvider, _) {
          final globalKey = widget.album.globalKey;
          final progress = downloadProvider.getProgress(globalKey);
          final isQueueing = downloadProvider.isQueueing(globalKey);
          final status = progress?.status;

          final Widget icon;
          final String tooltip;
          if (isQueueing) {
            icon = const DownloadQueueingSpinner(size: 20);
            tooltip = t.downloads.downloadingTooltip;
          } else if (status == DownloadStatus.queued) {
            icon = const AppIcon(Symbols.schedule_rounded, fill: 1);
            tooltip = t.downloads.queuedTooltip;
          } else if (status == DownloadStatus.downloading) {
            icon = DownloadStatusIcon(
              status: DownloadStatus.downloading,
              size: 20,
              progress: progress?.progressPercent,
            );
            tooltip = t.downloads.downloadingTooltip;
          } else if (status == DownloadStatus.completed) {
            icon = const AppIcon(Symbols.download_done_rounded, fill: 1);
            tooltip = t.downloads.deleteDownload;
          } else if (status == DownloadStatus.partial) {
            icon = const AppIcon(Symbols.downloading_rounded, fill: 1);
            tooltip = t.downloads.partialDownloadClickToComplete;
          } else {
            icon = const AppIcon(Symbols.download_rounded, fill: 1);
            tooltip = t.downloads.downloadNow;
          }

          return Container(
            decoration: FocusTheme.focusBackgroundDecoration(isFocused: state.showFocus, borderRadius: 20),
            child: IconButton(icon: icon, tooltip: tooltip, onPressed: () => unawaited(_handleDownloadPressed())),
          );
        },
      ),
    );
  }

  @override
  List<FocusableAction> getAppBarActions() {
    final client = context.tryGetMediaClientWithFallback(serverIdOrNull(widget.album.serverId));
    return buildMusicActions(
      onPlay: () => unawaited(_playAll()),
      onShuffle: () => unawaited(_playAll(shuffle: true)),
      onInstantMix: (client?.capabilities.instantMix ?? false)
          ? () => unawaited(playInstantMix(context, widget.album))
          : null,
      download: _downloadAction(),
      trailing: _overflowAction(),
    );
  }

  int get _totalDurationMs => items.fold(0, (sum, item) => sum + (item.durationMs ?? 0));

  Widget _buildHeader() {
    final tk = tokens(context);
    final textTheme = Theme.of(context).textTheme;
    final client = context.tryGetMediaClientWithFallback(serverIdOrNull(widget.album.serverId));
    final artistName = widget.album.albumArtistTitle;

    final metaParts = <String>[
      if (widget.album.year != null) '${widget.album.year}',
      if (items.isNotEmpty) t.music.trackCount(n: items.length),
      if (_totalDurationMs > 0) formatDurationTextual(_totalDurationMs),
    ];

    Widget cover(double size) => ClipRRect(
      borderRadius: BorderRadius.circular(tk.radiusLg),
      child: OptimizedMediaImage(
        client: client,
        imagePath: widget.album.thumbPath,
        imageType: ImageType.square,
        width: size,
        height: size,
        fallbackIcon: Symbols.album_rounded,
      ),
    );

    Widget info({required bool centered}) => Column(
      mainAxisSize: .min,
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          widget.album.displayTitle,
          style: textTheme.titleLarge,
          textAlign: centered ? TextAlign.center : TextAlign.start,
        ),
        if (artistName != null && artistName.isNotEmpty) ...[
          const SizedBox(height: 4),
          _ArtistLink(name: artistName, onTap: widget.album.parentId == null ? null : () => unawaited(_openArtist())),
        ],
        if (metaParts.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(toBulletedString(metaParts), style: textTheme.bodyMedium?.copyWith(color: tk.textMuted)),
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
      artworkBuilder: cover,
      infoBuilder: info,
      actionBar: actionRow,
      compactArtworkSize: 200,
      compactArtworkSpacing: 16,
      wideAlignment: CrossAxisAlignment.end,
    );
  }

  /// Flattens tracks into list rows, inserting disc headers when the album
  /// spans multiple discs. Tracks arrive in disc/track order from both
  /// backends, so grouping is a single pass.
  List<_TrackListEntry> _rowModels() {
    final multiDisc = items.map((item) => item.discNumber ?? 1).toSet().length > 1;
    final rows = <_TrackListEntry>[];
    for (var i = 0; i < items.length; i++) {
      final disc = items[i].discNumber ?? 1;
      final previousDisc = i > 0 ? (items[i - 1].discNumber ?? 1) : null;
      final nextDisc = i < items.length - 1 ? (items[i + 1].discNumber ?? 1) : null;
      if (multiDisc && disc != previousDisc) rows.add(_TrackListEntry.header(disc));
      rows.add(
        _TrackListEntry.track(
          i,
          isFirst: multiDisc ? disc != previousDisc : i == 0,
          isLast: multiDisc ? disc != nextDisc : i == items.length - 1,
        ),
      );
    }
    return rows;
  }

  Widget _buildTrackList() {
    final tk = tokens(context);
    final rows = _rowModels();
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      sliver: SliverList.builder(
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];
          final disc = row.discNumber;
          if (disc != null) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, index == 0 ? 0 : 16, 16, 8),
              child: Text(
                t.music.discNumber(n: disc),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: tk.textMuted, fontWeight: .w600),
              ),
            );
          }
          final trackIndex = row.trackIndex!;
          final item = items[trackIndex];
          return Padding(
            padding: EdgeInsets.only(top: row.isFirst ? 0 : tk.groupGap),
            child: TrackRow(
              key: ValueKey(item.id),
              item: item,
              isFirst: row.isFirst,
              isLast: row.isLast,
              showDownloadStatus: true,
              focusNode: focusNodeForIndex(trackIndex, firstItemFocusNode, prefix: 'detail_grid_item'),
              onNavigateUp: trackIndex == 0 ? navigateToAppBar : null,
              onBack: handleBackFromContent,
              onFocusChange: (hasFocus) => trackGridItemFocus(trackIndex, hasFocus),
              onRefresh: updateItem,
              onTap: () => unawaited(playTracks(context, tracks: items, startTrack: item, playContext: _playContext)),
            ),
          );
        },
      ),
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
                CustomAppBar(title: Text(widget.album.displayTitle)),
                SliverToBoxAdapter(child: _buildHeader()),
                ...buildStateSlivers(),
                if (hasItems) _buildTrackList(),
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

/// Tappable, focusable artist line under the album title. Focus renders as a
/// background fill (never an outline); SELECT activates like a tap.
class _ArtistLink extends StatefulWidget {
  final String name;
  final VoidCallback? onTap;

  const _ArtistLink({required this.name, this.onTap});

  @override
  State<_ArtistLink> createState() => _ArtistLinkState();
}

class _ArtistLinkState extends State<_ArtistLink> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'album_artist_link');
  bool _focused = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: .w500);
    if (widget.onTap == null) return Text(widget.name, style: style);

    final showFocus = _focused && InputModeTracker.isKeyboardMode(context);
    return Semantics(
      button: true,
      enabled: true,
      label: widget.name,
      onTap: widget.onTap,
      child: ExcludeSemantics(
        child: Focus(
          focusNode: _focusNode,
          onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
          onKeyEvent: dpadKeyHandler(onSelect: widget.onTap),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: FocusTheme.getAnimationDuration(context),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: FocusTheme.focusBackgroundDecoration(isFocused: showFocus),
                child: Text(widget.name, style: style),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
