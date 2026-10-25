import 'dart:async';

import '../connection/connection_registry.dart';
import '../profiles/active_plex_token.dart';
import '../profiles/active_profile_provider.dart';
import '../profiles/profile_connection_registry.dart';
import '../utils/app_logger.dart';
import 'home_layout_sync_service.dart';

/// Hands [HomeLayoutSyncService] the active profile's own Plex token whenever
/// the profile settles (startup, a switch, a freshly minted Home-user token),
/// and null for a profile without one (Jellyfin-only, not yet minted).
///
/// Home profiles never fall back to the owner's token: the layout is stored
/// on the account that token belongs to, and the owner's copy is not this
/// profile's layout.
class HomeLayoutSyncBinder {
  HomeLayoutSyncBinder({
    required ActiveProfileProvider activeProfile,
    required ConnectionRegistry connections,
    required ProfileConnectionRegistry profileConnections,
  }) : this._(activeProfile, connections, profileConnections);

  HomeLayoutSyncBinder._(this._activeProfile, this._connections, this._profileConnections) {
    _activeProfile.addListener(_onProfileChanged);
    _onProfileChanged();
  }

  final ActiveProfileProvider _activeProfile;
  final ConnectionRegistry _connections;
  final ProfileConnectionRegistry _profileConnections;
  int _generation = 0;
  bool _disposed = false;

  void _onProfileChanged() {
    if (_disposed || _activeProfile.isBinding) return;
    final generation = ++_generation;
    unawaited(() async {
      try {
        final resolved = await resolveActivePlexToken(
          activeProfile: _activeProfile,
          connections: _connections,
          profileConnections: _profileConnections,
          allowAccountTokenForHomeUser: false,
        );
        if (_disposed || generation != _generation) return;
        HomeLayoutSyncService.instance.bind(resolved?.token);
      } catch (e, s) {
        appLogger.w('HomeLayoutSync: token resolve failed', error: e, stackTrace: s);
      }
    }());
  }

  void dispose() {
    _disposed = true;
    _activeProfile.removeListener(_onProfileChanged);
  }
}
