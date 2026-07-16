import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/media/media_backend.dart';

import 'package:plezy/media/media_kind.dart';
import 'package:plezy/metadata_edit/jellyfin_metadata_edit_adapter.dart';
import 'package:plezy/metadata_edit/metadata_edit_models.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/utils/media_image_helper.dart';
import '../test_helpers/media_items.dart';

void main() {
  test('load fails when the full editable Jellyfin DTO is unavailable', () async {
    final client = JellyfinClient.forTesting(
      connection: _connection(),
      httpClient: MockClient((request) async => http.Response('', 404)),
    );
    addTearDown(client.close);

    final adapter = JellyfinMetadataEditAdapter(client);
    final item = testMediaItem(
      id: 'item-1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.movie,
      raw: {'Id': 'item-1', 'Name': 'Sparse browse row'},
    );

    expect(adapter.load(item), throwsA(isA<StateError>()));
  });

  test('episode poster artwork uses 16:9 thumbnail geometry', () async {
    final client = JellyfinClient.forTesting(
      connection: _connection(),
      httpClient: MockClient((request) async => http.Response('', 500)),
    );
    addTearDown(client.close);
    final adapter = JellyfinMetadataEditAdapter(client);

    MetadataArtworkConfig posterConfig(MediaKind kind) {
      final item = testMediaItem(id: 'item-1', backend: MediaBackend.jellyfin, kind: kind);
      final draft = MetadataEditDraft(sourceItem: item, currentItem: item, values: {});
      final artwork = adapter.buildSchema(draft).singleWhere((section) => section.id == 'artwork');
      return artwork.fields.singleWhere((field) => field.id == 'artwork:Primary').artwork!;
    }

    final episode = posterConfig(MediaKind.episode);
    expect(episode.gridAspectRatio, 16 / 9);
    expect(episode.imageType, ImageType.thumb);
    expect(episode.gridColumns, 2);

    final movie = posterConfig(MediaKind.movie);
    expect(movie.gridAspectRatio, 2 / 3);
    expect(movie.imageType, ImageType.poster);
  });

  test('save preserves unchanged Jellyfin people and studio identity data', () async {
    String? capturedBody;
    final client = JellyfinClient.forTesting(
      connection: _connection(),
      httpClient: MockClient((request) async {
        if (request.url.path == '/Users/user-1/Items/item-1') {
          return http.Response(jsonEncode(_editableMovie()), 200, headers: {'content-type': 'application/json'});
        }
        if (request.url.path == '/Items/item-1') {
          capturedBody = request.body;
          return http.Response('', 204);
        }
        return http.Response('unexpected ${request.url}', 500);
      }),
    );
    addTearDown(client.close);

    final adapter = JellyfinMetadataEditAdapter(client);
    final item = testMediaItem(id: 'item-1', backend: MediaBackend.jellyfin, kind: MediaKind.movie);
    final draft = await adapter.load(item);

    draft.setValue('director', ['Alice', 'Charlie']);
    draft.setValue('studio', ['Studio A', 'Studio C']);
    draft.setValue('tagline', 'Updated tagline');

    final success = await adapter.save(draft);

    expect(success, isTrue);
    final body = jsonDecode(capturedBody!) as Map<String, dynamic>;

    final people = (body['People'] as List).cast<Map<String, dynamic>>();
    expect(people.any((person) => person['Name'] == 'Bob'), isFalse);
    expect(_byName(people, 'Alice'), containsPair('Id', 'person-alice'));
    expect(_byName(people, 'Alice'), containsPair('PrimaryImageTag', 'alice-tag'));
    expect(_byName(people, 'Alice'), containsPair('ProviderIds', {'Imdb': 'nm1'}));
    expect(_byName(people, 'Charlie'), {'Name': 'Charlie', 'Type': 'Director'});
    expect(_byName(people, 'Actor One'), containsPair('Id', 'actor-1'));
    expect(_byName(people, 'Wendy'), containsPair('Id', 'person-wendy'));

    final studios = (body['Studios'] as List).cast<Map<String, dynamic>>();
    expect(studios.any((studio) => studio['Name'] == 'Studio B'), isFalse);
    expect(_byName(studios, 'Studio A'), containsPair('Id', 'studio-a'));
    expect(_byName(studios, 'Studio C'), {'Name': 'Studio C'});

    expect(body['Taglines'], ['Updated tagline', 'Second tagline']);
  });
}

JellyfinConnection _connection() {
  return JellyfinConnection(
    id: 'srv-1/user-1',
    baseUrl: 'https://jf.example.com',
    serverName: 'Home',
    serverMachineId: 'srv-1',
    userId: 'user-1',
    userName: 'edde',
    accessToken: 'tok',
    deviceId: 'dev',
    isAdministrator: true,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );
}

Map<String, dynamic> _editableMovie() {
  return {
    'Id': 'item-1',
    'Name': 'Movie',
    'Type': 'Movie',
    'ProviderIds': {'Tmdb': '123'},
    'Tags': ['Favorite'],
    'Genres': ['Drama'],
    'Studios': [
      {'Name': 'Studio A', 'Id': 'studio-a'},
      {'Name': 'Studio B', 'Id': 'studio-b'},
    ],
    'People': [
      {
        'Name': 'Alice',
        'Type': 'Director',
        'Id': 'person-alice',
        'PrimaryImageTag': 'alice-tag',
        'ProviderIds': {'Imdb': 'nm1'},
      },
      {'Name': 'Bob', 'Type': 'Director', 'Id': 'person-bob'},
      {'Name': 'Wendy', 'Type': 'Writer', 'Id': 'person-wendy'},
      {'Name': 'Actor One', 'Type': 'Actor', 'Role': 'Hero', 'Id': 'actor-1'},
    ],
    'ProductionLocations': ['US'],
    'Taglines': ['Original tagline', 'Second tagline'],
    'LockedFields': ['Overview'],
    'LockData': true,
    'PremiereDate': '2020-01-01T00:00:00.0000000Z',
    'Trickplay': {'1': {}},
  };
}

Map<String, dynamic> _byName(List<Map<String, dynamic>> values, String name) {
  return values.singleWhere((value) => value['Name'] == name);
}
