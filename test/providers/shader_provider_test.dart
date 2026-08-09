import 'dart:io';

import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/shader_preset.dart';
import 'package:plezy/providers/shader_provider.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/settings_export_service.dart';

import '../test_helpers/io_fakes.dart';
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

    test('setPreset restores current when saved preset id is unchanged', () async {
      final p = ShaderProvider();
      await Future.delayed(Duration.zero);
      final saved = ShaderPreset.anime4kPreset(Anime4KQuality.fast, Anime4KMode.modeA);

      await p.setPreset(saved);
      p.setCurrentPreset(ShaderPreset.none);
      expect(p.savedPreset, saved);
      expect(p.currentPreset, ShaderPreset.none);

      await p.setPreset(saved);
      expect(p.savedPreset, saved);
      expect(p.currentPreset, saved);

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

    test('reuses the unmodifiable built-in catalog when no custom presets exist', () async {
      final p = ShaderProvider();
      await Future.delayed(Duration.zero);

      expect(identical(p.allPresets, ShaderPreset.allPresets), isTrue);
      expect(identical(p.allPresets, p.allPresets), isTrue);
      expect(() => p.allPresets.add(ShaderPreset.none), throwsUnsupportedError);
      p.dispose();
    });

    test('refreshes a stable merged catalog when custom presets change', () async {
      final originalPathProvider = PathProviderPlatform.instance;
      final root = await Directory.systemTemp.createTemp('plezy_shader_provider_test_');
      PathProviderPlatform.instance = FakePathProvider(root);
      addTearDown(() async {
        PathProviderPlatform.instance = originalPathProvider;
        if (await root.exists()) await root.delete(recursive: true);
      });
      final source = File(path.join(root.path, 'custom.glsl'))..writeAsStringSync('shader');
      final p = ShaderProvider();
      addTearDown(p.dispose);
      await Future.delayed(Duration.zero);
      final builtIns = p.allPresets;

      final custom = await p.importCustomShader(source.path, 'Custom');
      final merged = p.allPresets;
      expect(identical(merged, builtIns), isFalse);
      expect(identical(merged, p.allPresets), isTrue);
      expect(merged.last, custom);
      expect(() => merged.removeLast(), throwsUnsupportedError);

      await p.deleteCustomShader(custom);
      expect(p.findPresetById(custom.id), isNull);
      expect(identical(p.allPresets, ShaderPreset.allPresets), isTrue);
    });

    test('filters unsafe persisted custom shader rows and invalid saved selection', () async {
      const valid = ShaderPreset(
        id: 'custom_ks9p7.glsl',
        name: 'Legacy',
        type: ShaderPresetType.custom,
        fileName: 'ks9p7.glsl',
      );
      const unsafeRows = [
        ShaderPreset(
          id: 'custom_traversal',
          name: 'Traversal',
          type: ShaderPresetType.custom,
          fileName: '../sentinel.glsl',
        ),
        ShaderPreset(
          id: 'custom_nested',
          name: 'Nested',
          type: ShaderPresetType.custom,
          fileName: 'nested/shader.glsl',
        ),
        ShaderPreset(
          id: 'custom_wrong_type',
          name: 'Wrong type',
          type: ShaderPresetType.custom,
          fileName: 'shader.txt',
        ),
      ];
      final svc = await SettingsService.getInstance();
      await svc.write(SettingsService.customShaderPresets, [valid.toJson(), ...unsafeRows.map((row) => row.toJson())]);
      await svc.write(SettingsService.globalShaderPreset, unsafeRows.first.id);

      final p = ShaderProvider();
      await Future.delayed(Duration.zero);

      expect(p.customPresets, [valid]);
      expect(p.findPresetById(unsafeRows.first.id), isNull);
      expect(p.savedPreset, ShaderPreset.none);
      expect(p.currentPreset, ShaderPreset.none);
      p.dispose();
    });

    test('portable settings import cannot expose an unsafe custom shader row', () async {
      const unsafe = ShaderPreset(
        id: 'custom_imported_traversal',
        name: 'Imported traversal',
        type: ShaderPresetType.custom,
        fileName: '../sentinel.glsl',
      );
      final prefs = await BaseSharedPreferencesService.sharedCache();
      final result = await SettingsExportService.applyImportMap(
        {
          'formatVersion': SettingsExportService.formatVersion,
          'prefs': {
            'custom_shader_presets': {
              'type': 'string',
              'value': jsonEncode([unsafe.toJson()]),
            },
          },
        },
        prefs,
        currentUserUuid: 'profile',
      );
      expect(result.keysImported, 0);
      final svc = await SettingsService.getInstance();
      await svc.write(SettingsService.globalShaderPreset, unsafe.id);

      final p = ShaderProvider();
      await Future.delayed(Duration.zero);

      expect(p.customPresets, isEmpty);
      expect(p.findPresetById(unsafe.id), isNull);
      expect(p.savedPreset, ShaderPreset.none);
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
