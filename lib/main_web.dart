/// Web/webOS-specific entry point initialization.
///
/// This file contains initialization logic that replaces dart:io
/// dependent code from main.dart for the web platform.
library;

import 'package:flutter/material.dart';
import 'services/settings_service.dart';
import 'services/storage_service.dart';
import 'services/webos_service.dart';
import 'utils/app_logger.dart';
import 'utils/language_codes.dart';
import 'i18n/strings.g.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Initialize web/webOS-specific services.
///
/// This replaces the native platform initialization in main.dart
/// that depends on dart:io (Platform.isAndroid, windowManager, etc.)
Future<void> initializeWebPlatform() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize settings
  final settings = await SettingsService.getInstance();
  final savedLocale = settings.getAppLocale();
  LocaleSettings.setLocale(savedLocale);
  await initializeDateFormatting(savedLocale.languageCode, null);

  // Configure image cache (lower for TV memory constraints)
  PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20; // 100MB

  // Initialize storage and language codes in parallel
  await Future.wait([
    StorageService.getInstance().then((_) {}),
    LanguageCodes.initialize(),
  ]);

  // Initialize logger
  final debugEnabled = settings.getEnableDebugLogging();
  setLoggerLevel(debugEnabled);

  // Initialize webOS service
  await WebOSService.instance.initialize();
}
