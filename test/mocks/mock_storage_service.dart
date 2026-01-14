import 'package:shared_preferences/shared_preferences.dart';

/// A mock storage service for testing purposes.
/// Stores data in memory instead of persistent storage.
class MockStorageService {
  final Map<String, dynamic> _storage = {};
  String? _clientIdentifier;

  MockStorageService();

  /// Get or set client identifier
  String? getClientIdentifier() => _clientIdentifier;

  Future<void> saveClientIdentifier(String id) async {
    _clientIdentifier = id;
  }

  /// Generic storage methods
  Future<void> setString(String key, String value) async {
    _storage[key] = value;
  }

  String? getString(String key) => _storage[key] as String?;

  Future<void> setInt(String key, int value) async {
    _storage[key] = value;
  }

  int? getInt(String key) => _storage[key] as int?;

  Future<void> setBool(String key, bool value) async {
    _storage[key] = value;
  }

  bool? getBool(String key) => _storage[key] as bool?;

  Future<void> setDouble(String key, double value) async {
    _storage[key] = value;
  }

  double? getDouble(String key) => _storage[key] as double?;

  Future<void> setStringList(String key, List<String> value) async {
    _storage[key] = value;
  }

  List<String>? getStringList(String key) => _storage[key] as List<String>?;

  Future<bool> remove(String key) async {
    return _storage.remove(key) != null;
  }

  Future<bool> clear() async {
    _storage.clear();
    _clientIdentifier = null;
    return true;
  }

  bool containsKey(String key) => _storage.containsKey(key);

  Set<String> getKeys() => _storage.keys.toSet();
}

/// Helper to set up SharedPreferences with mock values for testing
Future<void> setupMockSharedPreferences([Map<String, Object>? values]) async {
  SharedPreferences.setMockInitialValues(values ?? {});
}
