import 'dart:async';

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

  /// Wait briefly for a specific server client to become available.
  ///
  /// This covers first-launch cases where playback can be requested while the
  /// multi-server connection layer is still finishing startup.
  Future<PlexClient> waitForClientForServer(
    String serverId, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final multiServerProvider = Provider.of<MultiServerProvider>(this, listen: false);

    final existing = multiServerProvider.getClientForServer(serverId);
    if (existing != null) {
      return existing;
    }

    appLogger.w('Client for server $serverId not ready, waiting up to ${timeout.inSeconds}s');

    unawaited(multiServerProvider.serverManager.reconnectOfflineServers());

    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final client = multiServerProvider.getClientForServer(serverId);
      if (client != null) {
        return client;
      }

      final remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        break;
      }

      final waitSlice = remaining > const Duration(milliseconds: 500)
          ? const Duration(milliseconds: 500)
          : remaining;

      try {
        await multiServerProvider.serverManager.statusStream.first.timeout(waitSlice);
      } on TimeoutException {
        // No status event yet — poll again until timeout expires.
      }
    }

    appLogger.e('No client found for server $serverId after waiting ${timeout.inSeconds}s');
    throw Exception(t.errors.noClientAvailable);
  }

  /// Get PlexClient for a specific server ID, or null if unavailable.
  PlexClient? tryGetClientForServer(String? serverId) {
    if (serverId == null) return null;
    final multiServerProvider = Provider.of<MultiServerProvider>(this, listen: false);
    return multiServerProvider.getClientForServer(serverId);
  }

  /// Get PlexClient for a library
  /// Throws an exception if no client is available
  PlexClient getClientForLibrary(PlexLibrary library) {
    // If library doesn't have a serverId, fall back to first available server
    if (library.serverId == null) {
      final multiServerProvider = Provider.of<MultiServerProvider>(this, listen: false);
      final serverId = multiServerProvider.onlineServerIds.firstOrNull;
      if (serverId == null) {
        throw Exception(t.errors.noClientAvailable);
      }
      return getClientForServer(serverId);
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

  /// Wait briefly for a metadata-scoped client to become available.
  Future<PlexClient> waitForClientForMetadata(
    PlexMetadata metadata, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (metadata.serverId != null) {
      return waitForClientForServer(metadata.serverId!, timeout: timeout);
    }

    final multiServerProvider = Provider.of<MultiServerProvider>(this, listen: false);
    final existingServerId = multiServerProvider.onlineServerIds.firstOrNull;
    if (existingServerId != null) {
      return getClientForServer(existingServerId);
    }

    appLogger.w('No online server yet for metadata ${metadata.ratingKey}, waiting up to ${timeout.inSeconds}s');
    unawaited(multiServerProvider.serverManager.reconnectOfflineServers());

    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final serverId = multiServerProvider.onlineServerIds.firstOrNull;
      if (serverId != null) {
        return getClientForServer(serverId);
      }

      final remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        break;
      }

      final waitSlice = remaining > const Duration(milliseconds: 500)
          ? const Duration(milliseconds: 500)
          : remaining;

      try {
        await multiServerProvider.serverManager.statusStream.first.timeout(waitSlice);
      } on TimeoutException {
        // No status event yet — poll again until timeout expires.
      }
    }

    throw Exception(t.errors.noClientAvailable);
  }

  /// Get PlexClient for metadata, or null if offline mode or no serverId
  /// Use this for screens that support offline mode
  PlexClient? getClientForMetadataOrNull(PlexMetadata metadata, {bool isOffline = false}) {
    if (isOffline || metadata.serverId == null) {
      return null;
    }
    return tryGetClientForServer(metadata.serverId);
  }

  /// Get the first available client from connected servers
  /// Throws an exception if no servers are available
  PlexClient getFirstAvailableClient() {
    final multiServerProvider = Provider.of<MultiServerProvider>(this, listen: false);
    final serverId = multiServerProvider.onlineServerIds.firstOrNull;
    if (serverId == null) {
      throw Exception(t.errors.noClientAvailable);
    }
    return getClientForServer(serverId);
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
