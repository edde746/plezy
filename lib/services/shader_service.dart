import 'package:flutter/foundation.dart';

import '../models/shader_preset.dart';
import '../mpv/player/player.dart';
import 'ambient_lighting_service.dart';
import 'shader_asset_loader.dart';

/// Service for applying GLSL shaders to the MPV video player.
///
/// Handles shader chain building, HDR detection, and runtime switching.
/// When ambient lighting is active, the ambient lighting shader is always appended last
/// in the chain after any upscaling/processing shaders.
class ShaderService {
  final Player _player;
  ShaderPreset _currentPreset = ShaderPreset.none;

  /// Reference to ambient lighting service for re-appending its shader after chain rebuilds.
  AmbientLightingService? ambientLightingService;

  ShaderService(this._player);

  /// The currently applied shader preset
  ShaderPreset get currentPreset => _currentPreset;

  /// Check if the player is MPV (shaders are MPV-only)
  bool get isSupported => _player.playerType == 'mpv';

  /// Apply a shader preset to the video player.
  ///
  /// For NVScaler with auto-HDR skip enabled, will check video colorspace
  /// and skip shader application for HDR content.
  Future<void> applyPreset(ShaderPreset preset) async {
    if (!isSupported) {
      if (kDebugMode) {
        debugPrint('ShaderService: Shaders not supported on ${_player.playerType}');
      }
      return;
    }

    try {
      // Handle NVScaler HDR auto-skip
      if (preset.type == ShaderPresetType.nvscaler && preset.nvscalerConfig?.autoHdrSkip == true) {
        final isHdr = await _isHdrContent();
        if (isHdr) {
          if (kDebugMode) {
            debugPrint('ShaderService: Skipping NVScaler on HDR content');
          }
          await _clearShaders();
          _currentPreset = ShaderPreset.none;
          await _reappendAmbientLighting();
          return;
        }
      }

      // Get shader paths for the preset
      final shaderPaths = await ShaderAssetLoader.getShadersForPreset(preset);

      if (shaderPaths.isEmpty) {
        // No shaders - clear any existing ones
        await _clearShaders();
        _currentPreset = preset;
        await _reappendAmbientLighting();
        return;
      }

      // Clear existing shaders first
      await _clearShaders();

      // Apply new shader chain
      for (final shaderPath in shaderPaths) {
        await _player.command(['change-list', 'glsl-shaders', 'append', shaderPath]);
      }

      _currentPreset = preset;

      // Re-append ambient lighting shader at end of chain
      await _reappendAmbientLighting();

      if (kDebugMode) {
        debugPrint('ShaderService: Applied ${preset.name} with ${shaderPaths.length} shaders');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ShaderService: Failed to apply preset: $e');
      }
      // Don't rethrow - shader failure shouldn't stop playback
    }
  }

  /// Clear all currently applied shaders.
  Future<void> _clearShaders() async {
    try {
      await _player.command(['change-list', 'glsl-shaders', 'clr', '']);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ShaderService: Failed to clear shaders: $e');
      }
    }
  }

  /// Re-append the ambient lighting shader if it's active.
  /// Called after shader chain rebuilds to keep ambient lighting last.
  Future<void> _reappendAmbientLighting() async {
    final service = ambientLightingService;
    if (service == null || !service.isEnabled) return;

    try {
      await service.reappendShader();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ShaderService: Failed to re-append ambient lighting: $e');
      }
    }
  }

  /// Check if the current video content is HDR.
  Future<bool> _isHdrContent() async {
    try {
      // Check video color matrix for BT.2020 (HDR indicator)
      final colormatrix = await _player.getProperty('video-params/colormatrix');
      if (colormatrix?.contains('bt.2020') == true) {
        return true;
      }

      // Also check color primaries
      final primaries = await _player.getProperty('video-params/primaries');
      if (primaries?.contains('bt.2020') == true) {
        return true;
      }

      // Check for HDR transfer characteristics
      final gamma = await _player.getProperty('video-params/gamma');
      if (gamma?.contains('pq') == true || gamma?.contains('hlg') == true) {
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ShaderService: HDR detection failed: $e');
      }
      return false;
    }
  }

  /// Disable all shaders.
  Future<void> disable() async {
    await applyPreset(ShaderPreset.none);
  }

  /// Cycle to the next preset in the available list.
  Future<ShaderPreset> cyclePreset() async {
    final presets = ShaderPreset.allPresets;
    final currentIndex = presets.indexWhere((p) => p.id == _currentPreset.id);
    final nextIndex = (currentIndex + 1) % presets.length;
    final nextPreset = presets[nextIndex];

    await applyPreset(nextPreset);
    return nextPreset;
  }

  /// Reapply current preset (useful after video source changes).
  Future<void> reapply() async {
    if (_currentPreset.type != ShaderPresetType.none) {
      await applyPreset(_currentPreset);
    }
  }
}
