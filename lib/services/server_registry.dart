import 'dart:convert';

import 'package:dio/dio.dart';

import '../utils/app_logger.dart';
import 'plex_auth_service.dart';
import 'storage_service.dart';

enum ServerRefreshResult { success, networkError, authError, noToken }

/// Centralized server configuration registry
/// Manages which servers are available and their configurations
class ServerRegistry {
  final StorageService _storage;

  ServerRegistry(this._storage);

  /// Get all registered servers
  Future<List<PlexServer>> getServers() async {
    try {
      final serversJson = _storage.getServersListJson();
      if (serversJson == null || serversJson.isEmpty) {
        return [];
      }

      final List<dynamic> serversList = jsonDecode(serversJson);
      return serversList.map((json) => PlexServer.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e, stackTrace) {
      appLogger.e('Failed to load servers from storage', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Save all servers to storage
  Future<void> saveServers(List<PlexServer> servers) async {
    try {
      final serversJson = jsonEncode(servers.map((s) => s.toJson()).toList());
      await _storage.saveServersListJson(serversJson);
      appLogger.d('Saved ${servers.length} servers to storage');
    } catch (e, stackTrace) {
      appLogger.e('Failed to save servers to storage', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get a specific server by ID
  Future<PlexServer?> getServer(String serverId) async {
    final servers = await getServers();
    try {
      return servers.firstWhere((s) => s.clientIdentifier == serverId);
    } catch (e) {
      return null;
    }
  }

  /// Update server status (called when server connection status changes)
  Future<void> updateServerStatus(String serverId) async {
    final servers = await getServers();
    final serverIndex = servers.indexWhere((s) => s.clientIdentifier == serverId);

    if (serverIndex == -1) {
      appLogger.w('Server not found for status update: $serverId');
      return;
    }

    // Note: PlexServer from auth service doesn't have mutable status fields
    // Status tracking is handled by MultiServerManager
    // This method is kept for future extension if we add status to PlexServer model
  }

  /// Add or update a single server
  Future<void> upsertServer(PlexServer server) async {
    final servers = await getServers();
    final index = servers.indexWhere((s) => s.clientIdentifier == server.clientIdentifier);

    if (index >= 0) {
      servers[index] = server;
      appLogger.d('Updated server: ${server.name}');
    } else {
      servers.add(server);
      appLogger.d('Added new server: ${server.name}');
    }

    await saveServers(servers);
  }

  /// Remove a server
  Future<void> removeServer(String serverId) async {
    final servers = await getServers();
    servers.removeWhere((s) => s.clientIdentifier == serverId);
    await saveServers(servers);

    appLogger.i('Removed server: $serverId');
  }

  /// Clear all servers
  Future<void> clearAllServers() async {
    await _storage.clearServersList();
    appLogger.i('Cleared all servers from registry');
  }

  /// Refresh servers from Plex API and update storage.
  /// This updates connection info (IPs, ports) that may have changed.
  /// Returns [ServerRefreshResult.authError] when the stored token is rejected
  /// (e.g. after removing a Plex profile PIN), so the caller can redirect to re-auth.
  Future<ServerRefreshResult> refreshServersFromApi() async {
    final token = _storage.getPlexToken();
    if (token == null || token.isEmpty) {
      appLogger.d('No Plex token available, skipping server refresh');
      return ServerRefreshResult.noToken;
    }

    try {
      appLogger.d('Refreshing servers from Plex API...');
      final authService = await PlexAuthService.create();
      final freshServers = await authService.fetchServers(token);

      if (freshServers.isEmpty) {
        appLogger.w('API returned no servers, keeping existing data');
        return ServerRefreshResult.success;
      }

      // Get existing servers to preserve any local-only data
      final existingServers = await getServers();
      final existingIds = existingServers.map((s) => s.clientIdentifier).toSet();

      // Update existing servers with fresh connection info, add new ones
      final updatedServers = <PlexServer>[];
      for (final fresh in freshServers) {
        if (existingIds.contains(fresh.clientIdentifier)) {
          // Server exists - use fresh data (updated IPs, connections)
          updatedServers.add(fresh);
        } else {
          // New server - add it
          updatedServers.add(fresh);
          appLogger.i('Discovered new server: ${fresh.name}');
        }
      }

      await saveServers(updatedServers);
      appLogger.i('Refreshed ${updatedServers.length} servers from API');
      return ServerRefreshResult.success;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        appLogger.w('Plex token is invalid (401), re-authentication required');
        return ServerRefreshResult.authError;
      }
      appLogger.w('Failed to refresh servers from API, using cached data', error: e);
      return ServerRefreshResult.networkError;
    } catch (e, stackTrace) {
      appLogger.w('Failed to refresh servers from API, using cached data', error: e, stackTrace: stackTrace);
      return ServerRefreshResult.networkError;
    }
  }
}
