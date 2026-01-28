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

  UserProfileProvider watchUserProfile() => Provider.of<UserProfileProvider>(this, listen: true);

  HiddenLibrariesProvider get hiddenLibraries => Provider.of<HiddenLibrariesProvider>(this, listen: false);

  HiddenLibrariesProvider watchHiddenLibraries() => Provider.of<HiddenLibrariesProvider>(this, listen: true);

  // Direct profile settings access (nullable)
  PlexUserProfile? get profileSettings => userProfile.profileSettings;

  /// Get PlexClient for a specific server ID
  /// Throws an exception if no client is available for the given serverId
  PlexClient getClientForServer(String serverId) {
    final multiServerProvider = Provider.of<MultiServerProvider>(this, listen: false);

    final serverClient = multiServerProvider.getClientForServer(serverId);

    if (serverClient == null) {
      appLogger.e('No client found for server $serverId');
      throw Exception(t.errors.noClientAvailable);
    }

    return serverClient;
  }

  /// Get PlexClient for a library
  /// Throws an exception if no client is available
  PlexClient getClientForLibrary(PlexLibrary library) {
    // If library doesn't have a serverId, fall back to first available server
    if (library.serverId == null) {
      final multiServerProvider = Provider.of<MultiServerProvider>(this, listen: false);
      if (!multiServerProvider.hasConnectedServers) {
        throw Exception(t.errors.noClientAvailable);
      }
      return getClientForServer(multiServerProvider.onlineServerIds.first);
    }
    return getClientForServer(library.serverId!);
  }

  /// Get PlexClient for metadata, with fallback to first available server
  /// Throws an exception if no servers are available
  PlexClient getClientForMetadata(PlexMetadata metadata) {
    if (metadata.serverId != null) {
      return getClientForServer(metadata.serverId!);
    }
    return getFirstAvailableClient();
  }

  /// Get PlexClient for metadata, or null if offline mode or no serverId
  /// Use this for screens that support offline mode
  PlexClient? getClientForMetadataOrNull(PlexMetadata metadata, {bool isOffline = false}) {
    if (isOffline || metadata.serverId == null) {
      return null;
    }
    return getClientForServer(metadata.serverId!);
  }

  /// Get the first available client from connected servers
  /// Throws an exception if no servers are available
  PlexClient getFirstAvailableClient() {
    final multiServerProvider = Provider.of<MultiServerProvider>(this, listen: false);
    if (!multiServerProvider.hasConnectedServers) {
      throw Exception(t.errors.noClientAvailable);
    }
    return getClientForServer(multiServerProvider.onlineServerIds.first);
  }

  /// Get client for a serverId with fallback to first available server
  /// Useful for items that might not have a serverId
  PlexClient getClientWithFallback(String? serverId) {
    if (serverId != null) {
      return getClientForServer(serverId);
    }
    return getFirstAvailableClient();
  }
}
