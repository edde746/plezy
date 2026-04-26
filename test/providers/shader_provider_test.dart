import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/shader_preset.dart';
import 'package:plezy/providers/shader_provider.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/prefs.dart';

void main() {
  setUp(resetSharedPreferencesForTest);

  group('ShaderProvider', () {
    test('starts uninitialized and exposes the none preset by default', () async {
      final p = ShaderProvider();
      expect(p.initialized, isFalse);
      expect(p.savedPreset, ShaderPreset.none);
      expect(p.currentPreset, ShaderPreset.none);
      expect(p.customPresets, isEmpty);
      expect(p.isShaderEnabled, isFalse);

      // Wait for the eager async _initialize() to finish.
      await Future.delayed(Duration.zero);
      expect(p.initialized, isTrue);
      expect(p.savedPreset, ShaderPreset.none);
      p.dispose();
    });

    test('allPresets exposes built-in presets and includes none + nvscaler', () async {
      final p = ShaderProvider();
      await Future.delayed(Duration.zero);

      // Built-ins should always be present even with no custom presets stored.
      final ids = p.allPresets.map((preset) => preset.id).toList();
      expect(ids, contains(ShaderPreset.none.id));
      expect(ids, contains(ShaderPreset.nvscalerDefault.id));
      expect(ids, contains('artcnn_c4f16_neutral'));
      expect(ids, contains('artcnn_c4f16_dn'));
      expect(ids, contains('artcnn_c4f16_ds'));
      expect(ids, contains('artcnn_c4f32_neutral'));
      expect(ids, contains('artcnn_c4f32_dn'));
      expect(ids, contains('artcnn_c4f32_ds'));
      expect(p.allPresets.length, ShaderPreset.allPresets.length);

      p.dispose();
    });

    test('setPreset persists, updates current/saved, and notifies', () async {
      final p = ShaderProvider();
      await Future.delayed(Duration.zero);

      var notified = 0;
      p.addListener(() => notified++);

      await p.setPreset(ShaderPreset.nvscalerDefault);
      expect(p.savedPreset, ShaderPreset.nvscalerDefault);
      expect(p.currentPreset, ShaderPreset.nvscalerDefault);
      expect(p.isShaderEnabled, isTrue);
      expect(notified, 1);

      // Verify persisted via the SettingsService directly.
      final svc = await SettingsService.getInstance();
      expect(svc.read(SettingsService.globalShaderPreset), ShaderPreset.nvscalerDefault.id);

      p.dispose();
    });

    test('setCurrentPreset updates current without persisting and is a no-op for same id', () async {
      final p = ShaderProvider();
      await Future.delayed(Duration.zero);
      await p.setPreset(ShaderPreset.nvscalerDefault);

      var notified = 0;
      p.addListener(() => notified++);

      // Toggle off transiently — saved should stay nvscaler, current goes none.
      p.setCurrentPreset(ShaderPreset.none);
      expect(p.currentPreset, ShaderPreset.none);
      expect(p.savedPreset, ShaderPreset.nvscalerDefault);
      expect(notified, 1);

      // Same id → no notify.
      p.setCurrentPreset(ShaderPreset.none);
      expect(notified, 1);

      // Persisted store should still hold nvscaler since we never called setPreset.
      final svc = await SettingsService.getInstance();
      expect(svc.read(SettingsService.globalShaderPreset), ShaderPreset.nvscalerDefault.id);

      p.dispose();
    });

    test('reset returns to the none preset', () async {
      final p = ShaderProvider();
      await Future.delayed(Duration.zero);
      await p.setPreset(ShaderPreset.nvscalerDefault);
      expect(p.isShaderEnabled, isTrue);

      await p.reset();
      expect(p.savedPreset, ShaderPreset.none);
      expect(p.currentPreset, ShaderPreset.none);
      expect(p.isShaderEnabled, isFalse);

      final svc = await SettingsService.getInstance();
      expect(svc.read(SettingsService.globalShaderPreset), ShaderPreset.none.id);

      p.dispose();
    });

    test('findPresetById returns built-in presets and null for unknown ids', () async {
      final p = ShaderProvider();
      await Future.delayed(Duration.zero);

      expect(p.findPresetById(ShaderPreset.nvscalerDefault.id), ShaderPreset.nvscalerDefault);
      expect(p.findPresetById(ShaderPreset.none.id), ShaderPreset.none);
      expect(p.findPresetById('not-a-real-preset'), isNull);

      p.dispose();
    });

    test('persists selected preset across provider instances via SharedPreferences', () async {
      final first = ShaderProvider();
      await Future.delayed(Duration.zero);
      await first.setPreset(ShaderPreset.nvscalerDefault);
      first.dispose();

      // Reset only the cached singleton — backing store is preserved.
      BaseSharedPreferencesService.resetForTesting();

      final second = ShaderProvider();
      await Future.delayed(Duration.zero);
      expect(second.savedPreset, ShaderPreset.nvscalerDefault);
      expect(second.currentPreset, ShaderPreset.nvscalerDefault);
      second.dispose();
    });

    test('initializes from a previously persisted preset id', () async {
      // Pre-populate the persisted preset id before the provider boots.
      final svc = await SettingsService.getInstance();
      await svc.write(SettingsService.globalShaderPreset, ShaderPreset.nvscalerDefault.id);

      final p = ShaderProvider();
      await Future.delayed(Duration.zero);
      expect(p.savedPreset, ShaderPreset.nvscalerDefault);
      expect(p.currentPreset, ShaderPreset.nvscalerDefault);

      p.dispose();
    });

    test('safeNotifyListeners no-ops after dispose', () async {
      final p = ShaderProvider();
      await Future.delayed(Duration.zero);
      p.dispose();
      // Should not throw — setPreset calls safeNotifyListeners under the hood.
      await p.setPreset(ShaderPreset.none);
    });
  });
}
