import 'dart:io';

import 'package:auto_updater/auto_updater.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to check for new versions on GitHub
/// Only enabled when ENABLE_UPDATE_CHECK build flag is set
///
/// On macOS (non-Homebrew) and installed Windows: delegates to Sparkle/WinSparkle
/// via auto_updater for native update dialogs and in-app installs.
/// On all other platforms: falls back to GitHub API check + browser link dialog.
class UpdateService {
  static final Logger _logger = Logger();
  static const String _githubRepo = 'edde746/plezy';
  static const String _feedUrl = 'https://github.com/edde746/plezy/releases/latest/download/appcast.xml';

  // SharedPreferences keys
  static const String _keySkippedVersion = 'update_skipped_version';
  static const String _keyLastCheckTime = 'update_last_check_time';

  // Check cooldown: 6 hours
  static const Duration _checkCooldown = Duration(hours: 6);

  static bool _nativeUpdaterInitialized = false;

  /// Check if update checking is enabled via build flag
  static bool get isUpdateCheckEnabled {
    return const bool.fromEnvironment('ENABLE_UPDATE_CHECK', defaultValue: false);
  }

  /// Whether the native auto_updater (Sparkle/WinSparkle) should be used.
  /// True on macOS (non-Homebrew) and installed Windows (has uninstaller).
  static bool get useNativeUpdater {
    if (!isUpdateCheckEnabled) return false;
    if (Platform.isMacOS) return !_isHomebrewInstall();
    if (Platform.isWindows) return _isInstalledApp() && !_isWingetInstall();
    return false;
  }

  /// Initialize the native auto_updater (Sparkle/WinSparkle).
  /// Call once at startup if [useNativeUpdater] is true.
  static Future<void> initNativeUpdater() async {
    if (_nativeUpdaterInitialized) return;
    _nativeUpdaterInitialized = true;

    try {
      await autoUpdater.setFeedURL(_feedUrl);
      // 6 hours in seconds
      await autoUpdater.setScheduledCheckInterval(_checkCooldown.inSeconds);
    } catch (e) {
      _logger.e('Failed to initialize native auto updater: $e');
    }
  }

  /// Trigger a background update check via Sparkle/WinSparkle.
  /// Only shows UI if an update is found.
  static Future<void> checkForUpdatesNative({bool inBackground = true}) async {
    if (!_nativeUpdaterInitialized) await initNativeUpdater();
    try {
      await autoUpdater.checkForUpdates(inBackground: inBackground);
    } catch (e) {
      _logger.e('Native update check failed: $e');
    }
  }

  /// Check if the macOS app was installed via Homebrew.
  /// Homebrew casks live under /opt/homebrew/Caskroom/ or /usr/local/Caskroom/.
  static bool _isHomebrewInstall() {
    try {
      final execPath = Platform.resolvedExecutable;
      return execPath.contains('/Caskroom/') || execPath.contains('/homebrew/');
    } catch (_) {
      return false;
    }
  }

  /// Check if the Windows app was installed via winget.
  /// The Inno Setup installer writes a .winget marker file when invoked with /WINGET=1.
  static bool _isWingetInstall() {
    try {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      return File('$exeDir\\.winget').existsSync();
    } catch (_) {
      return false;
    }
  }

  /// Check if the Windows app is an installed copy (not portable).
  /// The Inno Setup installer places unins000.exe next to the executable.
  static bool _isInstalledApp() {
    try {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      return File('$exeDir\\unins000.exe').existsSync();
    } catch (_) {
      return false;
    }
  }

  /// Skip a specific version
  static Future<void> skipVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySkippedVersion, version);
  }

  /// Get the skipped version
  static Future<String?> getSkippedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySkippedVersion);
  }

  /// Clear skipped version
  static Future<void> clearSkippedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySkippedVersion);
  }

  /// Check if cooldown period has passed since last check
  static Future<bool> shouldCheckForUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheckString = prefs.getString(_keyLastCheckTime);

    if (lastCheckString == null) return true;

    final lastCheck = DateTime.parse(lastCheckString);
    final now = DateTime.now();
    final timeSinceLastCheck = now.difference(lastCheck);

    return timeSinceLastCheck >= _checkCooldown;
  }

  /// Update the last check timestamp
  static Future<void> _updateLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastCheckTime, DateTime.now().toIso8601String());
  }

  /// Internal method that performs the actual update check
  /// [respectCooldown] - if true, checks cooldown and updates last check time
  static Future<Map<String, dynamic>?> _performUpdateCheck({required bool respectCooldown}) async {
    if (!isUpdateCheckEnabled) {
      return null;
    }

    // Check cooldown if requested
    if (respectCooldown && !await shouldCheckForUpdates()) {
      return null;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final dio = Dio();
      final response = await dio.get(
        'https://api.github.com/repos/$_githubRepo/releases/latest',
        options: Options(headers: {'Accept': 'application/vnd.github+json'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final latestVersion = data['tag_name'] as String;

        // Remove 'v' prefix if present
        final cleanVersion = latestVersion.startsWith('v') ? latestVersion.substring(1) : latestVersion;

        final hasUpdate = _isNewerVersion(cleanVersion, currentVersion);

        if (hasUpdate) {
          // Check if this version was skipped
          final skippedVersion = await getSkippedVersion();
          if (skippedVersion == cleanVersion) {
            // Update last check time even when skipped (if respecting cooldown)
            if (respectCooldown) {
              await _updateLastCheckTime();
            }
            return null;
          }

          // Update last check time on success (if respecting cooldown)
          if (respectCooldown) {
            await _updateLastCheckTime();
          }

          return {
            'hasUpdate': true,
            'currentVersion': currentVersion,
            'latestVersion': cleanVersion,
            'releaseUrl': data['html_url'] as String,
            'releaseName': data['name'] as String? ?? 'Version $cleanVersion',
            'releaseNotes': data['body'] as String? ?? '',
            'publishedAt': data['published_at'] as String,
          };
        }
      }

      // Update last check time even when no update (if respecting cooldown)
      if (respectCooldown) {
        await _updateLastCheckTime();
      }
    } catch (e) {
      _logger.e('Failed to check for updates: $e');
    }

    return null;
  }

  /// Check for updates on GitHub (manual check, ignores cooldown)
  /// Returns a map with update info, or null if no update or error
  static Future<Map<String, dynamic>?> checkForUpdates() {
    return _performUpdateCheck(respectCooldown: false);
  }

  /// Check for updates on startup (respects cooldown and skipped versions)
  /// Returns update info if available, null otherwise
  static Future<Map<String, dynamic>?> checkForUpdatesOnStartup() {
    return _performUpdateCheck(respectCooldown: true);
  }

  /// Parse version string into list of integers
  /// Handles versions like "1.2.3+4" by taking only the numeric parts
  static List<int> _parseVersionParts(String version) {
    return version.split('.').map((p) {
      final numPart = p.split('+').first.split('-').first;
      return int.tryParse(numPart) ?? 0;
    }).toList();
  }

  /// Compare two version strings
  /// Returns true if newVersion is newer than currentVersion
  static bool _isNewerVersion(String newVersion, String currentVersion) {
    try {
      final newParts = _parseVersionParts(newVersion);
      final currentParts = _parseVersionParts(currentVersion);

      // Compare each part
      final maxLength = newParts.length > currentParts.length ? newParts.length : currentParts.length;

      for (int i = 0; i < maxLength; i++) {
        final newPart = i < newParts.length ? newParts[i] : 0;
        final currentPart = i < currentParts.length ? currentParts[i] : 0;

        if (newPart > currentPart) return true;
        if (newPart < currentPart) return false;
      }

      return false; // Versions are equal
    } catch (e) {
      _logger.e('Error comparing versions: $e');
      return false;
    }
  }
}
