import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../source_database.dart';
import '../source_models.dart';
import 'sync_document.dart';
import 'sync_store.dart';

class PublicationSyncConfig {
  const PublicationSyncConfig({required this.sourceId, required this.code, this.folder = ''});
  final String sourceId;
  final String code;
  final String folder;
  Map<String, dynamic> toJson() => {'sourceId': sourceId, 'code': code, 'folder': folder};
  factory PublicationSyncConfig.fromJson(Map<String, dynamic> j) => PublicationSyncConfig(
    sourceId: j['sourceId'] as String,
    code: j['code'] as String,
    folder: j['folder'] as String? ?? '',
  );
}

class PublicationSyncConflict {
  PublicationSyncConflict(this.key, this.entry, this.values);
  final String key;
  final SourceEntry entry;
  final List<SyncVersion> values;
}

class _LocalValue {
  _LocalValue(this.value, this.localKey, this.entry, {this.progress, this.annotation});
  final Map<String, dynamic> value;
  final String localKey;
  final SourceEntry entry;
  final PublicationProgress? progress;
  final BookAnnotation? annotation;
}

typedef _EditionCandidate = ({String edition, List<dynamic> descriptor});

class _SyncCache {
  _SyncCache(Map<String, dynamic> j)
    : document = j['document'] == null ? SyncDocument() : SyncDocument.fromJson(sourceMap(j['document'])),
      observed = sourceMap(j['observed']).map((k, v) => MapEntry(k, v as String)),
      basis = sourceMap(j['basis']).map((k, v) => MapEntry(k, sourceMap(v).map((a, b) => MapEntry(a, b as int)))),
      sequence = sourceInt(j['sequence']) ?? 0,
      published = j['published'] as String? ?? '';
  final SyncDocument document;
  final Map<String, String> observed;
  final Map<String, Map<String, int>> basis;
  int sequence;
  String published;
  Map<String, dynamic> toJson() => {
    'document': document.toJson(),
    'observed': observed,
    'basis': basis,
    'sequence': sequence,
    'published': published,
  };
}

/// Profile-scoped, offline-first state replication. The durable cache and local
/// rows are updated in one SQLite transaction, including the import baseline.
class PublicationSync {
  PublicationSync(this.repository);
  final SourceRepository repository;
  final Map<String, PublicationSyncConflict> conflicts = {};
  bool running = false;
  SourceFailure? failure;
  DateTime? lastSuccess;
  static const configKey = 'publication-sync-config-v1';
  static const entryMappingsKey = 'publication-sync-entry-mappings-v1';
  static String _cacheKey(String namespace) => 'publication-sync-cache-v1:$namespace';
  void resetStatus() {
    conflicts.clear();
    failure = null;
    lastSuccess = null;
  }

  Future<PublicationSyncConfig?> config(String profile) async {
    final json = await repository.privatePreference(profile, configKey);
    return json.isEmpty ? null : PublicationSyncConfig.fromJson(json);
  }

  Future<void> configure(String profile, PublicationSyncConfig? value) async {
    if (value == null) {
      await repository.forgetPreference(profile, configKey);
      resetStatus();
      return;
    }
    SyncCipher(value.code);
    await repository.savePrivatePreference(profile, configKey, value.toJson());
    resetStatus();
  }

  static String recoveryName(String namespace) => 'plezyng-recovery-v1-$namespace.json';

  /// Exports only the encrypted sync document. The user must retain the
  /// private sync code separately; no source account or media data is bundled.
  Future<String> exportRecovery(String profile) async {
    final config = await this.config(profile);
    if (config == null) throw const SourceException(SourceFailure.unsupported);
    final cipher = SyncCipher(config.code);
    final cache = _SyncCache(await repository.preference(profile, _cacheKey(cipher.namespace)));
    final device = (await repository.preference(profile, 'publication-sync-device-v1'))['id'] as String?;
    cache.document.compactSafe(actor: device);
    final name = recoveryName(cipher.namespace);
    final encrypted = await cipher.seal(cache.document, name);
    return canonicalSyncJson({'format': 'plezyng-encrypted-recovery-v1', 'name': name, 'encrypted': encrypted});
  }

  /// Imports are additive. The recovery file is authenticated with the
  /// configured code and merged through the same causal rules as cloud state.
  Future<void> importRecovery({
    required String profile,
    required String text,
    required List<FileSource> sources,
    required Set<String> activeKeys,
  }) async {
    final config = await this.config(profile);
    if (config == null) throw const SourceException(SourceFailure.unsupported);
    try {
      if (text.length > 7 * 1024 * 1024 || utf8.encode(text).length > 7 * 1024 * 1024) {
        throw const SourceException(SourceFailure.invalidData);
      }
      final envelope = sourceMap(jsonDecode(text));
      final cipher = SyncCipher(config.code);
      final name = envelope['name'];
      if (envelope['format'] != 'plezyng-encrypted-recovery-v1' ||
          name != recoveryName(cipher.namespace) ||
          envelope['encrypted'] is! String) {
        throw const SourceException(SourceFailure.invalidData);
      }
      final incoming = await cipher.open(envelope['encrypted'] as String, name as String);
      final entries = await repository.entries(profile);
      final device = (await repository.preference(profile, 'publication-sync-device-v1'))['id'] as String?;
      final entryMappings = await sharedEntryMappings(profile);
      final cacheKey = _cacheKey(cipher.namespace);
      await repository.database.transaction(() async {
        final cache = _SyncCache(await repository.preference(profile, cacheKey));
        cache.document.merge(incoming);
        cache.document.compactSafe(actor: device);
        cache.published = '';
        await _apply(profile, cache, _identities(sources, entries, entryMappings), entryMappings, activeKeys);
        await repository.savePreference(profile, cacheKey, cache.toJson());
      });
    } on SourceException {
      rethrow;
    } on Object {
      throw const SourceException(SourceFailure.invalidData);
    }
  }

  /// Re-keys cached sync records when a source is paired under a shared
  /// library ID. Old records remain as history; every participating device
  /// needs the matching IDs before it can join the paired identity.
  Future<void> migrateSourceIdentity({
    required String profile,
    required FileSource oldSource,
    required FileSource newSource,
    required List<SourceEntry> entries,
  }) async {
    await repository.database.transaction(() async {
      final entryMappings = await sharedEntryMappings(profile);
      final identityMigrations = <String, String>{};
      final editionMigrations = <String, String>{};
      for (final entry in entries) {
        final sharedEntryId = entryMappings[entry.key];
        final oldIdentity = entryIdentity(oldSource, entry, sharedEntryId: sharedEntryId);
        final newIdentity = entryIdentity(newSource, entry, sharedEntryId: sharedEntryId);
        if (oldIdentity != newIdentity) identityMigrations[oldIdentity] = newIdentity;
        editionMigrations.addAll(
          _editionMigrationForEntry(
            entry,
            oldIdentity,
            oldSource.options['syncLibrary']?.trim().isNotEmpty == true ? sharedEntryId : null,
            newSource.options['syncLibrary']?.trim().isNotEmpty == true ? sharedEntryId : null,
          ),
        );
      }
      await _migrateCachedIdentities(profile, identityMigrations, editionMigrations);
    });
  }

  Future<String?> sharedEntryMapping(String profile, SourceEntry entry) async =>
      (await sharedEntryMappings(profile))[entry.key];

  Future<Map<String, String>> sharedEntryMappings(String profile) async {
    final raw = sourceMap((await repository.preference(profile, entryMappingsKey))['entries']);
    return {
      for (final item in raw.entries)
        if (item.value is String && RegExp(r'^[a-zA-Z0-9._-]{8,100}$').hasMatch(item.value as String))
          item.key: (item.value as String).trim().toLowerCase(),
    };
  }

  Future<void> setSharedEntryMapping({
    required String profile,
    required FileSource source,
    required SourceEntry entry,
    required String? sharedEntryId,
  }) async {
    final normalized = sharedEntryId?.trim().toLowerCase();
    if (source.options['syncLibrary']?.trim().isNotEmpty != true ||
        normalized != null && !RegExp(r'^[a-zA-Z0-9._-]{8,100}$').hasMatch(normalized)) {
      throw const SourceException(SourceFailure.invalidData);
    }
    await repository.database.transaction(() async {
      final current = await sharedEntryMappings(profile);
      final mappingKey = entry.key;
      final oldSharedEntryId = current[mappingKey];
      if (oldSharedEntryId == normalized) return;
      if (normalized != null) {
        final library = source.options['syncLibrary']!.trim().toLowerCase();
        final configuredSources = {for (final item in await repository.sources(profile)) item.id: item};
        for (final item in current.entries.where((item) => item.key != mappingKey && item.value == normalized)) {
          try {
            final localSourceId = (jsonDecode(item.key) as List).first as String;
            final otherLibrary = configuredSources[localSourceId]?.options['syncLibrary']?.trim().toLowerCase();
            if (otherLibrary == library) throw const SourceException(SourceFailure.conflict);
          } on SourceException {
            rethrow;
          } on Object {
            // Ignore malformed old aliases; only reject a verified collision.
          }
        }
      }
      final oldIdentity = entryIdentity(source, entry, sharedEntryId: oldSharedEntryId);
      final newIdentity = entryIdentity(source, entry, sharedEntryId: normalized);
      final editionMigrations = _editionMigrationForEntry(entry, oldIdentity, oldSharedEntryId, normalized);
      if (oldIdentity != newIdentity || editionMigrations.isNotEmpty) {
        await _migrateCachedIdentities(
          profile,
          oldIdentity == newIdentity ? const {} : {oldIdentity: newIdentity},
          editionMigrations,
        );
      }
      if (normalized == null) {
        current.remove(mappingKey);
      } else {
        current[mappingKey] = normalized;
      }
      await repository.savePreference(profile, entryMappingsKey, {'entries': current});
    });
  }

  static String _editionMigrationKey(String identity, PublicationMode mode, String edition) =>
      canonicalSyncJson([identity, mode.name, edition]);

  static List<_EditionCandidate> _editionCandidates(SourceEntry entry, PublicationMode mode) {
    final byEdition = <String, List<dynamic>>{};
    void add(List<PublicationFile> files, String edition) {
      byEdition.putIfAbsent(
        edition,
        () => [
          'catalog',
          for (final file in entry.files) [file.kind.name, file.mimeType.trim().toLowerCase(), file.size],
          'selection',
          for (final file in files) entry.files.indexWhere((candidate) => candidate.fingerprint == file.fingerprint),
          for (final file in files) [file.kind.name, file.mimeType.trim().toLowerCase(), file.size],
        ],
      );
    }

    if (mode == PublicationMode.reading) {
      for (final file in entry.ebooks) {
        add([file], file.fingerprint);
      }
    } else if (mode == PublicationMode.listening) {
      if (entry.audio.isNotEmpty) add(entry.audio, sourceDigest(jsonEncode(entry.audio.map((f) => f.fingerprint).toList())));
      for (final file in entry.files) {
        add([file], sourceDigest(jsonEncode([file.fingerprint])));
      }
    } else {
      if (entry.files.isNotEmpty) add(entry.files, sourceDigest(jsonEncode(entry.files.map((f) => f.fingerprint).toList())));
      for (final file in entry.files) {
        add([file], sourceDigest(jsonEncode([file.fingerprint])));
      }
    }
    return [for (final candidate in byEdition.entries) (edition: candidate.key, descriptor: candidate.value)];
  }

  static String? _sharedEditionId(SourceEntry entry, String sharedEntryId, PublicationMode mode, String edition) {
    final candidates = _editionCandidates(entry, mode);
    final matches = candidates.where((candidate) => candidate.edition == edition).toList();
    if (matches.length != 1) return null;
    final descriptor = matches.single.descriptor;
    final token = sourceDigest(canonicalSyncJson(['paired-edition-v1', sharedEntryId.trim().toLowerCase(), mode.name, descriptor]));
    if (candidates.where((candidate) {
      return sourceDigest(
            canonicalSyncJson(['paired-edition-v1', sharedEntryId.trim().toLowerCase(), mode.name, candidate.descriptor]),
          ) ==
          token;
    }).length != 1) {
      return null;
    }
    return token;
  }

  static String? _localEditionForShared(SourceEntry entry, String sharedEntryId, PublicationMode mode, String sharedEdition) {
    final matches = _editionCandidates(entry, mode).where((candidate) {
      final token = sourceDigest(
        canonicalSyncJson(['paired-edition-v1', sharedEntryId.trim().toLowerCase(), mode.name, candidate.descriptor]),
      );
      return token == sharedEdition;
    }).toList();
    return matches.length == 1 ? matches.single.edition : null;
  }

  static Map<String, String> _editionMigrationForEntry(
    SourceEntry entry,
    String oldIdentity,
    String? oldSharedEntryId,
    String? newSharedEntryId,
  ) {
    final migrations = <String, String>{};
    for (final mode in PublicationMode.values) {
      for (final candidate in _editionCandidates(entry, mode)) {
        final oldEdition = oldSharedEntryId == null
            ? candidate.edition
            : _sharedEditionId(entry, oldSharedEntryId, mode, candidate.edition) ?? candidate.edition;
        final newEdition = newSharedEntryId == null
            ? candidate.edition
            : _sharedEditionId(entry, newSharedEntryId, mode, candidate.edition) ?? candidate.edition;
        if (oldEdition != newEdition) {
          migrations[_editionMigrationKey(oldIdentity, mode, oldEdition)] = newEdition;
        }
      }
    }
    return migrations;
  }

  Future<void> _migrateCachedIdentities(
    String profile,
    Map<String, String> identityMigrations,
    Map<String, String> editionMigrations,
  ) async {
    if (identityMigrations.isEmpty && editionMigrations.isEmpty) return;
    final cacheRows = await repository.database
        .customSelect(
          "SELECT key,payload FROM preferences WHERE profile=? AND key LIKE 'publication-sync-cache-v1:%'",
          variables: [Variable(profile)],
        )
        .get();
    if (cacheRows.isEmpty) return;
    final devicePreference = await repository.preference(profile, 'publication-sync-device-v1');
    final device = devicePreference['id'] as String? ?? const Uuid().v4().replaceAll('-', '');
    if (devicePreference['id'] != device) {
      await repository.savePreference(profile, 'publication-sync-device-v1', {'id': device});
    }
    for (final cacheRow in cacheRows) {
      final cacheKey = cacheRow.read<String>('key');
      final cache = _SyncCache(sourceMap(jsonDecode(cacheRow.read<String>('payload'))));
      final additions = SyncDocument();
      for (final record in cache.document.records.entries) {
        for (final version in record.value) {
          final value = version.value;
          final oldIdentity = value['entry'];
          if (oldIdentity is! String) continue;
          final newIdentity = identityMigrations[oldIdentity] ?? oldIdentity;
          final data = sourceMap(value['data']);
          final type = value['type'];
          final mode = PublicationMode.values.where((item) => item.name == data['mode']).firstOrNull;
          final oldEdition = data['edition'];
          final newEdition = mode != null && oldEdition is String
              ? editionMigrations[_editionMigrationKey(oldIdentity, mode, oldEdition)] ?? oldEdition
              : oldEdition;
          if (newIdentity == oldIdentity && newEdition == oldEdition) continue;
          final migratedData = {...data, if (newEdition != null) 'edition': newEdition};
          final migratedValue = {...value, 'entry': newIdentity, 'data': migratedData};
          final String? migratedKey;
          if (type == 'progress' &&
              newEdition is String &&
              mode != null) {
            migratedKey = progressKey(newIdentity, newEdition, mode);
          } else if (type == 'annotation' && data['id'] is String) {
            migratedKey = annotationKey(newIdentity, data['id'] as String);
          } else {
            continue;
          }
          final sameKeyValueChanged = migratedKey == record.key && canonicalSyncJson(migratedValue) != canonicalSyncJson(value);
          var migratedClock = version.clock;
          var migratedActor = version.actor;
          if (sameKeyValueChanged) {
            final actor = device ?? version.actor;
            if (actor == null) throw const SourceException(SourceFailure.invalidData);
            migratedClock = Map<String, int>.from(version.clock);
            migratedClock[actor] = (migratedClock[actor] ?? 0) + 1;
            if (migratedClock[actor]! > 9007199254740991) throw const SourceException(SourceFailure.invalidData);
            migratedActor = actor;
          }
          additions.merge(SyncDocument({
            migratedKey: [SyncVersion(migratedClock, migratedValue, actor: migratedActor)],
          }));
          if (cache.observed[record.key] == _hash(value)) {
            cache.observed[migratedKey] = _hash(migratedValue);
          }
        }
      }
      if (additions.records.isEmpty) continue;
      cache.document.merge(additions);
      cache.document.compactSafe(actor: device);
      for (final key in additions.records.keys) {
        final versions = cache.document.records[key];
        if (versions != null) cache.basis[key] = joinedClock(versions);
      }
      cache.published = '';
      await repository.savePreference(profile, cacheKey, cache.toJson());
    }
  }

  static String entryIdentity(FileSource source, SourceEntry entry, {String? sharedEntryId}) {
    // Connection UUIDs and local profile IDs differ across installations.
    // Provider IDs plus origin identify the publication. Roots are browsing
    // preferences and do not change an existing provider object's identity.
    final library = source.options['syncLibrary'];
    if (library?.trim().isNotEmpty == true) {
      return sourceDigest(
        canonicalSyncJson(['paired-library-v1', library!.trim().toLowerCase(), sharedEntryId?.trim().toLowerCase() ?? entry.id]),
      );
    }
    return sourceDigest(
      canonicalSyncJson([
        source.kind.name,
        library?.isNotEmpty == true
            ? library
            : source.kind == FileSourceKind.local
            ? source.root
            : source.endpoint.replaceAll(RegExp(r'/+$'), ''),
        source.options['driveId'] ?? '',
        entry.id,
      ]),
    );
  }

  static String progressKey(String entry, String edition, PublicationMode mode) =>
      sourceDigest(jsonEncode(['progress', entry, edition, mode.name]));
  static String annotationKey(String entry, String id) => sourceDigest(jsonEncode(['annotation', entry, id]));
  static Map<String, dynamic> _progressValue(String identity, PublicationProgress p, {String? edition}) => {
    'type': 'progress',
    'entry': identity,
    'data': {...p.toJson(), if (edition != null) 'edition': edition}
      ..remove('entryKey')
      ..remove('session')
      ..remove('revision')
      ..remove('updatedAt'),
  };
  static Map<String, dynamic> _annotationValue(String identity, BookAnnotation a, {String? edition}) => {
    'type': 'annotation',
    'entry': identity,
    'data': {...a.toJson(), if (edition != null) 'edition': edition}
      ..remove('entryKey')
      ..remove('updatedAt'),
  };
  static String _hash(Map<String, dynamic> value) => sourceDigest(canonicalSyncJson(value));

  Future<Map<String, _LocalValue>> _locals(
    String profile,
    List<FileSource> sources,
    List<SourceEntry> entries,
    Map<String, String> entryMappings,
  ) async {
    final identities = <String, String>{};
    for (final entry in entries) {
      final source = sources.where((s) => s.id == entry.sourceId).firstOrNull;
      if (source != null) identities[entry.key] = entryIdentity(source, entry, sharedEntryId: entryMappings[entry.key]);
    }
    final byKey = {for (final e in entries) e.key: e};
    final values = <String, _LocalValue>{};
    for (final p in await repository.allProgress(profile)) {
      final identity = identities[p.entryKey];
      if (identity != null) {
        final entry = byKey[p.entryKey]!;
        final sharedEntryId = entryMappings[entry.key];
        final pairedEdition = sharedEntryId == null ? null : _sharedEditionId(entry, sharedEntryId, p.mode, p.edition);
        final edition = pairedEdition ?? p.edition;
        values[progressKey(identity, edition, p.mode)] = _LocalValue(
          _progressValue(identity, p, edition: edition),
          p.key,
          entry,
          progress: p,
        );
      }
    }
    final rows = await repository.database
        .customSelect('SELECT payload FROM annotations WHERE profile=?', variables: [Variable(profile)])
        .get();
    for (final row in rows) {
      final a = BookAnnotation.fromJson(sourceMap(jsonDecode(row.read<String>('payload'))));
      final identity = identities[a.entryKey];
      if (identity != null) {
        final entry = byKey[a.entryKey]!;
        final sharedEntryId = entryMappings[entry.key];
        final pairedEdition = sharedEntryId == null ? null : _sharedEditionId(entry, sharedEntryId, a.mode, a.edition);
        final edition = pairedEdition ?? a.edition;
        values[annotationKey(identity, a.id)] = _LocalValue(
          _annotationValue(identity, a, edition: edition),
          a.id,
          entry,
          annotation: a,
        );
      }
    }
    return values;
  }

  void _capture(_SyncCache cache, String device, Map<String, _LocalValue> locals) {
    for (final e in locals.entries) {
      final hash = _hash(e.value.value);
      if (cache.observed[e.key] == hash) continue;
      final next = cache.document.edit(e.key, device, e.value.value, cache.basis[e.key] ?? {});
      cache.basis[e.key] = next.clock;
      cache.observed[e.key] = hash;
    }
  }

  Map<String, SourceEntry> _identities(
    List<FileSource> sources,
    List<SourceEntry> entries,
    Map<String, String> entryMappings,
  ) => {
    for (final e in entries)
      if (sources.any((s) => s.id == e.sourceId))
        entryIdentity(sources.firstWhere((s) => s.id == e.sourceId), e, sharedEntryId: entryMappings[e.key]): e,
  };

  bool _compatible(SourceEntry entry, Map<String, dynamic> data, {String? sharedEntryId}) {
    final edition = data['edition'], mode = data['mode'];
    if (edition is! String) return false;
    final publicationMode = PublicationMode.values.where((candidate) => candidate.name == mode).firstOrNull;
    if (publicationMode == null) return false;
    if (_editionCandidates(entry, publicationMode).any((candidate) => candidate.edition == edition)) return true;
    return sharedEntryId != null && _localEditionForShared(entry, sharedEntryId, publicationMode, edition) != null;
  }

  Future<void> _apply(
    String profile,
    _SyncCache cache,
    Map<String, SourceEntry> identities,
    Map<String, String> entryMappings,
    Set<String> activeKeys,
  ) async {
    conflicts.clear();
    for (final record in cache.document.records.entries) {
      final values = record.value;
      final first = values.first.value;
      final entry = identities[first['entry']];
      if (entry == null) continue; // Discovered later; retained in the document.
      for (final v in values) {
        if (v.value['entry'] != first['entry'] || v.value['type'] != first['type']) {
          throw const SourceException(SourceFailure.invalidData);
        }
      }
      if (cache.document.conflicted(record.key)) {
        conflicts[record.key] = PublicationSyncConflict(record.key, entry, values);
        continue;
      }
      final data = sourceMap(first['data']);
      final edition = data['edition'], mode = data['mode'];
      if (edition is! String || mode is! String || !PublicationMode.values.any((m) => m.name == mode)) {
        throw const SourceException(SourceFailure.invalidData);
      }
      final recordEntry = first['entry'];
      if (recordEntry is! String) throw const SourceException(SourceFailure.invalidData);
      final expectedKey = first['type'] == 'progress'
          ? progressKey(recordEntry, edition, PublicationMode.values.byName(mode))
          : first['type'] == 'annotation'
          ? annotationKey(recordEntry, data['id'] as String? ?? '')
          : '';
      if (expectedKey.isEmpty || expectedKey != record.key) {
        throw const SourceException(SourceFailure.invalidData);
      }
      final sharedEntryId = entryMappings[entry.key];
      if (!(first['type'] == 'annotation' && data['deleted'] == true) &&
          !_compatible(entry, data, sharedEntryId: sharedEntryId)) {
        continue;
      }
      final publicationMode = PublicationMode.values.byName(mode as String);
      final localEdition = sharedEntryId == null
          ? edition as String
          : _localEditionForShared(entry, sharedEntryId, publicationMode, edition as String) ?? edition as String;
      final localData = localEdition == edition ? data : {...data, 'edition': localEdition};
      final hash = _hash(first);
      if (cache.observed[record.key] == hash) {
        cache.basis[record.key] = joinedClock(values);
        continue;
      }
      if (first['type'] == 'progress') {
        final value = PublicationProgress.fromJson({...localData, 'entryKey': entry.key, 'session': const Uuid().v4()});
        if (value.positionMs < 0 ||
            value.filePositionMs < 0 ||
            value.fileIndex < 0 ||
            value.fileIndex >= entry.files.length ||
            !value.speed.isFinite) {
          throw const SourceException(SourceFailure.invalidData);
        }
        final knownDuration = entry.files[value.fileIndex].durationMs;
        if (knownDuration != null && value.filePositionMs > knownDuration) {
          throw const SourceException(SourceFailure.invalidData);
        }
        if (activeKeys.contains(value.key)) continue;
        final current = await repository.progress(profile, value.key);
        final saved = await repository.saveProgress(
          profile,
          value.copyWith(revision: current?.revision ?? 0),
          kind: 'cloud',
        );
        await repository.acknowledge(profile, saved.key, saved.revision);
      } else if (first['type'] == 'annotation') {
        final a = BookAnnotation.fromJson({
          ...localData,
          'entryKey': entry.key,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
        var invalidFileCursor = (a.fileIndex == null) != (a.filePositionMs == null);
        if (a.fileIndex != null && a.filePositionMs != null) {
          if (a.fileIndex! < 0 || a.fileIndex! >= entry.files.length || a.filePositionMs! < 0) {
            invalidFileCursor = true;
          } else {
            final duration = entry.files[a.fileIndex!].durationMs;
            if (duration != null && a.filePositionMs! > duration) invalidFileCursor = true;
          }
        }
        if (a.note.length > 100000 ||
            a.quote.length > 100000 ||
            a.id.length > 200 ||
            (a.positionMs != null && a.positionMs! < 0) ||
            invalidFileCursor) {
          throw const SourceException(SourceFailure.invalidData);
        }
        await repository.database.customStatement('INSERT OR REPLACE INTO annotations VALUES (?,?,?,?)', [
          profile,
          a.id,
          a.entryKey,
          jsonEncode(a.toJson()),
        ]);
      } else {
        throw const SourceException(SourceFailure.invalidData);
      }
      cache.observed[record.key] = hash;
      cache.basis[record.key] = joinedClock(values);
    }
  }

  Future<void> run({
    required String profile,
    required List<FileSource> sources,
    required PublicationSyncConfig config,
    required SyncStore store,
    required Set<String> activeKeys,
    required void Function() check,
  }) async {
    if (running) throw const SourceException(SourceFailure.conflict);
    running = true;
    failure = null;
    try {
      check();
      final cipher = SyncCipher(config.code), cacheKey = _cacheKey(SyncCipher(config.code).namespace);
      final cache = _SyncCache(await repository.preference(profile, cacheKey));
      final deviceConfig = await repository.preference(profile, 'publication-sync-device-v1');
      final device = deviceConfig['id'] as String? ?? const Uuid().v4().replaceAll('-', '');
      check();
      await repository.savePreference(profile, 'publication-sync-device-v1', {'id': device});
      final entries = await repository.entries(profile);
      final entryMappings = await sharedEntryMappings(profile);
      // Persist new local edits BEFORE any network access. Retry retains the
      // same causal context even if a pull, upload or application crashes.
      await repository.database.transaction(() async {
        check();
        _capture(cache, device, await _locals(profile, sources, entries, entryMappings));
        cache.document.compactSafe(actor: device);
        await repository.savePreference(profile, cacheKey, cache.toJson());
      });
      final listed = await store.list(cipher.namespace);
      check();
      final latest = <String, int>{};
      for (final f in listed) {
        if (f.sequence > (latest[f.device] ?? -1)) latest[f.device] = f.sequence;
        if (f.device == device && f.sequence > cache.sequence) cache.sequence = f.sequence;
      }
      if (latest.length > 128) throw const SourceException(SourceFailure.invalidData);
      final remote = SyncDocument();
      for (final f in listed.where((f) => latest[f.device] == f.sequence)) {
        check();
        final document = await cipher.open(await store.read(f), f.name);
        check();
        remote.merge(document);
      }
      // A tick during network I/O is captured against the pre-pull basis.
      late Map<String, _LocalValue> publishedLocals;
      await repository.database.transaction(() async {
        check();
        publishedLocals = await _locals(profile, sources, entries, entryMappings);
        _capture(cache, device, publishedLocals);
        cache.document.merge(remote);
        cache.document.compactSafe(actor: device);
        await _apply(profile, cache, _identities(sources, entries, entryMappings), entryMappings, activeKeys);
        check();
        await repository.savePreference(profile, cacheKey, cache.toJson());
      });
      final digest = _hash(cache.document.toJson());
      if (digest != cache.published || !latest.containsKey(device)) {
        cache.sequence++;
        if (cache.sequence > 9999999999999999) throw const SourceException(SourceFailure.invalidData);
        check();
        await repository.savePreference(profile, cacheKey, cache.toJson());
        final name = SyncFile.filename(cipher.namespace, device, cache.sequence);
        final encrypted = await cipher.seal(cache.document, name);
        check();
        await store.create(name, encrypted);
        check();
        cache.published = digest;
        await repository.savePreference(profile, cacheKey, cache.toJson());
        // Keep the previous successful snapshot as a recovery copy. No other
        // device's files, books or unrelated JSON are ever removed.
        final owned = listed.where((f) => f.device == device).toList()
          ..sort((a, b) => b.sequence.compareTo(a.sequence));
        for (final old in owned.skip(1)) {
          check();
          try {
            await store.delete(old);
          } on SourceException catch (e) {
            if (e.reason == SourceFailure.cancelled) rethrow;
            // Retention failure does not invalidate the committed generation.
          }
        }
      }
      check();
      // The encrypted generation is the cloud backup for these durable local
      // snapshots. Clear only the exact revisions/payloads represented here,
      // so a concurrent edit remains pending for the next run.
      for (final value in publishedLocals.values) {
        check();
        if (value.progress case final progress?) {
          await repository.acknowledge(profile, progress.key, progress.revision);
        }
        if (value.annotation case final annotation?) {
          await repository.acknowledgeAnnotation(profile, annotation);
        }
      }
      lastSuccess = DateTime.now();
    } on SourceException catch (e) {
      failure = e.reason;
      rethrow;
    } catch (_) {
      failure = SourceFailure.unavailable;
      rethrow;
    } finally {
      running = false;
    }
  }

  Future<void> resolve({
    required String profile,
    required PublicationSyncConfig config,
    required String key,
    required SyncVersion selected,
    required List<FileSource> sources,
    required Set<String> activeKeys,
    required void Function() check,
  }) async {
    final cacheKey = _cacheKey(SyncCipher(config.code).namespace);
    await repository.database.transaction(() async {
      check();
      final cache = _SyncCache(await repository.preference(profile, cacheKey));
      final current = cache.document.records[key] ?? [];
      if (!current.any((v) => canonicalSyncJson(v.toJson()) == canonicalSyncJson(selected.toJson()))) {
        throw const SourceException(SourceFailure.conflict);
      }
      final device = (await repository.preference(profile, 'publication-sync-device-v1'))['id'] as String;
      cache.document.edit(key, device, selected.value, joinedClock(current));
      cache.observed.remove(key);
      final entryMappings = await sharedEntryMappings(profile);
      await _apply(
        profile,
        cache,
        _identities(sources, await repository.entries(profile), entryMappings),
        entryMappings,
        activeKeys,
      );
      check();
      await repository.savePreference(profile, cacheKey, cache.toJson());
    });
  }
}

