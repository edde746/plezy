import 'dart:async';

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
import 'plex_client.dart';
import 'trackers/tracker_ui_helper.dart';
import 'trackers/watch_state_overlay.dart';

/// Cross-server aggregation: fans calls out to every online client and
/// merges the results. Single-server operations now go through the
/// [MediaServerClient] interface directly (resolved via
/// [ProviderExtensions.tryGetMediaClientForServer] etc.), so this service
/// only owns the genuinely multi-server flows: home/discover hubs, on-deck,
/// search, and the global library list.
class DataAggregationService {
  final MultiServerManager _serverManager;

  DataAggregationService(this._serverManager);

  /// Fetch libraries from all online clients regardless of backend, returning
  /// neutral [MediaLibrary]s.
  Future<List<MediaLibrary>> getMediaLibrariesFromAllServers() async {
    final clients = _serverManager.onlineClients;
    if (clients.isEmpty) {
      appLogger.w('No online servers available for fetching libraries (neutral)');
      return [];
    }
    final futures = clients.entries.map((entry) async {
      try {
        return await entry.value.fetchLibraries();
      } catch (e, stackTrace) {
        appLogger.e('Failed neutral library fetch from ${entry.key}', error: e, stackTrace: stackTrace);
        return <MediaLibrary>[];
      }
    });
    final results = await Future.wait(futures);
    return [for (final list in results) ...list];
  }

  /// Fetch "On Deck" (Continue Watching) from all servers and merge by recency.
  /// Items are tagged with server info by the underlying client. Returns
  /// neutral [MediaItem]s. When a tracker authority is active (e.g. Trakt),
  /// the authority is the sole source of truth for Continue Watching.
  Future<List<MediaItem>> getOnDeckFromAllServers({int? limit, Set<String>? hiddenLibraryKeys}) async {
    await WatchStateOverlay.instance.cacheReady;

    // When a tracker authority is active it is the sole source of truth.
    if (WatchStateOverlay.instance.hasActiveAuthority) {
      return _getOnDeckFromAuthority(limit: limit, hiddenLibraryKeys: hiddenLibraryKeys);
    }

    final clients = _serverManager.onlineClients;
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

    // Re-check: if authority became active during the fetch, use it instead.
    if (WatchStateOverlay.instance.hasActiveAuthority) {
      return _getOnDeckFromAuthority(limit: limit, hiddenLibraryKeys: hiddenLibraryKeys);
    }

    List<MediaItem> result = allOnDeck;
    if (hiddenLibraryKeys != null && hiddenLibraryKeys.isNotEmpty) {
      result = allOnDeck.where((item) {
        if (item.libraryId == null || item.serverId == null) return true;
        final globalKey = buildGlobalKey(item.serverId!, item.libraryId!);
        return !hiddenLibraryKeys.contains(globalKey);
      }).toList();
    }

    result.sort((a, b) {
      final aTime = a.lastViewedAt ?? a.addedAt ?? 0;
      final bTime = b.lastViewedAt ?? b.addedAt ?? 0;
      return bTime.compareTo(aTime);
    });

    result = await _deduplicateContinueWatching(result);

    if (limit != null && limit < result.length) result = result.sublist(0, limit);
    appLogger.i('Fetched ${result.length} on deck items from all servers');
    return result;
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
    final client = serverId == null ? null : _serverManager.getClient(serverId);

    if (client != null && targetId != null && targetId.isNotEmpty) {
      try {
        final cacheKey = buildGlobalKey(serverId!, targetId);
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

  Future<List<MediaItem>> _getOnDeckFromAuthority({int? limit, Set<String>? hiddenLibraryKeys}) async {
    final plexClients = Map.fromEntries(
      _serverManager.onlineClients.entries
          .where((e) => e.value is PlexClient)
          .map((e) => MapEntry(e.key, e.value as PlexClient)),
    );
    final fallbackServerId = plexClients.keys.firstOrNull;
    // Await enrichment so not-found stubs are filtered before returning.
    // Fast on subsequent calls (needsWork empty, returns immediately).
    await Future.wait([
      enrichTrackerStubs(fallbackServerId, plexClients),
      resolveTrackerEpisodeDisplayPositions(plexClients, fallbackServerId),
    ]);

    var items = WatchStateOverlay.instance.getContinueWatchingItems().map((i) {
      final meta = i.metadata;
      if (meta.serverId != null || fallbackServerId == null) return meta;
      return meta.copyWith(serverId: fallbackServerId);
    }).toList();

    if (hiddenLibraryKeys != null && hiddenLibraryKeys.isNotEmpty) {
      items = items.where((item) {
        if (item.libraryId == null || item.serverId == null) return true;
        return !hiddenLibraryKeys.contains(buildGlobalKey(item.serverId!, item.libraryId!));
      }).toList();
    }

    if (limit != null && limit < items.length) items = items.sublist(0, limit);
    appLogger.i('Fetched ${items.length} on deck items from tracker authority');
    return items;
  }

  /// Enriches Trakt stubs by searching Plex servers, populating the bridge map
  /// so stub-to-Plex resolution is ready before the user taps an item.
  Future<void> enrichTrackerStubsFromPlex(String? preferredServerId) {
    final plexClients = Map.fromEntries(
      _serverManager.onlineClients.entries
          .where((e) => e.value is PlexClient)
          .map((e) => MapEntry(e.key, e.value as PlexClient)),
    );
    return enrichTrackerStubs(preferredServerId, plexClients);
  }

  /// Fetch recommendation hubs from all servers as neutral [MediaHub]s.
  /// When useGlobalHubs is true (default), rich-hub backends use their true
  /// home page hubs (Plex's promoted/global hub endpoint).
  /// Backends without rich home hubs fall back to per-library hubs so one
  /// capped "Latest" response cannot hide whole library types.
  Future<List<MediaHub>> getHubsFromAllServers({
    int? limit,
    Set<String>? hiddenLibraryKeys,
    bool useGlobalHubs = true,
    bool includePlaybackHubs = true,
  }) async {
    final clients = _serverManager.onlineClients;
    if (clients.isEmpty) {
      appLogger.w('No online servers available for fetching hubs');
      return [];
    }

    // Only fallback clients need a library prefetch when home layout is on;
    // rich-hub backends return the intended home rows directly.
    final needsLibraryPrefetch = useGlobalHubs && clients.values.any((client) => !client.capabilities.richHubs);
    final libraries = needsLibraryPrefetch ? _groupLibrariesByServer(await getMediaLibrariesFromAllServers()) : null;

    final futures = clients.entries.map((entry) async {
      final serverId = entry.key;
      final client = entry.value;
      try {
        final serverLibraries = libraries?[serverId];
        final shouldUseGlobalHubs = useGlobalHubs && client.capabilities.richHubs;
        final hubs = shouldUseGlobalHubs
            ? await client.fetchGlobalHubs(limit: limit ?? 10, includePlaybackHubs: includePlaybackHubs)
            : await _fetchLibraryHubsForClient(
                client,
                limit: limit ?? 10,
                hiddenLibraryKeys: hiddenLibraryKeys,
                includePlaybackHubs: includePlaybackHubs,
                libraries: useGlobalHubs ? serverLibraries : null,
              );
        return _postProcessHubs(hubs, serverId: serverId, hiddenLibraryKeys: hiddenLibraryKeys);
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
    // Apply watch state overlay (Trakt authority, etc.) to all hub items.
    await WatchStateOverlay.instance.cacheReady;
    final overlaid = all
        .map((hub) => hub.copyWith(items: WatchStateOverlay.instance.applyAll(hub.items)))
        .toList();
    return limit != null && limit < overlaid.length ? overlaid.sublist(0, limit) : overlaid;
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
  List<MediaHub> _postProcessHubs(List<MediaHub> hubs, {required String serverId, Set<String>? hiddenLibraryKeys}) {
    var filtered = hubs;
    if (hiddenLibraryKeys != null && hiddenLibraryKeys.isNotEmpty) {
      filtered = filtered
          .map((hub) {
            final filteredItems = hub.items.where((item) {
              final libraryId = item.libraryId;
              if (libraryId == null) return true;
              final globalKey = buildGlobalKey(serverId, libraryId);
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
    final overlaid = allResults.map(WatchStateOverlay.instance.apply).toList();
    final result = rankMediaSearchResults(overlaid, query, limit: resultLimit);

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
