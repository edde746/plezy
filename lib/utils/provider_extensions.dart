import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/plex_client.dart';
import '../i18n/strings.g.dart';
import '../models/plex_library.dart';
import '../models/plex_user_profile.dart';
import '../providers/hidden_libraries_provider.dart';
import '../providers/multi_server_provider.dart';
import '../providers/plex_client_provider.dart';
import '../providers/user_profile_provider.dart';
import 'app_logger.dart';

extension ProviderExtensions on BuildContext {
  PlexClientProvider get plexClient =>
      Provider.of<PlexClientProvider>(this, listen: false);

  UserProfileProvider get userProfile =>
      Provider.of<UserProfileProvider>(this, listen: false);

  PlexClientProvider watchPlexClient() =>
      Provider.of<PlexClientProvider>(this, listen: true);

  UserProfileProvider watchUserProfile() =>
      Provider.of<UserProfileProvider>(this, listen: true);

  HiddenLibrariesProvider get hiddenLibraries =>
      Provider.of<HiddenLibrariesProvider>(this, listen: false);

  HiddenLibrariesProvider watchHiddenLibraries() =>
      Provider.of<HiddenLibrariesProvider>(this, listen: true);

  // Direct profile settings access (nullable)
  PlexUserProfile? get profileSettings => userProfile.profileSettings;

  /// Get PlexClient for a specific server ID
  /// Throws an exception if no client is available for the given serverId
  PlexClient getClientForServer(String serverId) {
    final multiServerProvider = Provider.of<MultiServerProvider>(
      this,
      listen: false,
    );

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
      final multiServerProvider = Provider.of<MultiServerProvider>(
        this,
        listen: false,
      );
      if (!multiServerProvider.hasConnectedServers) {
        throw Exception(t.errors.noClientAvailable);
      }
      return getClientForServer(multiServerProvider.onlineServerIds.first);
    }
    return getClientForServer(library.serverId!);
  }
}
