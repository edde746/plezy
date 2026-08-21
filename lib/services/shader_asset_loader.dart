import 'dart:async' show unawaited;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/shader_preset.dart';
import '../utils/app_logger.dart';

/// Utility class for loading GLSL shader assets for MPV video enhancement.
///
/// Extracts shader files from Flutter assets to the app's cache directory
/// where MPV can access them at runtime.
class ShaderAssetLoader {
  static const String _shaderAssetBase = 'assets/shaders';
  static String? _cachedShaderDir;
  static final RegExp _customShaderFileNamePattern = RegExp(r'^[A-Za-z0-9-]+\.glsl$', caseSensitive: false);
  static final Map<String, String> _verifiedBuiltInShaderPaths = {};
  static final Map<String, Future<String?>> _inFlightBuiltInShaders = {};
  static int _cacheGeneration = 0;

  /// NVScaler shader file
  static const String _nvscalerShader = 'nvscaler/NVScaler.glsl';

  /// ArtCNN shader files organized by preset model and variant.
  static const Map<String, String> _artcnnShaders = {
    'c4f16_neutral': 'artcnn/ArtCNN_C4F16.glsl',
    'c4f16_dn': 'artcnn/ArtCNN_C4F16_DN.glsl',
    'c4f16_ds': 'artcnn/ArtCNN_C4F16_DS.glsl',
    'c4f32_neutral': 'artcnn/ArtCNN_C4F32.glsl',
    'c4f32_dn': 'artcnn/ArtCNN_C4F32_DN.glsl',
    'c4f32_ds': 'artcnn/ArtCNN_C4F32_DS.glsl',
  };

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

  /// Get the application-owned shader cache directory, creating it if needed.
  static Future<String> _getShaderDirectory() async {
    if (_cachedShaderDir != null) return _cachedShaderDir!;

    final cacheDir = await getApplicationCacheDirectory();
    final shaderDir = Directory(path.join(cacheDir.path, 'shaders'));
    if (!await shaderDir.exists()) {
      await shaderDir.create(recursive: true);
    }

    _cachedShaderDir = shaderDir.path;
    return shaderDir.path;
  }

  /// Extract a single shader file from assets to the cache directory.
  /// Returns the absolute file path of the extracted shader.
  static Future<String?> _extractShader(String assetPath) {
    final generation = _cacheGeneration;
    final operationKey = '$generation:$assetPath';
    final active = _inFlightBuiltInShaders[operationKey];
    if (active != null) return active;

    final operation = _materializeBuiltInShader(assetPath, generation);
    _inFlightBuiltInShaders[operationKey] = operation;
    unawaited(
      operation.whenComplete(() {
        if (identical(_inFlightBuiltInShaders[operationKey], operation)) {
          _inFlightBuiltInShaders.remove(operationKey);
        }
      }),
    );
    return operation;
  }

  static Future<String?> _materializeBuiltInShader(String assetPath, int generation) async {
    File? pendingFile;
    try {
      final verifiedPath = _verifiedBuiltInShaderPaths[assetPath];
      if (verifiedPath != null) {
        if (await File(verifiedPath).exists()) return verifiedPath;
        _verifiedBuiltInShaderPaths.remove(assetPath);
      }

      final shaderDir = await _getShaderDirectory();
      final targetDir = Directory(path.join(shaderDir, path.dirname(assetPath)));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      final targetFile = File(path.join(targetDir.path, path.basename(assetPath)));
      final data = await rootBundle.load('$_shaderAssetBase/$assetPath');
      final bundledBytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      if (await _fileMatches(targetFile, bundledBytes)) {
        if (generation == _cacheGeneration) {
          _verifiedBuiltInShaderPaths[assetPath] = targetFile.path;
        }
        return targetFile.path;
      }

      pendingFile = File('${targetFile.path}.pending.${const Uuid().v4()}');
      await pendingFile.writeAsBytes(bundledBytes, flush: true);
      if (!await _promotePendingShader(pendingFile, targetFile, bundledBytes)) {
        return null;
      }
      if (!await _fileMatches(targetFile, bundledBytes)) return null;

      if (generation == _cacheGeneration) {
        _verifiedBuiltInShaderPaths[assetPath] = targetFile.path;
      }
      return targetFile.path;
    } catch (e, st) {
      appLogger.w('Failed to extract shader $assetPath', error: e, stackTrace: st);
      return null;
    } finally {
      if (pendingFile != null) {
        try {
          if (await pendingFile.exists()) await pendingFile.delete();
        } on FileSystemException {
          // The pending path is never returned and can be reclaimed with cache.
        }
      }
    }
  }

  static Future<bool> _promotePendingShader(File pendingFile, File targetFile, List<int> bundledBytes) async {
    try {
      await pendingFile.rename(targetFile.path);
      return true;
    } on FileSystemException {
      if (await _fileMatches(targetFile, bundledBytes)) return true;
    }

    try {
      if (await targetFile.exists()) await targetFile.delete();
      await pendingFile.rename(targetFile.path);
      return true;
    } on FileSystemException {
      return _fileMatches(targetFile, bundledBytes);
    }
  }

  static Future<bool> _fileMatches(File file, List<int> expected) async {
    try {
      if (!await file.exists()) return false;
      final actual = await file.readAsBytes();
      if (actual.length != expected.length) return false;
      for (var index = 0; index < expected.length; index++) {
        if (actual[index] != expected[index]) return false;
      }
      return true;
    } on FileSystemException {
      return false;
    }
  }

  /// Get the shader file paths for NVScaler preset.
  /// Returns a list containing the single NVScaler shader path.
  static Future<List<String>> getNVScalerShaders() async {
    final shaderPath = await _extractShader(_nvscalerShader);
    if (shaderPath == null) return [];
    return [shaderPath];
  }

  /// Get the shader file path for an ArtCNN preset.
  /// Returns a list containing exactly one ArtCNN shader path.
  static Future<List<String>> getArtCNNShaders(ArtCNNConfig config) async {
    final shaderPath = await _extractShader(_artcnnShaders['${config.model.name}_${config.variant.slug}']!);
    if (shaderPath == null) return [];
    return [shaderPath];
  }

  /// Get the shader file paths for an Anime4K preset.
  /// Returns a list of shader paths in the correct order for MPV.
  static Future<List<String>> getAnime4KShaders(Anime4KConfig config) async {
    final (restoreVariant, upscaleVariant) = switch (config.quality) {
      Anime4KQuality.fast => ('restore_m', 'upscale_m'),
      Anime4KQuality.hq => ('restore_vl', 'upscale_vl'),
    };

    // All modes start with Clamp, then apply their own ordered chain.
    final chain = <String>[
      'clamp',
      ...switch (config.mode) {
        Anime4KMode.modeA => [restoreVariant],
        Anime4KMode.modeB => [restoreVariant, upscaleVariant, 'downscale'],
        Anime4KMode.modeC => [upscaleVariant, 'downscale'],
        Anime4KMode.modeAA => [restoreVariant, restoreVariant],
        Anime4KMode.modeBB => [restoreVariant, restoreVariant, upscaleVariant, 'downscale'],
        Anime4KMode.modeCA => [upscaleVariant, restoreVariant, 'downscale'],
      },
    ];

    final shaders = <String>[];
    final extracted = <String, String?>{};
    for (final key in chain) {
      if (!extracted.containsKey(key)) {
        extracted[key] = await _extractShader(_anime4kShaders[key]!);
      }
      final shaderPath = extracted[key];
      if (shaderPath != null) shaders.add(shaderPath);
    }

    return shaders;
  }

  /// Whether [fileName] is a direct managed GLSL shader basename.
  ///
  /// UUID names generated by current builds and alphanumeric names generated
  /// by older builds are both accepted.
  static bool isValidCustomShaderFileName(String fileName) {
    return _customShaderFileNamePattern.hasMatch(fileName);
  }

  /// Get the custom shader directory path, creating it if necessary.
  /// Uses app support directory (persistent) rather than temp/cache.
  static Future<String> _getCustomShaderDirectory() async {
    final supportDir = await getApplicationSupportDirectory();
    final customDir = Directory(path.join(supportDir.path, 'custom_shaders'));

    if (!await customDir.exists()) {
      await customDir.create(recursive: true);
    }

    return customDir.path;
  }

  /// Import a custom shader file into the custom shaders directory.
  /// Returns the stored file name (UUID-based to avoid collisions).
  static Future<String> importCustomShader(String sourcePath) async {
    if (path.extension(sourcePath).toLowerCase() != '.glsl') {
      throw ArgumentError.value(sourcePath, 'sourcePath', 'Custom shaders must use the .glsl extension');
    }

    final customDir = await _getCustomShaderDirectory();
    final storedName = '${const Uuid().v4()}.glsl';
    await File(sourcePath).copy(path.join(customDir, storedName));
    return storedName;
  }

  /// Delete a custom shader file from the custom shaders directory.
  static Future<void> deleteCustomShader(String fileName) async {
    final file = await _resolveManagedCustomShaderFile(fileName);
    if (file != null && await file.exists()) {
      await file.delete();
    }
  }

  static Future<File?> _resolveManagedCustomShaderFile(String fileName) async {
    if (!isValidCustomShaderFileName(fileName)) return null;

    final customDir = path.canonicalize(await _getCustomShaderDirectory());
    final candidate = path.canonicalize(path.join(customDir, fileName));
    if (!path.equals(path.dirname(candidate), customDir)) return null;
    return File(candidate);
  }

  /// Get shader paths for a given preset.
  /// Returns an empty list for ShaderPresetType.none.
  static Future<List<String>> getShadersForPreset(ShaderPreset preset) async {
    switch (preset.type) {
      case ShaderPresetType.none:
        return [];
      case ShaderPresetType.nvscaler:
        return getNVScalerShaders();
      case ShaderPresetType.artcnn:
        if (preset.artcnnConfig == null) return [];
        return getArtCNNShaders(preset.artcnnConfig!);
      case ShaderPresetType.anime4k:
        if (preset.anime4kConfig == null) return [];
        return getAnime4KShaders(preset.anime4kConfig!);
      case ShaderPresetType.custom:
        final fileName = preset.fileName;
        if (fileName == null) return [];
        final shaderFile = await _resolveManagedCustomShaderFile(fileName);
        if (shaderFile == null || !await shaderFile.exists()) return [];
        return [shaderFile.path];
    }
  }

  /// Clear cached shader directory reference.
  /// Call when clearing app cache.
  static void clearCache() {
    _cacheGeneration++;
    _cachedShaderDir = null;
    _verifiedBuiltInShaderPaths.clear();
  }
}
