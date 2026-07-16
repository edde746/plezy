import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';

import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/services/playback_initialization_types.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/media_items.dart';

/// Regression coverage for the Plex transcode reporting bug: while
/// transcoding, the `/:/timeline` reports must carry the playback's
/// `X-Plex-Session-Identifier` so the server correlates the timeline with the
/// active transcode session and reports "Transcode" instead of falling back to
/// a generic Direct Play / Original entry.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
  });

  tearDown(() async {
    await db.close();
  });

  PlexClient makeClient(Future<http.Response> Function(http.Request request) handler) =>
      testPlexClient(serverId: ServerId('server-id'), handler: handler);

  /// Captures every request and answers `/:/timeline` with 200 so
  /// [PlexClient.updateProgress]'s `throwIfHttpError` is satisfied.
  ({PlexClient client, List<http.Request> requests}) makeRecordingClient() {
    final requests = <http.Request>[];
    final client = makeClient((request) async {
      requests.add(request);
      return http.Response('', 200);
    });
    return (client: client, requests: requests);
  }

  http.Request timelineRequest(List<http.Request> requests) {
    return requests.firstWhere((r) => r.url.path == '/:/timeline');
  }

  group('Plex timeline carries the session identifier', () {
    test('reportPlaybackStarted sends X-Plex-Session-Identifier when a play session id is set', () async {
      final harness = makeRecordingClient();
      addTearDown(harness.client.close);

      await harness.client.reportPlaybackStarted(
        itemId: '42',
        position: const Duration(seconds: 12),
        duration: const Duration(minutes: 90),
        playSessionId: 'session-abc',
        playMethod: 'Transcode',
      );

      final request = timelineRequest(harness.requests);
      expect(request.method, 'POST');
      expect(request.url.queryParameters['state'], 'playing');
      expect(request.headers['X-Plex-Session-Identifier'], 'session-abc');
    });

    test('reportPlaybackProgress sends X-Plex-Session-Identifier when a play session id is set', () async {
      final harness = makeRecordingClient();
      addTearDown(harness.client.close);

      await harness.client.reportPlaybackProgress(
        itemId: '42',
        position: const Duration(minutes: 5),
        duration: const Duration(minutes: 90),
        playSessionId: 'session-abc',
        playMethod: 'Transcode',
      );

      final request = timelineRequest(harness.requests);
      expect(request.method, 'POST');
      expect(request.url.queryParameters['state'], 'playing');
      expect(request.headers['X-Plex-Session-Identifier'], 'session-abc');
    });

    test('reportPlaybackStopped sends X-Plex-Session-Identifier when a play session id is set', () async {
      final harness = makeRecordingClient();
      addTearDown(harness.client.close);

      await harness.client.reportPlaybackStopped(
        itemId: '42',
        position: const Duration(minutes: 5),
        duration: const Duration(minutes: 90),
        playSessionId: 'session-abc',
      );

      final request = timelineRequest(harness.requests);
      expect(request.method, 'POST');
      expect(request.url.queryParameters['state'], 'stopped');
      expect(request.headers['X-Plex-Session-Identifier'], 'session-abc');
    });

    test('timeline omits X-Plex-Session-Identifier when there is no play session id', () async {
      final harness = makeRecordingClient();
      addTearDown(harness.client.close);

      await harness.client.reportPlaybackProgress(
        itemId: '42',
        position: const Duration(minutes: 5),
        duration: const Duration(minutes: 90),
      );

      final request = timelineRequest(harness.requests);
      expect(request.headers.containsKey('X-Plex-Session-Identifier'), isFalse);
    });
  });

  group('getPlaybackInitialization threads the session identifier onto the result', () {
    PlexClient makeMetadataClient() {
      return makeClient((request) async {
        if (request.url.path != '/library/metadata/42') {
          return http.Response('not found', 404);
        }
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              'Metadata': [
                {
                  'ratingKey': '42',
                  'type': 'movie',
                  'title': 'Movie',
                  'Media': [
                    {
                      'id': 7,
                      'container': 'mkv',
                      'Part': [
                        {
                          'id': 99,
                          'key': '/library/parts/99/file.mkv',
                          'Stream': [
                            {'streamType': 1, 'id': 300, 'codec': 'h264'},
                            {'streamType': 2, 'id': 301, 'index': 0, 'languageCode': 'eng', 'selected': true},
                          ],
                        },
                      ],
                    },
                  ],
                },
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
    }

    test('direct-play result carries the session identifier as playSessionId', () async {
      final client = makeMetadataClient();
      addTearDown(client.close);

      final result = await client.getPlaybackInitialization(
        PlaybackInitializationOptions(
          metadata: testMediaItem(id: '42', backend: MediaBackend.plex, kind: MediaKind.movie, serverId: 'server-id'),
          selectedMediaIndex: 0,
          // Original preset stays on the direct-play branch (no transcode
          // decision round-trip needed for this assertion).
          qualityPreset: TranscodeQualityPreset.original,
          sessionIdentifier: 'session-abc',
          transcodeSessionId: 'transcode-abc',
        ),
      );

      expect(result.isTranscoding, isFalse);
      expect(result.playSessionId, 'session-abc');
    });
  });
}
