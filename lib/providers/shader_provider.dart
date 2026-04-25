import 'package:flutter/foundation.dart';

import '../mixins/disposable_change_notifier_mixin.dart';
import '../models/shader_preset.dart';
import '../services/settings_service.dart';
import '../services/shader_asset_loader.dart';

/// Provider for managing shader preset state.
///
/// Persists the selected shader preset so it is restored across sessions.
class ShaderProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  late SettingsService _settingsService;

  ShaderPreset _savedPreset = ShaderPreset.none;
  ShaderPreset _currentPreset = ShaderPreset.none;
  List<ShaderPreset> _customPresets = [];
  bool _initialized = false;

  ShaderProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _settingsService = await SettingsService.getInstance();

    // Load custom presets from storage
    final customData = _settingsService.read(SettingsService.customShaderPresets);
    _customPresets = customData.map((json) => ShaderPreset.fromJson(json)).toList();

    final presetId = _settingsService.read(SettingsService.globalShaderPreset);
    _savedPreset = findPresetById(presetId) ?? ShaderPreset.none;
    _currentPreset = _savedPreset;

    _initialized = true;
    safeNotifyListeners();
  }

  /// Whether the provider has finished initializing
  bool get initialized => _initialized;

  /// The persisted shader preset
  ShaderPreset get savedPreset => _savedPreset;

  /// The currently active shader preset
  ShaderPreset get currentPreset => _currentPreset;

  /// All available shader presets (built-in + custom)
  List<ShaderPreset> get allPresets => [...ShaderPreset.allPresets, ..._customPresets];

  /// Custom shader presets only
  List<ShaderPreset> get customPresets => _customPresets;

  /// Whether any shader is currently enabled
  bool get isShaderEnabled => _currentPreset.type != ShaderPresetType.none;

  /// Find a preset by its ID, searching both built-in and custom presets.
  ShaderPreset? findPresetById(String id) {
    return ShaderPreset.fromId(id) ??
        _customPresets.cast<ShaderPreset?>().firstWhere((p) => p!.id == id, orElse: () => null);
  }

  /// Apply and persist a shader preset
  Future<void> setPreset(ShaderPreset preset) async {
    _savedPreset = preset;
    _currentPreset = preset;
    await _settingsService.write(SettingsService.globalShaderPreset, preset.id);
    safeNotifyListeners();
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
  Future<ShaderPreset> importCustomShader(String filePath, String displayName) async {
    final storedFileName = await ShaderAssetLoader.importCustomShader(filePath);
    final id = 'custom_$storedFileName';

    final preset = ShaderPreset(id: id, name: displayName, type: ShaderPresetType.custom, fileName: storedFileName);

    _customPresets.add(preset);
    await _saveCustomPresets();
    safeNotifyListeners();
    return preset;
  }

  /// Delete a custom shader preset and its file.
  Future<void> deleteCustomShader(ShaderPreset preset) async {
    if (preset.fileName != null) {
      await ShaderAssetLoader.deleteCustomShader(preset.fileName!);
    }
    _customPresets.removeWhere((p) => p.id == preset.id);
    await _saveCustomPresets();

    // Reset to none if the deleted preset was active
    if (_currentPreset.id == preset.id || _savedPreset.id == preset.id) {
      _savedPreset = ShaderPreset.none;
      _currentPreset = ShaderPreset.none;
      await _settingsService.write(SettingsService.globalShaderPreset, ShaderPreset.none.id);
    }

    safeNotifyListeners();
  }

  Future<void> _saveCustomPresets() async {
    final data = _customPresets.map((p) => p.toJson()).toList();
    await _settingsService.write(SettingsService.customShaderPresets, data);
  }

  /// Reset to default (no shaders)
  Future<void> reset() async {
    await setPreset(ShaderPreset.none);
  }
}
