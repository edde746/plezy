import 'dart:async';

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/app_logger.dart';
import '../utils/external_ids.dart';
import '../utils/json_utils.dart';

/// Credentials for Plex's cloud Discover provider. The access token is scoped
/// to the active Plex/Home profile; it must never be logged or persisted here.
class PlexDiscoverSession {
  final String accessToken;
  final String clientIdentifier;

  const PlexDiscoverSession({required this.accessToken, required this.clientIdentifier});

  bool get isUsable => accessToken.isNotEmpty && clientIdentifier.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is PlexDiscoverSession && other.accessToken == accessToken && other.clientIdentifier == clientIdentifier;

  @override
  int get hashCode => Object.hash(accessToken, clientIdentifier);
}

class PlexDiscoverPage {
  final List<Map<String, dynamic>> items;
  final bool hasMore;

  const PlexDiscoverPage({required this.items, this.hasMore = false});
}

class PlexDiscoverHub {
  final String id;
  final String key;
  final String title;
  final PlexDiscoverPage page;

  const PlexDiscoverHub({required this.id, required this.key, required this.title, required this.page});
}

class PlexDiscoverException implements Exception {
  final int statusCode;
  final String message;

  const PlexDiscoverException(this.statusCode, this.message);

  @override
  String toString() => 'PlexDiscoverException($statusCode): $message';
}

/// Minimal client for the Plex cloud catalog/watchlist API advertised by
/// `https://discover.provider.plex.tv/`.
class PlexDiscoverClient {
  static final Uri _baseUri = Uri.parse('https://discover.provider.plex.tv');

  /// Home shelf types whose entries never become a catalog item: `directory`
  /// shelves list browse categories, `clip` shelves list trailers.
  static const Set<String> _unrenderableHubTypes = {'directory', 'clip'};

  final PlexDiscoverSession session;
  final http.Client _http;
  final Duration requestTimeout;

  PlexDiscoverClient(this.session, {http.Client? httpClient, this.requestTimeout = const Duration(seconds: 20)})
    : _http = httpClient ?? http.Client();

  Future<PlexDiscoverPage> getWatchlist({int page = 1, int limit = 25}) async {
    final safePage = page < 1 ? 1 : page;
    final safeLimit = limit.clamp(1, 500);
    final offset = (safePage - 1) * safeLimit;
    final data = await _request(
      'GET',
      '/library/sections/watchlist/all',
      query: {'X-Plex-Container-Start': offset, 'X-Plex-Container-Size': safeLimit, 'includeMeta': 1},
    );
    final container = _mediaContainer(data!);
    final items = flexibleMapList(container['Metadata']);
    final total = flexibleInt(container['totalSize']) ?? flexibleInt(container['size']) ?? items.length;
    return PlexDiscoverPage(items: items, hasMore: offset + items.length < total);
  }

  /// Discover's Home shelves — the rows Plex's own web client renders on its
  /// Home ▸ Trending tab, which reads
  /// `provider://tv.plex.provider.discover/hubs/sections/home`.
  ///
  /// The section listing is placeholders only: every hub comes back with
  /// `placeholder: true`, `size: 0` and no `Metadata`, so each rendered shelf
  /// costs one further request against its own key. Shelves that can never
  /// produce a catalog item are dropped before spending that request:
  /// `directory` shelves list browse categories (genre/decade/award) and
  /// `clip` shelves list trailers.
  Future<List<PlexDiscoverHub>> getHomeHubs({int limit = 25, int concurrency = 6}) async {
    final safeLimit = limit.clamp(1, 100);
    final data = await _request('GET', '/hubs/sections/home', query: {'includeMeta': 1});
    final container = _mediaContainer(data!);
    final candidates = <({String id, String key, String title})>[];
    final seen = <String>{};
    for (final hub in flexibleMapList(container['Hub'])) {
      if (_unrenderableHubTypes.contains(hub['type'])) continue;
      final key = _nonEmptyString(hub['key'] ?? hub['hubKey']);
      final id = _nonEmptyString(hub['hubIdentifier']) ?? key;
      final title = _nonEmptyString(hub['title']);
      if (key == null || id == null || title == null || !seen.add(id)) continue;
      candidates.add((id: id, key: key, title: title));
    }
    if (candidates.isEmpty) return const [];

    // One shelf failing (a hub retired between listing and hydration, a
    // transient 5xx) must not sink the whole tab, but a pass where every
    // shelf failed is a real failure and keeps the caller's error surface.
    final pages = List<PlexDiscoverPage?>.filled(candidates.length, null);
    Object? firstError;
    StackTrace? firstStackTrace;
    var cursor = 0;
    Future<void> hydrate() async {
      while (true) {
        final index = cursor++;
        if (index >= candidates.length) return;
        final candidate = candidates[index];
        try {
          // One over the shelf size is what tells View All there is more.
          pages[index] = await getHub(candidate.key, limit: safeLimit + 1);
        } catch (error, stackTrace) {
          firstError ??= error;
          firstStackTrace ??= stackTrace;
          appLogger.w('Plex Discover: home hub ${candidate.id} failed', error: error, stackTrace: stackTrace);
        }
      }
    }

    await Future.wait([for (var i = concurrency.clamp(1, candidates.length); i > 0; i--) hydrate()]);
    if (firstError case final error? when pages.every((page) => page == null)) {
      Error.throwWithStackTrace(error, firstStackTrace!);
    }

    return [
      for (var i = 0; i < candidates.length; i++)
        if (pages[i] case final page? when page.items.isNotEmpty)
          PlexDiscoverHub(
            id: candidates[i].id,
            key: candidates[i].key,
            title: candidates[i].title,
            page: PlexDiscoverPage(items: page.items.take(safeLimit).toList(), hasMore: page.items.length > safeLimit),
          ),
    ];
  }

  /// One Discover hub in full. The provider ignores container offsets on hub
  /// keys and truncates with `limit` instead, so a hub is always a single
  /// page and [PlexDiscoverPage.hasMore] never reports one.
  Future<PlexDiscoverPage> getHub(String key, {int limit = 100}) async {
    final safeLimit = limit.clamp(1, 500);
    final data = await _request(
      'GET',
      key,
      // Streaming parts and image variants roughly double the payload of a
      // 25-item shelf and nothing in the catalog layer reads them.
      query: {'limit': safeLimit, 'includeMeta': 1, 'excludeElements': 'Media,Image'},
    );
    final container = _mediaContainer(data!);
    final hub = firstFlexibleMap(container['Hub']);
    final containerItems = flexibleMapList(container['Metadata']);
    final rawItems = containerItems.isNotEmpty ? containerItems : flexibleMapList(hub?['Metadata']);
    return PlexDiscoverPage(items: rawItems.take(safeLimit).toList());
  }

  Future<List<Map<String, dynamic>>> search(String query, {int limit = 30}) async {
    final data = await _request(
      'GET',
      '/library/search',
      query: {
        'query': query,
        'limit': limit.clamp(1, 100),
        'searchTypes': 'movies,tv',
        'searchProviders': 'discover',
        'includeMetadata': 1,
        'filterPeople': 1,
      },
    );
    final container = _mediaContainer(data!);
    return [
      for (final group in flexibleMapList(container['SearchResults']))
        for (final result in flexibleMapList(group['SearchResult']))
          if (firstFlexibleMap(result['Metadata']) case final Map<String, dynamic> metadata) metadata,
    ];
  }

  Future<Map<String, dynamic>?> match(ExternalIds ids) async {
    final guid = switch (ids) {
      ExternalIds(imdb: final String imdb) => 'imdb://$imdb',
      ExternalIds(tmdb: final int tmdb) => 'tmdb://$tmdb',
      ExternalIds(tvdb: final int tvdb) => 'tvdb://$tvdb',
      _ => null,
    };
    if (guid == null) return null;
    final data = await _request('GET', '/library/metadata/matches', query: {'guid': guid}, allowNotFound: true);
    if (data == null) return null;
    return firstFlexibleMap(_mediaContainer(data)['Metadata']);
  }

  Future<Map<String, dynamic>?> getMetadata(String ratingKey) async {
    final data = await _request(
      'GET',
      '/library/metadata/${Uri.encodeComponent(ratingKey)}',
      query: {'includeGuids': 1},
      allowNotFound: true,
    );
    if (data == null) return null;
    return firstFlexibleMap(_mediaContainer(data)['Metadata']);
  }

  Future<List<Map<String, dynamic>>> getRelated(String ratingKey) async {
    final data = await _request(
      'GET',
      '/library/metadata/${Uri.encodeComponent(ratingKey)}/related',
      allowNotFound: true,
    );
    if (data == null) return const [];
    final container = _mediaContainer(data);
    return [
      for (final hub in flexibleMapList(container['Hub'])) ...flexibleMapList(hub['Metadata']),
      if (container['Hub'] == null) ...flexibleMapList(container['Metadata']),
    ];
  }

  Future<void> setWatchlisted(String ratingKey, {required bool add}) async {
    await _request(
      'PUT',
      add ? '/actions/addToWatchlist' : '/actions/removeFromWatchlist',
      query: {'ratingKey': ratingKey},
    );
  }

  Future<Map<String, dynamic>?> _request(
    String method,
    String path, {
    Map<String, Object?>? query,
    bool allowNotFound = false,
  }) async {
    final relative = Uri.parse(path);
    if (relative.hasScheme || relative.host.isNotEmpty || !relative.path.startsWith('/')) {
      throw ArgumentError.value(path, 'path', 'Plex Discover paths must stay on the provider host');
    }
    final uri = _baseUri.replace(
      path: relative.path,
      queryParameters: {
        ...relative.queryParameters,
        for (final entry in query?.entries ?? const <MapEntry<String, Object?>>[])
          if (entry.value != null) entry.key: entry.value.toString(),
      },
    );
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-Plex-Token': session.accessToken,
      'X-Plex-Client-Identifier': session.clientIdentifier,
      'X-Plex-Product': 'Plezy',
      'X-Plex-Version': '2',
    };
    final request = switch (method) {
      'GET' => _http.get(uri, headers: headers),
      'PUT' => _http.put(uri, headers: headers),
      _ => throw ArgumentError.value(method, 'method', 'Unsupported Plex Discover method'),
    };
    final response = await request.timeout(requestTimeout);
    if (allowNotFound && response.statusCode == 404) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PlexDiscoverException(response.statusCode, _errorMessage(response.body));
    }
    if (response.body.isEmpty) return const <String, dynamic>{};
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : const <String, dynamic>{};
  }

  static Map<String, dynamic> _mediaContainer(Map<String, dynamic> data) =>
      firstFlexibleMap(data['MediaContainer']) ?? const <String, dynamic>{};

  static String? _nonEmptyString(Object? value) {
    final string = value?.toString().trim();
    return string == null || string.isEmpty ? null : string;
  }

  static String _errorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      final error = decoded is Map<String, dynamic> ? firstFlexibleMap(decoded['Error']) : null;
      return error?['message']?.toString() ?? error?['error']?.toString() ?? 'Request failed';
    } catch (_) {
      return 'Request failed';
    }
  }

  void dispose() => _http.close();
}
