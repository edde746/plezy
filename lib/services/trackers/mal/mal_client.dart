import 'dart:async';

import 'package:http/http.dart' as http;

import '../../../models/mal/mal_anime.dart';
import '../../../models/mal/mal_character.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/json_utils.dart';
import '../future_coalescer.dart';
import '../tracker.dart';
import '../tracker_constants.dart';
import '../tracker_exceptions.dart';
import '../tracker_http_client.dart';
import '../tracker_session.dart';
import 'mal_auth_service.dart';
import 'mal_constants.dart';
import 'mal_page.dart';

/// HTTP wrapper for the MAL REST API.
///
/// Refreshes the access token 5 minutes before expiry or on 401. Concurrent
/// 401s are coalesced so only one refresh request is in flight.
class MalClient implements DisposableTrackerClient {
  TrackerSession _session;
  final TrackerHttpClient _http;
  final MalAuthService _auth;
  final void Function() onSessionInvalidated;
  final void Function(TrackerSession)? onSessionUpdated;

  final _refreshCoalescer = FutureCoalescer<TrackerSession>();

  MalClient(
    TrackerSession session, {
    required this.onSessionInvalidated,
    this.onSessionUpdated,
    http.Client? httpClient,
    MalAuthService? authService,
  }) : _session = session,
       _http = TrackerHttpClient(service: TrackerService.mal, logLabel: 'MAL', httpClient: httpClient),
       _auth = authService ?? MalAuthService();

  TrackerSession get session => _session;

  @override
  void dispose() {
    _http.dispose();
    _auth.dispose();
  }

  /// Fetch basic user info to get the display name.
  Future<Map<String, dynamic>?> getMyUser() async {
    final res = await _request('GET', '/users/@me');
    return res is Map ? res.cast<String, dynamic>() : null;
  }

  /// Update the user's list entry for an anime. Body shape:
  /// ```
  /// {"status": "watching", "num_watched_episodes": 5}
  /// ```
  Future<void> updateMyListStatus(int animeId, Map<String, String> fields) async {
    // MAL's list-status endpoint is form-encoded (not JSON).
    await _request('PUT', '/anime/$animeId/my_list_status', formBody: fields);
  }

  Future<void> deleteMyListStatus(int animeId) async {
    await _request('DELETE', '/anime/$animeId/my_list_status');
  }

  Future<int?> getMyListScore(int animeId) async {
    try {
      final res = await _request('GET', '/anime/$animeId?fields=my_list_status');
      if (res is! Map) return null;
      final myListStatus = res['my_list_status'];
      if (myListStatus is! Map) return null;
      final score = flexibleInt(myListStatus['score']);
      return score != null && score > 0 ? score : null;
    } on TrackerApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Anime summary fields the Explore catalog requests on list endpoints.
  static const String catalogFields =
      'id,title,main_picture,alternative_titles,start_date,synopsis,mean,'
      'genres,media_type,rating,num_episodes,average_episode_duration,start_season,'
      'status,studios,num_scoring_users';

  static const String _characterFields = 'role,main_picture,first_name,last_name';

  /// Characters of an anime, main roles first (MAL exposes no voice actors).
  Future<MalPage<MalCharacter>> getAnimeCharacters(int animeId, {int limit = 20}) async {
    final res = await _request('GET', '/anime/$animeId/characters?limit=$limit&fields=$_characterFields');
    return MalPage.fromJsonEntries(res, MalCharacter.fromEntry);
  }

  /// The user's Plan to Watch list — the MAL equivalent of a watchlist.
  /// `nsfw=true` because it is the user's own list.
  Future<MalPage<MalAnime>> getPlanToWatch({int page = 1, int limit = 100}) => _getAnimePage(
    '/users/@me/animelist',
    {'status': 'plan_to_watch', 'sort': 'list_updated_at', 'nsfw': 'true'},
    page: page,
    limit: limit,
  );

  /// Personalized recommendations. Empty for accounts without history.
  Future<MalPage<MalAnime>> getSuggestedAnime({int page = 1, int limit = 100}) =>
      _getAnimePage('/anime/suggestions', const {}, page: page, limit: limit);

  Future<MalPage<MalAnime>> getAnimeRanking(MalRankingType type, {int page = 1, int limit = 100}) =>
      _getAnimePage('/anime/ranking', {'ranking_type': type.queryValue}, page: page, limit: limit);

  /// Title search. MAL rejects queries under 3 characters (`invalid q`) —
  /// callers guard the minimum length.
  Future<MalPage<MalAnime>> searchAnime(String query, {int page = 1, int limit = 30}) =>
      _getAnimePage('/anime', {'q': query}, page: page, limit: limit);

  /// Community "users also liked" titles from the anime detail's
  /// `recommendations` field, with the catalog fields selected on the nested
  /// nodes (`fields=recommendations{...}` — braces percent-encoded, MAL
  /// accepts the nested selector).
  Future<List<MalAnime>> getAnimeRecommendations(int animeId, {int limit = 20}) async {
    final res = await _request('GET', '/anime/$animeId?fields=recommendations%7B$catalogFields%7D');
    if (res is! Map) return const [];
    final recommendations = res['recommendations'];
    if (recommendations is! List) return const [];
    return [
      for (final entry in recommendations.take(limit))
        if (entry is Map<String, dynamic> && entry['node'] is Map<String, dynamic>)
          MalAnime.fromJson(entry['node'] as Map<String, dynamic>),
    ];
  }

  Future<MalPage<MalAnime>> _getAnimePage(
    String path,
    Map<String, String> params, {
    required int page,
    required int limit,
  }) async {
    final query = Uri(
      queryParameters: {
        ...params,
        'limit': '$limit',
        if (page > 1) 'offset': '${(page - 1) * limit}',
        'fields': catalogFields,
      },
    ).query;
    final res = await _request('GET', '$path?$query');
    return MalPage.fromJson(res, MalAnime.fromJson);
  }

  Future<int?> getAnimeEpisodeCount(int animeId) async {
    final res = await _request('GET', '/anime/$animeId?fields=num_episodes');
    if (res is! Map) return null;
    final count = flexibleInt(res['num_episodes']);
    return count != null && count > 0 ? count : null;
  }

  Future<TrackerSession> _refresh() => _refreshCoalescer.run(_doRefresh);

  Future<TrackerSession> _doRefresh() async {
    try {
      final fresh = await _auth.refresh(_session);
      _session = fresh;
      onSessionUpdated?.call(fresh);
      return fresh;
    } catch (e) {
      appLogger.w('MAL: refresh failed', error: e);
      // Only a terminally-invalid grant clears the session; transient 5xx/
      // network failures fall through so the request can retry on a later 401.
      if (e is TrackerAuthException && e.isPermanent) onSessionInvalidated();
      rethrow;
    }
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? formBody,
  }) async {
    if (_session.needsRefresh) {
      try {
        await _refresh();
      } catch (_) {
        // Fall through; the request will hit 401 naturally and re-try.
      }
    }

    var res = await _send(method, path, body: body, formBody: formBody);

    if (res.statusCode == 401) {
      try {
        await _refresh();
      } catch (_) {
        throw TrackerApiException(service: TrackerService.mal, statusCode: 401, body: res.body);
      }
      res = await _send(method, path, body: body, formBody: formBody);
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return TrackerHttpClient.decodeJson(res.body);
    }
    throw TrackerApiException(service: TrackerService.mal, statusCode: res.statusCode, body: res.body);
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? formBody,
  }) async {
    final uri = Uri.parse('${MalConstants.apiBase}$path');
    final headers = MalConstants.headers(accessToken: _session.accessToken);

    if (formBody != null) {
      return _http.sendForm(method, uri, headers: headers, body: formBody);
    }

    return _http.sendJson(method, uri, headers: headers, body: body);
  }
}
