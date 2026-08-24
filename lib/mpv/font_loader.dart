import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../utils/app_logger.dart';

/// Extracts font files from Flutter assets to the cache directory for
/// comprehensive Unicode coverage (including CJK and Hangul characters) for
/// libass subtitles.
///
/// GoNotoCurrent (the primary font) covers every common script except Korean,
/// and the Android libmpv build has no fontconfig/system-font fallback, so
/// libass can only find glyphs in this directory. The Hangul subset next to
/// it provides the missing syllables: generated from GoNotoKurrent-Regular
/// (satbyy/go-noto-universal v7.0) via fontTools.subset, keeping Hangul
/// Syllables, Jamo, compat Jamo, and common Hangul punctuation.
class SubtitleFontLoader {
  static const String _fontAssetPath = 'assets/go-noto-current-regular.ttf';
  static const String _fontName = 'Go Noto Current-Regular';

  /// Hangul-only subset of Go Noto Kurrent-Regular (see class docs).
  static const String _hangulFontAssetPath = 'assets/go-noto-kurrent-hangul.ttf';

  /// Font files extracted to the subtitle fonts directory, in extraction order.
  static const List<(String, String)> _fonts = [
    (_fontAssetPath, 'go-noto-current-regular.ttf'),
    (_hangulFontAssetPath, 'go-noto-kurrent-hangul.ttf'),
  ];

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

      for (final (assetPath, fileName) in _fonts) {
        final fontFile = File(path.join(fontDir.path, fileName));
        if (await fontFile.exists()) continue;
        final fontData = await rootBundle.load(assetPath);
        await fontFile.writeAsBytes(fontData.buffer.asUint8List());
      }

      return fontDir.path;
    } catch (e, st) {
      appLogger.w('Failed to load subtitle font', error: e, stackTrace: st);
      return null;
    }
  }

  static String get fontName => _fontName;
}
