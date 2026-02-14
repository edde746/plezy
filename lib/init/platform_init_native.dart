/// Native platform initialization.
///
/// Handles dart:io dependent initialization for Android, iOS, macOS, Windows, Linux.
library;

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../services/discord_rpc_service.dart';
import '../services/download_storage_service.dart';
import '../services/fullscreen_state_manager.dart';
import '../services/gamepad_service.dart';
import '../services/macos_titlebar_service.dart';
import '../services/pip_service.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';
import '../utils/language_codes.dart';
import '../utils/platform_detector.dart';

/// Initialize native platform-specific services.
Future<void> initializePlatform(SettingsService settings) async {
  final futures = <Future<void>>[];

  // Initialize window_manager for desktop platforms
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    futures.add(windowManager.ensureInitialized());
  }

  // Initialize TV detection and PiP service for Android
  if (Platform.isAndroid) {
    futures.add(TvDetectionService.getInstance().then((_) {}));
    PipService();
  }

  // Configure macOS window with custom titlebar
  futures.add(MacOSTitlebarService.setupCustomTitlebar());

  // Initialize storage service
  futures.add(StorageService.getInstance().then((_) {}));

  // Initialize language codes for track selection
  futures.add(LanguageCodes.initialize());

  // Wait for all parallel services to complete
  await Future.wait(futures);

  // Initialize download storage service with settings
  await DownloadStorageService.instance.initialize(settings);

  // Start global fullscreen state monitoring
  FullscreenStateManager().startMonitoring();

  // Initialize gamepad service for desktop platforms
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    GamepadService.instance.start();
    DiscordRPCService.instance.initialize();
  }
}

/// Configure image cache for native platforms.
void configureImageCache() {
  PaintingBinding.instance.imageCache.maximumSizeBytes = 200 << 20; // 200MB
}
