import 'dart:convert';

import '../utils/app_logger.dart';
import 'plex_auth_service.dart';
import 'storage_service.dart';

/// Centralized server configuration registry
/// Manages which servers are available, enabled/disabled, and their configurations
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
      return serversList
          .map((json) => PlexServer.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      appLogger.e(
        'Failed to load servers from storage',
        error: e,
        stackTrace: stackTrace,
      );
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
      appLogger.e(
        'Failed to save servers to storage',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get enabled server IDs
  Future<Set<String>> getEnabledServerIds() async {
    try {
      final enabledJson = _storage.getEnabledServersJson();
      if (enabledJson == null || enabledJson.isEmpty) {
        // If no enabled servers are stored, all servers are enabled by default
        final servers = await getServers();
        return servers.map((s) => s.clientIdentifier).toSet();
      }

      final List<dynamic> enabledList = jsonDecode(enabledJson);
      return enabledList.cast<String>().toSet();
    } catch (e, stackTrace) {
      appLogger.e(
        'Failed to load enabled servers from storage',
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  /// Save enabled server IDs
  Future<void> saveEnabledServerIds(Set<String> serverIds) async {
    try {
      final enabledJson = jsonEncode(serverIds.toList());
      await _storage.saveEnabledServersJson(enabledJson);
      appLogger.d('Saved ${serverIds.length} enabled servers to storage');
    } catch (e, stackTrace) {
      appLogger.e(
        'Failed to save enabled servers to storage',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get only enabled servers
  Future<List<PlexServer>> getEnabledServers() async {
    final servers = await getServers();
    final enabledIds = await getEnabledServerIds();

    if (enabledIds.isEmpty) {
      // If no enabled list, all servers are enabled
      return servers;
    }

    return servers
        .where((s) => enabledIds.contains(s.clientIdentifier))
        .toList();
  }

  /// Enable a server
  Future<void> enableServer(String serverId) async {
    final enabledIds = await getEnabledServerIds();
    enabledIds.add(serverId);
    await saveEnabledServerIds(enabledIds);
    appLogger.i('Enabled server: $serverId');
  }

  /// Disable a server
  Future<void> disableServer(String serverId) async {
    final enabledIds = await getEnabledServerIds();
    enabledIds.remove(serverId);
    await saveEnabledServerIds(enabledIds);
    appLogger.i('Disabled server: $serverId');
  }

  /// Check if a server is enabled
  Future<bool> isServerEnabled(String serverId) async {
    final enabledIds = await getEnabledServerIds();
    return enabledIds.contains(serverId);
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
  Future<void> updateServerStatus(
    String serverId, {
    bool? online,
    DateTime? lastSeen,
  }) async {
    final servers = await getServers();
    final serverIndex = servers.indexWhere(
      (s) => s.clientIdentifier == serverId,
    );

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
    final index = servers.indexWhere(
      (s) => s.clientIdentifier == server.clientIdentifier,
    );

    if (index >= 0) {
      servers[index] = server;
      appLogger.d('Updated server: ${server.name}');
    } else {
      servers.add(server);
      appLogger.d('Added new server: ${server.name}');
    }

    await saveServers(servers);

    // Ensure new servers are enabled by default
    if (index < 0) {
      await enableServer(server.clientIdentifier);
    }
  }

  /// Remove a server
  Future<void> removeServer(String serverId) async {
    final servers = await getServers();
    servers.removeWhere((s) => s.clientIdentifier == serverId);
    await saveServers(servers);

    // Also remove from enabled list
    final enabledIds = await getEnabledServerIds();
    enabledIds.remove(serverId);
    await saveEnabledServerIds(enabledIds);

    appLogger.i('Removed server: $serverId');
  }

  /// Clear all servers
  Future<void> clearAllServers() async {
    await _storage.clearServersList();
    await _storage.clearEnabledServers();
    appLogger.i('Cleared all servers from registry');
  }

  /// Migrate from single server storage to multi-server
  /// This is called during app startup to migrate existing users
  Future<void> migrateFromSingleServer() async {
    try {
      // Check if we already have servers in the new format
      final existingServers = await getServers();
      if (existingServers.isNotEmpty) {
        appLogger.d('Servers already migrated, skipping migration');
        return;
      }

      // Try to load old single-server data
      final oldServerData = _storage.getServerData();
      if (oldServerData == null) {
        appLogger.d('No old server data to migrate');
        return;
      }

      // Parse and migrate
      final server = PlexServer.fromJson(oldServerData);

      appLogger.i('Migrating single server to multi-server: ${server.name}');

      // Save as first server in new format
      await saveServers([server]);
      await enableServer(server.clientIdentifier);

      appLogger.i('Migration complete');
    } catch (e, stackTrace) {
      appLogger.e(
        'Failed to migrate from single server',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't rethrow - migration failure shouldn't crash the app
    }
  }
}
