import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/lending/lending_service.dart';
import 'package:plezy/sources/source_database.dart';
import 'package:plezy/sources/source_models.dart';
import 'package:plezy/sources/source_transport.dart';

void main() {
  late SourceDatabase database;
  late SourceRepository repository;
  const library = LendingLibrary(
    id: 'card-a',
    provider: LendingProvider.overdrive,
    name: 'Library',
    home: 'https://library.example',
    gateway: 'https://signin.example',
    remoteId: 'local',
    integration: true,
    circulation: true,
  );
  setUp(() {
    database = SourceDatabase(NativeDatabase.memory());
    repository = SourceRepository(
      database,
      protect: (s) async => base64Encode(utf8.encode(s)),
      reveal: (s) async => utf8.decode(base64Decode(s)),
    );
  });
  tearDown(() => database.close());
  Future<void> token({String profile = 'alice', int? expiry}) =>
      repository.savePrivatePreference(profile, 'lending:token:card-a', {
        'access_token': 'patron-secret',
        'refresh_token': 'refresh-secret',
        'refreshProof': 'server-proof',
        'expiresAt': expiry ?? DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
      });
  test('OverDrive ships disabled and makes no native request', () async {
    expect(LendingService.overdriveEnabled, isFalse);
    final service = LendingService(
      repository,
      'alice',
      valid: () => true,
      transport: SourceTransport(client: MockClient((_) async => throw StateError('must not request'))),
    );
    await expectLater(service.gatewayLibraries(library.gateway), throwsA(isA<SourceException>()));
    service.close();
  });
  test('personal authorization stays encrypted and profile scoped', () async {
    await token();
    final row = await database.customSelect('SELECT payload FROM preferences').getSingle();
    expect(row.read<String>('payload'), isNot(contains('patron-secret')));
    final alice = LendingService(repository, 'alice', valid: () => true);
    final bob = LendingService(repository, 'bob', valid: () => true);
    expect(await alice.connected(library), isTrue);
    expect(await bob.connected(library), isFalse);
    await alice.save(library);
    await alice.remove(library);
    expect(await alice.connected(library), isFalse);
    alice.close();
    bob.close();
  });
  test('catalogue uses the current patron collection including Advantage', () async {
    await token();
    final requests = <http.Request>[];
    final service = LendingService(
      repository,
      'alice',
      valid: () => true,
      enableOverdrive: true,
      transport: SourceTransport(
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/v1/patrons/me') {
            return http.Response(
              jsonEncode({
                'linkTemplates': {
                  'search': {
                    'href': 'https://integration.api.overdrive.com/v1/collections/advantage/products/?q={keyword}',
                  },
                },
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'totalItems': 31,
              'products': [
                {
                  'id': 'book',
                  'title': 'A book',
                  'primaryCreator': {'name': 'Author'},
                },
              ],
            }),
            200,
          );
        }),
      ),
    );
    final page = await service.search(library, 'a & b');
    expect(requests.last.url.path, contains('/advantage/'));
    expect(requests.last.url.queryParameters['q'], 'a & b');
    expect(requests.last.headers['Authorization'], 'Bearer patron-secret');
    expect(page.more, isTrue);
    expect(page.books.single.author, 'Author');
    service.close();
  });
  test('provider hypermedia cannot exfiltrate a patron token', () async {
    await token();
    var calls = 0;
    final service = LendingService(
      repository,
      'alice',
      valid: () => true,
      enableOverdrive: true,
      transport: SourceTransport(
        client: MockClient((_) async {
          calls++;
          return http.Response(
            jsonEncode({
              'linkTemplates': {
                'search': {'href': 'https://attacker.example/v1/products?q={keyword}'},
              },
            }),
            200,
          );
        }),
      ),
    );
    await expectLater(service.search(library, 'book'), throwsA(isA<SourceException>()));
    expect(calls, 1);
    service.close();
  });
  test('borrowing and holds use distinct explicit provider actions', () async {
    await token();
    final requests = <http.Request>[];
    final service = LendingService(
      repository,
      'alice',
      valid: () => true,
      enableOverdrive: true,
      transport: SourceTransport(
        client: MockClient((request) async {
          requests.add(request);
          return http.Response('{}', 201);
        }),
      ),
    );
    const book = LendingBook(id: 'reserve-1', title: 'A book');
    await service.borrow(library, book);
    expect(requests.single.method, 'POST');
    expect(requests.single.url.path, endsWith('/checkouts'));
    expect(jsonDecode(requests.single.body), {
      'fields': [
        {'name': 'id', 'value': 'reserve-1'},
      ],
    });
    await service.borrow(library, book, holdEmail: 'patron@example.com');
    expect(requests.last.url.path, endsWith('/holds'));
    expect(requests.last.body, contains('emailAddress'));
    service.close();
  });
  test('expired authorization refreshes through gateway and rotates stored token', () async {
    await token(expiry: 0);
    final service = LendingService(
      repository,
      'alice',
      valid: () => true,
      enableOverdrive: true,
      transport: SourceTransport(
        client: MockClient((request) async {
          if (request.url.host == 'signin.example') {
            expect(request.url.path, '/v1/refresh');
            expect(request.headers['Authorization'], isNull);
            expect(jsonDecode(request.body)['refreshProof'], 'server-proof');
            return http.Response(
              jsonEncode({
                'access_token': 'new-token',
                'refresh_token': 'new-refresh',
                'refreshProof': 'new-proof',
                'expires_in': 3600,
              }),
              200,
            );
          }
          expect(request.headers['Authorization'], 'Bearer new-token');
          return http.Response('{"checkouts":[]}', 200);
        }),
      ),
    );
    expect((await service.shelf(library, holds: false)).books, isEmpty);
    final stored = await repository.privatePreference('alice', 'lending:token:card-a');
    expect(stored['refresh_token'], 'new-refresh');
    service.close();
  });
  test('fulfillment hands off one-use URL without authorization headers or persistence', () async {
    await token();
    Uri? opened;
    final service = LendingService(
      repository,
      'alice',
      valid: () => true,
      enableOverdrive: true,
      launch: (uri) async {
        opened = uri;
        return true;
      },
      transport: SourceTransport(
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer patron-secret');
          return http.Response(
            '',
            302,
            headers: {'location': 'https://library.overdrive.com/fulfillment/book?code=one-use'},
          );
        }),
      ),
    );
    const book = LendingBook(
      id: 'book',
      title: 'Book',
      loan: true,
      data: {
        'links': {
          'downloadRedirect': {
            'href':
                'https://integration-patron.api.overdrive.com/v1/patrons/me/checkouts/book/formats/downloadRedirect',
          },
        },
      },
    );
    await service.fulfill(library, book);
    expect(opened!.queryParameters['code'], 'one-use');
    expect((await repository.privatePreference('alice', 'lending:token:card-a')).values, isNot(contains('one-use')));
    service.close();
  });
  test('stale profile cannot launch a service or write preferences', () async {
    var active = true;
    final service = LendingService(
      repository,
      'alice',
      valid: () => active,
      launch: (_) async => throw StateError('must not open'),
    );
    active = false;
    await expectLater(service.openPage(Uri.parse(library.home)), throwsA(isA<SourceException>()));
    await repository.forgetProfile('alice');
    await expectLater(
      repository.savePrivatePreference('alice', 'lending:token:card-a', {'token': 'late'}),
      throwsA(isA<SourceException>()),
    );
    service.close();
  });
}
