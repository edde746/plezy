import '../../media/media_kind.dart';
import '../../models/catalog/catalog_cast_member.dart';
import '../../models/catalog/catalog_item.dart';
import '../../utils/external_ids.dart';
import '../../utils/json_utils.dart';
import '../plex_discover_client.dart';
import 'catalog_source.dart';
import 'catalog_watchlist_machinery.dart';

/// [CatalogSource] backed by the active Plex profile's universal watchlist
/// and its provider-defined recommendation hubs.
class PlexCatalogSource with CatalogWatchlistMachinery implements CatalogSource, CatalogHubSource {
  final PlexDiscoverClient _client;
  final Map<String, String> _hubKeys = {};

  PlexCatalogSource(this._client);

  @override
  CatalogSourceId get id => CatalogSourceId.plex;

  @override
  String get displayName => 'Plex';

  @override
  List<CatalogRowId> get supportedRows => const [CatalogRowId.watchlist];

  @override
  bool get supportsWatchlist => true;

  @override
  String get watchlistLogLabel => 'Plex: watchlist';

  @override
  int get watchlistPageLimit => 500;

  @override
  int get watchlistMaxPages => 10;

  @override
  Future<CatalogPage> fetchRow(CatalogRowId row, {int page = 1, int limit = 25}) async {
    if (row != CatalogRowId.watchlist) throw ArgumentError('Plex does not serve ${row.name}');
    final response = await _client.getWatchlist(page: page, limit: limit);
    return CatalogPage(items: _fromMetadata(response.items), hasMore: response.hasMore);
  }

  @override
  Future<List<CatalogHub>> fetchHubs({int limit = 25}) async {
    final fetched = await _client.getRecommendedHubs(limit: limit);
    final keys = <String, String>{};
    final result = <CatalogHub>[];
    for (final hub in fetched) {
      final items = _fromMetadata(hub.page.items);
      if (items.isEmpty) continue;
      keys[hub.id] = hub.key;
      result.add(
        CatalogHub(
          id: hub.id,
          title: hub.title,
          page: CatalogPage(items: items, hasMore: hub.page.hasMore),
        ),
      );
    }
    _hubKeys
      ..clear()
      ..addAll(keys);
    return result;
  }

  @override
  Future<CatalogPage> fetchHub(String id, {int page = 1, int limit = 25}) async {
    final key = _hubKeys[id];
    if (key == null) return const CatalogPage(items: []);
    final response = await _client.getHub(key, page: page, limit: limit);
    return CatalogPage(items: _fromMetadata(response.items), hasMore: response.hasMore);
  }

  @override
  Future<List<CatalogItem>> search(String query, {int limit = 30}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    return _fromMetadata(await _client.search(trimmed, limit: limit));
  }

  @override
  Future<CatalogItemIds?> resolveItemIds(MediaKind kind, ExternalIds external) async {
    if (!external.hasAny) return null;
    final metadata = await _client.match(external);
    final matchedKind = metadata == null ? null : _kindFor(metadata['type']);
    if (metadata == null || matchedKind != kind) return null;
    final ids = _idsFor(metadata);
    if (ids.plex == null) return null;
    return CatalogItemIds(
      plex: ids.plex,
      imdb: ids.imdb ?? external.imdb,
      tmdb: ids.tmdb ?? external.tmdb,
      tvdb: ids.tvdb ?? external.tvdb,
    );
  }

  @override
  Future<CatalogItemIds> resolveWatchlistMutationIds(MediaKind kind, CatalogItemIds ids) async {
    if (ids.plex != null && ids.plex!.isNotEmpty) return ids;
    final resolved = await resolveItemIds(kind, ids.toExternalIds());
    if (resolved?.plex == null || resolved!.plex!.isEmpty) {
      throw StateError('Plex: no rating key for ${ids.canonicalKey ?? 'item'}');
    }
    return resolved;
  }

  @override
  Future<List<CatalogCastMember>> fetchCast(CatalogItem item, {int limit = 20}) async {
    final ratingKey = item.ids.plex;
    if (ratingKey == null) return const [];
    final metadata = await _client.getMetadata(ratingKey);
    if (metadata == null) return const [];
    return [
      for (final role in flexibleMapList(metadata['Role']).take(limit))
        if (_nonEmptyString(role['tag'] ?? role['name']) case final String name)
          CatalogCastMember(
            name: name,
            secondary: _nonEmptyString(role['role']),
            imageUrl: _nonEmptyString(role['thumb']),
          ),
    ];
  }

  @override
  Future<List<CatalogItem>> fetchRelated(CatalogItem item, {int limit = 20}) async {
    final ratingKey = item.ids.plex;
    if (ratingKey == null) return const [];
    return _fromMetadata(await _client.getRelated(ratingKey)).take(limit).toList();
  }

  @override
  Future<WatchlistKeyPage> fetchWatchlistKeyPage(int page, int limit) async {
    final response = await _client.getWatchlist(page: page, limit: limit);
    return (
      groups: [for (final item in _fromMetadata(response.items)) membershipKeysFor(item.kind, item.ids)],
      hasMore: response.hasMore,
    );
  }

  @override
  Future<void> performWatchlistMutation(MediaKind kind, CatalogItemIds ids, {required bool add}) async {
    final ratingKey = ids.plex;
    if (ratingKey == null || ratingKey.isEmpty) {
      throw ArgumentError('Plex watchlist mutations require a Plex rating key');
    }
    await _client.setWatchlisted(ratingKey, add: add);
  }

  List<CatalogItem> _fromMetadata(List<Map<String, dynamic>> metadata) {
    final items = <CatalogItem>[];
    final seen = <String>{};
    for (final value in metadata) {
      final item = _toCatalogItem(value);
      if (item != null && seen.add(item.identityKey)) items.add(item);
    }
    return items;
  }

  CatalogItem? _toCatalogItem(Map<String, dynamic> metadata) {
    final kind = _kindFor(metadata['type']);
    final title = _nonEmptyString(metadata['title']);
    final ids = _idsFor(metadata);
    if (kind == null || title == null || ids.plex == null) return null;

    final genres = [
      for (final genre in flexibleMapList(metadata['Genre']))
        if (_nonEmptyString(genre['tag']) case final String name) name,
    ];
    final durationMs = flexibleInt(metadata['duration']);
    return CatalogItem(
      source: CatalogSourceId.plex,
      kind: kind,
      title: title,
      year: flexibleInt(metadata['year']),
      overview: _nonEmptyString(metadata['summary']),
      runtimeMinutes: durationMs == null ? null : Duration(milliseconds: durationMs).inMinutes,
      rating: flexibleDouble(metadata['rating'] ?? metadata['audienceRating']),
      genres: genres.isEmpty ? null : genres,
      certification: _nonEmptyString(metadata['contentRating']),
      episodeCount: kind == MediaKind.show ? flexibleInt(metadata['leafCount']) : null,
      network: _nonEmptyString(metadata['studio'] ?? metadata['network']),
      ids: ids,
      posterUrl: _nonEmptyString(metadata['thumb']),
      backdropUrl: _nonEmptyString(metadata['art']),
    );
  }

  static MediaKind? _kindFor(Object? type) => switch (type) {
    'movie' => MediaKind.movie,
    'show' => MediaKind.show,
    _ => null,
  };

  static CatalogItemIds _idsFor(Map<String, dynamic> metadata) {
    String? imdb;
    int? tmdb;
    int? tvdb;

    void consumeGuid(Object? value) {
      final guid = _nonEmptyString(value);
      if (guid == null) return;
      final separator = guid.indexOf('://');
      if (separator <= 0) return;
      final provider = guid.substring(0, separator).toLowerCase();
      final id = guid.substring(separator + 3);
      switch (provider) {
        case 'imdb':
          imdb ??= id;
        case 'tmdb':
          tmdb ??= int.tryParse(id);
        case 'tvdb':
          tvdb ??= int.tryParse(id);
      }
    }

    consumeGuid(metadata['guid']);
    for (final guid in flexibleMapList(metadata['Guid'])) {
      consumeGuid(guid['id']);
    }

    return CatalogItemIds(plex: _nonEmptyString(metadata['ratingKey']), imdb: imdb, tmdb: tmdb, tvdb: tvdb);
  }

  static String? _nonEmptyString(Object? value) {
    final string = value?.toString().trim();
    return string == null || string.isEmpty ? null : string;
  }

  @override
  void dispose() {
    disposeWatchlistMachinery();
    _client.dispose();
  }
}
