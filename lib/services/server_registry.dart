import 'dart:convert';

import '../utils/app_logger.dart';
import 'plex_auth_service.dart';
import 'storage_service.dart';

/// Per-Plex-account servers list, persisted as JSON in [StorageService].
///
/// Historically this was the single source of truth for "the user's Plex
/// servers". The new pipeline stores servers on
/// [PlexAccountConnection.servers] in [ConnectionRegistry] instead, so the
/// only remaining responsibility here is reading the legacy list during
/// the one-shot bootstrap migration in [ConnectionBootstrap].
class ServerRegistry {
  final StorageService _storage;

  ServerRegistry(this._storage);

  /// Read the legacy servers list from storage. Returns an empty list when
  /// there is no legacy data (post-migration installs and fresh installs).
  ///
  /// Called only by [ConnectionBootstrap.migrateLegacyPlexAccount].
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
}
