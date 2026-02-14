/// Web/webOS platform initialization.
///
/// Handles initialization for web platforms without dart:io dependencies.
library;

import 'package:flutter/material.dart';

import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../services/webos_service.dart';
import '../utils/language_codes.dart';
import '../utils/platform_detector.dart';

/// Initialize web/webOS-specific services.
Future<void> initializePlatform(SettingsService settings) async {
  // Initialize TV detection for webOS
  await TvDetectionService.getInstance();

  // Initialize storage and language codes in parallel
  await Future.wait([
    StorageService.getInstance().then((_) {}),
    LanguageCodes.initialize(),
  ]);

  // Initialize webOS service
  await WebOSService.instance.initialize();
}

/// Configure image cache for web/TV platforms (lower memory).
void configureImageCache() {
  PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20; // 100MB for TV
}
