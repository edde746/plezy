import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../media/media_kind.dart';
import '../sources/source_database.dart';
import '../sources/source_models.dart';
import '../sources/sync/sync_document.dart';
import '../sources/sync/sync_store.dart';
import 'discovery_choice.dart';
import 'discovery_store.dart';

class DiscoverySyncConflict {
  const DiscoverySyncConflict(this.key, this.choice, this.values);
  final String key;
  final DiscoveryChoice choice;
  final List<SyncVersion> values;
}

class _DiscoverySyncCache {
  _DiscoverySyncCache(Map<String, dynamic> json)
    : document = json['document'] == null ? SyncDocument() : SyncDocument.fromJson(sourceMap(json['document'])),
      observed = sourceMap(json['observed']).map((key, value) => MapEntry(key, value as String)),
      basis = sourceMap(
        json['basis'],
      ).map((key, value) => MapEntry(key, sourceMap(value).map((a, b) => MapEntry(a, b as int)))),
      sequence = sourceInt(json['sequence']) ?? 0,
      published = json['published'] as String? ?? '';

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

/// Opt-in replication for portable Saved picks. This uses the existing
/// encrypted file store and causal multi-value registers, but has its own
/// namespace and cache so picks never enter playback or publication state.
class DiscoverySync {
  DiscoverySync(this.repository);

  static const _cachePrefix = 'discovery-sync-cache-v1:';
  static const _deviceKey = 'publication-sync-device-v1';
  final SourceRepository repository;
  final Map<String, DiscoverySyncConflict> conflicts = {};
  bool running = false;
  SourceFailure? failure;
  DateTime? lastSuccess;

  static String namespaceFor(String code) {
    final publicationNamespace = SyncCipher(code).namespace;
    return sourceDigest('plezyng-discovery-sync-v1:$publicationNamespace').substring(0, 24);
  }

  static String recoveryName(String namespace) => 'plezyng-discovery-recovery-v1-$namespace.json';

  static String _cacheKey(String namespace) => '$_cachePrefix$namespace';

  void resetStatus() {
    conflicts.clear();
    failure = null;
    lastSuccess = null;
  }

  Future<SyncDocument> recoveryDocument(String profile, String code) async {
    final namespace = namespaceFor(code);
    final cacheKey = _cacheKey(namespace);
    final device = await _device(profile);
    return repository.database.transaction(() async {
      final cache = _DiscoverySyncCache(await repository.preference(profile, cacheKey));
      final state = await DiscoveryStore(repository).load(profile);
      _capture(cache, device, state.saved);
      cache.document.compactSafe(actor: device);
      await repository.savePreference(profile, cacheKey, cache.toJson());
      return cache.document;
    });
  }

  Future<void> importRecovery({required String profile, required String code, required SyncDocument incoming}) async {
    final namespace = namespaceFor(code);
    final cacheKey = _cacheKey(namespace);
    final device = await _device(profile);
    await repository.database.transaction(() async {
      final cache = _DiscoverySyncCache(await repository.preference(profile, cacheKey));
      final state = await DiscoveryStore(repository).load(profile);
      _capture(cache, device, state.saved);
      cache.document.merge(incoming);
      cache.document.compactSafe(actor: device);
      cache.published = '';
      await _apply(profile, cache);
      await repository.savePreference(profile, cacheKey, cache.toJson());
    });
  }

  Future<void> run({
    required String profile,
    required String code,
    required SyncStore store,
    required void Function() check,
  }) async {
    if (running) throw const SourceException(SourceFailure.conflict);
    running = true;
    failure = null;
    try {
      check();
      final cipher = SyncCipher(code);
      final namespace = namespaceFor(code);
      final cacheKey = _cacheKey(namespace);
      final cache = _DiscoverySyncCache(await repository.preference(profile, cacheKey));
      final device = await _device(profile);
      await repository.database.transaction(() async {
        check();
        final state = await DiscoveryStore(repository).load(profile);
        _capture(cache, device, state.saved);
        cache.document.compactSafe(actor: device);
        await repository.savePreference(profile, cacheKey, cache.toJson());
      });

      final listed = await store.list(namespace);
      check();
      final latest = <String, int>{};
      for (final file in listed) {
        if (file.sequence > (latest[file.device] ?? -1)) latest[file.device] = file.sequence;
        if (file.device == device && file.sequence > cache.sequence) cache.sequence = file.sequence;
      }
      if (latest.length > 128) throw const SourceException(SourceFailure.invalidData);
      final remote = SyncDocument();
      for (final file in listed.where((item) => latest[item.device] == item.sequence)) {
        check();
        remote.merge(await cipher.open(await store.read(file), file.name));
        check();
      }

      await repository.database.transaction(() async {
        check();
        final state = await DiscoveryStore(repository).load(profile);
        _capture(cache, device, state.saved);
        cache.document.merge(remote);
        cache.document.compactSafe(actor: device);
        await _apply(profile, cache);
        check();
        await repository.savePreference(profile, cacheKey, cache.toJson());
      });

      final digest = _hash(cache.document.toJson());
      if (digest != cache.published || !latest.containsKey(device)) {
        cache.sequence++;
        if (cache.sequence > 9999999999999999) throw const SourceException(SourceFailure.invalidData);
        check();
        await repository.savePreference(profile, cacheKey, cache.toJson());
        final name = SyncFile.filename(namespace, device, cache.sequence);
        await store.create(name, await cipher.seal(cache.document, name));
        check();
        cache.published = digest;
        await repository.savePreference(profile, cacheKey, cache.toJson());
        final owned = listed.where((file) => file.device == device).toList()
          ..sort((left, right) => right.sequence.compareTo(left.sequence));
        for (final old in owned.skip(1)) {
          check();
          try {
            await store.delete(old);
          } on SourceException catch (error) {
            if (error.reason == SourceFailure.cancelled) rethrow;
          }
        }
      }
      check();
      lastSuccess = DateTime.now();
    } on SourceException catch (error) {
      failure = error.reason;
      rethrow;
    } on Object {
      failure = SourceFailure.unavailable;
      rethrow;
    } finally {
      running = false;
    }
  }

  Future<void> resolve({
    required String profile,
    required String code,
    required String key,
    required SyncVersion selected,
    required void Function() check,
  }) async {
    final namespace = namespaceFor(code);
    final cacheKey = _cacheKey(namespace);
    await repository.database.transaction(() async {
      check();
      final cache = _DiscoverySyncCache(await repository.preference(profile, cacheKey));
      final current = cache.document.records[key] ?? const <SyncVersion>[];
      if (!current.any((value) => canonicalSyncJson(value.toJson()) == canonicalSyncJson(selected.toJson()))) {
        throw const SourceException(SourceFailure.conflict);
      }
      final device = await _device(profile);
      cache.document.edit(key, device, selected.value, joinedClock(current));
      cache.observed.remove(key);
      await _apply(profile, cache);
      check();
      await repository.savePreference(profile, cacheKey, cache.toJson());
    });
  }

  Future<String> _device(String profile) async {
    final preference = await repository.preference(profile, _deviceKey);
    final existing = preference['id'];
    if (existing is String && RegExp(r'^[a-f0-9]{32}$').hasMatch(existing)) return existing;
    final device = const Uuid().v4().replaceAll('-', '');
    await repository.savePreference(profile, _deviceKey, {'id': device});
    return device;
  }

  void _capture(_DiscoverySyncCache cache, String device, List<DiscoveryChoice> saved) {
    final byKey = <String, DiscoveryChoice>{};
    for (final choice in saved) {
      final key = choice.portableKey;
      if (key != null) byKey.putIfAbsent(key, () => choice);
    }
    final keys = {...cache.document.records.keys, ...byKey.keys};
    for (final key in keys) {
      if (cache.document.conflicted(key)) continue;
      final choice = byKey[key];
      final current = cache.document.records[key]?.firstOrNull;
      if (choice == null && current == null) continue;
      final value = choice == null
          ? _savedValue(_choiceFromValue(current!.value, key), false)
          : _savedValue(choice, true);
      final hash = _semanticHash(value);
      if (cache.observed[key] == hash) continue;
      final next = cache.document.edit(key, device, value, cache.basis[key] ?? const {});
      cache.basis[key] = next.clock;
      cache.observed[key] = hash;
    }
  }

  Future<void> _apply(String profile, _DiscoverySyncCache cache) async {
    final state = DiscoveryState.fromJson(await repository.preference(profile, DiscoveryStore.preferenceKey));
    final savedById = {for (final choice in state.saved) choice.id: choice};
    var hasChanged = false;
    conflicts.clear();
    for (final record in cache.document.records.entries) {
      final versions = record.value;
      if (versions.isEmpty) continue;
      final first = versions.first;
      final choice = _choiceFromValue(first.value, record.key);
      for (final version in versions) {
        final other = _choiceFromValue(version.value, record.key);
        if (other.portableReference != choice.portableReference) {
          throw const SourceException(SourceFailure.invalidData);
        }
      }
      if (cache.document.conflicted(record.key)) {
        conflicts[record.key] = DiscoverySyncConflict(record.key, choice, versions);
        continue;
      }
      final data = sourceMap(first.value['data']);
      if (data['saved'] == true) {
        final local = savedById.values.where((item) => item.portableKey == record.key).firstOrNull;
        if (local == null) {
          if (savedById.length >= DiscoveryStore.maxSaved) {
            throw const SourceException(SourceFailure.conflict);
          }
          final remote = _choiceFromValue(first.value, record.key);
          savedById[remote.id] = remote;
          hasChanged = true;
        }
      } else {
        final remove = savedById.values.where((item) => item.portableKey == record.key).map((item) => item.id).toList();
        if (remove.isNotEmpty) {
          for (final id in remove) {
            savedById.remove(id);
          }
          hasChanged = true;
        }
      }
      cache.observed[record.key] = _semanticHash(first.value);
      cache.basis[record.key] = joinedClock(versions);
    }
    if (hasChanged) {
      await repository.savePreference(
        profile,
        DiscoveryStore.preferenceKey,
        DiscoveryState(
          saved: savedById.values.toList(growable: false),
          seen: state.seen,
          history: state.history,
        ).toJson(),
      );
    }
  }

  void _refreshConflicts(_DiscoverySyncCache cache) {
    conflicts.clear();
    for (final record in cache.document.records.entries) {
      if (!cache.document.conflicted(record.key)) continue;
      final choice = _choiceFromValue(record.value.first.value, record.key);
      conflicts[record.key] = DiscoverySyncConflict(record.key, choice, record.value);
    }
  }

  Map<String, dynamic> _savedValue(DiscoveryChoice choice, bool saved) => {
    'type': 'discovery-pick',
    'data': {
      'saved': saved,
      'reference': choice.portableReference,
      'portableKey': choice.portableKey,
      'type': choice.type.name,
      'mediaKind': choice.mediaKind?.id,
      'ids': choice.portableIds,
      'title': _bounded(choice.title, 160),
      'durationMs': choice.totalDurationMs ?? choice.durationMs,
    },
  };

  DiscoveryChoice _choiceFromValue(Map<String, dynamic> value, String key) {
    if (value['type'] != 'discovery-pick') throw const SourceException(SourceFailure.invalidData);
    final data = sourceMap(value['data']);
    if (data['saved'] is! bool || data['reference'] is! String || data['portableKey'] != key) {
      throw const SourceException(SourceFailure.invalidData);
    }
    final type = DiscoveryChoiceType.values.where((item) => item.name == data['type']).firstOrNull;
    if (type == null || type == DiscoveryChoiceType.liveProgram) throw const SourceException(SourceFailure.invalidData);
    final rawIds = sourceMap(data['ids']);
    if (rawIds.values.any((value) => value is! String)) throw const SourceException(SourceFailure.invalidData);
    final ids = sanitizeDiscoveryPortableIds(rawIds.map((name, id) => MapEntry(name, id as String)));
    final kind = MediaKind.values.where((item) => item.id == data['mediaKind']).firstOrNull;
    final kindIsValid = switch (type) {
      DiscoveryChoiceType.video => kind == MediaKind.movie || kind == MediaKind.show,
      DiscoveryChoiceType.music =>
        kind == null || kind == MediaKind.artist || kind == MediaKind.album || kind == MediaKind.track,
      DiscoveryChoiceType.ebook ||
      DiscoveryChoiceType.audiobook ||
      DiscoveryChoiceType.comic ||
      DiscoveryChoiceType.sourceVideo => kind == null,
      DiscoveryChoiceType.liveProgram => false,
    };
    if (!kindIsValid) throw const SourceException(SourceFailure.invalidData);
    final title = _bounded(data['title'] is String ? data['title'] as String : '', 160);
    final rawDuration = sourceInt(data['durationMs']);
    final duration = rawDuration != null && rawDuration > 0 && rawDuration < const Duration(days: 60).inMilliseconds
        ? rawDuration
        : null;
    final result = DiscoveryChoice(
      id: 'portable:$key',
      type: type,
      title: title,
      subtitle: '',
      reason: '',
      summary: '',
      durationMs: duration,
      totalDurationMs: duration,
      isEstimate: false,
      serverId: null,
      mediaId: null,
      mediaKind: kind,
      sourceId: null,
      entryId: null,
      year: null,
      portableIds: ids,
    );
    if (result.title.isEmpty ||
        result.portableKey != key ||
        result.portableReference != data['reference'] ||
        result.portableIds.isEmpty) {
      throw const SourceException(SourceFailure.invalidData);
    }
    return result;
  }

  static String _bounded(String value, int limit) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    return normalized.substring(0, normalized.length > limit ? limit : normalized.length);
  }

  static String _semanticHash(Map<String, dynamic> value) => sourceDigest(canonicalSyncJson(_semanticValue(value)));

  static Map<String, dynamic> _semanticValue(Map<String, dynamic> value) {
    final data = sourceMap(value['data']);
    return {
      'type': 'discovery-pick',
      'data': {'saved': data['saved'] == true, 'reference': data['reference'], 'portableKey': data['portableKey']},
    };
  }

  static String _hash(Object? value) => sourceDigest(canonicalSyncJson(value));
}
