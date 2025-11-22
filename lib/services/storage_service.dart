import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../utils/log_redaction_manager.dart';

class StorageService {
  static const String _keyServerUrl = 'server_url';
  static const String _keyToken = 'token';
  static const String _keyPlexToken = 'plex_token';
  static const String _keyServerData = 'server_data';
  static const String _keyClientId = 'client_identifier';
  static const String _keySelectedLibraryIndex = 'selected_library_index';
  static const String _keySelectedLibraryKey = 'selected_library_key';
  static const String _keyLibraryFilters = 'library_filters';
  static const String _keyLibraryOrder = 'library_order';
  static const String _keyUserProfile = 'user_profile';
  static const String _keyCurrentUserUUID = 'current_user_uuid';
  static const String _keyHomeUsersCache = 'home_users_cache';
  static const String _keyHomeUsersCacheExpiry = 'home_users_cache_expiry';
  static const String _keyHiddenLibraries = 'hidden_libraries';
  static const String _keyServersList = 'servers_list';
  static const String _keyEnabledServers = 'enabled_servers';
  static const String _keyServerOrder = 'server_order';

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
    // Seed known values so logs can redact immediately on startup.
    LogRedactionManager.registerServerUrl(getServerUrl());
    LogRedactionManager.registerToken(getToken());
    LogRedactionManager.registerToken(getPlexToken());
  }

  // Server URL
  Future<void> saveServerUrl(String url) async {
    await _prefs.setString(_keyServerUrl, url);
    LogRedactionManager.registerServerUrl(url);
  }

  String? getServerUrl() {
    return _prefs.getString(_keyServerUrl);
  }

  // Per-Server Endpoint URL (for multi-server connection caching)
  Future<void> saveServerEndpoint(String serverId, String url) async {
    await _prefs.setString('server_endpoint_$serverId', url);
    LogRedactionManager.registerServerUrl(url);
  }

  String? getServerEndpoint(String serverId) {
    return _prefs.getString('server_endpoint_$serverId');
  }

  Future<void> clearServerEndpoint(String serverId) async {
    await _prefs.remove('server_endpoint_$serverId');
  }

  // Server Access Token
  Future<void> saveToken(String token) async {
    await _prefs.setString(_keyToken, token);
    LogRedactionManager.registerToken(token);
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
    LogRedactionManager.registerToken(token);
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
    return _readJsonMap(_keyServerData);
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
      clearMultiServerData(),
    ]);
    LogRedactionManager.clearTrackedValues();
  }

  // Get all credentials as a map
  Map<String, String?> getCredentials() {
    return {
      'serverUrl': getServerUrl(),
      'token': getToken(),
      'clientIdentifier': getClientIdentifier(),
    };
  }

  int? getSelectedLibraryIndex() {
    return _prefs.getInt(_keySelectedLibraryIndex);
  }

  // Selected Library Key (replaces index-based selection)
  Future<void> saveSelectedLibraryKey(String key) async {
    await _prefs.setString(_keySelectedLibraryKey, key);
  }

  String? getSelectedLibraryKey() {
    return _prefs.getString(_keySelectedLibraryKey);
  }

  // Library Filters (stored as JSON string)
  Future<void> saveLibraryFilters(
    Map<String, String> filters, {
    String? sectionId,
  }) async {
    final jsonString = json.encode(filters);
    final key = sectionId != null
        ? 'library_filters_$sectionId'
        : _keyLibraryFilters;
    await _prefs.setString(key, jsonString);
  }

  Map<String, String> getLibraryFilters({String? sectionId}) {
    final scopedKey = sectionId != null
        ? 'library_filters_$sectionId'
        : _keyLibraryFilters;

    // Prefer per-library filters when available
    final jsonString =
        _prefs.getString(scopedKey) ??
        // Legacy support: fall back to global filters if present
        _prefs.getString(_keyLibraryFilters);
    if (jsonString == null) return {};

    final decoded = _decodeJsonStringToMap(jsonString);
    return decoded.map((key, value) => MapEntry(key, value.toString()));
  }

  // Library Sort (per-library, stored individually with descending flag)
  Future<void> saveLibrarySort(
    String sectionId,
    String sortKey, {
    bool descending = false,
  }) async {
    final sortData = {'key': sortKey, 'descending': descending};
    await _prefs.setString('library_sort_$sectionId', json.encode(sortData));
  }

  Map<String, dynamic>? getLibrarySort(String sectionId) {
    return _readJsonMap('library_sort_$sectionId', legacyStringOk: true);
  }

  // Library Grouping (per-library, e.g., 'movies', 'shows', 'seasons', 'episodes')
  Future<void> saveLibraryGrouping(String sectionId, String grouping) async {
    await _prefs.setString('library_grouping_$sectionId', grouping);
  }

  String? getLibraryGrouping(String sectionId) {
    return _prefs.getString('library_grouping_$sectionId');
  }

  // Library Tab (per-library, saves last selected tab index)
  Future<void> saveLibraryTab(String sectionId, int tabIndex) async {
    await _prefs.setInt('library_tab_$sectionId', tabIndex);
  }

  int? getLibraryTab(String sectionId) {
    return _prefs.getInt('library_tab_$sectionId');
  }

  // Hidden Libraries (stored as JSON array of library section IDs)
  Future<void> saveHiddenLibraries(Set<String> libraryKeys) async {
    final list = libraryKeys.toList();
    final jsonString = json.encode(list);
    await _prefs.setString(_keyHiddenLibraries, jsonString);
  }

  Set<String> getHiddenLibraries() {
    final jsonString = _prefs.getString(_keyHiddenLibraries);
    if (jsonString == null) return {};

    try {
      final list = json.decode(jsonString) as List<dynamic>;
      return list.map((e) => e.toString()).toSet();
    } catch (e) {
      return {};
    }
  }

  // Clear library preferences
  Future<void> clearLibraryPreferences() async {
    await Future.wait([
      _prefs.remove(_keySelectedLibraryIndex),
      _prefs.remove(_keyLibraryFilters),
      _prefs.remove(_keyLibraryOrder),
      _prefs.remove(_keyHiddenLibraries),
    ]);

    // Also clear all library sort preferences
    final keys = _prefs.getKeys();
    final sortKeys = keys.where((key) => key.startsWith('library_sort_'));
    await Future.wait(sortKeys.map((key) => _prefs.remove(key)));
  }

  // Library Order (stored as JSON list of library keys)
  Future<void> saveLibraryOrder(List<String> libraryKeys) async {
    final jsonString = json.encode(libraryKeys);
    await _prefs.setString(_keyLibraryOrder, jsonString);
  }

  List<String>? getLibraryOrder() {
    final jsonString = _prefs.getString(_keyLibraryOrder);
    if (jsonString == null) return null;

    try {
      final decoded = json.decode(jsonString) as List<dynamic>;
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      return null;
    }
  }

  // User Profile (stored as JSON string)
  Future<void> saveUserProfile(Map<String, dynamic> profileJson) async {
    final jsonString = json.encode(profileJson);
    await _prefs.setString(_keyUserProfile, jsonString);
  }

  Map<String, dynamic>? getUserProfile() {
    return _readJsonMap(_keyUserProfile);
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

    return _readJsonMap(_keyHomeUsersCache);
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

  // Multi-Server Support Methods

  /// Get servers list as JSON string
  String? getServersListJson() {
    return _prefs.getString(_keyServersList);
  }

  /// Save servers list as JSON string
  Future<void> saveServersListJson(String serversJson) async {
    await _prefs.setString(_keyServersList, serversJson);
  }

  /// Get enabled servers as JSON string
  String? getEnabledServersJson() {
    return _prefs.getString(_keyEnabledServers);
  }

  /// Save enabled servers as JSON string
  Future<void> saveEnabledServersJson(String enabledJson) async {
    await _prefs.setString(_keyEnabledServers, enabledJson);
  }

  /// Clear servers list
  Future<void> clearServersList() async {
    await _prefs.remove(_keyServersList);
  }

  /// Clear enabled servers
  Future<void> clearEnabledServers() async {
    await _prefs.remove(_keyEnabledServers);
  }

  /// Clear all multi-server data
  Future<void> clearMultiServerData() async {
    // Clear all server endpoint caches
    final keys = _prefs.getKeys();
    final endpointKeys = keys.where(
      (key) => key.startsWith('server_endpoint_'),
    );

    await Future.wait([
      clearServersList(),
      clearEnabledServers(),
      clearServerOrder(),
      ...endpointKeys.map((key) => _prefs.remove(key)),
    ]);
  }

  /// Server Order (stored as JSON list of server IDs)
  Future<void> saveServerOrder(List<String> serverIds) async {
    final jsonString = json.encode(serverIds);
    await _prefs.setString(_keyServerOrder, jsonString);
  }

  List<String>? getServerOrder() {
    final jsonString = _prefs.getString(_keyServerOrder);
    if (jsonString == null) return null;

    try {
      final decoded = json.decode(jsonString) as List<dynamic>;
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      return null;
    }
  }

  /// Clear server order
  Future<void> clearServerOrder() async {
    await _prefs.remove(_keyServerOrder);
  }

  // Private helper methods

  /// Helper to read and decode JSON Map from preferences
  ///
  /// [key] - The preference key to read
  /// [legacyStringOk] - If true, returns {'key': value, 'descending': false}
  ///                    when value is a plain string (for legacy library sort)
  Map<String, dynamic>? _readJsonMap(
    String key, {
    bool legacyStringOk = false,
  }) {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;

    return _decodeJsonStringToMap(jsonString, legacyStringOk: legacyStringOk);
  }

  /// Helper to decode JSON string to Map with error handling
  ///
  /// [jsonString] - The JSON string to decode
  /// [legacyStringOk] - If true, returns {'key': value, 'descending': false}
  ///                    when value is a plain string (for legacy library sort)
  Map<String, dynamic> _decodeJsonStringToMap(
    String jsonString, {
    bool legacyStringOk = false,
  }) {
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      if (legacyStringOk) {
        // Legacy support: if it's just a string, return it as the key
        return {'key': jsonString, 'descending': false};
      }
      return {};
    }
  }
}
