import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import '../../scripts/release/upload_symbols.dart';

Uint8List elf(int seed, {int machine = 183}) {
  final bytes = Uint8List(160);
  final data = ByteData.sublistView(bytes);
  data.setUint32(0, 0x7f454c46);
  bytes[4] = 2;
  bytes[5] = 1;
  bytes[6] = 1;
  data.setUint16(16, 3, Endian.little);
  data.setUint16(18, machine, Endian.little);
  data.setUint64(32, 64, Endian.little);
  data.setUint16(54, 56, Endian.little);
  data.setUint16(56, 1, Endian.little);
  data.setUint32(64, 4, Endian.little);
  data.setUint64(72, 120, Endian.little);
  data.setUint64(96, 36, Endian.little);
  data.setUint32(120, 4, Endian.little);
  data.setUint32(124, 20, Endian.little);
  data.setUint32(128, 3, Endian.little);
  data.setUint32(132, 0x474e5500);
  for (var i = 0; i < 20; i++) {
    bytes[136 + i] = seed + i;
  }
  return bytes;
}

String fixtureDebugId(int seed) {
  String group(List<int> offsets) => offsets.map((i) => (seed + i).toRadixString(16).padLeft(2, '0')).join();
  return '${group([3, 2, 1, 0])}-${group([5, 4])}-${group([7, 6])}-${group([8, 9])}-${group([10, 11, 12, 13, 14, 15])}';
}

Uint8List zip(Map<String, Uint8List> members) {
  final archive = Archive();
  for (final entry in members.entries) {
    archive.add(ArchiveFile.bytes(entry.key, entry.value));
  }
  return ZipEncoder().encodeBytes(archive);
}

const mpvBuildReleases = 'https://github.com/edde746/mpv-build/releases/download';

void main() {
  late Directory repository;
  late Map<String, String> features;
  late List<List<String>> operations;
  late List<List<String>> uploadedMaps;
  late int Function(List<String>) failure;
  late StringBuffer warnings;
  late Map<Uri, Uint8List> releases;
  late List<Uri> downloads;
  late Set<String> unaccepted;

  File put(String relative, List<int> bytes, {String info = 'debug, symtab, unwind'}) {
    final file = File(path.join(repository.path, relative));
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
    features[file.path] = info;
    return file;
  }

  String typeOf(String file) => switch (path.extension(file)) {
    '.pdb' => 'pdb',
    '.exe' || '.dll' => 'pe',
    _ => 'elf',
  };

  Future<ProcessResult> cli(List<String> args) async {
    if (args.take(2).join(' ') == 'debug-files check') {
      final file = File(args.last);
      final bytes = file.readAsBytesSync();
      final machine = ByteData.sublistView(bytes).getUint16(18, Endian.little);
      // Fixture notes start at 136; this boundary stub is not an ELF parser.
      final id = fixtureDebugId(bytes[136]);
      final packaged = path.basename(file.path) == 'library.so';
      return ProcessResult(
        0,
        packaged ? 1 : 0,
        jsonEncode({
          'type': typeOf(file.path),
          'is_usable': !packaged,
          'features': features[file.path] ?? 'none',
          'variants': [
            {'debug_id': id, 'code_id': null, 'arch': machine == 62 ? 'x86_64' : 'arm64'},
          ],
        }),
        '',
      );
    }
    operations.add(List.of(args));
    if (args.first == 'dart-symbol-map') {
      uploadedMaps.add((jsonDecode(File(args[2]).readAsStringSync()) as List).cast<String>());
    }
    // sentry-cli 2.58.6 counts the objects whose format the server accepts,
    // as run 38170180917 logged them, and silently drops the rest.
    final found = args.take(2).join(' ') == 'debug-files upload'
        ? args.where((arg) => path.isAbsolute(arg) && !unaccepted.contains(typeOf(arg))).length
        : null;
    return ProcessResult(0, failure(args), switch (found) {
      null => '',
      0 => '> Found 0 debug information files\n> No debug information files found\n',
      1 => '> Found 1 debug information file\n',
      _ => '> Found $found debug information files\n',
    }, 'injected process failure');
  }

  Future<void> download(Uri url, File destination) async {
    downloads.add(url);
    final bytes = releases[url];
    if (bytes == null) throw HttpException('HTTP 404', uri: url);
    await destination.writeAsBytes(bytes);
  }

  // A symbols entry as mpv-build's artifacts.json publishes it and
  // scripts/set_native_revision.sh copies it into the lock.
  Map<String, String> publish(String group, String asset, Map<String, Uint8List> members) {
    final bytes = zip(members);
    releases[Uri.parse('$mpvBuildReleases/binaries-$group/$asset')] = bytes;
    return {'asset': asset, 'checksum': sha256.convert(bytes).toString()};
  }

  void lock(Map<String, Object?> artifacts) => put(
    'mpv-build.lock.json',
    utf8.encode(
      jsonEncode({
        'artifacts': artifacts,
        'commit': '8ad6d9b8290c4705573969415e9d97f7bffd51ff',
        'formatVersion': 1,
        'repo': 'edde746/mpv-build',
      }),
    ),
  );

  Map<String, Object?> linuxGroup([Map<String, Object?>? symbols]) => {
    'assetBase': '$mpvBuildReleases/binaries-linux',
    'assets': {
      'x86_64': {
        'asset': 'libmpv-linux-496db2c56ebc-x86_64.tar.zst',
        'checksum': '18588163504ea1395d09fe2406410493e65fce82e310af3c191cd26d575f68fc',
      },
    },
    'key': '496db2c56ebc',
    'symbols': ?symbols,
  };

  // Extracted debug files are registered like any other fixture file.
  String extracted(String asset, String name, {String info = 'debug, symtab, unwind'}) {
    final file = path.join(repository.path, 'build/symbols/mpv-build', path.withoutExtension(asset), name);
    features[file] = info;
    return file;
  }

  void android({bool map = true, bool dart = true}) {
    put(
      'build/app/outputs/bundle/release/app-release.aab',
      zip({'base/lib/arm64-v8a/libapp.so': elf(1), 'base/lib/arm64-v8a/libmpv.so': elf(30)}),
    );
    put(
      'build/app/intermediates/merged_native_libs/release/mergeReleaseNativeLibs/out/lib/arm64-v8a/libapp.so',
      elf(1),
    );
    put(
      'build/app/intermediates/merged_native_libs/release/mergeReleaseNativeLibs/out/lib/arm64-v8a/libmpv.so',
      elf(30),
      info: 'symtab, unwind',
    );
    if (dart) put('debug-info/android-aab/app.android-arm64.symbols', elf(1));
    if (map) put('debug-info/android-aab/obfuscation.map.json', utf8.encode('["Original","a"]'));
  }

  Future<SymbolPlan> plan([String platform = 'android-aab']) => createSymbolPlan(
    platform,
    repository.path,
    {'SENTRY_RELEASE': 'plezy@fixture', 'SENTRY_DIST': 'play-store'},
    cli,
    warnings: warnings,
    download: download,
  );

  void linux() {
    put('build/linux/x64/release/bundle/lib/libapp.so', elf(1, machine: 62));
    put('build/linux/x64/release/bundle/lib/libmpv.so.2', elf(5, machine: 62), info: 'symtab, unwind');
    put('debug-info/linux-x64/app.linux-x64.symbols', elf(1, machine: 62));
  }

  // windows-x64 as `flutter build windows` leaves it: the bundle, plugin
  // PDBs beside their DLLs, the runner's in link-artifacts, and the patched
  // engine's PDB in the ephemeral directory.
  void windows() {
    const bundle = 'build/windows/x64/runner/Release';
    put('$bundle/plezy.exe', elf(10, machine: 62), info: 'symtab, unwind');
    put('$bundle/window_manager_plugin.dll', elf(11, machine: 62), info: 'symtab, unwind');
    put('$bundle/flutter_windows.dll', elf(12, machine: 62), info: 'symtab, unwind');
    put('$bundle/screen_retriever_windows_plugin.dll', elf(13, machine: 62), info: 'symtab, unwind');
    put('$bundle/libmpv-2.dll', elf(14, machine: 62), info: 'symtab, unwind');
    put('$bundle/data/app.so', elf(1, machine: 62));
    put('debug-info/windows-x64/app.windows-x64.symbols', elf(1, machine: 62));
    put('build/windows/x64/link-artifacts/Release/plezy.pdb', elf(10, machine: 62), info: 'debug, symtab');
    put(
      'build/windows/x64/plugins/window_manager/Release/window_manager_plugin.pdb',
      elf(11, machine: 62),
      info: 'debug, symtab',
    );
    put('windows/flutter/ephemeral/flutter_windows.dll.pdb', elf(12, machine: 62), info: 'debug, symtab');
  }

  setUp(() async {
    repository = await Directory.systemTemp.createTemp('plezy_upload_symbols_');
    features = {};
    operations = [];
    uploadedMaps = [];
    failure = (_) => 0;
    warnings = StringBuffer();
    releases = {};
    downloads = [];
    unaccepted = {};
  });
  tearDown(() async => repository.delete(recursive: true));

  test('packaged identities exclude unshipped ABI, stale intermediates and mixed targets', () async {
    android();
    put(
      'build/app/intermediates/merged_native_libs/release/mergeReleaseNativeLibs/out/lib/x86_64/libmpv.so',
      elf(40, machine: 62),
    );
    put(
      'build/app/intermediates/merged_native_libs/release/mergeReleaseNativeLibs/out/lib/arm64-v8a/stale.so',
      elf(50),
    );
    put('build/app/intermediates/merged_native_libs/debug/mergeDebugNativeLibs/out/lib/arm64-v8a/libmpv.so', elf(30));
    put('build/app/intermediates/cxx/Release/obj/arm64-v8a/libmpv.so', elf(30));
    put('build/ios/Release-iphoneos/App.framework.dSYM/Contents/Resources/DWARF/App', elf(90));
    put('debug-info/android-apk/app.android-arm64.symbols', elf(80));
    put('debug-info/android-aab/app.ios-arm64.symbols', elf(80));
    final selected = await plan();
    expect(selected.native.map((a) => path.basename(a.file.path)).toList()..sort(), ['libapp.so', 'libmpv.so']);
    expect(
      selected.native.singleWhere((a) => path.basename(a.file.path) == 'libmpv.so').file.path,
      path.join(
        repository.path,
        'build/app/intermediates/merged_native_libs/release/mergeReleaseNativeLibs/out/lib/arm64-v8a/libmpv.so',
      ),
    );
    expect(selected.dart.map((a) => a.variants.single.debugId), [fixtureDebugId(1)]);
  });

  test('changed packaged payload cannot use stale matching-name native candidates', () async {
    android();
    put(
      'build/app/outputs/bundle/release/app-release.aab',
      zip({'base/lib/arm64-v8a/libapp.so': elf(1), 'base/lib/arm64-v8a/libmpv.so': elf(31)}),
    );
    await expectLater(plan(), throwsA(isA<SymbolFailure>()));
    expect(operations, isEmpty);
  });

  test('AGP release metadata selects the current APK rather than stale Flutter copies', () async {
    android();
    put(
      'build/app/outputs/apk/release/output-metadata.json',
      utf8.encode('{"elements":[{"outputFile":"app-arm64-v8a-release.apk"}]}'),
    );
    put(
      'build/app/outputs/apk/release/app-arm64-v8a-release.apk',
      zip({'lib/arm64-v8a/libapp.so': elf(1), 'lib/arm64-v8a/libmpv.so': elf(30)}),
    );
    put('build/app/outputs/flutter-apk/app-release.apk', zip({'lib/x86_64/libapp.so': elf(40, machine: 62)}));
    put('debug-info/android-apk/app.android-arm64.symbols', elf(1));
    put('debug-info/android-apk/obfuscation.map.json', utf8.encode('["Original","a"]'));
    final selected = await plan('android-apk');
    expect(selected.native.expand((a) => a.variants).map((v) => v.arch).toSet(), {'arm64'});
    expect(selected.dart.single.file.parent.path, path.join(repository.path, 'debug-info/android-apk'));
  });

  test('desktop release roots and Dart files isolate the requested architecture', () async {
    put('build/linux/x64/release/bundle/lib/libapp.so', elf(1, machine: 62));
    put('build/linux/arm64/release/bundle/lib/libapp.so', elf(2));
    put('build/linux/x64/debug/bundle/lib/libapp.so', elf(3, machine: 62));
    put('debug-info/linux-x64/app.linux-x64.symbols', elf(1, machine: 62));
    put('debug-info/linux-x64/app.linux-arm64.symbols', elf(2));
    final selected = await plan('linux-x64');
    expect(selected.native.single.variants.single.debugId, fixtureDebugId(1));
    expect(selected.dart.single.variants.single.arch, 'x86_64');
  });

  test('required platform map and Dart IDs cannot fall back to another build', () async {
    android(map: false);
    put('debug-info/android-apk/obfuscation.map.json', utf8.encode('["Wrong","b"]'));
    put('build/app/obfuscation.map.json', utf8.encode('["Wrong","c"]'));
    await expectLater(plan(), throwsA(isA<SymbolFailure>()));
    put('debug-info/android-aab/obfuscation.map.json', utf8.encode('["Original","a"]'));
    put('debug-info/android-aab/app.android-arm64.symbols', elf(2));
    await expectLater(plan(), throwsA(isA<SymbolFailure>()));
  });

  test('richer selection is order independent and preserves complementary classes', () {
    final file = put('rich.so', elf(1));
    final id = SymbolVariant(fixtureDebugId(1), 'arm64', null);
    final rich = SymbolArtifact(file, 'elf', [id], {'debug', 'symtab'}, 10);
    final poor = SymbolArtifact(put('poor.so', elf(1)), 'elf', [id], {'unwind'}, 30);
    final pdb = SymbolArtifact(put('complement.pdb', elf(1)), 'pdb', [id], {'debug'}, 10);
    for (final order in [
      [poor, rich, pdb],
      [pdb, rich, poor],
    ]) {
      expect(selectSymbolArtifacts(order).toSet(), {rich, pdb});
    }
  });

  test('batches enforce byte and expanded fat-object count boundaries', () {
    final file = put('fat', elf(1));
    SymbolArtifact artifact(String id, int count) =>
        SymbolArtifact(file, 'elf', List.generate(count, (i) => SymbolVariant('$id$i', 'arm64', null)), {'debug'}, 0);
    final one = artifact('a', 1);
    final two = artifact('b', 2);
    expect(batchSymbolArtifacts([one, two], maxObjects: 3, maxBytes: 480).map((b) => b.length), [2]);
    expect(batchSymbolArtifacts([one, two], maxObjects: 2, maxBytes: 480).map((b) => b.length), [1, 1]);
    expect(batchSymbolArtifacts([one, two], maxObjects: 3, maxBytes: 479).map((b) => b.length), [1, 1]);
    expect(() => batchSymbolArtifacts([two], maxBytes: 319), throwsA(isA<SymbolFailure>()));
  });

  test('artifacts beyond bounded upload capacity are dropped and reported', () {
    final file = put('fat', elf(1));
    SymbolArtifact artifact(String id, int count) =>
        SymbolArtifact(file, 'elf', List.generate(count, (i) => SymbolVariant('$id$i', 'arm64', null)), {'debug'}, 0);
    final one = artifact('a', 1);
    final two = artifact('b', 2);
    final warnings = StringBuffer();
    expect(withinUploadCapacity([one, two], maxBytes: 480, warnings: warnings), [one, two]);
    expect(warnings.toString(), isEmpty);
    // 'two' is charged once per slice, so it alone exceeds a 319-byte bound.
    expect(withinUploadCapacity([one, two], maxBytes: 319, warnings: warnings), [one]);
    expect(warnings.toString(), contains('Skipping artifact beyond bounded upload capacity'));
    expect(withinUploadCapacity([one, two], maxObjects: 1, maxBytes: 480), [one]);
  });

  test('native, Dart, map and release errors stop before later phases', () async {
    android();
    final selected = await plan();
    for (final phase in ['native', 'dart', 'map', 'new', 'finalize']) {
      operations.clear();
      failure = (args) {
        final upload = args.take(2).join(' ') == 'debug-files upload';
        if (phase == 'native' && upload && args.last.endsWith('.so')) return 22;
        if (phase == 'dart' && upload && args.last.endsWith('.symbols')) return 22;
        if (phase == 'map' && args.first == 'dart-symbol-map') return 22;
        if (args.first == 'releases' && args[1] == phase) return 22;
        return 0;
      };
      await expectLater(
        executeSymbolPlan(selected, cli),
        throwsA(isA<SymbolFailure>().having((e) => e.code, 'exit status', 22)),
      );
      final releasePhases = operations.where((a) => a.first == 'releases').map((a) => a[1]).toList();
      expect(
        releasePhases,
        phase == 'finalize'
            ? ['new', 'finalize']
            : phase == 'new'
            ? ['new']
            : isEmpty,
      );
      expect(failure(operations.last), 22);
    }
  });

  test('dry run and execution share selection; maps use temporary paired copies', () async {
    android();
    final map = File(path.join(repository.path, 'debug-info/android-aab/obfuscation.map.json'));
    final before = map.readAsBytesSync();
    final dryOutput = StringBuffer();
    final executionOutput = StringBuffer();
    final common = {'SENTRY_RELEASE': 'plezy@fixture', 'SENTRY_DIST': 'play-store'};
    expect(
      await runUploadSymbols(
        ['android-aab'],
        repositoryRoot: repository,
        environment: {...common, 'BUGS_UPLOAD_DRY_RUN': '0'},
        command: cli,
        output: dryOutput,
        errors: warnings,
      ),
      0,
    );
    expect(operations, isEmpty);
    expect(map.readAsBytesSync(), before);
    expect(
      await runUploadSymbols(
        ['android-aab'],
        repositoryRoot: repository,
        environment: {...common, 'SENTRY_AUTH_TOKEN': 'fixture'},
        command: cli,
        output: executionOutput,
        errors: warnings,
      ),
      0,
    );
    // The plan is the first line; execution then appends the CLI's own log.
    final executionPlan = const LineSplitter().convert(executionOutput.toString()).first;
    expect(jsonDecode(executionPlan), jsonDecode(dryOutput.toString()));
    expect(uploadedMaps, [
      ['SENTRY_DEBUG_ID_MARKER', fixtureDebugId(1), 'Original', 'a'],
    ]);
    expect(map.readAsBytesSync(), before);
    expect(operations.where((a) => a.first == 'releases').map((a) => a[1]), ['new', 'finalize']);
    final temporaryMap = operations.singleWhere((a) => a.first == 'dart-symbol-map')[2];
    expect(File(temporaryMap).existsSync(), isFalse);
  });

  test('non-obfuscated iOS does not invent a map and cannot consume Android map', () async {
    put('build/ios/iphoneos/Plezy.app/Frameworks/App.framework/App', elf(1));
    put('build/ios/Release-iphoneos/App.framework.dSYM/Contents/Resources/DWARF/App', elf(1));
    put('debug-info/ios/app.ios-arm64.symbols', elf(1));
    put('debug-info/android-aab/obfuscation.map.json', utf8.encode('["Wrong","a"]'));
    final selected = await plan('ios');
    expect(selected.mapPath, isNull);
    expect(selected.native.single.file.path, contains('App.framework.dSYM'));
  });

  test('mpv-build symbols are downloaded, verified and kept only for shipped identities', () async {
    linux();
    const asset = 'libmpv-linux-496db2c56ebc-x86_64-symbols.zip';
    lock({
      'linux': linuxGroup({
        'x86_64': publish('linux', asset, {
          'libmpv.so.2': elf(5, machine: 62),
          'libmpv-stale.so': elf(77, machine: 62),
          'nested/libmpv.so.2': elf(6, machine: 62),
        }),
      }),
    });
    final debugFile = extracted(asset, 'libmpv.so.2');
    final stale = extracted(asset, 'libmpv-stale.so');
    final selected = await plan('linux-x64');
    expect(downloads, [Uri.parse('$mpvBuildReleases/binaries-linux/$asset')]);
    // The debug file outranks the bundle's stripped copy of the same build-id.
    expect(selected.native.singleWhere((a) => a.variants.single.debugId == fixtureDebugId(5)).file.path, debugFile);
    expect(selected.native.map((a) => a.file.path), isNot(contains(stale)));
    expect(warnings.toString(), contains('Skipping debug file that matches no shipped binary: $stale'));
    expect(selected.native.map((a) => a.file.path).where((p) => p.contains('nested')), isEmpty);

    // A verified archive is reused rather than fetched again.
    await plan('linux-x64');
    expect(downloads, hasLength(1));
  });

  test('an mpv-build symbols checksum mismatch fails before anything is extracted', () async {
    linux();
    const asset = 'libmpv-linux-496db2c56ebc-x86_64-symbols.zip';
    final entry = publish('linux', asset, {'libmpv.so.2': elf(5, machine: 62)});
    lock({
      'linux': linuxGroup({
        'x86_64': {...entry, 'checksum': sha256.convert(utf8.encode('other bytes')).toString()},
      }),
    });
    await expectLater(
      plan('linux-x64'),
      throwsA(isA<SymbolFailure>().having((e) => e.message, 'message', contains('Checksum mismatch'))),
    );
    final directory = Directory(path.join(repository.path, 'build/symbols/mpv-build'));
    expect(directory.listSync(), isEmpty);

    lock({
      'linux': linuxGroup({
        'x86_64': {...entry, 'asset': '../$asset'},
      }),
    });
    await expectLater(plan('linux-x64'), throwsA(isA<SymbolFailure>()));
    releases.clear();
    lock({
      'linux': linuxGroup({'x86_64': entry}),
    });
    await expectLater(
      plan('linux-x64'),
      throwsA(isA<SymbolFailure>().having((e) => e.message, 'message', contains('Cannot download'))),
    );
  });

  test('a pin without mpv-build symbols is noted and skipped', () async {
    linux();
    lock({'linux': linuxGroup()});
    final selected = await plan('linux-x64');
    expect(downloads, isEmpty);
    expect(warnings.toString(), contains('mpv-build.lock.json has no linux symbols for x86_64'));
    expect(selected.native.map((a) => path.basename(a.file.path)), containsAll(['libapp.so', 'libmpv.so.2']));
  });

  test('Android fetches mpv-build symbols for packaged ABIs only', () async {
    android();
    const arm64 = 'mpv-android-c1014380930d-arm64-v8a-symbols.zip';
    lock({
      'android': {
        'aar': {
          'asset': 'mpv-android-c1014380930d.aar',
          'checksum': '3a5bc46c123ac52be00a7d89d5f88450e9f1b71bbba5d5d6b873a294cc22cfc7',
          'key': 'c1014380930d',
        },
        'assetBase': '$mpvBuildReleases/binaries-android',
        'symbols': {
          'arm64-v8a': publish('android', arm64, {'libmpv.so': elf(30)}),
          'x86_64': publish('android', 'mpv-android-c1014380930d-x86_64-symbols.zip', {
            'libmpv.so': elf(40, machine: 62),
          }),
        },
      },
    });
    final debugFile = extracted(arm64, 'libmpv.so');
    final selected = await plan();
    expect(downloads, [Uri.parse('$mpvBuildReleases/binaries-android/$arm64')]);
    expect(selected.native.singleWhere((a) => path.basename(a.file.path) == 'libmpv.so').file.path, debugFile);
  });

  test('Android engine symbols are the merged unstripped libflutter.so of the packaged build-id', () async {
    // Flutter's Android Gradle plugin merges the engine's unstripped
    // libflutter.so (build-id edfb9140... in 3.47.1's Maven jar and its
    // symbols.zip alike), so no engine symbols download is needed.
    android();
    put(
      'build/app/outputs/bundle/release/app-release.aab',
      zip({
        'base/lib/arm64-v8a/libapp.so': elf(1),
        'base/lib/arm64-v8a/libmpv.so': elf(30),
        'base/lib/arm64-v8a/libflutter.so': elf(60),
      }),
    );
    const merged = 'build/app/intermediates/merged_native_libs/release/mergeReleaseNativeLibs/out/lib/arm64-v8a';
    final engine = put('$merged/libflutter.so', elf(60));
    final selected = await plan();
    final flutter = selected.native.singleWhere((a) => path.basename(a.file.path) == 'libflutter.so');
    expect(flutter.file.path, engine.path);
    expect(flutter.features, contains('debug'));
    expect(downloads, isEmpty);
  });

  test('Windows PDBs are picked up from the build tree for shipped binaries only', () async {
    windows();
    final mismatched = put(
      'build/windows/x64/plugins/screen_retriever_windows/Release/screen_retriever_windows_plugin.pdb',
      elf(40, machine: 62),
    );
    final debugConfig = put(
      'build/windows/x64/plugins/window_manager/Debug/window_manager_plugin.pdb',
      elf(50, machine: 62),
    );
    const asset = 'libmpv-windows-3b5fe9282d30-x86_64-symbols.zip';
    lock({
      'windows': {
        'assetBase': '$mpvBuildReleases/binaries-windows',
        'assets': {
          'x86_64': {
            'asset': 'libmpv-windows-3b5fe9282d30-x86_64.zip',
            'checksum': '2bcdcd594b94c3dda436585716bfa7b4e55a39f7ac2e048f0b6e37edb3cb92ef',
          },
        },
        'key': '3b5fe9282d30',
        'symbols': {
          'x86_64': publish('windows', asset, {'libmpv-2.pdb': elf(14, machine: 62)}),
        },
      },
    });
    final libmpv = extracted(asset, 'libmpv-2.pdb', info: 'debug, symtab');
    final selected = await plan('windows-x64');
    final pdbs = selected.native.where((a) => a.type == 'pdb').map((a) => a.file.path).toSet();
    expect(pdbs, {
      path.join(repository.path, 'build/windows/x64/link-artifacts/Release/plezy.pdb'),
      path.join(repository.path, 'build/windows/x64/plugins/window_manager/Release/window_manager_plugin.pdb'),
      path.join(repository.path, 'windows/flutter/ephemeral/flutter_windows.dll.pdb'),
      libmpv,
    });
    // Each PDB rides with, not instead of, its binary's unwind information.
    final peIdentities = selected.native.where((a) => a.type == 'pe').expand((a) => a.variants).map((v) => v.identity);
    for (final pdb in selected.native.where((a) => a.type == 'pdb')) {
      expect(peIdentities, contains(pdb.variants.single.identity));
    }
    expect(warnings.toString(), contains('Skipping debug file that matches no shipped binary: ${mismatched.path}'));
    expect(warnings.toString(), isNot(contains(debugConfig.path)));
  });

  test('dry run plans the Windows PDBs', () async {
    windows();
    final output = StringBuffer();
    expect(
      await runUploadSymbols(
        ['windows-x64'],
        repositoryRoot: repository,
        environment: {
          'SENTRY_RELEASE': 'plezy@fixture',
          'SENTRY_DIST': 'github-windows-x64',
          'BUGS_UPLOAD_DRY_RUN': '1',
        },
        command: cli,
        output: output,
        errors: warnings,
        download: download,
      ),
      0,
    );
    expect(operations, isEmpty);
    final dryPlan = jsonDecode(output.toString()) as Map<String, Object?>;
    final planned = [
      for (final batch in dryPlan['native_batches']! as List)
        for (final artifact in (batch as List).cast<Map<String, Object?>>())
          if (artifact['class'] == 'pdb') path.basename(artifact['path']! as String),
    ];
    expect(planned, unorderedEquals(['plezy.pdb', 'window_manager_plugin.pdb', 'flutter_windows.dll.pdb']));
    expect(warnings.toString(), contains('mpv-build.lock.json has no windows symbols for x86_64'));
  });

  test('debug objects the CLI drops without an error fail the upload', () async {
    windows();
    final selected = await plan('windows-x64');
    // Run 38170180917: the server's chunk-upload accept list lacked "pdbs",
    // so sentry-cli found only the ELF of each Windows batch and exited 0.
    unaccepted = {'pdb', 'pe'};
    await expectLater(
      executeSymbolPlan(selected, cli),
      throwsA(isA<SymbolFailure>().having((e) => e.message, 'message', contains('dropped the rest'))),
    );
    expect(operations.where((a) => a.first == 'releases'), isEmpty);

    operations.clear();
    unaccepted = {};
    final output = StringBuffer();
    await executeSymbolPlan(selected, cli, output: output);
    expect(operations.where((a) => a.first == 'releases').map((a) => a[1]), ['new', 'finalize']);
    expect(output.toString(), contains('> Found 8 debug information files'));
  });
}
