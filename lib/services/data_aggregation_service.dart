import 'dart:async';

import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_library.dart';
import '../media/media_server_client.dart';
import '../utils/app_logger.dart';
import '../utils/global_key_utils.dart';
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
  /// neutral [MediaItem]s.
  Future<List<MediaItem>> getOnDeckFromAllServers({int? limit, Set<String>? hiddenLibraryKeys}) async {
    final clients = _serverManager.onlineClients;
    if (clients.isEmpty) {
      appLogger.w('No online servers available for fetching on deck');
      return [];
    }
    final futures = clients.entries.map((entry) async {
      final client = entry.value;
      try {
        return await client.fetchContinueWatching();
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
        final globalKey = buildGlobalKey(item.serverId!, item.libraryId!);
        return !hiddenLibraryKeys.contains(globalKey);
      }).toList();
    }

    // Sort by most recently viewed, falling back to addedAt for unwatched items
    filteredOnDeck.sort((a, b) {
      final aTime = a.lastViewedAt ?? a.addedAt ?? 0;
      final bTime = b.lastViewedAt ?? b.addedAt ?? 0;
      return bTime.compareTo(aTime); // Descending (most recent first)
    });

    // Apply limit if specified
    final result = limit != null && limit < filteredOnDeck.length ? filteredOnDeck.sublist(0, limit) : filteredOnDeck;

    appLogger.i('Fetched ${result.length} on deck items from all servers');

    return result;
  }

  /// Fetch recommendation hubs from all servers as neutral [MediaHub]s.
  /// When useGlobalHubs is true (default), uses the global /hubs endpoint
  /// to get the true home page hubs like "Recently Added Movies", "Recently
  /// Added TV"; when false, uses per-library hubs from
  /// /hubs/sections/{sectionId}.
  Future<List<MediaHub>> getHubsFromAllServers({
    int? limit,
    Set<String>? hiddenLibraryKeys,
    bool useGlobalHubs = true,
  }) async {
    final clients = _serverManager.onlineClients;
    if (clients.isEmpty) {
      appLogger.w('No online servers available for fetching hubs');
      return [];
    }

    // For global hubs, pre-fetch libraries to split "Recently Added" hubs
    // by library and resolve human-readable names.
    final libraries = useGlobalHubs ? _groupLibrariesByServer(await getMediaLibrariesFromAllServers()) : null;

    final futures = clients.entries.map((entry) async {
      final serverId = entry.key;
      final client = entry.value;
      try {
        final hubs = useGlobalHubs
            ? await client.fetchGlobalHubs(limit: limit ?? 10)
            : await _fetchLibraryHubsForClient(client, limit: limit ?? 10, hiddenLibraryKeys: hiddenLibraryKeys);
        return _postProcessHubs(
          hubs,
          serverId: serverId,
          hiddenLibraryKeys: hiddenLibraryKeys,
          libraries: libraries?[serverId],
          splitRecentlyAdded: useGlobalHubs,
        );
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
  }) async {
    final libs = await client.fetchLibraries();
    final visible = libs.where((l) {
      if (l.kind != MediaKind.movie && l.kind != MediaKind.show) return false;
      if (l.hidden) return false;
      if (hiddenLibraryKeys != null && hiddenLibraryKeys.contains(l.globalKey)) return false;
      return true;
    });
    final futures = visible.map((l) => client.fetchLibraryHubs(l.id, limit: limit));
    final results = await Future.wait(futures);
    return [for (final list in results) ...list];
  }

  /// Filter hidden-library items, optionally split multi-library "Recently
  /// Added" hubs by section, and drop empty hubs.
  List<MediaHub> _postProcessHubs(
    List<MediaHub> hubs, {
    required String serverId,
    Set<String>? hiddenLibraryKeys,
    List<MediaLibrary>? libraries,
    required bool splitRecentlyAdded,
  }) {
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

    if (splitRecentlyAdded) {
      filtered = _splitRecentlyAddedHubs(filtered, libraries);
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

    final futures = clients.entries.map((entry) async {
      final client = entry.value;
      try {
        return await client.searchItems(query, limit: limit ?? 30);
      } catch (e, st) {
        appLogger.e('Search failed on ${entry.key}', error: e, stackTrace: st);
        return <MediaItem>[];
      }
    });

    final allResults = (await Future.wait(futures)).expand((l) => l).toList();
    final result = limit != null && limit < allResults.length ? allResults.sublist(0, limit) : allResults;

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

  /// Split "Recently Added" hubs that contain items from multiple libraries
  /// into separate per-library hubs, matching the official Plex client behavior.
  List<MediaHub> _splitRecentlyAddedHubs(List<MediaHub> hubs, List<MediaLibrary>? libraries) {
    final result = <MediaHub>[];

    for (final hub in hubs) {
      final hubId = hub.identifier?.toLowerCase() ?? '';
      if (!hubId.contains('.recent')) {
        result.add(hub);
        continue;
      }

      // Group items by libraryId
      final groups = <String, List<MediaItem>>{};
      final ungrouped = <MediaItem>[];

      for (final item in hub.items) {
        final libraryId = item.libraryId;
        if (libraryId == null) {
          ungrouped.add(item);
        } else {
          groups.putIfAbsent(libraryId, () => []).add(item);
        }
      }

      // Single library (or no groupable items) — keep hub unchanged
      if (groups.length <= 1) {
        result.add(hub);
        continue;
      }

      // Multiple libraries — create one hub per library
      for (final entry in groups.entries) {
        final items = entry.value;
        final libraryName = _resolveLibraryName(items.first, libraries);
        final title = libraryName != null ? 'Recently Added in $libraryName' : hub.title;

        result.add(
          hub.copyWith(
            title: title,
            identifier: '${hub.identifier}_${entry.key}',
            size: items.length,
            items: items,
            libraryId: entry.key,
          ),
        );
      }

      // Keep ungrouped items in a hub with the original title
      if (ungrouped.isNotEmpty) {
        result.add(hub.copyWith(size: ungrouped.length, items: ungrouped));
      }
    }

    return result;
  }

  /// Resolve a library name from an item's [libraryTitle] or by looking up
  /// the library in the supplied list.
  String? _resolveLibraryName(MediaItem item, List<MediaLibrary>? libraries) {
    if (item.libraryTitle != null && item.libraryTitle!.isNotEmpty) {
      return item.libraryTitle;
    }
    if (libraries != null && item.libraryId != null) {
      for (final lib in libraries) {
        if (lib.id == item.libraryId) {
          return lib.title;
        }
      }
    }
    return null;
  }
}
