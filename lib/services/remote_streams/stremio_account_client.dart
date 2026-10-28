import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class StremioAccountException implements Exception {
  const StremioAccountException(this.kind);

  final StremioAccountFailure kind;
}

enum StremioAccountFailure { unavailable, invalidResponse, invalidLink, cancelled, timeout }

class StremioLinkAuthorization {
  const StremioLinkAuthorization({required this.code, required this.link, required this.qrData});

  final String code;
  final String link;
  final String qrData;
}

class StremioAccountAddon {
  const StremioAccountAddon({required this.name, required this.manifestUrl, required this.manifest});

  final String name;
  final String manifestUrl;
  final Map<String, dynamic> manifest;

  String get host => Uri.parse(manifestUrl).host;

  bool get supportsCatalogs => _hasResource('catalog') && (manifest['catalogs'] is List);

  bool get supportsStreams => _hasResource('stream');

  bool _hasResource(String name) {
    final resources = manifest['resources'];
    if (resources is! List) return false;
    return resources.any((resource) => resource == name || (resource is Map && resource['name'] == name));
  }
}

class StremioAccountAddonCollection {
  const StremioAccountAddonCollection({required this.addons, required this.ignoredCount});

  final List<StremioAccountAddon> addons;
  final int ignoredCount;
}

/// Read-only Stremio account linking and add-on collection import.
///
/// The account authorization key is held only on this client's stack while
/// the collection is fetched. This class never writes to Stremio's account,
/// stores the key, or logs secret-bearing values.
class StremioAccountClient {
  StremioAccountClient({http.Client? client}) : _client = client ?? http.Client();

  static const _linkHost = 'link.stremio.com';
  static const _apiHost = 'api.strem.io';
  static const _maxResponseBytes = 2 * 1024 * 1024;
  static const _requestTimeout = Duration(seconds: 15);
  static const _authorizationTimeout = Duration(minutes: 5);
  static const _pollInterval = Duration(seconds: 2);

  final http.Client _client;

  Future<StremioLinkAuthorization> createLinkAuthorization() async {
    final body = await _getJson(Uri.https(_linkHost, '/api/v2/create', {'type': 'Create'}), allowedHost: _linkHost);
    final result = body['result'];
    if (result is! Map) throw const StremioAccountException(StremioAccountFailure.invalidResponse);
    final row = Map<String, dynamic>.from(result);
    final code = row['code'];
    final link = row['link'];
    final qrData = row['qrcode'];
    if (code is! String || code.isEmpty || code.length > 128 ||
        link is! String || link.length > 2048 ||
        qrData is! String || qrData.isEmpty || qrData.length > 2048) {
      throw const StremioAccountException(StremioAccountFailure.invalidResponse);
    }
    final linkUri = Uri.tryParse(link);
    if (linkUri == null || linkUri.scheme != 'https' || linkUri.host != _linkHost || linkUri.userInfo.isNotEmpty) {
      throw const StremioAccountException(StremioAccountFailure.invalidLink);
    }
    return StremioLinkAuthorization(code: code, link: linkUri.toString(), qrData: qrData);
  }

  Future<StremioAccountAddonCollection> importAddonCollection(
    String code, {
    required bool Function() shouldCancel,
  }) async {
    final authKey = await _waitForAccountKey(code, shouldCancel: shouldCancel);
    if (shouldCancel()) throw const StremioAccountException(StremioAccountFailure.cancelled);
    final login = await _postJson(
      Uri.https(_apiHost, '/api/loginWithToken'),
      {'authKey': null, 'token': authKey},
      allowedHost: _apiHost,
    );
    final loginResult = login['result'];
    final accountKey = loginResult is Map ? loginResult['authKey'] : null;
    if (accountKey is! String || accountKey.isEmpty || accountKey.length > 4096) {
      throw const StremioAccountException(StremioAccountFailure.invalidResponse);
    }
    if (shouldCancel()) throw const StremioAccountException(StremioAccountFailure.cancelled);

    final collection = await _postJson(
      Uri.https(_apiHost, '/api/addonCollectionGet'),
      {'authKey': accountKey, 'update': true, 'addFromURL': <String>[]},
      allowedHost: _apiHost,
    );
    final result = collection['result'];
    final rawAddons = result is Map ? result['addons'] : null;
    if (rawAddons is! List) throw const StremioAccountException(StremioAccountFailure.invalidResponse);

    final addons = <StremioAccountAddon>[];
    final seenUrls = <String>{};
    var ignored = 0;
    for (final raw in rawAddons.take(200)) {
      final descriptor = _parseDescriptor(raw);
      if (descriptor == null || (!descriptor.supportsCatalogs && !descriptor.supportsStreams) ||
          !seenUrls.add(descriptor.manifestUrl)) {
        ignored++;
        continue;
      }
      addons.add(descriptor);
    }
    ignored += rawAddons.length - rawAddons.take(200).length;
    return StremioAccountAddonCollection(addons: List.unmodifiable(addons), ignoredCount: ignored);
  }

  Future<String> _waitForAccountKey(String code, {required bool Function() shouldCancel}) async {
    if (code.isEmpty || code.length > 128) throw const StremioAccountException(StremioAccountFailure.invalidResponse);
    final deadline = DateTime.now().add(_authorizationTimeout);
    final uri = Uri.https(_linkHost, '/api/v2/read', {'type': 'Read', 'code': code});
    while (DateTime.now().isBefore(deadline)) {
      if (shouldCancel()) throw const StremioAccountException(StremioAccountFailure.cancelled);
      try {
        final body = await _getJson(uri, allowedHost: _linkHost);
        final result = body['result'];
        final authKey = result is Map ? result['authKey'] : null;
        if (authKey is String && authKey.isNotEmpty && authKey.length <= 4096) return authKey;
      } on StremioAccountException catch (error) {
        if (error.kind != StremioAccountFailure.unavailable) rethrow;
        // A link request remains pending until it has been approved. The
        // endpoint may respond with an API error during that window; retry
        // until approval, explicit cancellation, or the local timeout.
      } on Object {
        // Network interruptions are also retryable while the user approves.
      }
      await Future<void>.delayed(_pollInterval);
    }
    if (shouldCancel()) throw const StremioAccountException(StremioAccountFailure.cancelled);
    throw const StremioAccountException(StremioAccountFailure.timeout);
  }

  Future<Map<String, dynamic>> _getJson(Uri uri, {required String allowedHost}) async {
    final response = await _sendJsonRequest(uri, method: 'GET', allowedHost: allowedHost);
    return _decodeJson(response);
  }

  Future<Map<String, dynamic>> _postJson(Uri uri, Map<String, Object?> body, {required String allowedHost}) async {
    final response = await _sendJsonRequest(uri, method: 'POST', body: body, allowedHost: allowedHost);
    return _decodeJson(response);
  }

  Future<http.Response> _sendJsonRequest(
    Uri initialUri, {
    required String method,
    required String allowedHost,
    Map<String, Object?>? body,
  }) async {
    var uri = initialUri;
    for (var redirect = 0; redirect <= 3; redirect++) {
      if (uri.scheme != 'https' || uri.host != allowedHost || uri.userInfo.isNotEmpty || uri.hasFragment) {
        throw const StremioAccountException(StremioAccountFailure.invalidLink);
      }
      final request = http.Request(method, uri)
        ..followRedirects = false
        ..headers['accept'] = 'application/json';
      if (body != null) {
        request.headers['content-type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      final streamed = await _client.send(request).timeout(_requestTimeout);
      if (streamed.statusCode >= 300 && streamed.statusCode < 400) {
        final location = streamed.headers['location'];
        await streamed.stream.drain<void>().timeout(_requestTimeout);
        if (location == null || redirect == 3) {
          throw const StremioAccountException(StremioAccountFailure.unavailable);
        }
        uri = uri.resolve(location);
        continue;
      }
      final bytes = <int>[];
      await for (final chunk in streamed.stream.timeout(_requestTimeout)) {
        if (bytes.length + chunk.length > _maxResponseBytes) {
          throw const StremioAccountException(StremioAccountFailure.invalidResponse);
        }
        bytes.addAll(chunk);
      }
      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        throw const StremioAccountException(StremioAccountFailure.unavailable);
      }
      return http.Response.bytes(bytes, streamed.statusCode, headers: streamed.headers);
    }
    throw const StremioAccountException(StremioAccountFailure.unavailable);
  }

  Map<String, dynamic> _decodeJson(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) throw const StremioAccountException(StremioAccountFailure.invalidResponse);
      return Map<String, dynamic>.from(decoded);
    } on StremioAccountException {
      rethrow;
    } on Object {
      throw const StremioAccountException(StremioAccountFailure.invalidResponse);
    }
  }

  StremioAccountAddon? _parseDescriptor(Object? raw) {
    if (raw is! Map) return null;
    final descriptor = Map<String, dynamic>.from(raw);
    final rawManifest = descriptor['manifest'];
    final rawUrl = descriptor['transportUrl'];
    if (rawManifest is! Map || rawUrl is! String || rawUrl.length > 4096) return null;
    final manifest = Map<String, dynamic>.from(rawManifest);
    final uri = Uri.tryParse(rawUrl);
    final id = manifest['id'];
    final name = manifest['name'];
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty || uri.userInfo.isNotEmpty || uri.hasFragment ||
        id is! String || id.trim().isEmpty || id.length > 512 || name is! String || name.trim().isEmpty ||
        manifest['resources'] is! List) {
      return null;
    }
    return StremioAccountAddon(
      name: _displayText(name) ?? 'Stremio add-on',
      manifestUrl: uri.toString(),
      manifest: Map.unmodifiable(manifest),
    );
  }

  String? _displayText(Object? value) {
    if (value is! String) return null;
    final cleaned = value.replaceAll(RegExp(r'[\u0000-\u001f\u007f]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return null;
    return cleaned.length > 160 ? '${cleaned.substring(0, 159)}…' : cleaned;
  }

  void close() => _client.close();
}
