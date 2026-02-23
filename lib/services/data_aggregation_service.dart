import 'dart:async';

import 'plex_client.dart';
import '../models/plex_hub.dart';
import '../models/plex_library.dart';
import '../models/plex_metadata.dart';
import '../utils/app_logger.dart';
import '../utils/global_key_utils.dart';
import 'multi_server_manager.dart';
import 'plex_auth_service.dart';

/// Service for aggregating data from multiple Plex servers
class DataAggregationService {
  final MultiServerManager _serverManager;

  DataAggregationService(this._serverManager);

  /// Clear any cached data (for compatibility with existing callers)
  // ignore: no-empty-block - stub, no cache to clear in current implementation
  void clearCache() {}

  /// Fetch libraries from all online servers
  /// Libraries are automatically tagged with server info by PlexClient
  Future<List<PlexLibrary>> getLibrariesFromAllServers() async {
    return _perServer<PlexLibrary>(
      operationName: 'fetching libraries',
      operation: (serverId, client, server) async {
        return await client.getLibraries();
      },
    );
  }

  /// Fetch "On Deck" (Continue Watching) from all servers and merge by recency
  /// Items are automatically tagged with server info by PlexClient
  Future<List<PlexMetadata>> getOnDeckFromAllServers({int? limit, Set<String>? hiddenLibraryKeys}) async {
    final allOnDeck = await _perServer<PlexMetadata>(
      operationName: 'fetching on deck',
      operation: (serverId, client, server) async {
        return await client.getOnDeck();
      },
    );

    // Filter out items from hidden libraries
    List<PlexMetadata> filteredOnDeck = allOnDeck;
    if (hiddenLibraryKeys != null && hiddenLibraryKeys.isNotEmpty) {
      filteredOnDeck = allOnDeck.where((item) {
        final librarySectionId = item.librarySectionID;
        if (librarySectionId == null) return true; // Keep if no section ID
        final globalKey = buildGlobalKey(item.serverId!, librarySectionId.toString());
        return !hiddenLibraryKeys.contains(globalKey);
      }).toList();
    }

    // Sort by most recently viewed
    // Use lastViewedAt (when item was last viewed), falling back to updatedAt/addedAt if not available
    filteredOnDeck.sort((a, b) {
      final aTime = a.lastViewedAt ?? a.updatedAt ?? a.addedAt ?? 0;
      final bTime = b.lastViewedAt ?? b.updatedAt ?? b.addedAt ?? 0;
      return bTime.compareTo(aTime); // Descending (most recent first)
    });

    // Apply limit if specified
    final result = limit != null && limit < filteredOnDeck.length ? filteredOnDeck.sublist(0, limit) : filteredOnDeck;

    appLogger.i('Fetched ${result.length} on deck items from all servers');

    return result;
  }

  /// Fetch recommendation hubs from all servers
  /// When useGlobalHubs is true (default), uses the global /hubs endpoint
  /// to get the true home page hubs like "Recently Added Movies", "Recently Added TV"
  /// When false, uses per-library hubs from /hubs/sections/{sectionId}
  Future<List<PlexHub>> getHubsFromAllServers({
    int? limit,
    Set<String>? hiddenLibraryKeys,
    Map<String, List<PlexLibrary>>? librariesByServer,
    bool useGlobalHubs = true,
  }) async {
    final clients = _serverManager.onlineClients;

    if (clients.isEmpty) {
      appLogger.w('No online servers available for fetching hubs');
      return [];
    }

    return useGlobalHubs
        ? _fetchGlobalHubs(clients, limit: limit, hiddenLibraryKeys: hiddenLibraryKeys)
        : _fetchLibraryHubs(
            clients,
            limit: limit,
            hiddenLibraryKeys: hiddenLibraryKeys,
            librariesByServer: librariesByServer,
          );
  }

  /// Fetch global hubs using /hubs endpoint (matches official Plex client)
  Future<List<PlexHub>> _fetchGlobalHubs(
    Map<String, PlexClient> clients, {
    int? limit,
    Set<String>? hiddenLibraryKeys,
  }) async {
    appLogger.d('Fetching global hubs from ${clients.length} servers');

    // Fetch global hubs from all servers in parallel
    final hubFutures = clients.entries.map((entry) async {
      final serverId = entry.key;
      final client = entry.value;

      try {
        final hubs = await client.getGlobalHubs(limit: limit ?? 10);
        appLogger.d('Fetched ${hubs.length} global hubs from server $serverId');

        // Filter out items from hidden libraries if specified
        if (hiddenLibraryKeys != null && hiddenLibraryKeys.isNotEmpty) {
          return hubs
              .map((hub) {
                final filteredItems = hub.items.where((item) {
                  // Build the global key for the item's library section
                  final librarySectionId = item.librarySectionID;
                  if (librarySectionId == null) return true; // Keep if no section ID
                  final globalKey = buildGlobalKey(serverId, librarySectionId.toString());
                  return !hiddenLibraryKeys.contains(globalKey);
                }).toList();

                if (filteredItems.isEmpty) return null;

                return PlexHub(
                  hubKey: hub.hubKey,
                  title: hub.title,
                  type: hub.type,
                  hubIdentifier: hub.hubIdentifier,
                  size: filteredItems.length,
                  more: hub.more,
                  items: filteredItems,
                  serverId: hub.serverId,
                  serverName: hub.serverName,
                );
              })
              .whereType<PlexHub>()
              .toList();
        }

        return hubs;
      } catch (e, stackTrace) {
        appLogger.e('Failed to fetch hubs from server $serverId', error: e, stackTrace: stackTrace);
        _serverManager.updateServerStatus(serverId, false);
        return <PlexHub>[];
      }
    });

    final results = await Future.wait(hubFutures);
    final result = _collectAndLimitResults(results, limit);

    appLogger.i('Fetched ${result.length} global hubs from all servers');

    return result;
  }

  /// Fetch per-library hubs using /hubs/sections/{sectionId} endpoint
  Future<List<PlexHub>> _fetchLibraryHubs(
    Map<String, PlexClient> clients, {
    int? limit,
    Set<String>? hiddenLibraryKeys,
    Map<String, List<PlexLibrary>>? librariesByServer,
  }) async {
    // Use pre-fetched libraries or fetch and group them
    final libraries = librariesByServer ?? groupLibrariesByServer(await getLibrariesFromAllServers());

    appLogger.d('Fetching per-library hubs from ${clients.length} servers');

    // Fetch from all servers in parallel using cached libraries
    final hubFutures = clients.entries.map((entry) async {
      final serverId = entry.key;
      final client = entry.value;

      try {
        // Use pre-fetched libraries for this server
        final serverLibraries = libraries[serverId] ?? <PlexLibrary>[];
        if (serverLibraries.isEmpty) {
          appLogger.w('No libraries available for server $serverId');
          return <PlexHub>[];
        }

        // Filter to only visible movie/show libraries
        final visibleLibraries = serverLibraries.where((library) {
          if (library.type != 'movie' && library.type != 'show') {
            return false;
          }
          if (library.hidden != null && library.hidden != 0) {
            return false;
          }
          // Check app-level hidden libraries
          if (hiddenLibraryKeys != null && hiddenLibraryKeys.contains(library.globalKey)) {
            return false;
          }
          return true;
        }).toList();

        // Fetch hubs from all libraries in parallel
        final libraryHubFutures = visibleLibraries.map((library) async {
          try {
            // Hubs are now tagged with server info at the source
            final hubs = await client.getLibraryHubs(library.key);
            appLogger.d('Fetched ${hubs.length} hubs for ${library.title} on $serverId');
            return hubs;
          } catch (e) {
            appLogger.w('Failed to fetch hubs for library ${library.title}: $e');
            return <PlexHub>[];
          }
        });

        final libraryHubResults = await Future.wait(libraryHubFutures);

        // Flatten all library hubs
        final serverHubs = <PlexHub>[];
        for (final hubs in libraryHubResults) {
          serverHubs.addAll(hubs);
        }

        return serverHubs;
      } catch (e, stackTrace) {
        appLogger.e('Failed to fetch hubs from server $serverId', error: e, stackTrace: stackTrace);
        _serverManager.updateServerStatus(serverId, false);
        return <PlexHub>[];
      }
    });

    final results = await Future.wait(hubFutures);
    final result = _collectAndLimitResults(results, limit);

    appLogger.i('Fetched ${result.length} library hubs from all servers');

    return result;
  }

  /// Search across all online servers
  /// Results are automatically tagged with server info by PlexClient
  Future<List<PlexMetadata>> searchAcrossServers(String query, {int? limit}) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final allResults = await _perServer<PlexMetadata>(
      operationName: 'searching for "$query"',
      operation: (serverId, client, server) async {
        return await client.search(query);
      },
    );

    // Apply limit if specified
    final result = limit != null && limit < allResults.length ? allResults.sublist(0, limit) : allResults;

    appLogger.i('Found ${result.length} search results across all servers');

    return result;
  }

  /// Get libraries for a specific server
  Future<List<PlexLibrary>> getLibrariesForServer(String serverId) async {
    final client = _serverManager.getClient(serverId);

    if (client == null) {
      appLogger.w('No client found for server $serverId');
      return [];
    }

    try {
      // Libraries are automatically tagged with server info by PlexClient
      return await client.getLibraries();
    } catch (e, stackTrace) {
      appLogger.e('Failed to fetch libraries for server $serverId', error: e, stackTrace: stackTrace);
      _serverManager.updateServerStatus(serverId, false);
      return [];
    }
  }

  /// Group libraries by server
  Map<String, List<PlexLibrary>> groupLibrariesByServer(List<PlexLibrary> libraries) {
    final grouped = <String, List<PlexLibrary>>{};

    for (final library in libraries) {
      final serverId = library.serverId;
      if (serverId != null) {
        grouped.putIfAbsent(serverId, () => []).add(library);
      }
    }

    return grouped;
  }

  // Private helper methods

  /// Collect results from multiple lists and optionally limit the total count.
  List<T> _collectAndLimitResults<T>(List<List<T>> results, int? limit) {
    final all = <T>[];
    for (final items in results) {
      all.addAll(items);
    }
    return limit != null && limit < all.length ? all.sublist(0, limit) : all;
  }

  /// Base helper for per-server fan-out operations
  ///
  /// Returns raw results as (serverId, result) tuples.
  /// Used by [_perServer] and [_perServerGrouped] for different aggregation strategies.
  Future<List<(String serverId, List<T> result)>> _perServerRaw<T>({
    required String operationName,
    required Future<List<T>> Function(String serverId, PlexClient client, PlexServer? server) operation,
  }) async {
    final clients = _serverManager.onlineClients;

    if (clients.isEmpty) {
      appLogger.w('No online servers available for $operationName');
      return [];
    }

    appLogger.d('$operationName from ${clients.length} servers');

    final futures = clients.entries.map((entry) async {
      final serverId = entry.key;
      final client = entry.value;
      final server = _serverManager.getServer(serverId);
      final sw = Stopwatch()..start();

      try {
        final result = await operation(serverId, client, server);
        appLogger.d(
          '$operationName for server $serverId completed in ${sw.elapsedMilliseconds}ms with ${result.length} items',
        );
        return (serverId, result);
      } catch (e, stackTrace) {
        appLogger.e('Failed $operationName from server $serverId', error: e, stackTrace: stackTrace);
        _serverManager.updateServerStatus(serverId, false);
        appLogger.d('$operationName for server $serverId failed after ${sw.elapsedMilliseconds}ms');
        return (serverId, <T>[]);
      }
    });

    return await Future.wait(futures);
  }

  /// Higher-order helper for per-server fan-out operations
  ///
  /// Iterates over all online clients, executes the operation for each server,
  /// handles errors, updates server status, and flattens results into a single list.
  Future<List<T>> _perServer<T>({
    required String operationName,
    required Future<List<T>> Function(String serverId, PlexClient client, PlexServer? server) operation,
  }) async {
    final results = await _perServerRaw(operationName: operationName, operation: operation);
    return [for (final (_, items) in results) ...items];
  }
}
