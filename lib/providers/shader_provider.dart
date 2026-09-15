import 'dart:async' show unawaited;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../mixins/disposable_change_notifier_mixin.dart';
import '../models/shader_preset.dart';
import '../services/settings_binding_owner.dart';
import '../services/settings_service.dart';
import '../services/shader_asset_loader.dart';

class ShaderProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  late final SettingsBindingOwner _settingsBinding;

  ShaderPreset _savedPreset = ShaderPreset.none;
  ShaderPreset _currentPreset = ShaderPreset.none;
  List<ShaderPreset> _customPresets = [];
  List<ShaderPreset> _allPresets = ShaderPreset.allPresets;
  bool _initialized = false;

  ShaderProvider() {
    _settingsBinding = SettingsBindingOwner(
      prefs: [SettingsService.globalShaderPreset, SettingsService.customShaderPresets],
      onRefresh: _syncFromSettings,
    );
    unawaited(_settingsBinding.bind());
  }

  void _syncFromSettings(SettingsService service) {
    final customPresets = <ShaderPreset>[];
    for (final json in service.read(SettingsService.customShaderPresets)) {
      try {
        final preset = ShaderPreset.fromJson(json);
        final fileName = preset.fileName;
        if (preset.type == ShaderPresetType.custom &&
            fileName != null &&
            ShaderAssetLoader.isValidCustomShaderFileName(fileName)) {
          customPresets.add(preset);
        }
      } on Object {
        // Imported settings can contain structurally invalid custom rows.
      }
    }
    _customPresets = customPresets;
    _refreshAllPresets();

    final presetId = service.read(SettingsService.globalShaderPreset);
    _savedPreset = findPresetById(presetId) ?? ShaderPreset.none;
    _currentPreset = _savedPreset;

    _initialized = true;
    safeNotifyListeners();
  }

  @override
  void dispose() {
    _settingsBinding.dispose();
    super.dispose();
  }

  bool get initialized => _initialized;
  ShaderPreset get savedPreset => _savedPreset;
  ShaderPreset get currentPreset => _currentPreset;
  List<ShaderPreset> get allPresets => _allPresets;
  List<ShaderPreset> get customPresets => _customPresets;
  bool get isShaderEnabled => _currentPreset.type != ShaderPresetType.none;

  ShaderPreset? findPresetById(String id) {
    return ShaderPreset.fromId(id) ?? _customPresets.firstWhereOrNull((p) => p.id == id);
  }

  Future<void> setPreset(ShaderPreset preset, {void Function()? checkCurrent, bool reset = false}) async {
    final service = _settingsBinding.settings ?? await SettingsService.getInstance();
    checkCurrent?.call();
    if (reset) {
      await service.reset(SettingsService.globalShaderPreset, checkCurrent: checkCurrent);
    } else {
      await service.write(SettingsService.globalShaderPreset, preset.id, checkCurrent: checkCurrent);
    }
    checkCurrent?.call();
    if (_settingsBinding.settings == null) {
      _syncFromSettings(service);
    } else if (_currentPreset.id != _savedPreset.id) {
      // Re-selecting the saved ID does not emit a preference notification.
      _currentPreset = _savedPreset;
      safeNotifyListeners();
    }
  }

  /// Update the current preset without persisting (e.g. toggling off temporarily)
  void setCurrentPreset(ShaderPreset preset) {
    if (_currentPreset.id != preset.id) {
      _currentPreset = preset;
      notifyListeners();
    }
  }

  /// Import a custom shader from a file path.
  /// Copies the file to the custom shaders directory and creates a preset.
  Future<ShaderPreset> importCustomShader(String filePath, String displayName, {void Function()? checkCurrent}) async {
    if (displayName.trim().isEmpty) throw const FormatException('A shader name is required');
    checkCurrent?.call();
    final storedFileName = await ShaderAssetLoader.importCustomShader(filePath, checkCurrent: checkCurrent);
    try {
      checkCurrent?.call();
      final preset = ShaderPreset(
        id: 'custom_$storedFileName',
        name: displayName.trim(),
        type: ShaderPresetType.custom,
        fileName: storedFileName,
      );
      final service = _settingsBinding.settings ?? await SettingsService.getInstance();
      checkCurrent?.call();
      await service.write(SettingsService.customShaderPresets, [
        ...service.read(SettingsService.customShaderPresets),
        preset.toJson(),
      ], checkCurrent: checkCurrent);
      checkCurrent?.call();
      if (_settingsBinding.settings == null) _syncFromSettings(service);
      return preset;
    } catch (_) {
      // The generated file belongs to this import alone. Do not remove it if
      // persistence succeeded and only the caller's lifetime changed afterward.
      final service = SettingsService.instance;
      if (!service.read(SettingsService.customShaderPresets).any((p) => p['fileName'] == storedFileName)) {
        await ShaderAssetLoader.deleteCustomShader(storedFileName);
      }
      rethrow;
    }
  }

  /// Delete a custom shader preset and its file.
  Future<void> deleteCustomShader(ShaderPreset preset, {void Function()? checkCurrent}) async {
    if (preset.type != ShaderPresetType.custom || !_customPresets.any((p) => p.id == preset.id)) {
      throw const FormatException('Unknown custom shader');
    }
    final service = _settingsBinding.settings ?? await SettingsService.getInstance();
    checkCurrent?.call();
    if (_currentPreset.id == preset.id || _savedPreset.id == preset.id) {
      await setPreset(ShaderPreset.none, checkCurrent: checkCurrent);
    }
    checkCurrent?.call();
    await service.write(SettingsService.customShaderPresets, [
      for (final item in service.read(SettingsService.customShaderPresets))
        if (item['id'] != preset.id) item,
    ], checkCurrent: checkCurrent);
    checkCurrent?.call();
    if (preset.fileName != null) {
      await ShaderAssetLoader.deleteCustomShader(preset.fileName!, checkCurrent: checkCurrent);
    }
    checkCurrent?.call();
    if (_settingsBinding.settings == null) _syncFromSettings(service);
  }

  void _refreshAllPresets() {
    _allPresets = _customPresets.isEmpty
        ? ShaderPreset.allPresets
        : List.unmodifiable([...ShaderPreset.allPresets, ..._customPresets]);
  }

  /// Reset to default (no shaders)
  Future<void> reset() async {
    await setPreset(ShaderPreset.none);
  }
}
