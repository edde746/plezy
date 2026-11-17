import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/models/seerr/seerr_request.dart';
import 'package:plezy/models/seerr/seerr_session.dart';
import 'package:plezy/services/seerr/seerr_client.dart';
import 'package:plezy/services/seerr/seerr_constants.dart';
import 'package:plezy/services/seerr/seerr_exceptions.dart';

http.Response _json(Object body, {int status = 200}) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

/// Seerr answers its deletes with an empty 204.
http.Response _noContent() => http.Response('', 204);

/// `isAuthenticated(permission)` middleware refusal — the body is the same
/// for a missing permission and for a session Seerr no longer knows.
http.Response _middlewareDenied() =>
    _json({'status': 403, 'error': 'You do not have permission to access this endpoint'}, status: 403);

({SeerrClient client, List<SeerrSession> updates, List<bool> invalidated}) _client(
  MockClient mock, {
  int permissions = SeerrPermission.manageRequests,
}) {
  final updates = <SeerrSession>[];
  final invalidated = <bool>[];
  final client = SeerrClient(
    SeerrSession(
      baseUrl: 'https://seerr.example.com',
      method: SeerrAuthMethod.local,
      identifier: 'a@b.c',
      secret: 'pw',
      cookie: 'cookie',
      userId: 7,
      permissions: permissions,
      displayName: 'Alice',
      instanceLabel: 'Seerr',
      createdAt: 0,
    ),
    onSessionInvalidated: () => invalidated.add(true),
    onSessionUpdated: updates.add,
    httpClient: mock,
  );
  addTearDown(client.dispose);
  return (client: client, updates: updates, invalidated: invalidated);
}

Map<String, dynamic> _request({
  required int id,
  int status = 1,
  bool is4k = false,
  String type = 'movie',
  int requestedBy = 7,
  bool? canRemove,
}) => {
  'id': id,
  'status': status,
  'is4k': is4k,
  'type': type,
  'createdAt': '2026-11-01T10:00:00.000Z',
  'media': {
    'id': 90 + id,
    'mediaType': type,
    'tmdbId': 600 + id,
    'status': 3,
    'status4k': 1,
    'serviceId': 0,
    'serviceId4k': null,
  },
  'requestedBy': {'id': requestedBy, 'displayName': 'Alice', 'email': 'a@b.c'},
  'seasons': [
    if (type == 'tv') {'id': 1, 'seasonNumber': 2, 'status': status},
  ],
  'canRemove': ?canRemove,
};

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group('SeerrClient.getRequests', () {
    test('sends paging, filter, sort and requester, and reads the pageInfo envelope', () async {
      late Uri seen;
      final (:client, updates: _, invalidated: _) = _client(
        MockClient((request) async {
          seen = request.url;
          expect(request.method, 'GET');
          return _json({
            'pageInfo': {'pages': 3, 'pageSize': 20, 'results': 45, 'page': 2},
            'results': [
              _request(id: 1, canRemove: true),
              _request(id: 2, status: 2, is4k: true, type: 'tv', requestedBy: 9),
            ],
          });
        }),
      );

      final page = await client.getRequests(take: 20, skip: 20, filter: 'pending', requestedBy: 7);

      expect(seen.path, '/api/v1/request');
      expect(seen.queryParameters, {
        'take': '20',
        'skip': '20',
        'filter': 'pending',
        'sort': 'added',
        'requestedBy': '7',
      });
      expect(page.hasMore, isTrue);
      expect(page.totalResults, 45);
      expect(page.items.map((r) => r.id), [1, 2]);

      final first = page.items.first;
      expect(first.status, SeerrRequestStatus.pending);
      expect(first.type, 'movie');
      expect(first.requestedBy?.id, 7);
      expect(first.createdAt, '2026-11-01T10:00:00.000Z');
      expect(first.canRemove, isTrue);
      expect(first.media?.id, 91);
      expect(first.media?.tmdbId, 601);
      expect(first.media?.mediaType, 'movie');
      expect(first.media?.serviceId, 0);
      expect(first.media?.serviceId4k, isNull);

      final second = page.items.last;
      expect(second.is4k, isTrue);
      expect(second.requestedBy?.id, 9);
      expect(second.canRemove, isNull, reason: 'Seerr only adds canRemove for MANAGE_REQUESTS holders');
      expect(second.seasons?.single.seasonNumber, 2);
    });

    test('leaves requester and media type out unless asked, and reports the last page', () async {
      late Uri seen;
      final (:client, updates: _, invalidated: _) = _client(
        MockClient((request) async {
          seen = request.url;
          return _json({
            'pageInfo': {'pages': 1, 'pageSize': 20, 'results': 0, 'page': 1},
            'results': <Object>[],
          });
        }),
      );

      final page = await client.getRequests();

      expect(seen.queryParameters, {'take': '20', 'skip': '0', 'filter': 'all', 'sort': 'added'});
      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
      expect(page.totalResults, 0);
    });

    test('passes a media type filter through', () async {
      late Uri seen;
      final (:client, updates: _, invalidated: _) = _client(
        MockClient((request) async {
          seen = request.url;
          return _json({'pageInfo': <String, Object>{}, 'results': <Object>[]});
        }),
      );
      await client.getRequests(mediaType: 'tv');
      expect(seen.queryParameters['mediaType'], 'tv');
    });
  });

  group('SeerrClient.deleteRequest', () {
    test('DELETEs the request and accepts the empty 204', () async {
      final calls = <String>[];
      final (:client, updates: _, invalidated: _) = _client(
        MockClient((request) async {
          calls.add('${request.method} ${request.url.path}');
          return _noContent();
        }),
      );
      await client.deleteRequest(42);
      expect(calls, ['DELETE /api/v1/request/42']);
    });

    test("the handler's 401 on a live session is a permission denial, with the mask refreshed", () async {
      final calls = <String>[];
      final (:client, :updates, :invalidated) = _client(
        MockClient((request) async {
          calls.add('${request.method} ${request.url.path}');
          return switch (request.url.path) {
            '/api/v1/request/42' => _json({
              'message': 'You do not have permission to delete this request.',
            }, status: 401),
            '/api/v1/auth/me' => _json({'id': 7, 'displayName': 'Alice', 'permissions': SeerrPermission.request}),
            _ => fail('unexpected ${request.url.path}'),
          };
        }),
      );

      await expectLater(
        client.deleteRequest(42),
        throwsA(
          isA<SeerrPermissionException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.display, 'display', t.seerr.permissionDenied),
        ),
      );
      expect(calls, ['DELETE /api/v1/request/42', 'GET /api/v1/auth/me']);
      expect(client.session.permissions, SeerrPermission.request, reason: 'the probe carries the current mask');
      expect(updates.single.permissions, SeerrPermission.request);
      expect(invalidated, isEmpty, reason: 'a denial never unlinks the session');
    });

    test('a 401 from something in front of Seerr stays a proxy failure', () async {
      final (:client, updates: _, :invalidated) = _client(
        MockClient((request) async => _json({'message': 'Unauthorized'}, status: 401)),
      );
      await expectLater(client.deleteRequest(42), throwsA(isA<SeerrProxyException>()));
      expect(invalidated, isEmpty);
    });

    test('a request that is already gone surfaces Seerr\'s 404', () async {
      final (:client, updates: _, invalidated: _) = _client(
        MockClient((request) async => _json({'message': 'Request not found.'}, status: 404)),
      );
      await expectLater(
        client.deleteRequest(42),
        throwsA(
          isA<SeerrApiException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.message, 'message', 'Request not found.'),
        ),
      );
    });
  });

  group('SeerrClient media removal', () {
    test('deleteMedia DELETEs the media record', () async {
      final calls = <String>[];
      final (:client, updates: _, invalidated: _) = _client(
        MockClient((request) async {
          calls.add('${request.method} ${request.url.path}?${request.url.query}');
          return _noContent();
        }),
      );
      await client.deleteMedia(5);
      expect(calls, ['DELETE /api/v1/media/5?']);
    });

    test('deleteMediaFile names the variant in is4k', () async {
      final calls = <String>[];
      final (:client, updates: _, invalidated: _) = _client(
        MockClient((request) async {
          calls.add('${request.method} ${request.url.path}?${request.url.query}');
          return _noContent();
        }),
      );
      await client.deleteMediaFile(5, is4k: false);
      await client.deleteMediaFile(5, is4k: true);
      expect(calls, ['DELETE /api/v1/media/5/file?is4k=false', 'DELETE /api/v1/media/5/file?is4k=true']);
    });

    test('a middleware 403 on a live session is a permission denial, never replayed', () async {
      final calls = <String>[];
      final (:client, :updates, :invalidated) = _client(
        MockClient((request) async {
          calls.add('${request.method} ${request.url.path}');
          return switch (request.url.path) {
            '/api/v1/media/5/file' => _middlewareDenied(),
            '/api/v1/auth/me' => _json({'id': 7, 'displayName': 'Alice', 'permissions': SeerrPermission.request}),
            _ => fail('unexpected ${request.url.path}'),
          };
        }),
      );

      await expectLater(
        client.deleteMediaFile(5, is4k: false),
        throwsA(isA<SeerrPermissionException>().having((e) => e.display, 'display', t.seerr.permissionDenied)),
      );
      expect(calls, [
        'DELETE /api/v1/media/5/file',
        'GET /api/v1/auth/me',
      ], reason: 'a destructive call is not retried');
      expect(updates.single.permissions, SeerrPermission.request);
      expect(invalidated, isEmpty);
    });

    test('a handler-shaped 403 is a permission denial too', () async {
      final (:client, updates: _, invalidated: _) = _client(
        MockClient(
          (request) async => switch (request.url.path) {
            '/api/v1/media/5' => _json({'message': 'Forbidden'}, status: 403),
            '/api/v1/auth/me' => _json({'id': 7, 'displayName': 'Alice', 'permissions': 0}),
            _ => fail('unexpected ${request.url.path}'),
          },
        ),
      );
      await expectLater(client.deleteMedia(5), throwsA(isA<SeerrPermissionException>()));
    });

    test('no configured Sonarr/Radarr instance surfaces Seerr\'s 409 message', () async {
      final (:client, updates: _, invalidated: _) = _client(
        MockClient(
          (request) async => _json({'message': 'No 4K Radarr server configured to delete media files'}, status: 409),
        ),
      );
      await expectLater(
        client.deleteMediaFile(5, is4k: true),
        throwsA(
          isA<SeerrApiException>()
              .having((e) => e.statusCode, 'statusCode', 409)
              .having((e) => e.message, 'message', 'No 4K Radarr server configured to delete media files'),
        ),
      );
    });
  });

  test('MANAGE_REQUESTS is bit 16 and admin implies it', () {
    expect(SeerrPermission.manageRequests, 16);
    expect(seerrHasPermission(SeerrPermission.manageRequests, [SeerrPermission.manageRequests]), isTrue);
    expect(seerrHasPermission(SeerrPermission.admin, [SeerrPermission.manageRequests]), isTrue);
    expect(seerrHasPermission(SeerrPermission.request, [SeerrPermission.manageRequests]), isFalse);
  });
}
