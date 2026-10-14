import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/services/catalog/plex_catalog_source.dart';
import 'package:plezy/services/jellyfin_mappers.dart';
import 'package:plezy/services/plex_discover_client.dart';
import 'package:plezy/services/plex_mappers.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/http_fixtures.dart';

const _session = PlexDiscoverSession(accessToken: 'profile-token', clientIdentifier: 'client-id');

void main() {
  group('Plex person details', () {
    test('a cast role keeps the plex.tv person key', () {
      final role = PlexMappers.role(
        PlexRoleDto.fromJson({
          'id': 49,
          'tag': 'John Garfield',
          'tagKey': '5d77682aeb5d26001f1de4b0',
          'role': 'Frank Chambers',
        }),
      );

      expect(role.id, '49');
      expect(role.tagKey, '5d77682aeb5d26001f1de4b0');
    });

    test('a cast role without a plex.tv match has no person key', () {
      final role = PlexMappers.role(PlexRoleDto.fromJson({'id': 50, 'tag': 'Extra', 'tagKey': ''}));

      expect(role.tagKey, isNull);
    });

    test('a people search hit keeps the plex.tv person key', () {
      final person = PlexMappers.personFromSearchResultJson({
        'type': 'tag',
        'tagType': 6,
        'id': 49,
        'tag': 'John Garfield',
        'tagKey': '5d77682aeb5d26001f1de4b0',
      }, serverId: ServerId('plex-1'));

      expect(person?.tagKey, '5d77682aeb5d26001f1de4b0');
    });

    test('maps the Discover person record', () {
      final details = PlexMappers.personDetails({
        'title': 'John Garfield',
        'summary': ' An American actor. ',
        'bornAt': '1913-03-04',
        'diedAt': '1952-05-21',
        'birthPlace': 'Manhattan, New York City, New York, USA',
      });

      expect(details?.overview, 'An American actor.');
      expect(details?.birthDate, '1913-03-04');
      expect(details?.deathDate, '1952-05-21');
      expect(details?.birthPlace, 'Manhattan, New York City, New York, USA');
    });

    test('a record with no details maps to null', () {
      expect(PlexMappers.personDetails({'title': 'Someone', 'summary': ''}), isNull);
      expect(PlexMappers.personDetails(null), isNull);
    });

    test('fetches the person from Discover by their plex.tv key', () async {
      late http.Request captured;
      final source = PlexCatalogSource(
        PlexDiscoverClient(
          _session,
          httpClient: MockClient((request) async {
            captured = request;
            return jsonResponse({
              'MediaContainer': {
                'size': 1,
                'Metadata': [
                  {'title': 'John Garfield', 'summary': 'Bio', 'bornAt': '1913-03-04'},
                ],
              },
            });
          }),
        ),
      );

      final details = await source.fetchPersonDetails('5d77682aeb5d26001f1de4b0');

      expect(captured.url.host, 'discover.provider.plex.tv');
      expect(captured.url.path, '/library/people/5d77682aeb5d26001f1de4b0');
      expect(captured.headers['X-Plex-Token'], 'profile-token');
      expect(captured.headers['Accept'], 'application/json');
      expect(details?.overview, 'Bio');
      expect(details?.birthDate, '1913-03-04');
    });

    test('a person plex.tv does not know has no details', () async {
      final source = PlexCatalogSource(
        PlexDiscoverClient(
          _session,
          httpClient: MockClient(
            (_) async => jsonResponse({
              'MediaContainer': {'size': 0, 'totalSize': 0},
            }),
          ),
        ),
      );

      expect(await source.fetchPersonDetails('unknown'), isNull);
    });
  });

  group('Jellyfin person details', () {
    test('maps overview, dates and birthplace from the person item', () {
      final details = JellyfinMappers.personDetails({
        'Id': 'person-1',
        'Name': 'Glenn Ford',
        'Type': 'Person',
        'Overview': 'A Canadian-born American actor.',
        'PremiereDate': '1916-04-30T23:00:00.0000000Z',
        'EndDate': '2006-08-29T22:00:00.0000000Z',
        'ProductionLocations': [' Quebec City, Quebec, Canada '],
      });

      expect(details?.overview, 'A Canadian-born American actor.');
      expect(details?.birthDate, _localYmd(DateTime.utc(1916, 4, 30, 23)));
      expect(details?.deathDate, _localYmd(DateTime.utc(2006, 8, 29, 22)));
      expect(details?.birthPlace, 'Quebec City, Quebec, Canada');
    });

    test('reads person dates in local time, as jellyfin-web does', () {
      final details = JellyfinMappers.personDetails({'PremiereDate': '1916-04-30T23:00:00.0000000Z'});
      final local = DateTime.utc(1916, 4, 30, 23).toLocal();

      expect(details?.birthDate, _localYmd(local));
      if (local.timeZoneOffset == const Duration(hours: 1)) expect(details?.birthDate, '1916-05-01');
      if (local.timeZoneOffset == Duration.zero) expect(details?.birthDate, '1916-04-30');
    });

    test('a date without a zone is taken as written', () {
      final details = JellyfinMappers.personDetails({'PremiereDate': '1916-05-01T00:00:00'});

      expect(details?.birthDate, '1916-05-01');
    });

    test('a person without metadata maps to null', () {
      expect(JellyfinMappers.personDetails({'Id': 'person-1', 'Name': 'Someone', 'ProductionLocations': []}), isNull);
    });

    test('fetches the person item for the signed-in user', () async {
      late http.Request captured;
      final client = testJellyfinClient(
        handler: (request) async {
          captured = request;
          return jsonResponse({'Id': 'person-1', 'Name': 'John Garfield', 'Overview': 'Bio'});
        },
      );

      final details = await client.fetchPersonDetails('person-1');

      expect(captured.url.path, '/Users/user-1/Items/person-1');
      expect(captured.url.queryParameters['Fields'], 'Overview,ProductionLocations');
      expect(details?.overview, 'Bio');
    });

    test('a person the server does not have has no details', () async {
      final client = testJellyfinClient(handler: (_) async => http.Response('not found', 404));

      expect(await client.fetchPersonDetails('missing'), isNull);
    });

    test('a server error surfaces to the caller', () async {
      final client = testJellyfinClient(handler: (_) async => http.Response('boom', 500));

      await expectLater(client.fetchPersonDetails('person-1'), throwsA(anything));
    });
  });
}

String _localYmd(DateTime instant) {
  final local = instant.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
