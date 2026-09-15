import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
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

void main() {
  late Directory repository;
  late Map<String, String> features;
  late List<List<String>> operations;
  late List<List<String>> uploadedMaps;
  late int Function(List<String>) failure;

  File put(String relative, List<int> bytes, {String info = 'debug, symtab, unwind'}) {
    final file = File(path.join(repository.path, relative));
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
    features[file.path] = info;
    return file;
  }

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
          'type': 'elf',
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
    return ProcessResult(0, failure(args), '', 'injected process failure');
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

  Future<SymbolPlan> plan([String platform = 'android-aab']) => createSymbolPlan(platform, repository.path, {
    'SENTRY_RELEASE': 'plezy@fixture',
    'SENTRY_DIST': 'play-store',
  }, cli);

  setUp(() async {
    repository = await Directory.systemTemp.createTemp('plezy_upload_symbols_');
    features = {};
    operations = [];
    uploadedMaps = [];
    failure = (_) => 0;
  });
  tearDown(() async => repository.delete(recursive: true));

  test('packaged identities exclude unshipped ABI, stale intermediates and mixed targets', () async {
    android();
    final rich = put('build/libmpv/libmpv/native/imported/arm64-v8a/libmpv.so', elf(30));
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
    expect(selected.native.singleWhere((a) => path.basename(a.file.path) == 'libmpv.so').file.path, rich.path);
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
      ),
      0,
    );
    expect(jsonDecode(executionOutput.toString()), jsonDecode(dryOutput.toString()));
    expect(uploadedMaps, [
      ['SENTRY_DEBUG_ID_MARKER', fixtureDebugId(1), 'Original', 'a'],
    ]);
    expect(map.readAsBytesSync(), before);
    expect(operations.where((a) => a.first == 'releases').map((a) => a[1]), ['new', 'finalize']);
    final temporaryMap = operations.singleWhere((a) => a.first == 'dart-symbol-map')[2];
    expect(File(temporaryMap).existsSync(), isFalse);
  });

  test('non-obfuscated iOS does not invent a map and cannot consume Android map', () async {
    put('build/ios/iphoneos/Runner.app/Frameworks/App.framework/App', elf(1));
    put('build/ios/Release-iphoneos/App.framework.dSYM/Contents/Resources/DWARF/App', elf(1));
    put('debug-info/ios/app.ios-arm64.symbols', elf(1));
    put('debug-info/android-aab/obfuscation.map.json', utf8.encode('["Wrong","a"]'));
    final selected = await plan('ios');
    expect(selected.mapPath, isNull);
    expect(selected.native.single.file.path, contains('App.framework.dSYM'));
  });
}
