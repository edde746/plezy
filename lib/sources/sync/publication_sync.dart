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

  static String entryIdentity(FileSource source, SourceEntry entry) {
    // Connection UUIDs and local profile IDs differ across installations.
    // Provider IDs plus origin identify the publication. Roots are browsing
    // preferences and do not change an existing provider object's identity.
    final library = source.options['syncLibrary'];
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
  static Map<String, dynamic> _progressValue(String identity, PublicationProgress p) => {
    'type': 'progress',
    'entry': identity,
    'data': {...p.toJson()}
      ..remove('entryKey')
      ..remove('session')
      ..remove('revision')
      ..remove('updatedAt'),
  };
  static Map<String, dynamic> _annotationValue(String identity, BookAnnotation a) => {
    'type': 'annotation',
    'entry': identity,
    'data': {...a.toJson()}
      ..remove('entryKey')
      ..remove('updatedAt'),
  };
  static String _hash(Map<String, dynamic> value) => sourceDigest(canonicalSyncJson(value));

  Future<Map<String, _LocalValue>> _locals(String profile, List<FileSource> sources, List<SourceEntry> entries) async {
    final identities = <String, String>{};
    for (final entry in entries) {
      final source = sources.where((s) => s.id == entry.sourceId).firstOrNull;
      if (source != null) identities[entry.key] = entryIdentity(source, entry);
    }
    final byKey = {for (final e in entries) e.key: e};
    final values = <String, _LocalValue>{};
    for (final p in await repository.allProgress(profile)) {
      final identity = identities[p.entryKey];
      if (identity != null) {
        values[progressKey(identity, p.edition, p.mode)] = _LocalValue(
          _progressValue(identity, p),
          p.key,
          byKey[p.entryKey]!,
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
        values[annotationKey(identity, a.id)] = _LocalValue(
          _annotationValue(identity, a),
          a.id,
          byKey[a.entryKey]!,
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

  Map<String, SourceEntry> _identities(List<FileSource> sources, List<SourceEntry> entries) => {
    for (final e in entries)
      if (sources.any((s) => s.id == e.sourceId)) entryIdentity(sources.firstWhere((s) => s.id == e.sourceId), e): e,
  };

  bool _compatible(SourceEntry entry, Map<String, dynamic> data) {
    final edition = data['edition'], mode = data['mode'];
    if (mode == PublicationMode.reading.name) return entry.ebooks.any((f) => f.fingerprint == edition);
    // Every selected sequence has a distinct edition; individual media are
    // also selectable. Never apply an offset to a replaced/reordered file set.
    final groups = <List<PublicationFile>>[
      entry.audio,
      for (final f in entry.files) [f],
    ];
    return const ['listening', 'watching'].contains(mode) &&
        groups
            .where((g) => g.isNotEmpty)
            .any((g) => sourceDigest(jsonEncode(g.map((f) => f.fingerprint).toList())) == edition);
  }

  Future<void> _apply(
    String profile,
    _SyncCache cache,
    Map<String, SourceEntry> identities,
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
      if (!(first['type'] == 'annotation' && data['deleted'] == true) && !_compatible(entry, data)) continue;
      final hash = _hash(first);
      if (cache.observed[record.key] == hash) {
        cache.basis[record.key] = joinedClock(values);
        continue;
      }
      if (first['type'] == 'progress') {
        final value = PublicationProgress.fromJson({...data, 'entryKey': entry.key, 'session': const Uuid().v4()});
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
          ...data,
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
      // Persist new local edits BEFORE any network access. Retry retains the
      // same causal context even if a pull, upload or application crashes.
      await repository.database.transaction(() async {
        check();
        _capture(cache, device, await _locals(profile, sources, entries));
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
        publishedLocals = await _locals(profile, sources, entries);
        _capture(cache, device, publishedLocals);
        cache.document.merge(remote);
        await _apply(profile, cache, _identities(sources, entries), activeKeys);
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
      await _apply(profile, cache, _identities(sources, await repository.entries(profile)), activeKeys);
      check();
      await repository.savePreference(profile, cacheKey, cache.toJson());
    });
  }
}
