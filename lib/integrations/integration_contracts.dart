import 'package:flutter/foundation.dart';

/// Stable content classes understood by cross-provider integrations. They are
/// intentionally separate from the app's media/file enums and catalog IDs:
/// an external work can be related to a local copy without replacing its owner.
enum IntegrationEntityKind {
  movie,
  series,
  season,
  episode,
  bookWork,
  bookEdition,
  audiobookEdition,
  comicSeries,
  comicIssue,
  musicRelease,
  musicRecording,
  game,
  gameEdition,
  unknown,
}

enum ProviderCapability {
  catalogSearch,
  catalogBrowse,
  availabilityOffers,
  accountConnection,
  entitlementRead,
  lending,
  officialHandoff,
  nativePlayback,
  progressSync,
}

enum ProviderConnectionState { connecting, connected, expired, revoked, failed, disconnected }

enum IdentifierMatchMethod { exactIdentifier, providerCrosswalk, userConfirmed, suggested }

enum EntityRelationKind {
  sameWork,
  editionOf,
  adaptationOf,
  episodeOf,
  issueOf,
  releaseOf,
  recordingOf,
  editionForPlatform,
  contains,
}

enum AccessOfferKind { free, adSupported, subscription, borrow, rent, buy }

/// Provider-level access models used only to organize external destinations.
/// They do not assert that a specific title, territory, or user account has
/// access; only a fresh [AccessOffer] can make that claim.
enum ProviderAccessModel { freeAdSupported, subscription, transactional, publicService }

enum AccessEvidenceState { verified, selfReported, unknown, expired, revoked }

enum AccessAction { open, play, read, listen, preview, borrow, placeHold, renew, returnLoan, rent, buy, import }

enum DistributionChannel { direct, appleAppStore, googlePlay, amazonAppstore, tvStore, web, unknown }

enum PolicyDecision { allowed, denied, unknown }

enum PolicyReason { officialHandoff, affiliateHandoff, approvedCommerce, missingApproval, expiredApproval, scopeMismatch, invalidTarget }

/// A public, non-secret description of a provider. Provider definitions never
/// imply that an account, offer source, or native capability is enabled.
@immutable
class ProviderDefinition {
  const ProviderDefinition({
    required this.id,
    required this.displayName,
    required this.officialHosts,
    required this.entityKinds,
    required this.capabilities,
    this.accessModels = const {},
    this.affiliateHosts = const {},
  });

  final String id;
  final String displayName;
  final Set<String> officialHosts;
  /// Exact HTTPS tracking hosts approved for this provider's affiliate links.
  /// These do not grant purchase, availability, or playback capability.
  final Set<String> affiliateHosts;
  final Set<IntegrationEntityKind> entityKinds;
  final Set<ProviderCapability> capabilities;
  final Set<ProviderAccessModel> accessModels;

  bool get isValid =>
      _providerId.hasMatch(id) &&
      displayName.trim().isNotEmpty &&
      officialHosts.isNotEmpty &&
      officialHosts.every(_validHost) &&
      affiliateHosts.every(
        (host) => host.startsWith('*.') ? _validHost(host.substring(2)) : _validHost(host),
      );
}

/// Profile-bound connection metadata. Credentials are kept in the existing
/// encrypted vault and referenced by [vaultReference]; they never enter this
/// model's JSON or ordinary preferences.
@immutable
class ProviderConnectionRef {
  const ProviderConnectionRef({
    required this.profileId,
    required this.connectionId,
    required this.providerId,
    required this.generation,
    required this.state,
    this.accountLabel,
    this.vaultReference,
    this.consentVersion,
  });

  final String profileId;
  final String connectionId;
  final String providerId;
  final int generation;
  final ProviderConnectionState state;
  final String? accountLabel;
  final String? vaultReference;
  final String? consentVersion;

  bool get isValid =>
      profileId.trim().isNotEmpty &&
      _providerId.hasMatch(providerId) &&
      connectionId.trim().isNotEmpty &&
      generation >= 0 &&
      (vaultReference == null || vaultReference!.trim().isNotEmpty);
}

@immutable
class IntegrationEntityRef {
  const IntegrationEntityRef({
    required this.providerId,
    required this.nativeId,
    required this.kind,
    this.editionId,
  });

  final String providerId;
  final String nativeId;
  final IntegrationEntityKind kind;
  final String? editionId;

  bool get isValid =>
      _providerId.hasMatch(providerId) &&
      _safeIdentifier(nativeId) &&
      (editionId == null || _safeIdentifier(editionId!)) &&
      kind != IntegrationEntityKind.unknown;
}

/// A typed external identifier with match provenance. Similar text is not an
/// identity crosswalk; only exact/provider/user-confirmed methods can be used
/// for automatic joins.
@immutable
class ExternalIdentifier {
  const ExternalIdentifier({
    required this.namespace,
    required this.value,
    required this.entityKind,
    required this.sourceProviderId,
    required this.method,
    required this.observedAt,
  });

  final String namespace;
  final String value;
  final IntegrationEntityKind entityKind;
  final String sourceProviderId;
  final IdentifierMatchMethod method;
  final DateTime observedAt;

  bool get isValid =>
      _namespace.hasMatch(namespace) &&
      _safeIdentifier(value) &&
      entityKind != IntegrationEntityKind.unknown &&
      _providerId.hasMatch(sourceProviderId);

  bool get mayJoinAutomatically =>
      isValid && method != IdentifierMatchMethod.suggested;
}

@immutable
class EntityRelation {
  const EntityRelation({required this.from, required this.to, required this.kind, required this.confirmed});

  final IntegrationEntityRef from;
  final IntegrationEntityRef to;
  final EntityRelationKind kind;
  final bool confirmed;

  bool get isValid =>
      from.isValid &&
      to.isValid &&
      !(from.providerId == to.providerId &&
          from.nativeId == to.nativeId &&
          from.kind == to.kind &&
          from.editionId == to.editionId);
}

/// An offer is licensed provider data, not evidence of purchase or access.
/// Prices use a canonical decimal string so currencies with differing minor
/// unit conventions do not get rounded or misrepresented.
@immutable
class AccessOffer {
  const AccessOffer({
    required this.id,
    required this.entity,
    required this.sellerProviderId,
    required this.kind,
    required this.countryCode,
    required this.canonicalDestination,
    required this.sourceId,
    required this.observedAt,
    this.fulfillmentProviderId,
    this.format,
    this.priceAmount,
    this.currencyCode,
    this.expiresAt,
    this.attributionLabel,
  });

  final String id;
  final IntegrationEntityRef entity;
  final String sellerProviderId;
  final String? fulfillmentProviderId;
  final AccessOfferKind kind;
  final String countryCode;
  final String? format;
  final String? priceAmount;
  final String? currencyCode;
  final Uri canonicalDestination;
  final String sourceId;
  final DateTime observedAt;
  final DateTime? expiresAt;
  final String? attributionLabel;

  bool get hasKnownPrice => priceAmount != null && currencyCode != null;

  bool get isValid =>
      id.trim().isNotEmpty &&
      entity.isValid &&
      _providerId.hasMatch(sellerProviderId) &&
      (fulfillmentProviderId == null || _providerId.hasMatch(fulfillmentProviderId!)) &&
      RegExp(r'^[A-Z]{2}$').hasMatch(countryCode) &&
      (priceAmount == null || RegExp(r'^(0|[1-9][0-9]*)(\.[0-9]{1,6})?$').hasMatch(priceAmount!)) &&
      (currencyCode == null || RegExp(r'^[A-Z]{3}$').hasMatch(currencyCode!)) &&
      ((priceAmount == null) == (currencyCode == null)) &&
      canonicalDestination.scheme == 'https' &&
      canonicalDestination.host.isNotEmpty &&
      canonicalDestination.userInfo.isEmpty &&
      !_hasCredentialQuery(canonicalDestination) &&
      sourceId.trim().isNotEmpty &&
      (expiresAt == null || !expiresAt!.isBefore(observedAt));

  bool isFreshAt(DateTime now, Duration maxAge) =>
      isValid &&
      !observedAt.isAfter(now) &&
      now.difference(observedAt) <= maxAge &&
      (expiresAt == null || expiresAt!.isAfter(now));
}

@immutable
class AccessEvidence {
  const AccessEvidence({
    required this.profileId,
    required this.entity,
    required this.providerId,
    required this.state,
    required this.observedAt,
    this.expiresAt,
    this.allowedActions = const {},
    this.connectionId,
  });

  final String profileId;
  final IntegrationEntityRef entity;
  final String providerId;
  final AccessEvidenceState state;
  final DateTime observedAt;
  final DateTime? expiresAt;
  final Set<AccessAction> allowedActions;
  final String? connectionId;

  bool isUsableAt(DateTime now, AccessAction action) =>
      profileId.isNotEmpty &&
      entity.isValid &&
      _providerId.hasMatch(providerId) &&
      state == AccessEvidenceState.verified &&
      !observedAt.isAfter(now) &&
      (expiresAt == null || expiresAt!.isAfter(now)) &&
      allowedActions.contains(action);
}

/// A target is a recipe understood by an owner. It is never a raw media URL.
sealed class AccessTarget {
  const AccessTarget();
}

final class ExistingSourceTarget extends AccessTarget {
  const ExistingSourceTarget({required this.sourceId, required this.entryId, required this.fileId});
  final String sourceId;
  final String entryId;
  final String fileId;
}

final class OfficialExternalTarget extends AccessTarget {
  const OfficialExternalTarget({required this.providerId, required this.uri});
  final String providerId;
  final Uri uri;

  bool isValidFor(ProviderDefinition provider) =>
      provider.id == providerId &&
      uri.scheme == 'https' &&
      uri.userInfo.isEmpty &&
      uri.fragment.isEmpty &&
      !_hasCredentialQuery(uri) &&
      provider.officialHosts.any((host) => host.toLowerCase() == uri.host.toLowerCase());
}

/// A tracking link issued by the server-side broker after the storefront's
/// agreement gate passed. Restricted to exact provider-approved hosts.
final class AffiliateExternalTarget extends AccessTarget {
  const AffiliateExternalTarget({required this.providerId, required this.uri});
  final String providerId;
  final Uri uri;

  bool isValidFor(ProviderDefinition provider) =>
      provider.id == providerId &&
      uri.scheme == 'https' &&
      uri.userInfo.isEmpty &&
      uri.fragment.isEmpty &&
      !_hasCredentialQuery(uri) &&
      provider.affiliateHosts.any((host) {
        final normalized = host.toLowerCase();
        if (normalized.startsWith('*.')) {
          return uri.host.toLowerCase().endsWith(normalized.substring(1));
        }
        return normalized == uri.host.toLowerCase();
      });
}

final class ProviderSdkTarget extends AccessTarget {
  const ProviderSdkTarget({required this.providerId, required this.itemId, required this.connectionId});
  final String providerId;
  final String itemId;
  final String connectionId;
}

final class LicensedAcquisitionTarget extends AccessTarget {
  const LicensedAcquisitionTarget({required this.providerId, required this.productId, required this.offerId});
  final String providerId;
  final String productId;
  final String offerId;
}

@immutable
class CommerceApproval {
  const CommerceApproval({
    required this.providerId,
    required this.propertyId,
    required this.termsVersion,
    required this.actions,
    required this.channels,
    required this.countryCodes,
    required this.entityKinds,
    required this.validUntil,
    required this.enabled,
  });

  final String providerId;
  final String propertyId;
  final String termsVersion;
  final Set<AccessAction> actions;
  final Set<DistributionChannel> channels;
  final Set<String> countryCodes;
  final Set<IntegrationEntityKind> entityKinds;
  final DateTime validUntil;
  final bool enabled;

  bool allows({
    required String providerId,
    required AccessAction action,
    required DistributionChannel channel,
    required String countryCode,
    required IntegrationEntityKind entityKind,
    required DateTime now,
  }) =>
      enabled &&
      _providerId.hasMatch(this.providerId) &&
      this.providerId == providerId &&
      propertyId.trim().isNotEmpty &&
      termsVersion.trim().isNotEmpty &&
      validUntil.isAfter(now) &&
      actions.contains(action) &&
      channels.contains(channel) &&
      countryCodes.contains(countryCode) &&
      entityKinds.contains(entityKind);
}

@immutable
class ActionPolicyDecision {
  const ActionPolicyDecision(this.decision, this.reason);
  final PolicyDecision decision;
  final PolicyReason reason;
}

/// Local policy is deny-by-default for commercial actions. Opens may use the
/// provider's curated HTTPS host or an exact affiliate host configured for the
/// server broker. Affiliate links never grant purchase permission.
abstract final class ActionPolicyEvaluator {
  static ActionPolicyDecision evaluate({
    required ProviderDefinition provider,
    required AccessTarget target,
    required AccessAction action,
    required DistributionChannel channel,
    required String countryCode,
    required IntegrationEntityKind entityKind,
    required DateTime now,
    CommerceApproval? approval,
  }) {
    if (!provider.isValid) return const ActionPolicyDecision(PolicyDecision.denied, PolicyReason.invalidTarget);

    if (action == AccessAction.open) {
      final entityAllowed = entityKind == IntegrationEntityKind.unknown || provider.entityKinds.contains(entityKind);
      if (provider.capabilities.contains(ProviderCapability.officialHandoff) && entityAllowed) {
        if (target is OfficialExternalTarget && target.isValidFor(provider)) {
          return const ActionPolicyDecision(PolicyDecision.allowed, PolicyReason.officialHandoff);
        }
        if (target is AffiliateExternalTarget && target.isValidFor(provider)) {
          return const ActionPolicyDecision(PolicyDecision.allowed, PolicyReason.affiliateHandoff);
        }
      }
      return const ActionPolicyDecision(PolicyDecision.denied, PolicyReason.invalidTarget);
    }

    if (const {AccessAction.buy, AccessAction.rent}.contains(action)) {
      if (!provider.capabilities.contains(ProviderCapability.availabilityOffers) ||
          target is! LicensedAcquisitionTarget ||
          target.providerId != provider.id ||
          target.productId.trim().isEmpty ||
          target.offerId.trim().isEmpty) {
        return const ActionPolicyDecision(PolicyDecision.denied, PolicyReason.invalidTarget);
      }
      if (approval == null) return const ActionPolicyDecision(PolicyDecision.unknown, PolicyReason.missingApproval);
      if (!approval.validUntil.isAfter(now)) {
        return const ActionPolicyDecision(PolicyDecision.denied, PolicyReason.expiredApproval);
      }
      return approval.allows(
            providerId: provider.id,
            action: action,
            channel: channel,
            countryCode: countryCode,
            entityKind: entityKind,
            now: now,
          )
          ? const ActionPolicyDecision(PolicyDecision.allowed, PolicyReason.approvedCommerce)
          : const ActionPolicyDecision(PolicyDecision.denied, PolicyReason.scopeMismatch);
    }

    return const ActionPolicyDecision(PolicyDecision.unknown, PolicyReason.missingApproval);
  }
}

final _providerId = RegExp(r'^[a-z0-9][a-z0-9._-]{0,63}$');
final _namespace = RegExp(r'^[a-z0-9][a-z0-9._:-]{0,63}$');
final _credentialParameter = RegExp(
  r'(token|password|signature|credential|authorization|secret|api[_-]?key|^auth$|^key$|^code$|x-amz-|x-goog-)',
  caseSensitive: false,
);

bool _hasCredentialQuery(Uri uri) => uri.queryParameters.keys.any(_credentialParameter.hasMatch);

bool _safeIdentifier(String value) =>
    value.trim().isNotEmpty && value.length <= 512 && !value.contains(RegExp(r'[\x00-\x1f\x7f]'));

bool _validHost(String host) {
  final normalized = host.toLowerCase();
  final uri = Uri.tryParse('https://$normalized/');
  return uri != null &&
      uri.host == normalized &&
      !normalized.startsWith('.') &&
      !normalized.endsWith('.') &&
      !normalized.contains('..') &&
      !normalized.contains('@');
}
