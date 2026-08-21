import '../../media/media_rating.dart';
import '../../media/media_kind.dart';
import '../../models/catalog/catalog_cast_member.dart';
import '../../models/catalog/catalog_item.dart';
import '../../models/catalog/catalog_metadata.dart';
import '../../utils/external_ids.dart';
import '../../utils/app_logger.dart';
import '../../utils/country_codes.dart';
import '../../utils/json_utils.dart';
import '../plex_discover_client.dart';
import '../plex_mappers.dart';
import 'catalog_source.dart';
import 'catalog_watchlist_machinery.dart';

/// [CatalogSource] backed by the active Plex profile's universal watchlist
/// and Discover's Home shelves (what Plex's own web client shows on its
/// Home ▸ Trending tab).
class PlexCatalogSource with CatalogWatchlistMachinery implements CatalogSource, CatalogHubSource {
  final PlexDiscoverClient _client;
  final bool includeImageVariants;
  final Map<String, String> _hubKeys = {};

  PlexCatalogSource(this._client, {this.includeImageVariants = false});

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

  // Discover validates X-Plex-Container-Size against a cap it drifts
  // without notice (#1715: 500 became invalid). 100 keeps the snapshot at
  // few requests while staying well under the observed cap, and the client
  // degrades to 25-item chunks if the cap ever drops below it; more pages
  // preserve the 5000-entry coverage.
  @override
  int get watchlistPageLimit => 100;

  @override
  int get watchlistMaxPages => 50;

  @override
  Future<CatalogPage> fetchRow(CatalogRowId row, {int page = 1, int limit = 25}) async {
    if (row != CatalogRowId.watchlist) throw ArgumentError('Plex does not serve ${row.name}');
    final response = await _client.getWatchlist(page: page, limit: limit);
    return CatalogPage(
      items: _fromMetadata(response.items),
      hasMore: response.hasMore,
      totalResults: response.totalResults,
    );
  }

  @override
  Future<List<CatalogHub>> fetchHubs({int limit = 25}) async {
    final fetched = await _client.getHomeHubs(limit: limit, includeImageVariants: includeImageVariants);
    final keys = <String, String>{};
    final result = <CatalogHub>[];
    for (final hub in fetched) {
      final items = _fromMetadata(hub.page.items);
      if (items.isEmpty) continue;
      final style = _hubStyleFor(hub.style);
      keys[hub.id] = hub.key;
      result.add(
        CatalogHub(
          id: hub.id,
          title: hub.title,
          style: style,
          page: CatalogPage(items: items, hasMore: hub.page.hasMore, totalResults: hub.page.totalResults),
        ),
      );
    }
    _hubKeys
      ..clear()
      ..addAll(keys);
    return result;
  }

  /// Discover serves a hub in one shot — it ignores container offsets — so
  /// View All has nothing to page into beyond the first request.
  @override
  Future<CatalogPage> fetchHub(String id, {int page = 1, int limit = 25}) async {
    final key = _hubKeys[id];
    if (key == null || page > 1) return const CatalogPage(items: []);
    final response = await _client.getHub(key, limit: limit, includeImageVariants: includeImageVariants);
    return CatalogPage(items: _fromMetadata(response.items), hasMore: false, totalResults: response.totalResults);
  }

  @override
  Future<List<CatalogItem>> search(String query, {int limit = 30}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    return _fromSearchResults(await _client.search(trimmed, limit: limit));
  }

  @override
  Future<CatalogItemIds?> resolveItemIds(MediaKind kind, ExternalIds external) async {
    // Plex Discover matches on imdb/tmdb/tvdb only; an AniDB-only item has
    // nothing to send it.
    if (!external.hasCatalogIds) return null;
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
  Future<CatalogDetail> fetchDetail(CatalogItem item, {int castLimit = 20, int relatedLimit = 20}) async {
    final ratingKey = item.ids.plex;
    if (ratingKey == null || ratingKey.isEmpty) return CatalogDetail(item: item);

    final metadataFuture = _loadDetailMetadata(ratingKey);
    final relatedFuture = _loadRelatedMetadata(ratingKey);
    final metadata = await metadataFuture;
    final relatedMetadata = await relatedFuture;
    final detailItem = metadata == null ? null : _toCatalogItem(metadata);
    final safeCastLimit = castLimit < 0 ? 0 : castLimit;
    final safeRelatedLimit = relatedLimit < 0 ? 0 : relatedLimit;

    return CatalogDetail(
      item: detailItem == null ? item : item.enrichedWith(detailItem),
      cast: metadata == null
          ? const []
          : [
              for (final role in flexibleMapList(metadata['Role']).take(safeCastLimit))
                if (_nonEmptyString(role['tag'] ?? role['name']) case final String name)
                  CatalogCastMember(
                    name: name,
                    secondary: _nonEmptyString(role['role']),
                    imageUrl: _nonEmptyString(role['thumb']),
                  ),
            ],
      related: _fromMetadata(relatedMetadata).take(safeRelatedLimit).toList(),
    );
  }

  Future<Map<String, dynamic>?> _loadDetailMetadata(String ratingKey) async {
    try {
      return await _client.getMetadata(ratingKey);
    } catch (error, stackTrace) {
      appLogger.w('Plex: detail metadata failed', error: error, stackTrace: stackTrace);
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _loadRelatedMetadata(String ratingKey) async {
    try {
      return await _client.getRelated(ratingKey);
    } catch (error, stackTrace) {
      appLogger.w('Plex: related metadata failed', error: error, stackTrace: stackTrace);
      return const [];
    }
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

  List<CatalogItem> _fromSearchResults(List<PlexDiscoverSearchResult> results) {
    final items = <CatalogItem>[];
    final seen = <String>{};
    for (final result in results) {
      final item = _toCatalogItem(result.metadata);
      if (item != null && seen.add(item.identityKey)) items.add(item);
    }
    return items;
  }

  CatalogItem? _toCatalogItem(Map<String, dynamic> metadata) {
    final kind = _kindFor(metadata['type']);
    final title = _nonEmptyString(metadata['title']);
    final ids = _idsFor(metadata);
    if (kind == null || title == null || ids.plex == null) return null;

    final genres = _tagsFor(metadata['Genre']);
    final studios = _tagsFor(metadata['Studio']);
    final countries = _countriesFor(metadata['Country']);
    final credits = _creditsFor(metadata);
    final ratings = _ratingsFor(metadata);
    final durationMs = flexibleInt(metadata['duration']);
    final continuing = flexibleBoolNullable(metadata['isContinuingSeries']);
    final nextAirDate = kind == MediaKind.show
        ? _date(metadata['nextEpisodeOriginallyAvailableAt']) ?? _date(metadata['nextSeasonOriginallyAvailableAt'])
        : null;

    String? coverPoster;
    String? coverArt;
    String? background;
    String? clearLogo;
    String? clearLogoWide;
    String? imageBanner;
    for (final image in flexibleMapList(metadata['Image'])) {
      final type = _nonEmptyString(image['type']);
      final url = _nonEmptyString(image['url']);
      if (type == null || url == null) continue;
      switch (type) {
        case 'coverPoster':
          coverPoster ??= url;
        case 'coverArt':
          coverArt ??= url;
        case 'background':
          background ??= url;
        case 'clearLogo':
          clearLogo ??= url;
        case 'clearLogoWide':
          clearLogoWide ??= url;
        case 'banner':
          imageBanner ??= url;
      }
    }

    final headlineRating = normalizedPlexRating(metadata['rating']);
    final audienceRating = normalizedPlexRating(metadata['audienceRating']);
    return CatalogItem(
      source: CatalogSourceId.plex,
      kind: kind,
      title: title,
      year: flexibleInt(metadata['year']),
      overview: _overviewFor(metadata),
      runtimeMinutes: durationMs == null ? null : Duration(milliseconds: durationMs).inMinutes,
      rating: headlineRating ?? audienceRating,
      genres: genres,
      certification: _nonEmptyString(metadata['contentRating']),
      airStatus: kind == MediaKind.show && continuing != null
          ? continuing
                ? CatalogAirStatus.airing
                : CatalogAirStatus.ended
          : null,
      episodeCount: kind == MediaKind.show ? flexibleInt(metadata['leafCount']) : null,
      network: _nonEmptyString(metadata['studio'] ?? metadata['network']),
      ids: ids,
      posterUrl: _nonEmptyString(metadata['thumb']) ?? coverPoster ?? coverArt,
      backdropUrl: _nonEmptyString(metadata['art']) ?? background,
      logoUrl: clearLogoWide ?? clearLogo,
      bannerUrl: _nonEmptyString(metadata['banner']) ?? imageBanner,
      ratings: ratings,
      nextEpisode: nextAirDate == null ? null : CatalogNextEpisode(airsAt: nextAirDate),
      releaseDate: _date(metadata['originallyAvailableAt']),
      endDate: kind == MediaKind.show && continuing == false
          ? _date(metadata['lastEpisodeOriginallyAvailableAt']) ?? _date(metadata['lastSeasonOriginallyAvailableAt'])
          : null,
      originalTitle: _nonEmptyString(metadata['originalTitle']),
      tagline: _nonEmptyString(metadata['tagline']),
      studios: studios,
      countries: countries,
      credits: credits,
      contentAdvisory: _contentAdvisoryFor(metadata),
      budget: flexibleInt(metadata['budget']),
      revenue: flexibleInt(metadata['revenue']),
    );
  }

  static List<String>? _tagsFor(Object? value) {
    final tags = <String>[];
    final seen = <String>{};
    for (final entry in flexibleMapList(value)) {
      final tag = _nonEmptyString(entry['tag'] ?? entry['name']);
      if (tag != null && seen.add(tag)) tags.add(tag);
    }
    return tags.isEmpty ? null : tags;
  }

  static List<String>? _countriesFor(Object? value) {
    final countries = <String>[];
    final seen = <String>{};
    for (final entry in flexibleMapList(value)) {
      final tag = _nonEmptyString(entry['tag'] ?? entry['name']);
      if (tag == null) continue;
      final country = CountryCodes.normalizeCode(tag);
      if (country.isNotEmpty && seen.add(country)) countries.add(country);
    }
    return countries.isEmpty ? null : countries;
  }

  static List<CatalogCredit>? _creditsFor(Map<String, dynamic> metadata) {
    final credits = <CatalogCredit>[];
    final seen = <String>{};

    void addCredits(Object? value, CatalogCreditRole role) {
      for (final entry in flexibleMapList(value)) {
        final name = _nonEmptyString(entry['tag'] ?? entry['name'] ?? entry['role']);
        if (name != null && seen.add('${role.name}\u0000$name')) {
          credits.add(CatalogCredit(name: name, role: role));
        }
      }
    }

    addCredits(metadata['Director'], CatalogCreditRole.director);
    addCredits(metadata['Writer'], CatalogCreditRole.writer);
    addCredits(metadata['Producer'], CatalogCreditRole.producer);
    return credits.isEmpty ? null : credits;
  }

  static List<MediaRatingSource>? _ratingsFor(Map<String, dynamic> metadata) => plexRatingSources(
    rating: metadata['rating'],
    ratingImage: metadata['ratingImage'],
    audienceRating: metadata['audienceRating'],
    audienceRatingImage: metadata['audienceRatingImage'],
    ratingSources: [
      for (final rating in flexibleMapList(metadata['Rating']))
        (image: rating['image'], type: rating['type'], value: rating['value']),
    ],
    imdbVotes: flexibleInt(metadata['imdbRatingCount']),
  );

  static String? _overviewFor(Map<String, dynamic> metadata) {
    var overview = _nonEmptyString(metadata['summary']);
    for (final summary in flexibleMapList(metadata['Summary'])) {
      final candidate = _nonEmptyString(summary['tag'] ?? summary['summary']);
      if (candidate != null && (overview == null || candidate.length > overview.length)) {
        overview = candidate;
      }
    }
    return overview;
  }

  static String? _contentAdvisoryFor(Map<String, dynamic> metadata) {
    final advisories = <String>[];
    final seen = <String>{};
    for (final commonSense in flexibleMapList(metadata['CommonSenseMedia'])) {
      final oneLiner = _nonEmptyString(commonSense['oneLiner']);
      int? age;
      for (final rating in flexibleMapList(commonSense['AgeRating'])) {
        age ??= flexibleInt(rating['age']);
      }
      final advisory = [if (age != null) '$age+', ?oneLiner].join(' · ');
      if (advisory.isNotEmpty && seen.add(advisory)) advisories.add(advisory);
    }
    return advisories.isEmpty ? null : advisories.join('\n');
  }

  static DateTime? _date(Object? value) => value is String ? DateTime.tryParse(value) : null;

  static MediaKind? _kindFor(Object? type) => switch (type) {
    'movie' => MediaKind.movie,
    'show' => MediaKind.show,
    _ => null,
  };

  static CatalogHubStyle? _hubStyleFor(Object? style) => switch (style) {
    'shelf' => CatalogHubStyle.shelf,
    'availabilityPlatforms' => CatalogHubStyle.availabilityPlatforms,
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
