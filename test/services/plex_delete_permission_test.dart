import 'dart:async';

import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';
import 'package:plezy/utils/active_client_scope.dart';
import 'package:plezy/utils/media_server_timeouts.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/http_fixtures.dart';
import '../test_helpers/media_items.dart';

/// PMS carries out `DELETE /library/metadata/{id}` even with the server's
/// "Allow media deletion" switch off (#2897), so the client is the only thing
/// standing between a stale menu and a deleted file. The switch lives on the
/// root MediaContainer as `allowMediaDeletion` and is omitted when off.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
  });

  tearDown(() async {
    await db.close();
  });

  final movie = testMediaItem(
    id: 'movie-1',
    backend: MediaBackend.plex,
    kind: MediaKind.movie,
    title: 'Movie',
    serverId: 'server-id',
  );

  http.Response root(Map<String, Object?> container) => jsonResponse({'MediaContainer': container});

  ({PlexClient client, List<http.Request> requests}) clientAnswering(
    Future<http.Response> Function(http.Request request) handler, {
    List<String>? prioritizedEndpoints,
  }) {
    final requests = <http.Request>[];
    final client = testPlexClient(
      serverId: ServerId('server-id'),
      prioritizedEndpoints: prioritizedEndpoints,
      handler: (request) {
        requests.add(request);
        return handler(request);
      },
    );
    addTearDown(client.close);
    return (client: client, requests: requests);
  }

  List<http.Request> deletesIn(List<http.Request> requests) => requests.where((r) => r.method == 'DELETE').toList();

  group('PlexClient.fetchDeletePermission', () {
    test('reads the switch from the authenticated root of the current endpoint only', () async {
      final fake = clientAnswering(
        (_) async => root({'allowMediaDeletion': true}),
        prioritizedEndpoints: const ['https://plex.example.com', 'https://plex-fallback.example.com'],
      );

      expect(fake.client, isA<MediaDeletionPermissionClient>());
      expect(await fake.client.fetchDeletePermission(movie), isTrue);

      final request = fake.requests.single;
      expect(request.method, 'GET');
      // The root, not `/identity` (which never carries the switch) and not
      // `/:/prefs` (a once-per-connect snapshot nothing refreshes).
      expect(request.url.path, '/');
      expect(request.url.host, 'plex.example.com');
      expect(request.headers['X-Plex-Token'], 'token');
    });

    test('reports the switch in every encoding PMS uses', () async {
      const encodings = <Object, bool>{
        true: true,
        1: true,
        '1': true,
        'true': true,
        false: false,
        0: false,
        '0': false,
      };
      for (final MapEntry(key: value, value: expected) in encodings.entries) {
        final fake = clientAnswering((_) async => root({'allowMediaDeletion': value}));

        expect(await fake.client.fetchDeletePermission(movie), expected, reason: 'allowMediaDeletion: $value');
      }
    });

    test('treats a missing switch as off', () async {
      // PMS omits the attribute when the switch is off.
      final fake = clientAnswering((_) async => root({'friendlyName': 'Plex', 'machineIdentifier': 'server-id'}));

      expect(await fake.client.fetchDeletePermission(movie), isFalse);
    });

    test('returns null for a body without a MediaContainer', () async {
      final fake = clientAnswering((_) async => jsonResponse({'unexpected': true}));

      expect(await fake.client.fetchDeletePermission(movie), isNull);
    });

    test('throws on an error response instead of reporting a permission', () async {
      for (final status in [401, 500]) {
        final fake = clientAnswering((_) async => http.Response('nope', status));

        await expectLater(
          fake.client.fetchDeletePermission(movie),
          throwsA(isA<MediaServerHttpException>().having((e) => e.statusCode, 'statusCode', status)),
        );
      }
    });

    test('does not move to another endpoint when the current one fails', () async {
      final fake = clientAnswering(
        (request) async => throw http.ClientException('connection refused', request.url),
        prioritizedEndpoints: const ['https://plex.example.com', 'https://plex-fallback.example.com'],
      );

      await expectLater(fake.client.fetchDeletePermission(movie), throwsA(isA<MediaServerHttpException>()));

      expect(fake.requests.map((r) => r.url.host), ['plex.example.com']);
      expect(fake.client.config.baseUrl, 'https://plex.example.com');
    });

    test('reads the switch fresh on every call', () async {
      var allowed = true;
      final fake = clientAnswering((_) async => root({'allowMediaDeletion': allowed}));

      expect(await fake.client.fetchDeletePermission(movie), isTrue);
      allowed = false;
      expect(await fake.client.fetchDeletePermission(movie), isFalse);
      allowed = true;
      expect(await fake.client.fetchDeletePermission(movie), isTrue);
      expect(fake.requests, hasLength(3));
    });

    test('gives up on a server that never answers, and aborts the request', () {
      fakeAsync((async) {
        final transport = _HangingClient();
        final client = testPlexClient(serverId: ServerId('server-id'), httpClient: transport);
        addTearDown(client.close);

        final failure = _failureOf(client.fetchDeletePermission(movie));

        async.elapse(MediaServerTimeouts.deletePermissionProbe - const Duration(milliseconds: 1));
        expect(failure(), isNull);
        expect(transport.aborted, isFalse);

        async.elapse(const Duration(milliseconds: 2));
        expect(failure(), _isProbeTimeout);
        expect(transport.aborted, isTrue, reason: 'the hung request must be stopped, not left running');
        expect(transport.requests.map((r) => r.url.path), ['/']);
      });
    });

    test('caps a slow connect followed by a stalled body at the whole-probe deadline', () {
      fakeAsync((async) {
        final body = StreamController<List<int>>();
        addTearDown(body.close);
        final client = testPlexClient(
          serverId: ServerId('server-id'),
          httpClient: MockClient.streaming((_, _) async {
            await Future<void>.delayed(MediaServerTimeouts.deletePermissionProbe - const Duration(seconds: 1));
            return http.StreamedResponse(body.stream, 200, headers: const {'content-type': 'application/json'});
          }),
        );
        addTearDown(client.close);

        final failure = _failureOf(client.fetchDeletePermission(movie));

        async.elapse(MediaServerTimeouts.deletePermissionProbe - const Duration(milliseconds: 1));
        expect(failure(), isNull, reason: 'the response arrived in time; only the body is stalled');

        async.elapse(const Duration(milliseconds: 2));
        expect(failure(), _isProbeTimeout);
        expect(async.elapsed, lessThan(MediaServerTimeouts.deletePermissionProbe * 2));
      });
    });
  });

  group('PlexClient.deleteMediaItem', () {
    test('deletes exactly the item once the server allows it', () async {
      final fake = clientAnswering((request) async {
        if (request.method == 'DELETE') return http.Response('', 200);
        return root({'allowMediaDeletion': true});
      });

      expect(await fake.client.deleteMediaItem(movie), isTrue);

      expect(fake.requests.map((r) => '${r.method} ${r.url.path}'), ['GET /', 'DELETE /library/metadata/movie-1']);
    });

    test('sends no DELETE when the switch is off or missing (#2897)', () async {
      final answers = <String, http.Response Function()>{
        'off': () => root({'allowMediaDeletion': false}),
        'off as a string': () => root({'allowMediaDeletion': '0'}),
        'missing': () => root({'friendlyName': 'Plex'}),
        'no MediaContainer': () => jsonResponse({'unexpected': true}),
      };
      for (final MapEntry(key: label, value: answer) in answers.entries) {
        final fake = clientAnswering((request) async {
          if (request.method == 'DELETE') return http.Response('', 200);
          return answer();
        });

        await expectLater(
          fake.client.deleteMediaItem(movie),
          throwsA(isA<MediaDeletionRefusedException>()),
          reason: 'switch $label',
        );
        expect(deletesIn(fake.requests), isEmpty, reason: 'switch $label');
      }
    });

    test('sends no DELETE when the switch cannot be read', () async {
      final fake = clientAnswering((request) async {
        if (request.method == 'DELETE') return http.Response('', 200);
        return http.Response('boom', 500);
      });

      await expectLater(fake.client.deleteMediaItem(movie), throwsA(isA<MediaServerHttpException>()));
      expect(deletesIn(fake.requests), isEmpty);
    });

    test('sends no DELETE when the check times out, even if a late answer allows it', () {
      fakeAsync((async) {
        final requests = <http.Request>[];
        final client = testPlexClient(
          serverId: ServerId('server-id'),
          handler: (request) async {
            requests.add(request);
            if (request.method == 'DELETE') return http.Response('', 200);
            await Future<void>.delayed(MediaServerTimeouts.deletePermissionProbe + const Duration(seconds: 1));
            return root({'allowMediaDeletion': true});
          },
        );
        addTearDown(client.close);

        final failure = _failureOf(client.deleteMediaItem(movie));

        async.elapse(MediaServerTimeouts.deletePermissionProbe * 4);
        expect(failure(), _isProbeTimeout);
        expect(deletesIn(requests), isEmpty);
      });
    });

    test('checks again when the switch was turned off after the menu read it', () async {
      var allowed = true;
      final fake = clientAnswering((request) async {
        if (request.method == 'DELETE') return http.Response('', 200);
        return root({'allowMediaDeletion': allowed});
      });

      // The menu saw the switch on and offered the entry; the admin turned it
      // off while the confirmation dialog was open.
      expect(await fake.client.fetchDeletePermission(movie), isTrue);
      allowed = false;

      await expectLater(fake.client.deleteMediaItem(movie), throwsA(isA<MediaDeletionRefusedException>()));
      expect(fake.requests.where((r) => r.method == 'GET'), hasLength(2));
      expect(deletesIn(fake.requests), isEmpty);
    });

    test('does not delete when the Plex Home user changed while the switch was being read', () async {
      final ownerProbeArrived = Completer<void>();
      final releaseOwnerProbe = Completer<void>();
      final fake = clientAnswering((request) async {
        if (request.method == 'DELETE') return http.Response('', 200);
        if (request.url.path == '/media/providers') return root({});
        if (request.headers['X-Plex-Token'] == 'home-token') {
          // The profile switch validates its token against the same root.
          return root({'machineIdentifier': 'server-id', 'allowMediaDeletion': true});
        }
        ownerProbeArrived.complete();
        await releaseOwnerProbe.future;
        return root({'allowMediaDeletion': true});
      });

      final deletion = fake.client.deleteMediaItem(movie);
      await ownerProbeArrived.future;
      final switched = await fake.client.applyProfileUpdate(
        newToken: 'home-token',
        newProfileScopeId: buildPlexProfileScopeId(serverId: ServerId('server-id'), profileId: 'home-user'),
      );
      expect(switched, isTrue);
      releaseOwnerProbe.complete();

      expect(await deletion, isFalse);
      expect(deletesIn(fake.requests), isEmpty, reason: "the owner's answer must not authorize the new user's DELETE");
    });
  });
}

/// Records requests and never answers; reports whether the caller aborted.
class _HangingClient extends http.BaseClient {
  final requests = <http.BaseRequest>[];
  var aborted = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    requests.add(request);
    final response = Completer<http.StreamedResponse>();
    final trigger = request is http.Abortable ? request.abortTrigger : null;
    unawaited(
      trigger?.then((_) {
        aborted = true;
        response.completeError(http.RequestAbortedException(request.url));
      }),
    );
    return response.future;
  }
}

/// Hands back a getter for whatever [future] failed with, so a [fakeAsync]
/// body can advance the clock and inspect the outcome without awaiting inside
/// the zone.
Object? Function() _failureOf(Future<Object?> future) {
  Object? failure;
  future.then<void>(
    (_) {},
    onError: (Object e) {
      failure = e;
    },
  );
  return () => failure;
}

/// The canonical media-server failure, the same shape `MediaServerHttpClient`
/// raises for its own per-phase expiries, so callers need one catch.
final _isProbeTimeout = isA<MediaServerHttpException>().having(
  (e) => e.type,
  'type',
  MediaServerHttpErrorType.connectionTimeout,
);
