import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/models/media_subscription.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/http_fixtures.dart';

/// `GET /LiveTv/Timers/Defaults?programId=` fixture: the full
/// `SeriesTimerInfoDto` the server pre-fills for a program. The canonical
/// MediaBrowser create flow mutates this object and POSTs it back whole.
Map<String, dynamic> timerDefaults() => {
  'Id': 'synthetic-defaults-id',
  'Type': 'SeriesTimer',
  'ServerId': 'srv-1',
  'ServiceName': 'Emby',
  'ChannelId': 'chan-1',
  'ChannelName': 'HBO',
  'ProgramId': 'prog-1',
  'ExternalProgramId': 'ext-prog-1',
  'Name': 'The Show',
  'Overview': 'Pilot',
  'StartDate': '2026-08-23T20:00:00.0000000Z',
  'EndDate': '2026-08-23T21:00:00.0000000Z',
  'Priority': 0,
  'PrePaddingSeconds': 60,
  'PostPaddingSeconds': 120,
  'IsPrePaddingRequired': false,
  'IsPostPaddingRequired': false,
  'KeepUntil': 'UntilDeleted',
  'RecordAnyTime': true,
  'SkipEpisodesInLibrary': true,
  'RecordAnyChannel': false,
  'KeepUpTo': 0,
  'RecordNewOnly': true,
  'Days': ['Sunday'],
  'DayPattern': 'Daily',
};

void main() {
  group('getSubscriptionTemplate', () {
    test('series program yields episode and series entries carrying the defaults payload', () async {
      final captured = <http.Request>[];
      final client = testJellyfinClient(
        handler: (request) async {
          captured.add(request);
          return switch (request.url.path) {
            '/LiveTv/Timers/Defaults' => jsonResponse(timerDefaults()),
            '/LiveTv/Programs/prog-1' => jsonResponse({'Id': 'prog-1', 'IsSeries': true}),
            _ => fail('Unexpected request: ${request.method} ${request.url}'),
          };
        },
      );
      addTearDown(client.close);

      final templates = await client.liveTvDvr!.getSubscriptionTemplate('prog-1');

      expect(captured.first.url.path, '/LiveTv/Timers/Defaults');
      expect(captured.first.url.queryParameters['programId'], 'prog-1');

      final entries = templates.single.subscriptions;
      expect(entries, hasLength(2));

      final episode = entries.first;
      expect(episode.type, MediaSubscription.typeEpisode);
      expect(episode.selected, isTrue);
      expect(episode.settings.map((s) => s.id), ['PrePaddingSeconds', 'PostPaddingSeconds']);
      expect(episode.settings.first.value, 60);
      expect(jsonDecode(episode.parameters!), timerDefaults());

      final series = entries.last;
      expect(series.type, MediaSubscription.typeSeries);
      expect(series.settings.map((s) => s.id), [
        'PrePaddingSeconds',
        'PostPaddingSeconds',
        'RecordNewOnly',
        'RecordAnyChannel',
        'RecordAnyTime',
        'SkipEpisodesInLibrary',
        'KeepUpTo',
      ]);
      // Values mirror the server defaults so the sheet round-trips them.
      expect(series.settings.firstWhere((s) => s.id == 'RecordNewOnly').value, true);
      expect(series.settings.firstWhere((s) => s.id == 'RecordAnyChannel').value, false);
    });

    test('non-series program yields only the episode entry', () async {
      final client = testJellyfinClient(
        handler: (request) async => switch (request.url.path) {
          '/LiveTv/Timers/Defaults' => jsonResponse(timerDefaults()),
          '/LiveTv/Programs/prog-1' => jsonResponse({'Id': 'prog-1', 'IsSeries': false}),
          _ => fail('Unexpected request: ${request.url}'),
        },
      );
      addTearDown(client.close);

      final templates = await client.liveTvDvr!.getSubscriptionTemplate('prog-1');
      final entries = templates.single.subscriptions;
      expect(entries.single.type, MediaSubscription.typeEpisode);
    });

    test('series probe failure degrades to episode-only instead of blocking', () async {
      final client = testJellyfinClient(
        handler: (request) async => switch (request.url.path) {
          '/LiveTv/Timers/Defaults' => jsonResponse(timerDefaults()),
          _ => http.Response('boom', 500),
        },
      );
      addTearDown(client.close);

      final templates = await client.liveTvDvr!.getSubscriptionTemplate('prog-1');
      expect(templates.single.subscriptions.single.type, MediaSubscription.typeEpisode);
    });
  });

  group('createRecordingRule', () {
    /// Fetch real template entries through the adapter so create tests
    /// exercise the same objects the record-options sheet hands back.
    Future<(MediaSubscription episode, MediaSubscription series)> fetchTemplate() async {
      final client = testJellyfinClient(
        handler: (request) async => switch (request.url.path) {
          '/LiveTv/Timers/Defaults' => jsonResponse(timerDefaults()),
          '/LiveTv/Programs/prog-1' => jsonResponse({'Id': 'prog-1', 'IsSeries': true}),
          _ => fail('Unexpected request: ${request.url}'),
        },
      );
      addTearDown(client.close);
      final entries = (await client.liveTvDvr!.getSubscriptionTemplate('prog-1')).single.subscriptions;
      return (entries.first, entries.last);
    }

    test('one-off create POSTs the mutated defaults to /LiveTv/Timers', () async {
      final (episode, _) = await fetchTemplate();
      final writes = <http.Request>[];
      final client = testJellyfinClient(
        handler: (request) async {
          writes.add(request);
          return http.Response('', 204);
        },
      );
      addTearDown(client.close);

      final request = MediaSubscriptionCreateRequest.fromTemplate(episode, prefs: {'PrePaddingSeconds': 300});
      final created = await client.liveTvDvr!.createRecordingRule(request);

      expect(created, isNull);
      final post = writes.single;
      expect(post.method, 'POST');
      expect(post.url.path, '/LiveTv/Timers');
      final body = jsonDecode(post.body) as Map<String, dynamic>;
      // Dirty pref overlaid; everything else from the defaults survives.
      expect(body['PrePaddingSeconds'], 300);
      expect(body['ServiceName'], 'Emby');
      expect(body['ProgramId'], 'prog-1');
      expect(body['RecordNewOnly'], true);
    });

    test('series create routes to /LiveTv/SeriesTimers and accepts an Emby-style bare 200', () async {
      final (_, series) = await fetchTemplate();
      final writes = <http.Request>[];
      final client = testJellyfinClient(
        handler: (request) async {
          writes.add(request);
          // Emby documents 200 with an empty body where Jellyfin answers 204.
          return http.Response('', 200);
        },
      );
      addTearDown(client.close);

      final request = MediaSubscriptionCreateRequest.fromTemplate(series, prefs: {'RecordNewOnly': false});
      await client.liveTvDvr!.createRecordingRule(request);

      final post = writes.single;
      expect(post.method, 'POST');
      expect(post.url.path, '/LiveTv/SeriesTimers');
      final body = jsonDecode(post.body) as Map<String, dynamic>;
      expect(body['RecordNewOnly'], false);
      expect(body['SkipEpisodesInLibrary'], true);
    });

    test('duplicate one-off create (HTTP 400) surfaces as RecordingConflictException', () async {
      final (episode, _) = await fetchTemplate();
      final client = testJellyfinClient(handler: (_) async => http.Response('Error processing request.', 400));
      addTearDown(client.close);

      final request = MediaSubscriptionCreateRequest.fromTemplate(episode);
      await expectLater(client.liveTvDvr!.createRecordingRule(request), throwsA(isA<RecordingConflictException>()));
    });

    test('series create 400 stays an HTTP exception (not a conflict)', () async {
      final (_, series) = await fetchTemplate();
      final client = testJellyfinClient(handler: (_) async => http.Response('', 400));
      addTearDown(client.close);

      final request = MediaSubscriptionCreateRequest.fromTemplate(series);
      await expectLater(client.liveTvDvr!.createRecordingRule(request), throwsA(isA<MediaServerHttpException>()));
    });
  });

  group('fetchScheduledRecordings', () {
    test('maps active timers to grabs and drops cancelled/completed tombstones', () async {
      final client = testJellyfinClient(
        handler: (request) async {
          expect(request.url.path, '/LiveTv/Timers');
          return jsonResponse({
            'Items': [
              {
                'Id': 't-new',
                'Name': 'Pilot',
                'ProgramId': 'prog-1',
                'ChannelId': 'chan-1',
                'ChannelName': 'HBO',
                'SeriesTimerId': 's-1',
                'Status': 'New',
                'StartDate': '2026-08-23T20:00:00.0000000Z',
                'EndDate': '2026-08-23T21:00:00.0000000Z',
                'ProgramInfo': {'SeriesName': 'The Show', 'IndexNumber': 1, 'ParentIndexNumber': 2},
              },
              {'Id': 't-live', 'Name': 'Live', 'Status': 'InProgress'},
              {'Id': 't-bad', 'Name': 'Broken', 'Status': 'Error'},
              {'Id': 't-skip', 'Name': 'Skipped', 'Status': 'Cancelled'},
              {'Id': 't-done', 'Name': 'Done', 'Status': 'Completed'},
            ],
          });
        },
      );
      addTearDown(client.close);

      final grabs = await client.liveTvDvr!.fetchScheduledRecordings();

      expect(grabs.map((g) => g.operationKey), ['timer:t-new', 'timer:t-live', 'timer:t-bad']);
      expect(grabs.map((g) => g.status), ['scheduled', 'grabbing', 'error']);

      final program = grabs.first.program!;
      expect(program.title, 'Pilot');
      expect(program.grandparentTitle, 'The Show');
      expect(program.ratingKey, 'prog-1');
      expect(program.channelIdentifier, 'chan-1');
      expect(program.beginsAt, DateTime.parse('2026-08-23T20:00:00Z').millisecondsSinceEpoch ~/ 1000);
      expect(program.endsAt, DateTime.parse('2026-08-23T21:00:00Z').millisecondsSinceEpoch ~/ 1000);
      // Rule keys carry their timer space so delete dispatch stays unambiguous.
      expect(program.subscriptionId, 'timer:t-new');
      expect(program.grandparentSubscriptionId, 'series:s-1');
    });
  });

  group('fetchRecordingRules', () {
    test('maps series timers to rules and nests their child grabs', () async {
      final client = testJellyfinClient(
        handler: (request) async => switch (request.url.path) {
          '/LiveTv/SeriesTimers' => jsonResponse({
            'Items': [
              {
                'Id': 's-1',
                'Name': 'The Show',
                'PrePaddingSeconds': 60,
                'PostPaddingSeconds': 120,
                'RecordNewOnly': false,
                'RecordAnyChannel': true,
                'RecordAnyTime': true,
                'SkipEpisodesInLibrary': true,
                'KeepUpTo': 5,
              },
            ],
          }),
          '/LiveTv/Timers' => jsonResponse({
            'Items': [
              {'Id': 't-1', 'Name': 'Ep 1', 'SeriesTimerId': 's-1', 'Status': 'New'},
              {'Id': 't-2', 'Name': 'Ep 2', 'SeriesTimerId': 's-1', 'Status': 'Cancelled'},
              {'Id': 't-3', 'Name': 'One-off', 'Status': 'New'},
            ],
          }),
          _ => fail('Unexpected request: ${request.url}'),
        },
      );
      addTearDown(client.close);

      final rules = await client.liveTvDvr!.fetchRecordingRules();

      final rule = rules.single;
      expect(rule.key, 'series:s-1');
      expect(rule.type, MediaSubscription.typeSeries);
      expect(rule.title, 'The Show');
      // The edit sheet renders these values; they must mirror the DTO.
      expect(rule.settings.firstWhere((s) => s.id == 'RecordNewOnly').value, false);
      expect(rule.settings.firstWhere((s) => s.id == 'KeepUpTo').value, 5);
      // Only the active child counts; the cancelled tombstone and the
      // unrelated one-off stay out.
      expect(rule.grabOperations.map((g) => g.operationKey), ['timer:t-1']);
    });

    test('includeGrabs: false skips the timers fetch', () async {
      final paths = <String>[];
      final client = testJellyfinClient(
        handler: (request) async {
          paths.add(request.url.path);
          return jsonResponse({
            'Items': [
              {'Id': 's-1', 'Name': 'The Show'},
            ],
          });
        },
      );
      addTearDown(client.close);

      await client.liveTvDvr!.fetchRecordingRules(includeGrabs: false);
      expect(paths, ['/LiveTv/SeriesTimers']);
    });
  });

  group('mutations', () {
    test('deleteRecordingRule dispatches on the key prefix', () async {
      final deletes = <String>[];
      final client = testJellyfinClient(
        handler: (request) async {
          expect(request.method, 'DELETE');
          deletes.add(request.url.path);
          return http.Response('', 204);
        },
      );
      addTearDown(client.close);

      final dvr = client.liveTvDvr!;
      await dvr.deleteRecordingRule('series:s-1');
      await dvr.deleteRecordingRule('timer:t-1');
      expect(deletes, ['/LiveTv/SeriesTimers/s-1', '/LiveTv/Timers/t-1']);

      await expectLater(dvr.deleteRecordingRule('naked-id'), throwsArgumentError);
    });

    test('cancelGrab strips the timer prefix and deletes the timer', () async {
      final deletes = <String>[];
      final client = testJellyfinClient(
        handler: (request) async {
          expect(request.method, 'DELETE');
          deletes.add(request.url.path);
          return http.Response('', 204);
        },
      );
      addTearDown(client.close);

      await client.liveTvDvr!.cancelGrab('timer:t-9');
      expect(deletes, ['/LiveTv/Timers/t-9']);
    });

    test('updateRecordingRule re-fetches the rule, overlays prefs, and POSTs it back whole', () async {
      final writes = <http.Request>[];
      final client = testJellyfinClient(
        handler: (request) async {
          if (request.method == 'GET') {
            expect(request.url.path, '/LiveTv/SeriesTimers/s-1');
            return jsonResponse({
              'Id': 's-1',
              'Name': 'The Show',
              'ServiceName': 'Emby',
              'RecordNewOnly': true,
              'PrePaddingSeconds': 60,
            });
          }
          writes.add(request);
          return http.Response('', 204);
        },
      );
      addTearDown(client.close);

      await client.liveTvDvr!.updateRecordingRule('series:s-1', {'RecordNewOnly': false});

      final post = writes.single;
      expect(post.method, 'POST');
      expect(post.url.path, '/LiveTv/SeriesTimers/s-1');
      final body = jsonDecode(post.body) as Map<String, dynamic>;
      expect(body['RecordNewOnly'], false);
      // Untouched fields survive the round trip.
      expect(body['ServiceName'], 'Emby');
      expect(body['PrePaddingSeconds'], 60);
    });

    test('updateRecordingRule rejects non-series keys', () async {
      final client = testJellyfinClient(handler: (_) async => fail('must not hit the network'));
      addTearDown(client.close);
      await expectLater(client.liveTvDvr!.updateRecordingRule('timer:t-1', const {}), throwsArgumentError);
    });

    test('processRecordingRules is unsupported and loud about it', () async {
      final client = testJellyfinClient(handler: (_) async => fail('must not hit the network'));
      addTearDown(client.close);
      final dvr = client.liveTvDvr!;
      expect(dvr.supportsRuleProcessing, isFalse);
      await expectLater(dvr.processRecordingRules(), throwsUnsupportedError);
    });
  });

  group('Emby dialect', () {
    test('shares the adapter: capability on, same timer routes, client-side status filtering', () async {
      final captured = <Uri>[];
      final client = testEmbyClient(
        handler: (request) async {
          captured.add(request.url);
          // Emby's QueryResult omits StartIndex; keep the envelope minimal.
          return jsonResponse({
            'Items': [
              {'Id': 't-1', 'Name': 'Ep 1', 'Status': 'New'},
              {'Id': 't-2', 'Name': 'Old', 'Status': 'Completed'},
            ],
            'TotalRecordCount': 2,
          });
        },
      );
      addTearDown(client.close);

      expect(client.capabilities.liveTvDvr, isTrue);
      final grabs = await client.liveTvDvr!.fetchScheduledRecordings();

      // Status filtering happens client-side because Emby's GET /LiveTv/Timers
      // has no isActive/isScheduled query params.
      expect(captured.single.path, '/LiveTv/Timers');
      expect(captured.single.queryParameters, isEmpty);
      expect(grabs.single.operationKey, 'timer:t-1');
    });
  });
}
