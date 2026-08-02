import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/seerr/seerr_session.dart';
import '../utils/app_logger.dart';
import '../utils/log_redaction_manager.dart';
import 'sensitive_prefs.dart';
import 'trackers/tracker_constants.dart';
import 'trackers/tracker_session.dart';

/// File-backed preference store used by the desktop `shared_preferences`
/// implementations. Windows and Linux both persist a single flat JSON object
/// at `<applicationSupport>/shared_preferences.json`, written with a
/// non-atomic `writeAsStringSync` and parsed with an unguarded `json.decode`.
/// A crash, power loss or antivirus interception mid-write therefore leaves a
/// truncated file that fails every subsequent launch identically.
const String prefsStoreFileName = 'shared_preferences.json';

/// Prefix the legacy `SharedPreferences` API writes into the same store file
/// (`shared_preferences_legacy.dart` `_prefix`). Entries only exist under this
/// spelling until the legacy-to-async migration has copied them across.
const String legacyKeyPrefix = 'flutter.';

/// Derived, content-free description of a damaged store's bytes.
///
/// Every field is a measurement, never a quotation: a length, and two
/// booleans. Together they separate the shapes that all surface as
/// "FormatException at offset 0" — an all-zero file, a document with a
/// non-JSON first character, bytes that are not UTF-8 at all — which the
/// message alone cannot (#1732).
class PrefsStoreShape {
  const PrefsStoreShape({required this.length, required this.validUtf8, required this.allZero});

  factory PrefsStoreShape.of(List<int> bytes) => PrefsStoreShape(
    length: bytes.length,
    validUtf8: _decodesAsUtf8(bytes),
    allZero: bytes.isNotEmpty && bytes.every((byte) => byte == 0),
  );

  final int length;
  final bool validUtf8;
  final bool allZero;

  static bool _decodesAsUtf8(List<int> bytes) {
    try {
      utf8.decode(bytes);
      return true;
    } on FormatException {
      return false;
    }
  }

  @override
  String toString() => '$length bytes, ${validUtf8 ? 'valid' : 'invalid'} UTF-8${allZero ? ', every byte zero' : ''}';
}

/// Raised when the preference store exists but cannot be parsed.
///
/// `BaseSharedPreferencesService` converts the platform's raw
/// `FormatException`/`TypeError` into this so the startup gate can tell a
/// repairable store apart from an inaccessible directory, and offer the user
/// an explicit repair instead of a dead app (#1732).
///
/// The original error is deliberately **not** retained. `json.decode` throws a
/// `FormatException` whose `source` is the entire preference document, and
/// `FormatException.toString()` prints an excerpt of it around the error
/// offset. Anything holding that object could persist, render or upload raw
/// credential material — `credential_vault_key_v1`, a tracker refresh token, a
/// Seerr cookie — and at this point in startup `LogRedactionManager` has no
/// registered values to catch it. Only the cause's type, offset and the
/// derived [PrefsStoreShape] survive, all of which are safe by construction.
class CorruptPreferenceStoreException implements Exception {
  CorruptPreferenceStoreException(Object cause, this.causeStackTrace, {this.reopenSafe = true, this.shape})
    : causeType = cause.runtimeType.toString(),
      offset = cause is FormatException ? cause.offset : null;

  /// Runtime type of the discarded cause, e.g. `FormatException`.
  final String causeType;

  /// Byte offset the parser failed at, when the cause reported one.
  final int? offset;

  /// Frames only — never contains document contents.
  final StackTrace causeStackTrace;

  /// Whether the store can be reopened inside this process after a repair.
  ///
  /// True when [PrefsRecovery.assertStoreReadable] rejected the document
  /// before either plugin backend touched it, so nothing was memoised. False
  /// when the preflight passed and the plugin failed anyway: the desktop
  /// backends cache the parsed document in a private map and never re-read it,
  /// so reopening would hand back the bad document and write it straight back.
  /// A repair in that state must be followed by a restart.
  final bool reopenSafe;

  /// Measurements of the rejected bytes, when they were available.
  final PrefsStoreShape? shape;

  @override
  String toString() =>
      'CorruptPreferenceStoreException: the preference store could not be parsed'
      ' ($causeType${offset == null ? '' : ' at offset $offset'};'
      ' ${shape ?? 'shape unavailable'}; reopenSafe: $reopenSafe)';
}

/// Raised when a credential preference exists but its stored type no longer
/// matches the declaration.
///
/// Ordinary preferences are dropped and defaulted on a type mismatch, but a
/// credential cannot be: silently discarding one would sign the user out with
/// no explanation. This surfaces instead, so the startup gate can offer the
/// same consented repair it offers for an unparseable store (#1732).
///
/// Only the key name and the cause's type are retained. Key names are not
/// secret; values are, and no value ever reaches this object.
class UnreadableSensitivePreferenceException implements Exception {
  UnreadableSensitivePreferenceException(this.key, Object cause) : causeType = cause.runtimeType.toString();

  final String key;
  final String causeType;

  @override
  String toString() =>
      'UnreadableSensitivePreferenceException: credential preference "$key"'
      ' has an unreadable stored type ($causeType)';
}

/// What a repair recovered and what it could not.
///
/// The distinction is user-facing. A salvaged vault key keeps every
/// server/profile signed in, because those tokens live as ciphertext in the
/// database rather than in preferences. Tracker and Seerr sessions are stored
/// as plaintext preference entries, so they survive only when individually
/// salvageable — the vault key says nothing about them.
class PrefsRepairOutcome {
  const PrefsRepairOutcome({
    required this.backupPath,
    required this.vaultKeySalvaged,
    required this.sessionsSalvaged,
    required this.sessionsLost,
    this.backupHoldsCredentials = true,
    this.settingsReset = true,
    this.requiresRestart = false,
  });

  /// Absolute path of the quarantined store. When [backupHoldsCredentials] it
  /// contains credentials in plaintext: never upload it, attach it to a
  /// report, or log its contents.
  final String? backupPath;

  /// Whether the quarantined file may still hold credential material.
  ///
  /// Derived from the bytes, never from what the salvage recovered: a store
  /// truncated mid-value keeps most of a vault key or an entire refresh token
  /// in plaintext while matching no entry at all, because the salvage pattern
  /// requires the value's closing quote. Only a file proven to contain
  /// nothing — every byte zero (#1732) — drops the warning, because a warning
  /// attached to a file of zeros is the one that teaches users to ignore it.
  final bool backupHoldsCredentials;

  /// Whether [credentialVaultKeyPref] was recovered. When false every stored
  /// server and profile token becomes undecryptable and must be re-acquired.
  final bool vaultKeySalvaged;

  /// Tracker/Seerr session slots reseeded into the fresh store.
  final int sessionsSalvaged;

  /// Session slots that were present but unrecoverable.
  final int sessionsLost;

  /// Whether the user has to reconnect at least one tracker or Seerr instance.
  bool get sessionsAffected => sessionsLost > 0;

  /// Whether the repair discarded the settings store. False for the surgical
  /// single-key repair, which leaves every other preference untouched.
  final bool settingsReset;

  /// Whether the app must restart before the repaired store can be used.
  /// Set when the plugin had already memoised the bad document.
  final bool requiresRestart;
}

/// Credentials lifted out of a damaged store, before it is quarantined.
class SalvagedPrefsCredentials {
  const SalvagedPrefsCredentials({required this.vaultKey, required this.sessions, required this.losses});

  static const SalvagedPrefsCredentials empty = SalvagedPrefsCredentials(vaultKey: null, sessions: {}, losses: 0);

  /// Base64 vault key, already validated as exactly 32 raw bytes.
  final String? vaultKey;

  /// Preference key → encoded session payload, each validated by decoding it
  /// with the owning store's codec.
  final Map<String, String> sessions;

  /// Credential slots that were present but could not be decoded.
  final int losses;

  /// Deliberately no "does this hold credentials" helper. What [salvage]
  /// recovered says nothing about what the file still contains: a store
  /// truncated mid-value keeps most of a vault key in plaintext and matches
  /// nothing. Ask [PrefsStoreShape] about the bytes instead.
}

/// Recovers a damaged desktop preference store without silently destroying
/// credentials.
///
/// Repair is never automatic. `SettingsService.getInstance()` surfaces
/// [CorruptPreferenceStoreException] to the startup gate, the gate offers the
/// user an explicit choice that names the real cost, and only an accepted
/// choice reaches `BaseSharedPreferencesService.repairCorruptStore`.
abstract final class PrefsRecovery {
  /// Whether a repair can be attempted on this platform. Only the desktop
  /// implementations use a single JSON file we can salvage and quarantine;
  /// Android, iOS and macOS delegate to platform-native stores.
  static bool get isSupportedPlatform => _supportedPlatformOverride ?? (Platform.isWindows || Platform.isLinux);

  static bool? _supportedPlatformOverride;

  /// Test seam. The desktop store path is Windows/Linux only, so a host suite
  /// running anywhere else cannot reach the production preflight at all — and
  /// that preflight is precisely where #1732 is decided.
  @visibleForTesting
  static void debugSetSupportedPlatformOverride(bool? value) => _supportedPlatformOverride = value;

  static Future<File> storeFile() async {
    final directory = await getApplicationSupportDirectory();
    return File(p.join(directory.path, prefsStoreFileName));
  }

  /// Rejects a damaged desktop store *before* either plugin backend reads it.
  ///
  /// This ordering is load-bearing. `shared_preferences_windows` assigns the
  /// decoded document to a private `_cachedPreferences` map and never re-reads
  /// it, and the map it stores is the lazy result of `Map.cast<String, Object>`
  /// — so a document containing a null value caches successfully and only
  /// throws later, when `Map<String, Object>.from` walks it. Detecting that
  /// after the fact would be useless: the bad document is already memoised, a
  /// repair could not reopen onto a clean store, and the first write would
  /// persist the memoised copy straight back over the repaired file.
  ///
  /// Validating here means the plugin only ever sees a document it can hold.
  ///
  /// No-op on the platforms that use a native store, and on a missing store —
  /// a first launch has nothing to validate.
  static Future<void> assertStoreReadable({File? storeFileOverride}) async {
    final damage = await describeCurrentStoreDamage(reopenSafe: true, storeFileOverride: storeFileOverride);
    if (damage != null) throw damage;
  }

  /// Re-reads the live store and classifies it, without throwing.
  ///
  /// Returns null when the bytes on disk are ones the desktop backends can
  /// hold — including a missing or unreadable file, neither of which a repair
  /// addresses. A non-null result means the *document* is damaged, which is
  /// the only thing that justifies offering the user a destructive repair.
  ///
  /// Used both as the preflight and, with `reopenSafe: false`, to classify a
  /// failure that surfaced after the preflight already passed.
  static Future<CorruptPreferenceStoreException?> describeCurrentStoreDamage({
    required bool reopenSafe,
    File? storeFileOverride,
  }) async {
    if (storeFileOverride == null && !isSupportedPlatform) return null;

    final File file;
    try {
      file = storeFileOverride ?? await storeFile();
      if (!await file.exists()) return null;
    } on Object {
      // Locating or stat-ing the directory is a different failure entirely
      // (missing/denied application support); let the plugin report it.
      return null;
    }

    final List<int> bytes;
    try {
      bytes = await file.readAsBytes();
    } on FileSystemException {
      return null; // Unreadable rather than invalid; not something a repair fixes.
    }

    return describeStoreDamage(bytes, reopenSafe: reopenSafe);
  }

  /// Classifies raw store bytes, returning the failure to surface or null when
  /// the document is one the desktop backends can hold.
  ///
  /// Byte-level on purpose. `File.readAsString` reports a UTF-8 decode failure
  /// as a `FileSystemException`, indistinguishable by type from a denied or
  /// locked file, so decoding explicitly here is the only way to tell a damaged
  /// document apart from a file we simply cannot read (#1732).
  @visibleForTesting
  static CorruptPreferenceStoreException? describeStoreDamage(List<int> bytes, {bool reopenSafe = true}) {
    final shape = PrefsStoreShape.of(bytes);

    final String raw;
    try {
      raw = utf8.decode(bytes);
    } on FormatException catch (error, stackTrace) {
      return CorruptPreferenceStoreException(error, stackTrace, reopenSafe: reopenSafe, shape: shape);
    }
    // Both desktop backends skip `json.decode` for an empty document and start
    // from `{}`, so an empty store is a first launch, not damage.
    if (raw.isEmpty) return null;

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error, stackTrace) {
      return CorruptPreferenceStoreException(error, stackTrace, reopenSafe: reopenSafe, shape: shape);
    }

    if (decoded is! Map) {
      return CorruptPreferenceStoreException(
        const FormatException('Preference store is not a JSON object'),
        StackTrace.current,
        reopenSafe: reopenSafe,
        shape: shape,
      );
    }
    for (final entry in decoded.entries) {
      if (entry.key is! String || !_isStorableValue(entry.value)) {
        // The key name is safe to omit and the value must never be quoted, so
        // the exception deliberately carries neither.
        return CorruptPreferenceStoreException(
          const FormatException('Preference store holds a value of an unsupported type'),
          StackTrace.current,
          reopenSafe: reopenSafe,
          shape: shape,
        );
      }
    }
    return null;
  }

  /// Mirrors what the desktop backends can hold: the JSON scalars plus a
  /// string list. A null value is the common real-world offender.
  static bool _isStorableValue(Object? value) {
    if (value is bool || value is int || value is double || value is String) return true;
    return value is List && value.every((element) => element is String);
  }

  /// Writes a fresh store containing only [salvaged], for the next process.
  ///
  /// Used when the plugin already memoised the bad document and cannot be
  /// reopened in-process. The salvage would otherwise be thrown away: the
  /// quarantined file is gone, nothing reseeds the vault key, and the next
  /// launch generates a replacement key that orphans every token stored as
  /// ciphertext in the database.
  ///
  /// Writes the same flat JSON object the desktop backends read, under the
  /// unprefixed async key names. Staged through a sibling temporary file and
  /// renamed into place so a crash mid-write cannot leave a second truncated
  /// store — the exact failure this whole path exists to recover from.
  ///
  /// Returns whether the seed landed.
  static Future<bool> seedStore(SalvagedPrefsCredentials salvaged, {File? storeFileOverride}) async {
    final vaultKey = salvaged.vaultKey;
    if (vaultKey == null && salvaged.sessions.isEmpty) return false;
    final values = <String, Object>{credentialVaultKeyPref: ?vaultKey, ...salvaged.sessions};

    try {
      final file = storeFileOverride ?? await storeFile();
      if (!await file.parent.exists()) await file.parent.create(recursive: true);
      final staged = File('${file.path}.seed');
      await staged.writeAsString(jsonEncode(values), flush: true);
      await staged.rename(file.path);
      return true;
    } catch (error, stackTrace) {
      appLogger.e('Could not seed a repaired preference store', error: error, stackTrace: stackTrace);
      return false;
    }
  }

  /// Lifts credentials out of the raw bytes of a store that no longer parses.
  ///
  /// A damaged store is almost always *truncated*, not scrambled, so entries
  /// near the front usually survive verbatim even when the object as a whole
  /// has no closing brace. Each value is matched on the wire, unescaped
  /// individually and validated with its owning codec, so a partially written
  /// entry is discarded rather than reseeded as garbage.
  ///
  /// Both key spellings are recognised. The legacy `SharedPreferences` API
  /// persists into the same file under a [legacyKeyPrefix] prefix, and
  /// `_loadSharedCache` runs `SharedPreferences.getInstance()` before the
  /// legacy-to-async migration — so a store damaged mid-migration can hold a
  /// credential only under its prefixed name. Salvage normalises those onto
  /// the async key the app actually reads, and an unprefixed entry always wins
  /// over a prefixed one regardless of their order in the file.
  @visibleForTesting
  static SalvagedPrefsCredentials salvage(String raw) {
    String? vaultKey;
    var vaultKeyFromLegacy = false;
    final sessions = <String, String>{};
    final sessionFromLegacy = <String, bool>{};
    var losses = 0;

    for (final match in _stringEntryPattern.allMatches(raw)) {
      final rawKey = _unescape(match.group(1)!);
      if (rawKey == null) continue;
      final legacy = rawKey.startsWith(legacyKeyPrefix);
      final key = legacy ? rawKey.substring(legacyKeyPrefix.length) : rawKey;
      if (!isSensitivePrefKey(key)) continue;
      final value = _unescape(match.group(2)!);

      if (key == credentialVaultKeyPref) {
        if (value == null || !_isVaultKey(value)) {
          losses++;
        } else if (vaultKey == null || (vaultKeyFromLegacy && !legacy)) {
          vaultKey = value;
          vaultKeyFromLegacy = legacy;
        }
        continue;
      }

      // The legacy Plex slot is an opaque token with no codec to validate
      // against; a non-empty string is all we can assert.
      final valid =
          value != null &&
          value.isNotEmpty &&
          (key == legacyPlexTokenPref ? _registerLegacyPlexToken(value) : _validateAndRegisterSession(key, value));
      if (!valid) {
        losses++;
        continue;
      }
      if (!sessions.containsKey(key) || ((sessionFromLegacy[key] ?? false) && !legacy)) {
        sessions[key] = value;
        sessionFromLegacy[key] = legacy;
      }
      // Defence in depth on top of the per-field registration above: catches
      // the payload being echoed whole.
      LogRedactionManager.registerCustomValue(value);
    }

    if (vaultKey != null) {
      // Register before returning so no later log line, diagnostic or crash
      // report can echo the key material even if a caller mishandles it.
      LogRedactionManager.registerCustomValue(vaultKey);
    }

    return SalvagedPrefsCredentials(vaultKey: vaultKey, sessions: sessions, losses: losses);
  }

  /// Copies the live store aside without disturbing it.
  ///
  /// Used by the surgical single-key repair, where the store is still valid
  /// and stays in place — only the copy records the pre-repair state.
  static Future<String?> backupStore({File? storeFileOverride}) async {
    final file = storeFileOverride ?? await storeFile();
    if (!await file.exists()) return null;
    final backup = File(p.join(file.parent.path, 'shared_preferences.backup-${_stamp()}.json'));
    try {
      await file.copy(backup.path);
    } on FileSystemException catch (error, stackTrace) {
      appLogger.w('Could not back up the preference store before repair', error: error, stackTrace: stackTrace);
      return null;
    }
    return backup.path;
  }

  static String _stamp() => DateTime.now().toUtc().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');

  /// Reports what a repair would recover, without touching the store.
  ///
  /// The consent dialog has to name a cost before anything is destroyed, and
  /// the cost is not uniform: a store that still holds a readable vault key
  /// keeps every server and profile signed in, while one that does not — an
  /// all-zero file being the canonical case (#1732) — signs the user out of
  /// everything. Promising the cheap outcome for the expensive case is worse
  /// than saying nothing, so the dialog runs this first and branches on it.
  ///
  /// Pure with respect to the filesystem. [salvage] does register every secret
  /// it decodes with `LogRedactionManager`, which is idempotent and wanted
  /// early regardless of whether the user goes on to accept the repair.
  static Future<SalvagedPrefsCredentials> previewSalvage({File? storeFileOverride}) async {
    final File file;
    try {
      file = storeFileOverride ?? await storeFile();
      if (!await file.exists()) return SalvagedPrefsCredentials.empty;
    } on Object {
      return SalvagedPrefsCredentials.empty;
    }

    try {
      return salvage(_decodeForSalvage(await file.readAsBytes()));
    } on FileSystemException catch (error, stackTrace) {
      // Only a preview; an unreadable file is the repair's problem to report,
      // not a reason to fail before the user has even been asked.
      appLogger.w('Could not preview the damaged preference store', error: error, stackTrace: stackTrace);
      return SalvagedPrefsCredentials.empty;
    }
  }

  /// Decodes damaged store bytes as text for the salvage pass.
  ///
  /// Lossy rather than strict, because `File.readAsString` surfaces a UTF-8
  /// decode failure as a `FileSystemException` and would abort on exactly the
  /// damaged store this exists to rescue. For a well-formed document this is
  /// identical to a strict decode; for a damaged one it still exposes the
  /// ASCII credential entries.
  static String _decodeForSalvage(List<int> bytes) => const Utf8Decoder(allowMalformed: true).convert(bytes);

  /// Quarantines the damaged store and returns what was salvaged, alongside
  /// the measured shape of the bytes that were moved aside.
  ///
  /// The caller opens a fresh store afterwards and reseeds it; see
  /// `BaseSharedPreferencesService.repairCorruptStore`.
  ///
  /// The damaged file is *moved*, never deleted: it is the only remaining copy
  /// of any credential that could not be salvaged.
  ///
  /// [shape] is returned rather than inferred from [salvage] because the two
  /// answer different questions. Salvage reports what could be *recovered*;
  /// only the bytes can say whether anything sensitive is still *in there*.
  /// A store truncated mid-value — the ordinary damage shape — holds most of a
  /// vault key or an entire refresh token in plaintext while
  /// [_stringEntryPattern] matches nothing at all, because it requires the
  /// value's closing quote.
  static Future<({SalvagedPrefsCredentials salvaged, String? backupPath, PrefsStoreShape? shape})> quarantine({
    File? storeFileOverride,
  }) async {
    final file = storeFileOverride ?? await storeFile();
    if (!await file.exists()) {
      return (salvaged: SalvagedPrefsCredentials.empty, backupPath: null, shape: null);
    }

    final bytes = await file.readAsBytes();
    final shape = PrefsStoreShape.of(bytes);
    final salvaged = salvage(_decodeForSalvage(bytes));

    final stamp = _stamp();
    final backup = File(p.join(file.parent.path, 'shared_preferences.corrupt-$stamp.json'));
    try {
      await file.rename(backup.path);
    } on FileSystemException catch (error, stackTrace) {
      // Cross-device or locked; copy-then-delete keeps the bytes rather than
      // failing the repair outright.
      appLogger.w(
        'Preference store quarantine could not rename; copying instead',
        error: error,
        stackTrace: stackTrace,
      );
      await file.copy(backup.path);
      await file.delete();
    }

    appLogger.w(
      'Quarantined a corrupt preference store'
      ' ($shape; vault key salvaged: ${salvaged.vaultKey != null},'
      ' sessions salvaged: ${salvaged.sessions.length}, lost: ${salvaged.losses})',
    );
    return (salvaged: salvaged, backupPath: backup.path, shape: shape);
  }

  /// Deletes a quarantined store so the user is not left holding a
  /// credential-bearing file indefinitely.
  static Future<void> deleteBackup(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  // A `"key": "value"` pair with JSON-escaped halves. Deliberately tolerant of
  // the surrounding object being unterminated.
  static final RegExp _stringEntryPattern = RegExp(r'"((?:[^"\\]|\\.)*)"\s*:\s*"((?:[^"\\]|\\.)*)"');

  /// The vault generates exactly 32 random bytes; anything else would make
  /// `AesGcm.with256bits()` throw on first use, which is worse than no key.
  static bool _isVaultKey(String value) {
    if (value.isEmpty) return false;
    try {
      return base64Decode(value).length == 32;
    } catch (_) {
      return false;
    }
  }

  /// The legacy Plex slot is an opaque bearer token. Registering it as a token
  /// also covers its URL-encoded form.
  static bool _registerLegacyPlexToken(String value) {
    LogRedactionManager.registerToken(value);
    return true;
  }

  /// Validates a session payload with its owning codec and registers every
  /// secret it carries individually.
  ///
  /// Registering only the encoded payload would redact it just when it appears
  /// verbatim; a bare access token, refresh token or session cookie quoted on
  /// its own would still leak. The decode step already hands us the fields, so
  /// harvest them while they are in scope.
  static bool _validateAndRegisterSession(String key, String encoded) {
    try {
      if (isSeerrSessionPrefKey(key)) {
        final session = SeerrSession.decode(encoded);
        LogRedactionManager.registerToken(session.cookie);
        // `secret` is CredentialVault ciphertext at rest; the plaintext is not
        // available here, so register the stored form.
        LogRedactionManager.registerCustomValue(session.secret);
        LogRedactionManager.registerServerUrl(session.baseUrl);
        return true;
      }
      final base = profileScopedCredentialBaseKey(key);
      final service = TrackerService.values.where((s) => base == '${s.name}_session').firstOrNull;
      if (service == null) return false;
      final session = TrackerSession.decode(encoded, service: service);
      LogRedactionManager.registerToken(session.accessToken);
      LogRedactionManager.registerToken(session.refreshToken);
      return true;
    } catch (_) {
      return false;
    }
  }

  static String? _unescape(String rawInner) {
    try {
      return jsonDecode('"$rawInner"') as String;
    } catch (_) {
      return null;
    }
  }
}
