import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'remote_stream_models.dart';

class StremioAddonException implements Exception {
  const StremioAddonException(this.kind);
  final StremioAddonFailure kind;
}

enum StremioAddonFailure { invalidAddress, notAnAddon, unavailable, unsupportedResource, invalidResponse }

class StremioAddonCatalog {
  const StremioAddonCatalog({
    required this.type,
    required this.id,
    required this.name,
    required this.canBrowse,
    required this.supportsSearch,
    required this.supportsSkip,
  });

  final String type;
  final String id;
  final String name;
  final bool canBrowse;
  final bool supportsSearch;
  final bool supportsSkip;
}

/// Bounded client for the Stremio add-on HTTP protocol. It never logs a
/// manifest or resource URL because either may carry the add-on's secret.
class StremioAddonClient {
  StremioAddonClient({http.Client? client}) : _client = client ?? http.Client();

  static const _maxResponseBytes = 2 * 1024 * 1024;
  static const _maxManifestBytes = 256 * 1024;
  static const _maxStreamsPerAddon = 100;
  static const _timeout = Duration(seconds: 18);
  final http.Client _client;

  Future<Map<String, dynamic>> fetchManifest(String address, {required bool allowHttp}) async {
    final uri = _validateAddress(address, allowHttp: allowHttp);
    final payload = await _getJson(uri);
    final id = payload['id'];
    final name = payload['name'];
    final version = payload['version'];
    if (id is! String || id.trim().isEmpty || id.length > 512 || name is! String || name.trim().isEmpty || version is! String) {
      throw const StremioAddonException(StremioAddonFailure.notAnAddon);
    }
    payload['name'] = _displayText(name) ?? 'Stremio add-on';
    if (utf8.encode(jsonEncode(payload)).length > _maxManifestBytes) {
      throw const StremioAddonException(StremioAddonFailure.invalidResponse);
    }
    final resources = _resources(payload);
    final supportsStreams = resources.any((resource) => resource.name == 'stream');
    final supportsCatalogs = resources.any((resource) => resource.name == 'catalog') && _rawCatalogs(payload).isNotEmpty;
    if (!supportsStreams && !supportsCatalogs) {
      throw const StremioAddonException(StremioAddonFailure.unsupportedResource);
    }
    return Map<String, dynamic>.unmodifiable(payload);
  }

  List<StremioAddonCatalog> catalogs(StremioAddonInstallation addon) {
    if (!_resources(addon.manifest).any((resource) => resource.name == 'catalog')) return const [];
    final result = <StremioAddonCatalog>[];
    for (final raw in _rawCatalogs(addon.manifest)) {
      if (raw is! Map || result.length >= 100) continue;
      final row = Map<String, dynamic>.from(raw);
      final type = row['type'];
      final id = row['id'];
      if (type is! String || !const {'movie', 'series'}.contains(type) ||
          id is! String || !_validSegment(id)) {
        continue;
      }
      final extras = row['extra'] is List ? row['extra'] as List : const [];
      final supportsSearchExtra = extras.any((extra) => extra is Map && extra['name'] == 'search');
      final supportsSkip = extras.any((extra) => extra is Map && extra['name'] == 'skip');
      final required = row['extraRequired'] is List ? row['extraRequired'] as List : const [];
      // A catalog that requires a user-selected filter has no honest default
      // page. Keep it available to search when possible; a future filter UI
      // can expose the remaining required extras without changing its ID.
      final canBrowse = required.every((extra) => extra is String && extra == 'skip') &&
          (required.isEmpty || supportsSkip);
      final supportsSearch = supportsSearchExtra && required.every((extra) => extra is String && {'skip', 'search'}.contains(extra));
      result.add(
        StremioAddonCatalog(
          type: type,
          id: id,
          name: _displayText(row['name']) ?? id,
          canBrowse: canBrowse,
          supportsSearch: supportsSearch,
          supportsSkip: supportsSkip,
        ),
      );
    }
    return List.unmodifiable(result);
  }

  Future<List<RemoteStreamCandidate>> fetchStreams(
    StremioAddonInstallation addon,
    RemoteStreamRequest request,
  ) async {
    final resources = _resources(addon.manifest);
    if (!resources.any((resource) => resource.supports('stream', request.type, request.id))) {
      throw const StremioAddonException(StremioAddonFailure.unsupportedResource);
    }
    final manifestUri = _validateAddress(addon.manifestUrl, allowHttp: addon.allowHttp);
    final streamUri = _resourceUri(manifestUri, 'stream', request.type, request.id);
    final body = await _getJson(streamUri);
    final rows = body['streams'];
    if (rows is! List) throw const StremioAddonException(StremioAddonFailure.invalidResponse);
    final candidates = <RemoteStreamCandidate>[];
    for (var index = 0; index < rows.length && candidates.length < _maxStreamsPerAddon; index++) {
      final row = rows[index];
      if (row is! Map) continue;
      if (_parseCandidate(addon, Map<String, dynamic>.from(row), index) case final candidate?) {
        candidates.add(candidate);
      }
    }
    return List.unmodifiable(candidates);
  }

  Future<List<Map<String, dynamic>>> fetchCatalog(
    StremioAddonInstallation addon,
    StremioAddonCatalog catalog, {
    int skip = 0,
  }) async {
    if (skip < 0 || skip > 1000000 || !catalog.canBrowse || (skip > 0 && !catalog.supportsSkip)) {
      throw const StremioAddonException(StremioAddonFailure.unsupportedResource);
    }
    final resources = _resources(addon.manifest);
    if (!resources.any((resource) => resource.supports('catalog', catalog.type, catalog.id))) {
      throw const StremioAddonException(StremioAddonFailure.unsupportedResource);
    }
    final manifestUri = _validateAddress(addon.manifestUrl, allowHttp: addon.allowHttp);
    final extras = catalog.supportsSkip ? {'skip': '$skip'} : const <String, String>{};
    final body = await _getJson(_resourceUri(manifestUri, 'catalog', catalog.type, catalog.id, extras: extras));
    final raw = body['metas'];
    if (raw is! List) throw const StremioAddonException(StremioAddonFailure.invalidResponse);
    return [
      for (final row in raw.take(_maxStreamsPerAddon))
        if (row is Map) Map<String, dynamic>.from(row),
    ];
  }

  Future<List<Map<String, dynamic>>> searchCatalog(
    StremioAddonInstallation addon,
    StremioAddonCatalog catalog,
    String query, {
    int skip = 0,
  }) async {
    final trimmed = query.trim();
    if (!catalog.supportsSearch || trimmed.isEmpty || trimmed.length > 120 ||
        trimmed.runes.any((rune) => rune < 0x20 || rune == 0x7f) || skip < 0 || skip > 1000000) {
      throw const StremioAddonException(StremioAddonFailure.unsupportedResource);
    }
    final resources = _resources(addon.manifest);
    if (!resources.any((resource) => resource.supports('catalog', catalog.type, catalog.id))) {
      throw const StremioAddonException(StremioAddonFailure.unsupportedResource);
    }
    final manifestUri = _validateAddress(addon.manifestUrl, allowHttp: addon.allowHttp);
    final extras = <String, String>{'search': trimmed, if (catalog.supportsSkip) 'skip': '$skip'};
    final body = await _getJson(_resourceUri(manifestUri, 'catalog', catalog.type, catalog.id, extras: extras));
    final raw = body['metas'];
    if (raw is! List) throw const StremioAddonException(StremioAddonFailure.invalidResponse);
    return [
      for (final row in raw.take(_maxStreamsPerAddon))
        if (row is Map) Map<String, dynamic>.from(row),
    ];
  }

  Future<Map<String, dynamic>?> fetchMeta(StremioAddonInstallation addon, String type, String id) async {
    if (!_validSegment(id)) throw const StremioAddonException(StremioAddonFailure.invalidResponse);
    final resources = _resources(addon.manifest);
    if (!resources.any((resource) => resource.supports('meta', type, id))) return null;
    final manifestUri = _validateAddress(addon.manifestUrl, allowHttp: addon.allowHttp);
    final body = await _getJson(_resourceUri(manifestUri, 'meta', type, id));
    final meta = body['meta'];
    return meta is Map ? Map<String, dynamic>.from(meta) : null;
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final response = await _requestFollowingSafeRedirects(uri).timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300 || response.bodyBytes.length > _maxResponseBytes) {
        throw const StremioAddonException(StremioAddonFailure.unavailable);
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) throw const StremioAddonException(StremioAddonFailure.invalidResponse);
      return Map<String, dynamic>.from(decoded);
    } on StremioAddonException {
      rethrow;
    } on FormatException {
      throw const StremioAddonException(StremioAddonFailure.invalidResponse);
    } on Object {
      throw const StremioAddonException(StremioAddonFailure.unavailable);
    }
  }

  Future<http.Response> _requestFollowingSafeRedirects(Uri initial) async {
    var uri = initial;
    for (var redirects = 0; redirects <= 4; redirects++) {
      final request = http.Request('GET', uri)
        ..followRedirects = false
        ..headers['accept'] = 'application/json';
      final streamed = await _client.send(request).timeout(_timeout);
      if (streamed.statusCode >= 300 && streamed.statusCode < 400) {
        final location = streamed.headers['location'];
        if (location == null || redirects == 4) {
          await streamed.stream.drain<void>().timeout(_timeout);
          throw const StremioAddonException(StremioAddonFailure.unavailable);
        }
        await streamed.stream.drain<void>().timeout(_timeout);
        final next = uri.resolve(location);
        if (next.scheme != 'https' && !(next.scheme == 'http' && uri.scheme == 'http')) {
          throw const StremioAddonException(StremioAddonFailure.invalidAddress);
        }
        uri = _validateAddress(next.toString(), allowHttp: next.scheme == 'http');
        continue;
      }
      final bytes = <int>[];
      await for (final chunk in streamed.stream.timeout(_timeout)) {
        if (bytes.length + chunk.length > _maxResponseBytes) {
          throw const StremioAddonException(StremioAddonFailure.invalidResponse);
        }
        bytes.addAll(chunk);
      }
      return http.Response.bytes(bytes, streamed.statusCode, headers: streamed.headers);
    }
    throw const StremioAddonException(StremioAddonFailure.unavailable);
  }

  static Uri _validateAddress(String input, {required bool allowHttp}) {
    if (input.length > 4096 || input.trim() != input || input.isEmpty) {
      throw const StremioAddonException(StremioAddonFailure.invalidAddress);
    }
    final uri = Uri.tryParse(input);
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        (uri.scheme != 'https' && !(allowHttp && uri.scheme == 'http'))) {
      throw const StremioAddonException(StremioAddonFailure.invalidAddress);
    }
    return uri;
  }

  static List<_AddonResource> _resources(Map<String, dynamic> manifest) {
    final raw = manifest['resources'];
    if (raw is! List) return const [];
    return [for (final resource in raw) if (_AddonResource.tryParse(resource) case final parsed?) parsed];
  }

  static Uri _resourceUri(
    Uri manifestUri,
    String resource,
    String type,
    String id, {
    Map<String, String> extras = const {},
  }) {
    // Stremio encodes every extra property into one final path component,
    // joined with `&` (for example, `search=Alien&skip=20.json`). Keep the
    // add-on's configured path prefix and query intact; both can carry
    // installation-specific routing or credentials.
    var basePath = manifestUri.path;
    if (basePath.endsWith('/manifest.json')) {
      basePath = basePath.substring(0, basePath.length - '/manifest.json'.length);
    } else if (basePath == '/manifest.json') {
      basePath = '';
    }
    final resourcePath = [resource, type, id].map(Uri.encodeComponent).join('/');
    final extraPath = extras.entries
        .map((entry) => '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}')
        .join('&');
    final path = extras.isEmpty ? '$basePath/$resourcePath.json' : '$basePath/$resourcePath/$extraPath.json';
    final query = manifestUri.hasQuery ? '?${manifestUri.query}' : '';
    return Uri.parse('${manifestUri.scheme}://${manifestUri.authority}$path$query');
  }

  static List<Object?> _rawCatalogs(Map<String, dynamic> manifest) =>
      manifest['catalogs'] is List ? List<Object?>.from(manifest['catalogs'] as List) : const [];

  static bool _validSegment(String value) =>
      value.isNotEmpty && value.length <= 512 && !value.runes.any((rune) => rune < 0x20 || rune == 0x7f);

  static RemoteStreamCandidate? _parseCandidate(StremioAddonInstallation addon, Map<String, dynamic> row, int index) {
    final behavior = row['behaviorHints'] is Map ? Map<String, dynamic>.from(row['behaviorHints'] as Map) : const {};
    Uri? url;
    final rawUrl = row['url'];
    if (rawUrl is String) url = _parseStreamUri(rawUrl, allowHttp: addon.allowHttp);
    final rawHash = row['infoHash'];
    final hash = rawHash is String ? _validHash(rawHash) : null;
    final rawFileIndex = row['fileIdx'];
    final fileIndex = rawFileIndex is num && rawFileIndex == rawFileIndex.toInt()
        ? rawFileIndex.toInt()
        : int.tryParse('$rawFileIndex');
    final external = row['externalUrl'] is String
        ? _parseStreamUri(row['externalUrl'] as String, allowHttp: addon.allowHttp)
        : null;
    final subtitles = <RemoteSubtitle>[];
    final rawSubtitles = row['subtitles'];
    if (rawSubtitles is List) {
      for (var i = 0; i < rawSubtitles.length; i++) {
        final subtitle = rawSubtitles[i];
        if (subtitle is! Map) continue;
        final data = Map<String, dynamic>.from(subtitle);
        final subtitleUri = data['url'] is String
            ? _parseStreamUri(data['url'] as String, allowHttp: addon.allowHttp)
            : null;
        if (subtitleUri == null) continue;
        subtitles.add(
          RemoteSubtitle(
            id: '${addon.id}:$index:$i',
            url: subtitleUri,
            lang: _displayText(data['lang']),
            label: _displayText(data['label']),
          ),
        );
      }
    }
    if (url == null && hash == null && external == null) return null;
    final headers = _requestHeaders(behavior['proxyHeaders']);
    final label = _displayText(row['name']) ?? _displayText(row['title']) ?? addon.name;
    return RemoteStreamCandidate(
      addonId: addon.id,
      addonName: addon.name,
      label: label,
      description: _displayText(row['description']),
      url: url,
      headers: headers,
      infoHash: hash,
      fileIndex: fileIndex != null && fileIndex >= 0 ? fileIndex : null,
      externalUrl: external,
      subtitles: List.unmodifiable(subtitles),
      behaviorHints: behavior,
    );
  }

  static Map<String, String> _requestHeaders(Object? proxyHeaders) {
    if (proxyHeaders is! Map) return const {};
    final request = proxyHeaders['request'];
    if (request is! Map) return const {};
    final headers = <String, String>{};
    const forbidden = {
      'host',
      'content-length',
      'connection',
      'transfer-encoding',
      'proxy-authorization',
      'range',
      'accept-encoding',
      'origin',
    };
    for (final entry in request.entries) {
      if (entry.key is! String || entry.value is! String) continue;
      final name = (entry.key as String).trim();
      final value = (entry.value as String).trim();
      if (name.isEmpty || name.length > 100 || value.length > 4096 || forbidden.contains(name.toLowerCase())) continue;
      if (!RegExp(r"^[!#$%&'*+.^_`|~0-9A-Za-z-]+$").hasMatch(name) ||
          name.runes.any((c) => c < 32 || c == 127) ||
          value.runes.any((c) => c < 32 && c != 9 || c == 127)) {
        continue;
      }
      final normalizedName = name.toLowerCase();
      if (headers.containsKey(normalizedName)) continue;
      headers[normalizedName] = value;
      if (headers.length >= 32) break;
    }
    return Map.unmodifiable(headers);
  }

  static Uri? _parseStreamUri(String raw, {required bool allowHttp}) {
    if (raw.length > 4096 || raw.runes.any((rune) => rune < 0x20 || rune == 0x7f)) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.host.isEmpty || uri.userInfo.isNotEmpty || uri.hasFragment) return null;
    if (uri.scheme != 'https' && !(allowHttp && uri.scheme == 'http')) return null;
    return uri;
  }

  static String? _validHash(String value) {
    final hash = value.toLowerCase();
    return RegExp(r'^(?:[0-9a-f]{40}|[0-9a-f]{64})$').hasMatch(hash) ? hash : null;
  }

  static String? _displayText(Object? raw) {
    if (raw is! String) return null;
    final value = raw.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '').trim();
    if (value.isEmpty) return null;
    return value.length > 240 ? value.substring(0, 240) : value;
  }

  void close() => _client.close();
}

class _AddonResource {
  const _AddonResource(this.name, this.types, this.idPrefixes);
  final String name;
  final Set<String> types;
  final List<String> idPrefixes;

  bool supports(String name, String type, [String? id]) =>
      this.name == name &&
      (types.isEmpty || types.contains(type)) &&
      (idPrefixes.isEmpty || id == null || idPrefixes.any(id.startsWith));

  static _AddonResource? tryParse(Object? raw) {
    if (raw is String) return _AddonResource(raw, const {}, const []);
    if (raw is! Map) return null;
    final row = Map<String, dynamic>.from(raw);
    final name = row['name'];
    if (name is! String) return null;
    final types = (row['types'] as List? ?? const []).whereType<String>().toSet();
    final prefixes = (row['idPrefixes'] as List? ?? const []).whereType<String>().toList(growable: false);
    return _AddonResource(name, types, prefixes);
  }
}
