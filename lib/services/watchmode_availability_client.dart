import 'dart:convert';

import 'package:http/http.dart' as http;

import 'plezy_server.dart';

class WatchmodeAvailabilitySource {
  const WatchmodeAvailabilitySource({
    required this.sourceId,
    required this.name,
    required this.type,
    required this.region,
    this.format,
    this.price,
    this.webUrl,
    this.iosUrl,
    this.androidUrl,
    this.tvosUrl,
    this.androidTvUrl,
  });

  final int sourceId;
  final String name;
  final String type;
  final String region;
  final String? format;
  /// API-provided text only. Null means unknown; the client never treats it as zero.
  final String? price;
  final String? webUrl;
  final String? iosUrl;
  final String? androidUrl;
  final String? tvosUrl;
  final String? androidTvUrl;

  String get typeLabel => switch (type) {
    'sub' => 'SUB',
    'rent' => 'RENT',
    'buy' => 'BUY',
    'free' => 'FREE',
    'tve' => 'TV',
    _ => '',
  };

  factory WatchmodeAvailabilitySource.fromJson(Map<String, Object?> json, String region) {
    final sourceId = json['sourceId'];
    final name = json['name'];
    final type = json['type'];
    final rowRegion = json['region'];
    if (sourceId is! int ||
        sourceId < 1 ||
        name is! String ||
        name.trim().isEmpty ||
        name.length > 120 ||
        type is! String ||
        !const {'sub', 'rent', 'buy', 'free', 'tve'}.contains(type) ||
        rowRegion != region) {
      throw const FormatException('Invalid Watchmode source row');
    }
    return WatchmodeAvailabilitySource(
      sourceId: sourceId,
      name: name.trim(),
      type: type,
      region: region,
      format: _optionalText(json['format'], 32),
      price: _optionalText(json['price'], 32),
      webUrl: _safeHttpsUrl(json['webUrl']),
      iosUrl: _safeHttpsUrl(json['iosUrl']),
      androidUrl: _safeHttpsUrl(json['androidUrl']),
      tvosUrl: _safeHttpsUrl(json['tvosUrl']),
      androidTvUrl: _safeHttpsUrl(json['androidTvUrl']),
    );
  }
}

class WatchmodeAvailabilityResult {
  const WatchmodeAvailabilityResult({
    required this.tmdbType,
    required this.tmdbId,
    required this.region,
    required this.sources,
    this.fetchedAt,
    this.expiresAt,
  });

  final String tmdbType;
  final int tmdbId;
  final String region;
  final List<WatchmodeAvailabilitySource> sources;
  final DateTime? fetchedAt;
  final DateTime? expiresAt;
}

class WatchmodeAvailabilityClient {
  WatchmodeAvailabilityClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  void dispose() => _http.close();

  Future<WatchmodeAvailabilityResult?> lookup({
    required String tmdbType,
    required int tmdbId,
    required String region,
  }) async {
    final type = tmdbType.toLowerCase();
    final country = region.toUpperCase();
    if ((type != 'movie' && type != 'tv') ||
        tmdbId < 1 ||
        tmdbId > 0x7fffffff ||
        !RegExp(r'^[A-Z]{2}$').hasMatch(country)) {
      return null;
    }

    final base = plezyWatchmodeAvailabilityBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/commerce/watchmode-availability').replace(
      queryParameters: {'tmdbType': type, 'tmdbId': tmdbId.toString(), 'region': country},
    );
    try {
      final response = await _http.get(uri, headers: const {'Accept': 'application/json'}).timeout(
        const Duration(seconds: 8),
      );
      if (response.statusCode != 200 || response.bodyBytes.length > 256 * 1024) return null;
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic> ||
          decoded['tmdbType'] != type ||
          decoded['tmdbId'] != tmdbId ||
          decoded['region'] != country) {
        return null;
      }
      final rawSources = decoded['sources'];
      if (rawSources is! List || rawSources.length > 50) return null;
      final sources = <WatchmodeAvailabilitySource>[];
      final seen = <String>{};
      for (final raw in rawSources) {
        if (raw is! Map<String, dynamic>) return null;
        final source = WatchmodeAvailabilitySource.fromJson(raw, country);
        final key = source.sourceId.toString() + ':' + source.type + ':' + (source.format ?? '');
        if (seen.add(key)) sources.add(source);
      }
      return WatchmodeAvailabilityResult(
        tmdbType: type,
        tmdbId: tmdbId,
        region: country,
        sources: List.unmodifiable(sources),
        fetchedAt: DateTime.tryParse(decoded['fetchedAt']?.toString() ?? ''),
        expiresAt: DateTime.tryParse(decoded['expiresAt']?.toString() ?? ''),
      );
    } on Object {
      return null;
    }
  }
}

String? _optionalText(Object? value, int maxLength) {
  if (value == null) return null;
  if (value is! String || value.length > maxLength) throw const FormatException('Invalid Watchmode text');
  final text = value.trim();
  return text.isEmpty ? null : text;
}

String? _safeHttpsUrl(Object? value) {
  if (value == null) return null;
  if (value is! String || value.length > 2048) throw const FormatException('Invalid Watchmode URL');
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment ||
      uri.hasPort) {
    return null;
  }
  return uri.toString();
}
