import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/utils/media_server_timeouts.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/http_fixtures.dart';
import '../test_helpers/media_items.dart';

/// `CanDelete` is what the server itself checks before honouring
/// `DELETE /Items/{id}` (`BaseItem.CanDelete(user)`), so it folds the global
/// `EnableContentDeletion` grant, the per-library grant, and item state. The
/// client must report it verbatim and never invent an answer.
void main() {
  final item = testMediaItem(
    id: 'movie-1',
    backend: MediaBackend.jellyfin,
    kind: MediaKind.movie,
    title: 'Movie',
    serverId: 'srv-1',
  );

  ({JellyfinClient client, List<Uri> requests}) clientAnswering(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    final requests = <Uri>[];
    final client = JellyfinClient.forTesting(
      connection: testJellyfinConnection(),
      httpClient: MockClient((request) async {
        requests.add(request.url);
        return handler(request);
      }),
    );
    addTearDown(client.close);
    return (client: client, requests: requests);
  }

  group('JellyfinClient.fetchDeletePermission', () {
    test('asks the list endpoint for CanDelete only, scoped to the item and user', () async {
      final fake = clientAnswering(
        (_) async => jsonResponse({
          'Items': [
            {'Id': 'movie-1', 'CanDelete': true},
          ],
        }),
      );

      await (fake.client as MediaDeletionPermissionClient).fetchDeletePermission(item);

      final uri = fake.requests.single;
      // `/Items?ids=` and not `/Users/{id}/Items/{id}`: the single-item route
      // ignores `Fields` and ships the whole dto.
      expect(uri.path, '/Items');
      expect(uri.queryParameters['ids'], 'movie-1');
      expect(uri.queryParameters['userId'], 'user-1');
      expect(uri.queryParameters['Fields'], 'CanDelete');
      expect(uri.queryParameters['EnableImages'], 'false');
      expect(uri.queryParameters['EnableUserData'], 'false');
    });

    test('reports the server answer for a permitted and a rejected item', () async {
      final permitted = clientAnswering(
        (_) async => jsonResponse({
          'Items': [
            {'Id': 'movie-1', 'CanDelete': true},
          ],
        }),
      );
      final rejected = clientAnswering(
        (_) async => jsonResponse({
          'Items': [
            {'Id': 'movie-1', 'CanDelete': false},
          ],
        }),
      );

      expect(await (permitted.client as MediaDeletionPermissionClient).fetchDeletePermission(item), isTrue);
      expect(await (rejected.client as MediaDeletionPermissionClient).fetchDeletePermission(item), isFalse);
    });

    test('treats an item the user cannot see as not deletable', () async {
      final fake = clientAnswering((_) async => jsonResponse({'Items': <Object>[]}));

      expect(await (fake.client as MediaDeletionPermissionClient).fetchDeletePermission(item), isFalse);
    });

    test('returns null when the server omits CanDelete', () async {
      // Old servers, or a future one that stops honouring the field: unknown is
      // not "allowed", and the caller fails closed on null.
      final fake = clientAnswering(
        (_) async => jsonResponse({
          'Items': [
            {'Id': 'movie-1'},
          ],
        }),
      );

      expect(await (fake.client as MediaDeletionPermissionClient).fetchDeletePermission(item), isNull);
    });

    test('throws on an error response instead of reporting a permission', () async {
      final fake = clientAnswering((_) async => http.Response('nope', 401));

      await expectLater(
        (fake.client as MediaDeletionPermissionClient).fetchDeletePermission(item),
        throwsA(isA<MediaServerHttpException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('gives up on a server that never answers', () {
      fakeAsync((async) {
        final client = JellyfinClient.forTesting(
          connection: testJellyfinConnection(),
          httpClient: MockClient((_) => Completer<http.Response>().future),
        );
        addTearDown(client.close);

        final failure = _failureOf(client, item);

        async.elapse(MediaServerTimeouts.jellyfinDeletePermission - const Duration(milliseconds: 1));
        expect(failure(), isNull);

        async.elapse(const Duration(milliseconds: 2));
        expect(failure(), _isProbeTimeout);
      });
    });

    test('caps a slow connect followed by a stalled body at the whole-probe deadline', () {
      // The regression this guards: the client applies its per-request budget
      // to the connect and the receive phase separately, so a server that
      // answers late and then stops sending would hold the context menu for
      // roughly twice the budget without the caller-side deadline.
      fakeAsync((async) {
        final body = StreamController<List<int>>();
        addTearDown(body.close);
        final client = JellyfinClient.forTesting(
          connection: testJellyfinConnection(),
          httpClient: MockClient.streaming((_, _) async {
            await Future<void>.delayed(MediaServerTimeouts.jellyfinDeletePermission - const Duration(seconds: 1));
            return http.StreamedResponse(body.stream, 200, headers: const {'content-type': 'application/json'});
          }),
        );
        addTearDown(client.close);

        final failure = _failureOf(client, item);

        async.elapse(MediaServerTimeouts.jellyfinDeletePermission - const Duration(milliseconds: 1));
        expect(failure(), isNull, reason: 'the response arrived in time; only the body is stalled');

        async.elapse(const Duration(milliseconds: 2));
        expect(failure(), _isProbeTimeout);
        expect(async.elapsed, lessThan(MediaServerTimeouts.jellyfinDeletePermission * 2));
      });
    });
  });
}

/// Starts the probe and hands back a getter for whatever it failed with, so a
/// [fakeAsync] body can advance the clock and inspect the outcome without
/// awaiting inside the zone.
Object? Function() _failureOf(JellyfinClient client, MediaItem item) {
  Object? failure;
  (client as MediaDeletionPermissionClient)
      .fetchDeletePermission(item)
      .then<void>(
        (_) {},
        onError: (Object e) {
          failure = e;
        },
      );
  return () => failure;
}

/// Both stalls must surface as the canonical media-server failure, the same
/// shape `MediaServerHttpClient` raises for its own per-phase expiries, so
/// callers need one catch and not two.
final _isProbeTimeout = isA<MediaServerHttpException>().having(
  (e) => e.type,
  'type',
  MediaServerHttpErrorType.connectionTimeout,
);
