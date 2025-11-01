import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyServerUrl = 'server_url';
  static const String _keyToken = 'token';
  static const String _keyPlexToken = 'plex_token';
  static const String _keyServerData = 'server_data';
  static const String _keyClientId = 'client_identifier';
  static const String _keySelectedLibraryIndex = 'selected_library_index';
  static const String _keyLibraryFilters = 'library_filters';
  static const String _keyUserProfile = 'user_profile';
  static const String _keyCurrentUserUUID = 'current_user_uuid';
  static const String _keyHomeUsersCache = 'home_users_cache';
  static const String _keyHomeUsersCacheExpiry = 'home_users_cache_expiry';

  static StorageService? _instance;
  late SharedPreferences _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Server URL
  Future<void> saveServerUrl(String url) async {
    await _prefs.setString(_keyServerUrl, url);
  }

  String? getServerUrl() {
    return _prefs.getString(_keyServerUrl);
  }

  // Server Access Token
  Future<void> saveToken(String token) async {
    await _prefs.setString(_keyToken, token);
  }

  String? getToken() {
    return _prefs.getString(_keyToken);
  }

  // Alias for server access token for clarity
  Future<void> saveServerAccessToken(String token) async {
    await saveToken(token);
  }

  String? getServerAccessToken() {
    return getToken();
  }

  // Plex.tv Token (for API access)
  Future<void> savePlexToken(String token) async {
    await _prefs.setString(_keyPlexToken, token);
  }

  String? getPlexToken() {
    return _prefs.getString(_keyPlexToken);
  }

  // Server Data (full PlexServer object as JSON)
  Future<void> saveServerData(Map<String, dynamic> serverJson) async {
    final jsonString = json.encode(serverJson);
    await _prefs.setString(_keyServerData, jsonString);
  }

  Map<String, dynamic>? getServerData() {
    final jsonString = _prefs.getString(_keyServerData);
    if (jsonString == null) return null;

    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // Client Identifier
  Future<void> saveClientIdentifier(String clientId) async {
    await _prefs.setString(_keyClientId, clientId);
  }

  String? getClientIdentifier() {
    return _prefs.getString(_keyClientId);
  }

  // Save all credentials at once
  Future<void> saveCredentials({
    required String serverUrl,
    required String token,
    required String clientIdentifier,
  }) async {
    await Future.wait([
      saveServerUrl(serverUrl),
      saveToken(token),
      saveClientIdentifier(clientIdentifier),
    ]);
  }

  // Check if credentials exist
  bool hasCredentials() {
    return getServerUrl() != null && getToken() != null;
  }

  // Clear all credentials
  Future<void> clearCredentials() async {
    await Future.wait([
      _prefs.remove(_keyServerUrl),
      _prefs.remove(_keyToken),
      _prefs.remove(_keyPlexToken),
      _prefs.remove(_keyServerData),
      _prefs.remove(_keyClientId),
      _prefs.remove(_keyUserProfile),
      _prefs.remove(_keyCurrentUserUUID),
      _prefs.remove(_keyHomeUsersCache),
      _prefs.remove(_keyHomeUsersCacheExpiry),
    ]);
  }

  // Get all credentials as a map
  Map<String, String?> getCredentials() {
    return {
      'serverUrl': getServerUrl(),
      'token': getToken(),
      'clientIdentifier': getClientIdentifier(),
    };
  }

  // Selected Library Index
  Future<void> saveSelectedLibraryIndex(int index) async {
    await _prefs.setInt(_keySelectedLibraryIndex, index);
  }

  int? getSelectedLibraryIndex() {
    return _prefs.getInt(_keySelectedLibraryIndex);
  }

  // Library Filters (stored as JSON string)
  Future<void> saveLibraryFilters(Map<String, String> filters) async {
    final jsonString = json.encode(filters);
    await _prefs.setString(_keyLibraryFilters, jsonString);
  }

  Map<String, String> getLibraryFilters() {
    final jsonString = _prefs.getString(_keyLibraryFilters);
    if (jsonString == null) return {};

    try {
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      return {};
    }
  }

  // Clear library preferences
  Future<void> clearLibraryPreferences() async {
    await Future.wait([
      _prefs.remove(_keySelectedLibraryIndex),
      _prefs.remove(_keyLibraryFilters),
    ]);
  }

  // User Profile (stored as JSON string)
  Future<void> saveUserProfile(Map<String, dynamic> profileJson) async {
    final jsonString = json.encode(profileJson);
    await _prefs.setString(_keyUserProfile, jsonString);
  }

  Map<String, dynamic>? getUserProfile() {
    final jsonString = _prefs.getString(_keyUserProfile);
    if (jsonString == null) return null;

    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // Current User UUID
  Future<void> saveCurrentUserUUID(String uuid) async {
    await _prefs.setString(_keyCurrentUserUUID, uuid);
  }

  String? getCurrentUserUUID() {
    return _prefs.getString(_keyCurrentUserUUID);
  }

  // Home Users Cache (stored as JSON string with expiry)
  Future<void> saveHomeUsersCache(Map<String, dynamic> homeData) async {
    final jsonString = json.encode(homeData);
    await _prefs.setString(_keyHomeUsersCache, jsonString);

    // Set cache expiry to 1 hour from now
    final expiry = DateTime.now()
        .add(const Duration(hours: 1))
        .millisecondsSinceEpoch;
    await _prefs.setInt(_keyHomeUsersCacheExpiry, expiry);
  }

  Map<String, dynamic>? getHomeUsersCache() {
    final expiry = _prefs.getInt(_keyHomeUsersCacheExpiry);
    if (expiry == null || DateTime.now().millisecondsSinceEpoch > expiry) {
      // Cache expired, clear it
      clearHomeUsersCache();
      return null;
    }

    final jsonString = _prefs.getString(_keyHomeUsersCache);
    if (jsonString == null) return null;

    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<void> clearHomeUsersCache() async {
    await Future.wait([
      _prefs.remove(_keyHomeUsersCache),
      _prefs.remove(_keyHomeUsersCacheExpiry),
    ]);
  }

  // Clear current user UUID (for server switching)
  Future<void> clearCurrentUserUUID() async {
    await _prefs.remove(_keyCurrentUserUUID);
  }

  // Clear all user-related data (for logout)
  Future<void> clearUserData() async {
    await Future.wait([clearCredentials(), clearLibraryPreferences()]);
  }

  // Update current user after switching
  Future<void> updateCurrentUser(String userUUID, String authToken) async {
    await Future.wait([
      saveCurrentUserUUID(userUUID),
      saveToken(authToken), // Update the main token
    ]);
  }
}
