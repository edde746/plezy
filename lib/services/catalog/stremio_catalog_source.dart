import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../i18n/strings.g.dart';
import '../../media/media_kind.dart';
import '../../models/catalog/catalog_cast_member.dart';
import '../../models/catalog/catalog_item.dart';
import '../../models/catalog/catalog_metadata.dart';
import '../../services/remote_streams/remote_stream_models.dart';
import '../../services/remote_streams/remote_streaming_provider.dart';
import '../../services/remote_streams/stremio_addon_client.dart';
import '../../utils/external_ids.dart';
import 'catalog_source.dart';

typedef _StremioCatalogRoute = ({StremioAddonInstallation addon, StremioAddonCatalog catalog});

/// Presents configured Stremio catalogs through the existing Explore and
/// catalog-detail contracts. Add-on installation IDs travel with each item so
/// detail and stream lookup stay bound to the add-on that supplied it.
class StremioCatalogSource implements CatalogSource, CatalogHubSource {
  StremioCatalogSource(this._streaming);

  static const int _maxSearchCatalogs = 20;
  static const int _requestBatchSize = 4;

  final RemoteStreamingProvider _streaming;
  final StremioAddonClient _client = StremioAddonClient();
  final WatchlistChangeNotifier _watchlistChanges = WatchlistChangeNotifier();
  bool _disposed = false;

  @override
  CatalogSourceId get id => CatalogSourceId.stremio;

  @override
  String get displayName => t.streaming.addons;

  @override
  List<CatalogRowId> get supportedRows => const [];

  @override
  bool get supportsWatchlist => false;

  bool get hasCatalogs => _routes.any((route) => route.catalog.canBrowse || route.catalog.supportsSearch);

  List<_StremioCatalogRoute> get _routes {
    if (_disposed || !_streaming.isReady || _streaming.profileId == null) return const [];
    return [
      for (final addon in _streaming.addons)
        if (addon.enabled)
          for (final catalog in _client.catalogs(addon))
            (addon: addon, catalog: catalog),
    ];
  }

  @override
  Listenable get watchlistChanges => _watchlistChanges;

  @override
  Future<List<CatalogHub>> fetchHubs({int limit = 25}) async {
    final routes = _routes.where((route) => route.catalog.canBrowse).take(limit.clamp(0, 40).toInt()).toList();
    final hubs = <CatalogHub>[];
    for (var start = 0; start < routes.length; start += _requestBatchSize) {
      final batch = routes.skip(start).take(_requestBatchSize);
      hubs.addAll(await Future.wait(batch.map(_loadHubFirstPage)));
    }
    return List.unmodifiable(hubs);
  }

  Future<CatalogHub> _loadHubFirstPage(_StremioCatalogRoute route) async {
    final id = _routeId(route.addon.id, route.catalog.type, route.catalog.id);
    final title = '${route.addon.name} · ${route.catalog.name}';
    try {
      final page = await _fetchCatalogPage(route, page: 1, limit: 25);
      return CatalogHub(id: id, title: title, page: page);
    } on Object {
      return CatalogHub(
        id: id,
        title: title,
        page: const CatalogPage(items: []),
        errorMessage: t.streaming.catalogLoadFailed,
      );
    }
  }

  @override
  Future<CatalogPage> fetchHub(String id, {int page = 1, int limit = 25}) async {
    if (page < 1 || limit < 1 || limit > 100) throw ArgumentError('Invalid Stremio catalog page');
    final route = _routeForId(id);
    if (route == null) throw const StremioAddonException(StremioAddonFailure.unsupportedResource);
    return _fetchCatalogPage(route, page: page, limit: limit);
  }

  Future<CatalogPage> _fetchCatalogPage(_StremioCatalogRoute route, {required int page, required int limit}) async {
    final profile = _streaming.profileId;
    if (profile == null || !_addonIsCurrent(route.addon.id, profile)) {
      throw const StremioAddonException(StremioAddonFailure.unavailable);
    }
    final skip = (page - 1) * limit;
    final rows = await _client.fetchCatalog(route.addon, route.catalog, skip: skip);
    if (!_addonIsCurrent(route.addon.id, profile)) {
      throw const StremioAddonException(StremioAddonFailure.unavailable);
    }
    final items = <CatalogItem>[];
    final seen = <String>{};
    for (final row in rows) {
      final item = _toCatalogItem(route.addon, row, defaultType: route.catalog.type);
      if (item != null && seen.add(_dedupeKey(item))) items.add(item);
      if (items.length >= limit) break;
    }
    return CatalogPage(
      items: List.unmodifiable(items),
      hasMore: route.catalog.supportsSkip && rows.length >= limit,
    );
  }

  @override
  Future<List<CatalogItem>> search(String query, {int limit = 30}) async {
    final trimmed = query.trim();
    if (trimmed.length < 2 || limit <= 0) return const [];
    final routes = _routes
        .where((route) => route.catalog.supportsSearch)
        .take(_maxSearchCatalogs)
        .toList(growable: false);
    if (routes.isEmpty) return const [];
    final profile = _streaming.profileId;
    if (profile == null) return const [];
    final results = <CatalogItem>[];
    var succeeded = 0;
    for (var start = 0; start < routes.length; start += _requestBatchSize) {
      final batch = routes.skip(start).take(_requestBatchSize);
      final answers = await Future.wait([
        for (final route in batch) _searchRoute(route, trimmed, profile),
      ]);
      for (final answer in answers) {
        if (answer != null) {
          succeeded++;
          results.addAll(answer);
        }
      }
    }
    if (succeeded == 0) throw const StremioAddonException(StremioAddonFailure.unavailable);
    final seen = <String>{};
    return List.unmodifiable([
      for (final item in results)
        if (seen.add(_dedupeKey(item))) item,
    ].take(limit));
  }

  Future<List<CatalogItem>?> _searchRoute(_StremioCatalogRoute route, String query, String profile) async {
    try {
      if (!_addonIsCurrent(route.addon.id, profile)) return null;
      final rows = await _client.searchCatalog(route.addon, route.catalog, query);
      if (!_addonIsCurrent(route.addon.id, profile)) return null;
      return [
        for (final row in rows)
          if (_toCatalogItem(route.addon, row, defaultType: route.catalog.type) case final item?) item,
      ];
    } on Object {
      return null;
    }
  }

  @override
  Future<CatalogDetail> fetchDetail(CatalogItem item, {int castLimit = 20, int relatedLimit = 20}) async {
    final installationId = item.sourceInstallationId;
    final itemId = item.sourceItemId;
    if (installationId == null || itemId == null || !_streaming.isReady) return CatalogDetail(item: item);
    final profile = _streaming.profileId;
    final addon = _enabledAddon(installationId);
    if (profile == null || addon == null) return CatalogDetail(item: item);
    final type = item.kind == MediaKind.movie ? 'movie' : 'series';
    try {
      final meta = await _client.fetchMeta(addon, type, itemId);
      if (meta == null || !_addonIsCurrent(addon.id, profile)) return CatalogDetail(item: item);
      final detail = _toCatalogItem(addon, meta, defaultType: type);
      if (detail == null) return CatalogDetail(item: item);
      final cast = <CatalogCastMember>[];
      final rawCast = meta['cast'];
      if (rawCast is List) {
        for (final entry in rawCast) {
          final name = entry is String ? entry : entry is Map ? entry['name'] : null;
          final clean = _displayText(name);
          if (clean != null) cast.add(CatalogCastMember(name: clean));
          if (cast.length >= castLimit) break;
        }
      }
      return CatalogDetail(
        item: item.enrichedWith(detail),
        cast: List.unmodifiable(cast),
        episodes: _episodes(meta['videos']),
      );
    } on Object {
      return CatalogDetail(item: item);
    }
  }

  CatalogItem? _toCatalogItem(StremioAddonInstallation addon, Map<String, dynamic> row, {required String defaultType}) {
    final id = _displayText(row['id']);
    final title = _displayText(row['name']) ?? _displayText(row['title']);
    if (id == null || title == null) return null;
    final rawType = row['type'];
    final type = rawType is String && const {'movie', 'series'}.contains(rawType) ? rawType : defaultType;
    if (!const {'movie', 'series'}.contains(type)) return null;
    final kind = type == 'movie' ? MediaKind.movie : MediaKind.show;
    final imdb = RegExp(r'^tt\d{6,12}$').hasMatch(id) ? id : null;
    final tmdbMatch = RegExp(r'^tmdb:(\d+)$').firstMatch(id);
    final tvdbMatch = RegExp(r'^tvdb:(\d+)$').firstMatch(id);
    final year = _year(row['year']) ?? _year(row['releaseInfo']);
    final rating = _number(row['imdbRating'] ?? row['rating']);
    final genres = row['genres'] is List ? (row['genres'] as List).whereType<String>().map(_cleanText).whereType<String>().take(20).toList() : null;
    return CatalogItem(
      source: CatalogSourceId.stremio,
      sourceInstallationId: addon.id,
      sourceItemId: id,
      kind: kind,
      title: title,
      year: year,
      overview: _displayText(row['description']),
      runtimeMinutes: _runtime(row['runtime']),
      rating: rating != null && rating >= 0 && rating <= 10 ? rating : null,
      genres: genres?.isEmpty == true ? null : genres,
      isAdult: row['isAdult'] is bool ? row['isAdult'] as bool : null,
      ids: CatalogItemIds(
        imdb: imdb,
        tmdb: tmdbMatch == null ? null : int.tryParse(tmdbMatch.group(1)!),
        tvdb: tvdbMatch == null ? null : int.tryParse(tvdbMatch.group(1)!),
        slug: 'stremio:${addon.id}:$id',
      ),
      posterUrl: _mediaUrl(row['poster'], addon),
      backdropUrl: _mediaUrl(row['background'], addon),
      links: _links(row['links'], addon),
    );
  }

  static List<CatalogEpisode> _episodes(Object? raw) {
    if (raw is! List) return const [];
    final result = <CatalogEpisode>[];
    final seen = <String>{};
    for (final value in raw.take(300)) {
      if (value is! Map) continue;
      final row = Map<String, dynamic>.from(value);
      final id = _displayText(row['id']);
      final title = _displayText(row['name']) ?? _displayText(row['title']) ?? id;
      if (id == null || title == null || !seen.add(id)) continue;
      final season = _episodeNumber(row['season']);
      final episode = _episodeNumber(row['episode']);
      result.add(
        CatalogEpisode(
          id: id,
          title: title,
          seasonNumber: season,
          episodeNumber: episode,
          year: _year(row['released']),
          runtimeMinutes: _runtime(row['runtime']),
          overview: _displayText(row['overview'] ?? row['description']),
        ),
      );
    }
    result.sort((left, right) {
      final season = (left.seasonNumber ?? 0).compareTo(right.seasonNumber ?? 0);
      if (season != 0) return season;
      return (left.episodeNumber ?? 0).compareTo(right.episodeNumber ?? 0);
    });
    return List.unmodifiable(result);
  }

  static int? _episodeNumber(Object? raw) {
    final value = raw is num ? raw.toInt() : raw is String ? int.tryParse(raw) : null;
    return value != null && value >= 0 && value <= 10000 ? value : null;
  }

  static String _dedupeKey(CatalogItem item) => '${item.kind.id}/${item.ids.canonicalKey ?? item.ids.entryKey}';

  static List<CatalogLink>? _links(Object? raw, StremioAddonInstallation addon) {
    if (raw is! List) return null;
    final links = <CatalogLink>[];
    for (final value in raw) {
      if (value is! Map) continue;
      final row = Map<String, dynamic>.from(value);
      final label = _displayText(row['name']);
      final url = _mediaUrl(row['url'], addon);
      if (label == null || url == null) continue;
      links.add(CatalogLink(label: label, url: url, isStreaming: row['category'] == 'watch'));
      if (links.length >= 20) break;
    }
    return links.isEmpty ? null : List.unmodifiable(links);
  }

  static String? _mediaUrl(Object? raw, StremioAddonInstallation addon) {
    if (raw is! String || raw.length > 4096 || raw.runes.any((rune) => rune < 0x20 || rune == 0x7f)) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.host.isEmpty || uri.userInfo.isNotEmpty || uri.hasFragment) return null;
    if (uri.scheme != 'https' && !(addon.allowHttp && uri.scheme == 'http')) return null;
    return uri.toString();
  }

  static int? _year(Object? raw) {
    if (raw is num) {
      final value = raw.toInt();
      return value >= 1870 && value <= 2200 ? value : null;
    }
    if (raw is! String) return null;
    final match = RegExp(r'\b(18\d{2}|19\d{2}|20\d{2}|21\d{2}|2200)\b').firstMatch(raw);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  static double? _number(Object? raw) => raw is num ? raw.toDouble() : raw is String ? double.tryParse(raw) : null;

  static int? _runtime(Object? raw) {
    if (raw is num) {
      final value = raw.toInt();
      return value > 0 && value <= 1000 ? value : null;
    }
    if (raw is! String) return null;
    final hours = int.tryParse(RegExp(r'(\d+)\s*h').firstMatch(raw)?.group(1) ?? '') ?? 0;
    final minutes = int.tryParse(RegExp(r'(\d+)\s*m(?:in)?').firstMatch(raw)?.group(1) ?? '') ?? 0;
    final total = hours * 60 + minutes;
    return total > 0 && total <= 1000 ? total : null;
  }

  static String? _displayText(Object? raw) => raw is String ? _cleanText(raw) : null;

  static String? _cleanText(String raw) {
    final clean = raw.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '').trim();
    if (clean.isEmpty) return null;
    return clean.length > 500 ? clean.substring(0, 500) : clean;
  }

  static String _routeId(String addonId, String type, String catalogId) =>
      'stremio:${base64Url.encode(utf8.encode(jsonEncode([addonId, type, catalogId]))).replaceAll('=', '')}';

  _StremioCatalogRoute? _routeForId(String id) {
    if (!id.startsWith('stremio:')) return null;
    try {
      final encoded = base64Url.normalize(id.substring('stremio:'.length));
      final value = jsonDecode(utf8.decode(base64Url.decode(encoded)));
      if (value is! List || value.length != 3 || value.any((part) => part is! String)) return null;
      final addon = _enabledAddon(value[0] as String);
      if (addon == null) return null;
      final catalog = _client.catalogs(addon).where((item) => item.type == value[1] && item.id == value[2]).firstOrNull;
      return catalog == null || !catalog.canBrowse ? null : (addon: addon, catalog: catalog);
    } on Object {
      return null;
    }
  }

  StremioAddonInstallation? _enabledAddon(String id) =>
      _streaming.addons.where((addon) => addon.id == id && addon.enabled).firstOrNull;

  bool _addonIsCurrent(String addonId, String profile) =>
      !_disposed && _streaming.isReady && _streaming.profileId == profile && _enabledAddon(addonId) != null;

  @override
  Future<CatalogItemIds?> resolveItemIds(MediaKind kind, ExternalIds external) async => null;

  @override
  Future<void> ensureWatchlistLoaded() async {}

  @override
  bool? isOnWatchlist(MediaKind kind, CatalogItemIds ids) => null;

  @override
  Future<void> addToWatchlist(MediaKind kind, CatalogItemIds ids) =>
      throw UnsupportedError('Stremio add-ons do not provide a watchlist');

  @override
  Future<void> removeFromWatchlist(MediaKind kind, CatalogItemIds ids) =>
      throw UnsupportedError('Stremio add-ons do not provide a watchlist');

  @override
  Future<CatalogPage> fetchRow(CatalogRowId row, {int page = 1, int limit = 25}) =>
      throw ArgumentError('Stremio add-ons do not serve fixed rows');

  @override
  void dispose() {
    _disposed = true;
    _client.close();
    _watchlistChanges.dispose();
  }
}
