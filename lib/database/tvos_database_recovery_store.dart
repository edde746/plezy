import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_logger.dart';
import '../services/base_shared_preferences_service.dart';

/// Startup result after reconciling the purgeable tvOS database with its
/// bounded standard-domain recovery image.
enum TvosDatabaseRecoveryOutcome { notApplicable, fresh, adoptedExistingDatabase, restored, recoveryRequired }

/// The critical row group changed by a database mutation.
enum TvosDatabaseRecoveryGroup { identity, pending }

/// Deterministic fault-injection points for the recovery commit protocol.
@visibleForTesting
enum TvosDatabaseRecoveryCrashPoint { afterInvalidation, afterDatabaseMutation, afterPayloadWrite, afterFinalManifest }

/// A durability failure that is deliberately free of protected row payloads.
final class TvosDatabaseDurabilityException implements Exception {
  const TvosDatabaseDurabilityException();

  @override
  String toString() => 'TvosDatabaseDurabilityException: critical local data was not durably committed';
}

final class _TvosDatabaseRecoveryBudgetException implements Exception {
  const _TvosDatabaseRecoveryBudgetException();
}

final class _TvosDatabaseRecoveryInvalidationException implements Exception {
  const _TvosDatabaseRecoveryInvalidationException();
}

/// Raw critical rows from a validated, committed recovery image.
///
/// Values are kept raw so already-protected connection configuration and user
/// token bytes are restored exactly, without crossing a reveal boundary.
final class TvosDatabaseRecoverySnapshot {
  const TvosDatabaseRecoverySnapshot({required this.identity, required this.pending});

  final Map<String, Object?> identity;
  final Map<String, Object?> pending;
}

typedef TvosDatabaseRecoveryRowsReader = Future<Map<String, Object?>> Function();
typedef TvosDatabaseRecoveryRestore = Future<void> Function(TvosDatabaseRecoverySnapshot snapshot);
typedef TvosDatabaseRecoveryPriorInstallEvidence = Future<bool> Function();
typedef TvosDatabaseRecoveryDebugCrash = Future<void> Function(TvosDatabaseRecoveryCrashPoint point);
typedef TvosDatabaseRecoveryDebugBeforePreferenceWrite = Future<void> Function(String key);

/// Maintains the bounded two-group tvOS recovery image in UserDefaults.standard.
///
/// The manifest is invalidated before a critical Drift mutation. The changed
/// payload and its digest are written only after Drift commits, followed by the
/// committed manifest as the final write. Therefore a missing database is
/// restorable only from a complete committed image; an interrupted update
/// always requires recovery instead of silently resurrecting stale state.
final class TvosDatabaseRecoveryStore {
  TvosDatabaseRecoveryStore(
    this._preferences, {
    this.isTvos = false,
    this.preferenceImageByteCeiling = defaultPreferenceImageByteCeiling,
    this.debugCrash,
    this.debugBeforePreferenceWrite,
  });

  static const int recoveryFormatVersion = 1;
  static const int defaultPreferenceImageByteCeiling = 400000;

  static const String manifestKey = 'tvos_db_recovery_manifest_v1';
  static const String identityKey = 'tvos_db_recovery_identity_v1';
  static const String pendingKey = 'tvos_db_recovery_pending_v1';
  static const String recoveryRequiredKey = 'tvos_db_recovery_required_v1';
  static const String keyPrefix = 'tvos_db_recovery_';

  static const String _stateInvalidated = 'invalidated';
  static const String _stateCommitted = 'committed';

  final SharedPreferencesWithCache _preferences;
  final bool isTvos;
  final int preferenceImageByteCeiling;
  final TvosDatabaseRecoveryDebugCrash? debugCrash;
  final TvosDatabaseRecoveryDebugBeforePreferenceWrite? debugBeforePreferenceWrite;

  bool _recoveryDisabled = false;
  bool _manifestCacheNeedsReload = false;
  bool _pendingPayloadTruncated = false;

  /// Reconciles startup before any registry, legacy bootstrap, or UI consumer.
  Future<TvosDatabaseRecoveryOutcome> reconcile({
    required bool databaseExisted,
    required TvosDatabaseRecoveryRowsReader readIdentity,
    required TvosDatabaseRecoveryRowsReader readPending,
    required TvosDatabaseRecoveryRestore restore,
    required TvosDatabaseRecoveryPriorInstallEvidence hasPriorInstallEvidence,
  }) async {
    if (!isTvos) return TvosDatabaseRecoveryOutcome.notApplicable;

    // Tolerant read: `reconcile` runs inside `AppDatabase.open`, a fatal
    // startup step, so a wrong-typed marker would veto the launch outright on
    // a first-class TV target. An unreadable marker tells us nothing, which is
    // the same position as an absent one — default false and drop the key
    // (#1732). The manifest reads below are already inside catch-alls.
    final recoveryRequired =
        readPreferenceTolerantly(_preferences, recoveryRequiredKey, () => _preferences.getBool(recoveryRequiredKey)) ??
        false;
    if (recoveryRequired) {
      await _reloadManifestCacheIfNeeded();
      final snapshot = _readCommittedSnapshot();
      if (snapshot == null) return TvosDatabaseRecoveryOutcome.recoveryRequired;
      try {
        return await _restoreCommittedSnapshot(
          snapshot: snapshot,
          restore: restore,
          readIdentity: readIdentity,
          readPending: readPending,
        );
      } catch (_) {
        return TvosDatabaseRecoveryOutcome.recoveryRequired;
      }
    }

    if (databaseExisted) {
      // The database is authoritative. Read it outside the recovery publishing
      // failure boundary so database failures are never mistaken for damaged
      // recovery evidence.
      final identityRows = await readIdentity();
      final pendingRows = await readPending();
      try {
        await _publishAuthoritativeRows(identityRows: identityRows, pendingRows: pendingRows);
        return TvosDatabaseRecoveryOutcome.adoptedExistingDatabase;
      } on _TvosDatabaseRecoveryInvalidationException {
        // The old committed image may still be restorable. Keep recovery
        // enabled so every later critical mutation must retry invalidation
        // before it is allowed to touch the authoritative database.
        _recoveryDisabled = false;
        return TvosDatabaseRecoveryOutcome.adoptedExistingDatabase;
      } catch (error, stackTrace) {
        _disableRecovery(error, stackTrace);
        return TvosDatabaseRecoveryOutcome.adoptedExistingDatabase;
      }
    }

    final hasAnyRecoveryKey = _preferences.keys.any((key) => key.startsWith(keyPrefix));
    if (!hasAnyRecoveryKey) {
      if (await hasPriorInstallEvidence()) {
        return _markRecoveryRequired();
      }
      try {
        await _commitAuthoritativeDatabase(readIdentity: readIdentity, readPending: readPending);
        return TvosDatabaseRecoveryOutcome.fresh;
      } on _TvosDatabaseRecoveryBudgetException catch (error, stackTrace) {
        _disableRecovery(error, stackTrace);
        return TvosDatabaseRecoveryOutcome.fresh;
      } catch (_) {
        return _markRecoveryRequired();
      }
    }

    final snapshot = _readCommittedSnapshot();
    if (snapshot == null) return _markRecoveryRequired();

    try {
      return await _restoreCommittedSnapshot(
        snapshot: snapshot,
        restore: restore,
        readIdentity: readIdentity,
        readPending: readPending,
      );
    } catch (_) {
      return _markRecoveryRequired();
    }
  }

  Future<TvosDatabaseRecoveryOutcome> _restoreCommittedSnapshot({
    required TvosDatabaseRecoverySnapshot snapshot,
    required TvosDatabaseRecoveryRestore restore,
    required TvosDatabaseRecoveryRowsReader readIdentity,
    required TvosDatabaseRecoveryRowsReader readPending,
  }) async {
    await restore(snapshot);
    // The restored database may have migrated legacy plaintext credentials.
    // Publish a replacement image before clearing the replay marker so the
    // committed preference copy is protected as well.
    await _commitAuthoritativeDatabase(readIdentity: readIdentity, readPending: readPending);
    await _clearRecoveryRequired();
    return TvosDatabaseRecoveryOutcome.restored;
  }

  Future<TvosDatabaseRecoveryOutcome> _markRecoveryRequired() async {
    try {
      await debugBeforePreferenceWrite?.call(recoveryRequiredKey);
      await _preferences.setBool(recoveryRequiredKey, true);
    } catch (_) {
      throw const TvosDatabaseDurabilityException();
    }
    return TvosDatabaseRecoveryOutcome.recoveryRequired;
  }

  Future<void> _clearRecoveryRequired() async {
    // Always issue the removal. SharedPreferencesWithCache can update its
    // cache before the platform write finishes, so a failed removal may make
    // the key look absent locally while it remains durable.
    try {
      await debugBeforePreferenceWrite?.call(recoveryRequiredKey);
      await _preferences.remove(recoveryRequiredKey);
    } catch (_) {
      throw const TvosDatabaseDurabilityException();
    }
  }

  /// Runs one complete critical mutation and resolves only after its recovery
  /// image is committed. Off tvOS this is a zero-storage wrapper.
  Future<T> runDurableMutation<T>({
    required TvosDatabaseRecoveryGroup group,
    required Future<T> Function() mutation,
    required TvosDatabaseRecoveryRowsReader readIdentity,
    required TvosDatabaseRecoveryRowsReader readPending,
  }) async {
    if (!isTvos) return mutation();
    if (_recoveryDisabled) return mutation();

    await _reloadManifestCacheIfNeeded();
    final previous = _readCommittedManifestForMutation();
    // Invalidating the old image is mandatory even when the preference
    // domain is already over budget: stale identity must never become
    // restorable after the database mutation commits.
    try {
      await _invalidateRecoveryImage(previous);
    } on _TvosDatabaseRecoveryInvalidationException {
      throw const TvosDatabaseDurabilityException();
    }
    await debugCrash?.call(TvosDatabaseRecoveryCrashPoint.afterInvalidation);

    late final T result;
    late final Map<String, Object?> rows;
    try {
      result = await mutation();
      await debugCrash?.call(TvosDatabaseRecoveryCrashPoint.afterDatabaseMutation);
      rows = await (group == TvosDatabaseRecoveryGroup.identity ? readIdentity() : readPending());
    } catch (error, stackTrace) {
      // The database may already have committed, so the previous recovery
      // image is no longer safe to restore. Keep it invalidated and let later
      // mutations use the authoritative database for the rest of this process.
      _disableRecovery(error, stackTrace);
      rethrow;
    }

    try {
      await _commitChangedGroup(previous: previous, group: group, rows: rows);
    } on _TvosDatabaseRecoveryBudgetException catch (error, stackTrace) {
      _disableRecovery(error, stackTrace);
    } on TvosDatabaseDurabilityException catch (error, stackTrace) {
      if (debugCrash != null || debugBeforePreferenceWrite != null) rethrow;
      _disableRecovery(error, stackTrace);
    }
    return result;
  }

  /// Replaces an irrecoverable image with the current authoritative database
  /// only after the user explicitly starts a new sign-in.
  Future<void> acknowledgeRecoveryRequired({
    required TvosDatabaseRecoveryRowsReader readIdentity,
    required TvosDatabaseRecoveryRowsReader readPending,
  }) async {
    if (!isTvos) return;
    try {
      await _commitAuthoritativeDatabase(readIdentity: readIdentity, readPending: readPending);
      await _clearRecoveryRequired();
      _recoveryDisabled = false;
    } on _TvosDatabaseRecoveryInvalidationException {
      throw const TvosDatabaseDurabilityException();
    } on _TvosDatabaseRecoveryBudgetException catch (error, stackTrace) {
      _disableRecovery(error, stackTrace);
      throw const TvosDatabaseDurabilityException();
    }
  }

  Future<void> _commitAuthoritativeDatabase({
    required TvosDatabaseRecoveryRowsReader readIdentity,
    required TvosDatabaseRecoveryRowsReader readPending,
  }) async {
    final identityRows = await readIdentity();
    final pendingRows = await readPending();
    await _publishAuthoritativeRows(identityRows: identityRows, pendingRows: pendingRows);
  }

  Future<void> _publishAuthoritativeRows({
    required Map<String, Object?> identityRows,
    required Map<String, Object?> pendingRows,
  }) async {
    await _reloadManifestCacheIfNeeded();
    final previous = _readManifestLenient();
    await _invalidateRecoveryImage(previous);

    final identityPayload = _encodePayload(identityRows);
    final pendingPayload = _encodePayload(pendingRows);
    final manifest = _Manifest(
      state: _stateCommitted,
      identityDigest: _digest(identityPayload),
      pendingDigest: _digest(pendingPayload),
    );
    await _commitGeneration(
      payloads: {identityKey: identityPayload, pendingKey: pendingPayload},
      manifest: manifest,
      reportsPendingPayloadState: true,
    );
  }

  Future<void> _commitChangedGroup({
    required _Manifest previous,
    required TvosDatabaseRecoveryGroup group,
    required Map<String, Object?> rows,
  }) async {
    final payloadKey = group == TvosDatabaseRecoveryGroup.identity ? identityKey : pendingKey;
    final payload = _encodePayload(rows);
    final digest = _digest(payload);
    final manifest = switch (group) {
      TvosDatabaseRecoveryGroup.identity => previous.copyWith(state: _stateCommitted, identityDigest: digest),
      TvosDatabaseRecoveryGroup.pending => previous.copyWith(state: _stateCommitted, pendingDigest: digest),
    };
    await _commitGeneration(
      payloads: {payloadKey: payload},
      manifest: manifest,
      reportsPendingPayloadState: group == TvosDatabaseRecoveryGroup.pending,
    );
  }

  Future<void> _commitGeneration({
    required Map<String, String> payloads,
    required _Manifest manifest,
    required bool reportsPendingPayloadState,
  }) async {
    final committedPayloads = Map<String, String>.of(payloads);
    var committedManifest = manifest;
    var replacements = <String, String>{...committedPayloads, manifestKey: _encodeManifest(committedManifest)};
    var pendingTruncated = false;

    if (!_candidateFits(replacements)) {
      final emptyPendingPayload = _encodePayload(_emptyPendingRows);
      committedPayloads[pendingKey] = emptyPendingPayload;
      committedManifest = committedManifest.copyWith(pendingDigest: _digest(emptyPendingPayload));
      replacements = <String, String>{...committedPayloads, manifestKey: _encodeManifest(committedManifest)};
      pendingTruncated = true;
    }

    _requireCandidateFits(replacements);
    if (reportsPendingPayloadState || pendingTruncated) {
      _markPendingPayloadTruncated(pendingTruncated);
    }
    try {
      for (final entry in committedPayloads.entries) {
        await debugBeforePreferenceWrite?.call(entry.key);
        await _preferences.setString(entry.key, entry.value);
      }
      await debugCrash?.call(TvosDatabaseRecoveryCrashPoint.afterPayloadWrite);
      await debugBeforePreferenceWrite?.call(manifestKey);
      await _preferences.setString(manifestKey, _encodeManifest(committedManifest));
      await debugCrash?.call(TvosDatabaseRecoveryCrashPoint.afterFinalManifest);
    } catch (_) {
      throw const TvosDatabaseDurabilityException();
    }
  }

  TvosDatabaseRecoverySnapshot? _readCommittedSnapshot() {
    try {
      final manifest = _decodeManifest(_preferences.getString(manifestKey));
      if (manifest == null || manifest.state != _stateCommitted) return null;
      if (_currentPreferenceImageSize() > preferenceImageByteCeiling) return null;

      final identityRaw = _preferences.getString(identityKey);
      final pendingRaw = _preferences.getString(pendingKey);
      if (identityRaw == null || pendingRaw == null) return null;
      if (_digest(identityRaw) != manifest.identityDigest || _digest(pendingRaw) != manifest.pendingDigest) {
        return null;
      }

      final identity = _decodePayload(identityRaw, _identityRowKeys);
      final pending = _decodePayload(pendingRaw, _pendingRowKeys);
      if (identity == null || pending == null) return null;
      return TvosDatabaseRecoverySnapshot(identity: identity, pending: pending);
    } catch (_) {
      return null;
    }
  }

  _Manifest _readCommittedManifestForMutation() {
    try {
      final manifest = _decodeManifest(_preferences.getString(manifestKey));
      final identityRaw = _preferences.getString(identityKey);
      final pendingRaw = _preferences.getString(pendingKey);
      if (manifest == null ||
          manifest.state != _stateCommitted ||
          identityRaw == null ||
          pendingRaw == null ||
          _digest(identityRaw) != manifest.identityDigest ||
          _digest(pendingRaw) != manifest.pendingDigest) {
        throw const TvosDatabaseDurabilityException();
      }
      return manifest;
    } catch (_) {
      throw const TvosDatabaseDurabilityException();
    }
  }

  _Manifest? _readManifestLenient() {
    try {
      return _decodeManifest(_preferences.getString(manifestKey));
    } catch (_) {
      return null;
    }
  }

  Future<void> _invalidateRecoveryImage(_Manifest? previous) async {
    try {
      await _writeManifest(_invalidatedManifest(previous), enforceBudget: false);
    } on TvosDatabaseDurabilityException {
      if (previous?.state == _stateCommitted) {
        throw const _TvosDatabaseRecoveryInvalidationException();
      }
      rethrow;
    }
  }

  Future<void> _writeManifest(_Manifest manifest, {bool enforceBudget = true}) async {
    final encoded = _encodeManifest(manifest);
    if (enforceBudget) _requireCandidateFits({manifestKey: encoded});
    try {
      await debugBeforePreferenceWrite?.call(manifestKey);
      await _preferences.setString(manifestKey, encoded);
    } catch (_) {
      // SharedPreferencesWithCache updates its local value before awaiting the
      // platform write. Reload the durable domain so a failed invalidation
      // cannot leave an optimistic "invalidated" manifest blocking retries.
      _manifestCacheNeedsReload = true;
      try {
        await _reloadManifestCacheIfNeeded();
      } catch (_) {
        // The next mutation retries the durable reload before reading state.
      }
      throw const TvosDatabaseDurabilityException();
    }
  }

  Future<void> _reloadManifestCacheIfNeeded() async {
    if (!_manifestCacheNeedsReload) return;
    try {
      await _preferences.reloadCache();
      _manifestCacheNeedsReload = false;
    } catch (_) {
      throw const TvosDatabaseDurabilityException();
    }
  }

  _Manifest _invalidatedManifest(_Manifest? previous) => _Manifest(
    state: _stateInvalidated,
    identityDigest: previous?.identityDigest ?? '',
    pendingDigest: previous?.pendingDigest ?? '',
  );

  bool _candidateFits(Map<String, Object?> replacements) =>
      _preferenceImageSize({recoveryRequiredKey: true, ...replacements}) <= preferenceImageByteCeiling;

  void _requireCandidateFits(Map<String, Object?> replacements) {
    if (!_candidateFits(replacements)) {
      throw const _TvosDatabaseRecoveryBudgetException();
    }
  }

  int _currentPreferenceImageSize() => _preferenceImageSize(const {});

  int _preferenceImageSize(Map<String, Object?> replacements) {
    final keys = <String>{..._preferences.keys.where((key) => key.startsWith(keyPrefix)), ...replacements.keys}.toList()
      ..sort();
    final image = <String, Object?>{};
    for (final key in keys) {
      image[key] = replacements.containsKey(key) ? replacements[key] : _preferences.get(key);
    }
    return utf8.encode(jsonEncode(image)).length;
  }

  void _markPendingPayloadTruncated(bool truncated) {
    if (truncated && !_pendingPayloadTruncated) {
      appLogger.w('tvOS database recovery omitted pending watch progress to stay within its preference budget');
    }
    _pendingPayloadTruncated = truncated;
  }

  void _disableRecovery(Object error, StackTrace stackTrace) {
    if (_recoveryDisabled) return;
    _recoveryDisabled = true;
    appLogger.w(
      'tvOS database recovery disabled for this process; the authoritative database remains available',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static const Set<String> _identityRowKeys = {'connections', 'profiles', 'profileConnections'};
  static const Set<String> _pendingRowKeys = {'offlineWatchProgress'};
  static const Map<String, Object?> _emptyPendingRows = {'offlineWatchProgress': <Object?>[]};

  static String _encodePayload(Map<String, Object?> rows) =>
      jsonEncode({'version': recoveryFormatVersion, 'rows': rows});

  static Map<String, Object?>? _decodePayload(String raw, Set<String> expectedKeys) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> || decoded.length != 2 || decoded['version'] != recoveryFormatVersion) {
      return null;
    }
    final rows = decoded['rows'];
    if (rows is! Map<String, dynamic> ||
        rows.keys.toSet().difference(expectedKeys).isNotEmpty ||
        rows.length != expectedKeys.length) {
      return null;
    }
    for (final key in expectedKeys) {
      final value = rows[key];
      if (value is! List || value.any((row) => row is! Map<String, dynamic>)) return null;
    }
    return Map<String, Object?>.unmodifiable(rows);
  }

  static String _digest(String value) => sha256.convert(utf8.encode(value)).toString();

  static String _encodeManifest(_Manifest manifest) => jsonEncode({
    'version': recoveryFormatVersion,
    'state': manifest.state,
    'identityDigest': manifest.identityDigest,
    'pendingDigest': manifest.pendingDigest,
  });

  static _Manifest? _decodeManifest(String? raw) {
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> ||
        decoded.length != 4 ||
        decoded['version'] != recoveryFormatVersion ||
        decoded['state'] is! String ||
        decoded['identityDigest'] is! String ||
        decoded['pendingDigest'] is! String) {
      return null;
    }
    final state = decoded['state'] as String;
    final identityDigest = decoded['identityDigest'] as String;
    final pendingDigest = decoded['pendingDigest'] as String;
    if ((state != _stateInvalidated && state != _stateCommitted) ||
        (state == _stateCommitted && (identityDigest.isEmpty || pendingDigest.isEmpty))) {
      return null;
    }
    return _Manifest(state: state, identityDigest: identityDigest, pendingDigest: pendingDigest);
  }
}

final class _Manifest {
  const _Manifest({required this.state, required this.identityDigest, required this.pendingDigest});

  final String state;
  final String identityDigest;
  final String pendingDigest;

  _Manifest copyWith({String? state, String? identityDigest, String? pendingDigest}) => _Manifest(
    state: state ?? this.state,
    identityDigest: identityDigest ?? this.identityDigest,
    pendingDigest: pendingDigest ?? this.pendingDigest,
  );
}
