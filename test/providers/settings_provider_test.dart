import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/providers/settings_provider.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/prefs.dart';

void main() {
  setUp(resetSharedPreferencesForTest);

  group('SettingsProvider', () {
    test('starts uninitialized and exposes defaults', () {
      final p = SettingsProvider();
      expect(p.isInitialized, isFalse);
      expect(p.isReady, isFalse);
      // Pre-init getters fall back to declared defaults.
      expect(p.libraryDensity, LibraryDensity.defaultValue);
      expect(p.viewMode, ViewMode.grid);
      expect(p.episodePosterMode, EpisodePosterMode.episodeThumbnail);
      expect(p.showHeroSection, isTrue);
      expect(p.useGlobalHubs, isTrue);
      expect(p.showServerNameOnHubs, isFalse);
      expect(p.hideSpoilers, isFalse);
      expect(p.defaultQualityPreset, TranscodeQualityPreset.original);
      p.dispose();
    });

    test('ensureInitialized completes and flips isInitialized', () async {
      final p = SettingsProvider();
      expect(p.isInitialized, isFalse);
      await p.ensureInitialized();
      expect(p.isInitialized, isTrue);
      expect(p.isReady, isTrue);
      p.dispose();
    });

    test('setLibraryDensity clamps and persists', () async {
      final p = SettingsProvider();
      await p.ensureInitialized();

      var notified = 0;
      p.addListener(() => notified++);

      // Above max → clamped to max.
      await p.setLibraryDensity(LibraryDensity.max + 5);
      expect(p.libraryDensity, LibraryDensity.max);
      expect(notified, 1);

      // Below min → clamped to min.
      await p.setLibraryDensity(LibraryDensity.min - 5);
      expect(p.libraryDensity, LibraryDensity.min);
      expect(notified, 2);

      // Verify persisted directly via the service.
      final svc = await SettingsService.getInstance();
      expect(svc.read(SettingsService.libraryDensity), LibraryDensity.min);

      p.dispose();
    });

    test('setShowHeroSection toggles, notifies, and is a no-op for same value', () async {
      final p = SettingsProvider();
      await p.ensureInitialized();

      var notified = 0;
      p.addListener(() => notified++);

      expect(p.showHeroSection, isTrue);
      await p.setShowHeroSection(false);
      expect(p.showHeroSection, isFalse);
      expect(notified, 1);

      // Same value → no notify.
      await p.setShowHeroSection(false);
      expect(notified, 1);

      // Flip back → notify again.
      await p.setShowHeroSection(true);
      expect(p.showHeroSection, isTrue);
      expect(notified, 2);

      p.dispose();
    });

    test('setDefaultQualityPreset round-trips through TranscodeQualityPreset', () async {
      final p = SettingsProvider();
      await p.ensureInitialized();

      await p.setDefaultQualityPreset(TranscodeQualityPreset.p1080_10mbps);
      expect(p.defaultQualityPreset, TranscodeQualityPreset.p1080_10mbps);

      // Verify the underlying string storage uses the storageKey.
      final svc = await SettingsService.getInstance();
      expect(svc.read(SettingsService.defaultQualityPreset), TranscodeQualityPreset.p1080_10mbps.storageKey);

      // Round-trip a different preset.
      await p.setDefaultQualityPreset(TranscodeQualityPreset.p720_2mbps);
      expect(p.defaultQualityPreset, TranscodeQualityPreset.p720_2mbps);

      p.dispose();
    });

    test('setViewMode persists enum by name', () async {
      final p = SettingsProvider();
      await p.ensureInitialized();

      expect(p.viewMode, ViewMode.grid);
      await p.setViewMode(ViewMode.list);
      expect(p.viewMode, ViewMode.list);

      final svc = await SettingsService.getInstance();
      expect(svc.read(SettingsService.viewMode), ViewMode.list);

      p.dispose();
    });

    test('reload re-reads after external mutation', () async {
      final p = SettingsProvider();
      await p.ensureInitialized();
      expect(p.hideSpoilers, isFalse);

      // Mutate via the service directly (simulates an import / reset).
      final svc = await SettingsService.getInstance();
      await svc.write(SettingsService.hideSpoilers, true);

      var notified = 0;
      p.addListener(() => notified++);

      await p.reload();
      expect(p.hideSpoilers, isTrue);
      expect(notified, 1);

      p.dispose();
    });

    test('persists across provider instances via SharedPreferences', () async {
      final first = SettingsProvider();
      await first.ensureInitialized();
      await first.setShowNavBarLabels(false);
      await first.setLibraryDensity(5);
      first.dispose();

      // Reset only the cached singleton — backing store is preserved.
      BaseSharedPreferencesService.resetForTesting();

      final second = SettingsProvider();
      await second.ensureInitialized();
      expect(second.showNavBarLabels, isFalse);
      expect(second.libraryDensity, 5);
      second.dispose();
    });

    test('safeNotifyListeners no-ops after dispose', () async {
      final p = SettingsProvider();
      await p.ensureInitialized();
      p.dispose();
      // Should not throw — reload calls safeNotifyListeners under the hood.
      await p.reload();
    });
  });
}
