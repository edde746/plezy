import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/models/livetv_channel.dart';
import 'package:plezy/services/favorite_channels_repository.dart';
import 'package:plezy/services/jellyfin_client.dart';

import '../test_helpers/backend_client_fixtures.dart';

FavoriteChannel _favorite(String id, {String? title}) =>
    FavoriteChannel(id: id, title: title ?? id, source: 'server://test-server/jellyfin');

JellyfinClient _client(
  _MemoryFavoriteChannelsRepository repository,
  Future<http.Response> Function(http.Request request) handler,
) => JellyfinClient.forTesting(
  connection: testJellyfinConnection(machineId: 'test-server', userId: 'test-user'),
  httpClient: MockClient(handler),
  favoritesRepository: repository,
);

String _mutationId(http.Request request) => request.url.pathSegments.last;

void main() {
  test('mixed outcomes persist confirmed projection and retry only unconfirmed differences', () async {
    final repository = _MemoryFavoriteChannelsRepository([
      _favorite('keep', title: 'Old keep'),
      _favorite('remove-ok'),
      _favorite('remove-fail'),
    ]);
    final attempts = <String>[];
    var failingIds = {'add-fail', 'remove-fail'};
    final client = _client(repository, (request) async {
      final id = _mutationId(request);
      attempts.add('${request.method}:$id');
      return http.Response('', failingIds.contains(id) ? 400 : 204);
    });
    addTearDown(client.close);
    final desired = [
      _favorite('keep', title: 'Updated keep'),
      _favorite('add-ok', title: 'Added'),
      _favorite('add-fail'),
    ];

    await expectLater(
      client.liveTv.setFavoriteChannels(desired),
      throwsA(isA<MediaServerHttpException>().having((error) => error.statusCode, 'statusCode', 400)),
    );

    expect(attempts, ['POST:add-ok', 'POST:add-fail', 'DELETE:remove-ok', 'DELETE:remove-fail']);
    expect(repository.writeCount, 1);
    expect(repository.current.map((channel) => channel.id), ['keep', 'add-ok', 'remove-fail']);
    expect(repository.current.first.title, 'Updated keep');

    attempts.clear();
    failingIds = {};
    await client.liveTv.setFavoriteChannels(desired);

    expect(attempts, ['POST:add-fail', 'DELETE:remove-fail']);
    expect(repository.writeCount, 2);
    expect(repository.current.map((channel) => channel.id), ['keep', 'add-ok', 'add-fail']);
  });

  test('a rejected single addition retains the empty baseline and throws', () async {
    final repository = _MemoryFavoriteChannelsRepository(const []);
    var attempts = 0;
    final client = _client(repository, (request) async {
      attempts++;
      return http.Response('', 409);
    });
    addTearDown(client.close);

    await expectLater(client.liveTv.setFavoriteChannels([_favorite('add')]), throwsA(isA<MediaServerHttpException>()));

    expect(attempts, 1);
    expect(repository.current, isEmpty);
  });

  test('a rejected single removal retains the prior favorite and throws', () async {
    final repository = _MemoryFavoriteChannelsRepository([_favorite('remove')]);
    var attempts = 0;
    final client = _client(repository, (request) async {
      attempts++;
      return http.Response('', 409);
    });
    addTearDown(client.close);

    await expectLater(client.liveTv.setFavoriteChannels(const []), throwsA(isA<MediaServerHttpException>()));

    expect(attempts, 1);
    expect(repository.current.map((channel) => channel.id), ['remove']);
  });

  test('successful writes preserve requested order and metadata without redundant reorder requests', () async {
    final repository = _MemoryFavoriteChannelsRepository([_favorite('first'), _favorite('second')]);
    final attempts = <String>[];
    final client = _client(repository, (request) async {
      attempts.add('${request.method}:${_mutationId(request)}');
      return http.Response('', 204);
    });
    addTearDown(client.close);

    await client.liveTv.setFavoriteChannels([
      _favorite('second', title: 'Second updated'),
      _favorite('third', title: 'Third added'),
      _favorite('first', title: 'First updated'),
    ]);
    expect(attempts, ['POST:third']);
    expect(repository.current.map((channel) => channel.id), ['second', 'third', 'first']);
    expect(repository.current.map((channel) => channel.title), ['Second updated', 'Third added', 'First updated']);

    attempts.clear();
    await client.liveTv.setFavoriteChannels([
      _favorite('first', title: 'First newest'),
      _favorite('second', title: 'Second newest'),
      _favorite('third', title: 'Third newest'),
    ]);
    expect(attempts, isEmpty);
    expect(repository.current.map((channel) => channel.id), ['first', 'second', 'third']);
    expect(repository.current.map((channel) => channel.title), ['First newest', 'Second newest', 'Third newest']);
  });

  test('baseline read failure aborts before HTTP mutation and persistence', () async {
    final failure = StateError('baseline unavailable');
    final repository = _MemoryFavoriteChannelsRepository(const [], readError: failure);
    var attempts = 0;
    final client = _client(repository, (request) async {
      attempts++;
      return http.Response('', 204);
    });
    addTearDown(client.close);

    await expectLater(client.liveTv.setFavoriteChannels([_favorite('add')]), throwsA(same(failure)));

    expect(attempts, 0);
    expect(repository.writeAttempts, 0);
  });

  test('durable write failure takes precedence over completed server mutations', () async {
    final failure = StateError('durable write unavailable');
    final repository = _MemoryFavoriteChannelsRepository(const [], writeError: failure);
    var attempts = 0;
    final client = _client(repository, (request) async {
      attempts++;
      return http.Response('', 204);
    });
    addTearDown(client.close);

    await expectLater(client.liveTv.setFavoriteChannels([_favorite('add')]), throwsA(same(failure)));

    expect(attempts, 1);
    expect(repository.writeAttempts, 1);
    expect(repository.current, isEmpty);
  });

  test('ambiguous timeout retains prior state, stays typed, and retries the absolute intent', () async {
    final repository = _MemoryFavoriteChannelsRepository(const []);
    var attempts = 0;
    var shouldTimeout = true;
    final client = _client(repository, (request) async {
      attempts++;
      if (shouldTimeout) throw TimeoutException('request timed out');
      return http.Response('', 204);
    });
    addTearDown(client.close);
    final desired = [_favorite('add')];

    await expectLater(
      client.liveTv.setFavoriteChannels(desired),
      throwsA(
        isA<MediaServerHttpException>().having(
          (error) => error.type,
          'type',
          MediaServerHttpErrorType.connectionTimeout,
        ),
      ),
    );
    expect(repository.current, isEmpty);

    shouldTimeout = false;
    await client.liveTv.setFavoriteChannels(desired);

    expect(attempts, 2);
    expect(repository.current.map((channel) => channel.id), ['add']);
  });
}

class _MemoryFavoriteChannelsRepository implements FavoriteChannelsRepository {
  _MemoryFavoriteChannelsRepository(List<FavoriteChannel> initial, {this.readError, this.writeError})
    : current = List.of(initial);

  List<FavoriteChannel> current;
  final Object? readError;
  final Object? writeError;
  int writeAttempts = 0;
  int writeCount = 0;

  @override
  Future<List<FavoriteChannel>> read({required String key, required String legacyKey}) async {
    if (readError case final error?) throw error;
    return List.of(current);
  }

  @override
  Future<void> write(String key, List<FavoriteChannel> channels) async {
    writeAttempts++;
    if (writeError case final error?) throw error;
    current = List.of(channels);
    writeCount++;
  }
}
