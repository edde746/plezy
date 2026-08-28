import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:auto_updater/auto_updater.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plezy/utils/app_logger.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'base_shared_preferences_service.dart';

enum UpdateChannel { official, labs }

class PlezyRelease {
  const PlezyRelease({
    required this.version,
    required this.releaseUrl,
    required this.releaseName,
    required this.releaseNotes,
    required this.publishedAt,
    required this.tag,
    this.revision,
  });

  final String version;
  final int? revision;
  final String releaseUrl;
  final String releaseName;
  final String releaseNotes;
  final String publishedAt;
  final String tag;

  String get displayVersion =>
      revision == null ? version : '$version r$revision';
}

class UpdateReleaseSources {
  const UpdateReleaseSources({required this.official, required this.labs});

  final PlezyRelease? official;
  final PlezyRelease? labs;

  bool get labsIsBehindOfficial {
    final officialRelease = official;
    final labsRelease = labs;
    if (officialRelease == null) return false;
    if (labsRelease == null) return true;
    return UpdateService.isNewerVersion(
      officialRelease.version,
      labsRelease.version,
    );
  }
}

/// Plezy Labs release discovery and update orchestration.
///
/// GitHub Releases is the single source of truth for release names, notes,
/// dates, and download pages. Sparkle/WinSparkle uses the separate Labs
/// appcast only for authenticated Labs-to-Labs native updates.
class UpdateService {
  static const String officialGithubRepo = 'edde746/plezy';
  static const String labsGithubRepo = 'RyanTheTechMan/plezy';
  static const String labsFeedUrl =
      'https://raw.githubusercontent.com/RyanTheTechMan/plezy/labs-feed/appcast.xml';
  static const String officialReleasesUrl =
      'https://github.com/edde746/plezy/releases/latest';
  static const int labsRevision = int.fromEnvironment(
    'LABS_REVISION',
    defaultValue: 1,
  );

  static const String _keySkippedVersion = 'update_skipped_version';
  static const String _keyLastCheckTime = 'update_last_check_time';
  static const String _keyUpdateChannel = 'update_channel';
  static const String _keyChannelChoiceComplete =
      'update_channel_choice_complete';
  static const Duration _checkCooldown = Duration(hours: 6);
  static final RegExp _labsTagPattern = RegExp(
    r'^labs-v(\d+\.\d+\.\d+)-r(\d+)$',
  );

  static bool _nativeUpdaterInitialized = false;

  static bool get isLabsBuild =>
      const bool.fromEnvironment('PLEZY_LABS', defaultValue: false);

  static bool get isUpdateCheckEnabled =>
      const bool.fromEnvironment('ENABLE_UPDATE_CHECK', defaultValue: false);

  /// Labs builds may show the official release as a manual replacement option,
  /// but their automatic updater must never follow the official channel.
  @visibleForTesting
  static UpdateChannel effectiveUpdateChannel({
    required bool labsBuild,
    required UpdateChannel storedChannel,
  }) => labsBuild ? UpdateChannel.labs : storedChannel;

  /// Whether any in-app update path applies to this install.
  /// False inside a packaged (MSIX/Store) install: the Store owns updates and
  /// the package directory is read-only, so neither WinSparkle nor the GitHub
  /// fallback dialog has anything it can do. Gates the settings entry too, so
  /// no dead affordance ships.
  static bool get isUpdateCheckAvailable =>
      isUpdateCheckEnabled && !PlatformDetector.isPackagedInstall();

  /// Whether the native auto_updater (Sparkle/WinSparkle) should be used.
  /// True on macOS (non-Homebrew) and installed Windows (has uninstaller).
  static bool get useNativeUpdater {
    if (!isUpdateCheckAvailable) return false;
    if (Platform.isMacOS) return !_isHomebrewInstall();
    if (Platform.isWindows) return _isInstalledApp() && !_isWingetInstall();
    return false;
  }

  static Future<UpdateChannel> getUpdateChannel() async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    final stored = prefs.getString(_keyUpdateChannel);
    final storedChannel =
        UpdateChannel.values
            .where((channel) => channel.name == stored)
            .firstOrNull ??
        UpdateChannel.labs;
    final effectiveChannel = effectiveUpdateChannel(
      labsBuild: isLabsBuild,
      storedChannel: storedChannel,
    );
    if (effectiveChannel != storedChannel) {
      await prefs.setString(_keyUpdateChannel, effectiveChannel.name);
    }
    return effectiveChannel;
  }

  static Future<void> setUpdateChannel(UpdateChannel channel) async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    final effectiveChannel = effectiveUpdateChannel(
      labsBuild: isLabsBuild,
      storedChannel: channel,
    );
    await prefs.setString(_keyUpdateChannel, effectiveChannel.name);
  }

  static Future<bool> shouldPromptForUpdateChannel() async {
    if (!isUpdateCheckEnabled) return false;
    final prefs = await BaseSharedPreferencesService.sharedCache();
    return prefs.getBool(_keyChannelChoiceComplete) != true;
  }

  static Future<void> completeUpdateChannelChoice(UpdateChannel channel) async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    final effectiveChannel = effectiveUpdateChannel(
      labsBuild: isLabsBuild,
      storedChannel: channel,
    );
    await prefs.setString(_keyUpdateChannel, effectiveChannel.name);
    await prefs.setBool(_keyChannelChoiceComplete, true);
  }

  static Future<void> initNativeUpdater() async {
    if (_nativeUpdaterInitialized ||
        await getUpdateChannel() != UpdateChannel.labs)
      return;

    try {
      await autoUpdater.setFeedURL(labsFeedUrl);
      _nativeUpdaterInitialized = true;
    } catch (error, stackTrace) {
      appLogger.e(
        'Failed to initialize Plezy Labs native updater',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> checkForUpdatesNative({bool inBackground = true}) async {
    if (await getUpdateChannel() != UpdateChannel.labs) return;
    if (!_nativeUpdaterInitialized) {
      await initNativeUpdater();
      if (!_nativeUpdaterInitialized) return;
    }
    try {
      await autoUpdater.checkForUpdates(inBackground: inBackground);
    } catch (error, stackTrace) {
      appLogger.e(
        'Plezy Labs native update check failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<UpdateReleaseSources> fetchReleaseSources({
    MediaServerHttpClient? client,
  }) async {
    final releaseClient = client ?? httpClient;
    PlezyRelease? official;
    PlezyRelease? labs;

    try {
      final responses = await Future.wait([
        releaseClient.get(
          'https://api.github.com/repos/$officialGithubRepo/releases/latest',
          headers: {'Accept': 'application/vnd.github+json'},
        ),
        releaseClient.get(
          'https://api.github.com/repos/$labsGithubRepo/releases?per_page=30',
          headers: {'Accept': 'application/vnd.github+json'},
        ),
      ]);

      if (responses[0].statusCode == 200 && responses[0].data is Map) {
        official = officialReleaseFromJson(
          Map<String, dynamic>.from(responses[0].data as Map),
        );
      }
      if (responses[1].statusCode == 200 && responses[1].data is List) {
        labs = latestLabsReleaseFromJson(responses[1].data as List<dynamic>);
      }
    } catch (error, stackTrace) {
      appLogger.e(
        'Failed to load Plezy release sources',
        error: error,
        stackTrace: stackTrace,
      );
    }

    return UpdateReleaseSources(official: official, labs: labs);
  }

  static PlezyRelease? officialReleaseFromJson(Map<String, dynamic> data) {
    final tag = data['tag_name'] as String?;
    final url = data['html_url'] as String?;
    if (tag == null ||
        url == null ||
        data['draft'] == true ||
        data['prerelease'] == true)
      return null;
    final version = tag.startsWith('v') ? tag.substring(1) : tag;
    return _releaseFromJson(data, version: version, tag: tag);
  }

  static PlezyRelease? latestLabsReleaseFromJson(List<dynamic> releases) {
    for (final raw in releases) {
      if (raw is! Map) continue;
      final data = Map<String, dynamic>.from(raw);
      final tag = data['tag_name'] as String? ?? '';
      final match = _labsTagPattern.firstMatch(tag);
      if (match == null || data['draft'] == true || data['prerelease'] != false)
        continue;
      return _releaseFromJson(
        data,
        version: match.group(1)!,
        revision: int.parse(match.group(2)!),
        tag: tag,
      );
    }
    return null;
  }

  static PlezyRelease? _releaseFromJson(
    Map<String, dynamic> data, {
    required String version,
    required String tag,
    int? revision,
  }) {
    final url = data['html_url'] as String?;
    if (url == null) return null;
    return PlezyRelease(
      version: version,
      revision: revision,
      releaseUrl: url,
      releaseName:
          data['name'] as String? ??
          (revision == null
              ? 'Plezy $version'
              : 'Plezy Labs $version r$revision'),
      releaseNotes: data['body'] as String? ?? '',
      publishedAt: data['published_at'] as String? ?? '',
      tag: tag,
    );
  }

  /// Check if the macOS app was installed via Homebrew.
  /// Homebrew casks live under /opt/homebrew/Caskroom/ or /usr/local/Caskroom/.
  static bool _isHomebrewInstall() {
    try {
      final execPath = Platform.resolvedExecutable;
      return execPath.contains('/Caskroom/') || execPath.contains('/homebrew/');
    } catch (error, stackTrace) {
      appLogger.e(
        'Failed to determine Homebrew install status',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Check if the Windows app was installed via winget.
  /// The Inno Setup installer writes a .winget marker file when invoked with /WINGET=1.
  static bool _isWingetInstall() {
    try {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      return File('$exeDir\\.winget').existsSync();
    } catch (error, stackTrace) {
      appLogger.e(
        'Failed to determine winget install status',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Check if the Windows app is an installed copy (not portable).
  /// The Inno Setup installer places unins000.exe next to the executable.
  static bool _isInstalledApp() {
    try {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      return File('$exeDir\\unins000.exe').existsSync();
    } catch (error, stackTrace) {
      appLogger.e(
        'Failed to determine Windows installation status',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  static Future<void> skipVersion(String version) async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    await prefs.setString(_keySkippedVersion, version);
  }

  static Future<String?> getSkippedVersion() async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    return prefs.getString(_keySkippedVersion);
  }

  static Future<void> clearSkippedVersion() async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    await prefs.remove(_keySkippedVersion);
  }

  /// Check if cooldown period has passed since last check
  static Future<bool> shouldCheckForUpdates() async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    final lastCheckString = prefs.getString(_keyLastCheckTime);
    if (lastCheckString == null) return true;

    final now = DateTime.now();
    final lastCheck = DateTime.tryParse(lastCheckString);
    if (lastCheck == null || lastCheck.isAfter(now)) {
      await prefs.remove(_keyLastCheckTime);
      return true;
    }

    return now.difference(lastCheck) >= _checkCooldown;
  }

  static Future<void> _updateLastCheckTime() async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    await prefs.setString(_keyLastCheckTime, DateTime.now().toIso8601String());
  }

  static Future<PlezyRelease?> _fetchReleaseForChannel(
    UpdateChannel channel, {
    MediaServerHttpClient? client,
  }) async {
    final releaseClient = client ?? httpClient;
    final response = await releaseClient.get(
      channel == UpdateChannel.labs
          ? 'https://api.github.com/repos/$labsGithubRepo/releases?per_page=30'
          : 'https://api.github.com/repos/$officialGithubRepo/releases/latest',
      headers: {'Accept': 'application/vnd.github+json'},
    );
    if (response.statusCode != 200) return null;
    if (channel == UpdateChannel.labs && response.data is List) {
      return latestLabsReleaseFromJson(response.data as List<dynamic>);
    }
    if (channel == UpdateChannel.official && response.data is Map) {
      return officialReleaseFromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    }
    return null;
  }

  /// Internal method that performs the actual update check
  /// [respectCooldown] - if true, checks cooldown and records the attempt before the request
  static Future<Map<String, dynamic>?> _performUpdateCheck({
    required bool respectCooldown,
    MediaServerHttpClient? client,
    bool forceEnabled = false,
  }) async {
    if (!forceEnabled && !isUpdateCheckAvailable) {
      return null;
    }

    // Check cooldown if requested
    if (respectCooldown && !await shouldCheckForUpdates()) {
      return null;
    }

    try {
      if (respectCooldown) {
        await _updateLastCheckTime();
      }

      final channel = await getUpdateChannel();
      final release = await _fetchReleaseForChannel(channel, client: client);
      if (release == null) return null;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final hasUpdate = channel == UpdateChannel.labs
          ? isNewerVersion(release.version, currentVersion) ||
                (release.version == currentVersion &&
                    (release.revision ?? 0) > labsRevision)
          : isNewerVersion(release.version, currentVersion);
      if (!hasUpdate || await getSkippedVersion() == release.tag) return null;

      return {
        'hasUpdate': true,
        'currentVersion': channel == UpdateChannel.labs
            ? '$currentVersion r$labsRevision'
            : currentVersion,
        'latestVersion': release.displayVersion,
        'releaseUrl': release.releaseUrl,
        'releaseName': release.releaseName,
        'releaseNotes': release.releaseNotes,
        'publishedAt': release.publishedAt,
        'tag': release.tag,
      };
    } catch (error, stackTrace) {
      appLogger.e(
        'Failed to check for updates',
        error: error,
        stackTrace: stackTrace,
      );
    }

    return null;
  }

  @visibleForTesting
  static Future<Map<String, dynamic>?> debugPerformUpdateCheck({
    required bool respectCooldown,
    required MediaServerHttpClient client,
  }) {
    return _performUpdateCheck(
      respectCooldown: respectCooldown,
      client: client,
      forceEnabled: true,
    );
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
  static bool isNewerVersion(String newVersion, String currentVersion) {
    try {
      final newParts = _parseVersionParts(newVersion);
      final currentParts = _parseVersionParts(currentVersion);

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

      return false;
    } catch (error, stackTrace) {
      appLogger.e(
        'Error comparing versions',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
