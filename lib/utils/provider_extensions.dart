import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/plex_client.dart';
import '../i18n/strings.g.dart';
import '../models/plex_library.dart';
import '../models/plex_metadata.dart';
import '../models/plex_user_profile.dart';
import '../providers/hidden_libraries_provider.dart';
import '../providers/multi_server_provider.dart';
import '../providers/user_profile_provider.dart';
import 'app_logger.dart';

extension ProviderExtensions on BuildContext {
  UserProfileProvider get userProfile => Provider.of<UserProfileProvider>(this, listen: false);

  HiddenLibrariesProvider get hiddenLibraries => Provider.of<HiddenLibrariesProvider>(this, listen: false);

  // Direct profile settings access (nullable)
  PlexUserProfile? get profileSettings => userProfile.profileSettings;

  /// Internal: resolve a [PlexClient] from a serverId or fall back to the
  /// first online server. Returns null if neither yields a client.
  PlexClient? _resolveClient(String? serverId) {
    final provider = Provider.of<MultiServerProvider>(this, listen: false);
    if (serverId != null) {
      final client = provider.getClientForServer(serverId);
      if (client != null) return client;
    }
    final fallbackId = provider.onlineServerIds.firstOrNull;
    if (fallbackId == null) return null;
    return provider.getClientForServer(fallbackId);
  }

  /// Internal: like [_resolveClient] but throws a localized exception when
  /// no client is available. The thrown message is the canonical
  /// `t.errors.noClientAvailable` so callers can surface it directly.
  PlexClient _requireClient(String? serverId, {bool fallback = true}) {
    final provider = Provider.of<MultiServerProvider>(this, listen: false);
    if (serverId != null) {
      final client = provider.getClientForServer(serverId);
      if (client != null) return client;
      if (!fallback) {
        appLogger.e('No client found for server $serverId');
        throw Exception(t.errors.noClientAvailable);
      }
    }
    final fallbackId = provider.onlineServerIds.firstOrNull;
    final client = fallbackId == null ? null : provider.getClientForServer(fallbackId);
    if (client == null) {
      throw Exception(t.errors.noClientAvailable);
    }
    return client;
  }

  /// Get PlexClient for a specific server ID. Throws if unavailable.
  PlexClient getClientForServer(String serverId) => _requireClient(serverId, fallback: false);

  /// Get PlexClient for a specific server ID, or null if unavailable.
  PlexClient? tryGetClientForServer(String? serverId) {
    if (serverId == null) return null;
    final provider = Provider.of<MultiServerProvider>(this, listen: false);
    return provider.getClientForServer(serverId);
  }

  /// Get PlexClient for a library, falling back to the first online server
  /// when the library has no serverId. Throws if no client is available.
  PlexClient getClientForLibrary(PlexLibrary library) => _requireClient(library.serverId);

  /// Get PlexClient for metadata, falling back to the first online server.
  /// Throws if no client is available.
  PlexClient getClientForMetadata(PlexMetadata metadata) => _requireClient(metadata.serverId);

  /// Get PlexClient for metadata, or null in offline mode / when no serverId.
  PlexClient? getClientForMetadataOrNull(PlexMetadata metadata, {bool isOffline = false}) {
    if (isOffline) return null;
    return tryGetClientForServer(metadata.serverId);
  }

  /// Get the first online server's client. Throws if none available.
  PlexClient getFirstAvailableClient() => _requireClient(null);

  /// Get the first online server's client, or null.
  PlexClient? tryGetFirstAvailableClient() => _resolveClient(null);

  /// Get client for a serverId, falling back to the first online server.
  /// Throws if no client is available.
  PlexClient getClientWithFallback(String? serverId) => _requireClient(serverId);
}
