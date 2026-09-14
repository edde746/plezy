import '../../media/ids.dart';
import '../../media/media_server_client.dart';
import '../../providers/multi_server_provider.dart';

/// Runs [body] once per Live TV server of [multiServer], isolating per-server failures.
///
/// Owns the iteration shape shared by the Live TV screens: resolve a client per entry via
/// [resolveClient] (What's On passes the Plex-specific resolver, everything else the generic
/// one), skip entries without a client, dedupe by `serverId`, and route a thrown [body] error
/// to [onError] before moving on to the next server.
///
/// - [dedupeByServerId] is on for server-scoped fetches. `liveTvServers` carries one entry per
///   DVR, so per-DVR sites (channel/favorites loading in LiveTvScreen) pass `false` to visit
///   every entry.
/// - [isCurrent] is re-checked between servers so a caller whose load generation went stale
///   inside [body] stops without touching the remaining servers.
/// - Omitting [onError] lets a [body] error abort the iteration and propagate to the caller.
Future<void> forEachLiveTvServer<C extends MediaServerClient>(
  MultiServerProvider multiServer, {
  required C? Function(ServerId serverId) resolveClient,
  required Future<void> Function(C client, LiveTvServerInfo serverInfo) body,
  void Function(C client, LiveTvServerInfo serverInfo, Object error, StackTrace stackTrace)? onError,
  bool dedupeByServerId = true,
  bool Function()? isCurrent,
}) async {
  final seenServers = <String>{};
  for (final serverInfo in multiServer.liveTvServers) {
    if (isCurrent?.call() == false) return;
    if (dedupeByServerId && !seenServers.add(serverInfo.serverId)) continue;
    final client = resolveClient(ServerId(serverInfo.serverId));
    if (client == null) continue;
    try {
      await body(client, serverInfo);
    } catch (error, stackTrace) {
      if (onError == null) rethrow;
      onError(client, serverInfo, error, stackTrace);
    }
  }
}
