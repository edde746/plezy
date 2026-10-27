import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../media/episode_collection.dart';
import '../../media/ids.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_server_client.dart';
import '../../models/livetv_channel.dart';
import '../../providers/catalog_sources_provider.dart';
import '../../providers/download_provider.dart';
import '../../providers/multi_server_provider.dart';
import '../../utils/app_logger.dart';
import '../../utils/global_key_utils.dart';
import '../../utils/live_tv_player_navigation.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/video_player_navigation.dart';
import '../catalog/plex_catalog_source.dart';
import '../data_aggregation_service.dart';
import '../media_list_playback_launcher.dart';
import 'deep_link.dart';

/// How long a link waits for the server it needs to come online, e.g. while
/// the app reconnects after the device woke up.
const deepLinkServerWait = Duration(seconds: 20);

/// Acts on [link] inside the active profile session, replacing whatever is
/// playing. The link's profile has already been applied.
Future<void> launchDeepLink(BuildContext context, DeepLink link, {required bool isOffline}) async {
  switch (link) {
    case OpenLink() || ExternalPlayerReturnLink():
      return;
    case PlayLink():
      await _launchPlayLink(context, link, isOffline: isOffline);
    case LiveLink():
      await _launchLiveLink(context, link, isOffline: isOffline);
  }
}

Future<void> _launchPlayLink(BuildContext context, PlayLink link, {required bool isOffline}) async {
  final multiServer = context.read<MultiServerProvider>();
  final downloads = context.read<DownloadProvider>();
  final plexCatalog = context
      .read<CatalogSourcesProvider>()
      .connectedSources
      .whereType<PlexCatalogSource>()
      .firstOrNull;
  final resolver = PlayLinkResolver(
    PlayLinkSources(
      clientFor: multiServer.getClientForServer,
      isServerOnline: multiServer.isServerOnline,
      hasOnlineServers: () => multiServer.hasConnectedServers,
      serversChanged: multiServer,
      findCatalogCopies: (target) => multiServer.aggregationService.findByExternalIdsAcrossServers(
        target.ids,
        kind: target.kind,
        serverIds: multiServer.expectedServerIds.toSet(),
        plexGuid: target.plexGuid,
      ),
      downloadedItem: (serverId, itemId) {
        final globalKey = buildGlobalKey(serverId, itemId);
        return downloads.isDownloaded(globalKey) ? downloads.getMetadata(globalKey) : null;
      },
      resolvePlexHash: plexCatalog == null
          ? null
          : (target) async => (await plexCatalog.resolveItemIds(target.kind, target.ids))?.plex,
    ),
    // An offline session has no server to wait for.
    serverWait: isOffline ? Duration.zero : deepLinkServerWait,
  );

  final resolution = await resolver.resolve(link);
  if (!context.mounted) return;
  switch (resolution) {
    case PlayLinkFailure(:final reason):
      showMainSnackBar(switch (reason) {
        PlayLinkFailureReason.serverUnavailable => t.deepLinks.serverUnavailable,
        PlayLinkFailureReason.notFound => t.deepLinks.notFound,
        PlayLinkFailureReason.unsupportedItem => t.deepLinks.unsupportedItem,
      });
    case PlayLinkItem(:final item, :final offline):
      // Completes when the player closes. An open player is replaced.
      unawaited(navigateToVideoPlayer(context, metadata: item, isOffline: offline));
    case PlayLinkShuffle(:final item):
      // Reports its own failures.
      unawaited(MediaListPlaybackLauncher.forItem(context, item).launchShuffledShow(metadata: item));
  }
}

/// What a [PlayLink] resolved to.
sealed class PlayLinkResolution {
  const PlayLinkResolution();
}

/// Play [item]; [offline] plays its download because its server is away.
final class PlayLinkItem extends PlayLinkResolution {
  const PlayLinkItem(this.item, {this.offline = false});

  final MediaItem item;
  final bool offline;
}

/// Play the show or season [item] as a shuffled queue.
final class PlayLinkShuffle extends PlayLinkResolution {
  const PlayLinkShuffle(this.item);

  final MediaItem item;
}

enum PlayLinkFailureReason {
  /// The server the link needs is not reachable, or a server that may hold
  /// the title failed to answer.
  serverUnavailable,

  /// No reachable server has the title.
  notFound,

  /// The link names something Plezy cannot play from a link (music, photos,
  /// collections).
  unsupportedItem,
}

final class PlayLinkFailure extends PlayLinkResolution {
  const PlayLinkFailure(this.reason);

  final PlayLinkFailureReason reason;
}

/// What resolving a [PlayLink] reads from the session.
class PlayLinkSources {
  const PlayLinkSources({
    required this.clientFor,
    required this.isServerOnline,
    required this.hasOnlineServers,
    required this.serversChanged,
    required this.findCatalogCopies,
    required this.downloadedItem,
    this.resolvePlexHash,
  });

  final MediaServerClient? Function(ServerId serverId) clientFor;
  final bool Function(ServerId serverId) isServerOnline;
  final bool Function() hasOnlineServers;

  /// Notifies when servers connect or drop.
  final Listenable serversChanged;

  /// Every copy of the target on the profile's servers, best first.
  final Future<LibraryLookupResult> Function(CatalogPlayTarget target) findCatalogCopies;

  /// The downloaded item, when [itemId] on [serverId] is downloaded.
  final MediaItem? Function(ServerId serverId, String itemId) downloadedItem;

  /// The Plex GUID hash Plex Discover has for a target's catalogue ids, or
  /// null when it has none. Plex cannot look up a library on its current
  /// agent by catalogue id, so a link without `plex=` finds the title on
  /// Plex through this. Absent when no Plex account is signed in.
  final Future<String?> Function(CatalogPlayTarget target)? resolvePlexHash;
}

typedef _Copy = ({MediaServerClient client, MediaItem item});

/// Turns a [PlayLink] into what to play, on whichever backend has it.
class PlayLinkResolver {
  PlayLinkResolver(this.sources, {this.serverWait = deepLinkServerWait});

  final PlayLinkSources sources;
  final Duration serverWait;

  Future<PlayLinkResolution> resolve(PlayLink link) => switch (link.target) {
    final ItemPlayTarget target => _resolveItem(target, link.mode),
    final CatalogPlayTarget target => _resolveCatalog(target, link.mode),
  };

  Future<PlayLinkResolution> _resolveItem(ItemPlayTarget target, PlayMode mode) async {
    final downloaded = sources.downloadedItem(target.serverId, target.itemId);
    final download = downloaded != null && downloaded.kind.isVideo ? downloaded : null;
    bool usable() => sources.isServerOnline(target.serverId) && sources.clientFor(target.serverId) != null;
    // A download plays at once instead of after waiting out an absent server.
    if (download != null && !usable()) return PlayLinkItem(download, offline: true);

    if (!await waitForServers(sources.serversChanged, usable, timeout: serverWait)) {
      return const PlayLinkFailure(PlayLinkFailureReason.serverUnavailable);
    }
    final client = sources.clientFor(target.serverId)!;
    final MediaItem? item;
    try {
      item = await client.fetchItem(target.itemId);
    } catch (e, stackTrace) {
      appLogger.w(
        'Play link: fetching ${target.itemId} on ${target.serverId} failed',
        error: e,
        stackTrace: stackTrace,
      );
      if (download != null) return PlayLinkItem(download, offline: true);
      return const PlayLinkFailure(PlayLinkFailureReason.serverUnavailable);
    }
    if (item == null) return const PlayLinkFailure(PlayLinkFailureReason.notFound);
    return _forItem(client, _onServer(item, target.serverId), mode);
  }

  Future<PlayLinkResolution> _resolveCatalog(CatalogPlayTarget target, PlayMode mode) async {
    // Discover answers while the servers connect.
    final withPlexHash = _withPlexHash(target);
    if (!await waitForServers(sources.serversChanged, sources.hasOnlineServers, timeout: serverWait)) {
      return const PlayLinkFailure(PlayLinkFailureReason.serverUnavailable);
    }
    final LibraryLookupResult lookup;
    try {
      lookup = await sources.findCatalogCopies(await withPlexHash);
    } catch (e, stackTrace) {
      appLogger.w('Play link: catalogue lookup failed', error: e, stackTrace: stackTrace);
      return const PlayLinkFailure(PlayLinkFailureReason.serverUnavailable);
    }
    final copies = <_Copy>[];
    for (final item in lookup.items) {
      if (item.kind != target.kind) continue;
      final serverId = serverIdOrNull(item.serverId);
      final client = serverId == null ? null : sources.clientFor(serverId);
      if (client != null) copies.add((client: client, item: item));
    }
    if (copies.isEmpty) {
      // A server that failed to answer or is offline may hold the title; one
      // that cannot run this query (a Plex GUID on Jellyfin) does not.
      final unanswered =
          lookup.failedServerIds.isNotEmpty ||
          lookup.cancelledServerIds.isNotEmpty ||
          lookup.unqueriedServerIds.any((id) => !sources.isServerOnline(ServerId(id)));
      return PlayLinkFailure(unanswered ? PlayLinkFailureReason.serverUnavailable : PlayLinkFailureReason.notFound);
    }

    if (target.kind == MediaKind.movie) {
      // Progress is per copy (a 4K and an HD library, two servers): resume
      // the copy watched last. The full item carries current watch state.
      final fresh = await Future.wait([for (final copy in copies) _refreshed(copy)]);
      return PlayLinkItem(_watchedLast(fresh, (item) => item));
    }

    if (mode == PlayMode.shuffle) return PlayLinkShuffle(copies.first.item);

    // Next: the copy being watched, and of several the one watched last.
    final onDeck = await Future.wait([for (final copy in copies) _onDeck(copy)]);
    final watching = onDeck.where((r) => r.episode != null).toList();
    if (watching.isNotEmpty) {
      final latest = _watchedLast(watching, (r) => r.show);
      return PlayLinkItem(_onServer(latest.episode!, _serverOf(latest.copy)));
    }
    final first = copies.first;
    return _firstEpisode(first.client, first.item);
  }

  /// [target] with the Plex GUID hash Discover has for its catalogue ids, or
  /// [target] itself when it has one already or Discover cannot say.
  Future<CatalogPlayTarget> _withPlexHash(CatalogPlayTarget target) async {
    final resolve = sources.resolvePlexHash;
    if (target.plexHash != null || !target.ids.hasCatalogIds || resolve == null) return target;
    try {
      final hash = await resolve(target);
      if (hash == null || hash.isEmpty) return target;
      return CatalogPlayTarget(kind: target.kind, ids: target.ids, plexHash: hash);
    } catch (e, stackTrace) {
      // Best effort: the catalogue ids still find the title elsewhere.
      appLogger.w('Play link: Plex Discover lookup failed', error: e, stackTrace: stackTrace);
      return target;
    }
  }

  Future<MediaItem> _refreshed(_Copy copy) async {
    try {
      final item = await copy.client.fetchItem(copy.item.id);
      return item == null ? copy.item : _onServer(item, _serverOf(copy));
    } catch (e, stackTrace) {
      appLogger.w('Play link: refreshing ${copy.item.globalKey} failed', error: e, stackTrace: stackTrace);
      return copy.item;
    }
  }

  Future<({_Copy copy, MediaItem show, MediaItem? episode})> _onDeck(_Copy copy) async {
    try {
      final result = await copy.client.fetchItemWithOnDeck(copy.item.id);
      return (copy: copy, show: result.item ?? copy.item, episode: result.onDeckEpisode);
    } catch (e, stackTrace) {
      appLogger.w('Play link: On Deck lookup for ${copy.item.globalKey} failed', error: e, stackTrace: stackTrace);
      return (copy: copy, show: copy.item, episode: null);
    }
  }

  Future<PlayLinkResolution> _forItem(MediaServerClient client, MediaItem item, PlayMode mode) async {
    switch (item.kind) {
      case MediaKind.movie || MediaKind.episode || MediaKind.clip:
        return PlayLinkItem(item);
      case MediaKind.show || MediaKind.season:
        if (mode == PlayMode.shuffle) return PlayLinkShuffle(item);
        if (item.kind == MediaKind.show) {
          final onDeck = (await _onDeck((client: client, item: item))).episode;
          if (onDeck != null) return PlayLinkItem(_onServer(onDeck, ServerId(item.serverId!)));
        }
        return _firstEpisode(client, item, preferUnwatched: item.kind == MediaKind.season);
      default:
        return const PlayLinkFailure(PlayLinkFailureReason.unsupportedItem);
    }
  }

  /// The first episode of [container] (specials last), or with
  /// [preferUnwatched] the first one not yet watched.
  Future<PlayLinkResolution> _firstEpisode(
    MediaServerClient client,
    MediaItem container, {
    bool preferUnwatched = false,
  }) async {
    final List<MediaItem> episodes;
    try {
      episodes = await client.fetchPlayableDescendants(container.id);
    } catch (e, stackTrace) {
      appLogger.w('Play link: episodes of ${container.globalKey} failed', error: e, stackTrace: stackTrace);
      return const PlayLinkFailure(PlayLinkFailureReason.serverUnavailable);
    }
    final ordered = episodes.where((e) => e.kind == MediaKind.episode).toList()..sort(compareEpisodesSpecialsLast);
    final episode = (preferUnwatched ? firstUnwatchedEpisode(ordered) : null) ?? ordered.firstOrNull;
    if (episode == null) return const PlayLinkFailure(PlayLinkFailureReason.notFound);
    return PlayLinkItem(_onServer(episode, ServerId(container.serverId!)));
  }
}

/// Waits up to [timeout] for [ready], re-checking whenever [changes]
/// notifies. Returns whether it became true.
Future<bool> waitForServers(Listenable changes, bool Function() ready, {required Duration timeout}) async {
  if (ready()) return true;
  if (timeout <= Duration.zero) return false;
  final done = Completer<bool>();
  void check() {
    if (!done.isCompleted && ready()) done.complete(true);
  }

  changes.addListener(check);
  final timer = Timer(timeout, () {
    if (!done.isCompleted) done.complete(ready());
  });
  try {
    return await done.future;
  } finally {
    timer.cancel();
    changes.removeListener(check);
  }
}

ServerId _serverOf(_Copy copy) => ServerId(copy.item.serverId!);

/// [item] with its server stamped on, for rows a backend returns without one.
MediaItem _onServer(MediaItem item, ServerId serverId) =>
    item.serverId == null ? item.copyWith(serverId: serverId) : item;

/// The entry whose item was watched last; the first on a tie, so with
/// nothing watched the first (best) copy.
T _watchedLast<T>(List<T> entries, MediaItem Function(T entry) item) =>
    entries.reduce((a, b) => (item(b).lastViewedAt ?? 0) > (item(a).lastViewedAt ?? 0) ? b : a);

Future<void> _launchLiveLink(BuildContext context, LiveLink link, {required bool isOffline}) async {
  final multiServer = context.read<MultiServerProvider>();
  List<LiveTvServerInfo> sources() => multiServer.liveTvServers
      .where((source) => link.serverId == null || source.serverId == link.serverId)
      .toList(growable: false);

  var found = sources();
  if (found.isEmpty && !isOffline) {
    // Live TV servers are known once their server has connected and been
    // probed; right after a cold start or a wake-up that may still be going.
    final serverId = link.serverId;
    await waitForServers(
      multiServer,
      () => serverId == null ? multiServer.hasConnectedServers : multiServer.isServerOnline(serverId),
      timeout: deepLinkServerWait,
    );
    if (!context.mounted) return;
    await multiServer.checkLiveTvAvailability();
    found = sources();
  }
  if (!context.mounted) return;
  if (found.isEmpty) {
    appLogger.w('Live link: no Live TV server${link.serverId == null ? '' : ' ${link.serverId}'}');
    showMainSnackBar(t.deepLinks.noLiveTv);
    return;
  }

  final channels = <LiveTvChannel>[];
  for (final source in found) {
    final client = multiServer.getClientForServer(ServerId(source.serverId));
    if (client == null) continue;
    try {
      final rows = await client.liveTv.fetchChannels(lineup: source.lineup);
      channels.addAll(rows.map((c) => c.copyWith(serverId: source.serverId, liveDvrKey: source.dvrKey)));
    } catch (e, stackTrace) {
      appLogger.w('Live link: fetching channels from ${source.serverId} failed', error: e, stackTrace: stackTrace);
    }
  }
  if (!context.mounted) return;

  final match = link.selectChannel(channels);
  if (match == null) {
    appLogger.w('Live link: channel "${link.channel}" not found');
    showMainSnackBar(t.deepLinks.channelNotFound(channel: link.channel));
    return;
  }
  unawaited(
    navigateToLiveTv(
      context,
      multiServer: multiServer,
      channel: match,
      channels: channels,
      startPosition: link.startPosition,
    ),
  );
}
