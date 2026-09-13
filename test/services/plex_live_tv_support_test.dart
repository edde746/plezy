import 'dart:async';
import 'dart:convert';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/live_tv_support.dart';
import 'package:plezy/media/live_tv_timeline.dart';
import 'package:plezy/screens/video_player/live_tv_seek.dart';
import 'package:plezy/screens/video_player/live_tv_session_state.dart';
import 'package:plezy/mpv/player/player_streams.dart';
import 'package:plezy/models/livetv_capture_buffer.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/models/media_subscription.dart';
import 'package:plezy/models/livetv_channel.dart';
import 'package:plezy/models/plex/plex_config.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';
import 'package:plezy/services/live_tv_program_guide.dart';
import 'package:plezy/utils/active_client_scope.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
  });

  tearDown(() async {
    await db.close();
  });

  PlexClient makeClient(
    Future<http.Response> Function(http.Request request) handler, {
    String token = 'tok',
    String clientIdentifier = 'client',
    List<PlexEpgProvider> epgProviders = const [(identifier: 'provider-a', gridEndpoint: '/provider-a/grid', id: '2')],
  }) {
    return PlexClient.forTesting(
      config: PlexConfig(
        baseUrl: 'https://plex.example.com',
        token: token,
        clientIdentifier: clientIdentifier,
        product: 'Plezy',
        version: '1',
        machineIdentifier: 'machine-1',
      ),
      serverId: ServerId('machine-1'),
      profileScopeId: buildPlexProfileScopeId(serverId: ServerId('machine-1'), profileId: 'profile-a'),
      httpClient: MockClient(handler),
      epgProviders: epgProviders,
    );
  }

  http.Response jsonResponse(Map<String, dynamic> body) {
    return http.Response(jsonEncode(body), 200, headers: const {'content-type': 'application/json'});
  }

  test('Plex timeshift translates fractional epochs on the capture offset grid', () async {
    final decisions = <Uri>[];
    final client = makeClient((request) async {
      if (request.url.path.endsWith('/tune')) {
        return jsonResponse({
          'MediaContainer': {
            'Metadata': [
              {'ratingKey': 'program', 'key': '/livetv/sessions/test', 'type': 'clip'},
            ],
            'TranscodeSession': {'timeStamp': 1000.25, 'minOffsetAvailable': 2.2, 'maxOffsetAvailable': 10},
          },
        });
      }
      if (request.url.path.endsWith('/decision')) {
        decisions.add(request.url);
        return http.Response('<MediaContainer/>', 200);
      }
      throw StateError('Unexpected request: ${request.url.path}');
    });
    addTearDown(client.close);
    final session = await client.liveTv.startPlayback('channel', dvrKey: 'dvr');
    expect(session, isA<LiveTvTimeshiftSession>());
    final adapter = session! as LiveTvTimeshiftSession;
    final buffer = session.captureBuffer!;
    final window = adapter.seekWindow(buffer)!;
    expect(window.startEpoch, 1003.25);
    expect(window.endEpoch, 1009.25);

    for (final example in [(999.0, 3), (1006.9, 7), (1010.25, 9)]) {
      final request = await adapter.resolveSeek(targetEpoch: example.$1, buffer: buffer);
      expect(request!.effectiveTargetEpoch, 1000.25 + example.$2);
      expect(Uri.parse(request.url).queryParameters['offset'], '${example.$2}');
      expect(decisions.last.queryParameters['offset'], '${example.$2}');
    }
    final live = await adapter.resolveSeek(targetEpoch: null, buffer: buffer);
    expect(Uri.parse(live!.url).queryParameters.containsKey('offset'), isFalse);
    expect(decisions.last.queryParameters.containsKey('offset'), isFalse);
    expect(live.effectiveTargetEpoch, 1010.25);

    expect(
      adapter
          .seekWindow(const CaptureBuffer(startedAt: 1000.25, seekStartSeconds: 2.2, seekEndSeconds: 10.2))!
          .endEpoch,
      1010.25,
    );
    for (final invalid in [
      const CaptureBuffer(startedAt: double.nan, seekStartSeconds: 0, seekEndSeconds: 10),
      const CaptureBuffer(startedAt: 1000, seekStartSeconds: 20, seekEndSeconds: 10),
      const CaptureBuffer(startedAt: 1000, seekStartSeconds: 2.2, seekEndSeconds: 2.8),
      const CaptureBuffer(startedAt: 1000, seekStartSeconds: 2, seekEndSeconds: 2),
    ]) {
      expect(adapter.seekWindow(invalid), isNull);
      expect(await adapter.resolveSeek(targetEpoch: 1005, buffer: invalid), isNull);
    }
    expect(await adapter.resolveSeek(targetEpoch: double.nan, buffer: buffer), isNull);
  });

  for (final replacement in ['B', 'A after B', 'new seek']) {
    test('Plex seek URL cannot open after $replacement takes ownership', () async {
      final resolving = Completer<void>();
      final release = Completer<void>();
      final client = makeClient((request) async {
        if (request.url.path.endsWith('/tune')) {
          return jsonResponse({
            'MediaContainer': {
              'Metadata': [
                {'ratingKey': 'program', 'key': '/livetv/sessions/test', 'type': 'clip'},
              ],
              'TranscodeSession': {'timeStamp': 1000, 'minOffsetAvailable': 0, 'maxOffsetAvailable': 200},
            },
          });
        }
        resolving.complete();
        await release.future;
        return http.Response('<MediaContainer/>', 200);
      });
      addTearDown(client.close);
      final session = (await client.liveTv.startPlayback('A', dvrKey: 'dvr'))!;
      var currentSession = session;
      var intent = 0;
      final capturedIntent = intent;
      var opens = 0;
      final result = runLiveTvSeek(
        session: session as LiveTvTimeshiftSession,
        targetEpoch: 1093,
        currentBuffer: () => session.captureBuffer,
        isCurrent: () => identical(currentSession, session) && intent == capturedIntent,
        open: (_) async {
          opens++;
          return true;
        },
      );
      await resolving.future;
      if (replacement == 'new seek') {
        intent++;
      } else {
        currentSession = (await client.liveTv.startPlayback('B', dvrKey: 'dvr'))!;
        if (replacement == 'A after B') {
          currentSession = (await client.liveTv.startPlayback('A', dvrKey: 'dvr'))!;
        }
      }
      release.complete();
      expect(await result, LiveTvSeekOutcome.superseded);
      expect(opens, 0);
    });
  }

  test('Plex resolution through source readiness preserves uncertainty and actual origin disagreement', () async {
    var seenOffset = '';
    final client = makeClient((request) async {
      if (request.url.path == '/provider-a/grid') {
        expect(request.url.queryParameters['endsAt>'], '1000');
        expect(request.url.queryParameters['beginsAt<'], '1200');
        return jsonResponse({
          'MediaContainer': {
            'Metadata': [
              {
                'title': 'Previous',
                'ratingKey': 'previous',
                'type': 'clip',
                'Media': [
                  {'beginsAt': 1000, 'endsAt': 1100, 'channelIdentifier': 'A'},
                ],
              },
              {
                'title': 'Current',
                'ratingKey': 'current',
                'type': 'clip',
                'Media': [
                  {'beginsAt': 1100, 'endsAt': 1200, 'channelIdentifier': 'A'},
                ],
              },
            ],
          },
        });
      }
      if (request.url.path.endsWith('/tune')) {
        return jsonResponse({
          'MediaContainer': {
            'Metadata': [
              {'ratingKey': 'program', 'key': '/livetv/sessions/test', 'type': 'clip'},
            ],
            'TranscodeSession': {'timeStamp': 1000.25, 'minOffsetAvailable': 0, 'maxOffsetAvailable': 200},
          },
        });
      }
      seenOffset = request.url.queryParameters['offset']!;
      return http.Response('<MediaContainer/>', 200);
    });
    addTearDown(client.close);
    final session = (await client.liveTv.startPlayback('A', dvrKey: 'dvr'))!;
    final state = LiveTvSessionState(null)..adoptSession(session);
    final guide = LiveTvProgramGuide();
    await guide.refresh(
      owner: session,
      channel: LiveTvChannel(key: 'A'),
      fromEpoch: 1000.25,
      toEpoch: 1200,
      fetch: (from, to) => client.liveTv.fetchSchedule(from: from, to: to),
    );
    expect(guide.programs, hasLength(2));
    LiveTvTimeline timeline(Duration position) => LiveTvTimeline.resolve(
      playback: state.playbackPosition(position),
      pendingSeekEpoch: state.pendingTargetEpoch,
      programs: guide.programs,
      programDataStale: guide.stale,
      metadataNowEpoch: 1150,
    );
    final result = await runLiveTvSeek(
      session: session as LiveTvTimeshiftSession,
      targetEpoch: 1093.25,
      currentBuffer: () => state.captureBuffer,
      isCurrent: () => true,
      open: (request) async {
        expect(seenOffset, '93');
        final generation = state.beginClockOpen(request.effectiveTargetEpoch!);
        final result = state.clockOpenResult(generation);
        expect(state.playbackPosition(Duration.zero).epoch, isNull);
        expect(timeline(Duration.zero).program!.title, 'Current');
        state.bindClockOpen(generation, 1);
        state.calibrateClockSource(const PlayerSourceReady(sourceId: 1, position: Duration(seconds: 52)));
        expect(state.playbackPosition(const Duration(seconds: 52)).epoch, 1093.25);
        expect(state.playbackPosition(const Duration(seconds: 52)).confirmedEpoch, isNull);
        final view = timeline(const Duration(seconds: 52));
        expect(view.program!.title, 'Previous');
        expect(view.mode, LiveTvTimelineMode.estimatedPlaybackProgram);
        expect((view.startEpoch, view.endEpoch), (1000, 1100));
        return result;
      },
    );
    expect(result, LiveTvSeekOutcome.opened);
    // A fixture with independently supplied origin differing by four seconds.
    // This tests reconciliation; it does not prove Plex's physical landing.
    state.adoptPlaybackStreamOrigin(
      const CaptureBuffer(startedAt: 1037.25, seekStartSeconds: 0, seekEndSeconds: 100),
      generation: state.streamGeneration,
    );
    final observed = state.playbackPosition(const Duration(seconds: 52));
    expect(observed.epoch, 1089.25);
    expect(observed.accuracy, LiveTvTimeAccuracy.estimated);
    state.failClockSource(const PlayerSourceFailed(1));
    expect(state.playbackPosition(const Duration(seconds: 99)).active, isFalse);
    expect(state.playbackPosition(const Duration(seconds: 99)).epoch, 1089.25);
  });

  test('Plex pending target revalidates when buffer moves during decision', () async {
    var decisions = 0;
    var buffer = const CaptureBuffer(startedAt: 1000, seekStartSeconds: 0, seekEndSeconds: 200);
    final client = makeClient((request) async {
      if (request.url.path.endsWith('/tune')) {
        return jsonResponse({
          'MediaContainer': {
            'Metadata': [
              {'ratingKey': 'program', 'key': '/livetv/sessions/test', 'type': 'clip'},
            ],
            'TranscodeSession': {'timeStamp': 1000, 'minOffsetAvailable': 0, 'maxOffsetAvailable': 200},
          },
        });
      }
      decisions++;
      buffer = const CaptureBuffer(startedAt: 1000, seekStartSeconds: 100, seekEndSeconds: 220);
      return http.Response('<MediaContainer/>', 200);
    });
    addTearDown(client.close);
    final session = (await client.liveTv.startPlayback('A', dvrKey: 'dvr'))!;
    final opened = <double?>[];
    expect(
      await runLiveTvSeek(
        session: session as LiveTvTimeshiftSession,
        targetEpoch: 1050,
        currentBuffer: () => buffer,
        isCurrent: () => true,
        open: (request) async {
          opened.add(request.effectiveTargetEpoch);
          return true;
        },
      ),
      LiveTvSeekOutcome.opened,
    );
    expect(decisions, 2);
    expect(opened, [1100]);
  });

  test('favorite source follows requested lineup provider', () async {
    final client = makeClient(
      (_) async => http.Response('{}', 200),
      epgProviders: const [
        (identifier: 'provider-a', gridEndpoint: '/provider-a/grid', id: '2'),
        (identifier: 'provider-b', gridEndpoint: '/provider-b/grid', id: '3'),
      ],
    );
    addTearDown(client.close);

    expect(await client.liveTv.buildFavoriteChannelSource(lineup: 'provider-b'), 'server://machine-1/provider-b');
  });

  test('favorite store is account device scoped instead of token scoped', () {
    final a = makeClient(
      (_) async => http.Response('{}', 200),
      token: 'server-token-a',
      clientIdentifier: 'account-device',
    );
    final b = makeClient(
      (_) async => http.Response('{}', 200),
      token: 'server-token-b',
      clientIdentifier: 'account-device',
    );
    addTearDown(a.close);
    addTearDown(b.close);

    expect(a.liveTv.favoriteStoreKey, b.liveTv.favoriteStoreKey);
  });

  test('favorite read preserves a successful empty response', () async {
    final client = makeClient((request) async {
      expect(request.url.path, '/settings/favoriteChannels');
      return jsonResponse({'MediaContainer': <String, dynamic>{}});
    });
    addTearDown(client.close);

    await expectLater(client.liveTv.fetchFavoriteChannels(), completion(isEmpty));
  });

  test('favorite read propagates HTTP errors', () async {
    final client = makeClient((request) async {
      expect(request.url.path, '/settings/favoriteChannels');
      return http.Response('service unavailable', 503);
    });
    addTearDown(client.close);

    await expectLater(
      client.liveTv.fetchFavoriteChannels(),
      throwsA(isA<MediaServerHttpException>().having((error) => error.statusCode, 'statusCode', 503)),
    );
  });

  test('favorite write propagates HTTP errors to the mutation caller', () async {
    final requestStarted = Completer<void>();
    final releaseResponse = Completer<void>();
    final client = makeClient((request) async {
      expect(request.method, 'PUT');
      expect(request.url.path, '/settings/favoriteChannels');
      requestStarted.complete();
      await releaseResponse.future;
      return http.Response('service unavailable', 503);
    });
    addTearDown(client.close);

    final mutation = client.liveTv.setFavoriteChannels(const []);
    await requestStarted.future;
    releaseResponse.complete();

    await expectLater(
      mutation,
      throwsA(isA<MediaServerHttpException>().having((error) => error.statusCode, 'statusCode', 503)),
    );
  });

  test('favorite write sends the JSON content type Plex cloud requires', () async {
    late http.Request captured;
    final client = makeClient((request) async {
      captured = request;
      return jsonResponse({'MediaContainer': <String, dynamic>{}});
    });
    addTearDown(client.close);

    await client.liveTv.setFavoriteChannels([
      FavoriteChannel(source: 'server://machine-1/provider-a', id: '2', title: 'Channel 2', vcn: '2'),
    ]);

    // Regression: without an explicit content type the body went out as
    // text/plain and epg.provider.plex.tv rejected the PUT with 400 (#1878).
    expect(captured.method, 'PUT');
    expect(captured.url.toString(), 'https://epg.provider.plex.tv/settings/favoriteChannels');
    expect(captured.headers['content-type'], startsWith('application/json'));
    expect(jsonDecode(captured.body), [
      {'source': 'server://machine-1/provider-a', 'id': '2', 'title': 'Channel 2', 'vcn': '2'},
    ]);
  });

  test('DVR list applies root channel mapping to each DVR and parses flexible enabled flags', () async {
    final client = makeClient((request) async {
      expect(request.url.path, '/livetv/dvrs');
      return jsonResponse({
        'MediaContainer': {
          'Dvr': [
            {'key': '1', 'uuid': 'dvr-1', 'lineupTitle': 'Antenna', 'tuners': '2', 'status': '1'},
          ],
          'ChannelMapping': [
            {'channelKey': 'ch-1', 'enabled': '1', 'lineupIdentifier': '001'},
          ],
        },
      });
    });
    addTearDown(client.close);

    final dvrs = await client.liveTvDvr!.fetchDvrs();

    expect(dvrs, hasLength(1));
    expect(dvrs.single.key, '1');
    expect(dvrs.single.lineupTitle, 'Antenna');
    expect(dvrs.single.channelMappings.single.channelKey, 'ch-1');
    expect(dvrs.single.channelMappings.single.enabled, isTrue);
  });

  test('subscription template parses settings and URL-encoded enum labels', () async {
    final client = makeClient((request) async {
      expect(request.url.path, '/media/subscriptions/template');
      expect(request.url.queryParameters['guid'], 'plex://episode/1');
      return jsonResponse({
        'MediaContainer': {
          'SubscriptionTemplate': [
            {
              'MediaSubscription': [
                {
                  'key': '',
                  'type': 4,
                  'selected': '1',
                  'title': 'This Episode',
                  'parameters': 'hints%5Bguid%5D=plex%3A%2F%2Fepisode%2F1',
                  'Setting': [
                    {'id': 'startTimeslot', 'type': 'int', 'value': '-1', 'enumValues': ':Any|1715319000:12%3A30%20AM'},
                  ],
                },
              ],
            },
          ],
        },
      });
    });
    addTearDown(client.close);

    final templates = await client.liveTvDvr!.getSubscriptionTemplate('plex://episode/1');

    final subscription = templates.single.subscriptions.single;
    expect(subscription.selected, isTrue);
    expect(subscription.parameters, contains('hints%5Bguid%5D'));
    expect(subscription.settings.single.options.map((o) => o.label), ['Any', '12:30 AM']);
  });

  test('createRecordingRule preserves template parameters and all prefs as query params', () async {
    late http.Request captured;
    final client = makeClient((request) async {
      captured = request;
      return jsonResponse({
        'MediaContainer': {
          'MediaSubscription': [
            {'key': '18', 'type': 4, 'title': 'Episode'},
          ],
        },
      });
    });
    addTearDown(client.close);

    final request = MediaSubscriptionCreateRequest.fromTemplate(
      const MediaSubscription(
        key: '',
        targetLibrarySectionID: 2,
        type: 4,
        parameters: 'hints%5Bguid%5D=plex%3A%2F%2Fepisode%2F1',
        settings: [
          SubscriptionSetting(id: 'oneShot', value: 'true', defaultValue: 'false', hidden: true),
          SubscriptionSetting(id: 'remoteMedia', value: 'false', defaultValue: 'false', hidden: true),
          SubscriptionSetting(id: 'startOffsetMinutes', value: '0', defaultValue: '0'),
        ],
      ),
      prefs: const {'startOffsetMinutes': 5},
    );

    final created = await client.liveTvDvr!.createRecordingRule(request);

    expect(captured.method, 'POST');
    expect(captured.url.path, '/media/subscriptions');
    expect(captured.body, isEmpty);
    expect(captured.headers.containsKey('content-type'), isFalse);
    expect(captured.url.queryParameters['hints[guid]'], 'plex://episode/1');
    expect(captured.url.queryParameters['targetLibrarySectionID'], '2');
    expect(captured.url.queryParameters['type'], '4');
    expect(captured.url.queryParameters['prefs[oneShot]'], 'true');
    expect(captured.url.queryParameters['prefs[remoteMedia]'], 'false');
    expect(captured.url.queryParameters['prefs[startOffsetMinutes]'], '5');
    expect(created?.key, '18');
  });

  test('fromTemplate section override drops the template location id', () async {
    late http.Request captured;
    final client = makeClient((request) async {
      captured = request;
      return jsonResponse({
        'MediaContainer': {
          'MediaSubscription': [
            {'key': '18', 'type': 4, 'title': 'Episode'},
          ],
        },
      });
    });
    addTearDown(client.close);

    const template = MediaSubscription(key: '', targetLibrarySectionID: 2, targetSectionLocationID: 7, type: 4);

    final overridden = MediaSubscriptionCreateRequest.fromTemplate(template, targetLibrarySectionID: 5);
    expect(overridden.targetLibrarySectionID, 5);
    expect(overridden.targetSectionLocationID, isNull);

    await client.liveTvDvr!.createRecordingRule(overridden);
    expect(captured.url.queryParameters['targetLibrarySectionID'], '5');
    expect(captured.url.queryParameters.containsKey('targetSectionLocationID'), isFalse);
  });

  test('fromTemplate without override keeps template section and location', () {
    const template = MediaSubscription(key: '', targetLibrarySectionID: 2, targetSectionLocationID: 7, type: 4);

    final request = MediaSubscriptionCreateRequest.fromTemplate(template);
    expect(request.targetLibrarySectionID, 2);
    expect(request.targetSectionLocationID, 7);

    // Same-section override is a no-op: the template location still applies.
    final sameSection = MediaSubscriptionCreateRequest.fromTemplate(template, targetLibrarySectionID: 2);
    expect(sameSection.targetSectionLocationID, 7);
  });

  test('updateRecordingRule sends prefs as query params', () async {
    late http.Request captured;
    final client = makeClient((request) async {
      captured = request;
      return jsonResponse({
        'MediaContainer': {
          'MediaSubscription': [
            {'key': '18', 'type': 4, 'title': 'Episode'},
          ],
        },
      });
    });
    addTearDown(client.close);

    final updated = await client.liveTvDvr!.updateRecordingRule('18', const {'startOffsetMinutes': 5});

    expect(captured.method, 'PUT');
    expect(captured.url.path, '/media/subscriptions/18');
    expect(captured.body, isEmpty);
    expect(captured.url.queryParameters['prefs[startOffsetMinutes]'], '5');
    expect(updated?.key, '18');
  });

  test('recording rules parse active grab operation metadata', () async {
    late http.Request captured;
    final client = makeClient((request) async {
      captured = request;
      return jsonResponse({
        'MediaContainer': {
          'MediaSubscription': [
            {
              'key': '18',
              'type': 4,
              'title': 'Episode',
              'MediaGrabOperation': [
                {
                  'id': 'grab-active',
                  'status': 'grabbing',
                  'Metadata': {
                    'title': 'Live Episode',
                    'ratingKey': 'episode-1',
                    'guid': 'plex://episode/1',
                    'Media': [
                      {'beginsAt': '1466060400', 'endsAt': '1466062200', 'channelIdentifier': '004'},
                    ],
                  },
                },
              ],
            },
          ],
        },
      });
    });
    addTearDown(client.close);

    final rules = await client.liveTvDvr!.fetchRecordingRules(includeGrabs: true, includeStorage: false);

    expect(captured.url.path, '/media/subscriptions');
    expect(captured.url.queryParameters['includeGrabs'], '1');
    expect(captured.url.queryParameters['includeStorage'], '0');
    final grab = rules.single.grabOperations.single;
    expect(grab.status, 'grabbing');
    expect(grab.program?.ratingKey, 'episode-1');
    expect(grab.program?.guid, 'plex://episode/1');
    expect(grab.program?.channelIdentifier, '004');
  });

  test('cancelGrab deletes the operation key path', () async {
    late http.Request captured;
    final client = makeClient((request) async {
      captured = request;
      return jsonResponse({'MediaContainer': <String, dynamic>{}});
    });
    addTearDown(client.close);

    await client.liveTvDvr!.cancelGrab('/media/grabbers/operations/grab-1');

    expect(captured.method, 'DELETE');
    expect(captured.url.path, '/media/grabbers/operations/grab-1');
  });

  test('scheduled recordings parse grab operation metadata', () async {
    final client = makeClient((request) async {
      expect(request.url.path, '/media/subscriptions/scheduled');
      return jsonResponse({
        'MediaContainer': {
          'MediaGrabOperation': [
            {
              'id': 'grab-1',
              'key': '/media/grabbers/operations/grab-1',
              'mediaSubscriptionID': '7',
              'status': 'scheduled',
              'percent': '42.5',
              'Metadata': {
                'title': 'Miracle on Dead Street',
                'grandparentTitle': 'Fresh Off the Boat',
                'type': 'episode',
                'Media': [
                  {'beginsAt': '1466060400', 'endsAt': '1466062200', 'channelIdentifier': '004'},
                ],
              },
            },
          ],
        },
      });
    });
    addTearDown(client.close);

    final operations = await client.liveTvDvr!.fetchScheduledRecordings();

    expect(operations.single.id, 'grab-1');
    expect(operations.single.operationKey, '/media/grabbers/operations/grab-1');
    expect(operations.single.mediaSubscriptionID, 7);
    expect(operations.single.percent, 42.5);
    expect(operations.single.program?.grandparentTitle, 'Fresh Off the Boat');
    expect(operations.single.program?.channelIdentifier, '004');
  });

  test('subscription mapping targets the numeric provider id route', () async {
    // The identifier-scoped form 404s on PMS (issue #2009); the official
    // client mounts this route under the numeric MediaProvider id.
    late http.Request captured;
    final client = makeClient((request) async {
      captured = request;
      return jsonResponse({
        'MediaContainer': {
          'MediaSubscription': [
            // The mapping endpoint identifies rules by `id`, not `key`.
            {'id': 1106, 'type': 2},
          ],
        },
      });
    });
    addTearDown(client.close);

    final mapped = await client.liveTvDvr!.fetchSubscriptionMapping(
      providerId: 'provider-a',
      ratingKeys: ['plex%3A%2F%2Fepisode%2F6a7fba88cb8a706b4d3047bb'],
    );

    expect(
      captured.url.path,
      '/media/providers/2/media/subscriptions/mapping/plex%3A%2F%2Fepisode%2F6a7fba88cb8a706b4d3047bb',
    );
    expect(captured.url.queryParameters['includeStorage'], '1');
    expect(mapped.single.key, '1106');
  });

  test('scheduled recordings read the airing from Video when Metadata is absent', () async {
    // PMS nests the airing under `Metadata` only for `scheduled` grabs;
    // active/complete/error grabs use `Video` (issue #2009 captures).
    final client = makeClient((request) async {
      return jsonResponse({
        'MediaContainer': {
          'MediaGrabOperation': [
            {
              'id': 'grab-2',
              'mediaSubscriptionID': 1456,
              'status': 'recording',
              'Video': {
                'ratingKey': 'plex%3A%2F%2Fepisode%2F6a5860d74ec32227cf90b41d',
                'guid': 'plex://episode/6a5860d74ec32227cf90b41d',
                'key': '/tv.plex.providers.epg.cloud:2/metadata/plex%3A%2F%2Fepisode%2F6a5860d74ec32227cf90b41d',
                'type': 'episode',
                'title': 'Wheeler Dealers',
              },
            },
          ],
        },
      });
    });
    addTearDown(client.close);

    final operations = await client.liveTvDvr!.fetchScheduledRecordings();

    expect(operations.single.program?.ratingKey, 'plex%3A%2F%2Fepisode%2F6a5860d74ec32227cf90b41d');
    expect(operations.single.program?.guid, 'plex://episode/6a5860d74ec32227cf90b41d');
  });

  test('EPG grid airings keep their subscription attributes', () async {
    // The grid tags subscribed airings itself — the signal the recording
    // indicator renders from (issue #2009 capture C).
    final client = makeClient((request) async {
      expect(request.url.path, '/provider-a/grid');
      return jsonResponse({
        'MediaContainer': {
          'Metadata': [
            {
              'ratingKey': 'plex%3A%2F%2Fepisode%2F6a740f1dfe67d773c5efd406',
              'guid': 'plex://episode/6a740f1dfe67d773c5efd406',
              'key': '/tv.plex.providers.epg.cloud:2/metadata/plex%3A%2F%2Fepisode%2F6a740f1dfe67d773c5efd406',
              'grandparentSubscriptionID': '1456',
              'type': 'episode',
              'title': 'Aston Martin DB6',
              'Media': [
                {'beginsAt': '1466060400', 'endsAt': '1466062200', 'channelIdentifier': '004'},
              ],
            },
            {
              'ratingKey': 'plex%3A%2F%2Fepisode%2Funsubscribed',
              'type': 'episode',
              'title': 'Untagged Airing',
              'Media': [
                {'beginsAt': '1466062200', 'endsAt': '1466064000', 'channelIdentifier': '004'},
              ],
            },
          ],
        },
      });
    });
    addTearDown(client.close);

    final programs = await client.liveTv.fetchSchedule();

    expect(programs, hasLength(2));
    expect(programs[0].grandparentSubscriptionId, '1456');
    expect(programs[0].recordingRuleKey, '1456');
    expect(programs[1].subscriptionId, isNull);
    expect(programs[1].recordingRuleKey, isNull);
  });
}
