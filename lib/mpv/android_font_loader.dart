import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Utility class for loading font assets on Android for libass subtitle rendering.
///
/// On Android, libass cannot access system fonts through fontconfig, so we need
/// to extract font files from Flutter assets to the app's cache directory.
class AndroidFontLoader {
  static const String _fontAssetPath = 'assets/go-noto-current-regular.ttf';
  static const String _fontName = 'Go Noto Current-Regular';

  /// Loads the subtitle font from assets to the Android cache directory.
  /// Returns the directory path containing the font file.
  static Future<String?> loadSubtitleFont() async {
    try {
      // Get the app's cache directory
      final cacheDir = await getTemporaryDirectory();
      final fontDir = Directory(path.join(cacheDir.path, 'subtitle_fonts'));

      // Create fonts directory if it doesn't exist
      if (!await fontDir.exists()) {
        await fontDir.create(recursive: true);
      }

      final fontFile = File(
        path.join(fontDir.path, 'go-noto-current-regular.ttf'),
      );

      // Load font from assets and write to cache if it doesn't exist
      if (!await fontFile.exists()) {
        final fontData = await rootBundle.load(_fontAssetPath);
        await fontFile.writeAsBytes(fontData.buffer.asUint8List());
      }

      return fontDir.path;
    } catch (e) {
      // Return null if font loading fails - libass will fall back gracefully
      if (kDebugMode) {
        debugPrint('Failed to load subtitle font: $e');
      }
      return null;
    }
  }

  /// Returns the font name to be used with libass.
  static String get fontName => _fontName;

  /// Returns the font asset path.
  static String get fontAssetPath => _fontAssetPath;
}
