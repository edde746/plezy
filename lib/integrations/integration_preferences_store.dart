import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../profiles/profile.dart';
import '../services/base_shared_preferences_service.dart';
import '../utils/serial_future_queue.dart';

/// User-declared service choices. These are relevance hints only; they never
/// verify a subscription, ownership, loan or provider entitlement.
class IntegrationPreferences {
  const IntegrationPreferences({
    this.countryCode,
    this.preferredProviderIds = const [],
    this.subscriptionTiers = const {},
  });

  final String? countryCode;
  final List<String> preferredProviderIds;
  final Map<String, String> subscriptionTiers;

  bool get isValid =>
      (countryCode == null || RegExp(r'^[A-Z]{2}$').hasMatch(countryCode!)) &&
      preferredProviderIds.length <= 100 &&
      preferredProviderIds.toSet().length == preferredProviderIds.length &&
      preferredProviderIds.every(_providerId.hasMatch) &&
      subscriptionTiers.length <= 100 &&
      subscriptionTiers.entries.every(
        (entry) => _providerId.hasMatch(entry.key) && _validText(entry.value, maxLength: 80),
      );

  IntegrationPreferences copyWith({String? countryCode, bool clearCountryCode = false}) => IntegrationPreferences(
    countryCode: clearCountryCode ? null : countryCode ?? this.countryCode,
    preferredProviderIds: preferredProviderIds,
    subscriptionTiers: subscriptionTiers,
  );

  Map<String, Object?> toJson() => {
    'version': 1,
    'countryCode': countryCode,
    'preferredProviderIds': preferredProviderIds,
    'subscriptionTiers': subscriptionTiers,
  };

  static IntegrationPreferences? fromJson(Object? value) {
    if (value is! Map) return null;
    final json = Map<String, dynamic>.from(value);
    if (json['version'] != 1) return null;
    final tiers = json['subscriptionTiers'];
    final parsed = IntegrationPreferences(
      countryCode: json['countryCode'] as String?,
      preferredProviderIds: json['preferredProviderIds'] is List
          ? (json['preferredProviderIds'] as List).whereType<String>().toList(growable: false)
          : const [],
      subscriptionTiers: tiers is Map
          ? {
              for (final entry in tiers.entries)
                if (entry.key is String && entry.value is String) entry.key as String: entry.value as String,
            }
          : const {},
    );
    return parsed.isValid ? parsed : null;
  }
}

/// Profile-scoped, non-secret service preferences. Account credentials belong
/// in a service owner backed by CredentialVault, never in this store.
class IntegrationPreferencesStore {
  IntegrationPreferencesStore({this.cacheLoader = BaseSharedPreferencesService.sharedCache});

  static const _baseKey = 'integration_preferences_v1';
  static final _persistence = SerialFutureQueue();
  static final _providerId = RegExp(r'^[a-z0-9][a-z0-9._-]{0,63}$');

  final Future<SharedPreferencesWithCache> Function() cacheLoader;

  String keyForProfile(String profileId) => profileScopedPrefsKey(profileId, _baseKey);

  Future<IntegrationPreferences> load(String profileId) => _persistence.run(() async {
    final prefs = await cacheLoader();
    return _decode(prefs.getString(keyForProfile(profileId)));
  });

  Future<IntegrationPreferences> setCountryCode(String profileId, String? countryCode) => _persistence.run(() async {
    final normalized = countryCode?.trim().toUpperCase();
    if (normalized != null && !RegExp(r'^[A-Z]{2}$').hasMatch(normalized)) {
      throw ArgumentError.value(countryCode, 'countryCode', 'Expected a two-letter country code.');
    }
    final prefs = await cacheLoader();
    final current = _decode(prefs.getString(keyForProfile(profileId)));
    final updated = current.copyWith(countryCode: normalized, clearCountryCode: normalized == null);
    await _write(prefs, profileId, updated);
    return updated;
  });

  Future<IntegrationPreferences> setPreferredProvider(String profileId, String providerId, {required bool preferred}) =>
      _persistence.run(() async {
        if (!_providerId.hasMatch(providerId)) throw ArgumentError.value(providerId, 'providerId');
        final prefs = await cacheLoader();
        final current = _decode(prefs.getString(keyForProfile(profileId)));
        final providers = current.preferredProviderIds.toSet();
        if (preferred) {
          providers.add(providerId);
        } else {
          providers.remove(providerId);
        }
        final updated = IntegrationPreferences(
          countryCode: current.countryCode,
          preferredProviderIds: providers.toList()..sort(),
          subscriptionTiers: current.subscriptionTiers,
        );
        await _write(prefs, profileId, updated);
        return updated;
      });

  Future<IntegrationPreferences> setSubscriptionTier(String profileId, String providerId, String? tier) =>
      _persistence.run(() async {
        if (!_providerId.hasMatch(providerId)) throw ArgumentError.value(providerId, 'providerId');
        final normalizedTier = tier?.trim();
        if (normalizedTier != null && !_validText(normalizedTier, maxLength: 80)) {
          throw ArgumentError.value(tier, 'tier');
        }
        final prefs = await cacheLoader();
        final current = _decode(prefs.getString(keyForProfile(profileId)));
        final tiers = Map<String, String>.of(current.subscriptionTiers);
        if (normalizedTier == null || normalizedTier.isEmpty) {
          tiers.remove(providerId);
        } else {
          tiers[providerId] = normalizedTier;
        }
        final updated = IntegrationPreferences(
          countryCode: current.countryCode,
          preferredProviderIds: current.preferredProviderIds,
          subscriptionTiers: tiers,
        );
        await _write(prefs, profileId, updated);
        return updated;
      });

  Future<void> clearForProfile(String profileId) => _persistence.run(() async {
    final prefs = await cacheLoader();
    await prefs.remove(keyForProfile(profileId));
  });

  IntegrationPreferences _decode(String? raw) {
    if (raw == null) return const IntegrationPreferences();
    try {
      return IntegrationPreferences.fromJson(jsonDecode(raw)) ?? const IntegrationPreferences();
    } on Object {
      return const IntegrationPreferences();
    }
  }

  Future<void> _write(SharedPreferencesWithCache prefs, String profileId, IntegrationPreferences value) async {
    if (!value.isValid) throw StateError('Refusing to persist invalid integration preferences.');
    await prefs.setString(keyForProfile(profileId), jsonEncode(value.toJson()));
  }
}

bool _validText(String value, {required int maxLength}) =>
    value.trim().isNotEmpty && value.length <= maxLength && !value.contains(RegExp(r'[\x00-\x1f\x7f]'));

final _providerId = RegExp(r'^[a-z0-9][a-z0-9._-]{0,63}$');
