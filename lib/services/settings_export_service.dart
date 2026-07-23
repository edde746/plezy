import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_logger.dart';
import '../utils/formatters.dart';
import '../utils/platform_detector.dart';
import 'file_picker_service.dart';
import 'settings_service.dart';
import 'storage_service.dart';

class ImportResult {
  final int keysImported;
  final int keysSkipped;
  const ImportResult({required this.keysImported, required this.keysSkipped});
}

class SettingsExportException implements Exception {
  final String message;
  const SettingsExportException(this.message);
  @override
  String toString() => 'SettingsExportException: $message';
}

/// Thrown when an import is attempted without an active Plex user, since the
/// user prefix needed to re-scope library preferences is unavailable.
class NoUserSignedInException extends SettingsExportException {
  const NoUserSignedInException() : super('No user is signed in');
}

/// Thrown when the chosen file isn't a valid Plezy settings export.
class InvalidExportFileException extends SettingsExportException {
  const InvalidExportFileException(super.message);
}

class _PreferencePolicy {
  final String type;
  final bool userScoped;

  const _PreferencePolicy(this.type, {this.userScoped = false});
}

class _PendingImport {
  final String targetKey;
  final String type;
  final Object? value;

  const _PendingImport({required this.targetKey, required this.type, required this.value});
}

class _StoredPreferenceValue {
  final bool existed;
  final Object? value;

  const _StoredPreferenceValue({required this.existed, required this.value});
}

/// Serializes / restores user-facing SharedPreferences to a JSON file.
///
/// Strategy is allow-by-default: every key is exported unless it matches an
/// exact denylist or a prefix denylist of auth/cache/internal keys. User-scoped
/// keys (prefixed with `user_{uuid}_`) have that prefix stripped on export and
/// re-applied with the current user's prefix on import, so preferences follow
/// whichever account is signed in on the target device.
class SettingsExportService {
  static const int formatVersion = 1;
  static const String fileExtension = 'json';

  // Type markers written into the export JSON. One per SharedPreferences setter.
  static const String _typeBool = 'bool';
  static const String _typeInt = 'int';
  static const String _typeDouble = 'double';
  static const String _typeString = 'string';
  static const String _typeStringList = 'stringList';
  static const String _userPrefixRoot = 'user_';
  // Device-local storage state must never cross installations. Keep these as
  // exact keys so portable download behavior settings remain transferable.
  static const Set<String> _nonPortableDeviceStorageKeys = {'custom_download_path', 'custom_download_path_type'};
  static const String _tvosDatabaseRecoveryPrefix = 'tvos_db_recovery_';

  /// Closed registry of portable, user-facing settings. The [Pref] declarations
  /// are the source of truth for both keys and stored types; credentials,
  /// runtime state, device paths, history, endpoints, and user-authored player
  /// configuration are intentionally absent.
  static final Map<String, _PreferencePolicy> _portablePreferences = {
    for (final pref in <Pref<Object?>>[
      SettingsService.enableDebugLogging,
      SettingsService.enableHardwareDecoding,
      SettingsService.enableHDR,
      SettingsService.preferredVideoCodec,
      SettingsService.preferredAudioCodec,
      SettingsService.viewMode,
      SettingsService.seekTimeSmall,
      SettingsService.seekTimeLarge,
      SettingsService.rewindOnResume,
      SettingsService.showHeroSection,
      SettingsService.tvFullCardLayout,
      SettingsService.focusGlow,
      SettingsService.useGlobalHubs,
      SettingsService.showServerNameOnHubs,
      SettingsService.groupLibrariesByServer,
      SettingsService.sleepTimerDuration,
      SettingsService.audioSyncOffset,
      SettingsService.subtitleSyncOffset,
      SettingsService.subtitleSearchLanguage,
      SettingsService.volume,
      SettingsService.rotationLocked,
      SettingsService.subtitleFontSize,
      SettingsService.subtitleTextColor,
      SettingsService.subtitleBorderSize,
      SettingsService.subtitleBorderColor,
      SettingsService.subtitleBackgroundColor,
      SettingsService.subtitleBackgroundOpacity,
      SettingsService.subAssOverride,
      SettingsService.subtitleRenderResolution,
      SettingsService.subtitleBold,
      SettingsService.subtitleItalic,
      SettingsService.rememberTrackSelections,
      SettingsService.showChapterMarkersOnTimeline,
      SettingsService.clickVideoTogglesPlayback,
      SettingsService.autoSkipIntro,
      SettingsService.autoSkipCredits,
      SettingsService.forceSkipMarkerFallback,
      SettingsService.autoSkipDelay,
      SettingsService.introPattern,
      SettingsService.creditsPattern,
      SettingsService.downloadOnWifiOnly,
      SettingsService.autoRemoveWatchedDownloads,
      SettingsService.downloadIncludeSpecials,
      SettingsService.autoCheckUpdatesOnStartup,
      SettingsService.showPerformanceOverlay,
      SettingsService.autoHidePerformanceOverlay,
      SettingsService.enableDiscordRPC,
      SettingsService.enableTraktScrobble,
      SettingsService.enableTraktWatchedSync,
      SettingsService.enableMalScrobble,
      SettingsService.enableAnilistScrobble,
      SettingsService.enableSimklScrobble,
      SettingsService.matchContentFrameRate,
      SettingsService.tunneledPlayback,
      SettingsService.dvConversionMode,
      SettingsService.defaultQualityPreset,
      SettingsService.musicQualityPreset,
      SettingsService.musicVolume,
      SettingsService.autoPlayNextEpisode,
      SettingsService.useExoPlayer,
      SettingsService.startupSection,
      SettingsService.alwaysKeepSidebarOpen,
      SettingsService.showUnwatchedCount,
      SettingsService.showEpisodeNumberOnCards,
      SettingsService.showSeasonPostersOnTabs,
      SettingsService.hideSpoilers,
      SettingsService.showNavBarLabels,
      SettingsService.globalShaderPreset,
      SettingsService.requireProfileSelectionOnOpen,
      SettingsService.useExternalPlayer,
      SettingsService.forceTvMode,
      SettingsService.visualEffects,
      SettingsService.ambientLighting,
      SettingsService.audioPassthrough,
      SettingsService.audioNormalization,
      SettingsService.audioDownmix,
      SettingsService.audioDownmixNormalize,
      SettingsService.liveTvDefaultFavorites,
      SettingsService.matchRefreshRate,
      SettingsService.matchDynamicRange,
      SettingsService.appLocale,
      SettingsService.autoPip,
      SettingsService.maxVolume,
      SettingsService.downmixCenterBoost,
      SettingsService.subtitlePosition,
      SettingsService.defaultPlaybackSpeed,
      SettingsService.defaultBoxFitMode,
      SettingsService.displaySwitchDelay,
      SettingsService.themeMode,
      SettingsService.videoPlayerNavigationEnabled,
      SettingsService.enableCompanionRemoteServer,
      SettingsService.startInFullscreen,
      SettingsService.exitFullscreenOnPlayerClose,
      SettingsService.bufferSize,
      SettingsService.libraryDensity,
      SettingsService.tvCornerSpotlightBackdrop,
      SettingsService.episodePosterMode,
      SettingsService.continueWatchingAction,
      SettingsService.episodeAction,
      SettingsService.keyboardHotkeys,
    ])
      pref.key: _PreferencePolicy(_storageTypeFor(pref)),
  };

  static const Map<String, _PreferencePolicy> _userScopedPreferences = {
    'hidden_libraries': _PreferencePolicy(_typeStringList, userScoped: true),
    'library_filters': _PreferencePolicy(_typeString, userScoped: true),
    'library_order': _PreferencePolicy(_typeStringList, userScoped: true),
  };

  static final List<(RegExp, _PreferencePolicy)> _dynamicUserScopedPreferences = [
    (RegExp(r'^library_(?:filters|sort|grouping|tab)_.+$'), const _PreferencePolicy(_typeString, userScoped: true)),
  ];

  @visibleForTesting
  static FutureOr<void> Function(String key)? debugBeforeImportWrite;

  static String _storageTypeFor(Pref<Object?> pref) {
    if (pref is BoolPref) return _typeBool;
    if (pref is IntPref) return _typeInt;
    if (pref is DoublePref) return _typeDouble;
    if (pref is StringPref || pref is NullableStringPref || pref is EnumPref || pref is JsonPref) {
      return _typeString;
    }
    if (pref is StringListPref) return _typeStringList;

    if (pref.key == SettingsService.appLocale.key) return _typeString;
    if (pref.key == SettingsService.libraryDensity.key) return _typeInt;
    if (pref.key == SettingsService.autoPip.key ||
        pref.key == SettingsService.useExternalPlayer.key ||
        pref.key == SettingsService.audioPassthrough.key) {
      return _typeBool;
    }
    throw StateError('Portable preference ${pref.key} has no storage type');
  }

  static _PreferencePolicy? _policyFor(String baseKey) {
    if (baseKey.startsWith(_tvosDatabaseRecoveryPrefix)) return null;
    if (_nonPortableDeviceStorageKeys.contains(baseKey)) return null;
    final exact = _portablePreferences[baseKey] ?? _userScopedPreferences[baseKey];
    if (exact != null) return exact;
    for (final (pattern, policy) in _dynamicUserScopedPreferences) {
      if (pattern.hasMatch(baseKey)) return policy;
    }
    return null;
  }

  /// Builds the export map from the given prefs. Pure and testable.
  ///
  /// [currentUserUuid] — if set, keys prefixed with `user_{uuid}_` have that
  /// prefix stripped so they can be re-scoped on import. Keys belonging to any
  /// OTHER user are skipped (we only export the active user's prefs).
  static Map<String, dynamic> buildExportMap(
    SharedPreferencesWithCache prefs, {
    String? currentUserUuid,
    String appVersion = '',
  }) {
    final prefsOut = <String, Map<String, dynamic>>{};
    final currentUserPrefix = (currentUserUuid != null && currentUserUuid.isNotEmpty)
        ? '$_userPrefixRoot${currentUserUuid}_'
        : null;

    for (final fullKey in prefs.keys) {
      final bool sourceIsUserScoped;
      final String baseKey;
      if (currentUserPrefix != null && fullKey.startsWith(currentUserPrefix)) {
        sourceIsUserScoped = true;
        baseKey = fullKey.substring(currentUserPrefix.length);
      } else if (fullKey.startsWith(_userPrefixRoot)) {
        continue;
      } else {
        sourceIsUserScoped = false;
        baseKey = fullKey;
      }

      final policy = _policyFor(baseKey);
      if (policy == null || policy.userScoped != sourceIsUserScoped) continue;

      final entry = _encodeValue(prefs.get(fullKey), policy.type);
      if (entry != null) prefsOut[baseKey] = entry;
    }

    return {
      'formatVersion': formatVersion,
      'appVersion': appVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'platform': Platform.operatingSystem,
      'prefs': prefsOut,
    };
  }

  static Map<String, dynamic>? _encodeValue(Object? value, String expectedType) {
    return switch (expectedType) {
      _typeBool when value is bool => {'type': _typeBool, 'value': value},
      _typeInt when value is int => {'type': _typeInt, 'value': value},
      _typeDouble when value is double => {'type': _typeDouble, 'value': value},
      _typeString when value is String => {'type': _typeString, 'value': value},
      _typeStringList when value is List<String> => {'type': _typeStringList, 'value': value},
      _ => null,
    };
  }

  /// Applies a parsed export map to [prefs]. Pure and testable.
  ///
  /// Each key in the import overwrites whatever value currently exists at the
  /// same (possibly re-scoped) key. Keys not present in the import are left
  /// alone — this is a per-key replacement, not a global wipe.
  ///
  /// Throws [SettingsExportException] for structural problems.
  static Future<ImportResult> applyImportMap(
    Map<String, dynamic> data,
    SharedPreferencesWithCache prefs, {
    required String currentUserUuid,
  }) async {
    final version = data['formatVersion'];
    if (version is! int) {
      throw const InvalidExportFileException('Missing formatVersion');
    }
    if (version > formatVersion) {
      throw InvalidExportFileException('Unsupported formatVersion: $version');
    }

    final rawPrefs = data['prefs'];
    if (rawPrefs is! Map) {
      throw const InvalidExportFileException('Missing prefs object');
    }

    final userPrefix = 'user_${currentUserUuid}_';
    final pending = <_PendingImport>[];
    int skipped = 0;

    for (final entry in rawPrefs.entries) {
      final baseKey = entry.key.toString();
      final policy = _policyFor(baseKey);
      final rawEntry = entry.value;
      if (policy == null || rawEntry is! Map) {
        skipped++;
        continue;
      }

      final type = rawEntry['type'];
      final value = rawEntry['value'];
      if (type is! String || type != policy.type || !_isValidValue(type, value)) {
        skipped++;
        continue;
      }

      pending.add(
        _PendingImport(targetKey: policy.userScoped ? '$userPrefix$baseKey' : baseKey, type: type, value: value),
      );
    }

    final snapshots = <String, _StoredPreferenceValue>{
      for (final mutation in pending)
        mutation.targetKey: _StoredPreferenceValue(
          existed: prefs.keys.contains(mutation.targetKey),
          value: prefs.get(mutation.targetKey),
        ),
    };

    try {
      for (final mutation in pending) {
        await debugBeforeImportWrite?.call(mutation.targetKey);
        await _writeTyped(prefs, mutation.targetKey, mutation.type, mutation.value);
      }
    } catch (error, stackTrace) {
      try {
        await _restoreSnapshots(prefs, snapshots);
      } catch (rollbackError, rollbackStackTrace) {
        appLogger.e('Settings import rollback failed', error: rollbackError, stackTrace: rollbackStackTrace);
      }
      appLogger.e('Settings import failed', error: error, stackTrace: stackTrace);
      throw const SettingsExportException('Could not apply settings import');
    }

    return ImportResult(keysImported: pending.length, keysSkipped: skipped);
  }

  static bool _isValidValue(String type, Object? value) {
    return switch (type) {
      _typeBool => value is bool,
      _typeInt => value is int,
      _typeDouble => value is num,
      _typeString => value is String,
      _typeStringList => value is List && value.every((element) => element is String),
      _ => false,
    };
  }

  static Future<void> _writeTyped(SharedPreferencesWithCache prefs, String key, String type, Object? value) async {
    switch (type) {
      case _typeBool:
        await prefs.setBool(key, value! as bool);
      case _typeInt:
        await prefs.setInt(key, value! as int);
      case _typeDouble:
        await prefs.setDouble(key, (value! as num).toDouble());
      case _typeString:
        await prefs.setString(key, value! as String);
      case _typeStringList:
        await prefs.setStringList(key, (value! as List).cast<String>());
      default:
        throw StateError('Unsupported portable preference type');
    }
  }

  static Future<void> _restoreSnapshots(
    SharedPreferencesWithCache prefs,
    Map<String, _StoredPreferenceValue> snapshots,
  ) async {
    for (final entry in snapshots.entries) {
      final snapshot = entry.value;
      if (!snapshot.existed) {
        await prefs.remove(entry.key);
        continue;
      }
      switch (snapshot.value) {
        case final bool value:
          await prefs.setBool(entry.key, value);
        case final int value:
          await prefs.setInt(entry.key, value);
        case final double value:
          await prefs.setDouble(entry.key, value);
        case final String value:
          await prefs.setString(entry.key, value);
        case final List<Object?> value:
          await prefs.setStringList(entry.key, value.cast<String>());
        default:
          throw StateError('Unsupported stored preference type');
      }
    }
  }

  static Future<String> _defaultFileName() async {
    final now = DateTime.now();
    final y = padNumber(now.year, 4);
    final m = padNumber(now.month, 2);
    final d = padNumber(now.day, 2);
    return 'plezy-settings-$y$m$d.$fileExtension';
  }

  /// Serializes the current user's settings and writes them to a location of
  /// the user's choosing. Returns the saved path, or `null` if the user
  /// cancelled the picker.
  ///
  /// Throws [SettingsExportException] on failure.
  static Future<String?> exportToFile() async {
    final prefs = (await SettingsService.getInstance()).prefs;
    final storage = await StorageService.getInstance();
    String appVersion = '';
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = info.version;
    } catch (_) {
      // best-effort; tolerate platforms without PackageInfo
    }

    final exportMap = buildExportMap(prefs, currentUserUuid: storage.activeUserScope(), appVersion: appVersion);
    final jsonString = const JsonEncoder.withIndent('  ').convert(exportMap);
    final bytes = Uint8List.fromList(utf8.encode(jsonString));
    final fileName = await _defaultFileName();

    // Android TV has no document picker — write to the app docs dir and let
    // the caller surface the path.
    if (Platform.isAndroid && TvDetectionService.isTVSync()) {
      return _writeToAppDocuments(fileName, bytes);
    }

    try {
      return await FilePickerService.instance.saveFile(
        dialogTitle: 'Export Plezy settings',
        fileName: fileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: const [fileExtension],
      );
    } catch (e, st) {
      appLogger.e('Settings export failed', error: e, stackTrace: st);
      throw const SettingsExportException('Could not write export file');
    }
  }

  static Future<String> _writeToAppDocuments(String fileName, Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Prompts the user to pick a settings JSON and writes its contents into
  /// SharedPreferences. Requires a signed-in user.
  ///
  /// Returns `null` if the user cancelled. Throws [SettingsExportException] on
  /// malformed files or unsupported versions.
  static Future<ImportResult?> importFromFile() async {
    final storage = await StorageService.getInstance();
    final uuid = storage.activeUserScope();
    if (uuid == null || uuid.isEmpty) {
      throw const NoUserSignedInException();
    }

    final picked = await FilePickerService.instance.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [fileExtension],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return null;

    final file = picked.files.first;
    String contents;
    try {
      final bytes = file.bytes;
      if (bytes != null) {
        contents = utf8.decode(bytes);
      } else if (file.path != null) {
        contents = await File(file.path!).readAsString();
      } else {
        throw const InvalidExportFileException('Could not read the selected file');
      }
    } catch (e, st) {
      appLogger.e('Settings import read failed', error: e, stackTrace: st);
      throw const InvalidExportFileException('Could not read the selected file');
    }

    Map<String, dynamic> data;
    try {
      final decoded = json.decode(contents);
      if (decoded is! Map<String, dynamic>) {
        throw const InvalidExportFileException('Invalid export file');
      }
      data = decoded;
    } catch (_) {
      throw const InvalidExportFileException('Invalid export file');
    }

    final prefs = (await SettingsService.getInstance()).prefs;
    return applyImportMap(data, prefs, currentUserUuid: uuid);
  }
}
