import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/plex_auth_service.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late Dio dio;
  late PlexAuthService plexAuthService;

  setUp(() async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Create mock secure storage
    final mockSecureStorage = _MockFlutterSecureStorage();
    StorageService.testSecureStorage = mockSecureStorage;

    // Initialize StorageService with mocked SecureStorage
    storageService = await StorageService.getInstance();

    // Mock Dio
    dio = Dio();
    dio.options.baseUrl = 'https://plex.tv/api/v2';

    // Create PlexAuthService with injected dependencies
    plexAuthService = await PlexAuthService.create(dio: dio, storage: storageService);
  });

  group('PlexAuthService', () {
    test('verifyToken returns true for valid token', () async {
      final adapter = HttpMockAdapter();
      adapter.onGet(
        '/user',
        (request) => ResponseBody.fromString(
          jsonEncode({'id': 1, 'username': 'testuser'}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        ),
      );
      dio.httpClientAdapter = adapter;

      final isValid = await plexAuthService.verifyToken('valid_token');
      expect(isValid, isTrue);
    });

    test('verifyToken returns false for invalid token', () async {
      final adapter = HttpMockAdapter();
      adapter.onGet(
        '/user',
        (request) => ResponseBody.fromString(
          '',
          401,
        ),
      );
      dio.httpClientAdapter = adapter;

      final isValid = await plexAuthService.verifyToken('invalid_token');
      expect(isValid, isFalse);
    });

    test('fetchServers parses server list correctly', () async {
      final adapter = HttpMockAdapter();
      final mockServers = [
        {
          'name': 'Test Server',
          'clientIdentifier': 'server_1',
          'provides': 'server',
          'accessToken': 'token',
          'connections': [
            {'protocol': 'http', 'address': '192.168.1.100', 'port': 32400, 'uri': 'http://192.168.1.100:32400', 'local': true}
          ]
        }
      ];

      adapter.onGet(
        'https://clients.plex.tv/api/v2/resources',
        (request) => ResponseBody.fromString(
          jsonEncode(mockServers),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        ),
      );
      dio.httpClientAdapter = adapter;

      final servers = await plexAuthService.fetchServers('auth_token');
      expect(servers, hasLength(1));
      expect(servers.first.name, 'Test Server');
      expect(servers.first.connections, hasLength(1));
    });

    test('findBestWorkingConnection prioritizes local connection', () async {
      // Create a server with multiple connections
      final server = PlexServer(
        name: 'My Server',
        clientIdentifier: 'id',
        accessToken: 'token',
        connections: [
          PlexConnection(protocol: 'http', address: '1.2.3.4', port: 32400, uri: 'http://1.2.3.4:32400', local: false, relay: false, ipv6: false),
          PlexConnection(protocol: 'http', address: '192.168.1.10', port: 32400, uri: 'http://192.168.1.10:32400', local: true, relay: false, ipv6: false),
        ],
        owned: true,
      );

      // We need to mock the latency tests performed by PlexClient.
      // Since PlexClient methods are static, we cannot easily mock them without further refactoring.
      // However, we can test that `getBestConnection` returns the local one synchronously.

      final bestConnection = server.getBestConnection();
      expect(bestConnection, isNotNull);
      expect(bestConnection!.local, isTrue);
      expect(bestConnection.address, '192.168.1.10');
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

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Simple Mock Adapter for Dio
class HttpMockAdapter implements HttpClientAdapter {
  final Map<String, ResponseBody Function(RequestOptions)> _handlers = {};

  void onGet(String path, ResponseBody Function(RequestOptions) handler) {
    _handlers['GET:$path'] = handler;
  }

  // Handle matching including query params if needed, but here simple path match
  // For 'https://clients.plex.tv/api/v2/resources?includeHttps=1&includeRelay=1&includeIPv6=1'
  // the path in RequestOptions might be the full URI or just path depending on how it's called.
  // We'll try to match loosely.

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = '${options.method}:${options.path}';
    // Check for exact match first
    if (_handlers.containsKey(key)) {
      return _handlers[key]!(options);
    }

    // Check if any key is a substring (simplified matching)
    for (final handlerKey in _handlers.keys) {
      if (handlerKey.startsWith('${options.method}:') && options.uri.toString().contains(handlerKey.substring(handlerKey.indexOf(':') + 1).split('?')[0])) {
         // This is a very rough check, but might work for 'fetchServers' where we have query params
         return _handlers[handlerKey]!(options);
      }
    }

    return ResponseBody.fromString('Not Found', 404);
  }

  @override
  void close({bool force = false}) {}
}
