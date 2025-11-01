import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plex_client_provider.dart';
import '../providers/user_profile_provider.dart';
import '../client/plex_client.dart';
import '../models/plex_user_profile.dart';

extension ProviderExtensions on BuildContext {
  PlexClientProvider get plexClient =>
      Provider.of<PlexClientProvider>(this, listen: false);

  UserProfileProvider get userProfile =>
      Provider.of<UserProfileProvider>(this, listen: false);

  PlexClientProvider watchPlexClient() =>
      Provider.of<PlexClientProvider>(this, listen: true);

  UserProfileProvider watchUserProfile() =>
      Provider.of<UserProfileProvider>(this, listen: true);

  // Direct client access (nullable)
  PlexClient? get client => plexClient.client;

  // Null-safe client access
  PlexClient get clientSafe => plexClient.client!;

  // Direct profile settings access (nullable)
  PlexUserProfile? get profileSettings => userProfile.profileSettings;
}
