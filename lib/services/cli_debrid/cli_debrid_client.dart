import 'package:http/http.dart' as http;

import '../../models/cli_debrid/cli_debrid_session.dart';
import 'cli_debrid_exceptions.dart';
import 'cli_debrid_http_client.dart';

/// One version/file candidate returned when a rescrape lookup is ambiguous
/// (`ms_item_id` matches more than one version and filename didn't narrow it
/// down) — the caller should show a picker keyed on [id] and retry with
/// [CliDebridClient.rescrapeItem]'s `itemId` parameter.
class CliDebridRescrapeCandidate {
  final int id;
  final String title;
  final String? version;
  final String? state;
  final int? seasonNumber;
  final int? episodeNumber;
  final String? locationBasename;
  final String? filledByFile;

  const CliDebridRescrapeCandidate({
    required this.id,
    required this.title,
    this.version,
    this.state,
    this.seasonNumber,
    this.episodeNumber,
    this.locationBasename,
    this.filledByFile,
  });

  factory CliDebridRescrapeCandidate.fromJson(Map<String, Object?> json) => CliDebridRescrapeCandidate(
    id: (json['id'] as num).toInt(),
    title: json['title'] as String? ?? '',
    version: json['version'] as String?,
    state: json['state'] as String?,
    seasonNumber: (json['season_number'] as num?)?.toInt(),
    episodeNumber: (json['episode_number'] as num?)?.toInt(),
    locationBasename: json['location_basename'] as String?,
    filledByFile: json['filled_by_file'] as String?,
  );

  /// Basename to show the user for disambiguation — prefers the on-disk
  /// (post-symlink) name, falling back to the original torrent/NZB filename.
  String get displayFilename => locationBasename ?? filledByFile ?? '';
}

/// Thrown by [CliDebridClient.rescrapeItem] when the lookup matched more than
/// one version and the caller needs to prompt the user to pick one.
class CliDebridAmbiguousRescrapeException implements Exception {
  final List<CliDebridRescrapeCandidate> candidates;
  const CliDebridAmbiguousRescrapeException(this.candidates);

  @override
  String toString() => 'CliDebridAmbiguousRescrapeException(${candidates.length} candidates)';
}

/// Authenticated cli_debrid API client, scoped to one [CliDebridSession].
///
/// No re-auth: the API token is a long-lived credential minted once from
/// cli_debrid's user-management screen, unlike Seerr's session cookie.
class CliDebridClient {
  final CliDebridSession session;
  final CliDebridHttpClient _http;

  CliDebridClient(this.session, {http.Client? httpClient})
    : _http = CliDebridHttpClient(
        baseUrl: CliDebridHttpClient.normalizeBaseUrl(session.baseUrl),
        apiToken: session.apiToken,
        httpClient: httpClient,
      );

  void dispose() => _http.dispose();

  /// Verify the URL+token combination actually reaches a cli_debrid instance
  /// with a working token, for the connect screen. Throws
  /// [CliDebridAuthException] on a bad token, [CliDebridUrlException] on an
  /// unreachable/non-cli_debrid URL.
  Future<void> verifyConnection() async {
    try {
      final res = await _http.send('GET', '/content/versions');
      CliDebridHttpClient.throwForStatus(res);
    } on CliDebridAuthException {
      rethrow;
    } on CliDebridApiException catch (e) {
      throw CliDebridUrlException(e.message);
    } catch (e) {
      throw CliDebridUrlException('Could not reach cli_debrid: $e');
    }
  }

  /// Move an already-collected item back to Wanted for re-request.
  ///
  /// Pass [itemId] directly when the caller already resolved which specific
  /// version/file to rescrape (e.g. the user picked one from a prior
  /// [CliDebridAmbiguousRescrapeException]). Otherwise pass [msItemId] +
  /// [type] (+ [seasonNumber]/[episodeNumber] for episodes) — cli_debrid
  /// narrows by those, then by [filename] (matched against the on-disk
  /// basename) when more than one version shares that ms_item_id.
  ///
  /// Throws [CliDebridAmbiguousRescrapeException] if multiple versions still
  /// match after filename narrowing — call again with `itemId` set to the
  /// user's chosen candidate's [CliDebridRescrapeCandidate.id].
  Future<void> rescrapeItem({
    int? itemId,
    String? msItemId,
    String? type,
    int? seasonNumber,
    int? episodeNumber,
    String? filename,
  }) async {
    assert(
      itemId != null || (msItemId != null && type != null),
      'rescrapeItem requires either itemId, or msItemId+type',
    );
    final res = await _http.send(
      'POST',
      '/database/rescrape_item',
      body: {
        if (itemId != null) 'item_id': itemId,
        if (msItemId != null) 'ms_item_id': msItemId,
        if (type != null) 'type': type,
        if (seasonNumber != null) 'season_number': seasonNumber,
        if (episodeNumber != null) 'episode_number': episodeNumber,
        if (filename != null) 'filename': filename,
      },
    );
    final data = res.data;
    if (res.statusCode == 200 && data is Map<String, dynamic> && data['error'] == 'ambiguous') {
      final rawCandidates = (data['candidates'] as List? ?? const [])
          .whereType<Map<String, Object?>>()
          .map(CliDebridRescrapeCandidate.fromJson)
          .toList();
      throw CliDebridAmbiguousRescrapeException(rawCandidates);
    }
    CliDebridHttpClient.throwForStatus(res);
  }

  /// Season numbers available for a show, for building a season picker
  /// before [requestContent]. `imdbId`/`tmdbId` — cli_debrid accepts either.
  Future<List<int>> showSeasons({String? tmdbId, String? imdbId}) async {
    final id = tmdbId ?? imdbId;
    if (id == null) throw ArgumentError('showSeasons requires tmdbId or imdbId');
    final res = await _http.send('GET', '/content/show_seasons', query: {'tmdb_id': id});
    CliDebridHttpClient.throwForStatus(res);
    final data = res.data as Map<String, dynamic>;
    return (data['seasons'] as List? ?? const []).map((e) => (e as num).toInt()).toList();
  }

  /// Request a movie, whole show, or specific seasons into cli_debrid's
  /// Wanted queue. Omit [seasons] to request every season of a show.
  Future<void> requestContent({
    required String id,
    required String mediaType, // 'movie' | 'tv'
    required String title,
    int? year,
    List<String>? versions,
    List<int>? seasons,
  }) async {
    final res = await _http.send(
      'POST',
      '/content/request',
      body: {
        'id': id,
        'mediaType': mediaType,
        'title': title,
        if (year != null) 'year': year,
        if (versions != null) 'versions': versions,
        if (seasons != null) 'seasons': seasons,
      },
    );
    CliDebridHttpClient.throwForStatus(res);
  }

  /// Available version/quality profile names, for the request sheet's
  /// version picker.
  Future<List<String>> availableVersions() async {
    final res = await _http.send('GET', '/content/versions');
    CliDebridHttpClient.throwForStatus(res);
    final data = res.data as Map<String, dynamic>;
    return (data['versions'] as List? ?? const []).map((e) => '$e').toList();
  }
}
