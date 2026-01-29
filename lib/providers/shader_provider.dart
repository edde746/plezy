import 'package:flutter/foundation.dart';

import '../models/shader_preset.dart';
import '../services/settings_service.dart';

/// Provider for managing shader preset state.
///
/// Persists the selected shader preset so it is restored across sessions.
class ShaderProvider extends ChangeNotifier {
  late SettingsService _settingsService;

  ShaderPreset _savedPreset = ShaderPreset.none;
  ShaderPreset _currentPreset = ShaderPreset.none;
  bool _initialized = false;

  ShaderProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _settingsService = await SettingsService.getInstance();

    final presetId = _settingsService.getGlobalShaderPreset();
    _savedPreset = ShaderPreset.fromId(presetId) ?? ShaderPreset.none;
    _currentPreset = _savedPreset;

    _initialized = true;
    notifyListeners();
  }

  /// Whether the provider has finished initializing
  bool get initialized => _initialized;

  /// The persisted shader preset
  ShaderPreset get savedPreset => _savedPreset;

  /// The currently active shader preset
  ShaderPreset get currentPreset => _currentPreset;

  /// All available shader presets
  List<ShaderPreset> get allPresets => ShaderPreset.allPresets;

  /// Whether any shader is currently enabled
  bool get isShaderEnabled => _currentPreset.type != ShaderPresetType.none;

  /// Apply and persist a shader preset
  Future<void> setPreset(ShaderPreset preset) async {
    _savedPreset = preset;
    _currentPreset = preset;
    await _settingsService.setGlobalShaderPreset(preset.id);
    notifyListeners();
  }

  /// Update the current preset without persisting (e.g. toggling off temporarily)
  void setCurrentPreset(ShaderPreset preset) {
    if (_currentPreset.id != preset.id) {
      _currentPreset = preset;
      notifyListeners();
    }
  }

  /// Reset to default (no shaders)
  Future<void> reset() async {
    await setPreset(ShaderPreset.none);
  }
}
