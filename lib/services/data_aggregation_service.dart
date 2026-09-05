import 'dart:async';
import '../media/ids.dart';

import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../media/media_item_merge.dart';
import '../media/media_kind.dart';
import '../media/media_library.dart';
import '../media/media_server_client.dart';
import '../exceptions/media_server_exceptions.dart';
import '../utils/app_logger.dart';
import '../utils/external_ids.dart';
import '../utils/global_key_utils.dart';
import '../utils/search_relevance.dart';
import '../utils/media_server_http_client.dart';
import 'local_playback_history.dart';
import 'multi_server_manager.dart';

/// A row a successful response actually returned, paired with the immutable
/// cache scope of the client that fetched it.
///
/// The scope cannot be recovered later: flattening and dedup lose which
/// client produced a row, and a user-scoped backend's public server id is
/// shared between users — so reconciling by public key could suppress a
/// different user's watch state.
typedef ObservedRow = ({MediaItem item, String? clientScope});

/// [observedItems] are the rows the successful responses actually returned,
/// *before* dedup or limiting. Continue Watching dedup can drop one server's
/// copy in favour of another's, and a dropped copy would otherwise leave that
/// key unreconciled even though its server did return it (#1829).
typedef OnDeckAggregationResult = ({
  List<MediaItem> items,
  List<ObservedRow> observedItems,
  Set<String> succeededServerIds,
  Set<String> cancelledServerIds,
  Set<String> failedServerIds,
});
typedef HubAggregationResult = ({
  List<MediaHub> hubs,
  List<ObservedRow> observedItems,
  Set<String> succeededServerIds,
  Set<String> cancelledServerIds,
  Set<String> failedServerIds,
});
typedef LibraryAggregationResult = ({
  List<MediaLibrary> libraries,
  Set<String> succeededServerIds,
  Set<String> cancelledServerIds,
  Set<String> failedServerIds,
});

/// `items` is the ranked list trimmed to the caller's limit; `candidates` is
/// the full post-hidden-filter, pre-rank pool behind it, so a caller can
/// re-rank a subset (e.g. one media kind) without a kind ranked out of
/// `items` disappearing from its own filter.
typedef SearchAggregationResult = ({
  List<MediaItem> items,
  List<MediaItem> candidates,
  Set<String> succeededServerIds,
  Set<String> cancelledServerIds,
  Set<String> failedServerIds,
});

/// One reverse-lookup wave over every online server. `items` are the
/// id-verified copies, deduped and ordered best-first; a server in
/// `failedServerIds` or `cancelledServerIds` contributed nothing and says
/// nothing about what it holds.
typedef LibraryLookupResult = ({
  List<MediaItem> items,
  Set<String> succeededServerIds,
  Set<String> cancelledServerIds,
  Set<String> failedServerIds,
});
typedef _FanOutResult<T> = ({
  List<T> items,
  Set<String> succeededServerIds,
  Set<String> cancelledServerIds,
  Set<String> failedServerIds,
});

/// Whether [error] is a client-side abort (client teardown mid-request)
/// rather than a genuine server failure. Aggregation reports these servers
/// in `cancelledServerIds` so callers can tell a *disrupted* pass — whose
/// results say nothing about actual content — from a settled failure.
bool _isCancellation(Object error) => error is MediaServerHttpException && error.isCancellation;

Map<String, int> _searchKindCounts(Iterable<MediaItem> items) {
  final counts = <String, int>{};
  for (final item in items) {
    counts.update(item.kind.name, (count) => count + 1, ifAbsent: () => 1);
  }
  return counts;
}

/// Drop items belonging to a hidden library.
///
/// Items the backend could not attribute to a library ([MediaItem.libraryGlobalKey]
/// is null) are kept: Plex search and `/library/shared/all` return shared and
/// external rows that have no local section, and those are not something the
/// user hid.
List<MediaItem> _withoutHiddenLibraries(List<MediaItem> items, Set<String>? hiddenLibraryKeys) {
  if (hiddenLibraryKeys == null || hiddenLibraryKeys.isEmpty) return items;
  return items.where((item) {
    final libraryKey = item.libraryGlobalKey;
    return libraryKey == null || !hiddenLibraryKeys.contains(libraryKey);
  }).toList();
}

/// The server-local library ids [serverId] owns within [hiddenLibraryKeys],
/// which hold cross-server `serverId:libraryId` global keys. Backends that
/// cannot attribute a search hit to a library need these to scope the request.
Set<String> _hiddenLibraryIdsOn(String serverId, Set<String>? hiddenLibraryKeys) {
  if (hiddenLibraryKeys == null || hiddenLibraryKeys.isEmpty) return const {};
  final ids = <String>{};
  for (final key in hiddenLibraryKeys) {
    final parsed = parseGlobalKey(key);
    if (parsed != null && parsed.serverId == serverId) ids.add(parsed.ratingKey);
  }
  return ids;
}

/// Cross-server aggregation: fans calls out to every online client and
/// merges the results. Single-server operations now go through the
/// [MediaServerClient] interface directly (resolved via
/// [ProviderExtensions.tryGetMediaClientForServer] etc.), so this service
/// only owns the genuinely multi-server flows: home/discover hubs, on-deck,
/// search, and the global library list.
class DataAggregationService {
  final MultiServerManager _serverManager;

  DataAggregationService(this._serverManager);

  /// Online clients, optionally restricted to [serverIds] — delta refreshes
  /// fan out to newly-online servers only.
  Map<String, MediaServerClient> _clientsFor(Set<String>? serverIds) {
    final clients = _serverManager.onlineClients;
    if (serverIds == null) return clients;
    return {
      for (final entry in clients.entries)
        if (serverIds.contains(entry.key)) entry.key: entry.value,
    };
  }

  /// Run [fetch] against every client in [clients] and concatenate the results
  /// in client order. A per-server failure is swallowed — logged with
  /// [failureMessage] and contributing nothing — so one bad server cannot sink
  /// the pass; that server is simply absent from `succeededServerIds` and lands
  /// in `failedServerIds`. A client-side abort is *not* a failure: it lands in
  /// `cancelledServerIds` and is logged at debug level, so callers can tell a
  /// disrupted pass from a settled one and torn-down requests do not spam the
  /// error log.
  Future<_FanOutResult<T>> _fanOut<T>(
    Map<String, MediaServerClient> clients, {
    required String Function(String serverId) failureMessage,
    required Future<List<T>> Function(String serverId, MediaServerClient client) fetch,
  }) async {
    final cancelledServerIds = <String>{};
    final failedServerIds = <String>{};
    final futures = clients.entries.map((entry) async {
      try {
        return (serverId: entry.key, items: await fetch(entry.key, entry.value));
      } catch (e, stackTrace) {
        if (_isCancellation(e)) {
          cancelledServerIds.add(entry.key);
          appLogger.d('Cancelled (client abort): ${failureMessage(entry.key)}');
        } else {
          failedServerIds.add(entry.key);
          appLogger.e(failureMessage(entry.key), error: e, stackTrace: stackTrace);
        }
        return (serverId: null, items: <T>[]);
      }
    });
    final results = await Future.wait(futures);
    return (
      items: [for (final result in results) ...result.items],
      succeededServerIds: {
        for (final result in results)
          if (result.serverId != null) result.serverId!,
      },
      cancelledServerIds: cancelledServerIds,
      failedServerIds: failedServerIds,
    );
  }

  /// Fetch libraries from all online clients regardless of backend, returning
  /// the merged neutral [MediaLibrary]s alongside the ids of the servers whose
  /// fetch actually succeeded. [serverIds] restricts the fan-out to those
  /// servers.
  ///
  /// A per-server `fetchLibraries()` failure is swallowed (that server simply
  /// contributes no libraries) so one unreachable server doesn't sink the whole
  /// list. [succeededServerIds] lets callers tell a *failed* fetch apart from a
  /// server that genuinely has no libraries — both contribute nothing, so
  /// conflating them would let a transient failure be cached as "loaded" and
  /// never retried. Servers whose fetch was aborted client-side land in
  /// `cancelledServerIds` — a disrupted pass, unlike a settled failure, must
  /// never be committed as authoritative.
  Future<LibraryAggregationResult> getMediaLibrariesFromAllServers({Set<String>? serverIds}) async {
    final clients = _clientsFor(serverIds);
    if (clients.isEmpty) {
      appLogger.w('No online servers available for fetching libraries (neutral)');
      return (
        libraries: const <MediaLibrary>[],
        succeededServerIds: const <String>{},
        cancelledServerIds: const <String>{},
        failedServerIds: const <String>{},
      );
    }
    final fetched = await _fanOut<MediaLibrary>(
      clients,
      failureMessage: (serverId) => 'Failed neutral library fetch from $serverId',
      fetch: (_, client) => client.fetchLibraries(),
    );
    return (
      libraries: fetched.items,
      succeededServerIds: fetched.succeededServerIds,
      cancelledServerIds: fetched.cancelledServerIds,
      failedServerIds: fetched.failedServerIds,
    );
  }

  /// Fetch "On Deck" (Continue Watching) from all servers and merge by recency.
  /// Items are tagged with server info by the underlying client. Returns
  /// neutral [MediaItem]s plus the ids of servers whose fetch succeeded.
  /// [serverIds] restricts the fan-out to those servers.
  Future<OnDeckAggregationResult> getOnDeckFromAllServers({
    int? limit,
    Set<String>? hiddenLibraryKeys,
    Set<String>? serverIds,
  }) async {
    final clients = _clientsFor(serverIds);
    if (clients.isEmpty) {
      return (
        items: const <MediaItem>[],
        observedItems: const <ObservedRow>[],
        succeededServerIds: const <String>{},
        cancelledServerIds: const <String>{},
        failedServerIds: const <String>{},
      );
    }

    final observedRows = <ObservedRow>[];
    final fetched = await _fanOut<MediaItem>(
      clients,
      failureMessage: (serverId) => 'Failed on-deck fetch from $serverId',
      fetch: (_, client) async {
        final rows = await client.fetchContinueWatching(count: limit);
        // Capture the scope here: after the fan-out flattens and dedup runs,
        // there is no way back to the client that produced a row.
        final scope = client.cacheServerId;
        observedRows.addAll([for (final row in rows) (item: row, clientScope: scope)]);
        return rows;
      },
    );
    // Filter out items from hidden libraries
    var filteredOnDeck = _withoutHiddenLibraries(fetched.items, hiddenLibraryKeys);

    // Sort by most recently viewed, falling back to addedAt for unwatched items.
    // Same key as JellyfinClient's continue-watching merge (MediaItem.recencySortKey)
    // so per-server and cross-server ordering can't drift apart.
    filteredOnDeck.sort((a, b) => b.recencySortKey.compareTo(a.recencySortKey));

    filteredOnDeck = await _deduplicateContinueWatching(filteredOnDeck);

    // Apply limit if specified
    final items = limit != null && limit < filteredOnDeck.length ? filteredOnDeck.sublist(0, limit) : filteredOnDeck;

    appLogger.i('Fetched ${items.length} on deck items from all servers');

    return (
      items: items,
      // Pre-dedup, pre-limit: a copy dropped by dedup or trimmed by the limit
      // was still authoritatively returned by its server.
      observedItems: observedRows,
      succeededServerIds: fetched.succeededServerIds,
      cancelledServerIds: fetched.cancelledServerIds,
      failedServerIds: fetched.failedServerIds,
    );
  }

  /// Merge an [existing] Continue Watching list with [fresh] rows from
  /// newly-online servers: same recency ordering and cross-server identity
  /// dedup as [getOnDeckFromAllServers], applied to the union.
  Future<List<MediaItem>> mergeContinueWatching(List<MediaItem> existing, List<MediaItem> fresh, {int? limit}) async {
    final combined = [...existing, ...fresh]..sort((a, b) => b.recencySortKey.compareTo(a.recencySortKey));
    final deduped = await _deduplicateContinueWatching(combined);
    return limit != null && limit < deduped.length ? deduped.sublist(0, limit) : deduped;
  }

  Future<List<MediaItem>> _deduplicateContinueWatching(List<MediaItem> items) async {
    if (items.length < 2) return items;

    final bucketCounts = <String, int>{};
    for (final item in items) {
      final bucket = _continueWatchingTitleBucket(item);
      if (bucket == null) continue;
      bucketCounts[bucket] = (bucketCounts[bucket] ?? 0) + 1;
    }

    final duplicateBuckets = {
      for (final entry in bucketCounts.entries)
        if (entry.value > 1) entry.key,
    };
    if (duplicateBuckets.isEmpty) return items;

    final externalIdLoads = <String, Future<ExternalIds>>{};
    final identityKeysByIndex = <int, Set<String>>{};
    final identityKeyLoads = <Future<void>>[];
    for (var i = 0; i < items.length; i++) {
      if (!duplicateBuckets.contains(_continueWatchingTitleBucket(items[i]))) continue;
      final index = i;
      identityKeyLoads.add(
        _continueWatchingIdentityKeys(items[index], externalIdLoads).then((keys) => identityKeysByIndex[index] = keys),
      );
    }
    await Future.wait(identityKeyLoads);

    // Group duplicates instead of greedily dropping them: the first item to
    // claim an identity key anchors the group and holds its shelf slot;
    // later items sharing a claimed key join as members without claiming
    // their own keys (same transitive semantics as the old drop). Each slot
    // then shows the member the user most recently played on this device —
    // servers sync watch state across guid-linked siblings, so their
    // lastViewedAt ties and can't tell the 4K copy from the 1080p one
    // (#1492). Without local history the anchor (recency order) stands.
    final keyToGroup = <String, int>{};
    final groups = <List<MediaItem>>[];
    final groupSlots = <int, int>{};
    final result = <MediaItem>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (!duplicateBuckets.contains(_continueWatchingTitleBucket(item))) {
        result.add(item);
        continue;
      }

      final identityKeys = identityKeysByIndex[i] ?? const <String>{};
      if (identityKeys.isEmpty) {
        result.add(item);
        continue;
      }

      var joined = false;
      for (final key in identityKeys) {
        final groupIndex = keyToGroup[key];
        if (groupIndex != null) {
          groups[groupIndex].add(item);
          joined = true;
          break;
        }
      }
      if (joined) continue;

      final groupIndex = groups.length;
      groups.add([item]);
      for (final key in identityKeys) {
        keyToGroup[key] = groupIndex;
      }
      groupSlots[result.length] = groupIndex;
      result.add(item);
    }

    if (groupSlots.isEmpty) return result;
    final lastPlayed = await LocalPlaybackHistory.snapshot();
    for (final slot in groupSlots.entries) {
      final members = groups[slot.value];
      if (members.length > 1) {
        result[slot.key] = _preferLocallyLastPlayed(members, lastPlayed);
      }
    }
    return result;
  }

  /// The duplicate-group member most recently played on this device (by item
  /// or series key), or the anchor — `members.first`, the group's most recent
  /// item by [MediaItem.recencySortKey] — when the local history has nothing
  /// newer to say.
  MediaItem _preferLocallyLastPlayed(List<MediaItem> members, Map<String, int> lastPlayed) {
    var winner = members.first;
    var winnerLastPlayedAt = 0;
    for (final member in members) {
      final itemTs = lastPlayed[member.globalKey] ?? 0;
      final seriesKey = member.seriesGlobalKey;
      final seriesTs = seriesKey != null ? (lastPlayed[seriesKey] ?? 0) : 0;
      final lastPlayedAt = itemTs > seriesTs ? itemTs : seriesTs;
      if (lastPlayedAt > winnerLastPlayedAt) {
        winner = member;
        winnerLastPlayedAt = lastPlayedAt;
      }
    }
    return winner;
  }

  String? _continueWatchingTitleBucket(MediaItem item) {
    final scope = _continueWatchingIdentityScope(item);
    if (scope == null) return null;

    final title = switch (item.kind) {
      MediaKind.episode || MediaKind.season => item.grandparentTitle ?? item.parentTitle ?? item.title,
      _ => item.title,
    };
    final normalized = title?.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized == null || normalized.isEmpty) return null;
    return '$scope:$normalized';
  }

  Future<Set<String>> _continueWatchingIdentityKeys(
    MediaItem item,
    Map<String, Future<ExternalIds>> externalIdLoads,
  ) async {
    final scope = _continueWatchingIdentityScope(item);
    if (scope == null) return const {};

    final keys = <String>{};
    final serverId = item.serverId;
    final targetId = _continueWatchingIdentityTargetId(item);
    final client = serverId == null ? null : _serverManager.getClient(ServerId(serverId));

    if (client != null && targetId != null && targetId.isNotEmpty) {
      try {
        final cacheKey = buildGlobalKey(ServerId(serverId!), targetId);
        final externalIds = await externalIdLoads.putIfAbsent(cacheKey, () => client.fetchExternalIds(targetId));
        _addExternalIdentityKeys(keys, scope, externalIds);
      } catch (e, stackTrace) {
        appLogger.d(
          'Failed to resolve Continue Watching identity for ${item.globalKey}',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

    final stableGuid = _stableMediaGuid(item.guid);
    if (stableGuid != null) {
      final guidScope = item.kind == MediaKind.episode ? 'episode' : scope;
      keys.add('$guidScope:guid:$stableGuid');
    }

    return keys;
  }

  String? _continueWatchingIdentityScope(MediaItem item) {
    return switch (item.kind) {
      MediaKind.episode || MediaKind.season || MediaKind.show => 'show',
      MediaKind.movie => 'movie',
      _ => null,
    };
  }

  String? _continueWatchingIdentityTargetId(MediaItem item) {
    return switch (item.kind) {
      MediaKind.episode => item.grandparentId,
      MediaKind.season => item.grandparentId ?? item.parentId,
      MediaKind.show || MediaKind.movie => item.id,
      _ => null,
    };
  }

  void _addExternalIdentityKeys(Set<String> keys, String scope, ExternalIds externalIds) {
    final imdb = externalIds.imdb?.trim().toLowerCase();
    if (imdb != null && imdb.isNotEmpty) keys.add('$scope:imdb:$imdb');
    final tmdb = externalIds.tmdb;
    if (tmdb != null) keys.add('$scope:tmdb:$tmdb');
    final tvdb = externalIds.tvdb;
    if (tvdb != null) keys.add('$scope:tvdb:$tvdb');
    final anidb = externalIds.anidb;
    if (anidb != null) keys.add('$scope:anidb:$anidb');
  }

  String? _stableMediaGuid(String? guid) {
    final value = guid?.trim();
    if (value == null || value.isEmpty) return null;
    if (!value.contains('://')) return null;
    if (value.contains('agents.none://')) return null;
    return value.toLowerCase();
  }

  /// Fetch recommendation hubs from all servers as neutral [MediaHub]s.
  /// When useGlobalHubs is true (default), rich-hub backends use their true
  /// home page hubs (Plex's promoted/global hub endpoint).
  /// Backends without rich home hubs fall back to per-library hubs so one
  /// capped "Latest" response cannot hide whole library types.
  /// [serverIds] restricts the fan-out (including the library prefetch) to
  /// those servers. Returns the ids of servers whose hub fetch succeeded so
  /// callers do not cache transient per-server failures as loaded.
  Future<HubAggregationResult> getHubsFromAllServers({
    int? limit,
    Set<String>? hiddenLibraryKeys,
    bool useGlobalHubs = true,
    bool includePlaybackHubs = true,
    Set<String>? serverIds,
  }) async {
    final clients = _clientsFor(serverIds);
    if (clients.isEmpty) {
      appLogger.w('No online servers available for fetching hubs');
      return (
        hubs: const <MediaHub>[],
        observedItems: const <ObservedRow>[],
        succeededServerIds: const <String>{},
        cancelledServerIds: const <String>{},
        failedServerIds: const <String>{},
      );
    }

    // Home layout needs the library list for every client: fallback backends
    // build all their rows from per-library hubs, and rich-hub backends
    // (Plex) need it to detect visible music libraries, whose hubs the
    // global-hub endpoint excludes. One `fetchLibraries` per server, served
    // from the per-backend API cache when warm.
    final libraryFetch = useGlobalHubs ? await getMediaLibrariesFromAllServers(serverIds: serverIds) : null;
    final libraries = libraryFetch == null ? null : _groupLibrariesByServer(libraryFetch.libraries);
    final legSucceededServerIds = <String>{};
    final legFailedServerIds = <String>{if (libraryFetch != null) ...libraryFetch.failedServerIds};
    final legCancelledServerIds = <String>{if (libraryFetch != null) ...libraryFetch.cancelledServerIds};
    final globalDiagnosticsByServer = <String, HubFetchDiagnostics>{};
    final observedRows = <ObservedRow>[];

    final fetched = await _fanOut<MediaHub>(
      clients,
      failureMessage: (serverId) => 'Failed to fetch hubs from server $serverId',
      fetch: (serverId, client) async {
        final serverLibraries = libraries?[serverId];
        final shouldUseGlobalHubs = useGlobalHubs && client.capabilities.richHubs;
        final prefetchDegraded = legFailedServerIds.contains(serverId) || legCancelledServerIds.contains(serverId);
        final hubItemLimit = limit ?? defaultHubPreviewLimit;
        List<MediaHub> hubs;
        if (shouldUseGlobalHubs) {
          // Both legs are independent, so start them before awaiting either.
          // Spreading `...await a, ...await b` into one list literal evaluates
          // them in order, which serialised the music rows behind the global
          // hub round trip.
          final globalDiagnostics = HubFetchDiagnostics();
          globalDiagnosticsByServer[serverId] = globalDiagnostics;
          final globalFuture = client.fetchGlobalHubs(
            limit: hubItemLimit,
            includePlaybackHubs: includePlaybackHubs,
            diagnostics: globalDiagnostics,
          );
          // Plex's promoted/global hub endpoint never includes music
          // libraries — append their per-library hubs so music rows
          // reach home. A failed prefetch cannot establish that there
          // are no visible music libraries, so it is not a successful no-op.
          final musicFuture = prefetchDegraded
              ? null
              : _fetchLibraryHubsForClient(
                  client,
                  limit: hubItemLimit,
                  hiddenLibraryKeys: hiddenLibraryKeys,
                  includePlaybackHubs: includePlaybackHubs,
                  libraries: serverLibraries ?? const [],
                  kinds: const {MediaKind.artist},
                );
          Object? globalError;
          StackTrace? globalStackTrace;
          List<MediaHub> globalHubs = const [];
          try {
            globalHubs = await globalFuture;
          } catch (error, stackTrace) {
            globalDiagnostics.recordFailure(error);
            globalError = error;
            globalStackTrace = stackTrace;
          }
          final music = musicFuture == null ? null : await musicFuture;
          if (globalHubs.isNotEmpty || (!globalDiagnostics.failed && !globalDiagnostics.cancelled)) {
            legSucceededServerIds.add(serverId);
          }
          if (music != null) {
            // The music append is optional: it must not vouch for the server
            // when the global leg failed or was cancelled (Plex records that
            // in diagnostics and returns [] instead of throwing), or a lone
            // music row would replace every cached movie/TV home row.
            if (music.succeeded && !globalDiagnostics.failed && !globalDiagnostics.cancelled) {
              legSucceededServerIds.add(serverId);
            }
            if (music.failed) legFailedServerIds.add(serverId);
            if (music.cancelled) legCancelledServerIds.add(serverId);
          }
          if (globalError != null) Error.throwWithStackTrace(globalError, globalStackTrace!);
          hubs = [...globalHubs, if (music != null) ...music.hubs];
        } else {
          // A fallback backend cannot run a hub leg without the libraries its
          // prefetch failed to discover.
          if (useGlobalHubs && prefetchDegraded) return const <MediaHub>[];
          final libraryHubs = await _fetchLibraryHubsForClient(
            client,
            limit: hubItemLimit,
            hiddenLibraryKeys: hiddenLibraryKeys,
            includePlaybackHubs: includePlaybackHubs,
            libraries: useGlobalHubs ? serverLibraries : null,
          );
          if (libraryHubs.succeeded || (!libraryHubs.failed && !libraryHubs.cancelled)) {
            legSucceededServerIds.add(serverId);
          }
          if (libraryHubs.failed) legFailedServerIds.add(serverId);
          if (libraryHubs.cancelled) legCancelledServerIds.add(serverId);
          hubs = libraryHubs.hubs;
        }
        final processed = _postProcessHubs(hubs, serverId: ServerId(serverId), hiddenLibraryKeys: hiddenLibraryKeys);
        final scope = client.cacheServerId;
        observedRows.addAll([
          for (final hub in processed)
            for (final item in hub.items) (item: item, clientScope: scope),
        ]);
        return processed;
      },
    );

    for (final entry in globalDiagnosticsByServer.entries) {
      if (entry.value.failed) legFailedServerIds.add(entry.key);
      if (entry.value.cancelled) legCancelledServerIds.add(entry.key);
    }

    final all = fetched.items;
    final hubs = limit != null && limit < all.length ? all.sublist(0, limit) : all;
    return (
      hubs: hubs,
      // Pre-limit, so a row trimmed off the tail still counts as observed.
      observedItems: observedRows,
      succeededServerIds: legSucceededServerIds,
      cancelledServerIds: {...fetched.cancelledServerIds, ...legCancelledServerIds},
      failedServerIds: {...fetched.failedServerIds, ...legFailedServerIds},
    );
  }

  /// Per-library hub fetch for a single client. Filters to visible libraries
  /// of [kinds] (movie/show/clip/artist by default — clip covers Jellyfin
  /// musicvideos/homevideos, #1476; artist brings music rows to home) and
  /// concatenates the results. The rich-hub music append passes
  /// `{MediaKind.artist}` to fetch only what the global endpoint misses.
  ///
  /// `succeeded` stays false when no library leg was attempted. This prevents
  /// the optional rich-hub music append from masking a failed global leg; the
  /// fallback caller separately recognizes a clean zero-library result as an
  /// authoritative no-op.
  Future<({List<MediaHub> hubs, bool succeeded, bool failed, bool cancelled})> _fetchLibraryHubsForClient(
    MediaServerClient client, {
    required int limit,
    Set<String>? hiddenLibraryKeys,
    required bool includePlaybackHubs,
    List<MediaLibrary>? libraries,
    Set<MediaKind> kinds = const {MediaKind.movie, MediaKind.show, MediaKind.clip, MediaKind.artist},
  }) async {
    final libs = libraries ?? await client.fetchLibraries();
    final visible = libs.where((l) {
      if (!kinds.contains(l.kind)) return false;
      if (l.hidden) return false;
      if (hiddenLibraryKeys != null && hiddenLibraryKeys.contains(l.globalKey)) return false;
      return true;
    }).toList();

    // Sliding window rather than batches of three separated by a barrier: a
    // batch waits for its slowest member before the next one starts, so wall
    // time was the sum of per-batch maxima and one slow library stalled every
    // library queued behind it (#1784). Starting the next request the moment
    // any slot frees keeps the same peak concurrency with no head-of-line
    // blocking. Results are written back by index so hub order stays the
    // library order regardless of completion order.
    const concurrency = 3;
    final results = List<List<MediaHub>>.filled(visible.length, const []);
    var next = 0;
    var succeeded = false;
    var failed = false;
    var cancelled = false;

    Future<void> worker() async {
      while (true) {
        final index = next++;
        if (index >= visible.length) return;
        final library = visible[index];
        final diagnostics = HubFetchDiagnostics();
        try {
          final hubs = await client.fetchLibraryHubs(
            library.id,
            libraryName: library.title,
            limit: limit,
            includePlaybackHubs: includePlaybackHubs,
            libraryKind: library.kind,
            diagnostics: diagnostics,
          );
          results[index] = hubs;
          if (hubs.isNotEmpty || (!diagnostics.failed && !diagnostics.cancelled)) succeeded = true;
        } catch (e, st) {
          if (_isCancellation(e)) {
            cancelled = true;
            appLogger.d('Cancelled library hub fetch for ${library.globalKey}');
          } else {
            failed = true;
            appLogger.e('Failed to fetch library hubs for ${library.globalKey}', error: e, stackTrace: st);
          }
        }
        if (diagnostics.failed) failed = true;
        if (diagnostics.cancelled) cancelled = true;
      }
    }

    await Future.wait([for (var i = 0; i < concurrency && i < visible.length; i++) worker()]);

    return (hubs: [for (final list in results) ...list], succeeded: succeeded, failed: failed, cancelled: cancelled);
  }

  /// Filter hidden-library items and drop empty hubs.
  List<MediaHub> _postProcessHubs(List<MediaHub> hubs, {required ServerId serverId, Set<String>? hiddenLibraryKeys}) {
    var filtered = hubs;
    if (hiddenLibraryKeys != null && hiddenLibraryKeys.isNotEmpty) {
      filtered = filtered
          .map((hub) {
            final filteredItems = hub.items.where((item) {
              final libraryId = item.libraryId;
              if (libraryId == null) return true;
              final globalKey = buildGlobalKey(ServerId(serverId), libraryId);
              return !hiddenLibraryKeys.contains(globalKey);
            }).toList();
            if (filteredItems.isEmpty) return null;
            return hub.copyWith(items: filteredItems, size: filteredItems.length);
          })
          .whereType<MediaHub>()
          .toList();
    }
    return filtered;
  }

  /// Search across all online servers (Plex + Jellyfin). Per-server outcomes
  /// distinguish authoritative empty results from failed or cancelled legs.
  ///
  /// [hiddenLibraryKeys] excludes results the user has hidden, matching every
  /// other aggregated surface. Backends whose search rows carry no library id
  /// cannot be filtered here; they must scope the search server-side instead.
  Future<SearchAggregationResult> searchAcrossServers(
    String query, {
    int? limit,
    Set<String>? hiddenLibraryKeys,
    AbortController? abort,
  }) async {
    if (query.trim().isEmpty) {
      return (
        items: const <MediaItem>[],
        candidates: const <MediaItem>[],
        succeededServerIds: const <String>{},
        cancelledServerIds: const <String>{},
        failedServerIds: const <String>{},
      );
    }

    abort?.throwIfAborted();
    final clients = _serverManager.onlineClients;
    if (clients.isEmpty) {
      return (
        items: const <MediaItem>[],
        candidates: const <MediaItem>[],
        succeededServerIds: const <String>{},
        cancelledServerIds: const <String>{},
        failedServerIds: const <String>{},
      );
    }

    final resultLimit = limit ?? defaultMediaSearchLimit;
    final fetchLimit = resultLimit < defaultMediaSearchLimit ? defaultMediaSearchLimit : resultLimit;

    final fetched = await _fanOut<MediaItem>(
      clients,
      failureMessage: (serverId) => 'Search failed on $serverId',
      fetch: (serverId, client) async {
        final stopwatch = Stopwatch()..start();
        final items = await client.searchItems(
          query,
          limit: fetchLimit,
          abort: abort,
          excludedLibraryIds: _hiddenLibraryIdsOn(serverId, hiddenLibraryKeys),
        );
        appLogger.i(
          'Search completed on $serverId in ${stopwatch.elapsedMilliseconds}ms: '
          '${items.length} results ${_searchKindCounts(items)}',
        );
        return items;
      },
    );
    abort?.throwIfAborted();
    // Before ranking, so hidden results cannot spend the `resultLimit` budget
    // and silently shrink what the user sees.
    final visible = _withoutHiddenLibraries(fetched.items, hiddenLibraryKeys);
    final items = rankMediaSearchResults(visible, query, limit: resultLimit);

    appLogger.i(
      'Search aggregation completed: ${items.length} results '
      '(${fetched.succeededServerIds.length} succeeded, ${fetched.cancelledServerIds.length} cancelled, '
      '${fetched.failedServerIds.length} failed) ${_searchKindCounts(items)}',
    );

    return (
      items: items,
      candidates: visible,
      succeededServerIds: fetched.succeededServerIds,
      cancelledServerIds: fetched.cancelledServerIds,
      failedServerIds: fetched.failedServerIds,
    );
  }

  /// Reverse external-id lookup fanned out to every online server (see
  /// [MediaServerClient.findByExternalIds]). One request wave per tap on an
  /// Explore catalog item.
  ///
  /// Every server contributes every copy it holds, not one apiece: the same
  /// movie routinely sits in a 4K library and an HD library on one server
  /// (#1754). Results are deduped by global key and ordered best-first with
  /// [compareLibraryCopies] so the chooser is stable across repeated passes.
  ///
  /// A server that could not be asked — slow past its lookup deadline,
  /// unreachable, or aborted client-side — is reported in the failed or
  /// cancelled set rather than folded into an empty answer (#2098): the
  /// caller shows it as unchecked, and a caller holding earlier results must
  /// merge rather than replace (see [mergeLibraryCopies]).
  Future<LibraryLookupResult> findByExternalIdsAcrossServers(
    ExternalIds ids, {
    required MediaKind kind,
    List<String> titles = const [],
    int? year,
    String? plexGuid,
    ExternalSeasonRef? season,
  }) async {
    final clients = _serverManager.onlineClients;
    if ((!ids.hasAny && plexGuid == null) || clients.isEmpty) {
      return (
        items: const <MediaItem>[],
        succeededServerIds: const <String>{},
        cancelledServerIds: const <String>{},
        failedServerIds: const <String>{},
      );
    }

    final fetched = await _fanOut<MediaItem>(
      clients,
      failureMessage: (serverId) => 'External-id lookup failed on $serverId',
      fetch: (_, client) =>
          client.findByExternalIds(ids, kind: kind, titles: titles, year: year, plexGuid: plexGuid, season: season),
    );
    return (
      items: mergeLibraryCopies(const [], fetched.items),
      succeededServerIds: fetched.succeededServerIds,
      cancelledServerIds: fetched.cancelledServerIds,
      failedServerIds: fetched.failedServerIds,
    );
  }

  /// Group libraries by server (internal aggregation helper).
  Map<String, List<MediaLibrary>> _groupLibrariesByServer(List<MediaLibrary> libraries) {
    final grouped = <String, List<MediaLibrary>>{};

    for (final library in libraries) {
      final serverId = library.serverId;
      if (serverId != null) {
        grouped.putIfAbsent(serverId, () => []).add(library);
      }
    }

    return grouped;
  }
}
