import 'package:flutter/foundation.dart';

import 'integration_contracts.dart';

/// Setup state for a licensed title-availability source. Credentials are never
/// represented here: confidential partner keys belong in the backend secret
/// store, and a client adapter receives only authorized responses.
enum AvailabilityProviderGate { ready, partnerApprovalRequired, credentialsRequired, disabled }

enum AvailabilityResultState { complete, blocked, unavailable }

enum AvailabilityFailure {
  approvalRequired,
  credentialsRequired,
  unsupportedRegion,
  rateLimited,
  timedOut,
  invalidResponse,
  upstreamUnavailable,
}

@immutable
class AvailabilityLookupRequest {
  const AvailabilityLookupRequest({
    required this.entity,
    required this.countryCode,
    required this.requestedAt,
    this.maxOffers = 30,
  });

  final IntegrationEntityRef entity;
  final String countryCode;
  final DateTime requestedAt;
  final int maxOffers;

  bool get isValid =>
      entity.isValid &&
      RegExp(r'^[A-Z]{2}$').hasMatch(countryCode) &&
      maxOffers > 0 &&
      maxOffers <= 100;
}

/// A bounded result from a licensed availability provider. A complete result
/// may contain zero offers. It never proves a user's account or entitlement.
@immutable
class AvailabilityLookupResult {
  const AvailabilityLookupResult({
    required this.providerId,
    required this.state,
    required this.checkedAt,
    this.offers = const [],
    this.failure,
    this.retryAfter,
  });

  final String providerId;
  final AvailabilityResultState state;
  final DateTime checkedAt;
  final List<AccessOffer> offers;
  final AvailabilityFailure? failure;
  final Duration? retryAfter;

  /// Rejects responses that could attach an offer to the wrong title, country,
  /// provider, or unapproved destination host before the result reaches UI.
  bool isValidFor(
    AvailabilityLookupRequest request,
    ProviderDefinition provider, {
    required Map<String, ProviderDefinition> destinationProviders,
  }) {
    if (!request.isValid ||
        !provider.isValid ||
        !provider.capabilities.contains(ProviderCapability.availabilityOffers) ||
        providerId != provider.id ||
        offers.length > request.maxOffers ||
        (retryAfter != null && retryAfter! < Duration.zero)) {
      return false;
    }

    if (state != AvailabilityResultState.complete) return offers.isEmpty && failure != null;
    if (failure != null) return false;

    final seenOfferIds = <String>{};
    for (final offer in offers) {
      final destinationProvider = destinationProviders[offer.sellerProviderId];
      if (!offer.isValid ||
          offer.sourceId != provider.id ||
          offer.countryCode != request.countryCode ||
          !_sameEntity(offer.entity, request.entity) ||
          !seenOfferIds.add(offer.id) ||
          destinationProvider == null ||
          !destinationProvider.isValid ||
          !destinationProvider.officialHosts.any(
            (host) => host.toLowerCase() == offer.canonicalDestination.host.toLowerCase(),
          )) {
        return false;
      }
    }
    return true;
  }
}

/// Implementations may use an approved public API or an authorized backend
/// service. This interface deliberately has no API-key property or key setter.
abstract interface class AvailabilityProviderAdapter {
  ProviderDefinition get definition;

  AvailabilityProviderGate get gate;

  Future<AvailabilityLookupResult> lookup(AvailabilityLookupRequest request);
}

/// Deterministic adapter registry used by detail/search projections. A
/// provider becomes queryable only when an implementation reports `ready`;
/// missing approval or credentials stay explicit and fail closed.
class AvailabilityProviderRegistry {
  AvailabilityProviderRegistry(Iterable<AvailabilityProviderAdapter> providers)
    : providers = List.unmodifiable(providers) {
    final ids = <String>{};
    for (final provider in this.providers) {
      if (!provider.definition.isValid ||
          !provider.definition.capabilities.contains(ProviderCapability.availabilityOffers) ||
          !ids.add(provider.definition.id)) {
        throw ArgumentError('Availability providers need unique IDs and the availabilityOffers capability.');
      }
    }
  }

  final List<AvailabilityProviderAdapter> providers;

  List<AvailabilityProviderAdapter> readyFor(IntegrationEntityKind kind) => List.unmodifiable(
    providers.where(
      (provider) =>
          provider.gate == AvailabilityProviderGate.ready && provider.definition.entityKinds.contains(kind),
    ),
  );

  AvailabilityProviderAdapter? byId(String providerId) {
    for (final provider in providers) {
      if (provider.definition.id == providerId) return provider;
    }
    return null;
  }
}

bool _sameEntity(IntegrationEntityRef left, IntegrationEntityRef right) =>
    left.providerId == right.providerId &&
    left.nativeId == right.nativeId &&
    left.kind == right.kind &&
    left.editionId == right.editionId;
