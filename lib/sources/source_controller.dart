import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'adapters/audiobookshelf_source.dart';
import 'adapters/cloud_sources.dart';
import 'adapters/local_source.dart';
import 'adapters/opds_source.dart';
import 'adapters/s3_source.dart';
import 'adapters/smb_source.dart';
import 'adapters/webdav_source.dart';
import 'content_access.dart';
import 'source_database.dart';
import 'source_models.dart';
import 'source_oauth.dart';
import 'source_transport.dart';
import 'publication_shelf.dart';

class SourceController extends ChangeNotifier {
  SourceController({SourceRepository? repository}) {
    ready = _initialize(repository);
  }
  late final Future<void> ready;
  late SourceRepository repository;
  late SourceOAuthService oauth;
  late PublicationDownloads downloads;
  final Map<String, Future<File?>> _covers = {};
  final Map<String, SourceAdapter> _adapters = {};
  List<FileSource> sources = const [];
  Set<PublicationShelf> shelves = {};
  final Map<String, int> scanning = {};
  final Map<String, Object> _scanSessions = {};
  String? profileId;
  bool blocked = true;
  bool loading = true;
  bool _disposed = false;
  int generation = 0;
  SourceFailure? failure;
  Future<void> Function()? stopPlayback;
  Timer? _syncTimer;
  Timer? _syncSoon;
  Future<void> _syncQueue = Future.value();
  void scheduleSync() {
    if (_disposed || blocked || profileId == null) return;
    _syncSoon ??= Timer(const Duration(seconds: 15), () {
      _syncSoon = null;
      if (!_disposed && !blocked && profileId != null) unawaited(sync().catchError((Object _) {}));
    });
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _initialize(SourceRepository? provided) async {
    repository = provided ?? SourceRepository(await SourceDatabase.open());
    oauth = SourceOAuthService(repository);
    downloads = PublicationDownloads(
      repository,
      Directory(p.join((await getApplicationSupportDirectory()).path, 'publication-files')),
    );
    _syncTimer = Timer.periodic(const Duration(minutes: 1), (_) => scheduleSync());
  }

  void attachProfile(String? id, {required bool blocked}) {
    if (profileId == id && this.blocked == blocked) return;
    profileId = id;
    this.blocked = blocked;
    generation++;
    sources = const [];
    shelves = {};
    scanning.clear();
    _scanSessions.clear();
    loading = true;
    failure = null;
    for (final adapter in _adapters.values) {
      adapter.close();
    }
    _adapters.clear();
    unawaited(stopPlayback?.call());
    final epoch = generation;
    unawaited(
      ready
          .then((_) async {
            downloads.cancelAll();
            oauth.cancel();
            if (id != null && !blocked && current(epoch)) {
              sources = await repository.sources(id);
              await _shelves(id, epoch);
              scheduleSync();
            }
            if (current(epoch)) {
              loading = false;
              _notify();
            }
          })
          .catchError((Object error) {
            if (current(epoch)) {
              failure = SourceFailure.unavailable;
              loading = false;
              _notify();
            }
          }),
    );
  }

  bool current(int epoch) => !_disposed && generation == epoch;

  SourceEntry _withSyncIdentity(FileSource source, SourceEntry entry) {
    if (source.kind == FileSourceKind.webdav) {
      // Preserve existing WebDAV state-file names for its own content.
      return entry.copyWith(syncIdentity: entry.id);
    }
    final endpoint = Uri.tryParse(source.endpoint);
    final normalizedEndpoint = endpoint == null
        ? source.endpoint.trim()
        : endpoint
            .replace(
              scheme: endpoint.scheme.toLowerCase(),
              host: endpoint.host.toLowerCase(),
              path: endpoint.path.replaceAll(RegExp(r'/+$'), ''),
              port: endpoint.scheme == 'smb' && endpoint.hasPort && endpoint.port == 445
                  ? null
                  : endpoint.port,
            )
            .toString();
    final normalizedRoot = source.root.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');
    final normalizedEntryId = entry.id.replaceAll('\\', '/');
    final identity = sourceDigest(
      jsonEncode([
        source.kind.name,
        if (source.kind != FileSourceKind.smb) source.name,
        normalizedEndpoint,
        normalizedRoot,
        normalizedEntryId,
      ]),
    );
    return entry.copyWith(syncIdentity: identity);
  }

  SourceAdapter? _stateAdapter(SourceEntry entry, PublicationProgress progress) {
    final owner = sources.where((source) => source.id == entry.sourceId).firstOrNull;
    if (owner != null) {
      final local = adapter(owner.id);
      if (local.supportsProgress(entry, progress)) return local;
    }
    // A single configured WebDAV state folder can synchronize other sources.
    // If more than one is configured, leave cross-source progress local.
    final targets = sources.where(
      (source) =>
          source.kind == FileSourceKind.webdav &&
          (source.options['syncRoot']?.trim().isNotEmpty ?? false),
    ).toList();
    if (targets.length != 1) return null;
    final target = adapter(targets.single.id);
    return target.supportsProgress(entry, progress) ? target : null;
  }

  void requireSession([int? epoch]) {
    if (_disposed || blocked || profileId == null || (epoch != null && !current(epoch))) {
      throw const SourceException(SourceFailure.cancelled);
    }
  }

  Future<void> reload() async {
    await ready;
    requireSession();
    final epoch = generation;
    final result = await repository.sources(profileId!);
    if (current(epoch)) {
      sources = result;
      await _shelves(profileId!, epoch);
      _notify();
    }
  }

  Future<void> forgetProfile(String profile) async {
    await ready;
    if (profileId == profile) {
      attachProfile(null, blocked: true);
      _notify();
      await stopPlayback?.call();
    }
    await repository.forgetProfile(profile);
    await downloads.settleCancelled();
    final root = Directory(p.join(downloads.directory.path, sourceDigest(profile)));
    if (await root.exists()) await root.delete(recursive: true);
    _covers.clear();
  }

  Future<void> _shelves(String profile, int epoch) async {
    final entries = await repository.entries(profile);
    if (!current(epoch)) return;
    shelves = {
      for (final shelf in PublicationShelf.values)
        if (entries.any(shelf.includes) ||
            sources.any((source) {
              final configured = source.options['shelves']?.split(',');
              final enabled = configured ?? defaultPublicationShelves(source.kind).map((s) => s.name).toList();
              return enabled.contains(shelf.name);
            }))
          shelf,
    };
  }

  Future<void> scan(String sourceId) async {
    if (scanning.containsKey(sourceId)) return;
    requireSession();
    final epoch = generation, profile = profileId!;
    final session = Object();
    _scanSessions[sourceId] = session;
    void checkScan() {
      requireSession(epoch);
      if (!identical(_scanSessions[sourceId], session)) throw const SourceException(SourceFailure.cancelled);
    }

    scanning[sourceId] = 0;
    _notify();
    final pending = <(String?, int)>[(null, 0)], seen = <String>{};
    try {
      while (pending.isNotEmpty) {
        checkScan();
        final (parent, depth) = pending.removeAt(0);
        if (depth > 32 || !seen.add(parent ?? '') || seen.length > 10000) continue;
        String? cursor;
        final cursors = <String>{};
        do {
          final page = await browse(sourceId, parent: parent, cursor: cursor);
          checkScan();
          scanning[sourceId] = (scanning[sourceId] ?? 0) + page.entries.length;
          _notify();
          if (scanning[sourceId]! > 100000) throw const SourceException(SourceFailure.invalidData);
          for (final folder in page.entries.where((e) => e.isFolder)) {
            pending.add((folder.id, depth + 1));
          }
          cursor = page.next;
          if (cursor != null && !cursors.add(cursor)) throw const SourceException(SourceFailure.invalidData);
        } while (cursor != null);
      }
      await _shelves(profile, epoch);
    } finally {
      if (current(epoch) && identical(_scanSessions[sourceId], session)) {
        _scanSessions.remove(sourceId);
        scanning.remove(sourceId);
        _notify();
      }
    }
  }

  void cancelScan(String sourceId) {
    _scanSessions.remove(sourceId);
    scanning.remove(sourceId);
    _notify();
  }

  Future<void> add(FileSource source, Map<String, String> credentials) async {
    await ready;
    requireSession();
    if (source.profileId != profileId) throw const SourceException(SourceFailure.permission);
    final epoch = generation;
    await repository.saveSource(source, credentials);
    requireSession(epoch);
    await reload();
  }

  Future<void> reconnect(String id) async {
    _adapters.remove(id)?.close();
  }

  Future<void> remove(FileSource source) async {
    requireSession();
    if (source.profileId != profileId) throw const SourceException(SourceFailure.permission);
    cancelScan(source.id);
    await stopPlayback?.call();
    _adapters.remove(source.id)?.close();
    downloads.cancelAll();
    await repository.removeSource(profileId!, source.id);
    await reload();
  }

  SourceAdapter adapter(String id) {
    requireSession();
    return _adapters.putIfAbsent(id, () {
      final source = sources.where((s) => s.id == id).firstOrNull;
      if (source == null) throw const SourceException(SourceFailure.authentication);
      final transport = SourceTransport(allowHttp: source.options['allowHttp'] == 'true');
      Future<Map<String, String>> credentials() => repository.credentials(source);
      Future<String> token({bool refresh = false}) => oauth.accessToken(source, refresh: refresh);
      return switch (source.kind) {
        FileSourceKind.local => LocalSourceAdapter(source, transport),
        FileSourceKind.webdav => WebDavSourceAdapter(source, transport, credentials),
        FileSourceKind.googleDrive => GoogleDriveSourceAdapter(source, transport, token),
        FileSourceKind.oneDrive => OneDriveSourceAdapter(source, transport, token),
        FileSourceKind.dropbox => DropboxSourceAdapter(source, transport, token),
        FileSourceKind.s3 => S3SourceAdapter(source, transport, credentials),
        FileSourceKind.smb => SmbSourceAdapter(source, transport, credentials),
        FileSourceKind.opds => OpdsSourceAdapter(source, transport, credentials),
        FileSourceKind.audiobookshelf => AudiobookshelfSourceAdapter(source, transport, credentials),
      };
    });
  }

  Future<SourcePage> browse(String source, {String? parent, String? cursor, String? query}) async {
    await ready;
    requireSession();
    final epoch = generation, profile = profileId!;
    final fileSource = sources.where((item) => item.id == source).firstOrNull;
    if (fileSource == null) throw const SourceException(SourceFailure.authentication);
    final page = await adapter(source).browse(parent: parent, cursor: cursor, query: query);
    requireSession(epoch);
    final entries = page.entries.map((entry) => _withSyncIdentity(fileSource, entry)).toList();
    await repository.cacheEntries(profile, entries);
    shelves.addAll(PublicationShelf.values.where((s) => entries.any(s.includes)));
    _notify();
    return SourcePage(entries, next: page.next, title: page.title);
  }

  Future<SourceEntry> hydrate(SourceEntry entry) async {
    requireSession();
    final epoch = generation, profile = profileId!;
    final fileSource = sources.where((item) => item.id == entry.sourceId).firstOrNull;
    if (fileSource == null) throw const SourceException(SourceFailure.authentication);
    final result = _withSyncIdentity(fileSource, await adapter(entry.sourceId).hydrate(entry));
    requireSession(epoch);
    await repository.cacheEntries(profile, [result]);
    return result;
  }

  Future<File> content(SourceEntry entry, PublicationFile file, {void Function(int, int?)? onProgress}) async {
    await ready;
    requireSession();
    final epoch = generation;
    final local = await downloads.local(profileId!, entry.sourceId, file);
    if (local != null) return local;
    final result = await downloads.download(profileId!, adapter(entry.sourceId), file, onProgress: onProgress);
    requireSession(epoch);
    return result;
  }

  Future<File?> cover(SourceEntry entry) {
    final profile = profileId;
    if (profile == null || blocked) return Future.value();
    return _covers.putIfAbsent(sourceKey(profile, entry.key), () async {
      await ready;
      final epoch = generation;
      final file = File(
        p.join(downloads.directory.path, sourceDigest(profile), 'covers', '${sourceDigest('${entry.key}:${entry.coverId ?? ''}')}.png'),
      );
      if (await file.exists()) return file;
      if (!sources.any((s) => s.id == entry.sourceId)) return null;
      try {
        final provider = adapter(entry.sourceId);
        final directBytes = await provider.coverBytes(entry);
        if (directBytes != null) {
          requireSession(epoch);
          return await saveCover(entry, Uint8List.fromList(directBytes), profile: profile);
        }
        final lease = await provider.cover(entry);
        if (lease == null) return null;
        final response = await provider.transport.send('GET', lease.uri, headers: lease.headers, redirects: true);
        SourceTransport.check(response.statusCode);
        final bytes = <int>[];
        await for (final chunk in response.stream.timeout(const Duration(seconds: 20))) {
          if (bytes.length + chunk.length > 8 * 1024 * 1024) throw const SourceException(SourceFailure.invalidData);
          bytes.addAll(chunk);
        }
        requireSession(epoch);
        return await saveCover(entry, Uint8List.fromList(bytes), profile: profile);
      } catch (_) {
        return null;
      }
    });
  }

  Future<File> saveCover(SourceEntry entry, Uint8List bytes, {String? profile}) async {
    requireSession();
    final epoch = generation, owner = profile ?? profileId!;
    if (bytes.length > 8 * 1024 * 1024) throw const SourceException(SourceFailure.invalidData);
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 384, allowUpscaling: false);
    final frame = await codec.getNextFrame();
    codec.dispose();
    final image = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    requireSession(epoch);
    if (owner != profileId || image == null) throw const SourceException(SourceFailure.cancelled);
    final file = File(
      p.join(downloads.directory.path, sourceDigest(owner), 'covers', '${sourceDigest(entry.key)}.png'),
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(image.buffer.asUint8List(), flush: true);
    if (!current(epoch)) {
      if (await file.exists()) await file.delete();
      throw const SourceException(SourceFailure.cancelled);
    }
    _covers[sourceKey(owner, entry.key)] = Future.value(file);
    return file;
  }

  static bool samePosition(PublicationProgress a, PublicationProgress b) {
    if (a.finished != b.finished) return false;
    if (a.mode == PublicationMode.reading) {
      if (a.locator?.cfi != null || b.locator?.cfi != null) return a.locator?.cfi == b.locator?.cfi;
      return a.locator?.page == b.locator?.page && (a.fraction - b.fraction).abs() < .0001;
    }
    return (a.positionMs - b.positionMs).abs() < 1000 && a.fileIndex == b.fileIndex;
  }

  Future<void> _baseline(String profile, PublicationProgress value) =>
      repository.savePreference(profile, 'remote:${value.key}', value.toJson());
  Future<bool> _diverged(String profile, PublicationProgress local, PublicationProgress remote) async {
    if (samePosition(local, remote)) return false;
    final baseline = await repository.preference(profile, 'remote:${local.key}');
    // A server clock is not an ordering primitive. Compare against the last
    // observed server snapshot, preserving deliberate rewinds and resets.
    return baseline.isEmpty || !samePosition(PublicationProgress.fromJson(baseline), remote);
  }

  Future<PublicationProgress> openProgress(SourceEntry entry, PublicationProgress initial) async {
    await ready;
    requireSession();
    final epoch = generation, profile = profileId!;
    var local = await repository.progress(profile, initial.key);
    final owner = sources.where((s) => s.id == entry.sourceId).firstOrNull;
    final syncEntry = owner == null ? entry : _withSyncIdentity(owner, entry);
    if (owner != null) {
      final provider = _stateAdapter(syncEntry, initial);
      if (provider != null) {
        try {
          final remote = await provider.readProgress(syncEntry, local ?? initial);
          requireSession(epoch);
          if (remote != null) {
            if (local == null || !await repository.isPending(profile, initial.key)) {
              local = await repository.saveProgress(
                profile,
                remote.copyWith(revision: local?.revision ?? 0, session: initial.session),
                kind: 'remote',
              );
              await repository.acknowledge(profile, local.key, local.revision);
              await _baseline(profile, remote);
            } else if (await _diverged(profile, local, remote)) {
              await repository.recordRemoteConflict(profile, remote);
            }
          } else if (local == null) {
            await _baseline(profile, initial);
          }
          final notes = await provider.readAnnotations(syncEntry, local ?? initial);
          requireSession(epoch);
          final existing = await repository.annotations(profile, entry.key);
          for (final note in notes) {
            if (existing.any(
              (a) =>
                  a.edition == note.edition &&
                  a.mode == note.mode &&
                  a.positionMs == note.positionMs &&
                  a.locator?.cfi == note.locator?.cfi,
            )) {
              continue;
            }
            await repository.importAnnotation(profile, note);
          }
        } on SourceException catch (e) {
          if (e.reason == SourceFailure.cancelled || e.reason == SourceFailure.invalidData) rethrow;
        } catch (_) {
          /* Offline local state remains authoritative until reconnection. */
        }
      }
    }
    requireSession(epoch);
    return (local ?? initial).copyWith(session: initial.session);
  }

  Future<void> resolveConflict(SourceEntry entry, PublicationProgress local, {required bool useRemote}) async {
    requireSession();
    final epoch = generation, profile = profileId!;
    final remote = await repository.remoteConflict(profile, local.key);
    if (remote == null) return;
    if (useRemote) {
      final current = await repository.progress(profile, local.key);
      final saved = await repository.saveProgress(
        profile,
        remote.copyWith(revision: current!.revision),
        kind: 'restore',
      );
      await repository.acknowledge(profile, saved.key, saved.revision);
      await _baseline(profile, remote);
    } else {
      await _baseline(profile, remote);
      await repository.clearConflict(profile, local.key);
      await sync(onlyKey: local.key);
    }
    requireSession(epoch);
    _notify();
  }

  Future<FileSource> importFiles(List<PlatformFile> files, {required String name}) async {
    await ready;
    requireSession();
    final epoch = generation, profile = profileId!;
    final root = Directory(p.join(downloads.directory.path, sourceDigest(profile), 'imports'));
    await root.create(recursive: true);
    final source =
        sources.where((s) => s.kind == FileSourceKind.local && s.options['imported'] == 'true').firstOrNull ??
        FileSource(
          id: const Uuid().v4(),
          profileId: profile,
          kind: FileSourceKind.local,
          name: name,
          root: root.path,
          options: const {'imported': 'true'},
        );
    for (final file in files) {
      requireSession(epoch);
      if (classifySourceFile(file.name) == SourceItemKind.unknown) continue;
      var filename = p.basename(file.name).replaceAll(RegExp(r'[\x00-\x1f]'), '');
      if (filename.isEmpty || filename == '.' || filename == '..') {
        throw const SourceException(SourceFailure.invalidData);
      }
      if (await File(p.join(root.path, filename)).exists()) {
        filename =
            '${p.basenameWithoutExtension(filename)}-${const Uuid().v4().substring(0, 8)}${p.extension(filename)}';
      }
      final partial = File(p.join(root.path, '.$filename.partial'));
      final input = file.readStream ?? (file.path == null ? null : File(file.path!).openRead());
      if (input == null) throw const SourceException(SourceFailure.unavailable);
      final sink = partial.openWrite();
      try {
        await sink.addStream(
          input.map((bytes) {
            requireSession(epoch);
            return bytes;
          }),
        );
        await sink.flush();
      } finally {
        await sink.close();
      }
      requireSession(epoch);
      await partial.rename(p.join(root.path, filename));
    }
    await add(source, {});
    await browse(source.id);
    return source;
  }

  Future<SourceEntry> groupAudio(SourceEntry folder, List<SourceEntry> children, {required String title}) async {
    requireSession();
    final entries = children.where((e) => e.audio.isNotEmpty).toList()
      ..sort((a, b) => _naturalCompare(a.title, b.title));
    final book = SourceEntry(
      sourceId: folder.sourceId,
      id: 'group:${folder.id}',
      title: title,
      kind: SourceItemKind.audiobook,
      parentId: folder.id,
      files: [...entries.expand((e) => e.audio), ...children.expand((e) => e.ebooks)],
    );
    await repository.cacheEntries(profileId!, [book]);
    _notify();
    return book;
  }

  static int _naturalCompare(String a, String b) {
    final pattern = RegExp(r'\d+|\D+');
    final aa = pattern.allMatches(a.toLowerCase()).map((m) => m[0]!).toList();
    final bb = pattern.allMatches(b.toLowerCase()).map((m) => m[0]!).toList();
    for (var i = 0; i < aa.length && i < bb.length; i++) {
      final an = int.tryParse(aa[i]), bn = int.tryParse(bb[i]);
      final compare = an != null && bn != null ? an.compareTo(bn) : aa[i].compareTo(bb[i]);
      if (compare != 0) return compare;
    }
    return aa.length.compareTo(bb.length);
  }

  /// Replays absolute snapshots once per key. A divergent server session is
  /// retained as a conflict, never resolved by taking the larger percentage.
  Future<void> sync({String? onlyKey}) {
    final operation = _syncQueue.then((_) => _sync(onlyKey: onlyKey));
    _syncQueue = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> _sync({String? onlyKey}) async {
    await ready;
    requireSession();
    final epoch = generation, profile = profileId!;
    final entries = await repository.entries(profile);
    final events = await repository.pendingEvents(profile);
    final latest = <String, Map<String, dynamic>>{};
    for (final event in events) {
      if (event['kind'] != 'annotation') latest[event['key'] as String] = event;
    }
    for (final event in latest.values) {
      requireSession(epoch);
      final progress = PublicationProgress.fromJson(sourceMap(jsonDecode(event['payload'] as String)));
      if (onlyKey != null && progress.key != onlyKey) continue;
      final storedEntry = entries.where((e) => e.key == progress.entryKey).firstOrNull;
      if (storedEntry == null) continue;
      final owner = sources.where((s) => s.id == storedEntry.sourceId).firstOrNull;
      if (owner == null) continue;
      final entry = _withSyncIdentity(owner, storedEntry);
      final source = _stateAdapter(entry, progress);
      if (source == null) continue;
      PublicationProgress? remote;
      try {
        remote = await source.readProgress(entry, progress);
      } on SourceException catch (e) {
        if (e.status != 404) rethrow;
      }
      requireSession(epoch);
      if (remote != null && await _diverged(profile, progress, remote)) {
        await repository.recordRemoteConflict(profile, remote);
        continue;
      }
      try {
        await source.writeProgress(entry, progress);
      } on SourceException catch (e) {
        if (e.reason != SourceFailure.conflict) rethrow;
        final changed = await source.readProgress(entry, progress);
        if (changed != null) await repository.recordRemoteConflict(profile, changed);
        continue;
      }
      requireSession(epoch);
      await _baseline(profile, progress);
      await repository.acknowledge(profile, progress.key, progress.revision);
    }
    for (final event in events.where((e) => e['kind'] == 'annotation')) {
      requireSession(epoch);
      final annotation = BookAnnotation.fromJson(sourceMap(jsonDecode(event['payload'] as String)));
      final storedEntry = entries.where((e) => e.key == annotation.entryKey).firstOrNull;
      if (storedEntry == null) continue;
      final owner = sources.where((s) => s.id == storedEntry.sourceId).firstOrNull;
      if (owner == null) continue;
      final entry = _withSyncIdentity(owner, storedEntry);
      final annotationProgress = PublicationProgress(
        entryKey: annotation.entryKey,
        edition: annotation.edition,
        mode: annotation.mode,
        session: '',
      );
      final source = _stateAdapter(entry, annotationProgress);
      if (source == null || !source.capabilities.annotations ||
          (source.source.kind == FileSourceKind.audiobookshelf && annotation.mode != PublicationMode.listening)) {
        continue;
      }
      await source.writeAnnotation(entry, annotation);
      requireSession(epoch);
      // The annotation/tombstone remains in its durable table. Only this exact
      // acknowledged event can be removed; newer edits have a different ID.
      await repository.database.customStatement('DELETE FROM events WHERE profile=? AND id=?', [profile, event['id']]);
    }
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _syncTimer?.cancel();
    _syncSoon?.cancel();
    generation++;
    final stopped = stopPlayback?.call();
    for (final adapter in _adapters.values) {
      adapter.close();
    }
    _adapters.clear();
    unawaited(
      ready.then((_) async {
        oauth.dispose();
        downloads.cancelAll();
        await stopped;
        await repository.database.close();
      }),
    );
    super.dispose();
  }
}
