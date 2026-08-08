import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../media/ids.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';
import 'plex_metadata_recovery.dart';
import 'tvos_database_recovery_store.dart';
import '../models/download_models.dart';
import '../services/base_shared_preferences_service.dart';
import '../services/credential_vault.dart';
import '../utils/app_logger.dart';
import '../utils/serial_future_queue.dart';
import '../utils/global_key_utils.dart';
import '../utils/content_utils.dart';

part 'app_database.g.dart';

/// Action queued in the offline watch-progress sync table. The serialized
/// form ([id]) is what gets persisted in [OfflineWatchProgress.actionType];
/// keep these strings stable across renames so existing rows resolve.
enum OfflineActionType {
  progress,
  watched,
  unwatched;

  /// Stable string id used for persistence. Survives an enum-name rename
  /// (e.g. `progress` → `inProgress`) — `.name` would corrupt every row.
  String get id => switch (this) {
    OfflineActionType.progress => 'progress',
    OfflineActionType.watched => 'watched',
    OfflineActionType.unwatched => 'unwatched',
  };

  /// Inverse of [id]. Throws on unknown so a typo in production doesn't
  /// silently fall back to the wrong action.
  static OfflineActionType fromId(String id) => switch (id) {
    'progress' => OfflineActionType.progress,
    'watched' => OfflineActionType.watched,
    'unwatched' => OfflineActionType.unwatched,
    _ => throw ArgumentError('Unknown OfflineActionType id: $id'),
  };
}

final class AppDatabaseBootstrap {
  const AppDatabaseBootstrap({required this.database, required this.recoveryOutcome});

  final AppDatabase database;
  final TvosDatabaseRecoveryOutcome recoveryOutcome;
}

@DriftDatabase(
  tables: [
    DownloadedMedia,
    DownloadOwners,
    DownloadQueue,
    ApiCache,
    OfflineWatchProgress,
    SyncRules,
    SyncRuleDownloads,
    Connections,
    Profiles,
    ProfileConnections,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._(QueryExecutor executor, {TvosDatabaseRecoveryStore? recoveryStore})
    : this._withRecovery(executor, recoveryStore);

  /// Test-only constructor — inject an in-memory [QueryExecutor]
  /// (e.g. `NativeDatabase.memory()`) so tests don't touch real disk.
  @visibleForTesting
  AppDatabase.forTesting(QueryExecutor executor, {TvosDatabaseRecoveryStore? recoveryStore})
    : this._withRecovery(executor, recoveryStore);
  AppDatabase._withRecovery(super.e, this._recoveryStore);

  final TvosDatabaseRecoveryStore? _recoveryStore;
  final SerialFutureQueue _durabilityQueue = SerialFutureQueue();
  static final Object _durabilityZoneKey = Object();
  static final SerialFutureQueue _tvosRecoveryQueue = SerialFutureQueue();

  /// Resolves and opens the production database, removing orphaned WAL/SHM
  /// sidecars when the main database is absent (#1732), then eagerly completing
  /// Drift setup and migrations on non-tvOS. tvOS recovery retains ownership
  /// of database access ordering.
  static Future<AppDatabaseBootstrap> open({
    bool isTvos = const bool.fromEnvironment('TVOS_BUILD'),
    File? databaseFile,
    SharedPreferencesWithCache? preferences,
    QueryExecutor Function(File file)? executorFactory,
    TvosDatabaseRecoveryStore? recoveryStore,
    TvosDatabaseRecoveryPriorInstallEvidence? priorInstallEvidence,
  }) async {
    final file = databaseFile ?? await _resolveProductionDatabaseFile();
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    if (databaseFile == null && !Platform.isAndroid && !Platform.isIOS && !await file.exists()) {
      await migrateLegacyDesktopDatabase(target: file);
    }

    final databaseExisted = await file.exists();
    if (!databaseExisted) {
      await _removeOrphanedDatabaseSidecars(file);
    }

    final prefs = preferences ?? await BaseSharedPreferencesService.sharedCache();
    final store = recoveryStore ?? TvosDatabaseRecoveryStore(prefs, isTvos: isTvos);
    final database = AppDatabase._((executorFactory ?? _createNativeDatabase)(file), recoveryStore: store);
    try {
      if (!isTvos) {
        // Drift executors open lazily. Force the connection through setup and
        // migrations while failures are still covered by this close/rethrow
        // boundary and the caller's startup download-recovery decision.
        await database.customSelect('SELECT 1').get();
        // It deliberately does not claim capacity for a later write.
      }
      final outcome = await _tvosRecoveryQueue.run(
        () => store.reconcile(
          databaseExisted: databaseExisted,
          readIdentity: database._readProtectedIdentityRecoveryRows,
          readPending: database._readPendingRecoveryRows,
          restore: database._restoreRecoverySnapshot,
          hasPriorInstallEvidence:
              priorInstallEvidence ??
              () async {
                return (prefs.getString('active_app_profile_id')?.isNotEmpty ?? false) ||
                    (prefs.getBool('profile_migration_v1_done') ?? false) ||
                    (prefs.getString('credential_vault_key_v1')?.isNotEmpty ?? false);
              },
        ),
      );
      return AppDatabaseBootstrap(database: database, recoveryOutcome: outcome);
    } catch (_) {
      await database.close();
      rethrow;
    }
  }

  /// Wraps one complete registry identity mutation. Nested registry helpers
  /// share the outer commit and all identity/pending commits are serialized.
  Future<T> runIdentityMutation<T>(Future<T> Function() mutation) {
    return _runDurableMutation(TvosDatabaseRecoveryGroup.identity, mutation);
  }

  /// Establishes a fresh committed recovery generation only after a user has
  /// acknowledged [TvosDatabaseRecoveryOutcome.recoveryRequired] by starting
  /// a new sign-in. This keeps invalid evidence blocking automatic bootstrap
  /// while allowing the explicit recovery path to persist new identity rows.
  Future<void> acknowledgeTvosDatabaseRecoveryRequired() {
    final store = _recoveryStore;
    if (store == null || !store.isTvos) return Future<void>.value();

    return _durabilityQueue.run(
      () => _tvosRecoveryQueue.run(
        () => store.acknowledgeRecoveryRequired(
          readIdentity: _readProtectedIdentityRecoveryRows,
          readPending: _readPendingRecoveryRows,
        ),
      ),
    );
  }

  Future<T> _runPendingMutation<T>(Future<T> Function() mutation) {
    return _runDurableMutation(TvosDatabaseRecoveryGroup.pending, mutation);
  }

  Future<T> _runDurableMutation<T>(TvosDatabaseRecoveryGroup group, Future<T> Function() mutation) {
    final store = _recoveryStore;
    if (store == null || !store.isTvos) return mutation();
    if (Zone.current[_durabilityZoneKey] == this) return mutation();

    return _durabilityQueue.run(
      () => _tvosRecoveryQueue.run(
        () => runZoned(
          () => store.runDurableMutation(
            group: group,
            mutation: mutation,
            readIdentity: _readProtectedIdentityRecoveryRows,
            readPending: _readPendingRecoveryRows,
          ),
          zoneValues: {_durabilityZoneKey: this},
        ),
      ),
    );
  }

  /// Recovery preferences are a second persisted copy of identity rows. Run
  /// the same credential-vault cutover before reading those rows so a legacy
  /// plaintext database can never become an authoritative plaintext image.
  Future<Map<String, Object?>> _readProtectedIdentityRecoveryRows() async {
    await _migrateLegacyCredentialsBeforeRecoverySnapshot();
    return _readIdentityRecoveryRows();
  }

  Future<void> _migrateLegacyCredentialsBeforeRecoverySnapshot() async {
    final connectionUpdates = <(String, String)>[];
    for (final row in await select(connections).get()) {
      final decoded = jsonDecode(row.configJson);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid connection configuration');
      }
      if (!_containsPlaintextConnectionCredential(row.kind, decoded)) continue;
      final protected = await CredentialVault.protectConnectionConfig(row.kind, decoded);
      connectionUpdates.add((row.id, jsonEncode(protected)));
    }

    final tokenUpdates = <(String, String, String)>[];
    for (final row in await select(profileConnections).get()) {
      if (row.userToken.isEmpty || CredentialVault.isProtected(row.userToken)) continue;
      tokenUpdates.add((row.profileId, row.connectionId, await CredentialVault.protect(row.userToken)));
    }
    if (connectionUpdates.isEmpty && tokenUpdates.isEmpty) return;

    await transaction(() async {
      for (final (id, configJson) in connectionUpdates) {
        await (update(
          connections,
        )..where((table) => table.id.equals(id))).write(ConnectionsCompanion(configJson: Value(configJson)));
      }
      for (final (profileId, connectionId, token) in tokenUpdates) {
        await (update(profileConnections)
              ..where((table) => table.profileId.equals(profileId) & table.connectionId.equals(connectionId)))
            .write(ProfileConnectionsCompanion(userToken: Value(token)));
      }
    });
  }

  static bool _containsPlaintextConnectionCredential(String kind, Map<String, dynamic> config) {
    bool isPlaintext(Object? value) => value is String && value.isNotEmpty && !CredentialVault.isProtected(value);

    if (kind == 'jellyfin' || kind == 'emby') return isPlaintext(config['accessToken']);
    if (kind != 'plex') return false;
    if (isPlaintext(config['accountToken'])) return true;
    final servers = config['servers'];
    return servers is List && servers.any((server) => server is Map && isPlaintext(server['accessToken']));
  }

  Future<Map<String, Object?>> _readIdentityRecoveryRows() async {
    final connectionRows = await (select(connections)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final profileRows = await (select(profiles)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final joinRows = await (select(
      profileConnections,
    )..orderBy([(t) => OrderingTerm.asc(t.profileId), (t) => OrderingTerm.asc(t.connectionId)])).get();
    // Drift's generated serializer is the recovery image's column schema:
    // `toJson`/`fromJson` use these camelCase keys, so the read and restore
    // sides can never drift apart when a column is added or renamed.
    return {
      'connections': [for (final row in connectionRows) row.toJson()],
      'profiles': [for (final row in profileRows) row.toJson()],
      'profileConnections': [for (final row in joinRows) row.toJson()],
    };
  }

  Future<Map<String, Object?>> _readPendingRecoveryRows() async {
    final rows = await (select(offlineWatchProgress)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    return {
      'offlineWatchProgress': [for (final row in rows) row.toJson()],
    };
  }

  Future<void> _restoreRecoverySnapshot(TvosDatabaseRecoverySnapshot snapshot) async {
    final connectionRows = _decodeRecoveryRows(snapshot.identity, 'connections', ConnectionRow.fromJson);
    final profileRows = _decodeRecoveryRows(snapshot.identity, 'profiles', ProfileRow.fromJson);
    final joinRows = _decodeRecoveryRows(snapshot.identity, 'profileConnections', ProfileConnectionRow.fromJson);
    final pendingRows = _decodeRecoveryRows(
      snapshot.pending,
      'offlineWatchProgress',
      OfflineWatchProgressItem.fromJson,
    );

    // Recovery images from releases before the credential vault may contain
    // plaintext secrets. Protect them before they cross into Drift; already
    // protected values remain byte-identical because vault protection is
    // idempotent.
    for (var index = 0; index < connectionRows.length; index++) {
      final row = connectionRows[index];
      final decoded = jsonDecode(row.configJson);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid connection configuration');
      }
      if (_containsPlaintextConnectionCredential(row.kind, decoded)) {
        connectionRows[index] = row.copyWith(
          configJson: jsonEncode(await CredentialVault.protectConnectionConfig(row.kind, decoded)),
        );
      }
    }
    for (var index = 0; index < joinRows.length; index++) {
      final row = joinRows[index];
      if (row.userToken.isNotEmpty && !CredentialVault.isProtected(row.userToken)) {
        joinRows[index] = row.copyWith(userToken: await CredentialVault.protect(row.userToken));
      }
    }

    await transaction(() async {
      // Recovery completion (the durable marker removal) is deliberately
      // separate from this transaction. Replace the snapshot-owned rows so a
      // restart can replay the same committed image after a crash or marker
      // removal failure without hitting primary-key conflicts.
      await delete(profileConnections).go();
      await delete(profiles).go();
      await delete(connections).go();
      await delete(offlineWatchProgress).go();
      // `toCompanion(false)` writes every column explicitly, including the
      // nulls, so a restored row is byte-identical to the captured one rather
      // than picking up column defaults.
      for (final row in connectionRows) {
        await into(connections).insert(row.toCompanion(false));
      }
      for (final row in profileRows) {
        await into(profiles).insert(row.toCompanion(false));
      }
      for (final row in joinRows) {
        await into(profileConnections).insert(row.toCompanion(false));
      }
      for (final row in pendingRows) {
        await into(offlineWatchProgress).insert(row.toCompanion(false));
      }
    });
  }

  static List<T> _decodeRecoveryRows<T extends DataClass>(
    Map<String, Object?> group,
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final value = group[key];
    if (value is! List) throw _invalidRecoveryImage;
    return [
      for (final row in value)
        if (row is Map<String, dynamic>) _decodeRecoveryRow(row, fromJson) else throw _invalidRecoveryImage,
    ];
  }

  /// Reads one row through drift's generated deserializer and rejects anything
  /// that does not round-trip back to the exact same map. Drift already throws
  /// on a missing or mistyped required column; the round-trip additionally
  /// rejects unknown and missing-but-nullable columns, which the serializer
  /// would otherwise accept silently.
  static T _decodeRecoveryRow<T extends DataClass>(
    Map<String, dynamic> row,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final T decoded;
    try {
      decoded = fromJson(row);
    } catch (_) {
      throw _invalidRecoveryImage;
    }
    if (!mapEquals(decoded.toJson(), row)) throw _invalidRecoveryImage;
    return decoded;
  }

  static const FormatException _invalidRecoveryImage = FormatException('Invalid tvOS database recovery image');

  @override
  int get schemaVersion => 20;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      // Enforce ProfileConnections → Profiles/Connections cascades.
      // Drift turns FKs *off* during migrations, so the per-connection
      // pragma we set in `_openConnection` is wiped on first open. This
      // hook runs after migrations and re-enables it for subsequent
      // queries — also applies to in-memory test databases that don't go
      // through `_openConnection`.
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 7) {
          appLogger.i('Adding OfflineWatchProgress table (v7 migration)');
          await _ignoreAlreadyExists('OfflineWatchProgress table', () => m.createTable(offlineWatchProgress));
        }
        if (from < 8) {
          appLogger.i('Adding bgTaskId column to DownloadedMedia (v8 migration)');
          await _ignoreAlreadyExists(
            'DownloadedMedia.bgTaskId column',
            () => m.addColumn(downloadedMedia, downloadedMedia.bgTaskId),
          );
        }
        if (from < 9) {
          appLogger.i('Adding mediaIndex column to DownloadedMedia (v9 migration)');
          await _ignoreAlreadyExists(
            'DownloadedMedia.mediaIndex column',
            () => m.addColumn(downloadedMedia, downloadedMedia.mediaIndex),
          );
        }
        if (from < 10) {
          appLogger.i('Adding SyncRules table (v10 migration)');
          await _ignoreAlreadyExists('SyncRules table', () => m.createTable(syncRules));
        }
        if (from < 11) {
          appLogger.i('Adding enabled column to SyncRules (v11 migration)');
          await _ignoreAlreadyExists('SyncRules.enabled column', () => m.addColumn(syncRules, syncRules.enabled));
        }
        if (from < 12) {
          appLogger.i('Adding downloadFilter column to SyncRules (v12 migration)');
          await _ignoreAlreadyExists(
            'SyncRules.downloadFilter column',
            () => m.addColumn(syncRules, syncRules.downloadFilter),
          );
        }
        if (from < 13) {
          appLogger.i('Adding indexes on DownloadedMedia hot-queried columns (v13 migration)');
          final indexes = {
            'idx_downloaded_media_status': idxDownloadedMediaStatus,
            'idx_downloaded_media_server': idxDownloadedMediaServer,
            'idx_downloaded_media_parent': idxDownloadedMediaParent,
            'idx_downloaded_media_grandparent': idxDownloadedMediaGrandparent,
          };
          for (final entry in indexes.entries) {
            await _ignoreAlreadyExists('Index ${entry.key}', () => m.create(entry.value));
          }
        }
        if (from < 14) {
          appLogger.i(
            'Adding Connections, Profiles, ProfileConnections, DownloadOwners + scope/profile columns (v14 migration)',
          );

          await _ignoreAlreadyExists('Connections table', () => m.createTable(connections));
          await _ignoreAlreadyExists('Index idx_connections_kind', () => m.create(idxConnectionsKind));

          await _ignoreAlreadyExists('Profiles table', () => m.createTable(profiles));
          await _ignoreAlreadyExists('Index idx_profiles_kind', () => m.create(idxProfilesKind));

          await _ignoreAlreadyExists('ProfileConnections table', () => m.createTable(profileConnections));
          await _ignoreAlreadyExists(
            'Index idx_profile_connections_connection_id',
            () => m.create(idxProfileConnectionsConnectionId),
          );
          await _ignoreAlreadyExists(
            'Index idx_profile_connections_profile_id',
            () => m.create(idxProfileConnectionsProfileId),
          );

          await _ignoreAlreadyExists('DownloadOwners table', () => m.createTable(downloadOwners));
          await _ignoreAlreadyExists('Index idx_download_owners_profile', () => m.create(idxDownloadOwnersProfile));
          await _ignoreAlreadyExists(
            'Index idx_download_owners_global_key',
            () => m.create(idxDownloadOwnersGlobalKey),
          );

          await _ignoreAlreadyExists(
            'DownloadedMedia.clientScopeId column',
            () => m.addColumn(downloadedMedia, downloadedMedia.clientScopeId),
          );
          await _ignoreAlreadyExists(
            'OfflineWatchProgress.clientScopeId column',
            () => m.addColumn(offlineWatchProgress, offlineWatchProgress.clientScopeId),
          );
          await _ignoreAlreadyExists('SyncRules.profileId column', () => m.addColumn(syncRules, syncRules.profileId));
          await _ignoreAlreadyExists(
            'OfflineWatchProgress.profileId column',
            () => m.addColumn(offlineWatchProgress, offlineWatchProgress.profileId),
          );

          await customStatement('''
            UPDATE downloaded_media
            SET client_scope_id = (
              SELECT id FROM connections
              WHERE kind = 'jellyfin'
                AND substr(id, 1, length(downloaded_media.server_id) + 1) = downloaded_media.server_id || '/'
              LIMIT 1
            )
            WHERE client_scope_id IS NULL
              AND EXISTS (
                SELECT 1 FROM connections
                WHERE kind = 'jellyfin'
                  AND substr(id, 1, length(downloaded_media.server_id) + 1) = downloaded_media.server_id || '/'
              )
          ''');
          await customStatement('''
            UPDATE offline_watch_progress
            SET client_scope_id = (
              SELECT id FROM connections
              WHERE kind = 'jellyfin'
                AND substr(id, 1, length(offline_watch_progress.server_id) + 1) = offline_watch_progress.server_id || '/'
              LIMIT 1
            )
            WHERE client_scope_id IS NULL
              AND EXISTS (
                SELECT 1 FROM connections
                WHERE kind = 'jellyfin'
                  AND substr(id, 1, length(offline_watch_progress.server_id) + 1) = offline_watch_progress.server_id || '/'
              )
          ''');

          await _ignoreAlreadyExists(
            'Index idx_offline_watch_progress_server',
            () => m.create(idxOfflineWatchProgressServer),
          );
          await _ignoreAlreadyExists('Index idx_sync_rules_profile', () => m.create(idxSyncRulesProfile));
          await _ignoreAlreadyExists(
            'Index idx_offline_watch_progress_profile',
            () => m.create(idxOfflineWatchProgressProfile),
          );
        }
        if (from < 15) {
          appLogger.i('Adding mediaSourceId column to DownloadedMedia (v15 migration)');
          await _ignoreAlreadyExists(
            'DownloadedMedia.mediaSourceId column',
            () => m.addColumn(downloadedMedia, downloadedMedia.mediaSourceId),
          );
        }
        if (from < 16) {
          appLogger.i('Adding includeSpecials column to SyncRules (v16 migration)');
          await _ignoreAlreadyExists(
            'SyncRules.includeSpecials column',
            () => m.addColumn(syncRules, syncRules.includeSpecials),
          );
        }
        if (from < 17) {
          appLogger.i('Scoping pinned legacy Plex metadata before removing bare cache rows (v17 migration)');
          await customStatement(
            _rescopePinnedPlexMetadataStatement(
              namespaceExpression: "'/~plex-profile/' || owner.profile_id || ':'",
              ownerJoin: '''JOIN download_owners AS owner
                ON owner.global_key = metadata.global_key''',
            ),
          );
          // A direct pre-v14 upgrade has no owners yet: profiles and owner
          // adoption are bootstrapped only after the database opens. Preserve
          // those downloads in the neutral Plex transfer namespace so the
          // first profile can adopt them without inheriting legacy watch data.
          await customStatement(
            _rescopePinnedPlexMetadataStatement(
              namespaceExpression: "'/~plex-transfer:'",
              ownerFilter: '''AND NOT EXISTS (
                  SELECT 1
                  FROM download_owners AS owner
                  WHERE owner.global_key = metadata.global_key
                )''',
            ),
          );

          final transferRows = await customSelect('''
            SELECT cache_key, data
            FROM api_cache
            WHERE instr(
              substr(cache_key, 1, instr(cache_key, ':') - 1),
              '/~plex-transfer'
            ) > 0
              AND instr(cache_key, ':/library/metadata/') > 0
          ''').get();
          for (final row in transferRows) {
            final cacheKey = row.read<String>('cache_key');
            try {
              final sanitized = sanitizePlexMetadataForOwnerlessTransfer(row.read<String>('data'));
              await customStatement('UPDATE api_cache SET data = ? WHERE cache_key = ?', [sanitized, cacheKey]);
            } on FormatException catch (error, stackTrace) {
              appLogger.w(
                'Discarding invalid legacy Plex transfer metadata for $cacheKey',
                error: error,
                stackTrace: stackTrace,
              );
              await customStatement('DELETE FROM api_cache WHERE cache_key = ?', [cacheKey]);
            }
          }

          // Only mark a physical row as transferable when its sanitized leaf
          // exists. Parent-only cache remnants cannot hydrate an offline item.
          await customStatement('''
            UPDATE downloaded_media
            SET client_scope_id = server_id || '/~plex-transfer'
            WHERE NOT EXISTS (
                SELECT 1
                FROM download_owners AS owner
                WHERE owner.global_key = downloaded_media.global_key
              )
              AND EXISTS (
                SELECT 1
                FROM api_cache AS transfer
                WHERE transfer.cache_key =
                    downloaded_media.server_id
                      || '/~plex-transfer:/library/metadata/'
                      || downloaded_media.rating_key
                  AND transfer.pinned = 1
              )
          ''');
          await customStatement('''
            WITH legacy_plex_metadata AS (
              SELECT
                cache_key,
                substr(cache_key, instr(cache_key, ':') + 1) AS endpoint
              FROM api_cache
              WHERE instr(cache_key, ':/library/metadata/') > 0
                AND instr(
                  substr(cache_key, 1, instr(cache_key, ':') - 1),
                  '/~plex-profile/'
                ) = 0
                AND instr(
                  substr(cache_key, 1, instr(cache_key, ':') - 1),
                  '/~plex-transfer'
                ) = 0
            )
            DELETE FROM api_cache
            WHERE cache_key IN (
              SELECT cache_key
              FROM legacy_plex_metadata
              WHERE (
                endpoint GLOB '/library/metadata/?*'
                AND endpoint NOT GLOB '/library/metadata/*/*'
              ) OR (
                endpoint GLOB '/library/metadata/?*/children'
                AND endpoint NOT GLOB '/library/metadata/*/*/*'
              )
            )
          ''');
        }
        if (from < 18) {
          appLogger.i('Adding safRootUri column to DownloadedMedia (v18 migration)');
          await _ignoreAlreadyExists(
            'DownloadedMedia.safRootUri column',
            () => m.addColumn(downloadedMedia, downloadedMedia.safRootUri),
          );
        }
        if (from < 19) {
          appLogger.i('Adding backend metadata scope columns to DownloadOwners (v19 migration)');
          await _ignoreAlreadyExists(
            'DownloadOwners.backend column',
            () => m.addColumn(downloadOwners, downloadOwners.backend),
          );
          await _ignoreAlreadyExists(
            'DownloadOwners.clientScopeId column',
            () => m.addColumn(downloadOwners, downloadOwners.clientScopeId),
          );
          await customStatement('''
            UPDATE download_owners
            SET client_scope_id = CASE
              WHEN EXISTS (
                SELECT 1
                FROM downloaded_media
                WHERE downloaded_media.global_key = download_owners.global_key
                  AND downloaded_media.client_scope_id LIKE '%/~plex-profile/%'
              ) THEN (
                SELECT downloaded_media.server_id || '/~plex-profile/' || download_owners.profile_id
                FROM downloaded_media
                WHERE downloaded_media.global_key = download_owners.global_key
              )
              WHEN EXISTS (
                SELECT 1
                FROM downloaded_media
                JOIN profile_connections
                  ON profile_connections.profile_id = download_owners.profile_id
                JOIN connections
                  ON connections.id = profile_connections.connection_id
                WHERE downloaded_media.global_key = download_owners.global_key
                  AND connections.kind = 'jellyfin'
                  AND profile_connections.user_identifier != ''
                  AND (
                    connections.id = downloaded_media.server_id
                    OR substr(connections.id, 1, length(downloaded_media.server_id) + 1)
                      = downloaded_media.server_id || '/'
                  )
              ) THEN (
                SELECT CASE
                  WHEN connections.id = downloaded_media.server_id
                    THEN downloaded_media.server_id || '/' || profile_connections.user_identifier
                  ELSE connections.id
                END
                FROM downloaded_media
                JOIN profile_connections
                  ON profile_connections.profile_id = download_owners.profile_id
                JOIN connections
                  ON connections.id = profile_connections.connection_id
                WHERE downloaded_media.global_key = download_owners.global_key
                  AND connections.kind = 'jellyfin'
                  AND profile_connections.user_identifier != ''
                  AND (
                    connections.id = downloaded_media.server_id
                    OR substr(connections.id, 1, length(downloaded_media.server_id) + 1)
                      = downloaded_media.server_id || '/'
                  )
                ORDER BY profile_connections.is_default DESC,
                  profile_connections.last_used_at DESC,
                  connections.id
                LIMIT 1
              )
              ELSE NULL
            END
            WHERE client_scope_id IS NULL
          ''');
          await customStatement('''
            UPDATE download_owners
            SET backend = CASE
              WHEN client_scope_id LIKE '%/~plex-profile/%' THEN 'plex'
              WHEN client_scope_id IS NOT NULL AND EXISTS (
                SELECT 1
                FROM downloaded_media
                JOIN profile_connections
                  ON profile_connections.profile_id = download_owners.profile_id
                JOIN connections
                  ON connections.id = profile_connections.connection_id
                WHERE downloaded_media.global_key = download_owners.global_key
                  AND connections.kind = 'jellyfin'
                  AND (
                    connections.id = downloaded_media.server_id
                    OR substr(connections.id, 1, length(downloaded_media.server_id) + 1)
                      = downloaded_media.server_id || '/'
                  )
              ) THEN 'jellyfin'
            END
            WHERE backend IS NULL
          ''');
        }
        if (from < 20) {
          appLogger.i('Adding sync rule download associations (v20 migration)');
          await _ignoreAlreadyExists(
            'SyncRules.downloadLinksInitialized column',
            () => m.addColumn(syncRules, syncRules.downloadLinksInitialized),
          );
          await _ignoreAlreadyExists('SyncRuleDownloads table', () => m.createTable(syncRuleDownloads));
          await _ignoreAlreadyExists(
            'Index idx_sync_rule_downloads_profile_key',
            () => m.create(idxSyncRuleDownloadsProfileKey),
          );
        }
      },
    );
  }

  Future<void> _ignoreAlreadyExists(String label, Future<void> Function() operation) async {
    try {
      await operation();
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('already exists') || message.contains('duplicate column name')) {
        appLogger.w('$label already exists during migration: $e');
        return;
      }
      rethrow;
    }
  }

  Expression<bool> _nullableTextPredicate(GeneratedColumn<String> column, String? value) {
    return value == null ? column.isNull() : column.equals(value);
  }

  /// Get all pending offline watch actions for sync
  Future<List<OfflineWatchProgressItem>> getPendingWatchActions({String? profileId}) {
    final query = select(offlineWatchProgress)..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    if (profileId != null) {
      query.where((t) => t.profileId.equals(profileId));
    }
    return query.get();
  }

  /// Claim pre-v18 offline watch actions for [profileId]. Those rows predate
  /// profile ownership and have `NULL profile_id`; the first active profile
  /// inherits them so already-watched offline progress is not stranded.
  Future<void> adoptLegacyOfflineWatchActionsForProfile(String profileId) async {
    if (profileId.isEmpty) return;
    await _runPendingMutation(
      () => (update(
        offlineWatchProgress,
      )..where((t) => t.profileId.isNull())).write(OfflineWatchProgressCompanion(profileId: Value(profileId))),
    );
  }

  /// Get pending watch actions for a specific server
  @visibleForTesting
  Future<List<OfflineWatchProgressItem>> getPendingWatchActionsForServer(ServerId serverId, {String? profileId}) {
    return (select(offlineWatchProgress)
          ..where(
            (t) =>
                t.serverId.equals(serverId) &
                (profileId == null ? const Constant(true) : t.profileId.equals(profileId)),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  SimpleSelectStatement<$OfflineWatchProgressTable, OfflineWatchProgressItem> _watchActionsQuery(
    Expression<bool> Function($OfflineWatchProgressTable table) matchesKey, {
    String? profileId,
    bool filterProfile = false,
    String? clientScopeId,
    bool filterClientScope = false,
  }) {
    return select(offlineWatchProgress)
      ..where(
        (t) =>
            matchesKey(t) &
            (filterProfile ? _nullableTextPredicate(t.profileId, profileId) : const Constant(true)) &
            (filterClientScope ? _nullableTextPredicate(t.clientScopeId, clientScopeId) : const Constant(true)),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt), (t) => OrderingTerm.desc(t.id)]);
  }

  /// Get the latest action for a specific item
  @visibleForTesting
  Future<OfflineWatchProgressItem?> getLatestWatchAction(
    String globalKey, {
    String? profileId,
    bool filterProfile = false,
    String? clientScopeId,
    bool filterClientScope = false,
  }) {
    return (_watchActionsQuery(
      (t) => t.globalKey.equals(globalKey),
      profileId: profileId,
      filterProfile: filterProfile,
      clientScopeId: clientScopeId,
      filterClientScope: filterClientScope,
    )..limit(1)).getSingleOrNull();
  }

  Future<List<OfflineWatchProgressItem>> getWatchActionsForKey(
    String globalKey, {
    String? profileId,
    bool filterProfile = false,
    String? clientScopeId,
    bool filterClientScope = false,
  }) {
    return _watchActionsQuery(
      (t) => t.globalKey.equals(globalKey),
      profileId: profileId,
      filterProfile: filterProfile,
      clientScopeId: clientScopeId,
      filterClientScope: filterClientScope,
    ).get();
  }

  Future<Map<String, List<OfflineWatchProgressItem>>> getWatchActionsForKeys(
    Set<String> globalKeys, {
    String? profileId,
    bool filterProfile = false,
    Map<String, String?>? clientScopeIdsByGlobalKey,
  }) async {
    if (globalKeys.isEmpty) return const {};
    final rows = await _watchActionsQuery(
      (t) => t.globalKey.isIn(globalKeys),
      profileId: profileId,
      filterProfile: filterProfile,
    ).get();

    final result = <String, List<OfflineWatchProgressItem>>{};
    for (final action in rows) {
      if (clientScopeIdsByGlobalKey != null && clientScopeIdsByGlobalKey.containsKey(action.globalKey)) {
        final expectedScope = clientScopeIdsByGlobalKey[action.globalKey];
        if (!_clientScopeValuesMatch(action.clientScopeId, expectedScope)) continue;
      }
      result.putIfAbsent(action.globalKey, () => <OfflineWatchProgressItem>[]).add(action);
    }
    return result;
  }

  /// Get the latest actions for multiple items in a single query
  ///
  /// Returns a map of globalKey -> latest action for each key.
  /// Keys with no actions will not be present in the returned map.
  Future<Map<String, OfflineWatchProgressItem>> getLatestWatchActionsForKeys(
    Set<String> globalKeys, {
    String? profileId,
    bool filterProfile = false,
    Map<String, String?>? clientScopeIdsByGlobalKey,
  }) async {
    final actionsByKey = await getWatchActionsForKeys(
      globalKeys,
      profileId: profileId,
      filterProfile: filterProfile,
      clientScopeIdsByGlobalKey: clientScopeIdsByGlobalKey,
    );
    return {for (final entry in actionsByKey.entries) entry.key: entry.value.first};
  }

  bool _clientScopeValuesMatch(String? actual, String? expected) {
    final normalizedActual = actual == null || actual.isEmpty ? null : actual;
    final normalizedExpected = expected == null || expected.isEmpty ? null : expected;
    return normalizedActual == normalizedExpected;
  }

  /// Insert or update a progress action (merges with existing).
  Future<({int rowId, int revision})> upsertProgressAction({
    String? profileId,
    required ServerId serverId,
    String? clientScopeId,
    required String ratingKey,
    required int viewOffset,
    required int? duration,
    required bool shouldMarkWatched,
  }) async {
    return _runPendingMutation(() async {
      final globalKey = buildGlobalKey(ServerId(serverId), ratingKey);
      final now = DateTime.now().millisecondsSinceEpoch;

      return transaction(() async {
        final existing =
            await (select(offlineWatchProgress)
                  ..where(
                    (t) =>
                        t.globalKey.equals(globalKey) &
                        _nullableTextPredicate(t.profileId, profileId) &
                        _nullableTextPredicate(t.clientScopeId, clientScopeId) &
                        t.actionType.equals(OfflineActionType.progress.id),
                  )
                  ..orderBy([(t) => OrderingTerm.asc(t.id)]))
                .get();

        final keep = existing.isEmpty ? null : existing.first;
        if (keep != null) {
          // The row id survives a merge, so its timestamp must advance even
          // when multiple playback updates land in one clock millisecond.
          final nextRevision = keep.updatedAt + 1;
          final revision = now > nextRevision ? now : nextRevision;
          // A merge is a new logical action; retry history belongs only to
          // the revision whose server write failed.
          await (update(offlineWatchProgress)..where((t) => t.id.equals(keep.id))).write(
            OfflineWatchProgressCompanion(
              viewOffset: Value(viewOffset),
              duration: Value(duration),
              shouldMarkWatched: Value(shouldMarkWatched),
              profileId: Value(profileId),
              clientScopeId: Value(clientScopeId),
              updatedAt: Value(revision),
              syncAttempts: const Value(0),
              lastError: const Value<String?>(null),
            ),
          );
          final duplicateIds = existing.skip(1).map((row) => row.id).toList(growable: false);
          if (duplicateIds.isNotEmpty) {
            await (delete(offlineWatchProgress)..where((t) => t.id.isIn(duplicateIds))).go();
          }
          return (rowId: keep.id, revision: revision);
        }

        final rowId = await into(offlineWatchProgress).insert(
          OfflineWatchProgressCompanion.insert(
            serverId: serverId,
            profileId: Value(profileId),
            clientScopeId: Value(clientScopeId),
            ratingKey: ratingKey,
            globalKey: globalKey,
            actionType: OfflineActionType.progress.id,
            viewOffset: Value(viewOffset),
            duration: Value(duration),
            shouldMarkWatched: Value(shouldMarkWatched),
            createdAt: now,
            updatedAt: now,
          ),
        );
        return (rowId: rowId, revision: now);
      });
    });
  }

  /// Insert a manual watch action (watched or unwatched).
  /// Removes conflicting actions for the same item.
  Future<({int rowId, int revision})> insertWatchAction({
    String? profileId,
    required ServerId serverId,
    String? clientScopeId,
    required String ratingKey,
    required String actionType, // 'watched' or 'unwatched'
  }) async {
    return _runPendingMutation(() async {
      final globalKey = buildGlobalKey(ServerId(serverId), ratingKey);
      final now = DateTime.now().millisecondsSinceEpoch;

      return transaction(() async {
        // Remove conflicting actions (opposite action type and progress).
        await (delete(offlineWatchProgress)..where(
              (t) =>
                  t.globalKey.equals(globalKey) &
                  _nullableTextPredicate(t.profileId, profileId) &
                  _nullableTextPredicate(t.clientScopeId, clientScopeId),
            ))
            .go();

        final rowId = await into(offlineWatchProgress).insert(
          OfflineWatchProgressCompanion.insert(
            serverId: serverId,
            profileId: Value(profileId),
            clientScopeId: Value(clientScopeId),
            ratingKey: ratingKey,
            globalKey: globalKey,
            actionType: actionType,
            createdAt: now,
            updatedAt: now,
          ),
        );
        return (rowId: rowId, revision: now);
      });
    });
  }

  /// Drop queued `progress` rows for one item, leaving `watched`/`unwatched`
  /// rows alone. Returns how many were removed.
  ///
  /// The mirror of the purge [insertWatchAction] performs: a terminal watch
  /// state written straight to the server (the online path, which queues
  /// nothing) also supersedes any progress still waiting to replay. Without
  /// it, [getPendingWatchActions] hands back the older progress row — it
  /// orders by `createdAt` — and replaying it rewrites the resume position the
  /// mark just cleared, pinning the item to Continue Watching (#1812).
  ///
  /// When [beforeRevision] is present, the notifier is settling a persisted
  /// offline mark. Its listener is asynchronous, so only older revisions are
  /// stale; an equal or newer progress revision is a genuine concurrent rewatch.
  Future<int> deleteQueuedProgressForItem({
    String? profileId,
    required ServerId serverId,
    String? clientScopeId,
    required String ratingKey,
    int? beforeRevision,
  }) {
    return _runPendingMutation(() async {
      final globalKey = buildGlobalKey(ServerId(serverId), ratingKey);
      return (delete(offlineWatchProgress)..where(
            (t) =>
                t.globalKey.equals(globalKey) &
                _nullableTextPredicate(t.profileId, profileId) &
                _nullableTextPredicate(t.clientScopeId, clientScopeId) &
                t.actionType.equals(OfflineActionType.progress.id) &
                (beforeRevision == null ? const Constant(true) : t.updatedAt.isSmallerThanValue(beforeRevision)),
          ))
          .go();
    });
  }

  /// Delete a watch action only if it is still the snapshotted revision.
  Future<bool> deleteWatchActionIfUnchanged(int id, int revision) {
    return _runPendingMutation(() async {
      final deleted = await (delete(
        offlineWatchProgress,
      )..where((t) => t.id.equals(id) & t.updatedAt.equals(revision))).go();
      return deleted != 0;
    });
  }

  /// Update the retry state only if the action is still the snapshotted revision.
  Future<bool> updateSyncAttemptIfUnchanged(int id, int revision, String? errorMessage) {
    return _runPendingMutation(() async {
      final existing = await (select(
        offlineWatchProgress,
      )..where((t) => t.id.equals(id) & t.updatedAt.equals(revision))).getSingleOrNull();
      if (existing == null) return false;

      final updated = await (update(offlineWatchProgress)..where((t) => t.id.equals(id) & t.updatedAt.equals(revision)))
          .write(
            OfflineWatchProgressCompanion(
              syncAttempts: Value(existing.syncAttempts + 1),
              lastError: Value(errorMessage),
            ),
          );
      return updated != 0;
    });
  }

  /// Delete a specific watch action outside a snapshotted replay.
  Future<void> deleteWatchAction(int id) {
    return _runPendingMutation(() async {
      await (delete(offlineWatchProgress)..where((t) => t.id.equals(id))).go();
    });
  }

  /// Update retry state outside a snapshotted replay.
  Future<void> updateSyncAttempt(int id, String? errorMessage) {
    return _runPendingMutation(() async {
      final existing = await (select(offlineWatchProgress)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (existing == null) return;

      await (update(offlineWatchProgress)..where((t) => t.id.equals(id))).write(
        OfflineWatchProgressCompanion(syncAttempts: Value(existing.syncAttempts + 1), lastError: Value(errorMessage)),
      );
    });
  }

  /// Get count of pending sync items
  Future<int> getPendingSyncCount({String? profileId, int? maxSyncAttempts}) async {
    final query = selectOnly(offlineWatchProgress)..addColumns([offlineWatchProgress.id.count()]);
    if (profileId != null) {
      query.where(offlineWatchProgress.profileId.equals(profileId));
    }
    if (maxSyncAttempts != null) {
      query.where(offlineWatchProgress.syncAttempts.isSmallerThanValue(maxSyncAttempts));
    }
    final count = await query.map((row) => row.read(offlineWatchProgress.id.count())).getSingle();
    return count ?? 0;
  }

  /// Clear all pending watch actions (e.g., after logout)
  Future<void> clearAllWatchActions() {
    return _runPendingMutation(() async {
      await delete(offlineWatchProgress).go();
    });
  }

  /// Drop a removed profile's queued watch actions (profile teardown).
  Future<void> deleteWatchActionsForProfile(String profileId) async {
    await _runPendingMutation(() async {
      await (delete(offlineWatchProgress)..where((t) => t.profileId.equals(profileId))).go();
    });
  }

  Future<List<SyncRuleItem>> getSyncRules({String? profileId}) {
    final query = select(syncRules);
    if (profileId != null) {
      query.where((t) => t.profileId.equals(profileId));
    }
    return query.get();
  }

  Future<SyncRuleItem?> getSyncRule(String globalKey) {
    return (select(syncRules)..where((t) => t.globalKey.equals(globalKey))).getSingleOrNull();
  }

  Future<void> associateSyncRuleDownload(SyncRuleItem rule, String downloadGlobalKey) {
    return into(syncRuleDownloads).insertOnConflictUpdate(
      SyncRuleDownloadsCompanion.insert(
        syncRuleId: rule.id,
        profileId: rule.profileId,
        downloadGlobalKey: downloadGlobalKey,
      ),
    );
  }

  Future<void> markSyncRuleDownloadLinksInitialized(String globalKey) {
    return (update(syncRules)..where((t) => t.globalKey.equals(globalKey))).write(
      const SyncRulesCompanion(downloadLinksInitialized: Value(true)),
    );
  }

  /// Returns uninitialized collection/playlist rules and every show/season
  /// rule whose local ancestry-derived links must be refreshed before cleanup.
  Future<List<SyncRuleItem>> getUninitializedSyncRulesForServer({
    required String profileId,
    required ServerId serverId,
  }) {
    return (select(syncRules)..where(
          (t) =>
              t.profileId.equals(profileId) &
              t.serverId.equals(serverId) &
              (t.downloadLinksInitialized.equals(false) |
                  t.targetType.isIn(const [ContentTypes.show, ContentTypes.season])),
        ))
        .get();
  }

  Future<List<SyncRuleDownloadItem>> getSyncRuleDownloadLinks(int syncRuleId) {
    return (select(syncRuleDownloads)..where((t) => t.syncRuleId.equals(syncRuleId))).get();
  }

  Future<List<String>> getOwnedDownloadKeysForAncestorRule({
    required String profileId,
    required ServerId serverId,
    required String ratingKey,
    required bool matchGrandparent,
  }) async {
    final query = select(
      downloadedMedia,
    ).join([innerJoin(downloadOwners, downloadOwners.globalKey.equalsExp(downloadedMedia.globalKey))]);
    final ancestorMatches = matchGrandparent
        ? downloadedMedia.grandparentRatingKey.equals(ratingKey) | downloadedMedia.parentRatingKey.equals(ratingKey)
        : downloadedMedia.parentRatingKey.equals(ratingKey);
    query.where(
      downloadOwners.profileId.equals(profileId) &
          downloadedMedia.serverId.equals(serverId) &
          downloadedMedia.status.isIn([
            DownloadStatus.queued.index,
            DownloadStatus.downloading.index,
            DownloadStatus.completed.index,
            DownloadStatus.paused.index,
          ]) &
          ancestorMatches,
    );
    final rows = await query.get();
    return rows.map((row) => row.readTable(downloadedMedia).globalKey).toList(growable: false);
  }

  Future<List<String>> getExclusiveSyncRuleDownloadKeys(SyncRuleItem rule) async {
    final links = await getSyncRuleDownloadLinks(rule.id);
    if (links.isEmpty) return const [];

    final keys = links.map((link) => link.downloadGlobalKey).toSet();
    final allLinks = await (select(
      syncRuleDownloads,
    )..where((t) => t.profileId.equals(rule.profileId) & t.downloadGlobalKey.isIn(keys))).get();
    final linkedRuleCounts = <String, int>{};
    for (final link in allLinks) {
      linkedRuleCounts.update(link.downloadGlobalKey, (count) => count + 1, ifAbsent: () => 1);
    }
    return [
      for (final key in keys)
        if (linkedRuleCounts[key] == 1) key,
    ];
  }

  Future<void> insertSyncRule({
    String profileId = '',
    required ServerId serverId,
    required String ratingKey,
    required String globalKey,
    required String targetType,
    required int episodeCount,
    int mediaIndex = 0,
    String downloadFilter = 'unwatched',
    bool includeSpecials = true,
  }) async {
    // [insertOnConflictUpdate] defaults the conflict target to the primary
    // key (`id`), which is auto-incremented — the conflict never triggers
    // and the row's UNIQUE [globalKey] constraint blows up instead. Drive
    // the upsert off the public [globalKey] so re-creating a rule for the same
    // shared target updates the existing row.
    await into(syncRules).insert(
      SyncRulesCompanion.insert(
        serverId: serverId,
        profileId: Value(profileId),
        ratingKey: ratingKey,
        globalKey: globalKey,
        targetType: targetType,
        episodeCount: episodeCount,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        mediaIndex: Value(mediaIndex),
        downloadFilter: Value(downloadFilter),
        includeSpecials: Value(includeSpecials),
      ),
      onConflict: DoUpdate(
        (_) => SyncRulesCompanion(
          serverId: Value(serverId),
          profileId: Value(profileId),
          ratingKey: Value(ratingKey),
          targetType: Value(targetType),
          episodeCount: Value(episodeCount),
          mediaIndex: Value(mediaIndex),
          downloadFilter: Value(downloadFilter),
          includeSpecials: Value(includeSpecials),
        ),
        target: [syncRules.globalKey],
      ),
    );
  }

  /// Claim pre-v16 public sync rules for [profileId]. Rules created before
  /// profile ownership have an empty profile id and a public global key.
  Future<void> adoptLegacySyncRulesForProfile(String profileId) async {
    if (profileId.isEmpty) return;
    final legacyRules = await (select(syncRules)..where((t) => t.profileId.equals(''))).get();
    for (final rule in legacyRules) {
      final scopedKey = buildProfileScopedGlobalKey(profileId, ServerId(rule.serverId), rule.ratingKey);
      final duplicate = await getSyncRule(scopedKey);
      if (duplicate != null) {
        await (delete(syncRules)..where((t) => t.id.equals(rule.id))).go();
        continue;
      }
      await (update(syncRules)..where((t) => t.id.equals(rule.id))).write(
        SyncRulesCompanion(profileId: Value(profileId), globalKey: Value(scopedKey)),
      );
      await (update(
        syncRuleDownloads,
      )..where((t) => t.syncRuleId.equals(rule.id))).write(SyncRuleDownloadsCompanion(profileId: Value(profileId)));
    }
  }

  Future<void> _writeSyncRule(String globalKey, SyncRulesCompanion values) async {
    await (update(syncRules)..where((t) => t.globalKey.equals(globalKey))).write(values);
  }

  Future<void> updateSyncRuleCount(String globalKey, int episodeCount) =>
      _writeSyncRule(globalKey, SyncRulesCompanion(episodeCount: Value(episodeCount)));

  Future<void> updateSyncRuleFilter(String globalKey, String downloadFilter) =>
      _writeSyncRule(globalKey, SyncRulesCompanion(downloadFilter: Value(downloadFilter)));

  Future<void> updateSyncRuleEnabled(String globalKey, bool enabled) =>
      _writeSyncRule(globalKey, SyncRulesCompanion(enabled: Value(enabled)));

  Future<void> updateSyncRuleLastExecuted(String globalKey) =>
      _writeSyncRule(globalKey, SyncRulesCompanion(lastExecutedAt: Value(DateTime.now().millisecondsSinceEpoch)));

  Future<void> completeSyncRuleExecution(String globalKey) {
    return (update(syncRules)..where((t) => t.globalKey.equals(globalKey))).write(
      SyncRulesCompanion(
        lastExecutedAt: Value(DateTime.now().millisecondsSinceEpoch),
        downloadLinksInitialized: const Value(true),
      ),
    );
  }

  Future<void> deleteSyncRule(String globalKey) async {
    await (delete(syncRules)..where((t) => t.globalKey.equals(globalKey))).go();
  }

  /// Drop a removed profile's sync rules (profile teardown).
  Future<void> deleteSyncRulesForProfile(String profileId) async {
    await (delete(syncRules)..where((t) => t.profileId.equals(profileId))).go();
  }

  /// Drop every sync rule (full logout).
  Future<void> clearAllSyncRules() async {
    await delete(syncRules).go();
  }

  /// Get all downloaded media items (for syncing watch states)
  Future<List<DownloadedMediaItem>> getAllDownloadedMetadata() {
    return (select(downloadedMedia)..where((t) => t.status.equals(DownloadStatus.completed.index))).get();
  }
}

/// Builds the v17 statement that re-keys pinned legacy Plex metadata rows into
/// a scoped cache namespace.
///
/// The owned and the ownerless branch run the same operation over the same
/// `download_metadata_ids` set and differ only in three spots: the expression
/// spliced into the new `cache_key` ([namespaceExpression]), an optional join
/// that exposes the owning profile ([ownerJoin]), and an optional extra
/// predicate that keeps each branch to its own rows ([ownerFilter]).
String _rescopePinnedPlexMetadataStatement({
  required String namespaceExpression,
  String ownerJoin = '',
  String ownerFilter = '',
}) =>
    '''
  WITH download_metadata_ids AS (
    SELECT global_key, server_id, rating_key AS metadata_id
    FROM downloaded_media
    UNION
    SELECT global_key, server_id, parent_rating_key AS metadata_id
    FROM downloaded_media
    WHERE parent_rating_key IS NOT NULL
      AND parent_rating_key != ''
    UNION
    SELECT global_key, server_id, grandparent_rating_key AS metadata_id
    FROM downloaded_media
    WHERE grandparent_rating_key IS NOT NULL
      AND grandparent_rating_key != ''
  )
  INSERT INTO api_cache (cache_key, data, pinned, cached_at)
  SELECT DISTINCT
    metadata.server_id
      || $namespaceExpression
      || substr(source.cache_key, length(metadata.server_id) + 2),
    source.data,
    source.pinned,
    source.cached_at
  FROM download_metadata_ids AS metadata
  $ownerJoin
  JOIN api_cache AS source
    ON source.cache_key =
        metadata.server_id || ':/library/metadata/' || metadata.metadata_id
      OR source.cache_key =
        metadata.server_id || ':/library/metadata/' || metadata.metadata_id || '/children'
  WHERE source.pinned = 1
    $ownerFilter
  ON CONFLICT(cache_key) DO UPDATE SET
    data = excluded.data,
    pinned = excluded.pinned,
    cached_at = excluded.cached_at
''';

Future<File> _resolveProductionDatabaseFile() async {
  final dbFolder = (Platform.isAndroid || Platform.isIOS)
      ? await getApplicationDocumentsDirectory()
      : await getApplicationSupportDirectory();
  return File(p.join(dbFolder.path, 'plezy_downloads.db'));
}

/// Best-effort removal for sidecars left without a main database after an
/// interrupted write. This runs on every platform but only when the caller has
/// confirmed the main database is absent (#1732).
Future<void> _removeOrphanedDatabaseSidecars(File databaseFile) async {
  for (final suffix in const ['-wal', '-shm']) {
    final sidecar = File('${databaseFile.path}$suffix');
    try {
      if (await sidecar.exists()) await sidecar.delete();
    } on FileSystemException catch (error, stackTrace) {
      appLogger.w('Unable to remove orphaned database sidecar ${sidecar.path}', error: error, stackTrace: stackTrace);
    }
  }
}

QueryExecutor _createNativeDatabase(File file) {
  return NativeDatabase.createInBackground(
    file,
    setup: (db) {
      db.execute('PRAGMA journal_mode=WAL');
      db.execute('PRAGMA synchronous=NORMAL');
      // Enforce ProfileConnections → Connections cascades.
      // SQLite requires this on every connection — it is not persisted.
      db.execute('PRAGMA foreign_keys = ON');
    },
  );
}

/// Move the legacy desktop DB from `Documents/` to `ApplicationSupport/`.
/// `File.rename` only works within a single volume — Windows users with
/// OneDrive-redirected Documents (or any cross-drive setup) hit
/// `ERROR_NOT_SAME_DEVICE` (errno 17), and the uncaught throw used to
/// strand the splash on "Loading servers..." forever (#1022). Falls back
/// to a synced sibling temporary copy followed by an atomic rename on any
/// [FileSystemException], and swallows all errors so a failed migration
/// never propagates fatally. The canonical-path lock file is intentionally
/// retained: deleting it could let a new process lock a different inode while
/// an existing waiter still holds the old one.
///
/// [sourceOverride], [renameOverride], [copyOverride], and [publishOverride]
/// are test seams — production callers leave them null.
Future<void> migrateLegacyDesktopDatabase({
  required File target,
  File? sourceOverride,
  Future<void> Function(File source, String targetPath)? renameOverride,
  Future<void> Function(File source, File temporary)? copyOverride,
  Future<void> Function(File temporary, File target)? publishOverride,
}) async {
  final File oldFile;
  try {
    if (sourceOverride != null) {
      oldFile = sourceOverride;
    } else {
      final oldFolder = await getApplicationDocumentsDirectory();
      oldFile = File(p.join(oldFolder.path, 'plezy_downloads.db'));
    }
    if (!await oldFile.exists()) return;
  } catch (e, st) {
    appLogger.w('Legacy DB migration skipped before source lookup completed', error: e, stackTrace: st);
    return;
  }

  try {
    final moved = await _withLegacyDatabasePublishLock(target, () async {
      if (await target.exists()) {
        appLogger.w('Legacy DB migration skipped because ${target.path} now exists');
        return false;
      }
      if (renameOverride != null) {
        await renameOverride(oldFile, target.path);
      } else {
        await oldFile.rename(target.path);
      }
      return true;
    });
    if (!moved) return;
    appLogger.i('Moved legacy DB from ${oldFile.path} → ${target.path}');
    return;
  } on FileSystemException catch (e) {
    appLogger.w('Legacy DB rename failed (osError=${e.osError?.errorCode}); falling back to copy', error: e);
  }

  final temporary = File(
    p.join(
      target.parent.path,
      '.${p.basename(target.path)}.legacy-migration-$pid-${DateTime.now().microsecondsSinceEpoch}.tmp',
    ),
  );
  try {
    if (copyOverride != null) {
      await copyOverride(oldFile, temporary);
    } else {
      await _copyFileAndSync(oldFile, temporary);
    }

    final published = await _withLegacyDatabasePublishLock(target, () async {
      // Recheck only while holding the inter-process lock. On POSIX, rename
      // replaces an existing destination, so an unlocked check can race a
      // concurrent publisher and overwrite its now-canonical database.
      if (await target.exists()) {
        appLogger.w('Legacy DB migration skipped because ${target.path} now exists');
        return false;
      }

      // The temporary file is a sibling, so this rename stays on one volume
      // and publishes the complete, synced copy atomically.
      if (publishOverride != null) {
        await publishOverride(temporary, target);
      } else {
        await temporary.rename(target.path);
      }
      return true;
    });
    if (!published) return;
    try {
      await oldFile.delete();
    } catch (e) {
      // Leaving the source behind is non-fatal — the new file is canonical.
      appLogger.w('Legacy DB copied but old file delete failed: $e');
    }
    appLogger.i('Copied legacy DB from ${oldFile.path} → ${target.path}');
  } catch (e, st) {
    // A failed copy or final rename never touches the canonical path. Keep
    // the legacy source so a future launch can retry.
    appLogger.e('Legacy DB migration failed entirely', error: e, stackTrace: st);
  } finally {
    try {
      if (await temporary.exists()) await temporary.delete();
    } catch (e, st) {
      appLogger.w('Failed to clean legacy DB migration temporary file', error: e, stackTrace: st);
    }
  }
}

Future<T> _withLegacyDatabasePublishLock<T>(File target, Future<T> Function() action) async {
  final lockFile = File(p.join(target.parent.path, '.${p.basename(target.path)}.legacy-migration.lock'));
  final handle = await lockFile.open(mode: FileMode.append);
  var locked = false;
  try {
    await handle.lock(FileLock.blockingExclusive);
    locked = true;
    return await action();
  } finally {
    try {
      if (locked) await handle.unlock();
    } finally {
      await handle.close();
    }
  }
}

Future<void> _copyFileAndSync(File source, File destination) async {
  final input = await source.open();
  try {
    final output = await destination.open(mode: FileMode.writeOnly);
    try {
      final buffer = Uint8List(64 * 1024);
      while (true) {
        final bytesRead = await input.readInto(buffer);
        if (bytesRead == 0) break;
        await output.writeFrom(buffer, 0, bytesRead);
      }
      await output.flush();
    } finally {
      await output.close();
    }
  } finally {
    await input.close();
  }
}
