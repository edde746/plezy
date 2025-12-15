import 'dart:async';

import 'plex_client.dart';
import '../models/plex_hub.dart';
import '../models/plex_library.dart';
import '../models/plex_metadata.dart';
import '../utils/app_logger.dart';
import 'multi_server_manager.dart';
import 'plex_auth_service.dart';

/// Service for aggregating data from multiple Plex servers
class DataAggregationService {
  final MultiServerManager _serverManager;

  // Cache for libraries with TTL
  Map<String, List<PlexLibrary>>? _cachedLibrariesByServer;
  DateTime? _librariesCacheTime;
  static const Duration _librariesCacheTTL = Duration(hours: 1);

  DataAggregationService(this._serverManager);

  /// Clear the libraries cache (useful for server changes or logout)
  void clearCache() {
    _cachedLibrariesByServer = null;
    _librariesCacheTime = null;
  }

  /// Check if libraries cache is still valid
  bool get _isLibrariesCacheValid {
    if (_cachedLibrariesByServer == null || _librariesCacheTime == null) {
      return false;
    }

    final cacheAge = DateTime.now().difference(_librariesCacheTime!);
    return cacheAge < _librariesCacheTTL;
  }

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
  Future<List<PlexMetadata>> getOnDeckFromAllServers({int? limit}) async {
    final allOnDeck = await _perServer<PlexMetadata>(
      operationName: 'fetching on deck',
      operation: (serverId, client, server) async {
        return await client.getOnDeck();
      },
    );

    // Sort by most recently viewed
    // Use lastViewedAt (when item was last viewed), falling back to updatedAt/addedAt if not available
    allOnDeck.sort((a, b) {
      final aTime = a.lastViewedAt ?? a.updatedAt ?? a.addedAt ?? 0;
      final bTime = b.lastViewedAt ?? b.updatedAt ?? b.addedAt ?? 0;
      return bTime.compareTo(aTime); // Descending (most recent first)
    });

    // Apply limit if specified
    final result = limit != null && limit < allOnDeck.length ? allOnDeck.sublist(0, limit) : allOnDeck;

    appLogger.i('Fetched ${result.length} on deck items from all servers');

    return result;
  }

  /// Fetch libraries from all servers and cache them for hub fetching
  /// This allows libraries to be fetched in parallel with other operations
  Future<Map<String, List<PlexLibrary>>> getLibrariesFromAllServersGrouped({bool forceRefresh = false}) async {
    // Return cached libraries if still valid and not forcing refresh
    if (!forceRefresh && _isLibrariesCacheValid) {
      appLogger.d('Using cached libraries data');
      return _cachedLibrariesByServer!;
    }

    final librariesByServer = await _perServerGrouped<PlexLibrary>(
      operationName: 'fetching libraries',
      operation: (serverId, client, server) async {
        return await client.getLibraries();
      },
    );

    // Cache the results
    _cachedLibrariesByServer = librariesByServer;
    _librariesCacheTime = DateTime.now();

    final totalLibraries = librariesByServer.values.fold<int>(0, (sum, libs) => sum + libs.length);
    appLogger.d('Fetched $totalLibraries libraries from ${librariesByServer.length} servers');

    return librariesByServer;
  }

  /// Fetch recommendation hubs from all servers using pre-fetched libraries
  Future<List<PlexHub>> getHubsFromAllServers({
    int? limit,
    Map<String, List<PlexLibrary>>? librariesByServer,
    Set<String>? hiddenLibraryKeys,
  }) async {
    final clients = _serverManager.onlineClients;

    if (clients.isEmpty) {
      appLogger.w('No online servers available for fetching hubs');
      return [];
    }

    // Use pre-fetched libraries or fetch them if not provided
    final libraries = librariesByServer ?? await getLibrariesFromAllServersGrouped();

    appLogger.d('Fetching hubs from ${clients.length} servers');

    final allHubs = <PlexHub>[];

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

    // Flatten results
    for (final hubs in results) {
      allHubs.addAll(hubs);
    }

    // Apply limit if specified
    final result = limit != null && limit < allHubs.length ? allHubs.sublist(0, limit) : allHubs;

    appLogger.i('Fetched ${result.length} hubs from all servers');

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

  /// Higher-order helper for per-server fan-out operations
  ///
  /// Iterates over all online clients, executes the operation for each server,
  /// handles errors, updates server status, and aggregates results.
  ///
  /// Type parameter `T` is the item type returned by the operation
  /// [operationName] is used for logging (e.g., "fetching libraries")
  /// [operation] is the async function to run per server, returning `List<T>`
  Future<List<T>> _perServer<T>({
    required String operationName,
    required Future<List<T>> Function(String serverId, PlexClient client, PlexServer? server) operation,
  }) async {
    final clients = _serverManager.onlineClients;

    if (clients.isEmpty) {
      appLogger.w('No online servers available for $operationName');
      return [];
    }

    appLogger.d('$operationName from ${clients.length} servers');

    final allResults = <T>[];

    // Execute operation on all servers in parallel
    final Iterable<Future<List<T>>> futures = clients.entries.map((entry) async {
      final serverId = entry.key;
      final client = entry.value;
      final server = _serverManager.getServer(serverId);
      final sw = Stopwatch()..start();

      try {
        final result = await operation(serverId, client, server);
        appLogger.d(
          '$operationName for server $serverId completed in ${sw.elapsedMilliseconds}ms with ${result.length} items',
        );
        return result;
      } catch (e, stackTrace) {
        appLogger.e('Failed $operationName from server $serverId', error: e, stackTrace: stackTrace);
        _serverManager.updateServerStatus(serverId, false);
        appLogger.d('$operationName for server $serverId failed after ${sw.elapsedMilliseconds}ms');
        return <T>[];
      }
    });

    final List<List<T>> results = await Future.wait<List<T>>(futures);

    // Flatten results
    for (final items in results) {
      allResults.addAll(items);
    }

    return allResults;
  }

  /// Higher-order helper for per-server fan-out operations that groups results by server
  ///
  /// Similar to [_perServer] but returns a Map with results grouped by serverId
  /// instead of flattening into a single list.
  ///
  /// Type parameter `T` is the item type returned by the operation
  /// [operationName] is used for logging (e.g., "fetching libraries")
  /// [operation] is the async function to run per server, returning `List<T>`
  Future<Map<String, List<T>>> _perServerGrouped<T>({
    required String operationName,
    required Future<List<T>> Function(String serverId, PlexClient client, PlexServer? server) operation,
  }) async {
    final clients = _serverManager.onlineClients;

    if (clients.isEmpty) {
      appLogger.w('No online servers available for $operationName');
      return {};
    }

    appLogger.d('$operationName from ${clients.length} servers');

    // Execute operation on all servers in parallel
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
        return MapEntry(serverId, result);
      } catch (e, stackTrace) {
        appLogger.e('Failed $operationName from server $serverId', error: e, stackTrace: stackTrace);
        _serverManager.updateServerStatus(serverId, false);
        appLogger.d('$operationName for server $serverId failed after ${sw.elapsedMilliseconds}ms');
        return MapEntry(serverId, <T>[]);
      }
    });

    final results = await Future.wait(futures);

    return Map.fromEntries(results);
  }
}
