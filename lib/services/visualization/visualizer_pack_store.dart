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
    ),
  ];
}

class VisualizerInstalledPack {
  const VisualizerInstalledPack({required this.entry, required this.path});

  final VisualizerPackCatalogEntry entry;
  final String path;
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
  VisualizerPackStore({http.Client? client}) : _client = client ?? http.Client();

  static const maxArchiveBytes = 32 * 1024 * 1024;
  static const maxExpandedBytes = 64 * 1024 * 1024;
  static const maxFileBytes = 16 * 1024 * 1024;
  static const maxFileCount = 2500;

  final http.Client _client;
  Future<Directory>? _rootFuture;

  bool get isStorageSupported => !kIsWeb;

  Future<Directory> _root() => _rootFuture ??= _createRoot();

  Future<Directory> _createRoot() async {
    if (kIsWeb) {
      throw const VisualizerPackException('Preset pack storage is not available in the web build.');
    }
    final support = await getApplicationSupportDirectory();
    final root = Directory(p.join(support.path, 'visualizer'));
    await root.create(recursive: true);
    return root;
  }

  Future<List<VisualizerInstalledPack>> installedPacks() async {
    final root = Directory(p.join((await _root()).path, 'packs'));
    if (!await root.exists()) return const [];
    final installed = <VisualizerInstalledPack>[];
    for (final entry in VisualizerPackCatalogEntry.available) {
      final directory = Directory(p.join(root.path, entry.id, entry.version));
      if (await directory.exists() && await File(p.join(directory.path, 'manifest.json')).exists()) {
        installed.add(VisualizerInstalledPack(entry: entry, path: directory.path));
      }
    }
    return installed;
  }

  Future<bool> isInstalled(VisualizerPackCatalogEntry entry) async {
    final root = Directory(p.join((await _root()).path, 'packs'));
    return File(p.join(root.path, entry.id, entry.version, 'manifest.json')).exists();
  }

  Future<void> install(
    VisualizerPackCatalogEntry entry, {
    VisualizerPackInstallCancellation? cancellation,
    void Function(double progress)? onProgress,
  }) async {
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
      final request = http.AbortableRequest('GET', uri, abortTrigger: cancellation?.abortTrigger);
      final response = await _client.send(request);
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
        await for (final chunk in response.stream) {
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
      if (digest.toString() != entry.sha256) {
        throw const VisualizerPackException('The pack checksum does not match the pinned catalog.');
      }

      await stage.create(recursive: true);
      final extracted = await Isolate.run(() => _extractArchive(download.path, stage.path));
      if (extracted.values.fold<int>(0, (sum, size) => sum + size) != entry.expandedBytes) {
        throw const VisualizerPackException('The expanded pack size does not match its pinned catalog.');
      }
      await _validateInstalledPack(stage, entry);

      await target.parent.create(recursive: true);
      if (await backup.exists()) await backup.delete(recursive: true);
      if (await target.exists()) await target.rename(backup.path);
      try {
        await stage.rename(target.path);
        if (await backup.exists()) await backup.delete(recursive: true);
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
      if (await download.exists()) await download.delete();
    }
  }

  Future<void> remove(VisualizerPackCatalogEntry entry) async {
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

  Future<String> importPreset(String name, List<int> bytes) async {
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
    final digest = sha256.convert(bytes).toString().substring(0, 12);
    final root = Directory(p.join((await _root()).path, 'imports'));
    await root.create(recursive: true);
    final target = File(p.join(root.path, '$digest-$safeName'));
    await target.writeAsBytes(bytes, flush: true);
    return target.path;
  }

  Future<String> importPresetFile(String name, String sourcePath, int announcedSize) async {
    if (announcedSize < 0 || announcedSize > 1024 * 1024) {
      throw const VisualizerPackException('Preset files must be smaller than 1 MB.');
    }
    final bytes = await File(sourcePath).readAsBytes();
    if (bytes.length != announcedSize) {
      throw const VisualizerPackException('The selected preset changed while it was being imported.');
    }
    return importPreset(name, bytes);
  }

  Future<void> removeImportedPreset(String name) async {
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

  static Future<void> _validateInstalledPack(Directory directory, VisualizerPackCatalogEntry entry) async {
    final manifestFile = File(p.join(directory.path, 'manifest.json'));
    final dynamic parsed;
    try {
      parsed = jsonDecode(await manifestFile.readAsString());
    } on Object {
      throw const VisualizerPackException('The pack manifest is unreadable.');
    }
    if (parsed is! Map<String, dynamic> ||
        parsed['schemaVersion'] != 1 ||
        parsed['id'] != entry.id ||
        parsed['version'] != entry.version ||
        parsed['license'] != entry.license ||
        parsed['distributionStatus'] != 'redistributable') {
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
        integrity['packId'] != entry.id ||
        integrity['packVersion'] != entry.version ||
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
      indexedBytes += record['size'] as int;
      final file = File(p.join(directory.path, ...relative.split('/')));
      if (!await file.exists() || await file.length() != record['size']) {
        throw const VisualizerPackException('A pack file does not match its integrity index.');
      }
      final digest = await sha256.bind(file.openRead()).first;
      if (digest.toString() != record['sha256']) {
        throw const VisualizerPackException('A pack file checksum does not match its integrity index.');
      }
    }
    if (!listedFiles.contains('manifest.json') || integrity['contentBytes'] != indexedBytes) {
      throw const VisualizerPackException('The pack integrity index omits the manifest or has the wrong total size.');
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
    if (presets is! List || presets.length != entry.presetCount) {
      throw const VisualizerPackException('The preset list does not match the catalog.');
    }
    for (final preset in presets) {
      if (preset is! Map<String, dynamic> || preset['file'] is! String) {
        throw const VisualizerPackException('A preset entry is malformed.');
      }
      final relative = safeArchivePath(preset['file'] as String);
      if (!assetPaths.contains(relative) || !await File(p.join(directory.path, ...relative.split('/'))).exists()) {
        throw const VisualizerPackException('The pack is missing a preset file.');
      }
    }
  }
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
