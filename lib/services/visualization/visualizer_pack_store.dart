import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A pack whose archive and digest are pinned in the application binary.
/// Runtime catalog URLs are intentionally not trusted to authorize new content.
class VisualizerPackCatalogEntry {
  const VisualizerPackCatalogEntry({
    required this.id,
    required this.name,
    required this.version,
    required this.license,
    required this.description,
    required this.contentNotice,
    required this.archiveUrl,
    required this.sha256,
    required this.archiveBytes,
    required this.expandedBytes,
    required this.presetCount,
    required this.sourceUrl,
    this.searchText = '',
  });

  final String id;
  final String name;
  final String version;
  final String license;
  final String description;
  final String contentNotice;
  final String archiveUrl;
  final String sha256;
  final int archiveBytes;
  final int expandedBytes;
  final int presetCount;
  final String sourceUrl;
  final String searchText;

  String get fileName => '$id-$version.rmpack';

  static const available = <VisualizerPackCatalogEntry>[
    VisualizerPackCatalogEntry(
      id: 'milkrust-sample-pack',
      name: 'MilkRust Sample Pack',
      version: '0.1.0',
      license: 'CC0-1.0',
      description: 'Two MilkRust-authored sample presets. No third-party assets.',
      contentNotice: 'MilkRust-authored sample content dedicated under CC0-1.0. No third-party presets or textures are included.',
      archiveUrl:
          'https://raw.githubusercontent.com/snapetech-org/MilkRust/de41e50c9d04c0b7c2de03f472c71720e1e9fda0/content/downloads/milkrust-sample-pack-0.1.0.rmpack',
      sha256: '175a042deb4edb224055a6334f67a1c492f32e447dc3c90a54f22849c43a27df',
      archiveBytes: 2927,
      expandedBytes: 5467,
      presetCount: 2,
      sourceUrl:
          'https://github.com/snapetech-org/MilkRust/tree/de41e50c9d04c0b7c2de03f472c71720e1e9fda0/examples/sample-pack',
      searchText: 'Warm Scope Blue Shape scope geometry shape fixture',
    ),
  ];
}

class VisualizerInstalledPack {
  const VisualizerInstalledPack({required this.entry, required this.path});

  final VisualizerPackCatalogEntry entry;
  final String path;
  String get version => p.basename(path);
  bool get isCurrent => version == entry.version;
}

/// A resolved local file, never a remote URL or executable preset module.
class VisualizerPresetFile {
  const VisualizerPresetFile({required this.id, required this.title, required this.path,
    required this.root, required this.libraryPath, this.packName = '', this.author = '',
    this.tags = const [], this.license = '', this.notice = ''});
  final String id, title, path, root, libraryPath, packName, author, license, notice;
  final List<String> tags;
  bool get supportsProjectM => p.extension(path).toLowerCase() == '.milk';
  String get searchText => '$title $packName $author ${tags.join(' ')}'.toLowerCase();
}

class VisualizerPlaylist {
  const VisualizerPlaylist({required this.name, required this.entries});
  final String name;
  /// Portable paths relative to the device library, never absolute paths/URLs.
  final List<String> entries;
  Map<String, Object> toJson() => {'name': name, 'entries': entries};
}

/// A user-imported, locally verified community pack. Its archive is not
/// app-pinned, so every expanded file is checked against the shipped index.
class VisualizerImportedPack {
  const VisualizerImportedPack({
    required this.id,
    required this.name,
    required this.version,
    required this.license,
    required this.contentNotice,
    required this.presetCount,
    required this.path,
    this.authors = '',
    this.presetSearchText = '',
    this.isDamaged = false,
  });

  final String id;
  final String name;
  final String version;
  final String license;
  final String contentNotice;
  final int presetCount;
  final String path;
  final String authors;
  final String presetSearchText;
  final bool isDamaged;
}

class VisualizerPackInstallCancellation {
  final Completer<void> _abort = Completer<void>();

  bool get isCanceled => _abort.isCompleted;

  Future<void> get abortTrigger => _abort.future;

  void cancel() {
    if (!_abort.isCompleted) _abort.complete();
  }
}

class VisualizerPackStore {
  VisualizerPackStore({http.Client? client, this.profileId}) : _client = client ?? http.Client();

  static const maxArchiveBytes = 32 * 1024 * 1024;
  static const maxExpandedBytes = 64 * 1024 * 1024;
  static const maxFileBytes = 16 * 1024 * 1024;
  static const maxFileCount = 2500;
  static const maxPresetImportCount = 2500;
  static const maxPresetImportBatchBytes = 64 * 1024 * 1024;
  static const maxLocalPackArchiveBytes = 32 * 1024 * 1024;
  static const maxLocalPackExpandedBytes = 64 * 1024 * 1024;

  static const _redistributableLicenses = <String>{
    '0BSD',
    'Apache-2.0',
    'BSD-2-Clause',
    'BSD-3-Clause',
    'CC-BY-3.0',
    'CC-BY-4.0',
    'CC-BY-SA-3.0',
    'CC-BY-SA-4.0',
    'CC0-1.0',
    'GPL-2.0-only',
    'GPL-2.0-or-later',
    'GPL-3.0-only',
    'GPL-3.0-or-later',
    'ISC',
    'LGPL-2.1-only',
    'LGPL-2.1-or-later',
    'LGPL-3.0-only',
    'LGPL-3.0-or-later',
    'MIT',
    'Unlicense',
    'Zlib',
  };

  final http.Client _client;
  final String? profileId;
  static Future<Directory>? _rootFuture;
  static Future<void> _assetTail = Future<void>.value();
  // Serializes small preference writes across store instances. Asset install
  // work has its own staging directories and never holds this queue.
  static Future<void> _preferencesTail = Future<void>.value();

  bool get isStorageSupported => !kIsWeb;

  Future<Directory> _root() => _rootFuture ??= _createRoot().catchError((Object error) {
    _rootFuture = null;
    throw error;
  });

  Future<T> _assetOperation<T>(Future<T> Function() action) {
    final result = _assetTail.then((_) => action());
    _assetTail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<Directory> _createRoot() async {
    if (kIsWeb) {
      throw const VisualizerPackException('Preset pack storage is not available in the web build.');
    }
    final support = await getApplicationSupportDirectory();
    final root = Directory(p.join(support.path, 'visualizer'));
    await root.create(recursive: true);
    // Runs once at process startup, before any mutation can create a stage.
    // A killed download restarts cleanly; a killed replacement restores its
    // previous complete version before the installed library is enumerated.
    for (final lane in ['packs', 'community-packs']) {
      final packs = Directory(p.join(root.path, lane));
      if (!await packs.exists()) continue;
      await for (final entity in packs.list(followLinks: false)) {
        final name = p.basename(entity.path);
        if ((entity is Directory && name.startsWith('.stage-')) || (entity is File && name.endsWith('.partial'))) {
          await entity.delete(recursive: true);
        } else if (entity is Directory) {
          await for (final backup in entity.list(followLinks: false)) {
            if (backup is! Directory || !backup.path.endsWith('.previous')) continue;
            final target = backup.path.substring(0, backup.path.length - '.previous'.length);
            if (!await Directory(target).exists()) await backup.rename(target);
            else await backup.delete(recursive: true);
          }
        }
      }
    }
    final imports = Directory(p.join(root.path, 'imports'));
    if (await imports.exists()) {
      final partialName = RegExp(r'^[a-f0-9]{64}-.*\.(milk|milk2)\.partial$', caseSensitive: false);
      await for (final file in imports.list(followLinks: false)) {
        if (file is File && partialName.hasMatch(p.basename(file.path))) await file.delete();
      }
    }
    return root;
  }

  Future<File> _preferenceFile(String name) async {
    final root = await _root();
    if (profileId == null) return File(p.join(root.path, '$name.json'));
    final key = sha256.convert(utf8.encode(profileId!)).toString();
    final directory = Directory(p.join(root.path, 'profiles', key));
    await directory.create(recursive: true);
    return File(p.join(directory.path, '$name.json'));
  }

  Future<dynamic> _readPreference(String name) async {
    await _preferencesTail;
    final target = await _preferenceFile(name);
    // A crash after the old file was moved aside leaves a readable backup.
    for (final file in [target, File('${target.path}.previous')]) {
      if (!await file.exists() || await file.length() > 512 * 1024) continue;
      try { return jsonDecode(await file.readAsString()); } on Object { /* Try backup. */ }
    }
    return null;
  }

  Future<void> _savePreference(String name, Object value) {
    final encoded = jsonEncode(value); // Snapshot before entering the queue.
    if (encoded.length > 512 * 1024) throw const VisualizerPackException('Visualization preferences are too large.');
    final operation = _preferencesTail.then((_) async {
      final target = await _preferenceFile(name);
      final temporary = File('${target.path}.tmp');
      final backup = File('${target.path}.previous');
      await temporary.writeAsString(encoded, flush: true);
      if (await target.exists()) {
        if (await backup.exists()) await backup.delete();
        await target.rename(backup.path);
      }
      try { await temporary.rename(target.path); }
      on Object {
        if (!await target.exists() && await backup.exists()) await backup.rename(target.path);
        rethrow;
      }
    });
    _preferencesTail = operation.catchError((Object _) {});
    return operation;
  }

  Future<Set<String>> favoriteIds() async {
    try {
      final decoded = await _readPreference('favorites');
      if (decoded is! List) return <String>{};
      return decoded.whereType<String>().where((value) => value.length <= 512).take(2500).toSet();
    } on Object {
      return <String>{};
    }
  }

  Future<void> saveFavoriteIds(Set<String> favorites) async {
    final values = favorites.where((value) => value.length <= 512).take(2500).toList()..sort();
    await _savePreference('favorites', values);
  }

  Future<Map<String, dynamic>> preferences() async {
    final value = await _readPreference('display');
    return value is Map<String, dynamic> && value['schemaVersion'] == 1 ? value : {};
  }

  Future<void> savePreferences(Map<String, dynamic> value) =>
      _savePreference('display', {...value, 'schemaVersion': 1});

  Future<List<VisualizerPlaylist>> playlists() async {
    final value = await _readPreference('playlists');
    if (value is! Map || value['schemaVersion'] != 1 || value['playlists'] is! List) return [];
    return decodePlaylists(value);
  }

  static List<VisualizerPlaylist> decodePlaylists(Map<dynamic, dynamic> value) {
    if (value['schemaVersion'] != 1 || value['playlists'] is! List || (value['playlists'] as List).length > 100) {
      throw const VisualizerPackException('Unsupported playlist file or more than 100 playlists.');
    }
    final result = <VisualizerPlaylist>[];
    final names = <String>{};
    for (final item in value['playlists'] as List) {
      if (item is! Map || item['name'] is! String || item['entries'] is! List ||
          (item['entries'] as List).length > 2500) {
        throw const VisualizerPackException('A playlist is malformed or exceeds 2,500 entries.');
      }
      final name = (item['name'] as String).trim();
      if (name.isEmpty || name.length > 80 || !names.add(name.toLowerCase())) {
        throw const VisualizerPackException('Playlist names must be unique and at most 80 characters.');
      }
      final entries = <String>{};
      for (final path in item['entries'] as List) {
        if (path is! String || path.length > 512) throw const VisualizerPackException('Invalid playlist preset reference.');
        final safe = safeArchivePath(path);
        if (!['packs', 'community-packs', 'imports'].contains(safe.split('/').first)) {
          throw const VisualizerPackException('Playlist references must stay inside the preset library.');
        }
        entries.add(safe);
      }
      result.add(VisualizerPlaylist(name: name, entries: entries.toList()));
    }
    return result;
  }

  Future<void> savePlaylists(List<VisualizerPlaylist> playlists) {
    final data = {'schemaVersion': 1, 'playlists': playlists.map((item) => item.toJson()).toList()};
    decodePlaylists(data);
    return _savePreference('playlists', data);
  }

  Future<List<VisualizerPresetFile>> presetsForPack(String path) async {
    final library = await (await _root()).resolveSymbolicLinks();
    final root = await Directory(path).resolveSymbolicLinks();
    if (!p.isWithin(library, root)) throw const VisualizerPackException('Pack is outside the local library.');
    final manifest = await _readPackManifest(Directory(root));
    final assets = <String, Map>{};
    for (final asset in (manifest['assets'] as List? ?? const [])) {
      if (asset is Map && asset['path'] is String) assets[asset['path'] as String] = asset;
    }
    final presets = <VisualizerPresetFile>[];
    for (final item in manifest['presets'] as List) {
      if (item is! Map || item['file'] is! String) continue;
      final relative = safeArchivePath(item['file'] as String);
      final file = await _resolvePreset(root, relative);
      final asset = assets[relative];
      presets.add(VisualizerPresetFile(
        id: 'pack:${manifest['id']}@${manifest['version']}/$relative',
        title: item['title'] is String ? (item['title'] as String).substring(0, (item['title'] as String).length.clamp(0, 256).toInt()) : p.basenameWithoutExtension(relative),
        path: file, root: root, libraryPath: p.split(p.relative(file, from: library)).join('/'),
        packName: '${manifest['name']} · ${manifest['version']}',
        author: asset?['author'] is String ? asset!['author'] as String : manifest['author'] as String? ?? '',
        tags: item['tags'] is List ? (item['tags'] as List).whereType<String>().take(32).toList() : const [],
        license: asset?['license'] is String ? asset!['license'] as String : manifest['license'] as String,
        notice: manifest['contentNotice'] as String,
      ));
    }
    return presets;
  }

  Future<VisualizerPresetFile> importedPreset(String name) async {
    if (name != p.basename(name)) throw const VisualizerPackException('Invalid preset filename.');
    final library = await (await _root()).resolveSymbolicLinks();
    final root = await Directory(p.join(library, 'imports')).resolveSymbolicLinks();
    final file = await _resolvePreset(root, name);
    return VisualizerPresetFile(id: 'preset:$name',
      title: p.basenameWithoutExtension(name).replaceFirst(RegExp(r'^[a-f0-9]{12,64}-'), ''),
      path: file, root: root, libraryPath: p.split(p.relative(file, from: library)).join('/'));
  }

  Future<List<VisualizerPresetFile>> allPresets() async {
    final result = <VisualizerPresetFile>[];
    for (final pack in await installedPacks()) {
      try { result.addAll(await presetsForPack(pack.path)); } on Object { /* Damaged packs remain visible in manager. */ }
    }
    for (final pack in await importedPacks()) {
      if (pack.isDamaged) continue;
      try { result.addAll(await presetsForPack(pack.path)); } on Object { /* As above. */ }
    }
    for (final name in await importedPresets()) {
      try { result.add(await importedPreset(name)); } on Object { /* Unreadable files cannot be selected. */ }
    }
    result.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return result;
  }

  static Future<String> _resolvePreset(String root, String relative) async {
    final safe = safeArchivePath(relative);
    final file = File(p.join(root, ...safe.split('/')));
    final canonical = await file.resolveSymbolicLinks();
    if (!p.isWithin(root, canonical) || !['.milk', '.milk2'].contains(p.extension(canonical).toLowerCase()) ||
        await file.length() == 0 || await file.length() > 2 * 1024 * 1024) {
      throw const VisualizerPackException('The preset is missing, outside its pack, or exceeds 2 MB.');
    }
    return canonical;
  }

  Future<List<VisualizerInstalledPack>> installedPacks() async {
    final root = Directory(p.join((await _root()).path, 'packs'));
    if (!await root.exists()) return const [];
    final installed = <VisualizerInstalledPack>[];
    for (final entry in VisualizerPackCatalogEntry.available) {
      final versions = Directory(p.join(root.path, entry.id));
      if (!await versions.exists()) continue;
      await for (final directory in versions.list(followLinks: false)) {
        if (directory is! Directory || directory.path.endsWith('.previous')) continue;
        try {
          final manifest = await _readPackManifest(directory);
          if (manifest['id'] == entry.id && manifest['version'] == p.basename(directory.path)) {
            installed.add(VisualizerInstalledPack(entry: entry, path: directory.path));
          }
        } on Object { /* A damaged copy is not offered for playback; downloading repairs it. */ }
      }
    }
    return installed;
  }

  Future<bool> isInstalled(VisualizerPackCatalogEntry entry) async {
    final root = Directory(p.join((await _root()).path, 'packs'));
    return File(p.join(root.path, entry.id, entry.version, 'manifest.json')).exists();
  }

  Future<List<VisualizerImportedPack>> importedPacks() async {
    final root = Directory(p.join((await _root()).path, 'community-packs'));
    if (!await root.exists()) return const [];
    final packs = <VisualizerImportedPack>[];
    await for (final idDirectory in root.list(followLinks: false)) {
      if (idDirectory is! Directory || p.basename(idDirectory.path).startsWith('.stage-')) continue;
      await for (final versionDirectory in idDirectory.list(followLinks: false)) {
        if (versionDirectory is! Directory || p.basename(versionDirectory.path).endsWith('.previous')) continue;
        try {
          final manifest = await _readPackManifest(versionDirectory);
          packs.add(_packSummary(manifest, versionDirectory.path));
        } on Object {
          final id = p.basename(idDirectory.path);
          final version = p.basename(versionDirectory.path);
          if (_isSafePackIdentifier(id) && _isSafePackIdentifier(version)) {
            packs.add(VisualizerImportedPack(
              id: id,
              name: 'Damaged community pack',
              version: version,
              license: 'Unknown',
              contentNotice: 'Pack metadata is unavailable. Remove this damaged local copy.',
              presetCount: 0,
              path: versionDirectory.path,
              isDamaged: true,
            ));
          }
        }
      }
    }
    packs.sort((a, b) {
      final nameOrder = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return nameOrder != 0 ? nameOrder : a.version.compareTo(b.version);
    });
    return packs;
  }

  Future<VisualizerImportedPack> importPackFile(String sourcePath, int announcedSize) =>
      _assetOperation(() => _importPackFile(sourcePath, announcedSize));

  Future<VisualizerImportedPack> _importPackFile(String sourcePath, int announcedSize) async {
    if (announcedSize <= 0 || announcedSize > maxLocalPackArchiveBytes) {
      throw const VisualizerPackException('Community pack archives must be 32 MB or smaller.');
    }
    final archive = File(sourcePath);
    if (await archive.length() != announcedSize) {
      throw const VisualizerPackException('The selected pack changed while it was being imported.');
    }
    final root = await _root();
    final packsRoot = Directory(p.join(root.path, 'community-packs'));
    await packsRoot.create(recursive: true);
    final stage = Directory(p.join(packsRoot.path, '.stage-${DateTime.now().microsecondsSinceEpoch}'));
    final snapshot = File('${stage.path}.partial');

    try {
      // Copy a bounded snapshot first. The file picker source can be replaced
      // or grow while open; parsing never races it in another isolate.
      final sink = snapshot.openWrite();
      var copied = 0;
      try {
        await for (final chunk in archive.openRead(0, maxLocalPackArchiveBytes + 1)) {
          copied += chunk.length;
          if (copied > announcedSize) throw const VisualizerPackException('The selected pack changed during import.');
          sink.add(chunk);
        }
        await sink.flush();
      } finally { await sink.close(); }
      if (copied != announcedSize) throw const VisualizerPackException('The selected pack changed during import.');
      await stage.create(recursive: true);
      final extracted = await Isolate.run(() => _extractArchive(snapshot.path, stage.path));
      final expandedBytes = extracted.values.fold<int>(0, (sum, size) => sum + size);
      if (expandedBytes > maxLocalPackExpandedBytes) {
        throw const VisualizerPackException('The expanded community pack exceeds its 64 MB limit.');
      }
      final summary = await _validatePack(stage, extracted);
      final target = Directory(p.join(packsRoot.path, summary.id, summary.version));
      final backup = Directory('${target.path}.previous');
      await target.parent.create(recursive: true);
      if (await backup.exists()) await backup.delete(recursive: true);
      if (await target.exists()) await target.rename(backup.path);
      try {
        await stage.rename(target.path);
        if (await backup.exists()) {
          try {
            await backup.delete(recursive: true);
          } on Object {
            // The new pack is committed; a stale backup can be cleaned up on
            // the next import without reporting the successful install as failed.
          }
        }
      } catch (_) {
        if (await backup.exists() && !await target.exists()) await backup.rename(target.path);
        rethrow;
      }
      return VisualizerImportedPack(
        id: summary.id,
        name: summary.name,
        version: summary.version,
        license: summary.license,
        contentNotice: summary.contentNotice,
        presetCount: summary.presetCount,
        path: target.path,
        isDamaged: false,
      );
    } catch (_) {
      if (await stage.exists()) await stage.delete(recursive: true);
      rethrow;
    } finally {
      if (await snapshot.exists()) await snapshot.delete();
    }
  }

  Future<void> removeImportedPack(VisualizerImportedPack pack) =>
      _assetOperation(() => _removeImportedPack(pack));

  Future<void> _removeImportedPack(VisualizerImportedPack pack) async {
    if (!_isSafePackIdentifier(pack.id) || !_isSafePackIdentifier(pack.version)) {
      throw const VisualizerPackException('The local pack identity is invalid.');
    }
    final root = Directory(p.join((await _root()).path, 'community-packs'));
    final target = Directory(p.join(root.path, pack.id, pack.version));
    if (!p.isWithin(root.path, target.path)) {
      throw const VisualizerPackException('The local pack path is invalid.');
    }
    if (await target.exists()) await target.delete(recursive: true);
    final parent = target.parent;
    if (await parent.exists() && await parent.list().isEmpty) await parent.delete();
  }

  Future<void> install(
    VisualizerPackCatalogEntry entry, {
    VisualizerPackInstallCancellation? cancellation,
    void Function(double progress)? onProgress,
  }) => _assetOperation(() => _install(entry, cancellation: cancellation, onProgress: onProgress));

  Future<void> _install(
    VisualizerPackCatalogEntry entry, {
    VisualizerPackInstallCancellation? cancellation,
    void Function(double progress)? onProgress,
  }) async {
    void checkCancellation() {
      if (cancellation?.isCanceled ?? false) throw const VisualizerPackCanceledException();
    }
    checkCancellation();
    final requestAbort = VisualizerPackInstallCancellation();
    final root = await _root();
    final packsRoot = Directory(p.join(root.path, 'packs'));
    await packsRoot.create(recursive: true);
    final download = File(p.join(packsRoot.path, '${entry.fileName}.partial'));
    final stage = Directory(p.join(packsRoot.path, '.stage-${entry.id}-${entry.version}'));
    final target = Directory(p.join(packsRoot.path, entry.id, entry.version));
    final backup = Directory('${target.path}.previous');
    if (await download.exists()) await download.delete();
    if (await stage.exists()) await stage.delete(recursive: true);

    try {
      final uri = Uri.parse(entry.archiveUrl);
      if (uri.scheme != 'https' || uri.host != 'raw.githubusercontent.com') {
        throw const VisualizerPackException('The pack catalog contains an untrusted download host.');
      }
      final request = http.AbortableRequest('GET', uri, abortTrigger: cancellation == null
          ? requestAbort.abortTrigger : Future.any([requestAbort.abortTrigger, cancellation.abortTrigger]));
      request.followRedirects = false; // The app pins the origin as well as the digest.
      final response = await _client.send(request).timeout(const Duration(seconds: 30));
      if (response.statusCode != HttpStatus.ok) {
        throw VisualizerPackException('Pack download failed with HTTP ${response.statusCode}.');
      }
      final announcedLength = response.contentLength;
      if (announcedLength != null &&
          (announcedLength != entry.archiveBytes || announcedLength > maxArchiveBytes)) {
        throw const VisualizerPackException('The downloaded pack size does not match its catalog entry.');
      }
      final sink = download.openWrite();
      var received = 0;
      try {
        await for (final chunk in response.stream.timeout(const Duration(seconds: 30))) {
          checkCancellation();
          received += chunk.length;
          if (received > maxArchiveBytes || received > entry.archiveBytes) {
            throw const VisualizerPackException('The pack archive exceeds its size limit.');
          }
          sink.add(chunk);
          if (entry.archiveBytes > 0) onProgress?.call(received / entry.archiveBytes);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      if (received != entry.archiveBytes) {
        throw const VisualizerPackException('The downloaded pack is incomplete.');
      }
      final digest = await sha256.bind(download.openRead()).first;
      checkCancellation();
      if (digest.toString() != entry.sha256) {
        throw const VisualizerPackException('The pack checksum does not match the pinned catalog.');
      }

      await stage.create(recursive: true);
      final extracted = await Isolate.run(() => _extractArchive(download.path, stage.path));
      checkCancellation();
      if (extracted.values.fold<int>(0, (sum, size) => sum + size) != entry.expandedBytes) {
        throw const VisualizerPackException('The expanded pack size does not match its pinned catalog.');
      }
      await _validatePack(stage, extracted, expectedEntry: entry);
      checkCancellation();

      await target.parent.create(recursive: true);
      if (await backup.exists()) await backup.delete(recursive: true);
      if (await target.exists()) await target.rename(backup.path);
      try {
        await stage.rename(target.path);
        if (await backup.exists()) {
          try { await backup.delete(recursive: true); } on Object { /* Clean up on next startup. */ }
        }
      } catch (_) {
        if (await backup.exists() && !await target.exists()) await backup.rename(target.path);
        rethrow;
      }
      onProgress?.call(1);
    } catch (error) {
      if (await stage.exists()) await stage.delete(recursive: true);
      if (error is http.RequestAbortedException) throw const VisualizerPackCanceledException();
      rethrow;
    } finally {
      requestAbort.cancel();
      if (await download.exists()) await download.delete();
    }
  }

  Future<void> remove(VisualizerPackCatalogEntry entry) => _assetOperation(() => _remove(entry));

  Future<void> _remove(VisualizerPackCatalogEntry entry) async {
    final root = Directory(p.join((await _root()).path, 'packs', entry.id));
    if (await root.exists()) await root.delete(recursive: true);
  }

  Future<List<String>> importedPresets() async {
    final root = Directory(p.join((await _root()).path, 'imports'));
    if (!await root.exists()) return const [];
    return root
        .list(followLinks: false)
        .where((entity) =>
            entity is File &&
            (entity.path.toLowerCase().endsWith('.milk') || entity.path.toLowerCase().endsWith('.milk2')))
        .map((entity) => p.basename(entity.path))
        .toList();
  }

  Future<String> importPreset(String name, List<int> bytes) => _assetOperation(() => _importPreset(name, bytes));

  Future<String> _importPreset(String name, List<int> bytes) async {
    if (bytes.isEmpty || bytes.length > 1024 * 1024) {
      throw const VisualizerPackException('Preset files must be smaller than 1 MB.');
    }
    final extension = p.extension(name).toLowerCase();
    if (extension != '.milk' && extension != '.milk2') {
      throw const VisualizerPackException('Choose a .milk or .milk2 preset file.');
    }
    final safeName = p.basename(name).replaceAll(RegExp(r'[^A-Za-z0-9._ -]'), '_');
    if (safeName == '.' || safeName == '..' || safeName.isEmpty) {
      throw const VisualizerPackException('The preset filename is not valid.');
    }
    final digest = sha256.convert(bytes).toString();
    final root = Directory(p.join((await _root()).path, 'imports'));
    await root.create(recursive: true);
    final shortName = safeName.length > 160 ? '${safeName.substring(0, 150)}$extension' : safeName;
    final target = File(p.join(root.path, '$digest-$shortName'));
    final stage = File('${target.path}.partial');
    await stage.writeAsBytes(bytes, flush: true);
    await stage.rename(target.path);
    return target.path;
  }

  Future<String> importPresetFile(String name, String sourcePath, int announcedSize) async {
    if (announcedSize < 0 || announcedSize > 1024 * 1024) {
      throw const VisualizerPackException('Preset files must be smaller than 1 MB.');
    }
    final bytes = await File(sourcePath).openRead(0, 1024 * 1024 + 1)
        .fold<List<int>>(<int>[], (buffer, chunk) => buffer..addAll(chunk));
    if (bytes.length != announcedSize) {
      throw const VisualizerPackException('The selected preset changed while it was being imported.');
    }
    return importPreset(name, bytes);
  }

  Future<void> removeImportedPreset(String name) => _assetOperation(() => _removeImportedPreset(name));

  Future<void> _removeImportedPreset(String name) async {
    if (name != p.basename(name) ||
        (!name.toLowerCase().endsWith('.milk') && !name.toLowerCase().endsWith('.milk2'))) {
      throw const VisualizerPackException('The local preset name is invalid.');
    }
    final root = Directory(p.join((await _root()).path, 'imports'));
    final file = File(p.join(root.path, name));
    if (await file.exists()) await file.delete();
  }

  void dispose() => _client.close();

  static String safeArchivePath(String value) {
    if (value.isEmpty ||
        value.startsWith('/') ||
        value.contains('\\') ||
        value.contains(':') ||
        value.contains('\x00') ||
        value.split('/').any((part) => part == '..' || part == '.')) {
      throw const VisualizerPackException('The pack contains an unsafe file path.');
    }
    return value;
  }

  static Map<String, int> _extractArchive(String archivePath, String destination) {
    if (File(archivePath).lengthSync() > maxArchiveBytes) {
      throw const VisualizerPackException('The pack archive exceeds its size limit.');
    }
    final input = InputFileStream(archivePath);
    try {
      final centralDirectory = ZipDirectory()..read(input);
      if (centralDirectory.fileHeaders.isEmpty || centralDirectory.fileHeaders.length > maxFileCount) {
        throw const VisualizerPackException('The pack file count is outside the allowed limit.');
      }
      var declaredTotal = 0;
      final seenPaths = <String>{};
      for (final header in centralDirectory.fileHeaders) {
        final file = header.file!;
        final name = safeArchivePath(file.filename);
        final normalizedHeaderName = safeArchivePath(header.filename);
        final folded = name.toLowerCase();
        if (name != normalizedHeaderName ||
            !seenPaths.add(folded) ||
            file.uncompressedSize < 0 ||
            file.uncompressedSize > maxFileBytes ||
            ((header.externalFileAttributes >> 16) & 0xf000) == 0xa000) {
          throw const VisualizerPackException('The pack contains a duplicate, oversized, or linked file.');
        }
        declaredTotal += file.uncompressedSize;
        if (declaredTotal > maxExpandedBytes) {
          throw const VisualizerPackException('The expanded pack exceeds its size limit.');
        }
      }
      final archive = ZipDecoder().decodeStream(input);
      final files = <String, int>{};
      for (final entry in archive) {
        if (!entry.isFile) continue;
        final name = safeArchivePath(entry.name);
        if (entry.isSymbolicLink || entry.size < 0 || entry.size > maxFileBytes) {
          throw const VisualizerPackException('The pack contains a link or oversized file.');
        }
        final outputFile = File(p.joinAll([destination, ...name.split('/')]));
        outputFile.parent.createSync(recursive: true);
        final output = OutputFileStream(outputFile.path);
        final bounded = _BoundedPackOutput(output, entry.size);
        try {
          entry.writeContent(bounded);
          if (bounded.length != entry.size) {
            throw const VisualizerPackException('The pack contains a truncated file.');
          }
        } finally {
          bounded.closeSync();
        }
        files[name] = entry.size;
      }
      if (files.length > maxFileCount || !files.containsKey('manifest.json')) {
        throw const VisualizerPackException('The pack is missing its manifest or exceeds its file limit.');
      }
      return files;
    } finally {
      input.close();
    }
  }

  static Future<VisualizerImportedPack> _validatePack(
    Directory directory,
    Map<String, int> archiveFiles, {
    VisualizerPackCatalogEntry? expectedEntry,
  }) async {
    final parsed = await _readPackManifest(directory);
    final id = parsed['id'] as String;
    final version = parsed['version'] as String;
    final license = parsed['license'] as String;
    if (!_redistributableLicenses.contains(license) || parsed['distributionStatus'] != 'redistributable') {
      throw const VisualizerPackException('The pack does not declare an approved redistributable license.');
    }
    if (expectedEntry != null &&
        (id != expectedEntry.id || version != expectedEntry.version || license != expectedEntry.license)) {
      throw const VisualizerPackException('The pack manifest does not match its pinned catalog entry.');
    }
    final integrityFile = File(p.join(directory.path, 'integrity.json'));
    final dynamic integrity;
    try {
      integrity = jsonDecode(await integrityFile.readAsString());
    } on Object {
      throw const VisualizerPackException('The pack integrity index is missing or unreadable.');
    }
    if (integrity is! Map<String, dynamic> ||
        integrity['schemaVersion'] != 1 ||
        integrity['packId'] != id ||
        integrity['packVersion'] != version ||
        integrity['files'] is! List) {
      throw const VisualizerPackException('The pack integrity index is malformed.');
    }
    final listedFiles = <String>{};
    var indexedBytes = 0;
    for (final record in integrity['files'] as List) {
      if (record is! Map<String, dynamic> ||
          record['path'] is! String ||
          record['sha256'] is! String ||
          record['size'] is! int) {
        throw const VisualizerPackException('A pack integrity record is malformed.');
      }
      final relative = safeArchivePath(record['path'] as String);
      if (!listedFiles.add(relative)) throw const VisualizerPackException('The pack integrity index has duplicates.');
      final size = record['size'] as int;
      final expectedDigest = record['sha256'] as String;
      if (size < 0 || size > maxFileBytes || !RegExp(r'^[a-f0-9]{64}$').hasMatch(expectedDigest)) {
        throw const VisualizerPackException('A pack integrity record is outside the allowed limits.');
      }
      indexedBytes += size;
      final file = File(p.join(directory.path, ...relative.split('/')));
      if (!await file.exists() || await file.length() != size) {
        throw const VisualizerPackException('A pack file does not match its integrity index.');
      }
      final digest = await sha256.bind(file.openRead()).first;
      if (digest.toString() != expectedDigest) {
        throw const VisualizerPackException('A pack file checksum does not match its integrity index.');
      }
    }
    final indexedArchivePaths = {...listedFiles, 'integrity.json'};
    if (!listedFiles.contains('manifest.json') ||
        listedFiles.contains('integrity.json') ||
        integrity['contentBytes'] != indexedBytes ||
        archiveFiles.length != indexedArchivePaths.length ||
        !archiveFiles.keys.toSet().containsAll(indexedArchivePaths) ||
        indexedBytes + (archiveFiles['integrity.json'] ?? maxLocalPackExpandedBytes) > maxLocalPackExpandedBytes) {
      throw const VisualizerPackException('The pack integrity index omits the manifest or has the wrong total size.');
    }
    if (archiveFiles.keys.toSet().difference(indexedArchivePaths).isNotEmpty) {
      throw const VisualizerPackException('The archive contains files outside its integrity index.');
    }
    final licenseFiles = parsed['licenseFiles'];
    if (licenseFiles is! List || licenseFiles.isEmpty) {
      throw const VisualizerPackException('The pack does not include its license notice.');
    }
    final licensePaths = <String>{};
    for (final rawPath in licenseFiles) {
      if (rawPath is! String) throw const VisualizerPackException('The license notice path is invalid.');
      final relative = safeArchivePath(rawPath);
      if (!licensePaths.add(relative)) {
        throw const VisualizerPackException('The pack repeats a license notice path.');
      }
      if (!listedFiles.contains(relative)) {
        throw const VisualizerPackException('The pack integrity index omits its license notice.');
      }
      final notice = File(p.join(directory.path, ...relative.split('/')));
      if (!await notice.exists() || await notice.length() == 0) {
        throw const VisualizerPackException('The pack is missing its license notice.');
      }
    }
    final contentNotice = parsed['contentNotice'];
    final sourceUrls = parsed['sourceUrls'];
    if (contentNotice is! String || contentNotice.trim().isEmpty || sourceUrls is! List || sourceUrls.isEmpty) {
      throw const VisualizerPackException('The pack is missing its content notice or source provenance.');
    }
    for (final value in sourceUrls) {
      if (value is! String) throw const VisualizerPackException('A pack source URL is invalid.');
      final uri = Uri.tryParse(value);
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        throw const VisualizerPackException('Pack source URLs must use HTTPS.');
      }
    }
    final assets = parsed['assets'];
    if (assets is! List || assets.isEmpty) {
      throw const VisualizerPackException('The pack does not include per-asset attribution.');
    }
    final assetPaths = <String>{};
    for (final asset in assets) {
      if (asset is! Map<String, dynamic> ||
          asset['path'] is! String ||
          asset['kind'] is! String ||
          asset['license'] is! String ||
          asset['author'] is! String ||
          asset['sourceUrl'] is! String ||
          asset['licenseFile'] is! String) {
        throw const VisualizerPackException('A pack asset attribution record is malformed.');
      }
      final relative = safeArchivePath(asset['path'] as String);
      if (!assetPaths.add(relative) || !listedFiles.contains(relative) || licensePaths.contains(relative)) {
        throw const VisualizerPackException('A pack asset path is duplicated or missing from the integrity index.');
      }
      for (final field in ['kind', 'license', 'author']) {
        if ((asset[field] as String).trim().isEmpty) {
          throw const VisualizerPackException('A pack asset attribution field is empty.');
        }
      }
      if (!_redistributableLicenses.contains(asset['license'] as String)) {
        throw const VisualizerPackException('An asset uses a license that is not approved for redistribution.');
      }
      final sourceUri = Uri.tryParse(asset['sourceUrl'] as String);
      if (sourceUri == null || sourceUri.scheme != 'https' || sourceUri.host.isEmpty) {
        throw const VisualizerPackException('Pack asset source URLs must use HTTPS.');
      }
      final noticePath = safeArchivePath(asset['licenseFile'] as String);
      if (!licensePaths.contains(noticePath)) {
        throw const VisualizerPackException('A pack asset does not reference a shipped license notice.');
      }
    }
    final expectedAssets = listedFiles.where((path) => path != 'manifest.json' && !licensePaths.contains(path)).toSet();
    if (assetPaths.length != expectedAssets.length || !assetPaths.containsAll(expectedAssets)) {
      throw const VisualizerPackException('The pack attribution list does not cover every content file.');
    }
    final presets = parsed['presets'];
    if (presets is! List || presets.isEmpty ||
        (expectedEntry != null && presets.length != expectedEntry.presetCount)) {
      throw const VisualizerPackException('The preset list is empty or does not match the catalog.');
    }
    final presetPaths = <String>{};
    for (final preset in presets) {
      if (preset is! Map<String, dynamic> || preset['file'] is! String) {
        throw const VisualizerPackException('A preset entry is malformed.');
      }
      final relative = safeArchivePath(preset['file'] as String);
      if (!presetPaths.add(relative) ||
          !assetPaths.contains(relative) ||
          !['.milk', '.milk2'].contains(p.extension(relative).toLowerCase()) ||
          !await File(p.join(directory.path, ...relative.split('/'))).exists()) {
        throw const VisualizerPackException('The pack is missing a preset file.');
      }
    }
    return _packSummary(parsed, directory.path);
  }

  static Future<Map<String, dynamic>> _readPackManifest(Directory directory) async {
    final dynamic parsed;
    try {
      final file = File(p.join(directory.path, 'manifest.json'));
      if (await file.length() > maxFileBytes) throw const FormatException('Manifest exceeds its size limit.');
      parsed = jsonDecode(await file.readAsString());
    } on Object {
      throw const VisualizerPackException('The pack manifest is unreadable.');
    }
    if (parsed is! Map<String, dynamic> ||
        parsed['schemaVersion'] != 1 ||
        parsed['id'] is! String ||
        !_isSafePackIdentifier(parsed['id'] as String) ||
        parsed['version'] is! String ||
        !_isSafePackIdentifier(parsed['version'] as String) ||
        parsed['name'] is! String ||
        (parsed['name'] as String).trim().isEmpty ||
        (parsed['name'] as String).length > 160 ||
        parsed['license'] is! String ||
        parsed['contentNotice'] is! String ||
        (parsed['contentNotice'] as String).trim().isEmpty ||
        (parsed['contentNotice'] as String).length > 2048 ||
        parsed['presets'] is! List ||
        (parsed['presets'] as List).isEmpty ||
        (parsed['presets'] as List).length > maxFileCount) {
      throw const VisualizerPackException('The pack manifest is malformed.');
    }
    return parsed;
  }

  static VisualizerImportedPack _packSummary(Map<String, dynamic> manifest, String path) {
    final authors = <String>{};
    final packAuthor = manifest['author'];
    if (packAuthor is String && packAuthor.trim().isNotEmpty) authors.add(packAuthor.trim());
    final presetSearchTerms = <String>{};
    final presets = manifest['presets'];
    if (presets is List) {
      for (final preset in presets) {
        if (preset is Map) {
          for (final key in ['title', 'id']) {
            final value = preset[key];
            if (value is String && value.trim().isNotEmpty) presetSearchTerms.add(value.trim());
          }
          final tags = preset['tags'];
          if (tags is List) {
            presetSearchTerms.addAll(tags.whereType<String>().where((tag) => tag.trim().isNotEmpty));
          }
        }
      }
    }
    final assets = manifest['assets'];
    if (assets is List) {
      for (final asset in assets) {
        if (asset is Map) {
          final author = asset['author'];
          if (author is String && author.trim().isNotEmpty) authors.add(author.trim());
        }
      }
    }
    return VisualizerImportedPack(
      id: manifest['id'] as String,
      name: manifest['name'] as String,
      version: manifest['version'] as String,
      license: manifest['license'] as String,
      contentNotice: manifest['contentNotice'] as String,
      presetCount: (manifest['presets'] as List).length,
      path: path,
      authors: authors.join(', '),
      presetSearchText: presetSearchTerms.join(' '),
    );
  }

  static bool _isSafePackIdentifier(String value) =>
      value != '.' && value != '..' && RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,79}$').hasMatch(value);
}

class _BoundedPackOutput extends OutputStream {
  _BoundedPackOutput(this.output, this.limit) : super(byteOrder: ByteOrder.littleEndian);

  final OutputFileStream output;
  final int limit;

  @override
  int get length => output.length;

  @override
  void writeByte(int value) {
    if (length + 1 > limit) throw const VisualizerPackException('A pack file expanded past its declared size.');
    output.writeByte(value);
  }

  @override
  void closeSync() => output.closeSync();
}

class VisualizerPackException implements Exception {
  const VisualizerPackException(this.message);

  final String message;

  @override
  String toString() => message;
}

class VisualizerPackCanceledException implements Exception {
  const VisualizerPackCanceledException();
}
