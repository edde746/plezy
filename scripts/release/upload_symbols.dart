import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

import 'symbol_cli.dart';

const symbolBatchObjects = 8;
const symbolBatchBytes = 256 * 1024 * 1024;
// sentry-cli 2.58.6's per-object limit (DEFAULT_MAX_DIF_SIZE), which is also
// the chunk-upload maxFileSize the tracker advertises by default.
const symbolObjectBytes = 2 * 1024 * 1024 * 1024;

typedef SymbolCommand = Future<ProcessResult> Function(List<String> arguments);
typedef SymbolDownload = Future<void> Function(Uri url, File destination);

class SymbolFailure implements Exception {
  SymbolFailure(this.message, [this.code = 1]);
  final String message;
  final int code;
  @override
  String toString() => message;
}

String _arch(String value) => switch (value) {
  'aarch64' || 'arm64e' => 'arm64',
  'armv7' || 'armv7s' => 'arm',
  'amd64' || 'x64' => 'x86_64',
  'i386' || 'i686' => 'x86',
  _ => value,
};

class SymbolVariant {
  SymbolVariant(this.debugId, this.arch, this.codeId);
  final String debugId;
  final String arch;
  final String? codeId;
  String get identity => '$debugId/$arch';
  Map<String, Object?> toJson() => {'debug_id': debugId, 'arch': arch, 'code_id': codeId};
}

class SymbolArtifact {
  SymbolArtifact(this.file, this.type, this.variants, this.features, this.provenance, {this.dart = false});
  final File file;
  final String type;
  final List<SymbolVariant> variants;
  final Set<String> features;
  final int provenance;
  final bool dart;
  int get quality =>
      (features.contains('debug') ? 8 : 0) +
      (features.contains('symtab') ? 4 : 0) +
      (features.contains('unwind') ? 2 : 0) +
      (features.contains('sources') ? 1 : 0);
  // Count every fat-object slice. Charging the whole file for each slice also
  // bounds expansion conservatively without relying on compressed wire sizes.
  int get bytes => file.lengthSync() * variants.length;
  Iterable<String> get keys => variants.map((v) => '${v.identity}/${dart ? 'dart' : type}');
  Map<String, Object?> toJson() => {
    'path': file.path,
    'class': dart ? 'dart' : type,
    'variants': variants.map((v) => v.toJson()).toList(),
    'features': features.toList()..sort(),
    'objects': variants.length,
    'byte_bound': bytes,
  };
}

List<SymbolArtifact> selectSymbolArtifacts(Iterable<SymbolArtifact> candidates) {
  final sorted = candidates.toList()
    ..sort((a, b) {
      var order = b.quality.compareTo(a.quality);
      if (order == 0) order = b.provenance.compareTo(a.provenance);
      return order == 0 ? a.file.path.compareTo(b.file.path) : order;
    });
  final claimed = <String>{};
  final selected = <SymbolArtifact>[];
  for (final candidate in sorted) {
    final keys = candidate.keys.toSet();
    if (keys.every(claimed.contains)) continue;
    if (keys.any(claimed.contains)) {
      throw SymbolFailure('Partially overlapping fat objects require a matching thin dSYM: ${candidate.file.path}');
    }
    claimed.addAll(keys);
    selected.add(candidate);
  }
  return selected..sort((a, b) => a.keys.first.compareTo(b.keys.first));
}

// The CLI sends every object in 8 MiB chunks, so an artifact larger than a
// batch still uploads, in a batch of its own: Flutter 3.47.1's macOS engine
// dSYM (~505 MB, two slices) and mpv-build's libmpv-2.pdb (~370 MB) do. Only
// an object beyond the per-object limit cannot. Dropping it costs
// symbolication for that one binary; failing the run costs every artifact and
// the release that carries them. No slice of a fat file exceeds the file.
List<SymbolArtifact> withinUploadCapacity(
  List<SymbolArtifact> artifacts, {
  int maxObjects = symbolBatchObjects,
  int maxObjectBytes = symbolObjectBytes,
  StringSink? warnings,
}) {
  return artifacts.where((artifact) {
    final size = artifact.file.lengthSync();
    if (artifact.variants.length <= maxObjects && size <= maxObjectBytes) return true;
    warnings?.writeln('Skipping artifact beyond bounded upload capacity: ${artifact.file.path} ($size bytes)');
    return false;
  }).toList();
}

// Batches bound each CLI invocation's assemble; an artifact over the byte
// bound fills a batch alone.
List<List<SymbolArtifact>> batchSymbolArtifacts(
  List<SymbolArtifact> artifacts, {
  int maxObjects = symbolBatchObjects,
  int maxBytes = symbolBatchBytes,
  int maxObjectBytes = symbolObjectBytes,
}) {
  final batches = <List<SymbolArtifact>>[];
  var batch = <SymbolArtifact>[];
  var objects = 0;
  var bytes = 0;
  for (final artifact in artifacts) {
    final size = artifact.file.lengthSync();
    if (artifact.variants.length > maxObjects || size > maxObjectBytes) {
      throw SymbolFailure('Artifact exceeds bounded upload capacity: ${artifact.file.path} ($size bytes)');
    }
    if (batch.isNotEmpty && (objects + artifact.variants.length > maxObjects || bytes + artifact.bytes > maxBytes)) {
      batches.add(batch);
      batch = [];
      objects = 0;
      bytes = 0;
    }
    batch.add(artifact);
    objects += artifact.variants.length;
    bytes += artifact.bytes;
  }
  if (batch.isNotEmpty) batches.add(batch);
  return batches;
}

class SymbolPlan {
  SymbolPlan(
    this.platform,
    this.sourceRoot,
    this.release,
    this.dist,
    this.native,
    this.dart,
    this.mapPath,
    this.mapEntries,
  );
  final String platform;
  final String sourceRoot;
  final String release;
  final String dist;
  final List<SymbolArtifact> native;
  final List<SymbolArtifact> dart;
  final String? mapPath;
  final List<String>? mapEntries;
  List<SymbolArtifact> get sourceJobs => [...native, ...dart].where((a) => a.features.contains('debug')).toList();
  Map<String, Object?> toJson() => {
    'platform': platform,
    'source_root': sourceRoot,
    'release': release,
    'dist': dist,
    'native_batches': batchSymbolArtifacts(native).map((b) => b.map((a) => a.toJson()).toList()).toList(),
    'dart_batches': batchSymbolArtifacts(dart).map((b) => b.map((a) => a.toJson()).toList()).toList(),
    'source_jobs': sourceJobs.map((a) => a.file.path).toList(),
    'source_policy':
        'Generate separately; measure resulting bundles before explicit bounded uploads. No implicit include-sources expansion.',
    'batch_limits': {
      'objects': symbolBatchObjects,
      'uncompressed_bytes': symbolBatchBytes,
      'object_bytes': symbolObjectBytes,
    },
    'maps': mapPath == null
        ? []
        : dart.map((a) => {'map': mapPath, 'debug_file': a.file.path, 'debug_id': a.variants.single.debugId}).toList(),
    'release_phases': ['new', 'finalize'],
    'commits': false,
  };
}

List<File> _files(String root) {
  final directory = Directory(root);
  if (!directory.existsSync()) return [];
  return directory.listSync(recursive: true, followLinks: false).whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

Future<SymbolArtifact?> _inspect(
  File file,
  SymbolCommand command,
  int provenance, {
  bool dart = false,
  bool identityOnly = false,
}) async {
  final result = await command(['debug-files', 'check', '--json', file.path]);
  dynamic metadata;
  try {
    metadata = jsonDecode(result.stdout.toString());
  } on FormatException {
    throw SymbolFailure('Cannot inspect ${file.path}: ${result.stderr}', result.exitCode == 0 ? 1 : result.exitCode);
  }
  if (metadata is! Map || metadata['variants'] is! List) throw SymbolFailure('Invalid CLI metadata for ${file.path}');
  if (!identityOnly && metadata['is_usable'] != true) {
    if (dart) throw SymbolFailure('Dart debug information is unusable: ${file.path}');
    return null;
  }
  if (result.exitCode != 0 && !(identityOnly && result.exitCode == 1 && metadata['is_usable'] == false)) {
    throw SymbolFailure('Metadata check failed: ${file.path}', result.exitCode);
  }
  final variants = <SymbolVariant>[];
  for (final variant in metadata['variants'] as List) {
    final id = variant['debug_id']?.toString().toLowerCase() ?? '';
    if (!RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}(?:-[0-9a-f]+)?$').hasMatch(id) ||
        id.replaceAll(RegExp(r'[-0]'), '').isEmpty) {
      throw SymbolFailure('Missing valid debug ID: ${file.path}');
    }
    variants.add(
      SymbolVariant(id, _arch(variant['arch']?.toString() ?? ''), variant['code_id']?.toString().toLowerCase()),
    );
  }
  if (variants.isEmpty) throw SymbolFailure('No debug variants in ${file.path}');
  return SymbolArtifact(
    file,
    metadata['type'].toString(),
    variants,
    metadata['features'].toString().split(',').map((s) => s.trim()).toSet(),
    provenance,
    dart: dart,
  );
}

bool isDebugObject(File file) {
  final input = file.openSync();
  try {
    final bytes = input.readSync(4);
    if (bytes.length != 4) return false;
    final magic = ByteData.sublistView(bytes).getUint32(0);
    return magic == 0x7f454c46 ||
        magic == 0xfeedface ||
        magic == 0xcefaedfe ||
        magic == 0xfeedfacf ||
        magic == 0xcffaedfe ||
        magic == 0xcafebabe ||
        magic == 0xbebafeca ||
        magic == 0xcafebabf ||
        magic == 0xbfbafeca ||
        magic == 0x4d696372 ||
        magic >> 16 == 0x4d5a;
  } finally {
    input.closeSync();
  }
}

Stream<({String name, SymbolVariant variant})> _packagedLibraries(File package, SymbolCommand command) async* {
  final temporary = await Directory.systemTemp.createTemp('plezy-package-inspection-');
  final input = InputFileStream(package.path);
  try {
    final archive = ZipDecoder().decodeStream(input);
    final file = File(path.join(temporary.path, 'library.so'));
    for (final entry in archive) {
      if (!entry.isFile || !RegExp(r'^(?:base/)?lib/[^/]+/[^/]+\.so$').hasMatch(entry.name)) continue;
      if (entry.isSymbolicLink || entry.size > 1024 * 1024 * 1024) {
        throw SymbolFailure('Unsupported packaged library: ${entry.name}');
      }
      final output = OutputFileStream(file.path);
      try {
        entry.writeContent(output);
      } finally {
        output.closeSync();
      }
      if (file.lengthSync() != entry.size) throw SymbolFailure('Truncated packaged library: ${entry.name}');
      // Stripped packaged objects still identify shipped payloads even when
      // they are not independently useful debug uploads (CLI check exit 1).
      final metadata = await _inspect(file, command, 0, identityOnly: true);
      if (metadata == null || metadata.type != 'elf' || metadata.variants.length != 1) {
        throw SymbolFailure('Expected one packaged ELF identity: ${entry.name}');
      }
      yield (name: entry.name, variant: metadata.variants.single);
    }
  } finally {
    input.closeSync();
    await temporary.delete(recursive: true);
  }
}

Future<void> downloadSymbolArchive(Uri url, File destination) async {
  final client = HttpClient();
  try {
    final response = await (await client.getUrl(url)).close();
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw HttpException('HTTP ${response.statusCode}', uri: url);
    }
    await response.pipe(destination.openWrite());
  } finally {
    client.close(force: true);
  }
}

// Reuses or downloads a checksummed zip, then extracts the debug files at its
// root beside it. The lock names exact bytes, so a mismatch is fatal.
Future<List<File>> _verifiedDebugArchive(Uri url, File archive, String checksum, SymbolDownload download) async {
  Future<String> digest(File file) async => (await sha256.bind(file.openRead()).first).toString();
  if (!archive.existsSync() || await digest(archive) != checksum) {
    archive.parent.createSync(recursive: true);
    final partial = File('${archive.path}.partial');
    try {
      await download(url, partial);
      final actual = await digest(partial);
      if (actual != checksum) throw SymbolFailure('Checksum mismatch for $url: expected $checksum, got $actual');
      partial.renameSync(archive.path);
    } on IOException catch (error) {
      throw SymbolFailure('Cannot download $url: $error');
    } finally {
      if (partial.existsSync()) partial.deleteSync();
    }
  }
  final destination = Directory(path.withoutExtension(archive.path));
  if (destination.existsSync()) destination.deleteSync(recursive: true);
  destination.createSync(recursive: true);
  final files = <File>[];
  final input = InputFileStream(archive.path);
  try {
    for (final entry in ZipDecoder().decodeStream(input)) {
      final name = entry.name;
      if (!entry.isFile ||
          entry.isSymbolicLink ||
          name.contains('/') ||
          name.contains(r'\') ||
          name == '.' ||
          name == '..') {
        continue;
      }
      final file = File(path.join(destination.path, name));
      final output = OutputFileStream(file.path);
      try {
        entry.writeContent(output);
      } finally {
        output.closeSync();
      }
      if (file.lengthSync() != entry.size) throw SymbolFailure('Truncated debug file $name in $url');
      if (isDebugObject(file)) files.add(file);
    }
  } finally {
    input.closeSync();
  }
  return files..sort((a, b) => a.path.compareTo(b.path));
}

// mpv-build.lock.json (schema in scripts/set_native_revision.sh) names one
// checksummed zip of debug files per variant of the library a group ships.
// Pins published before mpv-build shipped them have no symbols map.
Future<List<File>> _mpvBuildDebugFiles(
  String sourceRoot,
  String group,
  Iterable<String> variants,
  SymbolDownload download,
  StringSink notes,
) async {
  Object? field(Object? value, String key) => value is Map ? value[key] : null;
  final lock = File(path.join(sourceRoot, 'mpv-build.lock.json'));
  final section = lock.existsSync() ? field(field(jsonDecode(lock.readAsStringSync()), 'artifacts'), group) : null;
  final files = <File>[];
  for (final variant in variants.toList()..sort()) {
    final entry = field(field(section, 'symbols'), variant);
    if (entry == null) {
      notes.writeln('Note: mpv-build.lock.json has no $group symbols for $variant; skipping mpv-build debug files');
      continue;
    }
    final base = field(section, 'assetBase');
    final asset = field(entry, 'asset');
    final checksum = field(entry, 'checksum');
    if (base is! String ||
        asset is! String ||
        !RegExp(r'^[\w.-]+\.zip$').hasMatch(asset) ||
        checksum is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(checksum)) {
      throw SymbolFailure('Invalid mpv-build.lock.json $group symbols entry for $variant');
    }
    files.addAll(
      await _verifiedDebugArchive(
        Uri.parse('$base/$asset'),
        File(path.join(sourceRoot, 'build', 'symbols', 'mpv-build', asset)),
        checksum,
        download,
      ),
    );
  }
  return files;
}

// MSVC links `<target>.pdb` into the target's configuration directory;
// windows/CMakeLists.txt moves the runner's out of the bundle into
// link-artifacts/Release. The patched engine ships flutter_windows.dll.pdb.
List<File> _windowsPdbs(String sourceRoot, String arch, Iterable<File> shipped) {
  final names = {
    for (final file in shipped) ...[
      '${path.basenameWithoutExtension(file.path)}.pdb'.toLowerCase(),
      '${path.basename(file.path)}.pdb'.toLowerCase(),
    ],
  };
  final bundle = path.join(sourceRoot, 'build', 'windows', arch, 'runner', 'Release');
  final ephemeral = Directory(path.join(sourceRoot, 'windows', 'flutter', 'ephemeral'));
  return [
      ..._files(
        path.join(sourceRoot, 'build', 'windows', arch),
      ).where((file) => path.basename(file.parent.path) == 'Release' && !path.isWithin(bundle, file.path)),
      if (ephemeral.existsSync()) ...ephemeral.listSync(followLinks: false).whereType<File>(),
    ].where((file) => names.contains(path.basename(file.path).toLowerCase())).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

Future<SymbolPlan> createSymbolPlan(
  String platform,
  String sourceRoot,
  Map<String, String> environment,
  SymbolCommand command, {
  StringSink? warnings,
  SymbolDownload download = downloadSymbolArchive,
}) async {
  final build = path.join(sourceRoot, 'build');
  final symbolRoot = path.join(sourceRoot, 'debug-info', platform);
  final native = <SymbolArtifact>[];
  final shipped = <String>{};
  final dartShipped = <String>{};
  final allowedArch = <String>{};
  final abis = <String>{};
  final nativeRoots = <(String, int)>[];
  final sink = warnings ?? stderr;
  final android = platform.startsWith('android-');
  final apple = platform == 'ios' || platform == 'macos';
  if (android) {
    final packages = <File>[];
    if (platform == 'android-aab') {
      packages.add(File(path.join(build, 'app/outputs/bundle/release/app-release.aab')));
    } else {
      final metadataFile = File(path.join(build, 'app/outputs/apk/release/output-metadata.json'));
      if (metadataFile.existsSync()) {
        final metadata = jsonDecode(metadataFile.readAsStringSync()) as Map<String, dynamic>;
        for (final element in metadata['elements'] as List) {
          final name = element['outputFile'] as String;
          if (path.basename(name) != name || !name.endsWith('-release.apk')) {
            throw SymbolFailure('Unexpected release APK metadata');
          }
          packages.add(File(path.join(metadataFile.parent.path, name)));
        }
      } else {
        packages.addAll(
          _files(path.join(build, 'app/outputs/flutter-apk')).where(
            (f) => RegExp(r'^app-(?:(?:arm64-v8a|armeabi-v7a|x86_64)-)?release\.apk$').hasMatch(path.basename(f.path)),
          ),
        );
        if (packages.length > 1 && packages.any((f) => path.basename(f.path) == 'app-release.apk')) {
          throw SymbolFailure(
            'Ambiguous APK outputs; retain current AGP output-metadata.json or remove stale build outputs',
          );
        }
      }
    }
    if (packages.isEmpty) throw SymbolFailure('No packaged release for $platform');
    final libraryIds = <String, String>{};
    for (final package in packages) {
      if (!package.existsSync()) throw SymbolFailure('Missing packaged release: ${package.path}');
      await for (final entry in _packagedLibraries(package, command)) {
        final parts = entry.name.split('/');
        final abi = parts[parts.length - 2];
        final name = parts.last;
        final id = entry.variant;
        final expectedArch = {'arm64-v8a': 'arm64', 'armeabi-v7a': 'arm', 'x86_64': 'x86_64', 'x86': 'x86'}[abi];
        if (id.arch != expectedArch) throw SymbolFailure('Packaged ABI/ELF mismatch: ${entry.name}');
        final key = '$abi/$name';
        if (libraryIds.containsKey(key) && libraryIds[key] != id.debugId) {
          throw SymbolFailure('Conflicting release packages: $key');
        }
        libraryIds[key] = id.debugId;
        abis.add(abi);
        final identity = '${id.debugId}/${id.arch}';
        shipped.add(identity);
        allowedArch.add(id.arch);
        if (name == 'libapp.so') dartShipped.add(identity);
      }
    }
    if (dartShipped.isEmpty || dartShipped.length != allowedArch.length) {
      throw SymbolFailure('Packaged release is missing Dart AOT libraries');
    }
    // The AAR's libraries (libmpv, FFmpeg, libplayer) arrive stripped; their
    // debug files come from mpv-build below. The merged libraries are the
    // build-tree candidates, libflutter.so among them unstripped as the
    // engine's Maven artifact ships it.
    nativeRoots.add((
      path.join(build, 'app/intermediates/merged_native_libs/release/mergeReleaseNativeLibs/out/lib'),
      30,
    ));
  } else if (platform.startsWith('linux-') || platform.startsWith('windows-')) {
    final arch = platform.split('-').last;
    allowedArch.add(arch == 'x64' ? 'x86_64' : 'arm64');
    nativeRoots.add((
      path.join(build, platform.startsWith('linux-') ? 'linux/$arch/release/bundle' : 'windows/$arch/runner/Release'),
      30,
    ));
  } else if (apple) {
    final explicitArchive = environment['BUGS_APPLE_ARCHIVE'];
    final product = platform == 'macos'
        ? path.join(build, 'macos/Build/Products/Release/Plezy.app')
        : explicitArchive != null && explicitArchive.isNotEmpty
        ? path.join(
            path.isAbsolute(explicitArchive) ? explicitArchive : path.join(sourceRoot, explicitArchive),
            'Products/Applications/Plezy.app',
          )
        : path.join(build, 'ios/iphoneos/Plezy.app');
    if (!Directory(product).existsSync()) throw SymbolFailure('Missing selected release product: $product');
    for (final file in _files(product).where(isDebugObject)) {
      final artifact = await _inspect(file, command, 10);
      if (artifact == null) continue;
      native.add(artifact);
      for (final variant in artifact.variants) {
        shipped.add(variant.identity);
        allowedArch.add(variant.arch);
        if (path.basename(file.path) == 'App') dartShipped.add(variant.identity);
      }
    }
    if (explicitArchive != null && explicitArchive.isNotEmpty) {
      nativeRoots.add((
        path.join(path.isAbsolute(explicitArchive) ? explicitArchive : path.join(sourceRoot, explicitArchive), 'dSYMs'),
        40,
      ));
    } else {
      nativeRoots.add((
        path.join(build, platform == 'macos' ? 'macos/Build/Products/Release' : 'ios/Release-iphoneos'),
        30,
      ));
      // Archive symbols are accepted only by the selected device product's IDs,
      // never by archive directory presence or modification time.
      if (platform == 'ios') nativeRoots.add((path.join(build, 'ios/archive'), 20));
    }
  } else {
    throw SymbolFailure('Unknown platform: $platform', 2);
  }
  for (final (root, provenance) in nativeRoots) {
    for (final file in _files(root)) {
      if (apple && !path.split(file.path).any((part) => part.endsWith('.dSYM'))) continue;
      if (android &&
          (!file.path.endsWith('.so') ||
              !allowedArch.contains(
                _arch(
                  {'arm64-v8a': 'arm64', 'armeabi-v7a': 'arm', 'x86_64': 'x86_64', 'x86': 'x86'}[path.basename(
                        file.parent.path,
                      )] ??
                      '',
                ),
              ))) {
        continue;
      }
      if (!isDebugObject(file)) continue;
      final artifact = await _inspect(file, command, provenance);
      if (artifact == null) continue;
      if (!artifact.variants.every((v) => allowedArch.contains(v.arch))) continue;
      if ((android || apple) && !artifact.variants.every((v) => shipped.contains(v.identity))) continue;
      native.add(artifact);
    }
  }
  // Debug files built or published outside the shipped tree count only for
  // the exact binaries this release ships.
  final shippedIds = android ? shipped : native.expand((a) => a.variants).map((v) => v.identity).toSet();
  final companions = <File>[
    if (platform.startsWith('windows-'))
      ..._windowsPdbs(sourceRoot, platform.split('-').last, native.where((a) => a.type == 'pe').map((a) => a.file)),
    if (android) ...await _mpvBuildDebugFiles(sourceRoot, 'android', abis, download, sink),
    if (platform.startsWith('linux-') || platform.startsWith('windows-'))
      ...await _mpvBuildDebugFiles(
        sourceRoot,
        platform.split('-').first,
        [platform.endsWith('-x64') ? 'x86_64' : 'aarch64'],
        download,
        sink,
      ),
  ];
  for (final file in companions) {
    final artifact = await _inspect(file, command, 20);
    if (artifact == null) {
      sink.writeln('Skipping unusable debug file: ${file.path}');
    } else if (!artifact.variants.every((v) => shippedIds.contains(v.identity))) {
      sink.writeln(
        'Skipping debug file that matches no shipped binary: ${file.path} '
        '(${artifact.variants.map((v) => v.identity).join(', ')})',
      );
    } else {
      native.add(artifact);
    }
  }
  if (!android && !apple) {
    for (final artifact in native) {
      final basename = path.basename(artifact.file.path);
      if (basename == 'libapp.so' || basename == 'app.so') dartShipped.addAll(artifact.variants.map((v) => v.identity));
    }
  }
  final dart = <SymbolArtifact>[];
  final dartPlatform = android
      ? 'android'
      : platform == 'macos'
      ? 'darwin'
      : platform.split('-').first;
  for (final file in _files(symbolRoot)) {
    if (!RegExp('^app\\.$dartPlatform-[^.]+\\.symbols\$').hasMatch(path.basename(file.path))) continue;
    final artifact = await _inspect(file, command, 40, dart: true);
    if (artifact == null || !artifact.features.contains('debug')) {
      throw SymbolFailure('Missing Dart debug information: ${file.path}');
    }
    if (!artifact.variants.every((v) => allowedArch.contains(v.arch))) continue;
    if (dartShipped.isNotEmpty && !artifact.variants.every((v) => dartShipped.contains(v.identity))) continue;
    dart.add(artifact);
  }
  final selectedNative = selectSymbolArtifacts(native);
  final selectedDart = selectSymbolArtifacts(dart);
  final dartIds = selectedDart.expand((a) => a.variants).map((v) => v.identity).toSet();
  if (selectedDart.isEmpty || (dartShipped.isNotEmpty && !dartIds.containsAll(dartShipped))) {
    throw SymbolFailure(
      'Missing matching $platform Dart .symbols for shipped AOT identities: ${dartShipped.difference(dartIds).join(', ')}',
    );
  }
  if (android) {
    final covered = {...selectedNative.expand((a) => a.variants).map((v) => v.identity), ...dartIds};
    if (!covered.containsAll(shipped)) {
      throw SymbolFailure('Missing matching release native candidates: ${shipped.difference(covered).join(', ')}');
    }
  }
  if (selectedNative.isEmpty) throw SymbolFailure('No usable release native symbols for $platform');
  if (apple &&
      !selectedNative.any(
        (artifact) =>
            artifact.features.contains('debug') && path.split(artifact.file.path).any((part) => part.endsWith('.dSYM')),
      )) {
    throw SymbolFailure('No matching release dSYM for $platform');
  }
  final explicitMap = environment['SENTRY_DART_SYMBOL_MAP_PATH'];
  final mapFile = File(
    explicitMap != null && explicitMap.isNotEmpty
        ? path.isAbsolute(explicitMap)
              ? explicitMap
              : path.join(sourceRoot, explicitMap)
        : path.join(symbolRoot, 'obfuscation.map.json'),
  );
  List<String>? entries;
  if (android || mapFile.existsSync() || (explicitMap != null && explicitMap.isNotEmpty)) {
    if (!mapFile.existsSync()) throw SymbolFailure('Required Dart map missing: ${mapFile.path}');
    final decoded = jsonDecode(mapFile.readAsStringSync());
    if (decoded is! List || decoded.isEmpty || decoded.length.isOdd || decoded.any((value) => value is! String)) {
      throw SymbolFailure('Invalid Dart map: ${mapFile.path}');
    }
    entries = decoded.cast<String>().toList();
    if (entries.first == 'SENTRY_DEBUG_ID_MARKER') entries.removeRange(0, 2);
    if (entries.isEmpty) throw SymbolFailure('Empty Dart map: ${mapFile.path}');
    for (final artifact in selectedDart) {
      if (artifact.variants.length != 1) {
        throw SymbolFailure('Dart maps require single-ID .symbols: ${artifact.file.path}');
      }
    }
    // Marker UUID is bounded, and JSON encoding is exactly what execution writes.
    if (utf8.encode(jsonEncode(['SENTRY_DEBUG_ID_MARKER', '0' * 80, ...entries])).length > symbolBatchBytes) {
      throw SymbolFailure('Dart map exceeds bounded upload capacity');
    }
  }
  // Coverage is asserted above against everything shipped; capacity is applied
  // after, so an oversized artifact is a reported gap rather than a hard stop.
  final boundedNative = withinUploadCapacity(selectedNative, warnings: sink);
  final boundedDart = withinUploadCapacity(selectedDart, warnings: sink);
  if (boundedNative.isEmpty) {
    throw SymbolFailure('No release native symbols for $platform fit the bounded upload capacity');
  }
  final plan = SymbolPlan(
    platform,
    sourceRoot,
    environment['SENTRY_RELEASE']!,
    environment['SENTRY_DIST'] ?? '',
    boundedNative,
    boundedDart,
    entries == null ? null : mapFile.path,
    entries,
  );
  return plan;
}

Future<void> executeSymbolPlan(SymbolPlan plan, SymbolCommand command, {StringSink? output}) async {
  Future<String> checked(List<String> args) async {
    final result = await command(args);
    final log = result.stdout.toString();
    output?.write(log);
    if (result.exitCode != 0) {
      throw SymbolFailure('${args.take(2).join(' ')} failed: ${result.stderr}', result.exitCode);
    }
    return log;
  }

  Future<void> upload(List<SymbolArtifact> artifacts) async {
    // CLI 2.58.6's --require-all checks newly returned DIFs, not completed
    // receipts, and incorrectly fails an entirely already-present batch.
    // The plan has already checked every explicit file and required identity.
    for (final batch in batchSymbolArtifacts(artifacts)) {
      final log = await checked([
        'debug-files',
        'upload',
        '--wait-for',
        '600',
        '--no-zips',
        ...batch.expand((a) => a.variants).map((v) => v.debugId).toSet().expand((id) => ['--id', id]),
        ...batch.map((a) => a.file.path),
      ]);
      // The CLI also drops, logging only at debug level and exiting 0, every
      // object whose format the server's chunk-upload "accept" list omits
      // (2.58.6 valid_format: PE and PDB need "pdbs", source bundles
      // "sources"). Run 38170180917 planned flutter_windows.dll.pdb and each
      // Windows PE against a tracker without "pdbs"; the CLI found none of
      // them. Its count of found objects is the only trace; assembly errors
      // and still-missing objects already fail the command.
      final planned = batch.fold<int>(0, (count, artifact) => count + artifact.variants.length);
      final found = RegExp(
        r'Found (\d+) debug information file',
      ).firstMatch(log.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), ''))?.group(1);
      if (found == null || int.parse(found) < planned) {
        throw SymbolFailure(
          'sentry-cli took ${found ?? 'none'} of $planned planned debug objects and dropped the rest without an '
          'error; check the chunk-upload accept list of the server (PE/PDB need "pdbs"): '
          '${batch.map((a) => a.file.path).join(', ')}',
        );
      }
    }
  }

  await upload(plan.native);
  await upload(plan.dart);
  final sourceJobs = plan.sourceJobs;
  final temporary = await Directory.systemTemp.createTemp('plezy-symbol-upload-');
  try {
    for (var index = 0; index < sourceJobs.length; index++) {
      final artifact = sourceJobs[index];
      final destination = Directory(path.join(temporary.path, 'sources-$index'))..createSync();
      await checked(['debug-files', 'bundle-sources', '--output', destination.path, artifact.file.path]);
      final sources = <SymbolArtifact>[];
      for (final file in _files(destination.path)) {
        final source = await _inspect(file, command, 0);
        if (source == null ||
            source.type != 'sourcebundle' ||
            !source.variants.every((v) => artifact.variants.any((original) => original.debugId == v.debugId))) {
          throw SymbolFailure('Generated source bundle identity mismatch: ${file.path}');
        }
        sources.add(source);
      }
      // No --include-sources: every generated byte is measured before upload.
      await upload(selectSymbolArtifacts(sources));
    }
    if (plan.mapEntries != null) {
      for (final artifact in plan.dart) {
        final map = File(path.join(temporary.path, '${artifact.variants.single.debugId}.json'));
        await map.writeAsString(
          jsonEncode(['SENTRY_DEBUG_ID_MARKER', artifact.variants.single.debugId, ...plan.mapEntries!]),
        );
        // 2.58.6 waits internally for completion (300s) and fails pending/error
        // assemblies. It has no --wait option; passing one would be an error.
        await checked(['dart-symbol-map', 'upload', map.path, artifact.file.path]);
      }
    }
    await checked(['releases', 'new', plan.release]);
    await checked(['releases', 'finalize', plan.release]);
  } finally {
    await temporary.delete(recursive: true);
  }
}

Future<void> main(List<String> arguments) async {
  exitCode = await runUploadSymbols(arguments, repositoryRoot: File.fromUri(Platform.script).parent.parent.parent);
}

Future<int> runUploadSymbols(
  List<String> arguments, {
  required Directory repositoryRoot,
  Map<String, String>? environment,
  SymbolCommand? command,
  StringSink? output,
  StringSink? errors,
  SymbolDownload download = downloadSymbolArchive,
}) async {
  final out = output ?? stdout;
  final err = errors ?? stderr;
  try {
    if (arguments.isEmpty || arguments.length > 2) {
      throw SymbolFailure('Usage: upload-symbols <platform> [source-root]');
    }
    final root = path.normalize(path.absolute(repositoryRoot.path));
    final sourceRoot = arguments.length == 1
        ? root
        : path.normalize(path.isAbsolute(arguments[1]) ? arguments[1] : path.join(root, arguments[1]));
    final env = Map<String, String>.of(environment ?? Platform.environment);
    final dryRun = (env['BUGS_UPLOAD_DRY_RUN'] ?? '').isNotEmpty;
    env['SENTRY_URL'] = _first([env['SENTRY_URL'], env['BUGS_URL'], 'https://bugs.plezy.app']);
    env['SENTRY_ORG'] = _first([env['SENTRY_ORG'], 'plezy']);
    env['SENTRY_PROJECT'] = _first([env['SENTRY_PROJECT'], 'plezy']);
    env['SENTRY_AUTH_TOKEN'] = _first([env['SENTRY_AUTH_TOKEN'], env['BUGS_ADMIN_TOKEN'], '']);
    if (!dryRun && env['SENTRY_AUTH_TOKEN']!.isEmpty) {
      throw SymbolFailure('SENTRY_AUTH_TOKEN or BUGS_ADMIN_TOKEN required');
    }
    if ((env['SENTRY_RELEASE'] ?? '').isEmpty) {
      final revision = await Process.run('git', ['rev-parse', '--short', 'HEAD'], workingDirectory: sourceRoot);
      if (revision.exitCode != 0 || revision.stdout.toString().trim().isEmpty) {
        throw SymbolFailure('Cannot determine source-root release; set SENTRY_RELEASE');
      }
      env['SENTRY_RELEASE'] = 'plezy@${revision.stdout.toString().trim()}';
    }
    final executable = command == null ? await provisionSymbolCli(root, env, dryRun: dryRun) : null;
    final invoke =
        command ??
        (List<String> args) => Process.run(
          executable!,
          args,
          workingDirectory: sourceRoot,
          environment: env,
          includeParentEnvironment: false,
        );
    final plan = await createSymbolPlan(arguments.first, sourceRoot, env, invoke, warnings: err, download: download);
    out.writeln(jsonEncode(plan.toJson()));
    if (!dryRun) await executeSymbolPlan(plan, invoke, output: out);
    return 0;
  } on SymbolFailure catch (error) {
    err.writeln(error);
    return error.code;
  } on Exception catch (error) {
    err.writeln(error);
    return 1;
  }
}

String _first(List<String?> values) =>
    values.firstWhere((value) => value != null && value.isNotEmpty, orElse: () => '')!;
