import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../focus/focusable_button.dart';
import '../i18n/strings.g.dart';
import '../integrations/integration_contracts.dart';
import '../integrations/integration_preferences_store.dart';
import '../profiles/active_profile_provider.dart';
import '../services/book_identifiers.dart';
import '../services/comic_commerce_link_client.dart';
import '../services/external_access_directory.dart';
import '../utils/snackbar_helper.dart';
import 'app_icon.dart';
import 'connector_brand_mark.dart';

/// Title-aware comic storefront actions embedded in the existing publication
/// detail. The local Read action remains the primary action; these links never
/// claim that an issue is available, owned, or included in a subscription.
class ComicCommerceSection extends StatefulWidget {
  const ComicCommerceSection({super.key, required this.title, this.creator = '', this.identifiers = const {}});

  final String title;
  final String creator;
  final Map<String, String> identifiers;

  @override
  State<ComicCommerceSection> createState() => _ComicCommerceSectionState();
}

class _ComicCommerceSectionState extends State<ComicCommerceSection> {
  static const _supportedCountries = {
    'AE',
    'AU',
    'BE',
    'BR',
    'CA',
    'DE',
    'EG',
    'ES',
    'FR',
    'GB',
    'IE',
    'IN',
    'IT',
    'JP',
    'MX',
    'NL',
    'PL',
    'SA',
    'SE',
    'SG',
    'TR',
    'US',
  };
  static const _featuredIds = ['globalcomix', 'drive-thru-comics', 'renta-comics', 'gumroad-comics'];
  static const _isbnProviders = {'ebooks-comics', 'bookshop-comics', 'kobo-comics'};

  final IntegrationPreferencesStore _preferences = IntegrationPreferencesStore();
  final ComicCommerceLinkClient _commerceLinks = ComicCommerceLinkClient();
  String? _profileId;
  String _countryCode = 'CA';
  Set<String> _preferredProviderIds = const {};
  bool _dependenciesInitialized = false;
  bool _opening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profileId = Provider.of<ActiveProfileProvider?>(context)?.activeId;
    if (_dependenciesInitialized && profileId == _profileId) return;
    _dependenciesInitialized = true;
    _profileId = profileId;
    _countryCode = _defaultCountryCode();
    _preferredProviderIds = const {};
    unawaited(_loadPreferences(profileId));
  }

  String _defaultCountryCode() {
    final localeCountry = Localizations.localeOf(context).countryCode?.toUpperCase();
    return _supportedCountries.contains(localeCountry) ? localeCountry! : 'CA';
  }

  Future<void> _loadPreferences(String? profileId) async {
    if (profileId == null) return;
    try {
      final preference = await _preferences.load(profileId);
      if (!mounted || _profileId != profileId) return;
      setState(() {
        _countryCode = _supportedCountries.contains(preference.countryCode)
            ? preference.countryCode!
            : _defaultCountryCode();
        _preferredProviderIds = preference.preferredProviderIds.toSet();
      });
    } on Object {
      // A missing or unreadable preference leaves the local, country-aware
      // storefront handoff usable with the locale default.
    }
  }

  List<ExternalAccessDestination> _orderedDestinations() {
    final destinations = ExternalAccessDirectory.forCategory(ExternalAccessCategory.comics).toList();
    destinations.sort((a, b) {
      final aPreferred = _preferredProviderIds.contains(a.id);
      final bPreferred = _preferredProviderIds.contains(b.id);
      if (aPreferred != bPreferred) return aPreferred ? -1 : 1;
      final aFeatured = _featuredIds.indexOf(a.id);
      final bFeatured = _featuredIds.indexOf(b.id);
      final aRank = aFeatured < 0 ? _featuredIds.length : aFeatured;
      final bRank = bFeatured < 0 ? _featuredIds.length : bFeatured;
      if (aRank != bRank) return aRank.compareTo(bRank);
      return a.name.compareTo(b.name);
    });
    return destinations;
  }

  Future<void> _open(ExternalAccessDestination destination) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final region = _countryCode;
      final uri = destination.searchUri(
        widget.title,
        creator: widget.creator,
        region: region,
        identifiers: widget.identifiers,
      );
      final provider = destination.integrationDefinition(region.toLowerCase());
      final officialTarget = OfficialExternalTarget(providerId: destination.id, uri: uri);
      final decision = ActionPolicyEvaluator.evaluate(
        provider: provider,
        target: officialTarget,
        action: AccessAction.open,
        channel: DistributionChannel.unknown,
        countryCode: region,
        entityKind: IntegrationEntityKind.comicIssue,
        now: DateTime.now(),
      );
      if (decision.decision != PolicyDecision.allowed) {
        showErrorSnackBar(context, t.common.error);
        return;
      }

      var launchUri = uri;
      final commerceProviderId = destination.commerceProviderId;
      if (commerceProviderId != null) {
        final tracked = await _commerceLinks.resolve(
          providerId: commerceProviderId,
          destination: uri,
          isbn: _isbnProviders.contains(commerceProviderId) ? BookIdentifiers.preferred(widget.identifiers) : null,
        );
        if (!mounted) return;
        if (tracked != null) {
          final affiliateTarget = AffiliateExternalTarget(providerId: destination.id, uri: tracked);
          final affiliateDecision = ActionPolicyEvaluator.evaluate(
            provider: provider,
            target: affiliateTarget,
            action: AccessAction.open,
            channel: DistributionChannel.unknown,
            countryCode: region,
            entityKind: IntegrationEntityKind.comicIssue,
            now: DateTime.now(),
          );
          if (affiliateDecision.decision == PolicyDecision.allowed) launchUri = tracked;
        }
      }

      try {
        if (await launchUrl(launchUri, mode: LaunchMode.externalApplication)) return;
      } catch (_) {
        // Keep the app's existing error feedback for missing platform handlers.
      }
      if (mounted) showErrorSnackBar(context, t.common.error);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Widget _storeButton(ExternalAccessDestination destination) => FocusableButton(
    onPressed: _opening ? null : () => unawaited(_open(destination)),
    child: OutlinedButton.icon(
      onPressed: _opening ? null : () => unawaited(_open(destination)),
      icon: ConnectorBrandMark(providerId: destination.id, name: destination.name, size: 20),
      label: Text(t.explore.detail.openOn(site: destination.name)),
    ),
  );

  @override
  void dispose() {
    _commerceLinks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destinations = _orderedDestinations();
    if (destinations.isEmpty) return const SizedBox.shrink();
    final featuredCount = destinations.length < _featuredIds.length ? destinations.length : _featuredIds.length;
    final featured = destinations.take(featuredCount).toList(growable: false);
    final remaining = destinations.skip(featuredCount).toList(growable: false);

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.explore.detail.links, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final destination in featured) _storeButton(destination)]),
          if (remaining.isNotEmpty)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text(t.common.viewAll, style: theme.textTheme.bodyMedium),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final destination in remaining) _storeButton(destination)],
                ),
              ],
            ),
          if (destinations.any((destination) => destination.commerceProviderId != null))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                t.services.commissionDisclosure,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}
