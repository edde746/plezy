import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/main.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/credential_vault.dart';
import 'package:plezy/services/prefs_recovery.dart';
import 'package:plezy/services/seerr/seerr_session_store.dart';
import 'package:plezy/services/sensitive_prefs.dart';
import 'package:plezy/services/startup_diagnostics.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:plezy/services/trackers/tracker_account_store.dart';
import 'package:plezy/services/trackers/tracker_constants.dart';

import '../test_helpers/prefs.dart';

/// A stored value whose type no longer matches its declaration used to escape
/// as a raw `TypeError`. Inside the startup gate that failed the whole launch
/// with no indication of which preference was at fault (#1732).
void main() {
  group('ordinary preferences', () {
    test('a wrong stored type falls back to the declared default', () async {
      // `enable_debug_logging` is a BoolPref read by the very first gate step.
      resetSharedPreferencesForTest(initialAsync: {'enable_debug_logging': 'yes'});
      final settings = await SettingsService.getInstance();

      expect(settings.read(SettingsService.enableDebugLogging), isFalse);
    });

    test('the unreadable key is dropped so the next launch starts clean', () async {
      resetSharedPreferencesForTest(initialAsync: {'enable_debug_logging': 'yes'});
      final settings = await SettingsService.getInstance();

      settings.read(SettingsService.enableDebugLogging);
      // The removal is deliberately fire-and-forget; let it land.
      await Future<void>.delayed(Duration.zero);

      expect(settings.prefs.containsKey('enable_debug_logging'), isFalse);
    });

    test('a readable value is returned unchanged', () async {
      resetSharedPreferencesForTest(initialAsync: {'enable_debug_logging': true});
      final settings = await SettingsService.getInstance();

      expect(settings.read(SettingsService.enableDebugLogging), isTrue);
    });
  });

  group('credential preferences', () {
    // Silently discarding a credential would sign the user out with no
    // explanation, so every credential family has to reach the repair prompt
    // instead of being dropped or mistaken for "not set".

    test('the legacy Plex slot fails the storage step so the gate offers a repair', () async {
      // `StorageService.onInit` primes log redaction from this slot, so an
      // unreadable value fails a fatal gate step rather than being dropped.
      resetSharedPreferencesForTest(initialAsync: {legacyPlexTokenPref: 42});

      await expectLater(
        StorageService.getInstance(),
        throwsA(isA<UnreadableSensitivePreferenceException>().having((e) => e.key, 'key', legacyPlexTokenPref)),
      );

      // Still present: only an explicit, consented repair may remove it.
      final prefs = await BaseSharedPreferencesService.sharedCache();
      expect(prefs.containsKey(legacyPlexTokenPref), isTrue);
    });

    test('the gate classifies an unreadable credential as repairable', () async {
      final record = describeStartupFailure(
        const StartupPhaseException(StartupPhase.storage, _FakeUnreadable()),
        StackTrace.empty,
      );
      expect(record.repairable, isFalse, reason: 'sanity: an unrelated error is not repairable');

      final real = describeStartupFailure(
        StartupPhaseException(
          StartupPhase.storage,
          UnreadableSensitivePreferenceException(credentialVaultKeyPref, TypeError()),
        ),
        StackTrace.empty,
      );
      expect(real.repairable, isTrue);
      expect(real.phase, StartupPhase.storage);
    });

    test('the credential-vault key surfaces instead of being silently replaced', () async {
      // The dangerous outcome is not an exception: it is treating an
      // unreadable key as "no key yet", generating a fresh one and orphaning
      // every token stored as ciphertext in the database.
      resetSharedPreferencesForTest(initialAsync: {credentialVaultKeyPref: 1234});
      CredentialVault.resetKeyForTesting();
      addTearDown(CredentialVault.resetKeyForTesting);

      await expectLater(
        CredentialVault.protect('anything'),
        throwsA(isA<UnreadableSensitivePreferenceException>().having((e) => e.key, 'key', credentialVaultKeyPref)),
      );

      final prefs = await BaseSharedPreferencesService.sharedCache();
      expect(prefs.containsKey(credentialVaultKeyPref), isTrue);
    });

    test('every credential family fails settings init, where the repair prompt lives', () async {
      // The stores themselves are consulted long after startup, so a throw
      // there would be an unhandled provider error rather than a repair
      // prompt. `SettingsService.getInstance()` is a fatal gate step.
      final families = {
        'vault key': credentialVaultKeyPref,
        'tracker session': profileScopedPrefsKey('abc', 'trakt_session'),
        'seerr session': profileScopedPrefsKey('abc', seerrSessionBaseKey),
      };

      for (final entry in families.entries) {
        resetSharedPreferencesForTest(initialAsync: {entry.value: 7});
        await expectLater(
          SettingsService.getInstance(),
          throwsA(isA<UnreadableSensitivePreferenceException>().having((e) => e.key, 'key', entry.value)),
          reason: entry.key,
        );
      }
    });

    test('the stores themselves still refuse to guess', () async {
      final trackerKey = profileScopedPrefsKey('abc', 'trakt_session');
      resetSharedPreferencesForTest(initialAsync: {trackerKey: 7});
      await expectLater(
        trackerAccountStore(TrackerService.trakt).load('abc'),
        throwsA(isA<UnreadableSensitivePreferenceException>().having((e) => e.key, 'key', trackerKey)),
      );

      // `SeerrSessionStore.load` wraps decoding in a catch-all that returns
      // null; the read has to sit outside it or the credential vanishes with
      // no prompt at all.
      final seerrKey = profileScopedPrefsKey('abc', seerrSessionBaseKey);
      resetSharedPreferencesForTest(initialAsync: {seerrKey: 7});
      await expectLater(
        const SeerrSessionStore().load('abc'),
        throwsA(isA<UnreadableSensitivePreferenceException>().having((e) => e.key, 'key', seerrKey)),
      );
    });

    test('a readable credential is returned untouched', () async {
      resetSharedPreferencesForTest(initialAsync: {legacyPlexTokenPref: 'a-real-token'});
      final storage = await StorageService.getInstance();

      expect(storage.readNullableString(legacyPlexTokenPref), 'a-real-token');
    });
  });
}

/// Stands in for an error the in-app repair cannot address.
class _FakeUnreadable implements Exception {
  const _FakeUnreadable();
}
