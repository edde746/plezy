import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/metadata_edit/jellyfin_metadata_edit_adapter.dart';
import 'package:plezy/services/jellyfin_client.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/http_fixtures.dart';
import '../test_helpers/media_items.dart';

void main() {
  test('Emby save mirrors genres and tags into the name-pair arrays', () async {
    final postedBodies = <String>[];
    final client = _clientForDto(connection: testEmbyConnection(), dto: _embyItem(), postedBodies: postedBodies);
    addTearDown(client.close);
    final adapter = JellyfinMetadataEditAdapter(client);
    final draft = await adapter.load(_sourceItem(MediaBackend.emby));

    draft.setValue('genre', ['Adventure', 'Comedy']);
    draft.setValue('label', ['family', 'favorite']);

    expect(await adapter.save(draft), isTrue);
    expect(postedBodies, hasLength(1));
    final body = jsonDecode(postedBodies.single) as Map<String, dynamic>;
    expect(body['GenreItems'], [
      {'Name': 'Adventure'},
      {'Name': 'Comedy'},
    ]);
    expect(body['TagItems'], [
      {'Name': 'family'},
      {'Name': 'favorite'},
    ]);
  });

  test('Jellyfin save does not send the name-pair arrays', () async {
    final postedBodies = <String>[];
    final client = _clientForDto(connection: _jellyfinConnection(), dto: _jellyfinItem(), postedBodies: postedBodies);
    addTearDown(client.close);
    final adapter = JellyfinMetadataEditAdapter(client);
    final draft = await adapter.load(_sourceItem(MediaBackend.jellyfin));

    draft.setValue('genre', ['Adventure', 'Comedy']);
    draft.setValue('label', ['family', 'favorite']);

    expect(await adapter.save(draft), isTrue);
    expect(postedBodies, hasLength(1));
    final body = jsonDecode(postedBodies.single) as Map<String, dynamic>;
    expect(body['Genres'], ['Adventure', 'Comedy']);
    expect(body['Tags'], ['family', 'favorite']);
    expect(body.containsKey('GenreItems'), isFalse);
    expect(body.containsKey('TagItems'), isFalse);
  });

  test("an Emby DTO's tags are read from TagItems", () async {
    final client = _clientForDto(connection: testEmbyConnection(), dto: _embyItem(), postedBodies: <String>[]);
    addTearDown(client.close);
    final adapter = JellyfinMetadataEditAdapter(client);

    final draft = await adapter.load(_sourceItem(MediaBackend.emby));

    expect(draft.values['label'], ['archive']);
    expect(draft.values['genre'], ['Action']);
  });

  test('a save that does not touch tags preserves them', () async {
    final postedBodies = <String>[];
    final client = _clientForDto(connection: testEmbyConnection(), dto: _embyItem(), postedBodies: postedBodies);
    addTearDown(client.close);
    final adapter = JellyfinMetadataEditAdapter(client);
    final draft = await adapter.load(_sourceItem(MediaBackend.emby));

    draft.setValue('summary', 'Updated summary');

    expect(await adapter.save(draft), isTrue);
    expect(postedBodies, hasLength(1));
    final body = jsonDecode(postedBodies.single) as Map<String, dynamic>;
    expect(body['TagItems'], [
      {'Name': 'archive'},
    ]);
  });

  test("the adapter reports the dialect's backend", () {
    final embyClient = _clientForDto(connection: testEmbyConnection(), dto: _embyItem(), postedBodies: <String>[]);
    final jellyfinClient = _clientForDto(
      connection: _jellyfinConnection(),
      dto: _jellyfinItem(),
      postedBodies: <String>[],
    );
    addTearDown(embyClient.close);
    addTearDown(jellyfinClient.close);

    expect(JellyfinMetadataEditAdapter(embyClient).backend, MediaBackend.emby);
    expect(JellyfinMetadataEditAdapter(jellyfinClient).backend, MediaBackend.jellyfin);
  });
}

JellyfinClient _clientForDto({
  required JellyfinConnection connection,
  required Map<String, dynamic> dto,
  required List<String> postedBodies,
}) {
  return JellyfinClient.forTesting(
    connection: connection,
    httpClient: MockClient((request) async {
      if (request.method == 'GET' && request.url.path == '/Users/${connection.userId}/Items/item-1') {
        return jsonResponse(dto);
      }
      if (request.method == 'POST' && request.url.path == '/Items/item-1') {
        postedBodies.add(request.body);
        return http.Response('', 204);
      }
      return http.Response('Unexpected ${request.method} ${request.url}', 500);
    }),
  );
}

JellyfinConnection _jellyfinConnection() {
  return JellyfinConnection(
    id: 'srv-1/user-1',
    baseUrl: 'https://jf.example.com',
    serverName: 'Home',
    serverMachineId: 'srv-1',
    userId: 'user-1',
    userName: 'User',
    accessToken: 'token',
    deviceId: 'device-1',
    isAdministrator: false,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );
}

MediaItem _sourceItem(MediaBackend backend) {
  return testMediaItem(id: 'item-1', backend: backend, kind: MediaKind.movie);
}

Map<String, dynamic> _embyItem() {
  return {
    'Id': 'item-1',
    'Name': 'Movie',
    'Type': 'Movie',
    'Overview': 'Original summary',
    'ProviderIds': <String, String>{},
    'Genres': <String>[],
    'GenreItems': [
      {'Name': 'Action', 'Id': 3},
    ],
    'TagItems': [
      {'Name': 'archive', 'Id': 7},
    ],
  };
}

Map<String, dynamic> _jellyfinItem() {
  return {
    'Id': 'item-1',
    'Name': 'Movie',
    'Type': 'Movie',
    'Overview': 'Original summary',
    'ProviderIds': <String, String>{},
    'Genres': ['Drama'],
    'Tags': ['Favorite'],
  };
}
