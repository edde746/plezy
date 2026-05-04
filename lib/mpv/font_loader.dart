import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../utils/app_logger.dart';

/// Extracts font files from Flutter assets to the cache directory for
/// comprehensive Unicode coverage (including CJK characters) for libass subtitles.
class SubtitleFontLoader {
  static const String _fontAssetPath = 'assets/go-noto-current-regular.ttf';
  static const String _fontName = 'Go Noto Current-Regular';

  /// In-memory cache of the resolved font directory. The filesystem work
  /// (temp dir lookup, existence checks, asset extraction) is idempotent per
  /// process — caching the result skips ~20ms on every subsequent Player
  /// instantiation.
  static Future<String?>? _cachedFontDir;

  static Future<String?> loadSubtitleFont() {
    return _cachedFontDir ??= _loadSubtitleFontOnce();
  }

  static Future<String?> _loadSubtitleFontOnce() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final fontDir = Directory(path.join(cacheDir.path, 'subtitle_fonts'));

      if (!await fontDir.exists()) {
        await fontDir.create(recursive: true);
      }

      final fontFile = File(path.join(fontDir.path, 'go-noto-current-regular.ttf'));

      if (!await fontFile.exists()) {
        final fontData = await rootBundle.load(_fontAssetPath);
        await fontFile.writeAsBytes(fontData.buffer.asUint8List());
      }

      return fontDir.path;
    } catch (e, st) {
      appLogger.w('Failed to load subtitle font', error: e, stackTrace: st);
      return null;
    }
  }

  static String get fontName => _fontName;

  static String get fontAssetPath => _fontAssetPath;
}
