import 'package:flutter/widgets.dart';

import '../i18n/strings.g.dart';
import '../media/ids.dart';
import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../providers/multi_server_provider.dart';
import '../services/media_list_playback_launcher.dart';
import 'app_logger.dart';
import 'external_ids.dart';
import 'snackbar_helper.dart';
import 'video_player_navigation.dart';

/// How a Watch link that names a show picks what to play.
enum WatchMode { next, shuffle }

/// A `plezy://watch` deep link that names one show or movie and plays it.
///
/// Formats:
/// * Portable: `plezy://watch?plex=<show|movie>/<hash>[&mode=next|shuffle]`,
///   the item's Plex GUID without its `plex://` prefix. Resolves on every
///   Plex server that has the title.
/// * Server: `plezy://watch?id=<ratingKey>[&server=<machineIdentifier>][&mode=...]`.
///   Rating keys are per-server, so without `server` the key must match on
///   exactly one server.
///
/// For shows, `next` (the default) plays the On Deck episode, or the first
/// episode when nothing is On Deck; `shuffle` plays every episode in random
/// order. Movies ignore the mode.
///
/// Intended for automation (e.g. Home Assistant launching the URL when an
/// RFID tag is scanned). Plex servers only for now.
sealed class WatchLink {
  const WatchLink({this.mode = WatchMode.next});

  static const scheme = 'plezy';
  static const host = 'watch';

  final WatchMode mode;

  /// Parses [link], returning null when it is not a well-formed Watch link.
  static WatchLink? tryParse(String link) {
    final uri = Uri.tryParse(link);
    if (uri == null || uri.scheme != scheme || uri.host != host) return null;
    final params = uri.queryParameters;
    final mode = switch (params['mode']?.trim().toLowerCase()) {
      null || '' || 'next' => WatchMode.next,
      'shuffle' => WatchMode.shuffle,
      _ => null,
    };
    if (mode == null) return null;

    final plex = params['plex']?.trim();
    final id = params['id']?.trim();
    final hasPlex = plex != null && plex.isNotEmpty;
    final hasId = id != null && id.isNotEmpty;
    if (hasPlex == hasId) return null;

    if (hasPlex) {
      final slash = plex.indexOf('/');
      if (slash <= 0 || slash == plex.length - 1) return null;
      final kind = switch (plex.substring(0, slash).toLowerCase()) {
        'show' => MediaKind.show,
        'movie' => MediaKind.movie,
        _ => null,
      };
      if (kind == null) return null;
      return PortableWatchLink(kind: kind, hash: plex.substring(slash + 1), mode: mode);
    }
    final server = params['server']?.trim();
    return ServerWatchLink(
      ratingKey: id!,
      serverId: server == null || server.isEmpty ? null : ServerId(server),
      mode: mode,
    );
  }

  /// The portable link for [item] when it has a Plex GUID, otherwise the
  /// server link. Null for anything other than a Plex show or movie.
  static WatchLink? forItem(MediaItem item) {
    if (item.backend != MediaBackend.plex) return null;
    if (item.kind != MediaKind.show && item.kind != MediaKind.movie) return null;
    final guid = item.guid;
    final prefix = _plexGuidPrefix(item.kind);
    if (guid != null && guid.startsWith(prefix) && guid.length > prefix.length) {
      return PortableWatchLink(kind: item.kind, hash: guid.substring(prefix.length));
    }
    final serverId = serverIdOrNull(item.serverId);
    return ServerWatchLink(ratingKey: item.id, serverId: serverId);
  }

  /// `plex://show/` or `plex://movie/`: a Plex GUID minus its hash.
  static String _plexGuidPrefix(MediaKind kind) => 'plex://${kind.name}/';

  Map<String, String> get _identityParams;

  /// The link as a URL string.
  String toLink() => Uri(
    scheme: scheme,
    host: host,
    queryParameters: {..._identityParams, if (mode != WatchMode.next) 'mode': mode.name},
  ).toString();

  /// Resolves the link against the connected [servers], given in the user's
  /// server order.
  Future<WatchLinkResolution> resolve(List<WatchLinkServer> servers);

  /// How many times [resolveWhenConnected] waits for servers to connect
  /// before giving up.
  static const coldStartAttempts = 10;
  static const coldStartRetryDelay = Duration(seconds: 2);

  /// Resolves the link, and on a cold start keeps trying for a while: with
  /// no server online yet, or with a failure while some servers are still
  /// connecting (the one that has the title may be among them). [servers]
  /// is asked afresh before each attempt. Stops early once [isCurrent]
  /// turns false.
  Future<WatchLinkResolution> resolveWhenConnected(
    WatchLinkServers Function() servers, {
    Duration retryDelay = coldStartRetryDelay,
    bool Function()? isCurrent,
  }) async {
    var snapshot = servers();
    var resolution = await resolve(snapshot.online);
    for (var attempt = 0; attempt < coldStartAttempts && _worthWaiting(resolution, snapshot.connecting); attempt++) {
      await Future<void>.delayed(retryDelay);
      if (isCurrent != null && !isCurrent()) break;
      snapshot = servers();
      resolution = await resolve(snapshot.online);
    }
    return resolution;
  }

  static bool _worthWaiting(WatchLinkResolution resolution, bool connecting) => switch (resolution) {
    WatchLinkFailure(reason: WatchLinkFailureReason.noServer) => true,
    WatchLinkFailure(
      reason: WatchLinkFailureReason.notFound ||
          WatchLinkFailureReason.unreachable ||
          WatchLinkFailureReason.unsupportedBackend,
    ) =>
      connecting,
    _ => false,
  };

  /// Resolves the link on the connected servers and starts playback,
  /// replacing any player already open. Returns whether playback was
  /// launched; failures are reported to the user.
  Future<bool> launch(BuildContext context, MultiServerProvider multiServer) async {
    WatchLinkServers servers() {
      final online = multiServer.onlineServerIds.toSet();
      final failed = {
        ...multiServer.authErrorServerIds,
        ...multiServer.accessDeniedServerIds,
        ...multiServer.refusedServerIds,
      };
      return (
        online: [
          for (final id in online)
            if (multiServer.getClientForServer(ServerId(id)) case final client?) (id: ServerId(id), client: client),
        ],
        connecting: multiServer.serverIds.any((id) => !online.contains(id) && !failed.contains(id)),
      );
    }

    final resolution = await resolveWhenConnected(servers, isCurrent: () => context.mounted);
    if (!context.mounted) return false;

    switch (resolution) {
      case WatchLinkFailure(:final reason):
        appLogger.w('Watch link ${toLink()} failed: ${reason.name}');
        showMainSnackBar(switch (reason) {
          WatchLinkFailureReason.noServer || WatchLinkFailureReason.unreachable => t.watchLink.serverUnavailable,
          WatchLinkFailureReason.notFound => t.watchLink.notFound,
          WatchLinkFailureReason.ambiguous => t.watchLink.ambiguous,
          WatchLinkFailureReason.unsupportedBackend => t.watchLink.plexOnly,
          WatchLinkFailureReason.unsupportedItem => t.watchLink.unsupportedItem,
        });
        return false;
      case WatchTarget(:final item, :final episode, :final shuffle):
        // A scan replaces whatever is playing: the player route swaps out an
        // open player itself.
        if (shuffle) {
          final result = await MediaListPlaybackLauncher.forItem(context, item).launchShuffledShow(metadata: item);
          return result is! PlayQueueError;
        }
        await navigateToVideoPlayer(context, metadata: episode ?? item);
        return true;
    }
  }
}

/// A Watch link naming its title by Plex GUID.
final class PortableWatchLink extends WatchLink {
  const PortableWatchLink({required this.kind, required this.hash, super.mode});

  /// [MediaKind.show] or [MediaKind.movie].
  final MediaKind kind;

  /// The GUID after `plex://show/` or `plex://movie/`.
  final String hash;

  String get plexGuid => '${WatchLink._plexGuidPrefix(kind)}$hash';

  @override
  Map<String, String> get _identityParams => {'plex': '${kind.name}/$hash'};

  @override
  Future<WatchLinkResolution> resolve(List<WatchLinkServer> servers) async {
    final plexServers = _plexOnly(servers);
    if (plexServers.isEmpty) return _noPlexServer(servers);

    var unreachable = false;
    final lookups = await Future.wait([
      for (final server in plexServers)
        server.client
            .findByExternalIds(const ExternalIds(), kind: kind, plexGuid: plexGuid)
            .then((items) => items ?? const <MediaItem>[])
            .catchError((Object e) {
              appLogger.w('Watch link: Plex GUID lookup failed on ${server.id}', error: e);
              unreachable = true;
              return const <MediaItem>[];
            }),
    ]);
    // Every copy: a server often has the same title in several libraries
    // (e.g. 4K and 1080p), each with its own watch progress.
    final copies = [
      for (var i = 0; i < plexServers.length; i++)
        for (final item in lookups[i]) (server: plexServers[i], item: item),
    ];
    if (copies.isEmpty) return _notFound(unreachable: unreachable);
    if (kind == MediaKind.movie) {
      // Progress is per copy, so play the copy watched most recently on any
      // server; with none watched, the first in server order. The full item
      // is fetched for its watch state, as a server link and the Play
      // button do.
      final full = await Future.wait([
        for (final copy in copies)
          copy.server.client
              .fetchItem(copy.item.id)
              .then((item) => (server: copy.server, item: item ?? copy.item))
              .catchError((Object e) {
                appLogger.w('Watch link: item fetch failed on ${copy.server.id}', error: e);
                return copy;
              }),
      ]);
      final latest = _watchedLast(full, (copy) => copy.item);
      return _targetFor([latest], mode);
    }
    return _targetFor(copies, mode);
  }
}

/// A Watch link naming its title by rating key on one server.
final class ServerWatchLink extends WatchLink {
  const ServerWatchLink({required this.ratingKey, this.serverId, super.mode});

  final String ratingKey;

  /// The server's machine identifier. When null, every Plex server is asked.
  final ServerId? serverId;

  @override
  Map<String, String> get _identityParams => {'id': ratingKey, 'server': ?serverId?.value};

  @override
  Future<WatchLinkResolution> resolve(List<WatchLinkServer> servers) async {
    final candidates = [
      for (final s in servers)
        if (serverId == null || s.id == serverId) s,
    ];
    final plexServers = _plexOnly(candidates);
    if (plexServers.isEmpty) return _noPlexServer(candidates);

    var unreachable = false;
    final items = await Future.wait([
      for (final server in plexServers)
        server.client.fetchItem(ratingKey).catchError((Object e) {
          appLogger.w('Watch link: item lookup failed on ${server.id}', error: e);
          unreachable = true;
          return null;
        }),
    ]);
    final copies = [
      for (var i = 0; i < plexServers.length; i++)
        if (items[i] case final item?) (server: plexServers[i], item: item),
    ];
    if (copies.isEmpty) return _notFound(unreachable: unreachable);
    // Rating keys are per-server database numbers: the same key on two
    // servers is almost certainly two unrelated items.
    if (copies.length > 1) return const WatchLinkFailure(WatchLinkFailureReason.ambiguous);
    return _targetFor(copies, mode);
  }
}

/// One connected server as seen by Watch link resolution.
typedef WatchLinkServer = ({ServerId id, MediaServerClient client});

/// The servers online now, and whether any others may still connect.
typedef WatchLinkServers = ({List<WatchLinkServer> online, bool connecting});

typedef _Copy = ({WatchLinkServer server, MediaItem item});

/// What a Watch link resolved to.
sealed class WatchLinkResolution {
  const WatchLinkResolution();
}

/// Play [episode] when set, otherwise [item]; or shuffle the show [item].
final class WatchTarget extends WatchLinkResolution {
  const WatchTarget({required this.serverId, required this.item, this.episode, this.shuffle = false});

  final ServerId serverId;

  /// The show or movie the link named, as found on [serverId].
  final MediaItem item;

  /// For Next on a show, the episode to play.
  final MediaItem? episode;

  /// Whether to play the show [item] as a shuffled queue.
  final bool shuffle;
}

enum WatchLinkFailureReason {
  /// No server the link could use is connected.
  noServer,

  /// No connected server has the title.
  notFound,

  /// A server that might have the title failed to answer.
  unreachable,

  /// A server link without `server` matched on more than one server.
  ambiguous,

  /// Only non-Plex servers could be asked.
  unsupportedBackend,

  /// The rating key names something other than a show or movie.
  unsupportedItem,
}

final class WatchLinkFailure extends WatchLinkResolution {
  const WatchLinkFailure(this.reason);

  final WatchLinkFailureReason reason;
}

/// No copy was found: unreachable when some server failed to answer, since
/// it may have had the title.
WatchLinkFailure _notFound({required bool unreachable}) =>
    WatchLinkFailure(unreachable ? WatchLinkFailureReason.unreachable : WatchLinkFailureReason.notFound);

List<WatchLinkServer> _plexOnly(List<WatchLinkServer> servers) => [
  for (final s in servers)
    if (s.client.backend == MediaBackend.plex) s,
];

/// The entry whose item was watched most recently; the first on a tie, so
/// with nothing watched, the first in server order.
T _watchedLast<T>(List<T> entries, MediaItem Function(T) item) =>
    entries.reduce((a, b) => (item(b).lastViewedAt ?? 0) > (item(a).lastViewedAt ?? 0) ? b : a);

WatchLinkFailure _noPlexServer(List<WatchLinkServer> servers) =>
    WatchLinkFailure(servers.isEmpty ? WatchLinkFailureReason.noServer : WatchLinkFailureReason.unsupportedBackend);

/// Picks the copy and, for Next on a show, the episode. [copies] are in the
/// user's server order.
Future<WatchLinkResolution> _targetFor(List<_Copy> copies, WatchMode mode) async {
  final first = copies.first;
  switch (first.item.kind) {
    case MediaKind.movie:
      return WatchTarget(serverId: first.server.id, item: first.item);
    case MediaKind.show:
      break;
    default:
      return const WatchLinkFailure(WatchLinkFailureReason.unsupportedItem);
  }
  if (mode == WatchMode.shuffle) {
    return WatchTarget(serverId: first.server.id, item: first.item, shuffle: true);
  }

  // Next: progress is per server, so prefer the copy being watched, and of
  // several the one watched most recently.
  final withOnDeck = await Future.wait([
    for (final copy in copies)
      copy.server.client
          .fetchItemWithOnDeck(copy.item.id)
          .then((r) => (copy: copy, show: r.item ?? copy.item, onDeck: r.onDeckEpisode))
          .catchError((Object e) {
            appLogger.w('Watch link: On Deck lookup failed on ${copy.server.id}', error: e);
            return (copy: copy, show: copy.item, onDeck: null);
          }),
  ]);
  final watched = withOnDeck.where((r) => r.onDeck != null).toList();
  if (watched.isNotEmpty) {
    final latest = _watchedLast(watched, (r) => r.show);
    return WatchTarget(serverId: latest.copy.server.id, item: latest.show, episode: latest.onDeck);
  }

  // Unstarted or fully watched: start from the first episode.
  final MediaItem? firstEpisode;
  try {
    firstEpisode = firstEpisodeOf(await first.server.client.fetchPlayableDescendants(first.item.id));
  } catch (e) {
    appLogger.w('Watch link: episode lookup failed on ${first.server.id}', error: e);
    return const WatchLinkFailure(WatchLinkFailureReason.unreachable);
  }
  if (firstEpisode == null) return const WatchLinkFailure(WatchLinkFailureReason.notFound);
  return WatchTarget(serverId: first.server.id, item: withOnDeck.first.show, episode: firstEpisode);
}

/// The first episode of the lowest-numbered regular season, falling back to
/// specials when the show has nothing else.
@visibleForTesting
MediaItem? firstEpisodeOf(List<MediaItem> episodes) {
  int season(MediaItem e) => e.parentIndex ?? 0;
  int rank(MediaItem e) => season(e) == 0 ? 1 << 30 : season(e);
  MediaItem? best;
  for (final e in episodes.where((e) => e.kind == MediaKind.episode)) {
    if (best == null || rank(e) < rank(best) || (rank(e) == rank(best) && (e.index ?? 0) < (best.index ?? 0))) {
      best = e;
    }
  }
  return best;
}
