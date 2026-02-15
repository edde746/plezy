import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../utils/io_helpers.dart';

import '../models/shader_preset.dart';

/// Utility class for loading GLSL shader assets for MPV video enhancement.
///
/// Extracts shader files from Flutter assets to the app's cache directory
/// where MPV can access them at runtime.
class ShaderAssetLoader {
  static const String _shaderAssetBase = 'assets/shaders';
  static String? _cachedShaderDir;

  /// NVScaler shader file
  static const String _nvscalerShader = 'nvscaler/NVScaler.glsl';

  /// Anime4K shader files organized by function
  static const Map<String, String> _anime4kShaders = {
    'clamp': 'anime4k/Anime4K_Clamp_Highlights.glsl',
    'restore_m': 'anime4k/Anime4K_Restore_CNN_M.glsl',
    'restore_vl': 'anime4k/Anime4K_Restore_CNN_VL.glsl',
    'restore_ul': 'anime4k/Anime4K_Restore_CNN_UL.glsl',
    'upscale_m': 'anime4k/Anime4K_Upscale_CNN_x2_M.glsl',
    'upscale_vl': 'anime4k/Anime4K_Upscale_CNN_x2_VL.glsl',
    'upscale_ul': 'anime4k/Anime4K_Upscale_CNN_x2_UL.glsl',
    'downscale': 'anime4k/Anime4K_AutoDownscalePre_x2.glsl',
    'downscale_post': 'anime4k/Anime4K_AutoDownscalePre_x4.glsl',
  };

  /// Get the shader cache directory path, creating it if necessary.
  static Future<String> _getShaderDirectory() async {
    if (kIsWeb) throw UnsupportedError('Shaders not available on web');
    if (_cachedShaderDir != null) return _cachedShaderDir!;

    final cacheDir = await getTemporaryDirectory();
    final shaderDir = Directory(path.join(cacheDir.path, 'shaders'));

    if (!await shaderDir.exists()) {
      await shaderDir.create(recursive: true);
    }

    _cachedShaderDir = shaderDir.path;
    return shaderDir.path;
  }

  /// Extract a single shader file from assets to the cache directory.
  /// Returns the absolute file path of the extracted shader.
  static Future<String?> _extractShader(String assetPath) async {
    try {
      final shaderDir = await _getShaderDirectory();
      final fileName = path.basename(assetPath);
      final subDir = path.dirname(assetPath);

      // Create subdirectory if needed
      final targetDir = Directory(path.join(shaderDir, subDir));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final targetFile = File(path.join(targetDir.path, fileName));

      // Only extract if not already cached
      if (!await targetFile.exists()) {
        final fullAssetPath = '$_shaderAssetBase/$assetPath';
        final data = await rootBundle.load(fullAssetPath);
        await targetFile.writeAsBytes(data.buffer.asUint8List());
      }

      return targetFile.path;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to extract shader $assetPath: $e');
      }
      return null;
    }
  }

  /// Get the shader file paths for NVScaler preset.
  /// Returns a list containing the single NVScaler shader path.
  static Future<List<String>> getNVScalerShaders() async {
    final shaderPath = await _extractShader(_nvscalerShader);
    if (shaderPath == null) return [];
    return [shaderPath];
  }

  /// Get the shader file paths for an Anime4K preset.
  /// Returns a list of shader paths in the correct order for MPV.
  static Future<List<String>> getAnime4KShaders(Anime4KConfig config) async {
    final shaders = <String>[];
    final quality = config.quality;
    final mode = config.mode;

    // Get quality-specific shader variants
    String restoreVariant;
    String upscaleVariant;

    switch (quality) {
      case Anime4KQuality.fast:
        restoreVariant = 'restore_m';
        upscaleVariant = 'upscale_m';
        break;
      case Anime4KQuality.hq:
        restoreVariant = 'restore_vl';
        upscaleVariant = 'upscale_vl';
        break;
    }

    // Build shader chain based on mode
    // All modes start with Clamp
    final clampPath = await _extractShader(_anime4kShaders['clamp']!);
    if (clampPath != null) shaders.add(clampPath);

    switch (mode) {
      case Anime4KMode.modeA:
        // A: Clamp + Restore
        final restorePath = await _extractShader(_anime4kShaders[restoreVariant]!);
        if (restorePath != null) shaders.add(restorePath);
        break;

      case Anime4KMode.modeB:
        // B: Clamp + Restore + Upscale + Downscale
        final restorePath = await _extractShader(_anime4kShaders[restoreVariant]!);
        if (restorePath != null) shaders.add(restorePath);
        final upscalePath = await _extractShader(_anime4kShaders[upscaleVariant]!);
        if (upscalePath != null) shaders.add(upscalePath);
        final downscalePath = await _extractShader(_anime4kShaders['downscale']!);
        if (downscalePath != null) shaders.add(downscalePath);
        break;

      case Anime4KMode.modeC:
        // C: Clamp + Upscale + Downscale
        final upscalePath = await _extractShader(_anime4kShaders[upscaleVariant]!);
        if (upscalePath != null) shaders.add(upscalePath);
        final downscalePath = await _extractShader(_anime4kShaders['downscale']!);
        if (downscalePath != null) shaders.add(downscalePath);
        break;

      case Anime4KMode.modeAA:
        // A+A: Clamp + Restore + Restore
        final restorePath = await _extractShader(_anime4kShaders[restoreVariant]!);
        if (restorePath != null) {
          shaders.add(restorePath);
          shaders.add(restorePath); // Second restore pass
        }
        break;

      case Anime4KMode.modeBB:
        // B+B: Clamp + Restore + Restore + Upscale + Downscale
        final restorePath = await _extractShader(_anime4kShaders[restoreVariant]!);
        if (restorePath != null) {
          shaders.add(restorePath);
          shaders.add(restorePath); // Second restore pass
        }
        final upscalePath = await _extractShader(_anime4kShaders[upscaleVariant]!);
        if (upscalePath != null) shaders.add(upscalePath);
        final downscalePath = await _extractShader(_anime4kShaders['downscale']!);
        if (downscalePath != null) shaders.add(downscalePath);
        break;

      case Anime4KMode.modeCA:
        // C+A: Clamp + Upscale + Restore + Downscale
        final upscalePath = await _extractShader(_anime4kShaders[upscaleVariant]!);
        if (upscalePath != null) shaders.add(upscalePath);
        final restorePath = await _extractShader(_anime4kShaders[restoreVariant]!);
        if (restorePath != null) shaders.add(restorePath);
        final downscalePath = await _extractShader(_anime4kShaders['downscale']!);
        if (downscalePath != null) shaders.add(downscalePath);
        break;
    }

    return shaders;
  }

  /// Get shader paths for a given preset.
  /// Returns an empty list for ShaderPresetType.none.
  static Future<List<String>> getShadersForPreset(ShaderPreset preset) async {
    switch (preset.type) {
      case ShaderPresetType.none:
        return [];
      case ShaderPresetType.nvscaler:
        return getNVScalerShaders();
      case ShaderPresetType.anime4k:
        if (preset.anime4kConfig == null) return [];
        return getAnime4KShaders(preset.anime4kConfig!);
    }
  }

  /// Pre-extract all shader files to the cache.
  /// Call this at startup to avoid extraction delay during playback.
  static Future<void> preloadShaders() async {
    try {
      // Extract NVScaler
      await _extractShader(_nvscalerShader);

      // Extract all Anime4K shaders
      for (final shaderPath in _anime4kShaders.values) {
        await _extractShader(shaderPath);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to preload shaders: $e');
      }
    }
  }

  /// Clear cached shader directory reference.
  /// Call when clearing app cache.
  static void clearCache() {
    _cachedShaderDir = null;
  }
}
