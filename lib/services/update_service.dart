import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to check for new versions on GitHub
/// Only enabled when ENABLE_UPDATE_CHECK build flag is set
class UpdateService {
  static final Logger _logger = Logger();
  static const String _githubRepo = 'edde746/plezy';

  // SharedPreferences keys
  static const String _keySkippedVersion = 'update_skipped_version';
  static const String _keyLastCheckTime = 'update_last_check_time';

  // Check cooldown: 6 hours
  static const Duration _checkCooldown = Duration(hours: 6);

  /// Check if update checking is enabled via build flag
  static bool get isUpdateCheckEnabled {
    const enabled = bool.fromEnvironment(
      'ENABLE_UPDATE_CHECK',
      defaultValue: false,
    );
    return enabled;
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

  /// Check for updates on GitHub (manual check, ignores cooldown)
  /// Returns a map with update info, or null if no update or error
  static Future<Map<String, dynamic>?> checkForUpdates({
    bool silent = false,
  }) async {
    if (!isUpdateCheckEnabled) {
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
        final cleanVersion = latestVersion.startsWith('v')
            ? latestVersion.substring(1)
            : latestVersion;

        final hasUpdate = _isNewerVersion(cleanVersion, currentVersion);

        if (hasUpdate) {
          // Check if this version was skipped (always check, regardless of silent mode)
          final skippedVersion = await getSkippedVersion();
          if (skippedVersion == cleanVersion) {
            return null;
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
    } catch (e) {
      _logger.e('Failed to check for updates: $e');
    }

    return null;
  }

  /// Check for updates on startup (respects cooldown and skipped versions)
  /// Returns update info if available, null otherwise
  static Future<Map<String, dynamic>?> checkForUpdatesOnStartup() async {
    if (!isUpdateCheckEnabled) {
      return null;
    }

    // Check cooldown
    if (!await shouldCheckForUpdates()) {
      return null;
    }

    // Perform the check
    final updateInfo = await checkForUpdates(silent: true);

    // Update last check time
    await _updateLastCheckTime();

    return updateInfo;
  }

  /// Compare two version strings
  /// Returns true if newVersion is newer than currentVersion
  static bool _isNewerVersion(String newVersion, String currentVersion) {
    try {
      // Split by '.' and parse as integers
      final newParts = newVersion.split('.').map((p) {
        // Handle versions like "1.2.3+4" by taking only the numeric part
        final numPart = p.split('+').first.split('-').first;
        return int.tryParse(numPart) ?? 0;
      }).toList();

      final currentParts = currentVersion.split('.').map((p) {
        final numPart = p.split('+').first.split('-').first;
        return int.tryParse(numPart) ?? 0;
      }).toList();

      // Compare each part
      final maxLength = newParts.length > currentParts.length
          ? newParts.length
          : currentParts.length;

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
