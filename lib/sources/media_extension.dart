import 'dart:convert';
import 'dart:io';

/// A deliberately data-only search extension. The manifest can describe one
/// HTTPS JSON endpoint and field names; it cannot load code, headers, scripts,
/// or filesystem paths.
class MediaSearchExtension {
  const MediaSearchExtension({
    required this.id,
    required this.name,
    required this.description,
    required this.endpoint,
    required this.queryParameter,
    required this.resultsPath,
    required this.titleField,
    required this.urlField,
    this.subtitleField,
  });

  static const maxManifestBytes = 64 * 1024;
  static final _idPattern = RegExp(r'^[a-z0-9][a-z0-9-]{0,47}$');
  static final _fieldPattern = RegExp(r'^[A-Za-z][A-Za-z0-9_-]{0,63}$');
  static final _sensitiveParameter = RegExp(
    r'(token|password|signature|credential|authorization|secret|api[_-]?key|^auth$|^key$|^code$|x-amz-|x-goog-|^(expires|expiry|expiration|policy|key-pair-id|sig|se|sp|sv|sr|st|skoid|sktid|skt|ske|sks|skv|rscc|rscd|rsct)$)',
    caseSensitive: false,
  );

  final String id;
  final String name;
  final String description;
  final Uri endpoint;
  final String queryParameter;
  final List<String> resultsPath;
  final String titleField;
  final String urlField;
  final String? subtitleField;

  String get host => endpoint.host;

  Map<String, Object?> toJson() => {
    'schema_version': 1,
    'id': id,
    'name': name,
    'description': description,
    'endpoint': endpoint.toString(),
    'query_parameter': queryParameter,
    'results_path': resultsPath,
    'title_field': titleField,
    'url_field': urlField,
    if (subtitleField != null) 'subtitle_field': subtitleField,
  };

  static MediaSearchExtension parseManifest(List<int> bytes) {
    if (bytes.isEmpty || bytes.length > maxManifestBytes) {
      throw const MediaExtensionException(MediaExtensionFailure.invalidManifest);
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const MediaExtensionException(MediaExtensionFailure.invalidManifest);
    }
    if (decoded is! Map<String, dynamic> || decoded['schema_version'] != 1) {
      throw const MediaExtensionException(MediaExtensionFailure.invalidManifest);
    }
    final manifest = decoded;
    const allowedKeys = {
      'schema_version',
      'id',
      'name',
      'description',
      'endpoint',
      'query_parameter',
      'results_path',
      'title_field',
      'url_field',
      'subtitle_field',
    };
    if (manifest.keys.any((key) => !allowedKeys.contains(key))) {
      throw const MediaExtensionException(MediaExtensionFailure.invalidManifest);
    }

    String text(String key, {required int maxLength, bool required = true}) {
      final value = manifest[key];
      if ((value == null || value == '') && !required) return '';
      if (value is! String || value.length > maxLength || value.trim().isEmpty) {
        throw const MediaExtensionException(MediaExtensionFailure.invalidManifest);
      }
      if (RegExp(r'[\x00-\x1f\x7f]').hasMatch(value)) {
        throw const MediaExtensionException(MediaExtensionFailure.invalidManifest);
      }
      return value.trim();
    }

    final id = text('id', maxLength: 48);
    final name = text('name', maxLength: 80);
    final description = text('description', maxLength: 240, required: false);
    final endpointText = text('endpoint', maxLength: 2048);
    final parameter = text('query_parameter', maxLength: 64);
    final titleField = text('title_field', maxLength: 64);
    final urlField = text('url_field', maxLength: 64);
    final subtitleText = text('subtitle_field', maxLength: 64, required: false);

    if (!_idPattern.hasMatch(id) ||
        !_fieldPattern.hasMatch(parameter) ||
        !_fieldPattern.hasMatch(titleField) ||
        !_fieldPattern.hasMatch(urlField) ||
        (subtitleText.isNotEmpty && !_fieldPattern.hasMatch(subtitleText))) {
      throw const MediaExtensionException(MediaExtensionFailure.invalidManifest);
    }

    final endpoint = Uri.tryParse(endpointText);
    if (endpoint == null ||
        endpoint.scheme.toLowerCase() != 'https' ||
        endpoint.host.isEmpty ||
        endpoint.userInfo.isNotEmpty ||
        endpoint.hasFragment ||
        endpoint.queryParameters.keys.any(_sensitiveParameter.hasMatch) ||
        endpoint.queryParameters.containsKey(parameter)) {
      throw const MediaExtensionException(MediaExtensionFailure.invalidEndpoint);
    }

    final rawPath = manifest['results_path'];
    if (rawPath is! List || rawPath.isEmpty || rawPath.length > 4) {
      throw const MediaExtensionException(MediaExtensionFailure.invalidManifest);
    }
    final path = <String>[];
    for (final segment in rawPath) {
      if (segment is! String || !_fieldPattern.hasMatch(segment)) {
        throw const MediaExtensionException(MediaExtensionFailure.invalidManifest);
      }
      path.add(segment);
    }

    return MediaSearchExtension(
      id: id,
      name: name,
      description: description,
      endpoint: endpoint,
      queryParameter: parameter,
      resultsPath: List.unmodifiable(path),
      titleField: titleField,
      urlField: urlField,
      subtitleField: subtitleText.isEmpty ? null : subtitleText,
    );
  }

  Uri searchUri(String query) {
    final parameters = <String, String>{...endpoint.queryParameters, queryParameter: query};
    return endpoint.replace(queryParameters: parameters);
  }
}

class MediaSearchResult {
  const MediaSearchResult({required this.title, required this.uri, this.subtitle});

  final String title;
  final Uri uri;
  final String? subtitle;
}

enum MediaExtensionFailure { invalidManifest, invalidEndpoint, endpointUnavailable, invalidResponse }

class MediaExtensionException implements Exception {
  const MediaExtensionException(this.failure);

  final MediaExtensionFailure failure;
}

class MediaExtensionHost {
  MediaExtensionHost._();

  static const maxResponseBytes = 1024 * 1024;
  static const maxResults = 20;

  static Future<List<MediaSearchResult>> search(MediaSearchExtension extension, String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty || normalized.length > 200) {
      throw const MediaExtensionException(MediaExtensionFailure.invalidResponse);
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(extension.searchUri(normalized)).timeout(const Duration(seconds: 8));
      request.followRedirects = false;
      request.maxRedirects = 0;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const MediaExtensionException(MediaExtensionFailure.endpointUnavailable);
      }
      final mimeType = response.headers.contentType?.mimeType.toLowerCase();
      if (mimeType != null && mimeType != 'application/json' && !mimeType.endsWith('+json')) {
        throw const MediaExtensionException(MediaExtensionFailure.invalidResponse);
      }
      if (response.contentLength > maxResponseBytes) {
        throw const MediaExtensionException(MediaExtensionFailure.invalidResponse);
      }

      final bytes = await _readBoundedBody(response).timeout(const Duration(seconds: 30));
      return parseResults(extension, bytes);
    } on MediaExtensionException {
      rethrow;
    } on Object {
      throw const MediaExtensionException(MediaExtensionFailure.endpointUnavailable);
    } finally {
      client.close(force: true);
    }
  }

  static Future<List<int>> _readBoundedBody(HttpClientResponse response) async {
    final bytes = <int>[];
    await for (final chunk in response) {
      if (bytes.length + chunk.length > maxResponseBytes) {
        throw const MediaExtensionException(MediaExtensionFailure.invalidResponse);
      }
      bytes.addAll(chunk);
    }
    return bytes;
  }

  static List<MediaSearchResult> parseResults(MediaSearchExtension extension, List<int> bytes) {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const MediaExtensionException(MediaExtensionFailure.invalidResponse);
    }

    Object? current = decoded;
    for (final segment in extension.resultsPath) {
      if (current is! Map<String, dynamic>) return const [];
      current = current[segment];
    }
    if (current is! List) return const [];

    final results = <MediaSearchResult>[];
    final seen = <String>{};
    for (final row in current) {
      if (results.length >= maxResults) break;
      if (row is! Map<String, dynamic>) continue;
      final rawTitle = row[extension.titleField];
      final rawUrl = row[extension.urlField];
      if (rawTitle is! String || rawUrl is! String || rawUrl.length > 4096) continue;

      final title = _cleanText(rawTitle, maxLength: 180);
      final uri = Uri.tryParse(rawUrl.trim());
      if (title.isEmpty ||
          uri == null ||
          uri.scheme.toLowerCase() != 'https' ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty ||
          uri.hasFragment ||
          !seen.add(uri.toString())) {
        continue;
      }

      final rawSubtitle = extension.subtitleField == null ? null : row[extension.subtitleField];
      final subtitle = rawSubtitle is String ? _cleanText(rawSubtitle, maxLength: 180) : '';
      results.add(MediaSearchResult(title: title, uri: uri, subtitle: subtitle.isEmpty ? null : subtitle));
    }
    return List.unmodifiable(results);
  }

  static String _cleanText(String value, {required int maxLength}) {
    final cleaned = value.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.substring(0, cleaned.length.clamp(0, maxLength).toInt());
  }
}
