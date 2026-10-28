import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/integrations/integration_contracts.dart';
import 'package:plezy/services/hardcover/hardcover_client.dart';
import 'package:plezy/sources/source_models.dart';

http.Response _response(Object value, {int status = 200}) =>
    http.Response(jsonEncode(value), status, headers: const {'content-type': 'application/json'});

void main() {
  group('HardcoverClient', () {
    test('loads the account and paginated library with the token only in Authorization', () async {
      final requests = <http.Request>[];
      final client = HardcoverClient(
        token: ' private-token ',
        client: MockClient((request) async {
          requests.add(request);
          expect(request.url.toString(), 'https://api.hardcover.app/v1/graphql');
          expect(request.headers['authorization'], 'Bearer private-token');
          expect(request.headers['content-type'], 'application/json');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final query = body['query'] as String;
          if (query.contains('HardcoverMe')) {
            return _response({
              'data': {
                'me': [
                  {'id': 7, 'username': 'reader', 'name': 'Reader Name'},
                ],
              },
            });
          }
          expect(query, contains('HardcoverLibrary'));
          expect(body['variables'], {'userId': 7, 'limit': 100, 'offset': 0});
          return _response({
            'data': {
              'user_books': [
                {
                  'id': 12,
                  'book_id': 34,
                  'edition_id': 56,
                  'status_id': 2,
                  'rating': 4.5,
                  'updated_at': '2026-10-27T12:00:00Z',
                  'user_book_status': {'id': 2, 'status': 'Currently Reading', 'slug': 'currently_reading'},
                  'book': {'id': 34, 'title': 'A Good Book'},
                  'edition': {'id': 56, 'isbn_13': '9780306406157', 'pages': 320},
                  'active_reads': [
                    {'id': 78, 'edition_id': 56, 'started_at': '2026-10-01', 'progress_pages': 112},
                  ],
                  'latest_reads': [
                    {'id': 78, 'edition_id': 56, 'started_at': '2026-10-01', 'progress_pages': 112},
                  ],
                },
              ],
            },
          });
        }),
      );

      try {
        final account = await client.account();
        expect(account.id, 7);
        expect(account.displayName, 'Reader Name');
        final library = await client.library(account.id);
        expect(library, hasLength(1));
        expect(library.single.title, 'A Good Book');
        expect(library.single.editionId, 56);
        expect(library.single.editionPages, 320);
        expect(library.single.identifiers['isbn13'], '9780306406157');
        expect(library.single.status?.normalized, 'currently reading currently reading');
        expect(library.single.read?.progressPages, 112);
        expect(requests, hasLength(2));
        expect(requests.every((request) => !request.url.queryParameters.containsKey('token')), isTrue);
      } finally {
        client.dispose();
      }
    });

    test('writes only the requested shelf status/progress values and checks the response identity', () async {
      final mutations = <Map<String, dynamic>>[];
      final client = HardcoverClient(
        token: 'private-token',
        client: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final variables = Map<String, dynamic>.from(body['variables'] as Map);
          mutations.add(variables);
          final query = body['query'] as String;
          if (query.contains('HardcoverUpdateStatus')) {
            return _response({
              'data': {
                'update_user_book': {
                  'id': 1,
                  'error': null,
                  'user_book': {'id': 1, 'status_id': 3},
                },
              },
            });
          }
          return _response({
            'data': {
              'update_user_book_read': {
                'id': 2,
                'error': null,
                'user_book_read': {'id': 2, 'progress_pages': 180},
              },
            },
          });
        }),
      );
      try {
        await client.updateStatus(userBookId: 1, statusId: 3);
        await client.updateReadingProgress(readId: 2, pages: 180);
        expect(mutations, [
          {'id': 1, 'statusId': 3},
          {'id': 2, 'pages': 180},
        ]);
        await expectLater(client.updateReadingProgress(readId: 2, pages: -1), throwsA(isA<SourceException>()));
      } finally {
        client.dispose();
      }
    });

    test('maps HTTP auth failures without exposing the token or response body', () async {
      const secret = 'top-secret-token-value';
      final client = HardcoverClient(
        token: secret,
        client: MockClient((_) async => http.Response('upstream leaked $secret', 401)),
      );
      try {
        Object? failure;
        try {
          await client.account();
        } on Object catch (error) {
          failure = error;
        }
        expect(failure, isA<SourceException>());
        expect('$failure', isNot(contains(secret)));
        expect('$failure', isNot(contains('upstream leaked')));
      } finally {
        client.dispose();
      }
      expect(() => HardcoverClient(token: 'bad\nvalue'), throwsA(isA<SourceException>()));
    });
  });

  group('external access action policy', () {
    const provider = ProviderDefinition(
      id: 'books.example',
      displayName: 'Book Shop',
      officialHosts: {'books.example'},
      affiliateHosts: {'track.example'},
      entityKinds: {IntegrationEntityKind.comicIssue},
      capabilities: {ProviderCapability.officialHandoff, ProviderCapability.availabilityOffers},
    );
    const channel = DistributionChannel.web;
    const kind = IntegrationEntityKind.comicIssue;
    final now = DateTime.utc(2026, 10, 28);

    test('allows only credential-free official and configured tracking handoffs', () {
      final official = ActionPolicyEvaluator.evaluate(
        provider: provider,
        target: OfficialExternalTarget(providerId: 'books.example', uri: Uri.parse('https://books.example/search')),
        action: AccessAction.open,
        channel: channel,
        countryCode: 'US',
        entityKind: kind,
        now: now,
      );
      expect(official.decision, PolicyDecision.allowed);

      final tracked = ActionPolicyEvaluator.evaluate(
        provider: provider,
        target: AffiliateExternalTarget(providerId: 'books.example', uri: Uri.parse('https://track.example/click')),
        action: AccessAction.open,
        channel: channel,
        countryCode: 'US',
        entityKind: kind,
        now: now,
      );
      expect(tracked.decision, PolicyDecision.allowed);

      final credentialQuery = ActionPolicyEvaluator.evaluate(
        provider: provider,
        target: OfficialExternalTarget(
          providerId: 'books.example',
          uri: Uri.parse('https://books.example/search?access_token=private'),
        ),
        action: AccessAction.open,
        channel: channel,
        countryCode: 'US',
        entityKind: kind,
        now: now,
      );
      expect(credentialQuery.decision, PolicyDecision.denied);
    });

    test('keeps licensed purchases deny-by-default and scopes approval exactly', () {
      const target = LicensedAcquisitionTarget(providerId: 'books.example', productId: 'edition-1', offerId: 'offer-1');
      final missing = ActionPolicyEvaluator.evaluate(
        provider: provider,
        target: target,
        action: AccessAction.buy,
        channel: channel,
        countryCode: 'US',
        entityKind: kind,
        now: now,
      );
      expect(missing.decision, PolicyDecision.unknown);

      final approval = CommerceApproval(
        providerId: 'books.example',
        propertyId: 'plezyng',
        termsVersion: '2026-01',
        actions: {AccessAction.buy},
        channels: {DistributionChannel.web},
        countryCodes: {'US'},
        entityKinds: {IntegrationEntityKind.comicIssue},
        validUntil: DateTime.utc(2027),
        enabled: true,
      );
      final allowed = ActionPolicyEvaluator.evaluate(
        provider: provider,
        target: target,
        action: AccessAction.buy,
        channel: channel,
        countryCode: 'US',
        entityKind: kind,
        now: now,
        approval: approval,
      );
      expect(allowed.decision, PolicyDecision.allowed);
      final wrongCountry = ActionPolicyEvaluator.evaluate(
        provider: provider,
        target: target,
        action: AccessAction.buy,
        channel: channel,
        countryCode: 'CA',
        entityKind: kind,
        now: now,
        approval: approval,
      );
      expect(wrongCountry.decision, PolicyDecision.denied);
    });
  });
}
