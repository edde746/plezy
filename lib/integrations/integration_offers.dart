import 'dart:async';
import 'dart:convert';

import 'integration_contracts.dart';

/// Connection state projected from the existing provider-owned service.
///
/// This value contains no credential and has no persistence API. The service
/// that owns a provider still owns its sign-in, vault record, refresh, and
/// disconnect lifecycle.
enum IntegrationConnectionState {
  connected,
  reauthenticationRequired,
  expired,
  revoked,
  disconnected,
}

class IntegrationConnectionRef {
  const IntegrationConnectionRef({
    required this.connectionId,
    required this.profileId,
    required this.providerId,
    required this.generation,
    required this.state,
    required this.consentVersion,
  });

  final String connectionId;
  final String profileId;
  final String providerId;
  final int generation;
  final IntegrationConnectionState state;
  final String consentVersion;

  bool get isValid =>
      _safeIdentifier(connectionId, maxLength: 128) &&
      _safeIdentifier(profileId, maxLength: 128) &&
      _providerIdPattern.hasMatch(providerId) &&
      generation >= 0 &&
      _safeLabel(consentVersion, maxLength: 128);

  bool get isConnected => isValid && state == IntegrationConnectionState.connected;
}

enum IntegrationEvidenceKind {
  localCopy,
  purchase,
  subscription,
  libraryLoan,
  providerLibrary,
  userAssertion,
}

enum IntegrationEvidenceStatus { verified, selfReported, unknown, expired, revoked }

/// Evidence stays distinct from offers and provider preferences. Only verified
/// evidence with an unexpired action list can authorize a capability.
class IntegrationAccessEvidence {
  IntegrationAccessEvidence({
    required this.id,
    required this.entity,
    required this.providerId,
    required this.kind,
    required this.status,
    required this.observedAt,
    this.connectionId,
    this.validUntil,
    Set<AccessAction> allowedActions = const {},
  }) : allowedActions = Set.unmodifiable(allowedActions);

  final String id;
  final IntegrationEntityRef entity;
  final String providerId;
  final String? connectionId;
  final IntegrationEvidenceKind kind;
  final IntegrationEvidenceStatus status;
  final DateTime observedAt;
  final DateTime? validUntil;
  final Set<AccessAction> allowedActions;

  bool get isValid =>
      _safeIdentifier(id, maxLength: 128) &&
      entity.isValid &&
      _providerIdPattern.hasMatch(providerId) &&
      (connectionId == null || _safeIdentifier(connectionId!, maxLength: 128)) &&
      (validUntil == null || validUntil!.isAfter(observedAt)) &&
      !(kind == IntegrationEvidenceKind.libraryLoan &&
          status == IntegrationEvidenceStatus.verified &&
          validUntil == null) &&
      !(kind == IntegrationEvidenceKind.userAssertion && status == IntegrationEvidenceStatus.verified) &&
      (status == IntegrationEvidenceStatus.verified || allowedActions.isEmpty);

  IntegrationEvidenceStatus statusAt(DateTime now) {
    if (status == IntegrationEvidenceStatus.verified &&
        validUntil != null &&
        !validUntil!.isAfter(now)) {
      return IntegrationEvidenceStatus.expired;
    }
    return status;
  }

  bool allows(AccessAction action, {required DateTime now}) =>
      isValid &&
      statusAt(now) == IntegrationEvidenceStatus.verified &&
      allowedActions.contains(action);
}

class IntegrationMoney {
  const IntegrationMoney({this.amountMinor, this.currencyCode});

  /// Minor units in the source currency. Null means unknown, never zero.
  final int? amountMinor;
  final String? currencyCode;

  bool get isValid =>
      (amountMinor == null || (amountMinor! >= 0 && currencyCode != null)) &&
      (currencyCode == null || _currencyPattern.hasMatch(currencyCode!));
}

enum LicensedOfferKind {
  subscription,
  adSupported,
  channelAddon,
  rent,
  purchase,
  libraryLoan,
  preview,
  free,
}

enum LicensedOfferAvailability { available, comingSoon }

/// Provenance and retention terms for a normalized offer. The offer is
/// in-memory query data; it is not persisted before source-specific retention
/// rights have been approved.
class LicensedOfferSource {
  const LicensedOfferSource({
    required this.providerId,
    required this.termsVersion,
    required this.observedAt,
    required this.expiresAt,
    this.attributionLabel,
  });

  final String providerId;
  final String termsVersion;
  final DateTime observedAt;
  final DateTime expiresAt;
  final String? attributionLabel;

  bool get isValid =>
      _providerIdPattern.hasMatch(providerId) &&
      _safeLabel(termsVersion, maxLength: 128) &&
      expiresAt.isAfter(observedAt) &&
      (attributionLabel == null || _safeLabel(attributionLabel!, maxLength: 160));
}

class LicensedOffer {
  LicensedOffer({
    required this.id,
    required this.entity,
    required this.providerId,
    required this.kind,
    required this.availability,
    required this.countryCode,
    required this.channel,
    required this.source,
    this.productId,
    this.price,
    this.requiredTier,
    Set<String> requiredAddOnProviderIds = const {},
    this.languageTag,
  }) : requiredAddOnProviderIds = Set.unmodifiable(requiredAddOnProviderIds);

  final String id;
  final IntegrationEntityRef entity;

  /// Merchant or service that fulfills the offer; this can differ from the
  /// data source that returned the offer.
  final String providerId;
  final LicensedOfferKind kind;
  final LicensedOfferAvailability availability;
  final String countryCode;
  final DistributionChannel channel;
  final String? productId;
  final IntegrationMoney? price;
  final String? requiredTier;
  final Set<String> requiredAddOnProviderIds;
  final String? languageTag;
  final LicensedOfferSource source;

  bool get isValid =>
      _safeIdentifier(id, maxLength: 256) &&
      entity.isValid &&
      _providerIdPattern.hasMatch(providerId) &&
      countryCode == countryCode.toUpperCase() &&
      _countryPattern.hasMatch(countryCode) &&
      channel != DistributionChannel.unknown &&
      (productId == null || _safeIdentifier(productId!, maxLength: 256)) &&
      (price == null || price!.isValid) &&
      (kind != LicensedOfferKind.free || price?.amountMinor == 0) &&
      (requiredTier == null || _safeLabel(requiredTier!, maxLength: 120)) &&
      requiredAddOnProviderIds.length <= 20 &&
      requiredAddOnProviderIds.every(_providerIdPattern.hasMatch) &&
      (languageTag == null || _languagePattern.hasMatch(languageTag!)) &&
      source.isValid;

  bool isCurrentAt(DateTime now) =>
      isValid && !source.observedAt.isAfter(now) && source.expiresAt.isAfter(now);
}

class AvailabilityLookupRequest {
  AvailabilityLookupRequest({
    required this.entity,
    required this.countryCode,
    required this.channel,
    required List<String> providerIds,
    required Set<LicensedOfferKind> offerKinds,
    this.maxOffersPerProvider = 20,
  }) : providerIds = List.unmodifiable(providerIds),
       offerKinds = Set.unmodifiable(offerKinds);

  final IntegrationEntityRef entity;
  final String countryCode;
  final DistributionChannel channel;
  final List<String> providerIds;
  final Set<LicensedOfferKind> offerKinds;
  final int maxOffersPerProvider;

  /// Intentionally excludes profile IDs, account references, credentials,
  /// private source URLs, and reading or viewing history.
  bool get isValid =>
      entity.isValid &&
      countryCode == countryCode.toUpperCase() &&
      _countryPattern.hasMatch(countryCode) &&
      channel != DistributionChannel.unknown &&
      providerIds.isNotEmpty &&
      providerIds.length <= 8 &&
      providerIds.toSet().length == providerIds.length &&
      providerIds.every(_providerIdPattern.hasMatch) &&
      offerKinds.isNotEmpty &&
      maxOffersPerProvider >= 1 &&
      maxOffersPerProvider <= 50;

  /// Each adapter receives only its own provider ID, not the sibling list.
  AvailabilityLookupRequest _forProvider(String providerId) => AvailabilityLookupRequest(
    entity: entity,
    countryCode: countryCode,
    channel: channel,
    providerIds: [providerId],
    offerKinds: offerKinds,
    maxOffersPerProvider: maxOffersPerProvider,
  );
}

abstract interface class AvailabilityProvider {
  String get providerId;

  Future<List<LicensedOffer>> lookup(AvailabilityLookupRequest request);
}

sealed class AvailabilityProviderException implements Exception {
  const AvailabilityProviderException();
}

final class AvailabilityRateLimitedException extends AvailabilityProviderException {
  const AvailabilityRateLimitedException({this.retryAt});

  final DateTime? retryAt;
}

final class AvailabilityUnavailableException extends AvailabilityProviderException {
  const AvailabilityUnavailableException();
}

/// A retryable transport/server failure. The dispatcher allows at most one
/// retry, and only when the provider's delay fits the original query deadline.
final class AvailabilityTransientException extends AvailabilityProviderException {
  const AvailabilityTransientException({this.retryAfter});

  final Duration? retryAfter;
}

final class AvailabilityInvalidResponseException extends AvailabilityProviderException {
  const AvailabilityInvalidResponseException();
}

enum AvailabilityProviderStatus {
  success,
  notConfigured,
  timedOut,
  rateLimited,
  unavailable,
  invalidResponse,
}

class AvailabilityProviderOutcome {
  AvailabilityProviderOutcome({
    required this.providerId,
    required this.status,
    List<LicensedOffer> offers = const [],
    this.retryAt,
  }) : offers = List.unmodifiable(offers);

  final String providerId;
  final AvailabilityProviderStatus status;
  final List<LicensedOffer> offers;
  final DateTime? retryAt;
}

class AvailabilityLookupResult {
  AvailabilityLookupResult({
    required List<AvailabilityProviderOutcome> providers,
    required List<LicensedOffer> offers,
  }) : providers = List.unmodifiable(providers),
       offers = List.unmodifiable(offers);

  final List<AvailabilityProviderOutcome> providers;
  final List<LicensedOffer> offers;

  bool get hasProviderFailures => providers.any(
    (result) => !const {
      AvailabilityProviderStatus.success,
      AvailabilityProviderStatus.notConfigured,
    }.contains(result.status),
  );
}

/// Bounded, no-cache dispatcher for approved availability adapters.
///
/// Provider failures are isolated and never become positive offers. One
/// transient retry is allowed inside the original deadline; HTTP 429 responses
/// surface a bounded Retry-After time and are never retried automatically.
class AvailabilityLookupService {
  AvailabilityLookupService({
    required Iterable<AvailabilityProvider> providers,
    this.timeout = const Duration(seconds: 5),
    DateTime Function()? clock,
    Future<void> Function(Duration duration)? wait,
  }) : _providers = _indexProviders(providers),
       _clock = clock ?? DateTime.now,
       _wait = wait ?? ((duration) => Future<void>.delayed(duration)) {
    if (timeout <= Duration.zero || timeout > const Duration(seconds: 15)) {
      throw ArgumentError.value(timeout, 'timeout', 'Timeout must be between zero and 15 seconds.');
    }
  }

  final Map<String, AvailabilityProvider> _providers;
  final Duration timeout;
  final DateTime Function() _clock;
  final Future<void> Function(Duration duration) _wait;

  Future<AvailabilityLookupResult> lookup(AvailabilityLookupRequest request) async {
    if (!request.isValid) throw ArgumentError.value(request, 'request');
    final now = _clock();
    final outcomes = await Future.wait(
      request.providerIds.map((providerId) => _lookupProvider(providerId, request, now)),
    );
    final offers = [
      for (final outcome in outcomes)
        if (outcome.status == AvailabilityProviderStatus.success) ...outcome.offers,
    ];
    return AvailabilityLookupResult(
      providers: List.unmodifiable(outcomes),
      offers: List.unmodifiable(offers),
    );
  }

  Future<AvailabilityProviderOutcome> _lookupProvider(
    String providerId,
    AvailabilityLookupRequest request,
    DateTime now,
  ) async {
    final provider = _providers[providerId];
    if (provider == null) {
      return AvailabilityProviderOutcome(
        providerId: providerId,
        status: AvailabilityProviderStatus.notConfigured,
      );
    }

    final deadline = Stopwatch()..start();
    for (var attempt = 0; attempt < 2; attempt++) {
      final remaining = timeout - deadline.elapsed;
      if (remaining <= Duration.zero) {
        return _failure(providerId, AvailabilityProviderStatus.timedOut);
      }

      try {
        final offers = await provider.lookup(request._forProvider(providerId)).timeout(remaining);
        if (offers.length > request.maxOffersPerProvider) {
          return _failure(providerId, AvailabilityProviderStatus.invalidResponse);
        }
        final seen = <String>{};
        for (final offer in offers) {
          final identity = jsonEncode([offer.providerId, offer.id]);
          if (!_matchesRequest(offer, providerId, request, now) || !seen.add(identity)) {
            return _failure(providerId, AvailabilityProviderStatus.invalidResponse);
          }
        }
        return AvailabilityProviderOutcome(
          providerId: providerId,
          status: AvailabilityProviderStatus.success,
          offers: List.unmodifiable(offers),
        );
      } on TimeoutException {
        return _failure(providerId, AvailabilityProviderStatus.timedOut);
      } on AvailabilityRateLimitedException catch (error) {
        final retryAt = error.retryAt;
        return AvailabilityProviderOutcome(
          providerId: providerId,
          status: AvailabilityProviderStatus.rateLimited,
          retryAt: retryAt != null && retryAt.isAfter(now) && retryAt.isBefore(now.add(const Duration(days: 1)))
              ? retryAt
              : null,
        );
      } on AvailabilityTransientException catch (error) {
        if (attempt != 0) return _failure(providerId, AvailabilityProviderStatus.unavailable);
        final delay = error.retryAfter ?? const Duration(milliseconds: 100);
        if (delay < Duration.zero || delay > const Duration(milliseconds: 500)) {
          return _failure(providerId, AvailabilityProviderStatus.unavailable);
        }
        final waitBudget = timeout - deadline.elapsed;
        if (delay >= waitBudget) return _failure(providerId, AvailabilityProviderStatus.timedOut);
        try {
          await _wait(delay).timeout(waitBudget);
        } on TimeoutException {
          return _failure(providerId, AvailabilityProviderStatus.timedOut);
        }
      } on AvailabilityInvalidResponseException {
        return _failure(providerId, AvailabilityProviderStatus.invalidResponse);
      } on AvailabilityUnavailableException {
        return _failure(providerId, AvailabilityProviderStatus.unavailable);
      } on Object {
        return _failure(providerId, AvailabilityProviderStatus.unavailable);
      }
    }
    return _failure(providerId, AvailabilityProviderStatus.unavailable);
  }

  bool _matchesRequest(
    LicensedOffer offer,
    String sourceProviderId,
    AvailabilityLookupRequest request,
    DateTime now,
  ) =>
      offer.isCurrentAt(now) &&
      offer.source.providerId == sourceProviderId &&
      _sameEntity(offer.entity, request.entity) &&
      offer.countryCode == request.countryCode &&
      offer.channel == request.channel &&
      request.offerKinds.contains(offer.kind);

  AvailabilityProviderOutcome _failure(String providerId, AvailabilityProviderStatus status) =>
      AvailabilityProviderOutcome(providerId: providerId, status: status);

  static Map<String, AvailabilityProvider> _indexProviders(Iterable<AvailabilityProvider> providers) {
    final result = <String, AvailabilityProvider>{};
    for (final provider in providers) {
      if (!_providerIdPattern.hasMatch(provider.providerId) || result.containsKey(provider.providerId)) {
        throw ArgumentError.value(provider.providerId, 'providers', 'Provider IDs must be valid and unique.');
      }
      result[provider.providerId] = provider;
    }
    return Map.unmodifiable(result);
  }
}

bool _sameEntity(IntegrationEntityRef a, IntegrationEntityRef b) =>
    a.providerId == b.providerId &&
    a.nativeId == b.nativeId &&
    a.kind == b.kind &&
    a.editionId == b.editionId;

bool _safeIdentifier(String value, {required int maxLength}) =>
    value.trim().isNotEmpty &&
    value.length <= maxLength &&
    !value.contains(RegExp(r'[\x00-\x1f\x7f]'));

bool _safeLabel(String value, {required int maxLength}) =>
    value.trim().isNotEmpty &&
    value.length <= maxLength &&
    !value.contains(RegExp(r'[\x00-\x1f\x7f]'));

final _providerIdPattern = RegExp(r'^[a-z0-9][a-z0-9._-]{0,63}$');
final _countryPattern = RegExp(r'^[A-Z]{2}$');
final _currencyPattern = RegExp(r'^[A-Z]{3}$');
final _languagePattern = RegExp(r'^[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8})*$');
