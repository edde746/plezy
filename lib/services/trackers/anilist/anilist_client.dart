import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../utils/json_utils.dart';
import '../tracker.dart';
import '../tracker_constants.dart';
import '../tracker_exceptions.dart';
import '../tracker_http_client.dart';
import '../tracker_session.dart';
import 'anilist_constants.dart';

/// GraphQL client for AniList.
///
/// No refresh endpoint — on 401 the session is terminal and
/// [onSessionInvalidated] clears it so the user re-auths.
class AnilistClient implements DisposableTrackerClient {
  final TrackerSession _session;
  final TrackerHttpClient _http;
  final void Function() onSessionInvalidated;

  AnilistClient(TrackerSession session, {required this.onSessionInvalidated, http.Client? httpClient})
    : _session = session,
      _http = TrackerHttpClient(service: TrackerService.anilist, logLabel: 'AniList', httpClient: httpClient);

  TrackerSession get session => _session;

  @override
  void dispose() => _http.dispose();

  /// Fetch the current viewer's username for the settings UI.
  Future<String?> getViewerName() async {
    final data = await query('query { Viewer { name } }');
    final viewer = data['Viewer'];
    if (viewer is Map) return viewer['name'] as String?;
    return null;
  }

  /// Update the viewer's media-list entry for an AniList media ID.
  Future<void> saveMediaListEntry({required int mediaId, required int progress, required String status}) async {
    const mutation = '''
      mutation(\$mediaId: Int, \$progress: Int, \$status: MediaListStatus) {
        SaveMediaListEntry(mediaId: \$mediaId, progress: \$progress, status: \$status) {
          id
        }
      }
    ''';
    await query(mutation, variables: {'mediaId': mediaId, 'progress': progress, 'status': status});
  }

  Future<void> deleteMediaListEntry(int mediaId) async {
    const idQuery = '''
      query(\$mediaId: Int) {
        Media(id: \$mediaId, type: ANIME) {
          mediaListEntry {
            id
          }
        }
      }
    ''';
    final data = await query(idQuery, variables: {'mediaId': mediaId});
    final media = data['Media'];
    if (media is! Map) return;
    final entry = media['mediaListEntry'];
    if (entry is! Map) return;
    final entryId = flexibleInt(entry['id']);
    if (entryId == null) return;

    const mutation = '''
      mutation(\$id: Int) {
        DeleteMediaListEntry(id: \$id) {
          deleted
        }
      }
    ''';
    await query(mutation, variables: {'id': entryId});
  }

  Future<void> setMediaListScore({required int mediaId, required int score}) async {
    const mutation = '''
      mutation(\$mediaId: Int, \$scoreRaw: Int) {
        SaveMediaListEntry(mediaId: \$mediaId, scoreRaw: \$scoreRaw) {
          id
        }
      }
    ''';
    await query(mutation, variables: {'mediaId': mediaId, 'scoreRaw': score.clamp(0, 10).toInt() * 10});
  }

  Future<int?> getMediaListScore(int mediaId) async {
    const mediaQuery = '''
      query(\$mediaId: Int) {
        Media(id: \$mediaId, type: ANIME) {
          mediaListEntry {
            scoreRaw: score(format: POINT_100)
          }
        }
      }
    ''';
    final data = await query(mediaQuery, variables: {'mediaId': mediaId});
    final media = data['Media'];
    if (media is! Map) return null;
    final entry = media['mediaListEntry'];
    if (entry is! Map) return null;
    final scoreRaw = flexibleInt(entry['scoreRaw']);
    if (scoreRaw == null || scoreRaw <= 0) return null;
    return (scoreRaw / 10).round().clamp(1, 10).toInt();
  }

  Future<int?> getAnimeEpisodeCount(int mediaId) async {
    const mediaQuery = '''
      query(\$mediaId: Int) {
        Media(id: \$mediaId, type: ANIME) {
          episodes
        }
      }
    ''';
    final data = await query(mediaQuery, variables: {'mediaId': mediaId});
    final media = data['Media'];
    if (media is! Map) return null;
    final count = flexibleInt(media['episodes']);
    return count != null && count > 0 ? count : null;
  }

  Future<Map<String, dynamic>> query(String query, {Map<String, dynamic>? variables}) async {
    final uri = Uri.parse(AnilistConstants.apiBase);
    final headers = AnilistConstants.headers(accessToken: _session.accessToken);
    final res = await _http.sendJson(
      'POST',
      uri,
      headers: headers,
      body: {'query': query, 'variables': ?variables},
      allowedMethods: const {'POST'},
    );

    if (res.statusCode == 401) {
      onSessionInvalidated();
      throw const TrackerAuthException(
        service: TrackerService.anilist,
        message: 'Session invalidated (401)',
        statusCode: 401,
        isPermanent: true,
      );
    }
    if (res.statusCode != 200) {
      throw TrackerApiException(service: TrackerService.anilist, statusCode: res.statusCode, body: res.body);
    }
    final decoded = json.decode(res.body) as Map<String, dynamic>;
    final errors = decoded['errors'];
    if (errors is List && errors.isNotEmpty) {
      throw TrackerApiException(service: TrackerService.anilist, statusCode: res.statusCode, body: json.encode(errors));
    }
    final data = decoded['data'];
    return data is Map ? data.cast<String, dynamic>() : <String, dynamic>{};
  }
}
