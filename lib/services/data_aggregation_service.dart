import 'dart:async';
import '../media/ids.dart';

import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_library.dart';
import '../media/media_server_client.dart';
import '../utils/app_logger.dart';
import '../utils/external_ids.dart';
import '../utils/global_key_utils.dart';
import '../utils/search_relevance.dart';
import 'multi_server_manager.dart';

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
  /// never retried.
  Future<({List<MediaLibrary> libraries, Set<String> succeededServerIds})> getMediaLibrariesFromAllServers({
    Set<String>? serverIds,
  }) async {
    final clients = _clientsFor(serverIds);
    if (clients.isEmpty) {
      appLogger.w('No online servers available for fetching libraries (neutral)');
      return (libraries: const <MediaLibrary>[], succeededServerIds: const <String>{});
    }
    final succeededServerIds = <String>{};
    final futures = clients.entries.map((entry) async {
      try {
        final libraries = await entry.value.fetchLibraries();
        succeededServerIds.add(entry.key);
        return libraries;
      } catch (e, stackTrace) {
        appLogger.e('Failed neutral library fetch from ${entry.key}', error: e, stackTrace: stackTrace);
        return <MediaLibrary>[];
      }
    });
    final results = await Future.wait(futures);
    return (libraries: [for (final list in results) ...list], succeededServerIds: succeededServerIds);
  }

  /// Fetch "On Deck" (Continue Watching) from all servers and merge by recency.
  /// Items are tagged with server info by the underlying client. Returns
  /// neutral [MediaItem]s. [serverIds] restricts the fan-out to those servers.
  Future<List<MediaItem>> getOnDeckFromAllServers({
    int? limit,
    Set<String>? hiddenLibraryKeys,
    Set<String>? serverIds,
  }) async {
    final clients = _clientsFor(serverIds);
    if (clients.isEmpty) {
      appLogger.w('No online servers available for fetching on deck');
      return [];
    }
    final futures = clients.entries.map((entry) async {
      final client = entry.value;
      try {
        return await client.fetchContinueWatching(count: limit);
      } catch (e, st) {
        appLogger.e('Failed on-deck fetch from ${entry.key}', error: e, stackTrace: st);
        return <MediaItem>[];
      }
    });
    final allOnDeck = (await Future.wait(futures)).expand((l) => l).toList();

    // Filter out items from hidden libraries
    List<MediaItem> filteredOnDeck = allOnDeck;
    if (hiddenLibraryKeys != null && hiddenLibraryKeys.isNotEmpty) {
      filteredOnDeck = allOnDeck.where((item) {
        if (item.libraryId == null || item.serverId == null) return true;
        final globalKey = buildGlobalKey(ServerId(item.serverId!), item.libraryId!);
        return !hiddenLibraryKeys.contains(globalKey);
      }).toList();
    }

    // Sort by most recently viewed, falling back to addedAt for unwatched items.
    // Same key as JellyfinClient's continue-watching merge (MediaItem.recencySortKey)
    // so per-server and cross-server ordering can't drift apart.
    filteredOnDeck.sort((a, b) => b.recencySortKey.compareTo(a.recencySortKey));

    filteredOnDeck = await _deduplicateContinueWatching(filteredOnDeck);

    // Apply limit if specified
    final result = limit != null && limit < filteredOnDeck.length ? filteredOnDeck.sublist(0, limit) : filteredOnDeck;

    appLogger.i('Fetched ${result.length} on deck items from all servers');

    return result;
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

    final seenKeys = <String>{};
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

      if (identityKeys.any(seenKeys.contains)) continue;

      seenKeys.addAll(identityKeys);
      result.add(item);
    }

    return result;
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
  /// those servers.
  Future<List<MediaHub>> getHubsFromAllServers({
    int? limit,
    Set<String>? hiddenLibraryKeys,
    bool useGlobalHubs = true,
    bool includePlaybackHubs = true,
    Set<String>? serverIds,
  }) async {
    final clients = _clientsFor(serverIds);
    if (clients.isEmpty) {
      appLogger.w('No online servers available for fetching hubs');
      return [];
    }

    // Only fallback clients need a library prefetch when home layout is on;
    // rich-hub backends return the intended home rows directly.
    final needsLibraryPrefetch = useGlobalHubs && clients.values.any((client) => !client.capabilities.richHubs);
    final libraries = needsLibraryPrefetch
        ? _groupLibrariesByServer((await getMediaLibrariesFromAllServers(serverIds: serverIds)).libraries)
        : null;

    final futures = clients.entries.map((entry) async {
      final serverId = entry.key;
      final client = entry.value;
      try {
        final serverLibraries = libraries?[serverId];
        final shouldUseGlobalHubs = useGlobalHubs && client.capabilities.richHubs;
        final hubItemLimit = limit ?? defaultHubPreviewLimit;
        final hubs = shouldUseGlobalHubs
            ? await client.fetchGlobalHubs(limit: hubItemLimit, includePlaybackHubs: includePlaybackHubs)
            : await _fetchLibraryHubsForClient(
                client,
                limit: hubItemLimit,
                hiddenLibraryKeys: hiddenLibraryKeys,
                includePlaybackHubs: includePlaybackHubs,
                libraries: useGlobalHubs ? serverLibraries : null,
              );
        return _postProcessHubs(hubs, serverId: ServerId(serverId), hiddenLibraryKeys: hiddenLibraryKeys);
      } catch (e, stackTrace) {
        appLogger.e('Failed to fetch hubs from server $serverId', error: e, stackTrace: stackTrace);
        return <MediaHub>[];
      }
    });

    final results = await Future.wait(futures);
    final all = <MediaHub>[];
    for (final list in results) {
      all.addAll(list);
    }
    return limit != null && limit < all.length ? all.sublist(0, limit) : all;
  }

  /// Per-library hub fetch for a single client. Filters to visible
  /// movie/show libraries (Plex hides music libraries from this surface) and
  /// concatenates the results.
  Future<List<MediaHub>> _fetchLibraryHubsForClient(
    MediaServerClient client, {
    required int limit,
    Set<String>? hiddenLibraryKeys,
    required bool includePlaybackHubs,
    List<MediaLibrary>? libraries,
  }) async {
    final libs = libraries ?? await client.fetchLibraries();
    final visible = libs.where((l) {
      if (l.kind != MediaKind.movie && l.kind != MediaKind.show) return false;
      if (l.hidden) return false;
      if (hiddenLibraryKeys != null && hiddenLibraryKeys.contains(l.globalKey)) return false;
      return true;
    }).toList();

    const concurrency = 3;
    final all = <MediaHub>[];
    for (var start = 0; start < visible.length; start += concurrency) {
      final batch = visible.skip(start).take(concurrency);
      final results = await Future.wait(
        batch.map((l) async {
          try {
            return await client.fetchLibraryHubs(
              l.id,
              libraryName: l.title,
              limit: limit,
              includePlaybackHubs: includePlaybackHubs,
              libraryKind: l.kind,
            );
          } catch (e, st) {
            appLogger.e('Failed to fetch library hubs for ${l.globalKey}', error: e, stackTrace: st);
            return <MediaHub>[];
          }
        }),
      );
      for (final list in results) {
        all.addAll(list);
      }
    }
    return all;
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

  /// Search across all online servers (Plex + Jellyfin). Returns neutral
  /// [MediaItem]s.
  Future<List<MediaItem>> searchAcrossServers(String query, {int? limit}) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final clients = _serverManager.onlineClients;
    if (clients.isEmpty) return [];

    final resultLimit = limit ?? defaultMediaSearchLimit;
    final fetchLimit = resultLimit < defaultMediaSearchLimit ? defaultMediaSearchLimit : resultLimit;

    final futures = clients.entries.map((entry) async {
      final client = entry.value;
      try {
        return await client.searchItems(query, limit: fetchLimit);
      } catch (e, st) {
        appLogger.e('Search failed on ${entry.key}', error: e, stackTrace: st);
        return <MediaItem>[];
      }
    });

    final allResults = (await Future.wait(futures)).expand((l) => l).toList();
    final result = rankMediaSearchResults(allResults, query, limit: resultLimit);

    appLogger.i('Found ${result.length} search results across all servers');

    return result;
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
