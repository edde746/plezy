import 'package:flutter/material.dart';
import '../models/plex_home.dart';
import '../models/plex_home_user.dart';
import '../models/plex_user_profile.dart';
import '../services/plex_auth_service.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';
import '../utils/provider_extensions.dart';
import 'plex_client_provider.dart';

class UserProfileProvider extends ChangeNotifier {
  PlexHome? _home;
  PlexHomeUser? _currentUser;
  PlexUserProfile? _profileSettings;
  bool _isLoading = false;
  String? _error;

  PlexHome? get home => _home;
  PlexHomeUser? get currentUser => _currentUser;
  PlexUserProfile? get profileSettings => _profileSettings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMultipleUsers {
    final result = _home?.hasMultipleUsers ?? false;
    appLogger.d(
      'hasMultipleUsers: _home=${_home != null}, users count=${_home?.users.length ?? 0}, result=$result',
    );
    return result;
  }

  PlexAuthService? _authService;
  StorageService? _storageService;

  // Callback for data invalidation when switching profiles
  VoidCallback? _onDataInvalidationRequested;

  /// Set a callback to be called when profile switching requires data invalidation
  void setDataInvalidationCallback(VoidCallback? callback) {
    _onDataInvalidationRequested = callback;
  }

  /// Trigger data invalidation for all screens
  void _invalidateAllData() {
    if (_onDataInvalidationRequested != null) {
      _onDataInvalidationRequested!();
      appLogger.d('Data invalidation triggered for profile switch');
    }
  }

  Future<void> initialize() async {
    appLogger.d('UserProfileProvider: Initializing...');
    try {
      _authService = await PlexAuthService.create();
      _storageService = await StorageService.getInstance();
      await _loadCachedData();

      // If no cached home data or it's expired, try to load from API
      if (_home == null) {
        appLogger.d(
          'UserProfileProvider: No cached home data, attempting to load from API',
        );
        try {
          await loadHomeUsers();
        } catch (e) {
          appLogger.w(
            'UserProfileProvider: Failed to load home users during initialization',
            error: e,
          );
          // Don't set error here as it's not critical for app startup
        }
      }

      // Fetch fresh profile settings from API
      appLogger.d('UserProfileProvider: Fetching profile settings from API');
      try {
        await refreshProfileSettings();
      } catch (e) {
        appLogger.w(
          'UserProfileProvider: Failed to fetch profile settings during initialization',
          error: e,
        );
        // Don't set error here, cached profile (if any) was already loaded
      }

      appLogger.d('UserProfileProvider: Initialization complete');
    } catch (e) {
      appLogger.e(
        'UserProfileProvider: Critical initialization failure',
        error: e,
      );
      _setError('Failed to initialize profile services');
      // Ensure services are null on failure
      _authService = null;
      _storageService = null;
    }
  }

  Future<void> _loadCachedData() async {
    if (_storageService == null) return;

    // Load cached home users
    final cachedHomeData = _storageService!.getHomeUsersCache();
    if (cachedHomeData != null) {
      try {
        _home = PlexHome.fromJson(cachedHomeData);
      } catch (e) {
        appLogger.w('Failed to load cached home data', error: e);
      }
    }

    // Load current user UUID
    final currentUserUUID = _storageService!.getCurrentUserUUID();
    if (currentUserUUID != null && _home != null) {
      _currentUser = _home!.getUserByUUID(currentUserUUID);
    }

    // Profile settings are NOT cached - they will be fetched fresh from API
    // in refreshProfileSettings()

    notifyListeners();
  }

  /// Fetch the user's profile settings from the API
  Future<void> refreshProfileSettings() async {
    if (_authService == null || _storageService == null) {
      appLogger.w('refreshProfileSettings: Services not initialized, skipping');
      return;
    }

    appLogger.d('Fetching user profile settings from Plex API');
    try {
      final currentToken = _storageService!.getPlexToken();
      if (currentToken == null) {
        appLogger.w(
          'refreshProfileSettings: No Plex token available, cannot fetch profile',
        );
        return;
      }

      final profile = await _authService!.getUserProfile(currentToken);
      _profileSettings = profile;

      appLogger.i('Successfully fetched user profile settings from API');

      notifyListeners();
    } catch (e) {
      appLogger.w('Failed to fetch user profile settings from API', error: e);
      // Don't set error state, profile will remain null or keep existing value
    }
  }

  Future<void> loadHomeUsers({bool forceRefresh = false}) async {
    appLogger.d('loadHomeUsers called - forceRefresh: $forceRefresh');

    // Auto-initialize services if not ready
    if (_authService == null || _storageService == null) {
      appLogger.d(
        'loadHomeUsers: Services not initialized, initializing services...',
      );
      _authService = await PlexAuthService.create();
      _storageService = await StorageService.getInstance();
      await _loadCachedData();

      // Double-check after initialization
      if (_authService == null || _storageService == null) {
        appLogger.e('loadHomeUsers: Failed to initialize services');
        _setError('Failed to initialize services');
        return;
      }
    }

    // Use cached data if available and not forcing refresh
    if (!forceRefresh && _home != null) {
      appLogger.d(
        'loadHomeUsers: Using cached data, users count: ${_home!.users.length}',
      );
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final currentToken = _storageService!.getPlexToken();
      if (currentToken == null) {
        throw Exception('No Plex.tv authentication token available');
      }
      appLogger.d('loadHomeUsers: Using Plex.tv token');

      appLogger.d('loadHomeUsers: Fetching home users from API');
      final home = await _authService!.getHomeUsers(currentToken);
      _home = home;

      appLogger.i(
        'loadHomeUsers: Success! Home users count: ${home.users.length}',
      );
      appLogger.d(
        'loadHomeUsers: Users: ${home.users.map((u) => u.displayName).join(', ')}',
      );

      // Cache the home data
      await _storageService!.saveHomeUsersCache(home.toJson());

      // Set current user if not already set
      if (_currentUser == null) {
        final currentUserUUID = _storageService!.getCurrentUserUUID();
        if (currentUserUUID != null) {
          _currentUser = home.getUserByUUID(currentUserUUID);
          appLogger.d(
            'loadHomeUsers: Set current user from UUID: ${_currentUser?.displayName}',
          );
        } else {
          // Default to admin user if no current user set
          _currentUser = home.adminUser;
          if (_currentUser != null) {
            await _storageService!.saveCurrentUserUUID(_currentUser!.uuid);
            appLogger.d(
              'loadHomeUsers: Set current user to admin: ${_currentUser?.displayName}',
            );
          }
        }
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to load home users: $e');
      appLogger.e('Failed to load home users', error: e);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> switchToUser(PlexHomeUser user, BuildContext? context) async {
    if (_authService == null || _storageService == null) {
      _setError('Services not initialized');
      return false;
    }

    if (user.uuid == _currentUser?.uuid) {
      // Already on this user
      return true;
    }

    // Extract client provider before async operations
    PlexClientProvider? clientProvider;
    if (context != null) {
      try {
        clientProvider = context.plexClient;
      } catch (e) {
        appLogger.w('Failed to get PlexClientProvider', error: e);
      }
    }

    _setLoading(true);
    _clearError();

    try {
      final currentToken = _storageService!.getPlexToken();
      if (currentToken == null) {
        throw Exception('No Plex.tv authentication token available');
      }

      final switchResponse = await _authService!.switchToUser(
        user.uuid,
        currentToken,
      );

      // switchResponse.authToken is the new user's Plex.tv token
      // We need to fetch servers with this token to get the proper server access token
      appLogger.d('Got new user Plex.tv token, fetching servers...');

      final servers = await _authService!.fetchServers(
        switchResponse.authToken,
      );
      if (servers.isEmpty) {
        throw Exception('No servers available for this user');
      }

      // Find the current server from storage
      final currentServerData = _storageService!.getServerData();
      if (currentServerData == null) {
        throw Exception('No current server data found');
      }

      // Find matching server by name or client identifier
      final currentServerName = currentServerData['name'] as String?;
      final currentServerClientId =
          currentServerData['clientIdentifier'] as String?;

      final matchingServer = servers.firstWhere(
        (server) =>
            server.name == currentServerName ||
            server.clientIdentifier == currentServerClientId,
        orElse: () => servers.first, // Fallback to first server
      );

      appLogger.d(
        'Found matching server: ${matchingServer.name}, getting access token',
      );

      // Update storage with new tokens
      await _storageService!.updateCurrentUser(
        user.uuid,
        matchingServer
            .accessToken, // Use server access token, not Plex.tv token
      );

      // Also save the new Plex.tv token for future profile operations
      await _storageService!.savePlexToken(switchResponse.authToken);

      // Update current user
      _currentUser = user;

      // Update user profile settings (fresh from API)
      _profileSettings = switchResponse.profile;
      appLogger.d(
        'Updated profile settings for user: ${user.displayName}',
        error: {
          'defaultAudioLanguage':
              _profileSettings?.defaultAudioLanguage ?? 'not set',
          'defaultSubtitleLanguage':
              _profileSettings?.defaultSubtitleLanguage ?? 'not set',
        },
      );

      // Update PlexClient with proper server access token
      if (clientProvider != null) {
        try {
          clientProvider.updateToken(matchingServer.accessToken);
          appLogger.d(
            'Updated PlexClient with server access token for user: ${user.displayName}',
          );
        } catch (e) {
          appLogger.w('Failed to update PlexClient token', error: e);
        }
      }

      notifyListeners();

      // Invalidate all cached data for the new profile
      // This will cause screens to refresh and rebuild widgets with the new token
      _invalidateAllData();

      appLogger.d(
        'Profile switch complete, all data and images should refresh with new token',
      );

      appLogger.i('Successfully switched to user: ${user.displayName}');
      return true;
    } catch (e) {
      _setError('Failed to switch user: $e');
      appLogger.e('Failed to switch to user: ${user.displayName}', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshCurrentUser() async {
    if (_currentUser != null) {
      await loadHomeUsers(forceRefresh: true);

      // Update current user from refreshed data
      if (_home != null) {
        _currentUser = _home!.getUserByUUID(_currentUser!.uuid);
        notifyListeners();
      }
    }
  }

  Future<void> logout() async {
    if (_storageService == null) return;

    _setLoading(true);

    try {
      await _storageService!.clearUserData();

      // Clear user-specific provider state but keep services for future sign-ins
      _home = null;
      _currentUser = null;
      _profileSettings = null;
      _onDataInvalidationRequested = null;

      _clearError();
      notifyListeners();

      appLogger.i('User logged out successfully');
    } catch (e) {
      appLogger.e('Error during logout', error: e);
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh provider for new server context
  /// Call this when switching servers to ensure provider state is synchronized
  Future<void> refreshForNewServer([BuildContext? context]) async {
    appLogger.d('UserProfileProvider: Refreshing for new server context');

    _setLoading(true);

    try {
      // Clear cached data from previous server (both memory and storage)
      _home = null;
      _currentUser = null;
      _profileSettings = null;
      _clearError();

      // Re-initialize services with current storage state
      _authService = await PlexAuthService.create();
      _storageService = await StorageService.getInstance();

      // Clear storage state that's specific to the previous server context
      await Future.wait([
        // Clear home users cache (server-specific)
        _storageService!.clearHomeUsersCache(),
        // Clear current user UUID (profile-specific, should not persist across servers)
        _storageService!.clearCurrentUserUUID(),
      ]);

      appLogger.d('UserProfileProvider: Cleared previous server storage state');

      // Load fresh data for the new server (should be empty after clearing cache)
      await _loadCachedData();

      // Load from API since we cleared the cache
      appLogger.d(
        'UserProfileProvider: Loading fresh home users for new server',
      );

      // Store context reference before async operations to avoid build context warnings
      final contextForSwitch = context;

      try {
        await loadHomeUsers();

        // After loading home users, if a current user was set (admin user),
        // perform a complete profile switch to ensure tokens are properly updated
        if (_currentUser != null && contextForSwitch != null) {
          appLogger.d(
            'UserProfileProvider: Performing complete profile switch to ${_currentUser!.displayName} for new server',
          );

          // Perform full profile switch which includes API calls and token updates
          final userToSwitchTo = _currentUser!;
          // ignore: use_build_context_synchronously
          final success = await switchToUser(userToSwitchTo, contextForSwitch);

          if (success) {
            appLogger.d(
              'UserProfileProvider: Successfully switched to admin user for new server',
            );
          } else {
            appLogger.w(
              'UserProfileProvider: Failed to complete profile switch for new server',
            );
          }
        } else if (_currentUser != null && contextForSwitch == null) {
          appLogger.w(
            'UserProfileProvider: Cannot perform complete profile switch - no context provided',
          );
          // Still try to fetch profile settings even without full switch
          try {
            await refreshProfileSettings();
          } catch (e) {
            appLogger.w(
              'UserProfileProvider: Failed to refresh profile settings for new server',
              error: e,
            );
          }
        }
      } catch (e) {
        appLogger.w(
          'UserProfileProvider: Failed to load home users for new server',
          error: e,
        );
        // Don't set error as it's not critical
      }

      appLogger.d('UserProfileProvider: Refresh for new server complete');
    } catch (e) {
      appLogger.e(
        'UserProfileProvider: Failed to refresh for new server',
        error: e,
      );
      _setError('Failed to refresh for new server');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
