import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late _MockFlutterSecureStorage mockSecureStorage;

  setUp(() async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Create mock secure storage
    mockSecureStorage = _MockFlutterSecureStorage();

    // Set static mock before initialization
    StorageService.testSecureStorage = mockSecureStorage;

    // Initialize StorageService
    storageService = await StorageService.getInstance();
  });

  group('StorageService', () {
    test('saveServerUrl saves and retrieves url', () async {
      const url = 'https://plex.example.com';
      await storageService.saveServerUrl(url);
      expect(storageService.getServerUrl(), url);
    });

    test('saveToken saves to secure storage', () async {
      const token = 'my_secret_token';
      await storageService.saveToken(token);

      expect(storageService.getToken(), token);
      expect(await mockSecureStorage.read(key: 'token'), token);
    });

    test('saveServerData saves and retrieves json map', () async {
      final serverData = {'name': 'My Server', 'id': 123};
      await storageService.saveServerData(serverData);

      final retrievedData = storageService.getServerData();
      expect(retrievedData, serverData);
    });

    test('saveLibraryFilters saves filters for specific section', () async {
      final filters = {'genre': 'Action', 'year': '2023'};
      const sectionId = '1';

      await storageService.saveLibraryFilters(filters, sectionId: sectionId);

      final retrievedFilters = storageService.getLibraryFilters(sectionId: sectionId);
      expect(retrievedFilters, filters);
    });

    test('clearCredentials removes all tokens and urls', () async {
      await storageService.saveServerUrl('url');
      await storageService.saveToken('token');
      await storageService.savePlexToken('plex_token');

      await storageService.clearCredentials();

      expect(storageService.getServerUrl(), isNull);
      expect(storageService.getToken(), isNull);
      expect(storageService.getPlexToken(), isNull);
      expect(await mockSecureStorage.read(key: 'token'), isNull);
    });
  });
}

// Mock implementation of FlutterSecureStorage for testing
class _MockFlutterSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<String?> read({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    return _storage[key];
  }

  @override
  Future<void> write({required String key, required String? value, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    if (value != null) {
      _storage[key] = value;
    } else {
      _storage.remove(key);
    }
  }

  @override
  Future<void> delete({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll({IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    _storage.clear();
  }

  @override
  Future<bool> containsKey({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    return _storage.containsKey(key);
  }

  @override
  Future<Map<String, String>> readAll({IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    return Map.from(_storage);
  }

  // noSuchMethod handles other members if interface changes, but we should be good for basic usage
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
