import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/integrations/integration_contracts.dart';
import 'package:plezy/integrations/integration_identity_store.dart';
import 'package:plezy/integrations/integration_preferences_store.dart';

import '../test_helpers/prefs.dart';

void main() {
  setUp(resetSharedPreferencesForTest);

  group('IntegrationPreferencesStore', () {
    test('isolates country, providers, and plan notes by profile and clears them', () async {
      final store = IntegrationPreferencesStore();

      await store.setCountryCode('profile-a', 'ca');
      await store.setPreferredProvider('profile-a', 'crave', preferred: true);
      await store.setSubscriptionTier('profile-a', 'crave', 'Premium');
      await store.setCountryCode('profile-b', 'US');

      final profileA = await store.load('profile-a');
      final profileB = await store.load('profile-b');
      expect(profileA.countryCode, 'CA');
      expect(profileA.preferredProviderIds, ['crave']);
      expect(profileA.subscriptionTiers, {'crave': 'Premium'});
      expect(profileB.countryCode, 'US');
      expect(profileB.preferredProviderIds, isEmpty);
      expect(profileB.subscriptionTiers, isEmpty);

      await store.clearForProfile('profile-a');
      _expectEmptyPreferences(await store.load('profile-a'));
      expect((await store.load('profile-b')).countryCode, 'US');
    });

    test('rejects malformed country, provider, and tier values before persistence', () async {
      final store = IntegrationPreferencesStore();

      await expectLater(store.setCountryCode('profile-a', 'Canada'), throwsArgumentError);
      await expectLater(store.setPreferredProvider('profile-a', '../private', preferred: true), throwsArgumentError);
      await expectLater(store.setSubscriptionTier('profile-a', 'crave', 'Premium\nsecret'), throwsArgumentError);
      _expectEmptyPreferences(await store.load('profile-a'));
    });
  });

  group('IntegrationIdentityStore', () {
    test('stores confirmed crosswalks by profile and removes them reversibly', () async {
      final store = IntegrationIdentityStore();
      final crosswalk = IdentityCrosswalk(
        id: 'crosswalk-1',
        from: const IntegrationEntityRef(
          providerId: 'catalog',
          nativeId: 'comic-12',
          kind: IntegrationEntityKind.comicIssue,
        ),
        to: const IntegrationEntityRef(
          providerId: 'local-library',
          nativeId: 'file-34',
          kind: IntegrationEntityKind.comicIssue,
        ),
        relation: EntityRelationKind.sameWork,
        method: IdentifierMatchMethod.userConfirmed,
        confirmedAt: DateTime.utc(2026, 10, 28),
      );

      await store.put('profile-a', crosswalk);

      final loaded = (await store.load('profile-a')).single;
      expect(loaded.id, crosswalk.id);
      expect(loaded.from.nativeId, crosswalk.from.nativeId);
      expect(loaded.to.nativeId, crosswalk.to.nativeId);
      expect(await store.load('profile-b'), isEmpty);
      await store.remove('profile-a', crosswalk.id);
      expect(await store.load('profile-a'), isEmpty);
    });

    test('does not persist suggestions or silently remap a confirmed source', () async {
      final store = IntegrationIdentityStore();
      IdentityCrosswalk row(
        String id,
        String destination, {
        IdentifierMatchMethod method = IdentifierMatchMethod.userConfirmed,
      }) => IdentityCrosswalk(
            id: id,
            from: const IntegrationEntityRef(
              providerId: 'catalog',
              nativeId: 'comic-12',
              kind: IntegrationEntityKind.comicIssue,
            ),
            to: IntegrationEntityRef(
              providerId: 'local-library',
              nativeId: destination,
              kind: IntegrationEntityKind.comicIssue,
            ),
            relation: EntityRelationKind.sameWork,
            method: method,
            confirmedAt: DateTime.utc(2026, 10, 28),
          );

      final suggestion = row('suggestion', 'file-1', method: IdentifierMatchMethod.suggested);
      expect(suggestion.isValid, isFalse);
      await store.put('profile-a', row('confirmed', 'file-1'));
      await expectLater(store.put('profile-a', row('replacement', 'file-2')), throwsStateError);
      expect((await store.load('profile-a')).single.to.nativeId, 'file-1');
    });
  });
}

void _expectEmptyPreferences(IntegrationPreferences preferences) {
  expect(preferences.countryCode, isNull);
  expect(preferences.preferredProviderIds, isEmpty);
  expect(preferences.subscriptionTiers, isEmpty);
}
