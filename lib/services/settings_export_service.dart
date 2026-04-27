import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_logger.dart';
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

  /// Exact keys never included in the export. Matches the auth/account state
  /// tracked by [StorageService] plus multi-server and view-state keys.
  static const Set<String> _denyKeys = {
    // Credentials (from StorageService._credentialKeys)
    'server_url',
    'token',
    'plex_token',
    'server_data',
    'client_identifier',
    'user_profile',
    'current_user_uuid',
    'home_users_cache',
    'home_users_cache_expiry',
    // Multi-server routing
    'servers_list',
    'server_order',
    // View state, not settings
    'selected_library_index',
    'selected_library_key',
    // Internal migration flags
    'buffer_size_migrated_to_auto',
  };

  /// Prefix denylist. A key is excluded if it starts with any of these.
  /// The tracker prefixes (`trakt_`, `mal_`, `anilist_`, `simkl_`) cover
  /// OAuth session tokens and runtime sync queues. The `enable_*` feature
  /// toggles use a different prefix and stay exportable.
  static const List<String> _denyPrefixes = [
    'server_endpoint_',
    'episode_count_',
    'watched_threshold_',
    'trakt_',
    'mal_',
    'anilist_',
    'simkl_',
  ];

  /// Literal prefix used by [StorageService._userPrefix] for any scoped key.
  static const String _userPrefixRoot = 'user_';

  static bool _isExportable(String strippedKey) {
    if (_denyKeys.contains(strippedKey)) return false;
    for (final prefix in _denyPrefixes) {
      if (strippedKey.startsWith(prefix)) return false;
    }
    return true;
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
      String baseKey;
      if (currentUserPrefix != null && fullKey.startsWith(currentUserPrefix)) {
        baseKey = fullKey.substring(currentUserPrefix.length);
      } else if (fullKey.startsWith(_userPrefixRoot)) {
        // Scoped to some other user — skip so we only export the active user.
        continue;
      } else {
        baseKey = fullKey;
      }

      if (!_isExportable(baseKey)) continue;

      final value = prefs.get(fullKey);
      final entry = _encodeValue(value);
      if (entry == null) continue;
      prefsOut[baseKey] = entry;
    }

    return {
      'formatVersion': formatVersion,
      'appVersion': appVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'platform': Platform.operatingSystem,
      'prefs': prefsOut,
    };
  }

  static Map<String, dynamic>? _encodeValue(Object? value) {
    if (value is bool) return {'type': _typeBool, 'value': value};
    if (value is int) return {'type': _typeInt, 'value': value};
    if (value is double) return {'type': _typeDouble, 'value': value};
    if (value is String) return {'type': _typeString, 'value': value};
    if (value is List) {
      // SharedPreferences only supports List<String>.
      return {'type': _typeStringList, 'value': value.map((e) => e.toString()).toList()};
    }
    return null;
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
    int imported = 0;
    int skipped = 0;

    for (final entry in rawPrefs.entries) {
      final baseKey = entry.key.toString();
      if (!_isExportable(baseKey)) {
        skipped++;
        continue;
      }

      final rawEntry = entry.value;
      if (rawEntry is! Map) {
        skipped++;
        continue;
      }

      final type = rawEntry['type'];
      final value = rawEntry['value'];
      if (type is! String) {
        skipped++;
        continue;
      }

      final targetKey = _isUserScopedBaseKey(baseKey) ? '$userPrefix$baseKey' : baseKey;

      final ok = await _writeTyped(prefs, targetKey, type, value);
      if (ok) {
        imported++;
      } else {
        skipped++;
        appLogger.w('Skipped import of $targetKey (type=$type)');
      }
    }

    return ImportResult(keysImported: imported, keysSkipped: skipped);
  }

  /// Base keys that [StorageService] persists under the user prefix. These need
  /// to be re-scoped to the current user on import.
  static bool _isUserScopedBaseKey(String baseKey) {
    const exact = {'hidden_libraries', 'library_filters', 'library_order'};
    if (exact.contains(baseKey)) return true;
    const prefixes = ['library_filters_', 'library_sort_', 'library_grouping_', 'library_tab_'];
    return prefixes.any(baseKey.startsWith);
  }

  static Future<bool> _writeTyped(SharedPreferencesWithCache prefs, String key, String type, Object? value) async {
    try {
      switch (type) {
        case _typeBool:
          if (value is! bool) return false;
          await prefs.setBool(key, value);
          return true;
        case _typeInt:
          if (value is! int) return false;
          await prefs.setInt(key, value);
          return true;
        case _typeDouble:
          if (value is num) {
            await prefs.setDouble(key, value.toDouble());
            return true;
          }
          return false;
        case _typeString:
          if (value is! String) return false;
          await prefs.setString(key, value);
          return true;
        case _typeStringList:
          if (value is! List) return false;
          await prefs.setStringList(key, value.map((e) => e.toString()).toList());
          return true;
      }
    } catch (e, st) {
      appLogger.e('Failed to import key $key', error: e, stackTrace: st);
    }
    return false;
  }

  // --- File operations -----------------------------------------------------

  static Future<String> _defaultFileName() async {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
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

    final exportMap = buildExportMap(prefs, currentUserUuid: storage.getCurrentUserUUID(), appVersion: appVersion);
    final jsonString = const JsonEncoder.withIndent('  ').convert(exportMap);
    final bytes = Uint8List.fromList(utf8.encode(jsonString));
    final fileName = await _defaultFileName();

    // Android TV has no document picker — write to the app docs dir and let
    // the caller surface the path.
    if (Platform.isAndroid && TvDetectionService.isTVSync()) {
      return _writeToAppDocuments(fileName, bytes);
    }

    try {
      final savedPath = await FilePickerService.instance.saveFile(
        dialogTitle: 'Export Plezy settings',
        fileName: fileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: const [fileExtension],
      );
      return savedPath;
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
    final uuid = storage.getCurrentUserUUID();
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
