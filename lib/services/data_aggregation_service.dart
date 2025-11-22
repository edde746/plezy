import 'dart:async';

import '../client/plex_client.dart';
import '../models/plex_hub.dart';
import '../models/plex_library.dart';
import '../models/plex_metadata.dart';
import '../utils/app_logger.dart';
import 'multi_server_manager.dart';
import 'plex_auth_service.dart';

/// Service for aggregating data from multiple Plex servers
class DataAggregationService {
  final MultiServerManager _serverManager;

  DataAggregationService(this._serverManager);

  /// Fetch libraries from all online servers and tag them with server info
  Future<List<PlexLibrary>> getLibrariesFromAllServers() async {
    return _perServer<PlexLibrary>(
      operationName: 'fetching libraries',
      operation: (serverId, client, server) async {
        final libraries = await client.getLibraries();

        // Tag each library with server info
        return libraries.map((lib) {
          return PlexLibrary(
            key: lib.key,
            title: lib.title,
            type: lib.type,
            agent: lib.agent,
            scanner: lib.scanner,
            language: lib.language,
            uuid: lib.uuid,
            updatedAt: lib.updatedAt,
            createdAt: lib.createdAt,
            hidden: lib.hidden,
            serverId: serverId,
            serverName: server?.name,
          );
        }).toList();
      },
    );
  }

  /// Fetch "On Deck" (Continue Watching) from all servers and merge by recency
  Future<List<PlexMetadata>> getOnDeckFromAllServers({int? limit}) async {
    final allOnDeck = await _perServer<PlexMetadata>(
      operationName: 'fetching on deck',
      operation: (serverId, client, server) async {
        final items = await client.getOnDeck();

        // Tag each item with server info
        return items.map((item) {
          return item.copyWith(serverId: serverId, serverName: server?.name);
        }).toList();
      },
    );

    // Sort by most recent (lastViewedAt is stored in viewOffset metadata)
    // For on deck items, we use updatedAt or addedAt as proxy for recency
    allOnDeck.sort((a, b) {
      final aTime = a.updatedAt ?? a.addedAt ?? 0;
      final bTime = b.updatedAt ?? b.addedAt ?? 0;
      return bTime.compareTo(aTime); // Descending (most recent first)
    });

    // Apply limit if specified
    final result = limit != null && limit < allOnDeck.length
        ? allOnDeck.sublist(0, limit)
        : allOnDeck;

    appLogger.i('Fetched ${result.length} on deck items from all servers');

    return result;
  }

  /// Fetch recommendation hubs from all servers
  Future<List<PlexHub>> getHubsFromAllServers({int? limit}) async {
    final clients = _serverManager.onlineClients;

    if (clients.isEmpty) {
      appLogger.w('No online servers available for fetching hubs');
      return [];
    }

    appLogger.d('Fetching hubs from ${clients.length} servers');

    final allHubs = <PlexHub>[];

    // Fetch from all servers in parallel
    final hubFutures = clients.entries.map((entry) async {
      final serverId = entry.key;
      final client = entry.value;
      final server = _serverManager.getServer(serverId);

      try {
        // Get libraries for this server
        final libraries = await client.getLibraries();

        // Filter to only visible movie/show libraries
        final visibleLibraries = libraries.where((library) {
          if (library.type != 'movie' && library.type != 'show') {
            return false;
          }
          if (library.hidden != null && library.hidden != 0) {
            return false;
          }
          return true;
        }).toList();

        // Fetch hubs from all libraries in parallel
        final libraryHubFutures = visibleLibraries.map((library) async {
          try {
            final libraryHubs = await client.getLibraryHubs(library.key);

            // Tag hubs and their items with server info
            return libraryHubs.map((hub) {
              final taggedItems = hub.items.map((item) {
                return item.copyWith(
                  serverId: serverId,
                  serverName: server?.name,
                );
              }).toList();

              return PlexHub(
                hubKey: hub.hubKey,
                title: hub.title,
                type: hub.type,
                hubIdentifier: hub.hubIdentifier,
                size: hub.size,
                more: hub.more,
                items: taggedItems,
                serverId: serverId,
                serverName: server?.name,
              );
            }).toList();
          } catch (e) {
            appLogger.w(
              'Failed to fetch hubs for library ${library.title}: $e',
            );
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
        appLogger.e(
          'Failed to fetch hubs from server $serverId',
          error: e,
          stackTrace: stackTrace,
        );
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
    final result = limit != null && limit < allHubs.length
        ? allHubs.sublist(0, limit)
        : allHubs;

    appLogger.i('Fetched ${result.length} hubs from all servers');

    return result;
  }

  /// Search across all online servers
  Future<List<PlexMetadata>> searchAcrossServers(
    String query, {
    int? limit,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final allResults = await _perServer<PlexMetadata>(
      operationName: 'searching for "$query"',
      operation: (serverId, client, server) async {
        final results = await client.search(query);

        // Tag each result with server info
        return results.map((item) {
          return item.copyWith(serverId: serverId, serverName: server?.name);
        }).toList();
      },
    );

    // Apply limit if specified
    final result = limit != null && limit < allResults.length
        ? allResults.sublist(0, limit)
        : allResults;

    appLogger.i('Found ${result.length} search results across all servers');

    return result;
  }

  /// Get libraries for a specific server
  Future<List<PlexLibrary>> getLibrariesForServer(String serverId) async {
    final client = _serverManager.getClient(serverId);
    final server = _serverManager.getServer(serverId);

    if (client == null) {
      appLogger.w('No client found for server $serverId');
      return [];
    }

    try {
      final libraries = await client.getLibraries();

      // Tag with server info
      return libraries.map((lib) {
        return PlexLibrary(
          key: lib.key,
          title: lib.title,
          type: lib.type,
          agent: lib.agent,
          scanner: lib.scanner,
          language: lib.language,
          uuid: lib.uuid,
          updatedAt: lib.updatedAt,
          createdAt: lib.createdAt,
          hidden: lib.hidden,
          serverId: serverId,
          serverName: server?.name,
        );
      }).toList();
    } catch (e, stackTrace) {
      appLogger.e(
        'Failed to fetch libraries for server $serverId',
        error: e,
        stackTrace: stackTrace,
      );
      _serverManager.updateServerStatus(serverId, false);
      return [];
    }
  }

  /// Group libraries by server
  Map<String, List<PlexLibrary>> groupLibrariesByServer(
    List<PlexLibrary> libraries,
  ) {
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
    required Future<List<T>> Function(
      String serverId,
      PlexClient client,
      PlexServer? server,
    )
    operation,
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

      try {
        return await operation(serverId, client, server);
      } catch (e, stackTrace) {
        appLogger.e(
          'Failed $operationName from server $serverId',
          error: e,
          stackTrace: stackTrace,
        );
        _serverManager.updateServerStatus(serverId, false);
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
}
