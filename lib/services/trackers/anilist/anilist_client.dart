import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../utils/app_logger.dart';
import '../../../utils/platform_http_client_stub.dart'
    if (dart.library.io) '../../../utils/platform_http_client_io.dart'
    as platform;
import 'anilist_constants.dart';
import 'anilist_session.dart';

/// GraphQL client for AniList.
///
/// No refresh endpoint — on 401 the session is terminal and
/// [onSessionInvalidated] clears it so the user re-auths.
class AnilistClient {
  static const Duration _requestTimeout = Duration(seconds: 20);

  final AnilistSession _session;
  final http.Client _http;
  final void Function() onSessionInvalidated;

  AnilistClient(AnilistSession session, {required this.onSessionInvalidated, http.Client? httpClient})
    : _session = session,
      _http = httpClient ?? platform.createPlatformClient();

  AnilistSession get session => _session;

  void dispose() => _http.close();

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

  Future<Map<String, dynamic>> query(String query, {Map<String, dynamic>? variables}) async {
    final uri = Uri.parse(AnilistConstants.apiBase);
    final headers = AnilistConstants.headers(accessToken: _session.accessToken);
    final body = json.encode({'query': query, 'variables': ?variables});

    final sw = Stopwatch()..start();
    final res = await _http.post(uri, headers: headers, body: body).timeout(_requestTimeout);
    sw.stop();
    appLogger.d('AniList POST ${uri.path} → ${res.statusCode} (${sw.elapsedMilliseconds}ms)');

    if (res.statusCode == 401) {
      onSessionInvalidated();
      throw const AnilistAuthException('Session invalidated (401)');
    }
    if (res.statusCode != 200) {
      throw AnilistApiException(statusCode: res.statusCode, body: res.body);
    }
    final decoded = json.decode(res.body) as Map<String, dynamic>;
    final errors = decoded['errors'];
    if (errors is List && errors.isNotEmpty) {
      throw AnilistApiException(statusCode: res.statusCode, body: json.encode(errors));
    }
    final data = decoded['data'];
    return data is Map ? data.cast<String, dynamic>() : <String, dynamic>{};
  }
}

class AnilistApiException implements Exception {
  final int statusCode;
  final String body;
  const AnilistApiException({required this.statusCode, required this.body});
  @override
  String toString() => 'AnilistApiException(HTTP $statusCode): $body';
}

class AnilistAuthException implements Exception {
  final String message;
  const AnilistAuthException(this.message);
  @override
  String toString() => 'AnilistAuthException: $message';
}
