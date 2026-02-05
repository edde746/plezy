import 'package:flutter/material.dart';
import '../models/plex_friend.dart';
import '../services/plex_auth_service.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';

class FriendsProvider extends ChangeNotifier {
  List<PlexFriend> _friends = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetchTime;

  List<PlexFriend> get friends => _friends;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasFriends => _friends.isNotEmpty;

  PlexAuthService? _authService;
  StorageService? _storageService;

  static const Duration _cacheValidDuration = Duration(minutes: 5);

  Future<void> initialize() async {
    try {
      _authService = await PlexAuthService.create();
      _storageService = await StorageService.getInstance();
    } catch (e) {
      appLogger.e('FriendsProvider: Failed to initialize', error: e);
      _setError('Failed to initialize friends service');
    }
  }

  Future<void> loadFriends({bool forceRefresh = false}) async {
    if (_authService == null || _storageService == null) {
      await initialize();
    }

    // Skip if we have recent data and not forcing refresh
    if (!forceRefresh && _friends.isNotEmpty && _lastFetchTime != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
      if (timeSinceLastFetch < _cacheValidDuration) {
        appLogger.d('FriendsProvider: Using cached friends data');
        return;
      }
    }

    _setLoading(true);
    _clearError();

    try {
      final authToken = _storageService?.getPlexToken();
      if (authToken == null) {
        throw Exception('No auth token available');
      }

      final friends = await _authService!.getFriends(authToken);
      _friends = friends;
      _lastFetchTime = DateTime.now();
      appLogger.d('FriendsProvider: Loaded ${friends.length} friends');
      notifyListeners();
    } catch (e) {
      appLogger.e('FriendsProvider: Failed to load friends', error: e);
      _setError('Failed to load friends');
    } finally {
      _setLoading(false);
    }
  }

  void clearFriends() {
    _friends = [];
    _lastFetchTime = null;
    _clearError();
    notifyListeners();
  }

  PlexFriend? getFriendByUUID(String uuid) {
    try {
      return _friends.firstWhere((friend) => friend.uuid == uuid);
    } catch (e) {
      return null;
    }
  }

  List<PlexFriend> searchFriends(String query) {
    if (query.isEmpty) return _friends;

    final lowerQuery = query.toLowerCase();
    return _friends.where((friend) {
      return friend.displayName.toLowerCase().contains(lowerQuery) ||
          (friend.username?.toLowerCase().contains(lowerQuery) ?? false) ||
          (friend.email?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
