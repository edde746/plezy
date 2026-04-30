import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../exceptions/media_server_exceptions.dart';
import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_playlist.dart';
import '../media/media_server_client.dart';
import '../media/media_version.dart';
import '../services/plex_client.dart';
import '../services/media_list_playback_launcher.dart';
import '../services/playlist_items_loader.dart';
import '../models/transcode_quality_preset.dart';
import '../utils/download_version_utils.dart';
import '../utils/download_utils.dart';
import '../utils/quality_preset_labels.dart';
import '../utils/global_key_utils.dart';
import '../providers/download_provider.dart';
import '../providers/multi_server_provider.dart';
import '../providers/offline_mode_provider.dart';
import '../providers/offline_watch_provider.dart';
import '../profiles/active_profile_provider.dart';
import '../profiles/profile.dart';
import '../utils/provider_extensions.dart';
import '../utils/app_logger.dart';
import '../utils/library_refresh_notifier.dart';
import '../utils/platform_detector.dart';
import '../utils/snackbar_helper.dart';
import '../utils/dialogs.dart';
import '../utils/focus_utils.dart';
import '../services/external_player_service.dart';
import '../focus/focusable_button.dart';
import '../focus/dpad_navigator.dart';
import '../screens/plex_match_screen.dart';
import '../screens/media_detail_screen.dart';
import '../screens/plex_metadata_edit_screen.dart';
import '../utils/smart_deletion_handler.dart';
import '../utils/video_player_navigation.dart';
import '../utils/deletion_notifier.dart';
import '../theme/mono_tokens.dart';
import '../widgets/file_info_bottom_sheet.dart';
import 'pill_input_decoration.dart';
import '../widgets/focusable_list_tile.dart';
import '../widgets/overlay_sheet.dart';
import '../widgets/rating_bottom_sheet.dart';
import '../i18n/strings.g.dart';

/// Helper class to store menu action data
class _MenuAction {
  final String value;
  final IconData icon;
  final String label;
  final Color? hoverColor;
  final Color? foregroundColor;

  _MenuAction({required this.value, required this.icon, required this.label, this.hoverColor, this.foregroundColor});
}

bool isAdminActionAllowedForMediaItem({
  required bool isOwnerOrAdmin,
  required MediaBackend? itemBackend,
  required Profile? activeProfile,
}) {
  final blockedByPlexHomeRole =
      itemBackend == MediaBackend.plex && activeProfile != null && activeProfile.isPlexHome && !activeProfile.plexAdmin;
  return isOwnerOrAdmin && !blockedByPlexHomeRole;
}

/// A reusable wrapper widget that adds a context menu (long press / right click)
/// to any media item with appropriate actions based on the item type.
class MediaContextMenu extends StatefulWidget {
  /// Either a [MediaItem] or a [MediaPlaylist]. Typed as [Object] because
  /// Dart has no nominal union type — guarded at runtime via the
  /// [_itemAsMediaItem] / [_itemAsPlaylist] helpers.
  final Object item;
  final void Function(String itemId)? onRefresh;
  final VoidCallback? onRemoveFromContinueWatching;
  final VoidCallback? onListRefresh; // For refreshing list after deletion
  final VoidCallback? onTap;
  final Widget child;
  final bool isInContinueWatching;
  final String? collectionId; // The collection ID if displaying within a collection

  const MediaContextMenu({
    super.key,
    required this.item,
    this.onRefresh,
    this.onRemoveFromContinueWatching,
    this.onListRefresh,
    this.onTap,
    required this.child,
    this.isInContinueWatching = false,
    this.collectionId,
  });

  @override
  State<MediaContextMenu> createState() => MediaContextMenuState();
}

class MediaContextMenuState extends State<MediaContextMenu> {
  Offset? _tapPosition;

  bool _openedFromKeyboard = false;
  bool _isContextMenuOpen = false;

  bool get isContextMenuOpen => _isContextMenuOpen;

  /// The widget's [item] cast as a [MediaItem]. Returns `null` for playlists.
  MediaItem? get _mediaItem => widget.item is MediaItem ? widget.item as MediaItem : null;

  /// The widget's [item] cast as a [MediaPlaylist]. Returns `null` for media items.
  MediaPlaylist? get _playlist => widget.item is MediaPlaylist ? widget.item as MediaPlaylist : null;

  /// Show the context menu programmatically.
  /// Used for keyboard/gamepad long-press activation.
  /// If [position] is null, the menu will appear at the center of this widget.
  void showContextMenu(BuildContext menuContext, {Offset? position}) {
    _openedFromKeyboard = position == null;
    if (position != null) {
      _tapPosition = position;
    } else {
      // Calculate center of the widget for keyboard activation
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final size = renderBox.size;
        final topLeft = renderBox.localToGlobal(Offset.zero);
        _tapPosition = Offset(topLeft.dx + size.width / 2, topLeft.dy + size.height / 2);
      }
    }
    _showContextMenu(menuContext);
  }

  /// Get the serverId from the typed item.
  String? get _itemServerId => switch (widget.item) {
    MediaItem(:final serverId) => serverId,
    MediaPlaylist(:final serverId) => serverId,
    _ => null,
  };

  /// Item identifier for refresh callbacks.
  String _itemId() => switch (widget.item) {
    MediaItem(:final id) => id,
    MediaPlaylist(:final id) => id,
    _ => '',
  };

  /// Get the correct PlexClient for this item's server. Throws on
  /// non-Plex backends — Plex-only flows (Add to Collection, metadata
  /// edit, etc.) call this directly. Backend-neutral flows must use
  /// [_getMediaClientForItem] instead.
  PlexClient _getClientForItem() => context.getPlexClientWithFallback(_itemServerId);

  /// Backend-neutral client for the active item's server. Used by flows
  /// that work for Jellyfin too (downloads, basic browse).
  MediaServerClient _getMediaClientForItem() => context.getMediaClientWithFallback(_itemServerId);

  void _showContextMenu(BuildContext context) async {
    if (_isContextMenuOpen) return;
    _isContextMenuOpen = true;

    // Capture the currently focused node for restoration after menu closes
    final previousFocus = FocusManager.instance.primaryFocus;
    bool didNavigate = false;

    final mediaItem = _mediaItem;
    final playlist = _playlist;
    final isPlaylist = playlist != null;
    final mediaKind = mediaItem?.kind;
    final isCollection = mediaKind == MediaKind.collection;

    // Backend-aware gate: a few menu items remain Plex-only because the
    // server-side feature has no Jellyfin equivalent (metadata edit, match).
    // No fallback: items without a backend marker show only neutral actions —
    // dispatching a Plex-only action against an unknown-backend item could
    // crash or hit the wrong server.
    final itemBackend = mediaItem?.backend ?? playlist?.backend;
    final isPlex = itemBackend == MediaBackend.plex;

    final isPartiallyWatched = mediaItem?.isPartiallyWatched ?? false;

    final hasActiveProgress =
        mediaKind != null &&
        (mediaKind == MediaKind.movie || mediaKind == MediaKind.episode) &&
        mediaItem?.hasActiveProgress == true;

    // Check if we should use bottom sheet (on iOS and Android)
    final useBottomSheet = Platform.isIOS || Platform.isAndroid;

    // Check if user has admin privileges. Backend-neutral: Plex uses the
    // server-owned flag (folded with the active Plex Home profile's admin
    // bit, when applicable); Jellyfin uses `JellyfinConnection.isAdministrator`
    // captured at sign-in.
    final multiServerProvider = Provider.of<MultiServerProvider>(context, listen: false);
    final activeProfile = context.read<ActiveProfileProvider>().active;
    final isOwnerOrAdmin = _itemServerId != null && multiServerProvider.serverManager.isOwnerOrAdmin(_itemServerId!);
    final isAdmin = isAdminActionAllowedForMediaItem(
      isOwnerOrAdmin: isOwnerOrAdmin,
      itemBackend: itemBackend,
      activeProfile: activeProfile,
    );

    // Backend capabilities — used to gate the "Play Version" item below.
    // Reads the same `capabilities.videoTranscoding` flag the in-player
    // sheet uses so the two surfaces never disagree about what's offered.
    final mediaClient = _itemServerId != null ? multiServerProvider.getClientForServer(_itemServerId!) : null;
    final canTranscode = mediaClient?.capabilities.videoTranscoding ?? false;

    // Build menu actions
    final menuActions = <_MenuAction>[];

    // Special actions for collections and playlists
    if (isCollection || isPlaylist) {
      // Play
      menuActions.add(_MenuAction(value: 'play', icon: Symbols.play_arrow_rounded, label: t.common.play));

      // Shuffle
      menuActions.add(_MenuAction(value: 'shuffle', icon: Symbols.shuffle_rounded, label: t.mediaMenu.shufflePlay));

      // Download + sync-rule management. Video playlists and any collection
      // qualify — collections can contain movies, episodes, and shows.
      final isVideoPlaylist = isPlaylist && playlist.playlistType == 'video';
      if ((isVideoPlaylist || isCollection) && !PlatformDetector.isAppleTV()) {
        final hasRule = Provider.of<DownloadProvider>(context, listen: false).hasSyncRule(_itemSyncRuleKey(context));
        if (hasRule) {
          menuActions.add(
            _MenuAction(value: 'manage_sync', icon: Symbols.sync_rounded, label: t.downloads.manageSyncRule),
          );
          menuActions.add(
            _MenuAction(value: 'remove_sync', icon: Symbols.sync_disabled_rounded, label: t.downloads.removeSyncRule),
          );
        } else {
          menuActions.add(
            _MenuAction(
              value: isPlaylist ? 'download_playlist' : 'download_collection',
              icon: Symbols.download_rounded,
              label: t.downloads.downloadNow,
            ),
          );
        }
      }

      // Delete
      menuActions.add(_MenuAction(value: 'delete', icon: Symbols.delete_rounded, label: t.common.delete));

      // Skip other menu items for collections and playlists
    } else {
      // Regular menu items for other types

      // Play from Beginning (for movies and episodes with active progress)
      if (hasActiveProgress) {
        menuActions.add(
          _MenuAction(value: 'play_from_beginning', icon: Symbols.replay_rounded, label: t.mediaMenu.playFromBeginning),
        );
      }

      // Mark as Watched
      if (!mediaItem!.isWatched || isPartiallyWatched || hasActiveProgress) {
        menuActions.add(
          _MenuAction(value: 'watch', icon: Symbols.check_circle_outline_rounded, label: t.mediaMenu.markAsWatched),
        );
      }

      // Mark as Unwatched
      if (mediaItem.isWatched || isPartiallyWatched || hasActiveProgress) {
        menuActions.add(
          _MenuAction(
            value: 'unwatch',
            icon: Symbols.remove_circle_outline_rounded,
            label: t.mediaMenu.markAsUnwatched,
          ),
        );
      }

      // Remove from Continue Watching (only in continue watching section)
      if (widget.isInContinueWatching) {
        menuActions.add(
          _MenuAction(
            value: 'remove_from_continue_watching',
            icon: Symbols.close_rounded,
            label: t.mediaMenu.removeFromContinueWatching,
          ),
        );
      }

      // Rate (for movies, shows, seasons, and episodes)
      if (mediaKind == MediaKind.movie ||
          mediaKind == MediaKind.show ||
          mediaKind == MediaKind.season ||
          mediaKind == MediaKind.episode) {
        menuActions.add(_MenuAction(value: 'rate', icon: Symbols.star_rounded, label: t.mediaMenu.rate));
      }

      // Edit Metadata (for movies, shows, seasons, and episodes) — admin only
      // Plex-only: opens PlexMetadataEditScreen which talks to Plex's
      // `/library/metadata/{id}` PUT API; Jellyfin has no equivalent in v1.
      if (isPlex &&
          isAdmin &&
          (mediaKind == MediaKind.movie ||
              mediaKind == MediaKind.show ||
              mediaKind == MediaKind.season ||
              mediaKind == MediaKind.episode)) {
        menuActions.add(
          _MenuAction(value: 'edit_metadata', icon: Symbols.edit_rounded, label: t.metadataEdit.editMetadata),
        );
      }

      // Match / Unmatch — Plex-only (Jellyfin doesn't expose match agents).
      if (isPlex && isAdmin && (mediaKind == MediaKind.movie || mediaKind == MediaKind.show)) {
        final isUnmatched = _isUnmatched(mediaItem);
        menuActions.add(
          _MenuAction(
            value: 'match',
            icon: Symbols.search_rounded,
            label: isUnmatched ? t.matchScreen.match : t.matchScreen.fixMatch,
          ),
        );
        if (!isUnmatched) {
          menuActions.add(_MenuAction(value: 'unmatch', icon: Symbols.link_off_rounded, label: t.matchScreen.unmatch));
        }
      }

      // Remove from Collection (only when viewing items within a collection).
      // Plex-only — uses `removeFromCollection` API; Jellyfin's collection
      // membership API isn't wired here yet.
      if (isPlex && widget.collectionId != null) {
        menuActions.add(
          _MenuAction(
            value: 'remove_from_collection',
            icon: Symbols.delete_outline_rounded,
            label: t.collections.removeFromCollection,
          ),
        );
      }

      // Go to Series (for episodes and seasons) — hide if already on that series' detail screen
      final ancestorMediaDetail = context.findAncestorWidgetOfExactType<MediaDetailScreen>();
      final ancestorMeta = ancestorMediaDetail?.metadata;
      final ancestorSeriesKey = ancestorMeta != null && ancestorMeta.kind == MediaKind.season
          ? ancestorMeta.parentId
          : ancestorMeta?.id;
      // For episodes, the show key is grandparentId; for seasons, it's parentId
      final itemSeriesKey = mediaKind == MediaKind.episode ? mediaItem.grandparentId : mediaItem.parentId;
      if ((mediaKind == MediaKind.episode || mediaKind == MediaKind.season) &&
          itemSeriesKey != null &&
          ancestorSeriesKey != itemSeriesKey) {
        menuActions.add(_MenuAction(value: 'series', icon: Symbols.tv_rounded, label: t.mediaMenu.goToSeries));
      }

      // Go to Season (for episodes) — hide if already viewing that season's MediaDetailScreen
      if (mediaKind == MediaKind.episode &&
          mediaItem.parentTitle != null &&
          !(ancestorMeta != null && ancestorMeta.kind == MediaKind.season && ancestorMeta.id == mediaItem.parentId)) {
        menuActions.add(
          _MenuAction(value: 'season', icon: Symbols.playlist_play_rounded, label: t.mediaMenu.goToSeason),
        );
      }

      // Shuffle Play (for shows and seasons)
      if (mediaKind == MediaKind.show || mediaKind == MediaKind.season) {
        menuActions.add(
          _MenuAction(value: 'shuffle_play', icon: Symbols.shuffle_rounded, label: t.mediaMenu.shufflePlay),
        );
      }

      // Play Version (for episodes and movies). Hidden when there's
      // nothing to choose: a single source on a backend that can't
      // transcode (Jellyfin v1, or Plex installs without a working
      // transcoder) would just bounce straight to playback with default
      // settings, which is what the regular Play action already does.
      // Both backends inline their version list in browse responses
      // (`Media[]` for Plex, `MediaSources` for Jellyfin), so the count
      // is known up front.
      final versionCount = (mediaItem.mediaVersions ?? const []).length;
      final hasVersionChoice = versionCount > 1;
      if ((mediaKind == MediaKind.episode || mediaKind == MediaKind.movie) && (hasVersionChoice || canTranscode)) {
        menuActions.add(
          _MenuAction(value: 'play_version', icon: Symbols.video_file_rounded, label: t.mediaMenu.playVersion),
        );
      }

      // File Info (for episodes and movies). Backend-neutral — both
      // PlexClient and JellyfinClient implement [getFileInfo], reading
      // codec/stream metadata from `Media`/`MediaSources` respectively.
      // Hidden when the item has no backend marker so we don't fan out
      // to an arbitrary client.
      if (itemBackend != null && (mediaKind == MediaKind.episode || mediaKind == MediaKind.movie)) {
        menuActions.add(_MenuAction(value: 'fileinfo', icon: Symbols.info_rounded, label: t.mediaMenu.fileInfo));
      }

      // Play in External Player (for episodes and movies)
      if (mediaKind == MediaKind.episode || mediaKind == MediaKind.movie) {
        menuActions.add(
          _MenuAction(
            value: 'play_external',
            icon: Symbols.open_in_new_rounded,
            label: t.externalPlayer.playInExternalPlayer,
          ),
        );
      }

      // Download options (for episodes, movies, shows, and seasons).
      // Apple TV has no user-accessible file storage — skip entirely.
      if (!PlatformDetector.isAppleTV() &&
          (mediaKind == MediaKind.episode ||
              mediaKind == MediaKind.movie ||
              mediaKind == MediaKind.show ||
              mediaKind == MediaKind.season)) {
        final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
        final globalKey = mediaItem.globalKey;
        final hasSyncRule = downloadProvider.hasSyncRule(_itemSyncRuleKey(context));
        final hasAnyDownload = downloadProvider.getProgress(globalKey) != null;

        if (hasSyncRule) {
          // Synced item: manage sync + delete options
          menuActions.add(
            _MenuAction(value: 'manage_sync', icon: Symbols.sync_rounded, label: t.downloads.manageSyncRule),
          );
          menuActions.add(
            _MenuAction(value: 'remove_sync', icon: Symbols.sync_disabled_rounded, label: t.downloads.removeSyncRule),
          );
          if (hasAnyDownload) {
            menuActions.add(
              _MenuAction(value: 'delete_download', icon: Symbols.delete_rounded, label: t.downloads.deleteDownload),
            );
          }
        } else if (hasAnyDownload) {
          // Show delete option for any download state (completed, partial, queued, downloading, failed)
          menuActions.add(
            _MenuAction(value: 'delete_download', icon: Symbols.delete_rounded, label: t.downloads.deleteDownload),
          );
        } else {
          // Show download option
          menuActions.add(
            _MenuAction(value: 'download', icon: Symbols.download_rounded, label: t.downloads.downloadNow),
          );
        }
      }

      // Add to... (for episodes, movies, shows, and seasons). Plex-only —
      // uses `buildMetadataUri` + `addToPlaylist` / `addToCollection`. The
      // Jellyfin item-add API is different and not wired here yet.
      if (isPlex &&
          (mediaKind == MediaKind.episode ||
              mediaKind == MediaKind.movie ||
              mediaKind == MediaKind.show ||
              mediaKind == MediaKind.season)) {
        menuActions.add(_MenuAction(value: 'add_to', icon: Symbols.add_rounded, label: t.common.addTo));
      }

      // Delete media item (for episodes, movies, shows, and seasons) — admin
      // only. Backend-neutral: routed through `MediaServerClient.deleteMediaItem`,
      // which both Plex and Jellyfin implement (DELETE /library/metadata/{id}
      // and DELETE /Items/{id} respectively).
      if (isAdmin &&
          (mediaKind == MediaKind.episode ||
              mediaKind == MediaKind.movie ||
              mediaKind == MediaKind.show ||
              mediaKind == MediaKind.season)) {
        menuActions.add(
          _MenuAction(
            value: 'delete_media',
            icon: Symbols.delete_forever_rounded,
            label: t.mediaMenu.deleteFromServer,
            hoverColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } // End of regular menu items else block

    String? selected;

    final openedFromKeyboard = _openedFromKeyboard;
    _openedFromKeyboard = false;

    if (useBottomSheet) {
      selected = await OverlaySheetController.showAdaptive<String>(
        context,
        showDragHandle: true,
        builder: (context) => _FocusableContextMenuSheet(
          title: _itemDisplayTitle(),
          actions: menuActions,
          focusFirstItem: openedFromKeyboard,
        ),
      );
    } else {
      // Show custom focusable popup menu on larger screens
      // Use stored tap position or fallback to widget position
      final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;

      Offset position;
      if (_tapPosition != null) {
        position = _tapPosition!;
      } else {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        position = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
      }

      selected = await showDialog<String>(
        context: context,
        barrierColor: Colors.transparent,
        builder: (dialogContext) =>
            _FocusablePopupMenu(actions: menuActions, position: position, focusFirstItem: openedFromKeyboard),
      );
    }

    try {
      if (!context.mounted) return;

      switch (selected) {
        case 'play_from_beginning':
          didNavigate = true;
          if (context.mounted) {
            await navigateToVideoPlayer(context, metadata: mediaItem!.copyWith(viewOffsetMs: 0));
          }
          break;

        case 'watch':
          final isOffline = context.read<OfflineModeProvider>().isOffline;
          if (isOffline && mediaItem?.serverId != null) {
            // Offline mode: queue action for later sync (emits WatchStateEvent)
            final offlineWatch = context.read<OfflineWatchProvider>();
            await offlineWatch.markAsWatched(serverId: mediaItem!.serverId!, itemId: mediaItem.id);
            if (context.mounted) {
              showAppSnackBar(context, t.messages.markedAsWatchedOffline);
              widget.onRefresh?.call(mediaItem.id);
            }
          } else {
            // Resolve the right backend client — Plex hits scrobble, Jellyfin
            // hits /UserPlayedItems. WatchStateNotifier event is fired in both
            // paths so cross-screen UI updates regardless of backend.
            await _executeAction(context, () async {
              final client = context.tryGetMediaClientForServer(_itemServerId!);
              if (client != null) await client.markWatched(mediaItem!);
            }, t.messages.markedAsWatched);
          }
          break;

        case 'unwatch':
          final isOffline = context.read<OfflineModeProvider>().isOffline;
          if (isOffline && mediaItem?.serverId != null) {
            // Offline mode: queue action for later sync (emits WatchStateEvent)
            final offlineWatch = context.read<OfflineWatchProvider>();
            await offlineWatch.markAsUnwatched(serverId: mediaItem!.serverId!, itemId: mediaItem.id);
            if (context.mounted) {
              showAppSnackBar(context, t.messages.markedAsUnwatchedOffline);
              widget.onRefresh?.call(mediaItem.id);
            }
          } else {
            await _executeAction(context, () async {
              final client = context.tryGetMediaClientForServer(_itemServerId!);
              if (client != null) await client.markUnwatched(mediaItem!);
            }, t.messages.markedAsUnwatched);
          }
          break;

        case 'remove_from_continue_watching':
          // Remove from Continue Watching without affecting watch status or progress
          // This preserves the progression for partially watched items
          // and doesn't mark unwatched next episodes as watched
          try {
            final client = _getMediaClientForItem();
            await client.removeFromContinueWatching(mediaItem!);
            if (context.mounted) {
              showSuccessSnackBar(context, t.messages.removedFromContinueWatching);
              // Use specific callback if provided, otherwise fallback to onRefresh
              if (widget.onRemoveFromContinueWatching != null) {
                widget.onRemoveFromContinueWatching!();
              } else {
                widget.onRefresh?.call(mediaItem.id);
              }
            }
          } catch (e) {
            if (context.mounted) {
              showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
            }
          }
          break;

        case 'rate':
          if (context.mounted) {
            try {
              final client = _getMediaClientForItem();
              await _showRatingSheet(context, mediaItem!, client);
            } catch (e) {
              if (context.mounted) {
                showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
              }
            }
          }
          break;

        case 'edit_metadata':
          didNavigate = true;
          if (context.mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PlexMetadataEditScreen(metadata: mediaItem!)),
            );
            widget.onRefresh?.call(mediaItem!.id);
          }
          break;

        case 'match':
          didNavigate = true;
          if (context.mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PlexMatchScreen(metadata: mediaItem!)),
            );
            widget.onRefresh?.call(mediaItem!.id);
          }
          break;

        case 'unmatch':
          await _handleUnmatch(context, mediaItem!);
          break;

        case 'remove_from_collection':
          await _handleRemoveFromCollection(context, mediaItem!);
          break;

        case 'series':
          didNavigate = true;
          await _navigateToRelated(
            context,
            mediaItem!.kind == MediaKind.season ? mediaItem.parentId : mediaItem.grandparentId,
            (item) => MediaDetailScreen(metadata: item),
            t.messages.errorLoadingSeries,
          );
          break;

        case 'season':
          didNavigate = true;
          // Navigate to the show with the season tab pre-selected
          final seasonParentKey = mediaItem!.kind == MediaKind.episode ? mediaItem.grandparentId : mediaItem.parentId;
          final seasonIndex = mediaItem.parentIndex;
          await _navigateToRelated(
            context,
            seasonParentKey,
            (show) => MediaDetailScreen(metadata: show, initialSeasonIndex: seasonIndex),
            t.messages.errorLoadingSeason,
          );
          break;

        case 'play_version':
          didNavigate = await _handlePlayVersion(context);
          break;

        case 'fileinfo':
          await _showFileInfo(context);
          break;

        case 'add_to':
          await _showAddToSubmenu(context);
          break;

        case 'shuffle_play':
          await _handleShufflePlayWithQueue(context);
          break;

        case 'play':
          await _handlePlay(context, isCollection, isPlaylist);
          break;

        case 'shuffle':
          await _handleShuffle(context, isCollection, isPlaylist);
          break;

        case 'delete':
          await _handleDelete(context, isCollection, isPlaylist);
          break;

        case 'play_external':
          await _handlePlayExternal(context);
          break;

        case 'download_playlist':
          await _handleDownloadPlaylist(context);
          break;

        case 'download_collection':
          await _handleDownloadCollection(context);
          break;

        case 'download':
          await _handleDownload(context);
          break;

        case 'delete_download':
          await _handleDeleteDownload(context);
          break;

        case 'manage_sync':
          await _handleManageSyncRule(context);
          break;

        case 'remove_sync':
          await _handleRemoveSyncRule(context);
          break;

        case 'delete_media':
          await _handleDeleteMediaItem(context, mediaKind);
          break;
      }
    } finally {
      _isContextMenuOpen = false;

      // Restore focus to the previously focused item after the menu closes,
      // but only if no navigation occurred and the focus node is still valid
      if (!didNavigate && previousFocus != null && previousFocus.canRequestFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (previousFocus.canRequestFocus) {
            previousFocus.requestFocus();
          }
        });
      }
    }
  }

  /// Execute an action with error handling and refresh
  Future<void> _executeAction(BuildContext context, Future<void> Function() action, String successMessage) async {
    try {
      await action();
      if (context.mounted) {
        showSuccessSnackBar(context, successMessage);
        widget.onRefresh?.call(_itemId());
      }
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      }
    }
  }

  /// Plex-only: an item is unmatched when its [MediaItem.guid] is missing or
  /// references the Plex no-agent marker.
  bool _isUnmatched(MediaItem item) {
    final g = item.guid;
    return g == null || g.isEmpty || g.contains('agents.none://');
  }

  Future<void> _handleUnmatch(BuildContext context, MediaItem item) async {
    final confirmed = await showConfirmDialog(
      context,
      title: t.matchScreen.unmatch,
      message: t.matchScreen.unmatchConfirm,
      confirmText: t.matchScreen.unmatch,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final client = _getClientForItem();
    try {
      final success = await client.unmatchItem(item.id);
      if (!context.mounted) return;
      if (success) {
        showSuccessSnackBar(context, t.matchScreen.unmatchSuccess);
        widget.onRefresh?.call(item.id);
      } else {
        showErrorSnackBar(context, t.matchScreen.unmatchFailed);
      }
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      }
    }
  }

  /// Navigate to a related item (series or season)
  Future<void> _navigateToRelated(
    BuildContext context,
    String? id,
    Widget Function(MediaItem) screenBuilder,
    String errorPrefix,
  ) async {
    if (id == null) return;

    final client = _getMediaClientForItem();

    try {
      final metadata = await client.fetchItem(id);
      if (metadata != null && context.mounted) {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => screenBuilder(metadata)));
        widget.onRefresh?.call(_itemId());
      }
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, '$errorPrefix: $e');
      }
    }
  }

  /// Show file info bottom sheet
  Future<void> _showFileInfo(BuildContext context) async {
    final client = _getMediaClientForItem();

    try {
      if (context.mounted) {
        showLoadingDialog(context);
      }

      // Fetch file info
      final item = _mediaItem!;
      final fileInfo = await client.getFileInfo(item);

      // Close loading indicator
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (fileInfo != null && context.mounted) {
        // Show file info bottom sheet
        await OverlaySheetController.showAdaptive(
          context,
          isScrollControlled: true,
          builder: (context) => FileInfoBottomSheet(fileInfo: fileInfo, title: item.displayTitle),
        );
      } else if (context.mounted) {
        showErrorSnackBar(context, t.messages.fileInfoNotAvailable);
      }
    } catch (e) {
      // Close loading indicator if it's still open
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        showErrorSnackBar(context, t.messages.errorLoadingFileInfo(error: e.toString()));
      }
    }
  }

  Future<bool> _handlePlayVersion(BuildContext context) async {
    final item = _mediaItem!;
    // Same flag the in-player Version & Quality sheet reads — keeps both
    // surfaces honest about what the active backend can actually do.
    final canTranscode = _itemServerId == null
        ? false
        : (context.read<MultiServerProvider>().getClientForServer(_itemServerId!)?.capabilities.videoTranscoding ??
              false);
    final versions = item.mediaVersions ?? const [];

    int selectedVersionIndex = 0;
    if (versions.length > 1) {
      final picked = await showVersionPickerDialog(context, versions, t.mediaMenu.playVersion);
      if (picked == null || !context.mounted) return false;
      selectedVersionIndex = picked;
    }

    TranscodeQualityPreset selectedQuality = TranscodeQualityPreset.original;
    if (canTranscode) {
      final selectedVersion = selectedVersionIndex < versions.length ? versions[selectedVersionIndex] : null;
      final picked = await showQualityPickerDialog(
        context,
        sourceBitrateKbps: selectedVersion?.bitrate,
        sourceDurationMs: item.durationMs,
        sourceSizeBytes: _versionSizeBytes(selectedVersion),
      );
      if (picked == null || !context.mounted) return false;
      selectedQuality = picked;
    }

    await navigateToVideoPlayer(
      context,
      metadata: item,
      selectedMediaIndex: selectedVersionIndex,
      selectedQualityPreset: selectedQuality,
    );
    return true;
  }

  /// Sum of [MediaPart.sizeBytes] across all parts of [version]. Returns
  /// null when any part is missing a size (a partial sum would be misleading
  /// for the "Original" row in the quality picker).
  int? _versionSizeBytes(MediaVersion? version) {
    if (version == null || version.parts.isEmpty) return null;
    var total = 0;
    for (final p in version.parts) {
      final s = p.sizeBytes;
      if (s == null || s <= 0) return null;
      total += s;
    }
    return total > 0 ? total : null;
  }

  /// Handle shuffle play using play queues — dispatches via the
  /// neutral [MediaListPlaybackLauncher] so Jellyfin items get routed to
  /// [JellyfinSequentialLauncher] instead of falling through to the
  /// Plex-only `/playQueues` flow.
  Future<void> _handleShufflePlayWithQueue(BuildContext context) async {
    final mediaItem = _mediaItem;
    if (mediaItem == null) return;
    final launcher = MediaListPlaybackLauncher.forItem(context, mediaItem);
    await launcher.launchShuffledShow(metadata: mediaItem, showLoadingIndicator: true);
  }

  /// Show submenu for Add to... (Playlist or Collection)
  Future<void> _showAddToSubmenu(BuildContext context) async {
    final selected = await showOptionPickerDialog<String>(
      context,
      title: t.common.addTo,
      options: [
        (icon: Symbols.playlist_play_rounded, label: t.playlists.playlist, value: 'playlist'),
        (icon: Symbols.collections_rounded, label: t.collections.collection, value: 'collection'),
      ],
    );

    // Handle the submenu selection
    if (selected == 'playlist' && context.mounted) {
      await _showAddToPlaylistDialog(context);
    } else if (selected == 'collection' && context.mounted) {
      await _showAddToCollectionDialog(context);
    }
  }

  /// Show dialog to select playlist and add item
  Future<void> _showAddToPlaylistDialog(BuildContext context) async {
    final client = _getMediaClientForItem();

    try {
      final item = _mediaItem!;

      final playlists = await client.fetchPlaylists(playlistType: 'video');

      if (!context.mounted) return;

      // Show dialog to select playlist or create new
      final result = await showDialog<String>(
        context: context,
        builder: (context) => _PlaylistSelectionDialog(playlists: playlists),
      );

      if (result == null || !context.mounted) return;

      if (result == '_create_new') {
        // Create new playlist flow
        final playlistName = await showTextInputDialog(
          context,
          title: t.playlists.create,
          labelText: t.playlists.playlistName,
          hintText: t.playlists.enterPlaylistName,
        );

        if (playlistName == null || playlistName.isEmpty || !context.mounted) {
          return;
        }

        // Create playlist with the item(s)
        appLogger.d('Creating playlist "$playlistName" seeded with item ${item.id}');
        final newPlaylist = await client.createPlaylist(title: playlistName, items: [item]);

        if (!context.mounted) return;

        if (context.mounted) {
          if (newPlaylist != null) {
            appLogger.d('Successfully created playlist: ${newPlaylist.title}');
            showSuccessSnackBar(context, t.playlists.created);
            // Trigger refresh of playlists tab
            LibraryRefreshNotifier().notifyPlaylistsChanged();
          } else {
            appLogger.e('Failed to create playlist - API returned null');
            showErrorSnackBar(context, t.playlists.errorCreating);
          }
        }
      } else {
        // Add to existing playlist
        appLogger.d('Adding item ${item.id} to playlist $result');
        final success = await client.addToPlaylist(playlistId: result, items: [item]);

        if (!context.mounted) return;

        if (context.mounted) {
          if (success) {
            appLogger.d('Successfully added item(s) to playlist $result');
            showSuccessSnackBar(context, t.playlists.itemAdded);
            // Trigger refresh of playlists tab
            LibraryRefreshNotifier().notifyPlaylistsChanged();
            _triggerEagerSyncIfRuleExists(context, client.serverId, result);
          } else {
            appLogger.e('Failed to add item(s) to playlist $result - API returned false');
            showErrorSnackBar(context, t.playlists.errorAdding);
          }
        }
      }
    } catch (e, stackTrace) {
      appLogger.e('Error in add to playlist flow', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        showErrorSnackBar(context, '${t.playlists.errorLoading}: ${e.toString()}');
      }
    }
  }

  /// Show dialog to select collection and add item
  Future<void> _showAddToCollectionDialog(BuildContext context) async {
    final client = _getMediaClientForItem();

    try {
      final item = _mediaItem!;
      final itemKind = item.kind;

      // Resolve the library/section id from the item itself, falling back to
      // a metadata round-trip and the show's library if missing. Both
      // backends store this on [MediaItem.libraryId].
      String? libraryId = item.libraryId;
      appLogger.d('Resolving libraryId for ${item.title} (initial: $libraryId)');

      if (libraryId == null || libraryId.isEmpty) {
        try {
          final fullMetadata = await client.fetchItem(item.id);
          libraryId = fullMetadata?.libraryId;
          appLogger.d('  - libraryId from full metadata: $libraryId');
        } catch (e) {
          appLogger.w('Failed to get full metadata for libraryId: $e');
        }
      }

      if ((libraryId == null || libraryId.isEmpty) && item.grandparentId != null) {
        try {
          final parentMeta = await client.fetchItem(item.grandparentId!);
          libraryId = parentMeta?.libraryId;
          appLogger.d('  - libraryId from grandparent: $libraryId');
        } catch (e) {
          appLogger.w('Failed to get parent metadata for libraryId: $e');
        }
      }

      if (libraryId == null || libraryId.isEmpty) {
        if (context.mounted) {
          showErrorSnackBar(context, t.messages.unableToDetermineLibrarySection);
        }
        return;
      }

      // Load collections for this library section
      final collections = await client.fetchCollections(libraryId);

      if (!context.mounted) return;

      // Show dialog to select collection or create new
      final result = await showDialog<String>(
        context: context,
        builder: (context) => _CollectionSelectionDialog(collections: collections),
      );

      if (result == null || !context.mounted) return;

      if (result == '_create_new') {
        // Create new collection flow
        final collectionName = await showTextInputDialog(
          context,
          title: t.common.createNew,
          labelText: t.collections.collectionName,
          hintText: t.collections.enterCollectionName,
        );

        if (collectionName == null || collectionName.isEmpty || !context.mounted) {
          return;
        }

        appLogger.d('Creating collection "$collectionName" seeded with item ${item.id}');
        final newCollectionId = await client.createCollection(
          libraryId: libraryId,
          title: collectionName,
          items: [item],
          itemKind: itemKind,
        );

        if (!context.mounted) return;

        if (context.mounted) {
          if (newCollectionId != null) {
            appLogger.d('Successfully created collection with ID: $newCollectionId');
            showSuccessSnackBar(context, t.collections.created);
            // Trigger refresh of collections tab
            LibraryRefreshNotifier().notifyCollectionsChanged();
            _triggerEagerSyncIfRuleExists(context, client.serverId, newCollectionId);
          } else {
            appLogger.e('Failed to create collection - API returned null');
            showErrorSnackBar(context, t.collections.errorAddingToCollection);
          }
        }
      } else {
        // Add to existing collection
        appLogger.d('Adding item ${item.id} to collection $result');
        final success = await client.addToCollection(collectionId: result, items: [item]);

        if (!context.mounted) return;

        if (context.mounted) {
          if (success) {
            appLogger.d('Successfully added item(s) to collection $result');
            showSuccessSnackBar(context, t.collections.addedToCollection);
            // Trigger refresh of collections tab
            LibraryRefreshNotifier().notifyCollectionsChanged();
            _triggerEagerSyncIfRuleExists(context, client.serverId, result);
          } else {
            appLogger.e('Failed to add item(s) to collection $result - API returned false');
            showErrorSnackBar(context, t.collections.errorAddingToCollection);
          }
        }
      }
    } catch (e, stackTrace) {
      appLogger.e('Error in add to collection flow', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        showErrorSnackBar(context, '${t.collections.errorAddingToCollection}: ${e.toString()}');
      }
    }
  }

  Future<void> _showRatingSheet(BuildContext context, MediaItem item, MediaServerClient client) async {
    final currentStarValue = (item.userRating != null && item.userRating! > 0) ? item.userRating! / 2.0 : 0.0;
    await OverlaySheetController.showAdaptive(
      context,
      showDragHandle: true,
      builder: (context) => RatingBottomSheet(
        currentRating: currentStarValue,
        onRate: (stars) async {
          // 0-10 scale used by both Plex and Jellyfin rate endpoints.
          final rating = stars * 2.0;
          try {
            await client.rate(item, rating);
            widget.onRefresh?.call(item.id);
          } on MediaServerHttpException catch (e) {
            appLogger.w('Failed to set rating', error: e);
            if (context.mounted) showErrorSnackBar(context, t.errors.failedToRate);
          }
        },
        onClear: () async {
          try {
            await client.rate(item, -1);
            widget.onRefresh?.call(item.id);
          } on MediaServerHttpException catch (e) {
            appLogger.w('Failed to clear rating', error: e);
            if (context.mounted) showErrorSnackBar(context, t.errors.failedToRate);
          }
        },
      ),
    );
  }

  Future<void> _handleRemoveFromCollection(BuildContext context, MediaItem item) async {
    final client = _getMediaClientForItem();

    if (widget.collectionId == null) {
      appLogger.e('Cannot remove from collection: collectionId is null');
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDeleteConfirmation(
      context,
      title: t.collections.removeFromCollection,
      message: t.collections.removeFromCollectionConfirm(title: item.displayTitle),
    );

    if (!confirmed || !context.mounted) return;

    try {
      appLogger.d('Removing item ${item.id} from collection ${widget.collectionId}');
      final success = await client.removeFromCollection(collectionId: widget.collectionId!, item: item);

      if (context.mounted) {
        if (success) {
          showSuccessSnackBar(context, t.collections.removedFromCollection);
          // Trigger refresh of collections tab
          LibraryRefreshNotifier().notifyCollectionsChanged();
          // Trigger list refresh to remove the item from the view
          widget.onListRefresh?.call();
        } else {
          showErrorSnackBar(context, t.collections.removeFromCollectionFailed);
        }
      }
    } catch (e) {
      appLogger.e('Failed to remove from collection', error: e);
      if (context.mounted) {
        showErrorSnackBar(context, t.collections.removeFromCollectionError(error: e.toString()));
      }
    }
  }

  /// Handle play action for collections and playlists
  Future<void> _handlePlay(BuildContext context, bool _, bool _) async {
    await _launchCollectionOrPlaylist(context, shuffle: false);
  }

  /// Handle shuffle action for collections and playlists
  Future<void> _handleShuffle(BuildContext context, bool _, bool _) async {
    await _launchCollectionOrPlaylist(context, shuffle: true);
  }

  /// Launch playback for collection or playlist.
  ///
  /// Dispatches to the right launcher implementation based on the item's
  /// backend — Plex uses server-side `/playQueues`, Jellyfin builds an
  /// in-memory queue locally.
  Future<void> _launchCollectionOrPlaylist(BuildContext context, {required bool shuffle}) async {
    // Launcher accepts both MediaItem (for collections) and MediaPlaylist.
    final launcher = MediaListPlaybackLauncher.forItem(context, widget.item);
    await launcher.launchFromCollectionOrPlaylist(item: widget.item, shuffle: shuffle, showLoadingIndicator: false);
  }

  /// Handle delete action for collections and playlists
  Future<void> _handleDelete(BuildContext context, bool isCollection, bool isPlaylist) async {
    final client = _getMediaClientForItem();

    final itemTitle = _itemDisplayTitle();
    final itemTypeLabel = isCollection ? t.collections.collection : t.playlists.playlist;

    // Show confirmation dialog
    final confirmed = await showDeleteConfirmation(
      context,
      title: isCollection ? t.collections.deleteCollection : t.playlists.delete,
      message: isCollection
          ? t.collections.deleteConfirm(title: itemTitle)
          : t.playlists.deleteMessage(name: itemTitle),
    );

    if (!confirmed || !context.mounted) return;

    try {
      bool success = false;

      if (isCollection) {
        success = await client.deleteCollection(_mediaItem!);
      } else if (isPlaylist) {
        success = await client.deletePlaylist(_playlist!);
      }

      if (context.mounted) {
        if (success) {
          showSuccessSnackBar(context, isCollection ? t.collections.deleted : t.playlists.deleted);
          // Trigger list refresh
          widget.onListRefresh?.call();
        } else {
          showErrorSnackBar(context, isCollection ? t.collections.deleteFailed : t.playlists.errorDeleting);
        }
      }
    } catch (e) {
      appLogger.e('Failed to delete $itemTypeLabel', error: e);
      if (context.mounted) {
        showErrorSnackBar(
          context,
          isCollection ? t.collections.deleteFailedWithError(error: e.toString()) : t.playlists.errorDeleting,
        );
      }
    }
  }

  /// Handle play in external player action
  Future<void> _handlePlayExternal(BuildContext context) async {
    final item = _mediaItem!;

    // Check if the item is downloaded and use local file path if available
    final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
    final globalKey = item.globalKey;
    if (downloadProvider.isDownloaded(globalKey)) {
      final videoPath = await downloadProvider.getVideoFilePath(globalKey);
      if (videoPath != null && context.mounted) {
        final videoUrl = videoPath.contains('://') ? videoPath : 'file://$videoPath';
        await ExternalPlayerService.launch(context: context, videoUrl: videoUrl);
        return;
      }
    }

    final client = _getMediaClientForItem();
    if (!context.mounted) return;
    await ExternalPlayerService.launch(context: context, metadata: item, client: client);
  }

  /// Handle download collection action — opens the same sync/one-time dialog
  /// as playlists, wired to [showCollectionDownloadOptionsAndQueue].
  Future<void> _handleDownloadCollection(BuildContext context) async {
    final collection = _mediaItem!;
    final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
    final client = _getMediaClientForItem();

    try {
      // [fetchChildren] is the neutral equivalent of the previous Plex-only
      // `fetchAllCollectionItemsAsMediaItems` — both backends return the
      // collection's contents.
      final items = await client.fetchChildren(collection.id);
      if (!context.mounted) return;

      final result = await showCollectionDownloadOptionsAndQueue(
        context,
        collectionMetadata: collection,
        items: items,
        client: client,
        downloadProvider: downloadProvider,
      );
      if (result == null || !context.mounted) return;

      showSuccessSnackBar(context, result.toSnackBarMessage());
    } on CellularDownloadBlockedException {
      if (context.mounted) {
        showErrorSnackBar(context, t.settings.cellularDownloadBlocked);
      }
    } catch (e) {
      appLogger.e('Failed to queue collection download', error: e);
      if (context.mounted) {
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      }
    }
  }

  /// Handle download playlist action
  Future<void> _handleDownloadPlaylist(BuildContext context) async {
    final playlist = _playlist!;
    final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
    final client = _getMediaClientForItem();

    try {
      // Page through the playlist via the neutral interface so Jellyfin
      // playlists download too.
      final items = await fetchAllPlaylistItems(client, playlist.id);
      if (!context.mounted) return;

      final playlistMetadata = MediaItem(
        id: playlist.id,
        backend: playlist.backend,
        kind: MediaKind.playlist,
        title: playlist.title,
        thumbPath: playlist.thumbPath,
        serverId: playlist.serverId ?? client.serverId,
        serverName: playlist.serverName,
      );

      final result = await showPlaylistDownloadOptionsAndQueue(
        context,
        playlistMetadata: playlistMetadata,
        items: items,
        client: client,
        downloadProvider: downloadProvider,
      );
      if (result == null || !context.mounted) return;

      showSuccessSnackBar(context, result.toSnackBarMessage());
    } on CellularDownloadBlockedException {
      if (context.mounted) {
        showErrorSnackBar(context, t.settings.cellularDownloadBlocked);
      }
    } catch (e) {
      appLogger.e('Failed to queue playlist download', error: e);
      if (context.mounted) {
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      }
    }
  }

  /// Handle download action
  Future<void> _handleDownload(BuildContext context) async {
    final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
    final item = _mediaItem!;
    // Backend-agnostic resolve so Jellyfin items can be downloaded too.
    final client = context.getMediaClientWithFallback(_itemServerId);

    try {
      final result = await showDownloadOptionsAndQueue(
        context,
        metadata: item,
        client: client,
        downloadProvider: downloadProvider,
      );
      if (result == null || !context.mounted) return;

      showSuccessSnackBar(context, result.toSnackBarMessage());
    } on CellularDownloadBlockedException {
      if (context.mounted) {
        showErrorSnackBar(context, t.settings.cellularDownloadBlocked);
      }
    } catch (e) {
      appLogger.e('Failed to queue download', error: e);
      if (context.mounted) {
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      }
    }
  }

  /// Handle delete download action
  Future<void> _handleDeleteDownload(BuildContext context) async {
    final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
    final item = _mediaItem!;
    final globalKey = item.globalKey;

    // Show confirmation dialog
    final confirmed = await showDeleteConfirmation(
      context,
      title: t.downloads.deleteDownload,
      message: t.downloads.deleteConfirm(title: item.displayTitle),
    );

    if (!confirmed || !context.mounted) return;

    try {
      // Use smart deletion handler (shows progress only if >500ms)
      await SmartDeletionHandler.deleteWithProgress(context: context, provider: downloadProvider, globalKey: globalKey);

      if (context.mounted) {
        showSuccessSnackBar(context, t.downloads.downloadDeleted);
        // DownloadProvider.deleteDownload now broadcasts the DeletionEvent,
        // so DeletionAware screens (e.g. offline season detail) update without
        // a duplicate notification here.
        widget.onRefresh?.call(item.id);
      }
    } catch (e) {
      appLogger.e('Failed to delete download', error: e);
      if (context.mounted) {
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      }
    }
  }

  /// Resolve the sync-rule global key for whatever the menu item is — works
  /// for items (shows/seasons/collections/movies/episodes) and playlists.
  String _itemGlobalKey() {
    final raw = widget.item;
    return switch (raw) {
      MediaItem() => raw.globalKey,
      MediaPlaylist() => raw.globalKey,
      _ => '',
    };
  }

  String _itemSyncRuleKey(BuildContext context) {
    final globalKey = _itemGlobalKey();
    final serverId = _itemServerId;
    if (serverId == null) return globalKey;
    final client = context.tryGetMediaClientForServer(serverId);
    if (client == null) return globalKey;
    return context.read<DownloadProvider>().syncRuleKeyForClient(client, _itemId(), serverId: serverId);
  }

  String _itemDisplayTitle() => switch (widget.item) {
    MediaItem(:final displayTitle) => displayTitle,
    MediaPlaylist(:final displayTitle) => displayTitle,
    _ => '',
  };

  Future<void> _handleManageSyncRule(BuildContext context) =>
      manageSyncRule(context, downloadProvider: context.read<DownloadProvider>(), globalKey: _itemSyncRuleKey(context));

  /// Fire-and-forget: if a sync rule exists for the target list, run it now so
  /// newly-added items download immediately instead of waiting for the next
  /// cooldown-gated general pass. Fails silently — errors are logged only.
  static void _triggerEagerSyncIfRuleExists(BuildContext context, String serverId, String listId) {
    try {
      final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
      final client = Provider.of<MultiServerProvider>(context, listen: false).getClientForServer(serverId);
      final globalKey = client == null
          ? buildGlobalKey(serverId, listId)
          : downloadProvider.syncRuleKeyForClient(client, listId, serverId: serverId);
      if (!downloadProvider.hasSyncRule(globalKey)) return;
      final serverManager = Provider.of<MultiServerProvider>(context, listen: false).serverManager;
      unawaited(
        downloadProvider.executeSyncRuleFor(globalKey, serverManager).catchError((e) {
          appLogger.w('Eager sync-rule run failed for $globalKey: $e');
          return null;
        }),
      );
    } catch (e) {
      appLogger.w('Failed to schedule eager sync-rule run: $e');
    }
  }

  Future<void> _handleRemoveSyncRule(BuildContext context) => removeSyncRuleAndSnack(
    context,
    downloadProvider: context.read<DownloadProvider>(),
    globalKey: _itemSyncRuleKey(context),
    displayTitle: _itemDisplayTitle(),
  );

  /// Handle delete media item action
  /// This permanently removes the media item and its associated files from the server
  Future<void> _handleDeleteMediaItem(BuildContext context, MediaKind? mediaKind) async {
    final item = _mediaItem!;
    final isMultipleMediaItems = mediaKind == MediaKind.show || mediaKind == MediaKind.season;

    // Show confirmation dialog
    final confirmed = await showDeleteConfirmation(
      context,
      title: t.mediaMenu.deleteFromServer,
      message: "${t.mediaMenu.confirmDelete}${isMultipleMediaItems ? "\n\n${t.mediaMenu.deleteMultipleWarning}" : ""}",
      confirmText: t.mediaMenu.deleteFromServer,
    );

    if (!confirmed || !context.mounted) return;

    try {
      final client = _getMediaClientForItem();
      final success = await client.deleteMediaItem(item);

      if (context.mounted) {
        if (success) {
          showSuccessSnackBar(context, t.mediaMenu.mediaDeletedSuccessfully);
          // Broadcast deletion event for cross-screen propagation
          DeletionNotifier().notifyDeletedItem(item: item);
          // Backward-compatible list refresh for screens that are not DeletionAware yet
          widget.onListRefresh?.call();
        } else {
          showErrorSnackBar(context, t.mediaMenu.mediaFailedToDelete);
        }
      }
    } catch (e) {
      appLogger.e(t.mediaMenu.mediaFailedToDelete, error: e);
      if (context.mounted) {
        showErrorSnackBar(context, t.mediaMenu.mediaFailedToDelete);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // GestureDetector wrapping removed — gesture callbacks are now on InkWell
    // directly in the card widgets, saving 1 element level. The context menu
    // is still accessible programmatically via showContextMenu().
    return widget.child;
  }
}

/// Dialog to select a playlist or create a new one
class _PlaylistSelectionDialog extends StatelessWidget {
  final List<MediaPlaylist> playlists;

  const _PlaylistSelectionDialog({required this.playlists});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(t.playlists.selectPlaylist),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: playlists.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              // Create new playlist option (always shown first)
              return ListTile(
                leading: const AppIcon(Symbols.add_rounded, fill: 1),
                title: Text(t.common.createNew),
                onTap: () => Navigator.pop(context, '_create_new'),
              );
            }

            final playlist = playlists[index - 1];
            final subtitleText = playlist.leafCount == 1
                ? t.playlists.oneItem
                : t.playlists.itemCount(count: playlist.leafCount!);
            return ListTile(
              leading: playlist.smart
                  ? const AppIcon(Symbols.auto_awesome_rounded, fill: 1)
                  : const AppIcon(Symbols.playlist_play_rounded, fill: 1),
              title: Text(playlist.title),
              subtitle: playlist.leafCount != null ? Text(subtitleText) : null,
              onTap: playlist.smart
                  ? null // Disable smart playlists
                  : () => Navigator.pop(context, playlist.id),
              enabled: !playlist.smart,
            );
          },
        ),
      ),
      actions: [
        FocusableButton(
          autofocus: true,
          onPressed: () => Navigator.pop(context),
          child: TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.cancel)),
        ),
      ],
    );
  }
}

/// Dialog to select a collection or create a new one
class _CollectionSelectionDialog extends StatefulWidget {
  final List<MediaItem> collections;

  const _CollectionSelectionDialog({required this.collections});

  @override
  State<_CollectionSelectionDialog> createState() => _CollectionSelectionDialogState();
}

class _CollectionSelectionDialogState extends State<_CollectionSelectionDialog> {
  final _filterController = TextEditingController();
  late List<MediaItem> _filteredCollections = widget.collections;

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  void _onFilterChanged(String query) {
    final lower = query.toLowerCase();
    setState(() {
      _filteredCollections = lower.isEmpty
          ? widget.collections
          : widget.collections.where((c) => (c.title ?? '').toLowerCase().contains(lower)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(t.collections.selectCollection),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.collections.length >= 10) ...[
              TextField(
                controller: _filterController,
                autofocus: true,
                decoration: pillInputDecoration(
                  context,
                  hintText: t.collections.searchCollections,
                  prefixIcon: const Icon(Symbols.search_rounded, size: 20),
                ),
                onChanged: _onFilterChanged,
              ),
              const SizedBox(height: 8),
            ],
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredCollections.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      leading: const AppIcon(Symbols.add_rounded, fill: 1),
                      title: Text(t.common.createNew),
                      onTap: () => Navigator.pop(context, '_create_new'),
                    );
                  }

                  final collection = _filteredCollections[index - 1];
                  return ListTile(
                    leading: const AppIcon(Symbols.collections_rounded, fill: 1),
                    title: Text(collection.title ?? ''),
                    subtitle: collection.childCount != null
                        ? Text(t.playlists.itemCount(count: collection.childCount!))
                        : null,
                    onTap: () => Navigator.pop(context, collection.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        FocusableButton(
          onPressed: () => Navigator.pop(context),
          child: TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.cancel)),
        ),
      ],
    );
  }
}

/// Focusable context menu sheet for keyboard/gamepad navigation (mobile)
class _FocusableContextMenuSheet extends StatefulWidget {
  final String title;
  final List<_MenuAction> actions;
  final bool focusFirstItem;

  const _FocusableContextMenuSheet({required this.title, required this.actions, this.focusFirstItem = false});

  @override
  State<_FocusableContextMenuSheet> createState() => _FocusableContextMenuSheetState();
}

class _FocusableContextMenuSheetState extends State<_FocusableContextMenuSheet> {
  late final FocusNode _initialFocusNode;

  @override
  void initState() {
    super.initState();
    _initialFocusNode = FocusNode(debugLabel: 'ContextMenuSheetInitialFocus');
  }

  @override
  void dispose() {
    _initialFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...widget.actions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final action = entry.value;
                  return FocusableListTile(
                    focusNode: index == 0 && widget.focusFirstItem ? _initialFocusNode : null,
                    leading: AppIcon(action.icon, fill: 1),
                    title: Text(action.label),
                    onTap: () => OverlaySheetController.closeAdaptive(context, action.value),
                    hoverColor: action.hoverColor,
                    textColor: action.foregroundColor,
                    iconColor: action.foregroundColor,
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Focusable popup menu for keyboard/gamepad navigation (desktop)
class _FocusablePopupMenu extends StatefulWidget {
  final List<_MenuAction> actions;
  final Offset position;
  final bool focusFirstItem;

  const _FocusablePopupMenu({required this.actions, required this.position, this.focusFirstItem = false});

  @override
  State<_FocusablePopupMenu> createState() => _FocusablePopupMenuState();
}

class _FocusablePopupMenuState extends State<_FocusablePopupMenu> {
  late final FocusNode _initialFocusNode;

  @override
  void initState() {
    super.initState();
    _initialFocusNode = FocusNode(debugLabel: 'PopupMenuInitialFocus');
    if (widget.focusFirstItem) {
      FocusUtils.requestFocusAfterBuild(this, _initialFocusNode);
    }
  }

  @override
  void dispose() {
    _initialFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    const menuWidth = 220.0;

    // Clamp menu position to stay within screen bounds
    const edgePadding = 8.0;
    final left = widget.position.dx.clamp(edgePadding, screenSize.width - menuWidth - edgePadding);

    final estimatedHeight = widget.actions.length * 48.0 + 16;
    final spaceBelow = screenSize.height - widget.position.dy - edgePadding;
    final spaceAbove = widget.position.dy - edgePadding;

    // Place menu above the click point if it doesn't fit below and there's more room above
    final double top;
    final double maxHeight;
    if (estimatedHeight <= spaceBelow) {
      top = widget.position.dy;
      maxHeight = spaceBelow;
    } else if (spaceAbove > spaceBelow) {
      final menuHeight = estimatedHeight.clamp(0.0, spaceAbove);
      top = widget.position.dy - menuHeight;
      maxHeight = menuHeight;
    } else {
      top = widget.position.dy;
      maxHeight = spaceBelow;
    }

    return FocusScope(
      // When opened via mouse, don't autofocus any item — let hover handle highlights.
      // When opened via keyboard/dpad, autofocus is handled by _initialFocusNode.
      autofocus: false,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (node, event) {
          if (SelectKeyUpSuppressor.consumeIfSuppressed(event)) {
            return KeyEventResult.handled;
          }
          if (BackKeyUpSuppressor.consumeIfSuppressed(event)) {
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            // Barrier to close menu when clicking outside
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                behavior: HitTestBehavior.opaque,
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
            // Menu
            Positioned(
              left: left,
              top: top,
              child: Material(
                elevation: 8,
                color: Color.alphaBlend(
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                  Theme.of(context).colorScheme.surface,
                ),
                borderRadius: BorderRadius.circular(tokens(context).radiusSm),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: menuWidth, maxWidth: menuWidth, maxHeight: maxHeight),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: widget.actions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final action = entry.value;
                        return FocusableListTile(
                          focusNode: index == 0 && widget.focusFirstItem ? _initialFocusNode : null,
                          leading: AppIcon(action.icon, fill: 1, size: 20),
                          title: Text(action.label),
                          onTap: () => Navigator.pop(context, action.value),
                          hoverColor: action.hoverColor,
                          textColor: action.foregroundColor,
                          iconColor: action.foregroundColor,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
