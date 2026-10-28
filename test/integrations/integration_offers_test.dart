import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/integrations/integration_contracts.dart';
import 'package:plezy/integrations/integration_offers.dart';

const _entity = IntegrationEntityRef(
  providerId: 'catalog',
  nativeId: 'issue-12',
  kind: IntegrationEntityKind.comicIssue,
  editionId: 'cover-a',
);
final _now = DateTime.utc(2026, 10, 28, 12);

class _Provider implements AvailabilityProvider {
  _Provider(this.providerId, this.respond);

  @override
  final String providerId;
  final Future<List<LicensedOffer>> Function(AvailabilityLookupRequest request) respond;

  @override
  Future<List<LicensedOffer>> lookup(AvailabilityLookupRequest request) => respond(request);
}

LicensedOffer _offer({
  String providerId = 'store-a',
  String sourceProviderId = 'availability-a',
  IntegrationEntityRef entity = _entity,
  String countryCode = 'CA',
  DistributionChannel channel = DistributionChannel.web,
  LicensedOfferKind kind = LicensedOfferKind.purchase,
  String? productId = 'product-123',
  IntegrationMoney? price,
  DateTime? observedAt,
  DateTime? expiresAt,
  Set<String> addOns = const {},
}) => LicensedOffer(
  id: 'product-123',
  entity: entity,
  providerId: providerId,
  kind: kind,
  availability: LicensedOfferAvailability.available,
  countryCode: countryCode,
  channel: channel,
  productId: productId,
  price: price,
  requiredTier: 'Collector',
  requiredAddOnProviderIds: addOns,
  source: LicensedOfferSource(
    providerId: sourceProviderId,
    termsVersion: 'terms-2026-01',
    observedAt: observedAt ?? _now.subtract(const Duration(minutes: 2)),
    expiresAt: expiresAt ?? _now.add(const Duration(hours: 1)),
    attributionLabel: 'Availability partner',
  ),
);

AvailabilityLookupRequest _request({List<String> providers = const ['availability-a']}) =>
    AvailabilityLookupRequest(
      entity: _entity,
      countryCode: 'CA',
      channel: DistributionChannel.web,
      providerIds: providers,
      offerKinds: const {LicensedOfferKind.purchase, LicensedOfferKind.rent},
    );

void main() {
  group('availability contract', () {
    test('returns exact, fresh offers and keeps unknown price unknown', () async {
      final expected = _offer(addOns: const {'channel.extra'});
      final service = AvailabilityLookupService(
        providers: [_Provider('availability-a', (_) async => [expected])],
        clock: () => _now,
      );

      final result = await service.lookup(_request());

      expect(result.offers, [expected]);
      expect(result.providers.single.status, AvailabilityProviderStatus.success);
      expect(result.offers.single.price, isNull);
      expect(result.offers.single.requiredTier, 'Collector');
      expect(result.offers.single.requiredAddOnProviderIds, {'channel.extra'});
    });

    test('rejects a provider response containing stale, wrong-country or wrong-edition offers', () async {
      final stale = _offer(expiresAt: _now);
      final wrongCountry = _offer(countryCode: 'US');
      final wrongEdition = _offer(
        entity: const IntegrationEntityRef(
          providerId: 'catalog',
          nativeId: 'issue-12',
          kind: IntegrationEntityKind.comicIssue,
          editionId: 'cover-b',
        ),
      );
      final service = AvailabilityLookupService(
        providers: [
          _Provider('availability-a', (_) async => [stale, wrongCountry, wrongEdition]),
        ],
        clock: () => _now,
      );

      final result = await service.lookup(_request());

      expect(result.offers, isEmpty);
      expect(result.providers.single.status, AvailabilityProviderStatus.invalidResponse);
      expect(result.hasProviderFailures, isTrue);
    });

    test('scopes each adapter request to that adapter and freezes caller collections', () async {
      final received = <List<String>>[];
      final providerA = _Provider('availability-a', (request) async {
        received.add(request.providerIds);
        return const <LicensedOffer>[];
      });
      final providerB = _Provider('availability-b', (request) async {
        received.add(request.providerIds);
        return const <LicensedOffer>[];
      });
      final mutableProviders = ['availability-a', 'availability-b'];
      final mutableKinds = <LicensedOfferKind>{LicensedOfferKind.purchase};
      final request = AvailabilityLookupRequest(
        entity: _entity,
        countryCode: 'CA',
        channel: DistributionChannel.web,
        providerIds: mutableProviders,
        offerKinds: mutableKinds,
      );
      mutableProviders.clear();
      mutableKinds.clear();

      await AvailabilityLookupService(
        providers: [providerA, providerB],
        clock: () => _now,
      ).lookup(request);

      expect(received, [
        ['availability-a'],
        ['availability-b'],
      ]);
      expect(request.isValid, isTrue);
      expect(request.offerKinds, {LicensedOfferKind.purchase});
    });

    test('isolates rate limits, timeouts, and missing adapters', () async {
      final never = Completer<List<LicensedOffer>>();
      final service = AvailabilityLookupService(
        providers: [
          _Provider('limited', (_) async {
            throw AvailabilityRateLimitedException(retryAt: _now.add(const Duration(minutes: 3)));
          }),
          _Provider('slow', (_) => never.future),
          _Provider('healthy', (_) async => [_offer(sourceProviderId: 'healthy')]),
        ],
        timeout: const Duration(milliseconds: 50),
        clock: () => _now,
      );

      final result = await service.lookup(
        _request(providers: const ['limited', 'slow', 'not-installed', 'healthy']),
      );

      expect(result.providers.map((value) => value.status), [
        AvailabilityProviderStatus.rateLimited,
        AvailabilityProviderStatus.timedOut,
        AvailabilityProviderStatus.notConfigured,
        AvailabilityProviderStatus.success,
      ]);
      expect(result.providers.first.retryAt, _now.add(const Duration(minutes: 3)));
      expect(result.offers, hasLength(1));
      expect(result.offers.single.source.providerId, 'healthy');
    });

    test('retries one short transient failure without extending the query deadline', () async {
      var attempts = 0;
      final service = AvailabilityLookupService(
        providers: [
          _Provider('availability-a', (_) async {
            attempts++;
            if (attempts == 1) {
              throw const AvailabilityTransientException(retryAfter: Duration.zero);
            }
            return [_offer()];
          }),
        ],
        timeout: const Duration(seconds: 1),
        clock: () => _now,
        wait: (_) async {},
      );

      final result = await service.lookup(_request());

      expect(attempts, 2);
      expect(result.offers.single.id, 'product-123');
    });

    test('rejects duplicates, cross-provider rows, and invalid request scope', () async {
      final offer = _offer();
      final duplicateProvider = _Provider('availability-a', (_) async => [offer, offer]);
      final duplicateService = AvailabilityLookupService(
        providers: [duplicateProvider],
        clock: () => _now,
      );
      final duplicateResult = await duplicateService.lookup(_request());
      expect(duplicateResult.providers.single.status, AvailabilityProviderStatus.invalidResponse);

      final wrongSourceService = AvailabilityLookupService(
        providers: [
          _Provider('availability-a', (_) async => [_offer(sourceProviderId: 'availability-b')]),
        ],
        clock: () => _now,
      );
      final wrongSourceResult = await wrongSourceService.lookup(_request());
      expect(wrongSourceResult.providers.single.status, AvailabilityProviderStatus.invalidResponse);

      final invalid = AvailabilityLookupRequest(
        entity: _entity,
        countryCode: 'US',
        channel: DistributionChannel.unknown,
        providerIds: const ['availability-a', 'availability-a'],
        offerKinds: const {},
      );
      expect(invalid.isValid, isFalse);
      await expectLater(duplicateService.lookup(invalid), throwsArgumentError);
    });

    test('does not treat an unknown price as a free offer', () {
      final unknownFree = _offer(kind: LicensedOfferKind.free);
      final verifiedZero = _offer(
        kind: LicensedOfferKind.free,
        price: const IntegrationMoney(amountMinor: 0, currencyCode: 'CAD'),
      );

      expect(unknownFree.isValid, isFalse);
      expect(verifiedZero.isValid, isTrue);
      expect(verifiedZero.price?.amountMinor, 0);
    });

    test('a licensed purchase row does not authorize a purchase without approval', () {
      final provider = ProviderDefinition(
        id: 'store-a',
        displayName: 'Store',
        officialHosts: const {'store.example'},
        entityKinds: const {IntegrationEntityKind.comicIssue},
        capabilities: const {ProviderCapability.availabilityOffers},
      );
      final decision = ActionPolicyEvaluator.evaluate(
        provider: provider,
        target: const LicensedAcquisitionTarget(
          providerId: 'store-a',
          productId: 'product-123',
          offerId: 'product-123',
        ),
        action: AccessAction.buy,
        channel: DistributionChannel.web,
        countryCode: 'CA',
        entityKind: IntegrationEntityKind.comicIssue,
        now: _now,
      );

      expect(decision.decision, PolicyDecision.unknown);
      expect(decision.reason, PolicyReason.missingApproval);
    });
  });

  group('connection and access evidence', () {
    test('connection references expose lifecycle state without credential fields', () {
      const connection = IntegrationConnectionRef(
        connectionId: 'connection-1',
        profileId: 'profile-a',
        providerId: 'hardcover',
        generation: 4,
        state: IntegrationConnectionState.connected,
        consentVersion: '2026-01',
      );

      expect(connection.isValid, isTrue);
      expect(connection.isConnected, isTrue);
    });

    test('self-reported, revoked, and expired access never allow actions', () {
      final selfReported = IntegrationAccessEvidence(
        id: 'self',
        entity: _entity,
        providerId: 'streaming-service',
        kind: IntegrationEvidenceKind.userAssertion,
        status: IntegrationEvidenceStatus.selfReported,
        observedAt: _now,
      );
      final revoked = IntegrationAccessEvidence(
        id: 'revoked',
        entity: _entity,
        providerId: 'store-a',
        kind: IntegrationEvidenceKind.purchase,
        status: IntegrationEvidenceStatus.revoked,
        observedAt: _now,
      );
      final expiredLoan = IntegrationAccessEvidence(
        id: 'loan',
        entity: _entity,
        providerId: 'library',
        kind: IntegrationEvidenceKind.libraryLoan,
        status: IntegrationEvidenceStatus.verified,
        observedAt: _now.subtract(const Duration(days: 2)),
        validUntil: _now,
        allowedActions: const {AccessAction.read, AccessAction.returnLoan},
      );

      expect(selfReported.isValid, isTrue);
      expect(selfReported.allows(AccessAction.play, now: _now), isFalse);
      expect(revoked.allows(AccessAction.read, now: _now), isFalse);
      expect(expiredLoan.statusAt(_now), IntegrationEvidenceStatus.expired);
      expect(expiredLoan.allows(AccessAction.read, now: _now), isFalse);
    });

    test('verified loan evidence requires expiry and only allows its declared actions', () {
      final invalidLoan = IntegrationAccessEvidence(
        id: 'loan',
        entity: _entity,
        providerId: 'library',
        kind: IntegrationEvidenceKind.libraryLoan,
        status: IntegrationEvidenceStatus.verified,
        observedAt: _now,
        allowedActions: const {AccessAction.read},
      );
      final validLoan = IntegrationAccessEvidence(
        id: 'loan-2',
        entity: _entity,
        providerId: 'library',
        kind: IntegrationEvidenceKind.libraryLoan,
        status: IntegrationEvidenceStatus.verified,
        observedAt: _now,
        validUntil: _now.add(const Duration(days: 7)),
        allowedActions: const {AccessAction.read, AccessAction.returnLoan},
      );

      expect(invalidLoan.isValid, isFalse);
      expect(validLoan.allows(AccessAction.read, now: _now), isTrue);
      expect(validLoan.allows(AccessAction.buy, now: _now), isFalse);
    });
  });
}
