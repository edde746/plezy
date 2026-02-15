import 'dart:convert';

import '../utils/log_redaction_manager.dart';
import 'base_shared_preferences_service.dart';

class StorageService extends BaseSharedPreferencesService {
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
  static const String _keyServerOrder = 'server_order';

  // Key prefixes for per-id storage
  static const String _prefixServerEndpoint = 'server_endpoint_';
  static const String _prefixLibraryFilters = 'library_filters_';
  static const String _prefixLibrarySort = 'library_sort_';
  static const String _prefixLibraryGrouping = 'library_grouping_';
  static const String _prefixLibraryTab = 'library_tab_';
  // Key groups for bulk clearing
  static const List<String> _credentialKeys = [
    _keyServerUrl,
    _keyToken,
    _keyPlexToken,
    _keyServerData,
    _keyClientId,
    _keyUserProfile,
    _keyCurrentUserUUID,
    _keyHomeUsersCache,
    _keyHomeUsersCacheExpiry,
  ];

  static const List<String> _libraryPreferenceKeys = [
    _keySelectedLibraryIndex,
    _keyLibraryFilters,
    _keyLibraryOrder,
    _keyHiddenLibraries,
  ];

  StorageService._();

  static Future<StorageService> getInstance() {
    return BaseSharedPreferencesService.initializeInstance(() => StorageService._());
  }

  @override
  Future<void> onInit() async {
    // Seed known values so logs can redact immediately on startup.
    LogRedactionManager.registerServerUrl(prefs.getString(_keyServerUrl));
    LogRedactionManager.registerToken(prefs.getString(_keyToken));
    LogRedactionManager.registerToken(getPlexToken());
  }

  // Per-Server Endpoint URL (for multi-server connection caching)
  Future<void> saveServerEndpoint(String serverId, String url) async {
    await prefs.setString('$_prefixServerEndpoint$serverId', url);
    LogRedactionManager.registerServerUrl(url);
  }

  String? getServerEndpoint(String serverId) {
    return prefs.getString('$_prefixServerEndpoint$serverId');
  }

  Future<void> clearServerEndpoint(String serverId) async {
    await prefs.remove('$_prefixServerEndpoint$serverId');
  }

  // Plex.tv Token (for API access)
  Future<void> savePlexToken(String token) async {
    await prefs.setString(_keyPlexToken, token);
    LogRedactionManager.registerToken(token);
  }

  String? getPlexToken() {
    return prefs.getString(_keyPlexToken);
  }

  // Client Identifier
  Future<void> saveClientIdentifier(String clientId) async {
    await prefs.setString(_keyClientId, clientId);
  }

  String? getClientIdentifier() {
    return prefs.getString(_keyClientId);
  }

  // Clear all credentials
  Future<void> clearCredentials() async {
    await Future.wait([..._credentialKeys.map((k) => prefs.remove(k)), clearMultiServerData()]);
    LogRedactionManager.clearTrackedValues();
  }

  int? getSelectedLibraryIndex() {
    return prefs.getInt(_keySelectedLibraryIndex);
  }

  // Selected Library Key (replaces index-based selection)
  Future<void> saveSelectedLibraryKey(String key) async {
    await prefs.setString(_keySelectedLibraryKey, key);
  }

  String? getSelectedLibraryKey() {
    return prefs.getString(_keySelectedLibraryKey);
  }

  // Library Filters (stored as JSON string)
  Future<void> saveLibraryFilters(Map<String, String> filters, {String? sectionId}) async {
    final key = sectionId != null ? '$_prefixLibraryFilters$sectionId' : _keyLibraryFilters;
    // Note: using Map<String, String> which json.encode handles correctly
    final jsonString = json.encode(filters);
    await prefs.setString(key, jsonString);
  }

  Map<String, String> getLibraryFilters({String? sectionId}) {
    final scopedKey = sectionId != null ? '$_prefixLibraryFilters$sectionId' : _keyLibraryFilters;

    // Prefer per-library filters when available
    final jsonString =
        prefs.getString(scopedKey) ??
        // Legacy support: fall back to global filters if present
        prefs.getString(_keyLibraryFilters);
    if (jsonString == null) return {};

    final decoded = _decodeJsonStringToMap(jsonString);
    return decoded.map((key, value) => MapEntry(key, value.toString()));
  }

  // Library Sort (per-library, stored individually with descending flag)
  Future<void> saveLibrarySort(String sectionId, String sortKey, {bool descending = false}) async {
    final sortData = {'key': sortKey, 'descending': descending};
    await _setJsonMap('$_prefixLibrarySort$sectionId', sortData);
  }

  Map<String, dynamic>? getLibrarySort(String sectionId) {
    return _readJsonMap('$_prefixLibrarySort$sectionId', legacyStringOk: true);
  }

  // Library Grouping (per-library, e.g., 'movies', 'shows', 'seasons', 'episodes')
  Future<void> saveLibraryGrouping(String sectionId, String grouping) async {
    await prefs.setString('$_prefixLibraryGrouping$sectionId', grouping);
  }

  String? getLibraryGrouping(String sectionId) {
    return prefs.getString('$_prefixLibraryGrouping$sectionId');
  }

  // Library Tab (per-library, saves last selected tab index)
  Future<void> saveLibraryTab(String sectionId, int tabIndex) async {
    await prefs.setInt('$_prefixLibraryTab$sectionId', tabIndex);
  }

  int? getLibraryTab(String sectionId) {
    return prefs.getInt('$_prefixLibraryTab$sectionId');
  }

  // Hidden Libraries (stored as JSON array of library section IDs)
  Future<void> saveHiddenLibraries(Set<String> libraryKeys) async {
    await _setStringList(_keyHiddenLibraries, libraryKeys.toList());
  }

  Set<String> getHiddenLibraries() {
    final jsonString = prefs.getString(_keyHiddenLibraries);
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
      ..._libraryPreferenceKeys.map((k) => prefs.remove(k)),
      _clearKeysWithPrefix(_prefixLibrarySort),
      _clearKeysWithPrefix(_prefixLibraryFilters),
      _clearKeysWithPrefix(_prefixLibraryGrouping),
      _clearKeysWithPrefix(_prefixLibraryTab),
    ]);
  }

  // Library Order (stored as JSON list of library keys)
  Future<void> saveLibraryOrder(List<String> libraryKeys) async {
    await _setStringList(_keyLibraryOrder, libraryKeys);
  }

  List<String>? getLibraryOrder() => _getStringList(_keyLibraryOrder);

  // User Profile (stored as JSON string)
  Future<void> saveUserProfile(Map<String, dynamic> profileJson) async {
    await _setJsonMap(_keyUserProfile, profileJson);
  }

  Map<String, dynamic>? getUserProfile() {
    return _readJsonMap(_keyUserProfile);
  }

  // Current User UUID
  Future<void> saveCurrentUserUUID(String uuid) async {
    await prefs.setString(_keyCurrentUserUUID, uuid);
  }

  String? getCurrentUserUUID() {
    return prefs.getString(_keyCurrentUserUUID);
  }

  // Home Users Cache (stored as JSON string with expiry)
  Future<void> saveHomeUsersCache(Map<String, dynamic> homeData) async {
    await _setJsonMap(_keyHomeUsersCache, homeData);

    // Set cache expiry to 1 hour from now
    final expiry = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch;
    await prefs.setInt(_keyHomeUsersCacheExpiry, expiry);
  }

  Map<String, dynamic>? getHomeUsersCache() {
    final expiry = prefs.getInt(_keyHomeUsersCacheExpiry);
    if (expiry == null || DateTime.now().millisecondsSinceEpoch > expiry) {
      // Cache expired, clear it
      clearHomeUsersCache();
      return null;
    }

    return _readJsonMap(_keyHomeUsersCache);
  }

  Future<void> clearHomeUsersCache() async {
    await Future.wait([prefs.remove(_keyHomeUsersCache), prefs.remove(_keyHomeUsersCacheExpiry)]);
  }

  // Clear current user UUID (for server switching)
  Future<void> clearCurrentUserUUID() async {
    await prefs.remove(_keyCurrentUserUUID);
  }

  // Clear all user-related data (for logout)
  Future<void> clearUserData() async {
    await Future.wait([clearCredentials(), clearLibraryPreferences()]);
  }

  // Multi-Server Support Methods

  /// Get servers list as JSON string
  String? getServersListJson() {
    return prefs.getString(_keyServersList);
  }

  /// Save servers list as JSON string
  Future<void> saveServersListJson(String serversJson) async {
    await prefs.setString(_keyServersList, serversJson);
  }

  /// Clear servers list
  Future<void> clearServersList() async {
    await prefs.remove(_keyServersList);
  }

  /// Clear all multi-server data
  Future<void> clearMultiServerData() async {
    await Future.wait([clearServersList(), clearServerOrder(), _clearKeysWithPrefix(_prefixServerEndpoint)]);
  }

  /// Server Order (stored as JSON list of server IDs)
  Future<void> saveServerOrder(List<String> serverIds) async {
    await _setStringList(_keyServerOrder, serverIds);
  }

  List<String>? getServerOrder() => _getStringList(_keyServerOrder);

  /// Clear server order
  Future<void> clearServerOrder() async {
    await prefs.remove(_keyServerOrder);
  }

  // Private helper methods

  /// Helper to read and decode JSON `List<String>` from preferences
  List<String>? _getStringList(String key) {
    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;

    try {
      final decoded = json.decode(jsonString) as List<dynamic>;
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      return null;
    }
  }

  /// Helper to read and decode JSON Map from preferences
  ///
  /// [key] - The preference key to read
  /// [legacyStringOk] - If true, returns {'key': value, 'descending': false}
  ///                    when value is a plain string (for legacy library sort)
  Map<String, dynamic>? _readJsonMap(String key, {bool legacyStringOk = false}) {
    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;

    return _decodeJsonStringToMap(jsonString, legacyStringOk: legacyStringOk);
  }

  /// Helper to decode JSON string to Map with error handling
  ///
  /// [jsonString] - The JSON string to decode
  /// [legacyStringOk] - If true, returns {'key': value, 'descending': false}
  ///                    when value is a plain string (for legacy library sort)
  Map<String, dynamic> _decodeJsonStringToMap(String jsonString, {bool legacyStringOk = false}) {
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

  /// Remove all keys matching a prefix
  Future<void> _clearKeysWithPrefix(String prefix) async {
    final keys = prefs.getKeys().where((k) => k.startsWith(prefix));
    await Future.wait(keys.map((k) => prefs.remove(k)));
  }

  // Public JSON helpers for reducing boilerplate

  /// Save a JSON-encodable map to storage
  Future<void> _setJsonMap(String key, Map<String, dynamic> data) async {
    final jsonString = json.encode(data);
    await prefs.setString(key, jsonString);
  }

  /// Save a string list as JSON array
  Future<void> _setStringList(String key, List<String> list) async {
    final jsonString = json.encode(list);
    await prefs.setString(key, jsonString);
  }
}
