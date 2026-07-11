import 'dart:io';
import 'dart:async';
import '../media/ids.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../providers/watch_state_store.dart';
import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../media/media_item_labels.dart';
import '../media/media_item_types.dart';
import '../media/media_kind.dart';
import '../media/media_playlist.dart';
import '../media/media_server_client.dart';
import '../metadata_edit/metadata_edit_adapters.dart';
import '../media/media_version.dart';
import '../models/companion_remote/remote_command.dart';
import '../providers/companion_remote_provider.dart';
import '../screens/companion_remote/mobile_remote_screen.dart';
import '../services/plex_client.dart';
import '../services/media_list_playback_launcher.dart';
import '../services/music/music_playback_service.dart';
import '../services/offline_watch_sync_service.dart';
import '../services/playlist_items_loader.dart';
import '../services/watch_actions.dart';
import '../services/catalog/library_watchlist_candidates.dart';
import '../utils/content_utils.dart';
import '../utils/delete_impact.dart';
import '../utils/download_utils.dart';
import '../utils/global_key_utils.dart';
import '../providers/download_provider.dart';
import '../providers/multi_server_provider.dart';
import '../providers/offline_mode_provider.dart';
import '../providers/catalog_sources_provider.dart';
import '../profiles/active_profile_provider.dart';
import '../profiles/profile.dart';
import '../utils/provider_extensions.dart';
import '../utils/app_logger.dart';
import '../utils/library_refresh_notifier.dart';
import '../utils/media_navigation_helper.dart';
import '../utils/music_navigation.dart';
import '../utils/platform_detector.dart';
import '../utils/snackbar_helper.dart';
import '../utils/dialogs.dart';
import '../services/external_player_service.dart';
import 'collection_picker_dialog.dart';
import '../screens/plex_match_screen.dart';
import '../screens/media_detail_screen.dart';
import '../screens/metadata_edit_screen.dart';
import '../screens/music/album_detail_screen.dart';
import '../screens/music/artist_detail_screen.dart';
import '../utils/smart_deletion_handler.dart';
import '../utils/video_player_navigation.dart';
import '../utils/deletion_notifier.dart';
import '../widgets/app_menu.dart';
import '../widgets/file_info_bottom_sheet.dart';
import '../widgets/overlay_sheet.dart';
import 'watchlist_source_chooser.dart';
import '../widgets/rating_bottom_sheet.dart';
import '../i18n/strings.g.dart';

class _MenuAction {
  final String value;
  final IconData icon;
  final String label;
  final bool destructive;

  _MenuAction({required this.value, required this.icon, required this.label, this.destructive = false});
}

/// The sync-rule / download entry set shared by the list (playlist/collection)
/// and single-item menu branches: an existing rule offers manage/remove (plus
/// download deletion when files exist), an existing download alone offers
/// deletion, and otherwise the plain download entry — [downloadValue] names
/// the action the calling branch dispatches on.
List<_MenuAction> _syncDownloadMenuActions({
  required bool hasSyncRule,
  required bool hasAnyDownload,
  required String downloadValue,
}) {
  _MenuAction deleteDownload() => _MenuAction(
    value: 'delete_download',
    icon: Symbols.delete_rounded,
    label: t.downloads.deleteDownload,
    destructive: true,
  );
  if (hasSyncRule) {
    return [
      _MenuAction(value: 'manage_sync', icon: Symbols.sync_rounded, label: t.downloads.manageSyncRule),
      _MenuAction(value: 'remove_sync', icon: Symbols.sync_disabled_rounded, label: t.downloads.removeSyncRule),
      if (hasAnyDownload) deleteDownload(),
    ];
  }
  return [
    if (hasAnyDownload)
      deleteDownload()
    else
      _MenuAction(value: downloadValue, icon: Symbols.download_rounded, label: t.downloads.downloadNow),
  ];
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

/// Whether "Delete from server" may be offered for an item.
///
/// Deliberately not folded into [isAdminActionAllowedForMediaItem]: on MediaBrowser servers
/// the admin bit says nothing about deletion. `BaseItem.IsAuthorizedToDelete`
/// consults `EnableContentDeletion` and the per-library grant only, and only
/// the auto-created first user gets the former for free — so an administrator
/// can lack the right (issue #1749) and a plain user can hold it. The server's
/// per-item answer ([resolvedItemPermission], from
/// [MediaDeletionPermissionClient]) is therefore the sole MediaBrowser condition,
/// and anything unknown — offline, request failed, timed out, item invisible —
/// stays hidden rather than offering a button that 401s.
///
/// Plex has no per-item permission on the wire, so it keeps the account-level
/// owner/admin gate.
bool isMediaDeletionAllowed({
  required MediaBackend? itemBackend,
  required bool? resolvedItemPermission,
  required bool isAdminActionAllowed,
}) => switch (itemBackend) {
  null => false,
  MediaBackend.jellyfin || MediaBackend.emby => resolvedItemPermission == true,
  MediaBackend.plex => isAdminActionAllowed,
};

/// Whether the in-memory item is confirmed to have no playable media
/// (a metadata-only placeholder, e.g. from a Seerr placeholder library).
/// Deliberately fails open: shows/seasons trust an explicit leafCount of 0
/// (populated by listings on both backends), while an empty version list is
/// only trusted on Plex — Jellyfin listings omit MediaSources, so null is
/// indistinguishable from "not loaded" there.
bool hasKnownNoPlayableMedia({
  required MediaKind? kind,
  required MediaBackend? backend,
  required List<MediaVersion>? mediaVersions,
  required int? leafCount,
}) => switch (kind) {
  MediaKind.movie || MediaKind.episode => backend == MediaBackend.plex && (mediaVersions?.isEmpty ?? false),
  MediaKind.show || MediaKind.season => leafCount == 0,
  _ => false,
};

/// A reusable wrapper widget that adds a context menu (long press / right click)
/// to any media item with appropriate actions based on the item type.
/// Caller-supplied entry appended to a [MediaContextMenu] (e.g. the
/// now-playing screen's Sleep timer). Selection runs [onSelected].
class MediaMenuExtraEntry {
  final IconData icon;
  final String label;
  final VoidCallback onSelected;

  const MediaMenuExtraEntry({required this.icon, required this.label, required this.onSelected});
}

class MediaContextMenu extends StatefulWidget {
  /// Either a [MediaItem] or a [MediaPlaylist]. Typed as [Object] because
  /// Dart has no nominal union type — guarded at runtime via the
  /// [_itemAsMediaItem] / [_itemAsPlaylist] helpers.
  final Object item;
  final void Function(MediaItem source)? onRefresh;
  final VoidCallback? onRemoveFromContinueWatching;
  final VoidCallback? onListRefresh;

  /// Plays the item's trailer. When non-null a "Play trailer" item is added to
  /// the menu. Only the detail screen passes this (it resolves the trailer from
  /// Plex extras), so the item never appears on card/browse context menus. This
  /// keeps the trailer reachable even when the detail row hides its trailer
  /// button to fit a small screen.
  final VoidCallback? onPlayTrailer;
  final Widget child;
  final bool isInContinueWatching;
  final String? collectionId; // The collection ID if displaying within a collection

  /// Extra entries appended after the standard actions.
  final List<MediaMenuExtraEntry> extraEntries;

  const MediaContextMenu({
    super.key,
    required this.item,
    this.onRefresh,
    this.onRemoveFromContinueWatching,
    this.onListRefresh,
    this.onPlayTrailer,
    required this.child,
    this.isInContinueWatching = false,
    this.collectionId,
    this.extraEntries = const [],
  });

  @override
  State<MediaContextMenu> createState() => MediaContextMenuState();
}

class MediaContextMenuState extends State<MediaContextMenu> {
  Offset? _tapPosition;

  bool _openedFromKeyboard = false;
  bool _isContextMenuOpen = false;

  bool get isContextMenuOpen => _isContextMenuOpen;

  void _notifyRefresh(MediaItem source) {
    if (!mounted) return;
    widget.onRefresh?.call(source);
  }

  void _notifyListRefresh() {
    if (!mounted) return;
    widget.onListRefresh?.call();
  }

  /// The widget's [item] cast as a [MediaItem], resolved against the session
  /// watch-state store so the offered actions match what the card shows.
  /// Returns `null` for playlists.
  MediaItem? get _mediaItem {
    final item = widget.item;
    return item is MediaItem ? context.readFreshWatchState(item) : null;
  }

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

  /// Item identifier used for playlist and download sync operations.
  String _itemId() => switch (widget.item) {
    MediaItem(:final id) => id,
    MediaPlaylist(:final id) => id,
    _ => '',
  };

  /// Get the correct PlexClient for this item's server. Throws on
  /// non-Plex backends — Plex-only flows (Add to Collection, match,
  /// unmatch, etc.) call this directly. Backend-neutral flows must use
  /// [_getMediaClientForItem] instead.
  PlexClient _getClientForItem() => context.getPlexClientWithFallback(serverIdOrNull(_itemServerId));

  /// Backend-neutral client for the active item's server. Used by flows
  /// that work for Jellyfin too (downloads, basic browse).
  MediaServerClient _getMediaClientForItem() => context.getMediaClientWithFallback(serverIdOrNull(_itemServerId));

  /// Ask the server whether the signed-in user may delete [item] right now.
  ///
  /// Returns `null` when the backend exposes no per-item permission (Plex),
  /// which leaves the account-level gate in charge, and `false` for every
  /// unknown on a backend that does expose one — offline, server down, request
  /// failed or timed out. The probe blocks the menu opening, so it is bounded
  /// by `MediaServerTimeouts.jellyfinDeletePermission` and does not chase
  /// failover endpoints: a stalled endpoint hunt would be felt as a frozen
  /// long-press, and hiding one entry is the cheaper failure.
  ///
  /// Backend detection comes first so a menu on a backend without the
  /// capability neither probes nor touches offline state — the read would
  /// otherwise be a new dependency for every screen that shows a movie row.
  Future<bool?> _resolveDeletePermission({
    required MediaServerClient? client,
    required MediaItem? item,
    required bool serverOnline,
  }) async {
    final permissionClient = client is MediaDeletionPermissionClient ? client as MediaDeletionPermissionClient : null;
    if (item == null || permissionClient == null) return null;
    if (!serverOnline || context.read<OfflineModeProvider>().isOffline) return false;
    try {
      return await permissionClient.fetchDeletePermission(item);
    } catch (e, st) {
      appLogger.w('Delete permission probe failed', error: e, stackTrace: st);
      return false;
    }
  }

  /// Send the item to the connected companion-remote host for playback, then
  /// open the remote screen so the user can control it from here.
  Future<void> _handlePlayOnConnectedDevice(BuildContext context) async {
    final item = _mediaItem;
    final serverId = _itemServerId;
    final companionRemote = context.read<CompanionRemoteProvider?>();
    if (item == null || serverId == null || companionRemote == null) return;

    companionRemote.sendCommand(RemoteCommandType.playMedia, data: {'serverId': serverId, 'ratingKey': item.id});

    if (!context.mounted) return;
    final deviceName = companionRemote.connectedDevice?.name ?? t.companionRemote.unknownDevice;
    showAppSnackBar(context, t.companionRemote.playSentToDevice(device: deviceName));
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileRemoteScreen()));
  }

  void _showContextMenu(BuildContext context) async {
    if (_isContextMenuOpen) return;
    _isContextMenuOpen = true;

    final previousFocus = FocusManager.instance.primaryFocus;
    bool didNavigate = false;

    final mediaItem = _mediaItem;
    final playlist = _playlist;
    final isPlaylist = playlist != null;
    final mediaKind = mediaItem?.kind;
    final isCollection = mediaKind == MediaKind.collection;

    // Backend-aware gate: a few menu items remain Plex-only because the
    // server-side feature has no MediaBrowser equivalent (match/unmatch).
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

    // Check if user has admin privileges. Backend-neutral: Plex uses the
    // server-owned flag (folded with the active Plex Home profile's admin
    // bit, when applicable); MediaBrowser servers use `JellyfinConnection.isAdministrator`
    // captured at sign-in.
    final multiServerProvider = Provider.of<MultiServerProvider>(context, listen: false);
    final activeProfile = context.read<ActiveProfileProvider>().active;
    final isOwnerOrAdmin =
        _itemServerId != null && multiServerProvider.serverManager.isOwnerOrAdmin(ServerId(_itemServerId!));
    final isAdmin = isAdminActionAllowedForMediaItem(
      isOwnerOrAdmin: isOwnerOrAdmin,
      itemBackend: itemBackend,
      activeProfile: activeProfile,
    );

    // Backend capabilities gate menu items so we don't expose actions the
    // active server cannot perform.
    final mediaClient = _itemServerId != null ? multiServerProvider.getClientForServer(ServerId(_itemServerId!)) : null;
    final canTranscode = mediaClient?.capabilities.videoTranscoding ?? false;
    // Static capabilities stay truthy while the server is unreachable, so
    // version/quality choices need a liveness check on top.
    final itemServerOnline =
        _itemServerId != null && multiServerProvider.serverManager.isClientOnline(ServerId(_itemServerId!));
    final canRemoveFromContinueWatching = mediaClient?.capabilities.continueWatchingRemoval ?? false;
    final canEditMetadata = isAdmin && supportsMetadataEdit(mediaClient, mediaKind);

    // Watchlist (movies and shows), backed by the connected catalog sources
    // (Trakt, Plex, MAL, ...). Whether THIS item resolves in a source needs
    // its external ids, which load lazily: the entry defaults to "Add" — an
    // idempotent no-op when the item turns out to be listed already — and
    // only offers "Remove" once cached candidates prove membership, so a
    // cold cache can never turn a press into a surprise removal. Opening
    // the menu warms both caches for the tap and the next open.
    final catalogSources = Provider.of<CatalogSourcesProvider?>(context, listen: false);
    var showWatchlistEntry = false;
    var watchlistRemoveOffered = false;
    if (mediaItem != null &&
        (mediaKind == MediaKind.movie || mediaKind == MediaKind.show) &&
        catalogSources != null &&
        catalogSources.watchlistCapableSources.isNotEmpty &&
        itemServerOnline &&
        !context.read<OfflineModeProvider>().isOffline) {
      final cachedCandidates = catalogSources.cachedWatchlistCandidatesFor(mediaItem);
      // Resolved-and-empty means no connected source can hold this item.
      showWatchlistEntry = cachedCandidates == null || cachedCandidates.isNotEmpty;
      watchlistRemoveOffered =
          cachedCandidates?.any((c) => c.source.isOnWatchlist(mediaItem.kind, c.ids) == true) ?? false;
      if (showWatchlistEntry) {
        unawaited(
          catalogSources.watchlistCandidatesFor(mediaItem, client: mediaClient).catchError((Object e, StackTrace st) {
            appLogger.d('Watchlist candidate warm-up failed', error: e, stackTrace: st);
            return const <WatchlistCandidate>[];
          }),
        );
        for (final source in catalogSources.watchlistCapableSources) {
          unawaited(source.ensureWatchlistLoaded());
        }
      }
    }

    // Deletion is the one gate that asks the server per item; see
    // [isMediaDeletionAllowed]. Only kinds that can actually be deleted pay
    // for the round trip, and only on a backend that answers it.
    final isDeletableKind =
        mediaKind == MediaKind.episode ||
        mediaKind == MediaKind.movie ||
        mediaKind == MediaKind.show ||
        mediaKind == MediaKind.season;
    final canDeleteFromServer =
        isDeletableKind &&
        isMediaDeletionAllowed(
          itemBackend: itemBackend,
          resolvedItemPermission: await _resolveDeletePermission(
            client: mediaClient,
            item: mediaItem,
            serverOnline: itemServerOnline,
          ),
          isAdminActionAllowed: isAdmin,
        );
    if (!mounted || !context.mounted) {
      // The awaited probe outlived the widget; the try/finally that normally
      // clears this flag only starts once the menu is on screen.
      _isContextMenuOpen = false;
      return;
    }

    final menuActions = <_MenuAction>[];

    if (isCollection || isPlaylist) {
      menuActions.add(_MenuAction(value: 'play', icon: Symbols.play_arrow_rounded, label: t.common.play));

      menuActions.add(_MenuAction(value: 'shuffle', icon: Symbols.shuffle_rounded, label: t.mediaMenu.shufflePlay));

      // Download + sync-rule management. Video and audio playlists and any
      // collection qualify — collections can contain movies, episodes,
      // shows, albums, and artists; audio playlists queue their tracks.
      final isDownloadablePlaylist =
          isPlaylist && (playlist.playlistType == 'video' || playlist.playlistType == 'audio');
      if ((isDownloadablePlaylist || isCollection) && !PlatformDetector.isAppleTV()) {
        menuActions.addAll(
          _syncDownloadMenuActions(
            hasSyncRule: Provider.of<DownloadProvider>(context, listen: false).hasSyncRule(_itemSyncRuleKey(context)),
            hasAnyDownload: false,
            downloadValue: isPlaylist ? 'download_playlist' : 'download_collection',
          ),
        );
      }

      menuActions.add(
        _MenuAction(value: 'delete', icon: Symbols.delete_rounded, label: t.common.delete, destructive: true),
      );
    } else {
      // Music (artist/album/track) playback + navigation actions. Queue
      // insertion only exists where a playback session is bound.
      final isMusicKind = mediaKind != null && mediaKind.isMusic;
      if (isMusicKind) {
        menuActions.add(_MenuAction(value: 'music_play', icon: Symbols.play_arrow_rounded, label: t.common.play));

        final musicAvailable = context.read<MusicPlaybackService?>() != null;
        if (musicAvailable) {
          menuActions.add(
            _MenuAction(value: 'music_play_next', icon: Symbols.playlist_play_rounded, label: t.music.playNext),
          );
          menuActions.add(
            _MenuAction(value: 'music_add_queue', icon: Symbols.queue_music_rounded, label: t.music.addToQueue),
          );
        }

        // Instant Mix — capability-gated, and only while the server is
        // reachable (capabilities stay truthy for offline servers).
        if (itemServerOnline && (mediaClient?.capabilities.instantMix ?? false)) {
          menuActions.add(
            _MenuAction(value: 'music_instant_mix', icon: Symbols.wand_stars_rounded, label: t.music.instantMix),
          );
        }

        // Go to Album (tracks only) — hidden when already on that album's
        // detail screen, mirroring the Go to Series ancestor check.
        final ancestorAlbumId = context.findAncestorWidgetOfExactType<AlbumDetailScreen>()?.album.id;
        if (mediaKind == MediaKind.track && mediaItem!.parentId != null && ancestorAlbumId != mediaItem.parentId) {
          menuActions.add(_MenuAction(value: 'music_album', icon: Symbols.album_rounded, label: t.music.goToAlbum));
        }

        // Go to Artist — album: parent, track: grandparent; hidden when
        // already on that artist's detail screen.
        final musicArtistId = switch (mediaKind) {
          MediaKind.album => mediaItem!.parentId,
          MediaKind.track => mediaItem!.grandparentId,
          _ => null,
        };
        final ancestorArtistId = context.findAncestorWidgetOfExactType<ArtistDetailScreen>()?.artist.id;
        if (musicArtistId != null && ancestorArtistId != musicArtistId) {
          menuActions.add(_MenuAction(value: 'music_artist', icon: Symbols.artist_rounded, label: t.music.goToArtist));
        }
      }

      if (hasActiveProgress) {
        menuActions.add(
          _MenuAction(value: 'play_from_beginning', icon: Symbols.replay_rounded, label: t.mediaMenu.playFromBeginning),
        );
      }

      // Trailer playback. The detail row may hide its trailer button on small
      // screens, so surface it here whenever the screen wires up onPlayTrailer.
      if (widget.onPlayTrailer != null) {
        menuActions.add(
          _MenuAction(value: 'play_trailer', icon: Symbols.theaters_rounded, label: t.tooltips.playTrailer),
        );
      }

      // Play on connected device — mobile only, and only while this phone is
      // the controller in an active companion-remote session; the host device
      // performs the playback (shows/seasons resolve to their next-unwatched
      // episode host-side). Hidden for items known to be metadata-only, but
      // failing open when media presence is unknowable from the listing item.
      final companionRemote = context.read<CompanionRemoteProvider?>();
      final canPlayOnConnectedDevice =
          (Platform.isAndroid || Platform.isIOS) &&
          _itemServerId != null &&
          (companionRemote?.isRemote ?? false) &&
          (companionRemote?.isConnected ?? false) &&
          !hasKnownNoPlayableMedia(
            kind: mediaKind,
            backend: itemBackend,
            mediaVersions: mediaItem?.mediaVersions,
            leafCount: mediaItem?.leafCount,
          ) &&
          (mediaKind == MediaKind.movie ||
              mediaKind == MediaKind.episode ||
              mediaKind == MediaKind.show ||
              mediaKind == MediaKind.season);
      if (canPlayOnConnectedDevice) {
        menuActions.add(
          _MenuAction(
            value: 'play_on_connected_device',
            icon: Symbols.cast_rounded,
            label: t.mediaMenu.playOnConnectedDevice,
          ),
        );
      }

      if (!mediaItem!.isWatched || isPartiallyWatched || hasActiveProgress) {
        menuActions.add(
          _MenuAction(value: 'watch', icon: Symbols.check_circle_outline_rounded, label: t.mediaMenu.markAsWatched),
        );
      }

      if (mediaItem.isWatched || isPartiallyWatched || hasActiveProgress) {
        menuActions.add(
          _MenuAction(
            value: 'unwatch',
            icon: Symbols.remove_circle_outline_rounded,
            label: t.mediaMenu.markAsUnwatched,
          ),
        );
      }

      if (widget.isInContinueWatching && canRemoveFromContinueWatching) {
        menuActions.add(
          _MenuAction(
            value: 'remove_from_continue_watching',
            icon: Symbols.close_rounded,
            label: t.mediaMenu.removeFromContinueWatching,
          ),
        );
      }

      final isVideoKind = mediaItem.isVideoContent;

      if (widget.isInContinueWatching && isVideoKind) {
        menuActions.add(_MenuAction(value: 'details', icon: Symbols.info_rounded, label: t.mediaMenu.viewDetails));
      }

      if (isVideoKind) {
        menuActions.add(_MenuAction(value: 'rate', icon: Symbols.star_rounded, label: t.mediaMenu.rate));
      }

      // Edit Metadata — admin-only and backend-capability gated.
      if (canEditMetadata) {
        menuActions.add(
          _MenuAction(value: 'edit_metadata', icon: Symbols.edit_rounded, label: t.metadataEdit.editMetadata),
        );
      }

      // Match / Unmatch — Plex-only (MediaBrowser servers don't expose match agents).
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
      // Plex-only — uses `removeFromCollection` API; MediaBrowser collection
      // membership APIs aren't wired here yet.
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
          !widget.isInContinueWatching &&
          ancestorSeriesKey != itemSeriesKey) {
        menuActions.add(_MenuAction(value: 'series', icon: Symbols.tv_rounded, label: t.mediaMenu.goToSeries));
      }

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
      // is known up front. Also hidden while the item's server is
      // unreachable: at most one version exists locally and plain Play
      // already targets it, so the picker would be a no-op detour
      // offering versions that can't play (issue #1440).
      final versionCount = (mediaItem.mediaVersions ?? const []).length;
      final hasVersionChoice = versionCount > 1;
      if ((mediaKind == MediaKind.episode || mediaKind == MediaKind.movie) &&
          (hasVersionChoice || canTranscode) &&
          itemServerOnline) {
        menuActions.add(
          _MenuAction(value: 'play_version', icon: Symbols.video_file_rounded, label: t.mediaMenu.playVersion),
        );
      }

      // File Info — every file-backed leaf kind (movies, episodes, tracks,
      // clips). Backend-neutral: both PlexClient and JellyfinClient implement
      // [MediaServerClient.getFileInfo], reading codec/stream metadata from
      // `Media`/`MediaSources` respectively. Container kinds are excluded by
      // [MediaKind.hasFileInfo] because neither backend attaches media sources
      // to them — a show/season/album/artist entry would only ever produce the
      // "not available" snackbar. Hidden when the item has no backend marker
      // so we don't fan out to an arbitrary client.
      if (itemBackend != null && mediaKind != null && mediaKind.hasFileInfo) {
        menuActions.add(_MenuAction(value: 'fileinfo', icon: Symbols.info_rounded, label: t.mediaMenu.fileInfo));
      }

      if (PlatformDetector.supportsExternalPlayers() &&
          (mediaKind == MediaKind.episode || mediaKind == MediaKind.movie)) {
        menuActions.add(
          _MenuAction(
            value: 'play_external',
            icon: Symbols.open_in_new_rounded,
            label: t.externalPlayer.playInExternalPlayer,
          ),
        );
      }

      // Download options (for episodes, movies, shows, seasons, albums, and
      // tracks — not artists, whose full discography is too large for a
      // one-tap download). Apple TV has no user-accessible file storage —
      // skip entirely.
      if (!PlatformDetector.isAppleTV() &&
          (mediaKind == MediaKind.episode ||
              mediaKind == MediaKind.movie ||
              mediaKind == MediaKind.show ||
              mediaKind == MediaKind.season ||
              mediaKind == MediaKind.album ||
              mediaKind == MediaKind.track)) {
        final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
        menuActions.addAll(
          _syncDownloadMenuActions(
            hasSyncRule: downloadProvider.hasSyncRule(_itemSyncRuleKey(context)),
            hasAnyDownload: downloadProvider.getProgress(mediaItem.globalKey) != null,
            downloadValue: 'download',
          ),
        );
      }

      if (showWatchlistEntry) {
        menuActions.add(
          _MenuAction(
            value: 'toggle_watchlist',
            icon: watchlistRemoveOffered ? Symbols.bookmark_remove_rounded : Symbols.bookmark_add_rounded,
            label: watchlistRemoveOffered ? t.explore.removeFromWatchlist : t.explore.addToWatchlist,
          ),
        );
      }

      // Add to... (for episodes, movies, shows, and seasons). Plex-only —
      // uses `buildMetadataUri` + `addToPlaylist` / `addToCollection`. The
      // MediaBrowser item-add APIs are different and not wired here yet.
      if (isPlex &&
          (mediaKind == MediaKind.episode ||
              mediaKind == MediaKind.movie ||
              mediaKind == MediaKind.show ||
              mediaKind == MediaKind.season)) {
        menuActions.add(_MenuAction(value: 'add_to', icon: Symbols.add_rounded, label: t.common.addTo));
      }

      // Delete media item (for episodes, movies, shows, and seasons). Routed
      // through `MediaServerClient.deleteMediaItem`, which every backend
      // implements (DELETE /library/metadata/{id} for Plex and
      // DELETE /Items/{id} for MediaBrowser servers); the kind and permission checks were
      // resolved together above.
      //
      // The label names the kind. One shared "Delete from server" string for
      // an episode, a season and a whole show is what let #1781 happen: the
      // reporter hit the show-level entry believing it acted on the episode
      // he had highlighted.
      if (canDeleteFromServer) {
        menuActions.add(
          _MenuAction(
            value: 'delete_media',
            icon: Symbols.delete_forever_rounded,
            label: _deleteMenuLabel(mediaKind),
            destructive: true,
          ),
        );
      }
    }

    for (var i = 0; i < widget.extraEntries.length; i++) {
      final entry = widget.extraEntries[i];
      menuActions.add(_MenuAction(value: 'extra_$i', icon: entry.icon, label: entry.label));
    }

    final openedFromKeyboard = _openedFromKeyboard;
    _openedFromKeyboard = false;

    var position = _tapPosition;
    if (position == null) {
      final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      position = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
    }

    // Present from the menu's own context: it sits at the trigger widget,
    // below any screen-level OverlaySheetHost, while callers often pass a
    // screen context from ABOVE its host (which would skip the host and
    // fall back to a hostless modal sheet).
    final selected = await showAdaptiveAppMenu<String>(
      this.context,
      title: _itemMenuTitle(),
      entries: _menuEntries(menuActions),
      position: position,
      focusFirstItem: openedFromKeyboard,
      isScrollControlled: true,
    );

    try {
      if (!context.mounted) return;

      // Caller-supplied extra entries dispatch straight to their callback.
      if (selected != null && selected.startsWith('extra_')) {
        final index = int.tryParse(selected.substring('extra_'.length));
        if (index != null && index >= 0 && index < widget.extraEntries.length) {
          widget.extraEntries[index].onSelected();
        }
        return;
      }

      switch (selected) {
        case 'play_from_beginning':
          didNavigate = true;
          if (context.mounted) {
            await navigateToVideoPlayer(
              context,
              metadata: mediaItem!.copyWith(viewOffsetMs: 0),
              resolveWatchState: false,
            );
          }
          break;

        case 'play_trailer':
          didNavigate = true;
          widget.onPlayTrailer?.call();
          break;

        case 'play_on_connected_device':
          didNavigate = true;
          if (context.mounted) {
            await _handlePlayOnConnectedDevice(context);
          }
          break;

        case 'watch':
        case 'unwatch':
          final watched = selected == 'watch';
          final item = mediaItem;
          if (item == null) break;
          final isOffline = context.read<OfflineModeProvider>().isOffline;
          if (isOffline && item.serverId != null) {
            // Queue for later sync — the offline provider emits the WatchStateEvent.
            await WatchActions.setWatched(context, item, watched: watched, offline: true);
            if (context.mounted) {
              showAppSnackBar(
                context,
                watched ? t.messages.markedAsWatchedOffline : t.messages.markedAsUnwatchedOffline,
              );
              _notifyRefresh(item);
            }
          } else {
            await _executeAction(context, () async {
              await WatchActions.setWatched(context, item, watched: watched, offline: false);
            }, watched ? t.messages.markedAsWatched : t.messages.markedAsUnwatched);
          }
          break;

        case 'remove_from_continue_watching':
          // Remove from Continue Watching without affecting watch status or progress
          // This preserves the progression for partially watched items
          // and doesn't mark unwatched next episodes as watched
          try {
            await WatchActions.removeFromContinueWatching(context, mediaItem!);
            if (context.mounted) {
              showSuccessSnackBar(context, t.messages.removedFromContinueWatching);
              if (widget.onRemoveFromContinueWatching != null) {
                widget.onRemoveFromContinueWatching!();
              } else {
                _notifyRefresh(mediaItem);
              }
            }
          } catch (e) {
            if (context.mounted) {
              showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
            }
          }
          break;

        case 'details':
          didNavigate = true;
          if (context.mounted) {
            await navigateToMediaItemDetails(context, mediaItem!, onRefresh: _notifyRefresh);
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
            final item = mediaItem!;
            await Navigator.push(context, MaterialPageRoute(builder: (context) => MetadataEditScreen(metadata: item)));
            _notifyRefresh(item);
          }
          break;

        case 'match':
          didNavigate = true;
          if (context.mounted) {
            final item = mediaItem!;
            await Navigator.push(context, MaterialPageRoute(builder: (context) => PlexMatchScreen(metadata: item)));
            _notifyRefresh(item);
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
            (context, item) async {
              final target = mediaDetailNavigationTargetFor(mediaItem, metadataOverride: item);
              await Navigator.push(
                context,
                mediaDetailRoute(
                  metadata: target.metadata,
                  initialSeasonIndex: target.initialSeasonIndex,
                  initialSeasonId: target.initialSeasonId,
                  initialEpisodeId: target.initialEpisodeId,
                ),
              );
            },
            t.messages.errorLoadingSeries,
          );
          break;

        case 'play_version':
          didNavigate = await promptAndPlayVersion(context, _mediaItem!);
          break;

        case 'fileinfo':
          await _showFileInfo(context);
          break;

        case 'add_to':
          await _showAddToSubmenu(context);
          break;

        case 'toggle_watchlist':
          await _handleWatchlistToggle(
            context,
            mediaItem!,
            catalogSources!,
            mediaClient,
            removeOffered: watchlistRemoveOffered,
            position: position,
            openedFromKeyboard: openedFromKeyboard,
          );
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
          await _handleDownloadList(context, isPlaylist: true);
          break;

        case 'download_collection':
          await _handleDownloadList(context, isPlaylist: false);
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

        case 'music_play':
          await _handleMusicPlay(context);
          break;

        case 'music_play_next':
          await _handleMusicEnqueue(context, playNext: true);
          break;

        case 'music_add_queue':
          await _handleMusicEnqueue(context, playNext: false);
          break;

        case 'music_instant_mix':
          await playInstantMix(context, mediaItem!);
          break;

        case 'music_album':
          didNavigate = true;
          await _navigateToRelated(context, mediaItem!.parentId, navigateToAlbum, t.common.error);
          break;

        case 'music_artist':
          didNavigate = true;
          await _navigateToRelated(
            context,
            mediaItem!.kind == MediaKind.album ? mediaItem.parentId : mediaItem.grandparentId,
            navigateToArtist,
            t.common.error,
          );
          break;
      }
    } catch (e, st) {
      appLogger.e('Media context menu action failed', error: e, stackTrace: st);
      if (context.mounted) {
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
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

  List<AppMenuEntry<String>> _menuEntries(List<_MenuAction> actions) {
    return [
      for (final action in actions)
        AppMenuItem<String>(
          value: action.value,
          icon: action.icon,
          label: action.label,
          destructive: action.destructive,
        ),
    ];
  }

  /// Resolve-then-mutate for the watchlist entry. [removeOffered] pins the
  /// intent the user saw: an entry labeled "Add" always adds (idempotent
  /// when the item was already listed) — resolution finishing after the
  /// menu was built must not flip a press into a removal. With several
  /// capable sources a chooser opens and the picked source toggles by its
  /// own (by now resolved) membership, mirroring the detail screen.
  Future<void> _handleWatchlistToggle(
    BuildContext context,
    MediaItem item,
    CatalogSourcesProvider catalogSources,
    MediaServerClient? client, {
    required bool removeOffered,
    required Offset? position,
    required bool openedFromKeyboard,
  }) async {
    List<WatchlistCandidate> candidates;
    try {
      candidates = await catalogSources.watchlistCandidatesFor(item, client: client);
    } catch (e, st) {
      appLogger.w('Watchlist candidate resolution failed', error: e, stackTrace: st);
      if (context.mounted) showErrorSnackBar(context, t.explore.watchlistUpdateFailed);
      return;
    }
    if (!context.mounted) return;
    if (candidates.isEmpty) {
      showAppSnackBar(context, t.explore.watchlistNoMatch);
      return;
    }

    final WatchlistCandidate candidate;
    final bool add;
    if (candidates.length == 1) {
      candidate = candidates.single;
      add = !removeOffered;
    } else {
      final choice = await showWatchlistSourceChooser(
        context,
        kind: item.kind,
        candidates: candidates,
        position: position,
        focusFirstItem: openedFromKeyboard,
      );
      if (choice == null || !context.mounted) return;
      candidate = choice;
      add = !(choice.source.isOnWatchlist(item.kind, choice.ids) ?? false);
    }

    try {
      // Membership updates optimistically inside the source; Explore rows
      // and open detail screens listening to watchlistChanges follow.
      if (!await mutateWatchlistMembership(item.kind, candidate, add: add)) return;
      if (!context.mounted) return;
      showSuccessSnackBar(context, add ? t.explore.addedToWatchlist : t.explore.removedFromWatchlist);
    } catch (e, st) {
      appLogger.w('Watchlist update failed', error: e, stackTrace: st);
      if (context.mounted) showErrorSnackBar(context, t.explore.watchlistUpdateFailed);
    }
  }

  /// Execute an action with error handling and refresh
  Future<void> _executeAction(BuildContext context, Future<void> Function() action, String successMessage) async {
    try {
      await action();
      if (context.mounted) {
        showSuccessSnackBar(context, successMessage);
        if (_mediaItem case final source?) _notifyRefresh(source);
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
        _notifyRefresh(item);
      } else {
        showErrorSnackBar(context, t.matchScreen.unmatchFailed);
      }
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      }
    }
  }

  /// Fetch and navigate to a related item (series, album, or artist).
  Future<void> _navigateToRelated(
    BuildContext context,
    String? id,
    Future<void> Function(BuildContext context, MediaItem item) navigate,
    String errorPrefix,
  ) async {
    if (id == null) return;

    final client = _getMediaClientForItem();
    final source = _mediaItem;
    if (source == null) return;

    try {
      final metadata = await client.fetchItem(id);
      if (metadata != null && context.mounted) {
        await navigate(context, metadata);
        _notifyRefresh(source);
      }
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, '$errorPrefix: $e');
      }
    }
  }

  Future<void> _showFileInfo(BuildContext context) async {
    // The spinner is owned by a ScopedLoadingDialogController so the
    // `finally` can dismiss it even after the launching card unmounts —
    // the controller pops via the dialog's own context and only while the
    // dialog route is still current. A bare captured navigator + `canPop`
    // is insufficient: it can pop an intervening route instead.
    final loadingDialog = ScopedLoadingDialogController();

    try {
      final client = _getMediaClientForItem();
      if (context.mounted) {
        loadingDialog.show(
          context,
          // Same back-trapping spinner as [showLoadingDialog]: nothing the
          // user can do mid-fetch is better than backing into the screen
          // underneath while the pop is pending.
          builder: (_) => const PopScope(canPop: false, child: Center(child: CircularProgressIndicator())),
        );
      }

      // Fetch file info
      final item = _mediaItem!;
      final fileInfo = await client.getFileInfo(item);

      // Close the loading indicator before presenting the sheet.
      await loadingDialog.dismiss();

      if (fileInfo != null && context.mounted && mounted) {
        // Show file info bottom sheet, presented from the menu's own context
        // so a screen-level OverlaySheetHost is found (see _showContextMenu).
        await OverlaySheetController.showAdaptive(
          this.context,
          isScrollControlled: true,
          builder: (context) => FileInfoBottomSheet(fileInfo: fileInfo, title: item.displayTitle),
        );
      } else if (context.mounted) {
        showErrorSnackBar(context, t.messages.fileInfoNotAvailable);
      }
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, t.messages.errorLoadingFileInfo(error: e.toString()));
      }
    } finally {
      await loadingDialog.dismiss();
    }
  }

  /// The track list music playback should operate on for [item]: the item
  /// itself for a track, an album's tracks, or an artist's playable
  /// descendants (one server round-trip for the container kinds).
  Future<List<MediaItem>> _musicTracksForItem(MediaItem item) async {
    final client = _getMediaClientForItem();
    return switch (item.kind) {
      MediaKind.album => await client.fetchAlbumTracks(item.id),
      MediaKind.artist => await client.fetchPlayableDescendants(item.id),
      _ => [item],
    };
  }

  Future<void> _handleMusicPlay(BuildContext context) async {
    final item = _mediaItem!;
    if (item.kind == MediaKind.track) {
      await playTrackWithAlbumContext(context, item);
      return;
    }
    // No onError: a failed container fetch falls through to this menu's own
    // error boundary, which logs it and shows the snackbar.
    await playFetchedTracks(
      context,
      fetch: () => _musicTracksForItem(item),
      playContext: MusicPlayContext(
        title: item.displayTitle,
        kind: item.kind == MediaKind.artist ? MusicPlayContextKind.artist : MusicPlayContextKind.album,
      ),
    );
  }

  Future<void> _handleMusicEnqueue(BuildContext context, {required bool playNext}) async {
    final service = context.read<MusicPlaybackService?>();
    // Menu entries are hidden without a session; defensive re-check.
    if (service == null) return;
    final queueSessionRevision = service.queueSessionRevision;
    List<MediaItem> tracks;
    try {
      tracks = await _musicTracksForItem(_mediaItem!);
    } catch (_) {
      if (!context.mounted || service.queueSessionRevision != queueSessionRevision) return;
      rethrow;
    }
    if (!context.mounted || service.queueSessionRevision != queueSessionRevision || tracks.isEmpty) return;
    if (playNext) {
      service.addNext(tracks);
    } else {
      service.addToEnd(tracks);
    }
  }

  /// Handle shuffle play using play queues — dispatches via the
  /// neutral [MediaListPlaybackLauncher] so Jellyfin items get routed to
  /// `JellyfinSequentialLauncher` instead of falling through to the
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

    if (selected == 'playlist' && context.mounted) {
      await _showAddToPlaylistDialog(context);
    } else if (selected == 'collection' && context.mounted) {
      await _showAddToCollectionDialog(context);
    }
  }

  Future<void> _showAddToPlaylistDialog(BuildContext context) async {
    final client = _getMediaClientForItem();

    try {
      final item = _mediaItem!;

      final result = await showScopedDialog<String>(
        context: context,
        builder: (context) => PlaylistSelectionDialog(client: client),
      );

      if (result == null || !context.mounted) return;

      await _addItemToContainer<MediaPlaylist>(
        context,
        kind: 'playlist',
        item: item,
        client: client,
        result: result,
        createPrompt: (title: t.playlists.create, label: t.playlists.playlistName, hint: t.playlists.enterPlaylistName),
        create: (name) => client.createPlaylist(title: name, items: [item]),
        createdLog: (playlist) => 'Successfully created playlist: ${playlist.title}',
        eagerSyncId: (_) => null,
        add: () => client.addToPlaylist(playlistId: result, items: [item]),
        messages: (
          created: t.playlists.created,
          createError: t.playlists.errorCreating,
          added: t.playlists.itemAdded,
          addError: t.playlists.errorAdding,
        ),
        notifyChanged: () => LibraryRefreshNotifier().notifyPlaylistsChanged(),
      );
    } catch (e, stackTrace) {
      appLogger.e('Error in add to playlist flow', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        showErrorSnackBar(context, '${t.playlists.errorLoading}: ${e.toString()}');
      }
    }
  }

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
      final resolvedLibraryId = libraryId;
      if (!context.mounted) return;

      final result = await showScopedDialog<String>(
        context: context,
        builder: (context) => CollectionSelectionDialog(client: client, libraryId: resolvedLibraryId),
      );

      if (result == null || !context.mounted) return;

      await _addItemToContainer<String>(
        context,
        kind: 'collection',
        item: item,
        client: client,
        result: result,
        createPrompt: (
          title: t.common.createNew,
          label: t.collections.collectionName,
          hint: t.collections.enterCollectionName,
        ),
        create: (name) =>
            client.createCollection(libraryId: resolvedLibraryId, title: name, items: [item], itemKind: itemKind),
        createdLog: (id) => 'Successfully created collection with ID: $id',
        eagerSyncId: (id) => id,
        add: () => client.addToCollection(collectionId: result, items: [item]),
        messages: (
          created: t.collections.created,
          createError: t.collections.errorAddingToCollection,
          added: t.collections.addedToCollection,
          addError: t.collections.errorAddingToCollection,
        ),
        notifyChanged: () => LibraryRefreshNotifier().notifyCollectionsChanged(),
      );
    } catch (e, stackTrace) {
      appLogger.e('Error in add to collection flow', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        showErrorSnackBar(context, '${t.collections.errorAddingToCollection}: ${e.toString()}');
      }
    }
  }

  /// Create-or-add tail shared by the "Add to playlist" and "Add to collection"
  /// flows. [result] is the picker selection: an existing container id, or the
  /// `_create_new` sentinel to prompt for a name and create one via [create].
  /// [eagerSyncId] maps a freshly created container to the id to eager-sync, or
  /// `null` to skip it.
  Future<void> _addItemToContainer<T extends Object>(
    BuildContext context, {
    required String kind,
    required MediaItem item,
    required MediaServerClient client,
    required String result,
    required ({String title, String label, String hint}) createPrompt,
    required Future<T?> Function(String name) create,
    required String Function(T created) createdLog,
    required String? Function(T created) eagerSyncId,
    required Future<bool> Function() add,
    required ({String created, String createError, String added, String addError}) messages,
    required VoidCallback notifyChanged,
  }) async {
    if (result == '_create_new') {
      final name = await showTextInputDialog(
        context,
        title: createPrompt.title,
        labelText: createPrompt.label,
        hintText: createPrompt.hint,
      );

      if (name == null || name.isEmpty || !context.mounted) return;

      appLogger.d('Creating $kind "$name" seeded with item ${item.id}');
      final created = await create(name);

      if (!context.mounted) return;

      if (created != null) {
        appLogger.d(createdLog(created));
        showSuccessSnackBar(context, messages.created);
        notifyChanged();
        final syncId = eagerSyncId(created);
        if (syncId != null) {
          _triggerEagerSyncIfRuleExists(context, client.serverId, syncId);
        }
      } else {
        appLogger.e('Failed to create $kind - API returned null');
        showErrorSnackBar(context, messages.createError);
      }
    } else {
      appLogger.d('Adding item ${item.id} to $kind $result');
      final success = await add();

      if (!context.mounted) return;

      if (success) {
        appLogger.d('Successfully added item(s) to $kind $result');
        showSuccessSnackBar(context, messages.added);
        notifyChanged();
        _triggerEagerSyncIfRuleExists(context, client.serverId, result);
      } else {
        appLogger.e('Failed to add item(s) to $kind $result - API returned false');
        showErrorSnackBar(context, messages.addError);
      }
    }
  }

  Future<void> _showRatingSheet(BuildContext context, MediaItem item, MediaServerClient client) async {
    if (!mounted) return;
    // Presented from the menu's own context so a screen-level
    // OverlaySheetHost is found (see _showContextMenu).
    await OverlaySheetController.showAdaptive(
      this.context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => RatingBottomSheet(
        item: item,
        serverClient: client,
        onServerRatingChanged: (_) => _notifyRefresh(item),
        onServerFavoriteChanged: (_) => _notifyRefresh(item),
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
          _notifyListRefresh();
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
    final playlist = _playlist;
    if (playlist != null && playlist.playlistType == 'audio') {
      await playAudioPlaylist(
        context,
        client: _getMediaClientForItem(),
        playlist: playlist,
        shuffle: shuffle,
        onError: (e, st) {
          appLogger.w('Failed to fetch audio playlist ${playlist.id}', error: e, stackTrace: st);
          showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
        },
        onEmpty: () => showErrorSnackBar(context, t.messages.failedToCreatePlayQueueNoItems),
      );
      return;
    }

    // Launcher accepts both MediaItem (for collections) and MediaPlaylist.
    final launcher = MediaListPlaybackLauncher.forItem(context, widget.item);
    await launcher.launchFromCollectionOrPlaylist(item: widget.item, shuffle: shuffle);
  }

  /// Handle delete action for collections and playlists
  Future<void> _handleDelete(BuildContext context, bool _, bool isPlaylist) async {
    final client = _getMediaClientForItem();

    if (isPlaylist) {
      await deletePlaylistWithConfirm(
        context,
        client: client,
        playlist: _playlist!,
        confirmTitle: t.playlists.delete,
        onDeleted: _notifyListRefresh,
      );
      return;
    }

    final confirmed = await showDeleteConfirmation(
      context,
      title: t.collections.deleteCollection,
      message: t.collections.deleteConfirm(title: _itemDisplayTitle()),
    );
    if (!confirmed || !context.mounted) return;

    try {
      final success = await client.deleteCollection(_mediaItem!);
      if (context.mounted) {
        if (success) {
          showSuccessSnackBar(context, t.collections.deleted);
          // Trigger list refresh
          _notifyListRefresh();
        } else {
          showErrorSnackBar(context, t.collections.deleteFailed);
        }
      }
    } catch (e) {
      appLogger.e('Failed to delete collection', error: e);
      if (context.mounted) {
        showErrorSnackBar(context, t.collections.deleteFailedWithError(error: e.toString()));
      }
    }
  }

  /// Handle play in external player action
  Future<void> _handlePlayExternal(BuildContext context) async {
    if (!PlatformDetector.supportsExternalPlayers()) return;

    final item = _mediaItem!;

    // Check if the item is downloaded and use local file path if available
    final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
    final offlineWatchService = Provider.of<OfflineWatchSyncService>(context, listen: false);
    final client = _getMediaClientForItem();
    final globalKey = item.globalKey;
    if (downloadProvider.isDownloaded(globalKey)) {
      final videoPath = await downloadProvider.getVideoFilePath(globalKey);
      if (videoPath != null && context.mounted) {
        final videoUrl = videoPath.contains('://') ? videoPath : 'file://$videoPath';
        await ExternalPlayerService.launch(
          context: context,
          videoUrl: videoUrl,
          metadata: item,
          client: client,
          offlineWatchService: offlineWatchService,
        );
        return;
      }
    }

    if (!context.mounted) return;
    await ExternalPlayerService.launch(
      context: context,
      metadata: item,
      client: client,
      offlineWatchService: offlineWatchService,
    );
  }

  /// One dialog-driven download flow for both list kinds — the sync/one-time
  /// dialog wired to [showListDownloadOptionsAndQueue] via
  /// [fetchAndQueueListDownload]. Playlists synthesise their root metadata
  /// inside [downloadPlaylist]; collections pass the item itself.
  Future<void> _handleDownloadList(BuildContext context, {required bool isPlaylist}) async {
    final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
    final client = _getMediaClientForItem();

    if (isPlaylist) {
      await downloadPlaylist(context, client: client, downloadProvider: downloadProvider, playlist: _playlist!);
      return;
    }

    final collection = _mediaItem!;
    await fetchAndQueueListDownload(
      context,
      client: client,
      downloadProvider: downloadProvider,
      fetchItems: () => fetchAllCollectionItemsPaged(
        client,
        collection.id,
        libraryId: collection.libraryId,
        libraryTitle: collection.libraryTitle,
      ),
      rootMetadata: collection,
      targetType: ContentTypes.collection,
    );
  }

  /// Handle download action
  Future<void> _handleDownload(BuildContext context) async {
    final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
    final item = _mediaItem!;

    try {
      // Backend-agnostic resolve so Jellyfin items can be downloaded too.
      final client = context.getMediaClientWithFallback(serverIdOrNull(_itemServerId));
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
        _notifyRefresh(item);
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
    final client = context.tryGetMediaClientForServer(ServerId(serverId));
    if (client == null) return globalKey;
    return context.read<DownloadProvider>().syncRuleKeyForClient(client, _itemId(), serverId: ServerId(serverId));
  }

  String _itemDisplayTitle() => switch (widget.item) {
    MediaItem(:final displayTitle) => displayTitle,
    MediaPlaylist(:final displayTitle) => displayTitle,
    _ => '',
  };

  /// Header for the menu itself. Unlike [_itemDisplayTitle] — which stays on
  /// [MediaItem.displayTitle] for snackbars and the file-info sheet — this
  /// names the exact item the entries will act on, so an episode's menu is no
  /// longer headed by its show's name (#1781).
  String _itemMenuTitle() => switch (widget.item) {
    final MediaItem item => formatMediaTargetLabel(item),
    MediaPlaylist(:final displayTitle) => displayTitle,
    _ => '',
  };

  String _deleteMenuLabel(MediaKind? kind) => switch (kind) {
    MediaKind.season => t.mediaMenu.deleteSeasonFromServer,
    MediaKind.show => t.mediaMenu.deleteShowFromServer,
    MediaKind.movie => t.mediaMenu.deleteMovieFromServer,
    _ => t.mediaMenu.deleteEpisodeFromServer,
  };

  Future<void> _handleManageSyncRule(BuildContext context) => manageSyncRule(
    context,
    downloadProvider: context.read<DownloadProvider>(),
    globalKey: _itemSyncRuleKey(context),
    displayTitle: _itemDisplayTitle(),
  );

  /// Fire-and-forget: if a sync rule exists for the target list, run it now so
  /// newly-added items download immediately instead of waiting for the next
  /// cooldown-gated general pass. Fails silently — errors are logged only.
  static void _triggerEagerSyncIfRuleExists(BuildContext context, ServerId serverId, String listId) {
    try {
      final downloadProvider = Provider.of<DownloadProvider>(context, listen: false);
      final client = Provider.of<MultiServerProvider>(context, listen: false).getClientForServer(serverId);
      final globalKey = client == null
          ? buildGlobalKey(ServerId(serverId), listId)
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

  /// Handle delete media item action.
  ///
  /// Permanently removes the item and its files from the server. Everything
  /// before the DELETE exists to make the blast radius legible: the dialog
  /// names the exact target, states the kind, and — for a single playable
  /// item — reports what the server will actually destroy. When that cannot
  /// be established, the dialog says so instead of implying single-file
  /// scope (#1781).
  Future<void> _handleDeleteMediaItem(BuildContext context, MediaKind? mediaKind) async {
    final item = _mediaItem!;
    final client = _getMediaClientForItem();

    // Shows and seasons are known-broad by definition; probing their parts
    // would be a per-episode fan-out to restate what the copy already says.
    final probesImpact = mediaKind == MediaKind.episode || mediaKind == MediaKind.movie;
    DeleteImpact? impact;
    if (probesImpact) {
      showLoadingDialog(context);
      try {
        impact = await resolveDeleteImpact(item: item, client: client);
      } finally {
        // The spinner traps system back and nothing else pushes during the
        // probe, so it is still the top route here. A `Navigator.canPop`
        // guard would only test "is anything poppable", which is true of the
        // screen underneath — exactly the route that must not close.
        if (context.mounted) Navigator.pop(context);
      }
      if (!context.mounted) return;
    }

    final confirmed = await showDeleteConfirmation(
      context,
      title: _deleteDialogTitle(mediaKind),
      message: t.mediaMenu.confirmDeleteTarget(title: formatMediaTargetLabel(item)),
      warning: _deleteWarning(item, mediaKind, impact),
      confirmText: impact != null && impact.isUnverified ? t.mediaMenu.deleteAnyway : _deleteConfirmLabel(mediaKind),
    );

    if (!confirmed || !context.mounted) return;

    try {
      final success = await client.deleteMediaItem(item);

      if (context.mounted) {
        if (success) {
          showSuccessSnackBar(context, t.mediaMenu.mediaDeletedSuccessfully);
          // Broadcast deletion event for cross-screen propagation
          DeletionNotifier().notifyDeletedItem(item: item);
          // Siblings sharing the deleted file died with it server-side. Without
          // their own events their rows linger until a full refresh.
          for (final sibling in impact?.sharedWith ?? const <MediaItem>[]) {
            DeletionNotifier().notifyDeletedItem(item: sibling);
          }
          // Backward-compatible list refresh for screens that are not DeletionAware yet
          _notifyListRefresh();
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

  String _deleteDialogTitle(MediaKind? kind) => switch (kind) {
    MediaKind.season => t.mediaMenu.deleteSeasonTitle,
    MediaKind.show => t.mediaMenu.deleteShowTitle,
    MediaKind.movie => t.mediaMenu.deleteMovieTitle,
    _ => t.mediaMenu.deleteEpisodeTitle,
  };

  String _deleteConfirmLabel(MediaKind? kind) => switch (kind) {
    MediaKind.season => t.mediaMenu.deleteSeasonConfirm,
    MediaKind.show => t.mediaMenu.deleteShowConfirm,
    MediaKind.movie => t.mediaMenu.deleteMovieConfirm,
    _ => t.mediaMenu.deleteEpisodeConfirm,
  };

  /// The danger block under the confirmation message, or null when the delete
  /// is verified to remove exactly the named item.
  String? _deleteWarning(MediaItem item, MediaKind? kind, DeleteImpact? impact) {
    if (kind == MediaKind.show || kind == MediaKind.season) {
      // leafCount is the episode total; a season falls back to its direct
      // children. Neither is guaranteed, so keep the countless sentence.
      final episodes = item.leafCount ?? (kind == MediaKind.season ? item.childCount : null);
      return episodes != null && episodes > 0
          ? t.mediaMenu.deleteEpisodeCountWarning(n: episodes)
          : t.mediaMenu.deleteMultipleWarning;
    }

    if (impact == null) return null;

    if (impact.isUnverified) {
      return switch (impact.reason) {
        DeleteImpactUnverifiedReason.noFileInfo => t.mediaMenu.deleteScopeUnverifiedNoFileInfo,
        _ => t.mediaMenu.deleteScopeUnverifiedProbeFailed,
      };
    }

    if (!impact.isBroad) return null;

    final lines = <String>[];
    if (impact.files.length > 1) lines.add(t.mediaMenu.deleteMultiPartWarning(n: impact.files.length));
    if (impact.sharedWith.isNotEmpty) {
      lines.add(t.mediaMenu.deleteSharedFileHeading(n: impact.sharedWith.length));
      lines.addAll(impact.sharedWith.map((sibling) => '\u2022 ${formatMediaTargetLabel(sibling)}'));
    }
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    // GestureDetector wrapping removed — gesture callbacks are now on InkWell
    // directly in the card widgets, saving 1 element level. The context menu
    // is still accessible programmatically via showContextMenu().
    return widget.child;
  }
}
