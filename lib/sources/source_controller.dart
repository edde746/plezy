import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'adapters/audiobookshelf_source.dart';
import 'adapters/cloud_sources.dart';
import 'adapters/dlna_source.dart';
import 'adapters/ftp_source.dart';
import 'adapters/komga_source.dart';
import 'adapters/local_source.dart';
import 'adapters/nfs_source.dart';
import 'adapters/sftp_source.dart';
import 'adapters/opds_source.dart';
import 'adapters/s3_source.dart';
import 'adapters/smb_source.dart';
import 'adapters/webdav_source.dart';
import 'content_access.dart';
import 'source_database.dart';
import 'source_models.dart';
import 'source_oauth.dart';
import '../services/standalone_video_metadata_client.dart';
import 'source_transport.dart';
import 'publication_shelf.dart';
import 'sync/publication_sync.dart';
import 'sync/sync_store.dart';
import 'sync/sync_document.dart';

Uri? _trustedOnlinePosterUri(String? value) {
  final uri = Uri.tryParse(value ?? '');
  final host = uri?.host.toLowerCase();
  if (uri == null ||
      uri.scheme != 'https' ||
      host == null ||
      !(host == 'trakt.tv' || host.endsWith('.trakt.tv')) ||
      uri.userInfo.isNotEmpty) {
    return null;
  }
  return uri;
}

Uri? _trustedOnlineTrailerUri(String? value) {
  final uri = Uri.tryParse(value ?? '');
  final host = uri?.host.toLowerCase();
  if (uri == null || uri.scheme != 'https' || host == null || uri.userInfo.isNotEmpty) return null;
  if (host == 'youtu.be' ||
      host == 'youtube.com' ||
      host.endsWith('.youtube.com') ||
      host == 'vimeo.com' ||
      host.endsWith('.vimeo.com')) {
    return uri;
  }
  return null;
}

class SourceController extends ChangeNotifier {
  SourceController({SourceRepository? repository}) {
    ready = _initialize(repository);
  }
  late final Future<void> ready;
  late SourceRepository repository;
  late PublicationSync cloudSync;
  PublicationSyncConfig? syncConfig;
  final Set<String> activeProgressKeys = {};
  void holdProgress(String key) => activeProgressKeys.add(key);
  void releaseProgress(String key) => activeProgressKeys.remove(key);
  bool cloudConflict(String key) => cloudSync.conflicts.values.any(
    (c) => c.values.any((v) {
      final d = sourceMap(v.value['data']);
      return v.value['type'] == 'progress' &&
          PublicationProgress(
                entryKey: c.entry.key,
                edition: d['edition'] as String,
                mode: PublicationMode.values.byName(d['mode'] as String),
                session: '',
              ).key ==
              key;
    }),
  );
  late SourceOAuthService oauth;
  late PublicationDownloads downloads;
  final Map<String, _ImportTransfer> _importTransfers = {};
  final Map<String, Future<File?>> _covers = {};
  final Map<String, Future<SourceEntry>> _onlineLookups = {};
  final StandaloneVideoMetadataClient _videoMetadata = StandaloneVideoMetadataClient();
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
  final Map<String, int> _sourceSyncFailures = {};
  final Map<String, DateTime> _sourceSyncRetryAt = {};

  bool _sourceSyncReady(String sourceId) => !(_sourceSyncRetryAt[sourceId]?.isAfter(DateTime.now()) ?? false);

  void _sourceSyncFailed(String sourceId) {
    final failures = (_sourceSyncFailures[sourceId] ?? 0) + 1;
    _sourceSyncFailures[sourceId] = failures;
    final shift = (failures - 1).clamp(0, 7).toInt();
    final seconds = (30 << shift).clamp(30, 3600).toInt();
    _sourceSyncRetryAt[sourceId] = DateTime.now().add(Duration(seconds: seconds));
  }

  void _sourceSyncSucceeded(String sourceId) {
    _sourceSyncFailures.remove(sourceId);
    _sourceSyncRetryAt.remove(sourceId);
  }

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

  void _cancelImports({String? sourceId}) {
    for (final transfer in _importTransfers.values) {
      if (sourceId == null || transfer.sourceId == sourceId) transfer.cancellation.cancel();
    }
  }

  Future<void> _settleImports({String? sourceId}) async {
    final transfers = _importTransfers.values
        .where((transfer) => sourceId == null || transfer.sourceId == sourceId)
        .toList();
    for (final transfer in transfers) {
      transfer.cancellation.cancel();
    }
    await Future.wait(transfers.map((transfer) => transfer.finished.future));
  }

  Future<void> _initialize(SourceRepository? provided) async {
    repository = provided ?? SourceRepository(await SourceDatabase.open());
    cloudSync = PublicationSync(repository);
    oauth = SourceOAuthService(repository);
    downloads = PublicationDownloads(
      repository,
      Directory(p.join((await getApplicationSupportDirectory()).path, 'publication-files')),
    );
    _syncTimer = Timer.periodic(const Duration(minutes: 1), (_) => scheduleSync());
  }

  void attachProfile(String? id, {required bool blocked}) {
    if (profileId == id && this.blocked == blocked) return;
    _cancelImports();
    profileId = id;
    this.blocked = blocked;
    generation++;
    _sourceSyncFailures.clear();
    _sourceSyncRetryAt.clear();
    activeProgressKeys.clear();
    syncConfig = null;
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
            await _settleImports();
            downloads.cancelAll();
            oauth.cancel();
            if (id != null && !blocked && current(epoch)) {
              final loadedSources = await repository.sources(id);
              if (!current(epoch)) return;
              final config = await cloudSync.config(id);
              if (!current(epoch)) return;
              final profileSources = loadedSources.where((source) => source.profileId == id).toList(growable: false);
              final stagedAdapters = <String, SourceAdapter>{};
              var committed = false;
              try {
                SourceAdapter? resolveStagedAdapter(String sourceId) {
                  if (!current(epoch)) return null;
                  final source = profileSources.where((candidate) => candidate.id == sourceId).firstOrNull;
                  if (source == null || source.profileId != id) return null;
                  return stagedAdapters.putIfAbsent(sourceId, () => _createAdapter(source, epoch));
                }

                await downloads.restoreProfile(id, resolveStagedAdapter);
                if (!current(epoch)) return;
                for (final imported in profileSources.where((source) => source.options['imported'] == 'true')) {
                  await downloads.reconcileImportedFiles(id, imported);
                  if (!current(epoch)) return;
                }
                final profileShelves = await _loadShelves(id, profileSources, epoch);
                if (!current(epoch)) return;

                // Publish the complete snapshot only after its dependent
                // downloads, imports, and shelf state have been reconciled.
                sources = profileSources;
                cloudSync.resetStatus();
                syncConfig = config;
                _adapters.addAll(stagedAdapters);
                shelves = profileShelves;
                committed = true;
                scheduleSync();
              } finally {
                if (!committed) {
                  // restoreProfile may have requeued transfers before an
                  // imported-file or shelf reconciliation failed. Keep those
                  // jobs paused and wait for their writers before retiring
                  // adapters staged for this snapshot.
                  if (current(epoch)) await downloads.settleCancelled();
                  for (final adapter in stagedAdapters.values) {
                    adapter.close();
                  }
                }
              }
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
                port: endpoint.scheme == 'smb' && endpoint.hasPort && endpoint.port == 445 ? null : endpoint.port,
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

  SourceEntry _applyCachedOnlineMetadata(SourceEntry fresh, SourceEntry? cached) {
    if (fresh.kind != SourceItemKind.video ||
        cached == null ||
        cached.kind != SourceItemKind.video ||
        cached.onlineMetadataProvider == null) {
      return fresh;
    }
    return fresh.copyWith(
      onlineTitle: cached.onlineTitle,
      description: fresh.description.isNotEmpty ? fresh.description : cached.description,
      releaseYear: fresh.releaseYear ?? cached.releaseYear,
      rating: fresh.rating ?? cached.rating,
      genres: fresh.genres.isNotEmpty ? fresh.genres : cached.genres,
      identifiers: {...cached.identifiers, ...fresh.identifiers},
      onlinePosterUrl: cached.onlinePosterUrl,
      trailerUrl: cached.trailerUrl,
      cast: cached.cast,
      onlineMetadataProvider: cached.onlineMetadataProvider,
      onlineMetadataCheckedAt: cached.onlineMetadataCheckedAt,
    );
  }

  SourceAdapter? _stateAdapter(SourceEntry entry, PublicationProgress progress) {
    final owner = sources.where((source) => source.id == entry.sourceId).firstOrNull;
    if (owner != null) {
      final local = adapter(owner.id);
      if (local.supportsProgress(entry, progress)) return local;
    }
    // A single configured WebDAV state folder can synchronize other sources.
    // If more than one is configured, leave cross-source progress local.
    final targets = sources
        .where(
          (source) => source.kind == FileSourceKind.webdav && (source.options['syncRoot']?.trim().isNotEmpty ?? false),
        )
        .toList();
    if (targets.length != 1) return null;
    final target = adapter(targets.single.id);
    return target.supportsProgress(entry, progress) ? target : null;
  }

  void requireSession([int? epoch]) {
    if (_disposed || blocked || profileId == null || (epoch != null && !current(epoch))) {
      throw const SourceException(SourceFailure.cancelled);
    }
  }

  /// Searches only the active profile's already indexed catalogue. This never
  /// enumerates remote folders or sends a query to an unconfigured provider.
  Future<List<SourceEntry>> searchIndex(String query, {int limit = 500}) async {
    final epoch = generation;
    await ready;
    requireSession(epoch);
    if (query.trim().isEmpty) return const [];
    final page = await repository.entriesPage(profileId!, query: query, limit: limit);
    requireSession(epoch);
    final configured = {for (final source in sources) source.id};
    return [
      for (final entry in page.items)
        if (configured.contains(entry.sourceId) &&
            entry.kind != SourceItemKind.folder &&
            entry.kind != SourceItemKind.unknown)
          entry,
    ];
  }

  Future<void> reload() async {
    await ready;
    requireSession();
    final epoch = generation, profile = profileId!;
    final result = (await repository.sources(
      profile,
    )).where((source) => source.profileId == profile).toList(growable: false);
    if (!current(epoch)) return;
    final nextShelves = await _loadShelves(profile, result, epoch);
    if (!current(epoch)) return;
    sources = result;
    shelves = nextShelves;
    _notify();
  }

  Future<void> forgetProfile(String profile) async {
    await ready;
    if (profileId == profile) {
      attachProfile(null, blocked: true);
      _notify();
      await stopPlayback?.call();
    }
    await _settleImports();
    await downloads.settleCancelled();
    await repository.forgetProfile(profile);
    final root = Directory(p.join(downloads.directory.path, sourceDigest(profile)));
    if (await root.exists()) await root.delete(recursive: true);
    _covers.clear();
  }

  Future<void> _shelves(String profile, int epoch) async {
    final nextShelves = await _loadShelves(profile, sources, epoch);
    if (current(epoch)) shelves = nextShelves;
  }

  Future<Set<PublicationShelf>> _loadShelves(String profile, List<FileSource> profileSources, int epoch) async {
    final cached = await Future.wait(
      PublicationShelf.values.map((shelf) => repository.hasShelfEntries(profile, shelf)),
    );
    if (!current(epoch)) return const {};
    return {
      for (var index = 0; index < PublicationShelf.values.length; index++)
        if (cached[index] ||
            profileSources.any((source) {
              final configured = source.options['shelves']?.split(',');
              final enabled = configured ?? defaultPublicationShelves(source.kind).map((s) => s.name).toList();
              return enabled.contains(PublicationShelf.values[index].name);
            }))
          PublicationShelf.values[index],
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
    var pendingIndex = 0;
    try {
      final scanGeneration = await repository.beginSourceScan(profile, sourceId);
      while (pendingIndex < pending.length) {
        checkScan();
        final (parent, depth) = pending[pendingIndex++];
        if (!seen.add(parent ?? '')) continue;
        if (depth > 32 || seen.length > 10000) throw const SourceException(SourceFailure.invalidData);
        String? cursor;
        final cursors = <String>{};
        do {
          final page = await browse(sourceId, parent: parent, cursor: cursor);
          checkScan();
          await repository.markScannedEntries(profile, scanGeneration, page.entries);
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
      checkScan();
      await repository.finishSourceScan(
        profile,
        sourceId,
        scanGeneration,
        isCurrent: () => current(epoch) && identical(_scanSessions[sourceId], session),
      );
      checkScan();
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
    final oldSource = sources.where((candidate) => candidate.id == source.id).firstOrNull;
    final identityChanged =
        oldSource != null &&
        (oldSource.kind != source.kind ||
            oldSource.endpoint != source.endpoint ||
            oldSource.root != source.root ||
            oldSource.options['syncLibrary'] != source.options['syncLibrary'] ||
            oldSource.options['driveId'] != source.options['driveId']);
    final existingEntries = identityChanged
        ? await repository.entries(source.profileId, source: source.id)
        : const <SourceEntry>[];
    requireSession(epoch);
    if (identityChanged) {
      final migration = _syncQueue.then((_) async {
        requireSession(epoch);
        await cloudSync.migrateSourceIdentity(
          profile: source.profileId,
          oldSource: oldSource,
          newSource: source,
          entries: existingEntries,
        );
        requireSession(epoch);
      });
      _syncQueue = migration.catchError((Object _) {});
      await migration;
      requireSession(epoch);
    }
    await repository.saveSource(source, credentials);
    requireSession(epoch);
    _sourceSyncSucceeded(source.id);
    await reload();
  }

  Future<void> reconnect(String id) async {
    _adapters.remove(id)?.close();
    _sourceSyncSucceeded(id);
  }

  Future<void> remove(FileSource source) async {
    requireSession();
    final epoch = generation, profile = profileId!;
    if (source.profileId != profile) throw const SourceException(SourceFailure.permission);
    if (syncConfig?.sourceId == source.id) await configureCloudSync(null);
    requireSession(epoch);
    cancelScan(source.id);
    await stopPlayback?.call();
    requireSession(epoch);
    await _settleImports(sourceId: source.id);
    requireSession(epoch);
    await downloads.cancelSource(profile, source.id);
    requireSession(epoch);
    _adapters.remove(source.id)?.close();
    _sourceSyncSucceeded(source.id);
    await repository.removeSource(profile, source.id);
    requireSession(epoch);
    await reload();
  }

  SourceAdapter adapter(String id) {
    requireSession();
    if (loading) throw const SourceException(SourceFailure.cancelled);
    final epoch = generation;
    final source = sources.where((candidate) => candidate.id == id).firstOrNull;
    if (source == null || source.profileId != profileId) {
      throw const SourceException(SourceFailure.authentication);
    }
    return _adapters.putIfAbsent(id, () => _createAdapter(source, epoch));
  }

  SourceAdapter _createAdapter(FileSource source, int epoch) {
    if (!current(epoch) || blocked || source.profileId != profileId) {
      throw const SourceException(SourceFailure.cancelled);
    }
    final transport = SourceTransport(allowHttp: source.options['allowHttp'] == 'true');
    void checkOwner() {
      if (!current(epoch) || blocked || source.profileId != profileId) {
        throw const SourceException(SourceFailure.cancelled);
      }
    }

    Future<Map<String, String>> credentials() async {
      checkOwner();
      final value = await repository.credentials(source);
      checkOwner();
      return value;
    }

    Future<String> token({bool refresh = false}) async {
      checkOwner();
      final value = await oauth.accessToken(source, refresh: refresh);
      checkOwner();
      return value;
    }

    Future<Map<String, String>> backgroundCredentials() => credentials();
    return switch (source.kind) {
      FileSourceKind.local => LocalSourceAdapter(source, transport),
      FileSourceKind.webdav => WebDavSourceAdapter(source, transport, credentials),
      FileSourceKind.googleDrive => GoogleDriveSourceAdapter(source, transport, token, backgroundCredentials),
      FileSourceKind.oneDrive => OneDriveSourceAdapter(source, transport, token, backgroundCredentials),
      FileSourceKind.dropbox => DropboxSourceAdapter(source, transport, token, backgroundCredentials),
      FileSourceKind.s3 => S3SourceAdapter(source, transport, credentials),
      FileSourceKind.smb => SmbSourceAdapter(source, transport, credentials),
      FileSourceKind.ftp => FtpSourceAdapter(source, transport, credentials),
      FileSourceKind.sftp => SftpSourceAdapter(source, transport, credentials),
      FileSourceKind.nfs => NfsSourceAdapter(source, transport, credentials),
      FileSourceKind.dlna => DlnaSourceAdapter(source, transport),
      FileSourceKind.komga => KomgaSourceAdapter(source, transport, credentials),
      FileSourceKind.opds => OpdsSourceAdapter(source, transport, credentials),
      FileSourceKind.audiobookshelf => AudiobookshelfSourceAdapter(source, transport, credentials),
    };
  }

  Future<SourcePage> browse(String source, {String? parent, String? cursor, String? query}) async {
    await ready;
    requireSession();
    final epoch = generation, profile = profileId!;
    final fileSource = sources.where((item) => item.id == source).firstOrNull;
    if (fileSource == null) throw const SourceException(SourceFailure.authentication);
    final page = await adapter(source).browse(parent: parent, cursor: cursor, query: query);
    requireSession(epoch);
    final entries = <SourceEntry>[];
    for (final entry in page.entries) {
      final fresh = _withSyncIdentity(fileSource, entry);
      final cached = fresh.kind == SourceItemKind.video ? await repository.entryById(profile, source, fresh.id) : null;
      entries.add(_applyCachedOnlineMetadata(fresh, cached));
    }
    requireSession(epoch);
    await repository.cacheEntries(profile, entries);
    requireSession(epoch);
    shelves.addAll(PublicationShelf.values.where((s) => entries.any(s.includes)));
    _notify();
    return SourcePage(entries, next: page.next, title: page.title);
  }

  Future<SourceEntry> hydrate(SourceEntry entry) async {
    requireSession();
    final epoch = generation, profile = profileId!;
    final fileSource = sources.where((item) => item.id == entry.sourceId).firstOrNull;
    if (fileSource == null) throw const SourceException(SourceFailure.authentication);
    final fresh = _withSyncIdentity(fileSource, await adapter(entry.sourceId).hydrate(entry));
    final cached = fresh.kind == SourceItemKind.video
        ? await repository.entryById(profile, entry.sourceId, fresh.id)
        : null;
    final result = _applyCachedOnlineMetadata(fresh, cached);
    requireSession(epoch);
    await repository.cacheEntries(profile, [result]);
    return result;
  }

  Future<void> saveOnlineMetadata(
    SourceEntry entry, {
    required String title,
    String? overview,
    int? releaseYear,
    double? rating,
    List<String> genres = const [],
    Map<String, String> identifiers = const {},
    String? posterUrl,
    String? trailerUrl,
    List<String> cast = const [],
    required String provider,
  }) async {
    await ready;
    requireSession();
    final profile = profileId!;
    final epoch = generation;
    final source = sources.where((item) => item.id == entry.sourceId).firstOrNull;
    if (source == null || entry.kind != SourceItemKind.video || title.trim().isEmpty) {
      throw const SourceException(SourceFailure.invalidData);
    }
    final poster = _trustedOnlinePosterUri(posterUrl)?.toString();
    final trailer = _trustedOnlineTrailerUri(trailerUrl)?.toString();
    final matched = _withSyncIdentity(
      source,
      entry.copyWith(
        onlineTitle: title.trim(),
        description: entry.description.isNotEmpty ? entry.description : overview,
        releaseYear: entry.releaseYear ?? releaseYear,
        rating: entry.rating ?? rating,
        genres: entry.genres.isNotEmpty ? entry.genres : genres,
        identifiers: {...entry.identifiers, ...identifiers},
        onlinePosterUrl: poster,
        trailerUrl: trailer,
        cast: cast.take(20).toList(growable: false),
        onlineMetadataProvider: provider,
        onlineMetadataCheckedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    await repository.cacheEntries(profile, [matched]);
    requireSession(epoch);
    unawaited(_covers.remove(sourceKey(profile, entry.key))?.then<void>((_) {}, onError: (Object _) {}));
    _notify();
  }

  Future<SourceEntry> identifyOnlineMetadata(SourceEntry entry, {bool force = false}) async {
    await ready;
    requireSession();
    if (entry.kind != SourceItemKind.video) return entry;
    final profile = profileId!;
    final source = sources.where((item) => item.id == entry.sourceId).firstOrNull;
    if (source == null || source.options['onlineMetadata'] != 'true') return entry;
    final key = sourceKey(profile, entry.key);
    final cachedLookup = _onlineLookups[key];
    if (cachedLookup != null) return cachedLookup;
    final task = _identifyOnlineMetadata(entry, source, profile, generation, force);
    _onlineLookups[key] = task;
    try {
      return await task;
    } finally {
      _onlineLookups.removeWhere((key, value) => identical(value, task));
    }
  }

  Future<SourceEntry> _identifyOnlineMetadata(
    SourceEntry entry,
    FileSource source,
    String profile,
    int epoch,
    bool force,
  ) async {
    final cached = await repository.entryById(profile, source.id, entry.id);
    final current = _applyCachedOnlineMetadata(entry, cached);
    if (!force &&
        (current.onlineMetadataProvider != null ||
            current.onlineMetadataCheckedAt != null &&
                DateTime.now().millisecondsSinceEpoch - current.onlineMetadataCheckedAt! <
                    const Duration(days: 30).inMilliseconds)) {
      return current;
    }
    try {
      final metadata = await _videoMetadata.identify(current);
      requireSession(epoch);
      if (metadata == null) {
        final checked = _withSyncIdentity(
          source,
          current.copyWith(onlineMetadataCheckedAt: DateTime.now().millisecondsSinceEpoch),
        );
        await repository.cacheEntries(profile, [checked]);
        return checked;
      }
      await saveOnlineMetadata(
        current,
        title: metadata.title,
        overview: metadata.overview,
        releaseYear: metadata.year,
        rating: metadata.rating,
        genres: metadata.genres,
        identifiers: metadata.identifiers,
        posterUrl: metadata.posterUrl,
        trailerUrl: metadata.trailerUrl,
        cast: metadata.cast,
        provider: metadata.provider,
      );
      requireSession(epoch);
      return await repository.entryById(profile, source.id, entry.id) ?? current;
    } on Object {
      return current;
    }
  }

  Future<File> content(SourceEntry entry, PublicationFile file, {void Function(int, int?)? onProgress}) async {
    await ready;
    requireSession();
    final epoch = generation;
    final local = await downloads.local(profileId!, entry.sourceId, file);
    if (local != null) return local;
    final result = await downloads.download(
      profileId!,
      adapter(entry.sourceId),
      file,
      label: entry.displayTitle,
      onProgress: onProgress,
    );
    requireSession(epoch);
    return result;
  }

  Future<void> cancelDownload(String downloadKey) async {
    await ready;
    requireSession();
    final importing = _importTransfers[downloadKey];
    if (importing != null) {
      importing.cancellation.cancel();
      await importing.finished.future;
      return;
    }
    final profile = profileId!;
    final row = await repository.download(profile, downloadKey);
    if (row == null) return;
    final sourceId = row['source_id'] as String? ?? '';
    final file = PublicationFile.fromJson(sourceMap(jsonDecode(row['file_payload'] as String? ?? '{}')));
    if (sourceId.isEmpty) throw const SourceException(SourceFailure.invalidData);
    await downloads.cancelAndWait(profile, sourceId, file);
  }

  Future<void> retryDownload(String downloadKey) async {
    await ready;
    requireSession();
    final epoch = generation, profile = profileId!;
    final row = await repository.download(profile, downloadKey);
    requireSession(epoch);
    if (row == null) throw const SourceException(SourceFailure.invalidData);
    if (row['state'] == 'orphaned' || row['state'] == 'importing') {
      throw const SourceException(SourceFailure.unsupported);
    }
    final sourceId = row['source_id'] as String? ?? '';
    final file = PublicationFile.fromJson(sourceMap(jsonDecode(row['file_payload'] as String? ?? '{}')));
    if (sourceId.isEmpty || file.fingerprint != row['fingerprint'] || sourceKey(sourceId, file.id) != downloadKey) {
      throw const SourceException(SourceFailure.invalidData);
    }
    final source = sources.where((candidate) => candidate.id == sourceId).firstOrNull;
    if (source == null || source.profileId != profile) throw const SourceException(SourceFailure.permission);
    final sourceAdapter = adapter(sourceId);
    requireSession(epoch);
    await downloads.download(profile, sourceAdapter, file, label: row['label'] as String? ?? '');
    requireSession(epoch);
  }

  Future<void> removeDownloadJob(String downloadKey) async {
    await ready;
    requireSession();
    final epoch = generation, profile = profileId!;
    final importing = _importTransfers[downloadKey];
    if (importing != null) {
      importing.cancellation.cancel();
      await importing.finished.future;
      final row = await repository.download(profile, downloadKey);
      if (row != null && row['complete'] == 1) {
        final sourceId = row['source_id'] as String? ?? '';
        final file = PublicationFile.fromJson(sourceMap(jsonDecode(row['file_payload'] as String? ?? '{}')));
        if (sourceId.isEmpty) throw const SourceException(SourceFailure.invalidData);
        await downloads.remove(profile, sourceId, file);
        requireSession(epoch);
        return;
      }
    }
    await downloads.removeQueuedJob(profile, downloadKey);
    requireSession(epoch);
  }

  Future<String?> sharedEntryMapping(SourceEntry entry) async {
    await ready;
    requireSession();
    if (!sources.any((source) => source.id == entry.sourceId)) {
      throw const SourceException(SourceFailure.authentication);
    }
    return cloudSync.sharedEntryMapping(profileId!, entry);
  }

  Future<void> setSharedEntryMapping(SourceEntry entry, String? sharedEntryId) async {
    await ready;
    requireSession();
    final epoch = generation, profile = profileId!;
    final source = sources.where((candidate) => candidate.id == entry.sourceId).firstOrNull;
    if (source == null || source.options['syncLibrary']?.trim().isNotEmpty != true) {
      throw const SourceException(SourceFailure.unsupported);
    }
    final operation = _syncQueue.then((_) async {
      requireSession(epoch);
      final localEntry = await repository.entryById(profile, source.id, entry.id);
      requireSession(epoch);
      if (localEntry == null) throw const SourceException(SourceFailure.permission);
      await cloudSync.setSharedEntryMapping(
        profile: profile,
        source: source,
        entry: localEntry,
        sharedEntryId: sharedEntryId,
      );
      requireSession(epoch);
    });
    _syncQueue = operation.catchError((Object _) {});
    await operation;
    scheduleSync();
    _notify();
  }

  Future<({int bytes, int elapsedMs, int requests, int readAhead, double mebibytesPerSecond})> qualifyNfsRead(
    String sourceId,
    PublicationFile file,
  ) async {
    await ready;
    requireSession();
    final source = adapter(sourceId);
    if (source is! NfsSourceAdapter) throw const SourceException(SourceFailure.unsupported);
    final epoch = generation;
    final result = await source.qualifyRead(file);
    requireSession(epoch);
    return result;
  }

  Future<File?> cover(SourceEntry entry, {bool refresh = false}) {
    final profile = profileId;
    if (profile == null || blocked) return Future.value();
    final cacheKey = sourceKey(profile, entry.key);
    if (refresh) _covers.remove(cacheKey);
    return _covers.putIfAbsent(cacheKey, () async {
      await ready;
      final epoch = generation;
      final file = File(
        p.join(
          downloads.directory.path,
          sourceDigest(profile),
          'covers',
          '${sourceDigest(jsonEncode([entry.key, entry.coverId, entry.onlinePosterUrl]))}.png',
        ),
      );
      if (!refresh && await file.exists()) return file;
      if (!sources.any((s) => s.id == entry.sourceId)) return null;
      try {
        final provider = adapter(entry.sourceId);
        final directBytes = await provider.coverBytes(entry);
        if (directBytes != null) {
          requireSession(epoch);
          return await saveCover(entry, Uint8List.fromList(directBytes), profile: profile);
        }
        final posterUri = _trustedOnlinePosterUri(entry.onlinePosterUrl);
        final lease = await provider.cover(entry) ?? (posterUri == null ? null : ContentLease(posterUri));
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
      p.join(
        downloads.directory.path,
        sourceDigest(owner),
        'covers',
        '${sourceDigest(jsonEncode([entry.key, entry.coverId, entry.onlinePosterUrl]))}.png',
      ),
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
    if (syncConfig != null) {
      try {
        await sync();
      } on SourceException catch (e) {
        if (e.reason == SourceFailure.cancelled || e.reason == SourceFailure.invalidData) rethrow;
      } catch (_) {
        /* Durable local progress remains usable offline. */
      }
      requireSession(epoch);
    }
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
    final defaultRoot = p.join(downloads.directory.path, sourceDigest(profile), 'imports');
    final existingSource = sources
        .where((s) => s.kind == FileSourceKind.local && s.options['imported'] == 'true')
        .firstOrNull;
    if (existingSource != null && !p.equals(existingSource.root, defaultRoot)) {
      throw const SourceException(SourceFailure.permission);
    }
    final source =
        existingSource ??
        FileSource(
          id: const Uuid().v4(),
          profileId: profile,
          kind: FileSourceKind.local,
          name: name,
          root: defaultRoot,
          options: const {'imported': 'true'},
        );
    final importable = files.where((file) => classifySourceFile(file.name) != SourceItemKind.unknown).toList();
    if (importable.isEmpty) throw const SourceException(SourceFailure.invalidData);
    final root = Directory(source.root);
    await root.create(recursive: true);
    await add(source, {});
    for (final file in importable) {
      requireSession(epoch);
      var filename = p.basename(file.name).replaceAll(RegExp(r'[\x00-\x1f]'), '');
      if (filename.isEmpty || filename == '.' || filename == '..') {
        throw const SourceException(SourceFailure.invalidData);
      }
      if (filename.startsWith('.')) filename = 'imported$filename';
      var downloadKey = sourceKey(source.id, filename);
      while (await File(p.join(root.path, filename)).exists() ||
          await File(p.join(root.path, '.$filename.partial')).exists() ||
          await repository.download(profile, downloadKey) != null ||
          _importTransfers.containsKey(downloadKey)) {
        filename =
            '${p.basenameWithoutExtension(filename)}-${const Uuid().v4().substring(0, 8)}${p.extension(filename)}';
        downloadKey = sourceKey(source.id, filename);
      }
      final partial = File(p.join(root.path, '.$filename.partial'));
      final finalCopy = File(p.join(root.path, filename));
      final input = file.readStream ?? (file.path == null ? null : File(file.path!).openRead());
      if (input == null) throw const SourceException(SourceFailure.unavailable);
      final expectedSize = file.size > 0 ? file.size : null;
      final descriptor = PublicationFile(
        id: filename,
        name: filename,
        mimeType: '',
        size: expectedSize,
        revision: 'importing:${const Uuid().v4()}',
      );
      final transfer = _ImportTransfer(source.id);
      _importTransfers[downloadKey] = transfer;
      var promoted = false;
      try {
        await repository.reserveDownload(
          profile: profile,
          key: downloadKey,
          sourceId: source.id,
          file: descriptor,
          path: partial.path,
          reservedBytes: expectedSize ?? 0,
          bytes: 0,
          state: 'importing',
          label: filename,
        );
        final iterator = StreamIterator<List<int>>(input);
        final output = await partial.open(mode: FileMode.write);
        var copiedBytes = 0;
        try {
          while (true) {
            requireSession(epoch);
            final hasNext = await Future.any<bool>([
              iterator.moveNext(),
              transfer.cancellation.aborted.then((_) => false),
            ]);
            requireSession(epoch);
            transfer.cancellation.check();
            if (!hasNext) break;
            final chunk = iterator.current;
            final nextBytes = copiedBytes + chunk.length;
            if (expectedSize != null && nextBytes > expectedSize) {
              throw const SourceException(SourceFailure.invalidData);
            }
            final releaseStorage = await downloads.reserveStorageWrite(
              profile: profile,
              transferKey: sourceKey(profile, downloadKey),
              chunkBytes: chunk.length,
              unknownSize: expectedSize == null,
            );
            try {
              requireSession(epoch);
              transfer.cancellation.check();
              await repository.reserveDownload(
                profile: profile,
                key: downloadKey,
                sourceId: source.id,
                file: descriptor,
                path: partial.path,
                reservedBytes: expectedSize ?? nextBytes,
                bytes: nextBytes,
                state: 'importing',
                label: filename,
              );
              requireSession(epoch);
              transfer.cancellation.check();
              await output.writeFrom(chunk);
              copiedBytes = nextBytes;
            } finally {
              releaseStorage();
            }
          }
          await output.flush();
        } finally {
          try {
            await iterator.cancel();
          } finally {
            await output.close();
          }
        }
        requireSession(epoch);
        transfer.cancellation.check();
        if (copiedBytes == 0 || (expectedSize != null && copiedBytes != expectedSize)) {
          throw const SourceException(SourceFailure.invalidData);
        }
        await partial.rename(finalCopy.path);
        promoted = true;
        final stat = await finalCopy.stat();
        final importedFile = PublicationFile(
          id: filename,
          name: filename,
          mimeType: '',
          size: stat.size,
          revision: '${stat.modified.microsecondsSinceEpoch}:${stat.size}',
        );
        await repository.recordDownload(
          profile,
          downloadKey,
          finalCopy.path,
          importedFile.fingerprint,
          stat.size,
          reservedBytes: stat.size,
          sourceId: source.id,
          file: importedFile,
          label: filename,
        );
      } catch (_) {
        if (await partial.exists()) await partial.delete();
        if (promoted && await finalCopy.exists()) await finalCopy.delete();
        await repository.forgetDownload(profile, downloadKey);
        rethrow;
      } finally {
        _importTransfers.remove(downloadKey);
        if (!transfer.finished.isCompleted) transfer.finished.complete();
      }
    }
    requireSession(epoch);
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
    Object? firstFailure;
    StackTrace? firstFailureStack;
    if (syncConfig != null) {
      final config = syncConfig!;
      final source = sources.where((s) => s.id == config.sourceId).firstOrNull;
      try {
        if (source == null) throw const SourceException(SourceFailure.authentication);
        await cloudSync.run(
          profile: profile,
          sources: List.of(sources),
          config: config,
          store: ProviderSyncStore(adapter(source.id), folder: config.folder, check: () => requireSession(epoch)),
          activeKeys: activeProgressKeys,
          check: () => requireSession(epoch),
        );
      } catch (error, stackTrace) {
        requireSession(epoch);
        firstFailure = error;
        firstFailureStack = stackTrace;
      } finally {
        if (current(epoch)) _notify();
      }
    }
    final entriesByKey = <String, SourceEntry?>{};
    Future<SourceEntry?> entryFor(String key) async {
      if (entriesByKey.containsKey(key)) return entriesByKey[key];
      final entry = await repository.entryByKey(profile, key);
      requireSession(epoch);
      entriesByKey[key] = entry;
      return entry;
    }

    final sourcesById = <String, FileSource>{for (final source in sources) source.id: source};
    final events = await repository.pendingEvents(profile);
    final latest = <String, Map<String, dynamic>>{};
    for (final event in events) {
      if (event['kind'] == 'annotation') continue;
      final key = event['key'];
      if (event['kind'] != 'progress' || key is! String || key.isEmpty) {
        firstFailure ??= const SourceException(SourceFailure.invalidData);
        firstFailureStack ??= StackTrace.current;
        continue;
      }
      latest[key] = event;
    }
    for (final event in latest.values) {
      requireSession(epoch);
      late PublicationProgress progress;
      try {
        progress = PublicationProgress.fromJson(sourceMap(jsonDecode(event['payload'] as String)));
      } catch (error, stackTrace) {
        firstFailure ??= error;
        firstFailureStack ??= stackTrace;
        continue;
      }
      if (onlyKey != null && progress.key != onlyKey) continue;
      final storedEntry = await entryFor(progress.entryKey);
      if (storedEntry == null) continue;
      final owner = sourcesById[storedEntry.sourceId];
      if (owner == null) continue;
      late SourceEntry entry;
      SourceAdapter? source;
      try {
        entry = _withSyncIdentity(owner, storedEntry);
        source = _stateAdapter(entry, progress);
      } catch (error, stackTrace) {
        requireSession(epoch);
        _sourceSyncFailed(owner.id);
        firstFailure ??= error;
        firstFailureStack ??= stackTrace;
        continue;
      }
      if (source == null) continue;
      try {
        if (!_sourceSyncReady(source.source.id)) continue;
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
        _sourceSyncSucceeded(source.source.id);
      } catch (error, stackTrace) {
        requireSession(epoch);
        _sourceSyncFailed(source.source.id);
        firstFailure ??= error;
        firstFailureStack ??= stackTrace;
      }
    }
    for (final event in events.where((e) => e['kind'] == 'annotation')) {
      requireSession(epoch);
      late BookAnnotation annotation;
      try {
        annotation = BookAnnotation.fromJson(sourceMap(jsonDecode(event['payload'] as String)));
      } catch (error, stackTrace) {
        firstFailure ??= error;
        firstFailureStack ??= stackTrace;
        continue;
      }
      final storedEntry = await entryFor(annotation.entryKey);
      if (storedEntry == null) continue;
      final owner = sourcesById[storedEntry.sourceId];
      if (owner == null) continue;
      late SourceEntry entry;
      late SourceAdapter? source;
      try {
        entry = _withSyncIdentity(owner, storedEntry);
        final annotationProgress = PublicationProgress(
          entryKey: annotation.entryKey,
          edition: annotation.edition,
          mode: annotation.mode,
          session: '',
        );
        source = _stateAdapter(entry, annotationProgress);
      } catch (error, stackTrace) {
        requireSession(epoch);
        _sourceSyncFailed(owner.id);
        firstFailure ??= error;
        firstFailureStack ??= stackTrace;
        continue;
      }
      if (source == null ||
          !source.capabilities.annotations ||
          (source.source.kind == FileSourceKind.audiobookshelf && annotation.mode != PublicationMode.listening)) {
        continue;
      }
      try {
        if (!_sourceSyncReady(source.source.id)) continue;
        await source.writeAnnotation(entry, annotation);
        requireSession(epoch);
        // The annotation/tombstone remains in its durable table. Only this exact
        // acknowledged event can be removed; newer edits have a different ID.
        await repository.database.customStatement('DELETE FROM events WHERE profile=? AND id=?', [
          profile,
          event['id'],
        ]);
        _sourceSyncSucceeded(source.source.id);
      } catch (error, stackTrace) {
        requireSession(epoch);
        _sourceSyncFailed(source.source.id);
        firstFailure ??= error;
        firstFailureStack ??= stackTrace;
      }
    }
    _notify();
    if (firstFailure != null) Error.throwWithStackTrace(firstFailure, firstFailureStack!);
  }

  Future<void> configureCloudSync(PublicationSyncConfig? config) async {
    await ready;
    requireSession();
    final epoch = generation, profile = profileId!;
    if (config != null) {
      SyncCipher(config.code);
      final source = sources.firstWhere((s) => s.id == config.sourceId);
      if (!ProviderSyncStore.supports(source.kind)) throw const SourceException(SourceFailure.unsupported);
      if (source.options['syncWrites'] != 'true' &&
          const {FileSourceKind.googleDrive, FileSourceKind.oneDrive, FileSourceKind.dropbox}.contains(source.kind)) {
        final writable = FileSource(
          id: source.id,
          profileId: profile,
          kind: source.kind,
          name: source.name,
          endpoint: source.endpoint,
          root: source.root,
          options: {...source.options, 'syncWrites': 'true'},
        );
        final previous = await repository.credentials(source);
        final credentials = await oauth.authorize(writable, clientSecret: previous['clientSecret']);
        requireSession(epoch);
        await add(writable, credentials);
        await reconnect(source.id);
      }
    }
    requireSession(epoch);
    // Wait for the old target's in-flight cycle before replacing its config.
    await _syncQueue;
    requireSession(epoch);
    await cloudSync.configure(profile, config);
    syncConfig = config;
    _notify();
    if (config != null) await sync();
  }

  Future<String> exportCloudSyncRecovery() async {
    await ready;
    final epoch = generation;
    requireSession(epoch);
    await _syncQueue;
    requireSession(epoch);
    return cloudSync.exportRecovery(profileId!);
  }

  Future<void> importCloudSyncRecovery(String text) async {
    await ready;
    requireSession();
    final epoch = generation, profile = profileId!;
    final activeSources = List<FileSource>.of(sources);
    final activeKeys = Set<String>.of(activeProgressKeys);
    final operation = _syncQueue.then(
      (_) => cloudSync.importRecovery(profile: profile, text: text, sources: activeSources, activeKeys: activeKeys),
    );
    _syncQueue = operation.catchError((Object _) {});
    await operation;
    requireSession(epoch);
    _notify();
    scheduleSync();
  }

  Future<void> resolveCloudConflict(String key, SyncVersion selected) {
    final operation = _syncQueue.then((_) async {
      requireSession();
      final epoch = generation, profile = profileId!, config = syncConfig;
      if (config == null) throw const SourceException(SourceFailure.cancelled);
      await cloudSync.resolve(
        profile: profile,
        config: config,
        key: key,
        selected: selected,
        sources: List.of(sources),
        activeKeys: activeProgressKeys,
        check: () => requireSession(epoch),
      );
      requireSession(epoch);
      _notify();
    });
    _syncQueue = operation.catchError((Object _) {});
    return operation.then((_) => sync());
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelImports();
    _syncTimer?.cancel();
    _syncSoon?.cancel();
    generation++;
    final stopped = stopPlayback?.call();
    for (final adapter in _adapters.values) {
      adapter.close();
    }
    _adapters.clear();
    _videoMetadata.close();
    unawaited(
      ready.then((_) async {
        oauth.dispose();
        await _settleImports();
        await downloads.settleCancelled();
        await stopped;
        await repository.database.close();
      }),
    );
    super.dispose();
  }
}

class _ImportTransfer {
  _ImportTransfer(this.sourceId);
  final String sourceId;
  final TransferCancellation cancellation = TransferCancellation();
  final Completer<void> finished = Completer<void>();
}
