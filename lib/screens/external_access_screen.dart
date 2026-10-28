import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../focus/focusable_text_field.dart';
import '../i18n/strings.g.dart';
import '../integrations/integration_contracts.dart';
import '../integrations/integration_preferences_store.dart';
import '../profiles/active_profile_provider.dart';
import '../services/external_access_directory.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/app_icon.dart';
import '../widgets/focused_scroll_scaffold.dart';
import '../widgets/focusable_list_tile.dart';
import '../widgets/settings_section.dart';

/// Title-aware official-site handoff. Provider pages make the final offer,
/// territory, account and access decision; this screen never implies that a
/// title is available or that opening a destination changed library state.
class ExternalAccessScreen extends StatefulWidget {
  const ExternalAccessScreen({
    super.key,
    required this.title,
    this.creator = '',
    this.identifiers = const {},
    this.gamePlatformIds = const {},
    required this.categories,
  });

  final String title;
  final String creator;
  final Map<String, String> identifiers;
  final Map<String, String> gamePlatformIds;
  final List<ExternalAccessCategory> categories;

  @override
  State<ExternalAccessScreen> createState() => _ExternalAccessScreenState();
}

class _ExternalAccessScreenState extends State<ExternalAccessScreen> {
  static const _countryCodes = [
    'AE', 'AU', 'BE', 'BR', 'CA', 'DE', 'EG', 'ES', 'FR', 'GB', 'IE', 'IN', 'IT', 'JP', 'MX', 'NL', 'PL', 'SA',
    'SE', 'SG', 'TR', 'US',
  ];

  final TextEditingController _filter = TextEditingController();
  final IntegrationPreferencesStore _preferences = IntegrationPreferencesStore();
  String? _profileId;
  String? _countryCode;
  Set<String> _preferredProviderIds = const {};
  Map<String, String> _subscriptionTiers = const {};
  bool _savingCountry = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profileId = Provider.of<ActiveProfileProvider?>(context)?.activeId;
    if (profileId == _profileId) return;
    _profileId = profileId;
    _countryCode = _defaultCountryCode();
    _savingCountry = false;
    unawaited(_loadCountry(profileId));
  }

  String _defaultCountryCode() {
    final localeCountry = Localizations.localeOf(context).countryCode?.toUpperCase();
    return _countryCodes.contains(localeCountry) ? localeCountry! : 'CA';
  }

  Future<void> _loadCountry(String? profileId) async {
    if (profileId == null) {
      if (mounted) {
        setState(() {
          _countryCode = _defaultCountryCode();
          _preferredProviderIds = const {};
          _subscriptionTiers = const {};
        });
      }
      return;
    }
    try {
      final preference = await _preferences.load(profileId);
      if (!mounted || _profileId != profileId) return;
      setState(() {
        _countryCode = _countryCodes.contains(preference.countryCode) ? preference.countryCode : _defaultCountryCode();
        _preferredProviderIds = preference.preferredProviderIds.toSet();
        _subscriptionTiers = Map.unmodifiable(preference.subscriptionTiers);
      });
    } on Object {
      if (mounted && _profileId == profileId) {
        setState(() {
          _countryCode = _defaultCountryCode();
          _preferredProviderIds = const {};
          _subscriptionTiers = const {};
        });
      }
    }
  }

  Future<void> _setCountry(String countryCode) async {
    final profileId = _profileId;
    final old = _countryCode;
    setState(() {
      _countryCode = countryCode;
      _savingCountry = true;
    });
    try {
      if (profileId != null) await _preferences.setCountryCode(profileId, countryCode);
    } on Object {
      if (mounted && _profileId == profileId) {
        setState(() => _countryCode = old);
        showErrorSnackBar(context, t.common.error);
      }
    } finally {
      if (mounted && _profileId == profileId) setState(() => _savingCountry = false);
    }
  }

  Future<void> _setPreferred(String providerId, bool preferred) async {
    final profileId = _profileId;
    final previous = _preferredProviderIds;
    final next = Set<String>.of(previous);
    if (preferred) {
      next.add(providerId);
    } else {
      next.remove(providerId);
    }
    setState(() => _preferredProviderIds = next);
    try {
      if (profileId != null) {
        await _preferences.setPreferredProvider(profileId, providerId, preferred: preferred);
      }
    } on Object {
      if (mounted && _profileId == profileId) {
        setState(() => _preferredProviderIds = previous);
        showErrorSnackBar(context, t.common.error);
      }
    }
  }

  Future<void> _editTier(ExternalAccessDestination destination) async {
    final profileId = _profileId;
    if (profileId == null) return;
    final controller = TextEditingController(text: _subscriptionTiers[destination.id] ?? '');
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(destination.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Optional plan note. This is your label only; PlezyNG does not verify account access.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Plan label'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.common.cancel)),
          TextButton(onPressed: () => Navigator.pop(dialogContext, controller.text), child: Text(t.common.save)),
        ],
      ),
    );
    controller.dispose();
    if (value == null || !mounted || _profileId != profileId) return;
    final previous = _subscriptionTiers;
    final updated = Map<String, String>.of(previous);
    if (value.trim().isEmpty) {
      updated.remove(destination.id);
    } else {
      updated[destination.id] = value.trim();
    }
    setState(() => _subscriptionTiers = Map.unmodifiable(updated));
    try {
      await _preferences.setSubscriptionTier(profileId, destination.id, value);
    } on Object {
      if (mounted && _profileId == profileId) {
        setState(() => _subscriptionTiers = previous);
        showErrorSnackBar(context, t.common.error);
      }
    }
  }

  String _sectionLabel(ExternalAccessCategory category) => switch (category) {
    ExternalAccessCategory.video => t.explore.detail.watchOn,
    ExternalAccessCategory.rentals => t.explore.detail.links,
    ExternalAccessCategory.books => t.fileSources.read,
    ExternalAccessCategory.audiobooks => t.fileSources.listen,
    ExternalAccessCategory.comics => t.fileSources.read,
    ExternalAccessCategory.music => t.fileSources.listen,
    ExternalAccessCategory.games => t.games.title,
  };

  IconData _icon(ExternalAccessCategory category) => switch (category) {
    ExternalAccessCategory.video => Symbols.tv_rounded,
    ExternalAccessCategory.rentals => Symbols.shopping_bag_rounded,
    ExternalAccessCategory.books || ExternalAccessCategory.comics => Symbols.menu_book_rounded,
    ExternalAccessCategory.audiobooks || ExternalAccessCategory.music => Symbols.headphones_rounded,
    ExternalAccessCategory.games => Symbols.sports_esports_rounded,
  };

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  Future<void> _open(BuildContext context, ExternalAccessDestination destination) async {
    final region = _countryCode ?? _defaultCountryCode();
    final uri = destination.searchUri(
      widget.title,
      creator: widget.creator,
      region: region,
      identifiers: widget.identifiers,
      gamePlatformIds: widget.gamePlatformIds,
    );
    final provider = destination.integrationDefinition(region.toLowerCase());
    final target = OfficialExternalTarget(providerId: destination.id, uri: uri);
    final decision = ActionPolicyEvaluator.evaluate(
      provider: provider,
      target: target,
      action: AccessAction.open,
      channel: DistributionChannel.unknown,
      countryCode: region,
      entityKind: IntegrationEntityKind.unknown,
      now: DateTime.now(),
    );
    if (decision.decision != PolicyDecision.allowed) {
      showErrorSnackBar(context, t.common.error);
      return;
    }
    try {
      if (await launchUrl(target.uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Report the same recovery state for platform handlers and launch errors.
    }
    if (context.mounted) showErrorSnackBar(context, t.common.error);
  }

  @override
  Widget build(BuildContext context) {
    final query = _filter.text.trim().toLowerCase();
    final destinationsByCategory = {
      for (final category in widget.categories)
        category: ExternalAccessDirectory.forCategory(category)
            .where((destination) => destination.name.toLowerCase().contains(query))
            .toList(growable: false)
          ..sort((a, b) {
            final aPreferred = _preferredProviderIds.contains(a.id);
            final bPreferred = _preferredProviderIds.contains(b.id);
            if (aPreferred != bPreferred) return aPreferred ? -1 : 1;
            if (category == ExternalAccessCategory.video) {
              final aFreeAdSupported = a.accessModels.contains(ProviderAccessModel.freeAdSupported);
              final bFreeAdSupported = b.accessModels.contains(ProviderAccessModel.freeAdSupported);
              if (aFreeAdSupported != bFreeAdSupported) return aFreeAdSupported ? -1 : 1;
            }
            return a.name.compareTo(b.name);
          }),
    };
    final hasResults = destinationsByCategory.values.any((destinations) => destinations.isNotEmpty);
    return FocusedScrollScaffold(
      title: Text(t.explore.detail.links),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.title.trim().isNotEmpty)
                        Text(widget.title, style: Theme.of(context).textTheme.headlineSmall),
                      if (widget.creator.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(widget.creator, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),
                FocusableTextField(
                  controller: _filter,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: t.lending.search,
                    prefixIcon: const AppIcon(Symbols.search_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(_countryCode),
                  initialValue: _countryCode ?? _defaultCountryCode(),
                  decoration: InputDecoration(
                    labelText: t.explore.detail.country,
                    suffixIcon: _savingCountry
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : null,
                  ),
                  items: [for (final countryCode in _countryCodes) DropdownMenuItem(value: countryCode, child: Text(countryCode))],
                  onChanged: _savingCountry ? null : (countryCode) => countryCode == null ? null : _setCountry(countryCode),
                ),
                const SizedBox(height: 12),
                for (final category in widget.categories)
                  if (destinationsByCategory[category]!.isNotEmpty)
                    SettingsGroup(
                      title: _sectionLabel(category),
                      children: [
                        for (final destination in destinationsByCategory[category]!)
                          FocusableListTile(
                            leading: AppIcon(_icon(category)),
                            title: Text(destination.name),
                            subtitle: Text([
                              t.explore.detail.openOn(site: destination.name),
                              if (_subscriptionTiers[destination.id] case final tier?) 'Plan: $tier',
                            ].join(' · ')),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: _preferredProviderIds.contains(destination.id)
                                      ? t.accessibility.unfavorite
                                      : t.accessibility.favorite,
                                  onPressed: () => _setPreferred(
                                    destination.id,
                                    !_preferredProviderIds.contains(destination.id),
                                  ),
                                  icon: AppIcon(
                                    _preferredProviderIds.contains(destination.id)
                                        ? Symbols.star_rounded
                                        : Symbols.star_outline_rounded,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Set plan label',
                                  onPressed: () => unawaited(_editTier(destination)),
                                  icon: const AppIcon(Symbols.edit_rounded),
                                ),
                                const AppIcon(Symbols.open_in_new_rounded),
                              ],
                            ),
                            onTap: () => _open(context, destination),
                          ),
                      ],
                    ),
                if (!hasResults)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text(t.messages.noResultsFound)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
